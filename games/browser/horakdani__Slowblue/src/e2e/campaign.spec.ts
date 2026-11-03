import { expect, test } from '@playwright/test';
import { boot, bootAct, clearStation, collectErrors, completeAct, metrics } from './helpers';

/**
 * Slowblue: the circuit, driven through the real shell.
 *
 * `tests/circuit.test.ts` already proves the state machine in isolation, and it
 * is the right place for that - the controller owns no world and reads no clock.
 * What it cannot see is the half of the campaign that only exists in `main.ts`:
 * that a finished act reaches no dialog, that the next one opens by itself on
 * what arrived, that a failure in the upper acts costs a station rather than the
 * journey, and that the seventh hands back to the title having banked a cycle.
 *
 * That is what this file is for, and it is deliberately the slow spec: seven acts
 * with a film between each one is most of a minute of wall clock, and there is no
 * way to prove "no dialog ever appeared" without waiting for the frames in which
 * one could have.
 */

/** The circuit, in order. Trench floor to trench floor. */
const ACTS = ['water', 'air', 'thin', 'orbit', 'reentry', 'rain', 'home'];

/**
 * Generous, and per act rather than for the whole run: the handover waits out the
 * outgoing act's film, and the films differ by an order of magnitude - a beat for
 * an act that still ends on a cut, fifteen seconds for the release.
 */
const HANDOVER_TIMEOUT = 30_000;

test('plays the whole circuit end to end, and closes it', async ({ page }) => {
  test.setTimeout(240_000);
  const errors = collectErrors(page);
  await boot(page, 2026);

  const seen: string[] = [];
  let cargo = 0;
  for (let i = 0; i < ACTS.length; i++) {
    const at = await metrics(page);
    seen.push(at.act as string);
    expect(at.mode, `act ${i + 1} is playing`).toBe('playing');
    expect(at.campaign).toBe(true);
    // Every act after the first opens on what the last one handed over.
    if (i > 0) expect(at.count as number).toBeGreaterThan(15);

    cargo = (await metrics(page)).count as number;
    // Each act is worth something, so the banked total is a sum the runs earned
    // rather than seven zeroes.
    await completeAct(page, 500);
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
    // The one thing a handover may never be.
    await expect(page.locator('.ui')).toBeHidden();

    if (i < ACTS.length - 1) {
      const next = ACTS[i + 1]!;
      await page.waitForFunction((key) => window.__slowblue!.metrics().act === key, next, {
        timeout: HANDOVER_TIMEOUT,
      });
      const arrived = await metrics(page);
      expect(arrived.actIndex).toBe(i + 1);
      expect(arrived.actsCleared).toBe(i + 1);
      expect(arrived.cargo).toBe(cargo);
      expect(arrived.banked as number).toBeGreaterThanOrEqual(500 * (i + 1));
    }
  }

  expect(seen).toEqual(ACTS);

  // The seventh act has no next one. It closes the circuit, banks it, and only
  // then is the player shown anything.
  await expect(page.locator('.ui-score')).toBeVisible({ timeout: HANDOVER_TIMEOUT });
  const done = await metrics(page);
  expect(done.cycles as number).toBeGreaterThanOrEqual(1);
  expect(errors).toEqual([]);
});

/**
 * Act select: the other way into the circuit, and the one screen that has to be
 * honest about where the player has been. An act is open once they have arrived
 * at it and never before.
 */
test('offers the acts the player has reached, and only those', async ({ page }) => {
  await page.goto('/?seed=7');
  await page.waitForFunction(() => window.__slowblue !== undefined);
  // A first-time player is offered the map too, and it tells them the truth: an
  // unlit ring, and none of the forty-two behind them. It used to be hidden until
  // there was a journey to look at, which meant the one screen that shows what
  // "seven acts, one circuit" means was the last thing the game showed you.
  const map = page.getByRole('button', { name: /^the circuit\b/i });
  await expect(map).toBeVisible();
  await expect(map).toHaveText(/0\/42/);

  // ...and a player who has reached act V is offered five of the seven.
  await page.evaluate(() => {
    const key = 'tide.profile';
    const raw = localStorage.getItem(key);
    const p = raw === null ? {} : (JSON.parse(raw) as Record<string, unknown>);
    p.unlockedAct = 4;
    p.saved = {
      position: { act: 3, level: 0 },
      banked: 12400,
      cargo: 96,
      actsCleared: 3,
      completed: false,
    };
    localStorage.setItem(key, JSON.stringify(p));
  });
  await page.reload();
  await page.waitForFunction(() => window.__slowblue !== undefined);

  // A circuit was put down, so the first button continues it rather than
  // offering to start one.
  await expect(page.locator('button.ui-btn.primary').first()).toHaveText(/continue/i);
  // The one number the title screen carries: how much of the circuit is behind
  // them. It rides on the button that opens the map rather than on a line of its
  // own, because the title screen's whole job is to get out of the way.
  const open = page.getByRole('button', { name: /^the circuit\b/i });
  await expect(open).toHaveText(/24\/42/);
  await open.click();

  // The seven acts are picked on the picture itself - each one owns its stretch
  // of the line and the name beside it - rather than from a strip of numerals
  // underneath, which said nothing about where any act was.
  const marks = page.locator('button.ui-map-act');
  await expect(marks).toHaveCount(7);
  await expect(page.locator('button.ui-map-act:not(.locked)')).toHaveCount(5);
  await expect(page.locator('button.ui-map-act.locked')).toHaveCount(2);
  // Locked markers are not merely dimmed, they are unpressable.
  await expect(marks.nth(6)).toBeDisabled();

  /*
   * ...and the map draws where they have been, which is the half of this screen
   * a list of names could never carry.
   *
   * The fixture above is a version 2 profile: it names act V and stores no
   * station record at all. `unlockedAct` can only be raised by an act *finishing*
   * - act select offers nothing above it - so four completed acts is what the
   * old field means, and the migration says so rather than starting this player
   * back at zero. Twenty-four of the forty-two marks are lit, the three acts
   * ahead are dark, and the bright point is on the station the circuit will
   * resume from.
   */
  const world = page.locator('svg.ui-map-world');
  await expect(world).toBeVisible();
  await expect(world.locator('circle.ui-map-station')).toHaveCount(42);
  await expect(world.locator('circle.ui-map-station.on')).toHaveCount(24);
  await expect(world.locator('circle.ui-map-here')).toHaveCount(1);
  // Four acts flown, so four stretches of the line are lit and no more - and
  // four links, because a link is earned by finishing the act that leads into it.
  await expect(world.locator('path.ui-map-flown:not(.link)')).toHaveCount(4);
  await expect(world.locator('path.ui-map-flown.link:not(.close)')).toHaveCount(4);
  // ...and the circuit has not closed, so the bottom of the map is still dark.
  await expect(world.locator('path.ui-map-flown.close')).toHaveCount(0);
  // The whole route is drawn whether or not it has been flown - seven acts at
  // one weight, and the seven seams between them at less than half of it, which
  // is what makes seven services out of one chain of forty-two stops.
  await expect(world.locator('path.ui-route:not(.join)')).toHaveCount(7);
  await expect(world.locator('path.ui-route.join')).toHaveCount(7);
  // ...and each of those seams carries a head, so the picture says which way
  // round the journey goes and not only what order the names are in. The arrow
  // is drawn on a road nobody has been down as well: direction is a fact about
  // the route. What it takes from the record is its ink - four seams flown,
  // four lit heads.
  await expect(world.locator('path.ui-route-arrow')).toHaveCount(7);
  await expect(world.locator('path.ui-route-arrow.on')).toHaveCount(4);
  // The act it is sitting in is marked on its own target too, and only that one.
  await expect(page.locator('button.ui-map-act.here')).toHaveCount(1);
  await expect(marks.nth(3)).toHaveClass(/here/);

  /*
   * The card opens on the act the circuit is sitting in - not on the last thing
   * anyone pressed, and not on act I - because that is the act this player is
   * about to play. Its six stations are the six pads picked out on the map, and
   * one line of what the act is.
   */
  await expect(page.locator('button.ui-map-act.sel')).toHaveCount(1);
  await expect(marks.nth(3)).toHaveClass(/sel/);
  const core = page.locator('.ui-map-core');
  await expect(core).toContainText(/orbit/i);
  await expect(core.locator('.ui-map-arc')).toHaveText(/\S/);
  await expect(world.locator('circle.ui-map-station.sel')).toHaveCount(6);
  // Every act is ringed where its road is entered, and one of the seven is the
  // one the card is showing.
  await expect(world.locator('circle.ui-map-entry')).toHaveCount(7);
  await expect(world.locator('circle.ui-map-entry.sel')).toHaveCount(1);
  // How much of the selected act is behind you is said once, on the map, in the
  // six stops themselves - the card used to carry a row of dots repeating it.
  // Act IV is done, so all six of its stops are filled.
  await expect(world.locator('circle.ui-map-station.sel.on')).toHaveCount(6);

  /*
   * The button under the writing says which of the two things it does.
   *
   * Act IV is where this player put the circuit down, so pressing it picks that
   * circuit back up - station included - and the button says so. Act V is a
   * fresh circuit entered at act V, from its first station, and calling that
   * CONTINUE would be the button promising a journey it is about to replace.
   */
  const go = page.locator('button.ui-btn.primary').first();
  await expect(go).toHaveText(/continue/i);

  // Pressing one moves the writing and the marks; it does not start anything.
  await marks.nth(4).click();
  await expect(marks.nth(4)).toHaveClass(/sel/);
  await expect(marks.nth(3)).not.toHaveClass(/sel/);
  await expect(core).toContainText(/fallback/i);
  await expect(go).toHaveText(/begin/i);
  // Act V has not been touched, and the map says so in the same six stops.
  await expect(world.locator('circle.ui-map-station.sel')).toHaveCount(6);
  await expect(world.locator('circle.ui-map-station.sel.on')).toHaveCount(0);
  // Nothing was entered: the map is still the screen.
  await expect(world).toBeVisible();

  // The stations unfold from the sentence that introduces them - there is no
  // second control for it further down the screen - and they follow the pick.
  await expect(page.locator('ol.ui-stations')).toHaveCount(0);
  const stations = page.locator('button.ui-map-core-open');
  await stations.click();
  const list = page.locator('ol.ui-stations');
  await expect(list.locator('li')).toHaveCount(6);
  await expect(list.locator('li.done')).toHaveCount(0);
  await marks.nth(0).click();
  await expect(list.locator('li').first()).toContainText(/trench floor/i);
  await expect(list.locator('li.done')).toHaveCount(6);
  await page.locator('button.ui-map-core-open').click();
  await expect(page.locator('ol.ui-stations')).toHaveCount(0);

  // Entering at act IV plays act IV, with a swarm in it.
  await marks.nth(3).click();
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  const m = await metrics(page);
  expect(m.act).toBe('orbit');
  expect(m.actIndex).toBe(3);
  expect(m.campaign).toBe(true);
  expect(m.count as number).toBeGreaterThan(15);
});

/**
 * The failure rule, at the seam where it actually matters. The unit tests assert
 * each act's policy; this asserts that the policy reaches the player - that a
 * swarm lost puts the station back rather than putting the campaign down.
 *
 * Acts I and II are in the list now, and they are the reason the list exists.
 * They used to end the run and hand the player back to the top of the campaign,
 * which made the two acts somebody meets first - on a phone, before they have
 * learned anything - the only two that could take twenty minutes for one mistake.
 *
 * This is the *first* failure of an attempt. What the third one does is the next
 * test but one.
 */
test('every act costs a station, never the campaign', async ({ page }) => {
  for (const key of ['water', 'air', 'thin', 'orbit', 'reentry', 'rain']) {
    await bootAct(page, key, 31337);
    expect((await metrics(page)).act).toBe(key);

    // Lose the whole swarm, the way a badly scattered one is lost, and let the
    // world notice on its own step rather than telling it what to conclude.
    const after = await page.evaluate(() => {
      const w = window.__slowblue!.world;
      const before = w.run.restarts;
      for (const a of w.swarm.agents) if (a.faction === 0) a.alive = false;
      for (let i = 0; i < 8; i++) w.step(1 / 60);
      return { phase: w.run.phase, count: w.shoalCount, gained: w.run.restarts - before };
    });

    expect(after.phase, `${key} keeps running`).toBe('running');
    expect(after.gained, `${key} restarted a station`).toBeGreaterThan(0);
    // The station was rebuilt with a swarm in it, not left empty.
    expect(after.count, `${key} respawned`).toBeGreaterThan(0);
    expect((await metrics(page)).mode).toBe('playing');
  }
});

/**
 * Slowblue: a cleared station stays cleared, through the real shell and a real reload.
 *
 * `tests/checkpoint.test.ts` proves the controller and the restore in isolation.
 * What only exists in `main.ts` is the wiring between them: that the sim's own
 * station event is what writes the save, that the number it writes is the *next*
 * station rather than the one just finished, that the title screen prints that
 * number, and that pressing the button opens the water there. Every one of those
 * is an off-by-one waiting to happen, and none of them can be seen from a unit
 * test.
 *
 * The reload is a real `page.reload()` with nothing run on the way out - no
 * pause, no quit, no chance to tidy up. That is the case the whole feature is
 * for: a browser tab reclaimed in the background, or a phone that took the
 * process while the player was looking at something else.
 */
test('keeps a cleared station across a reload, and says where it is', async ({ page }) => {
  const errors = collectErrors(page);
  await boot(page, 2026);
  expect((await metrics(page)).station).toBe(0);

  // The first station, flown and cleared.
  await clearStation(page, 0, 500);
  const at = await metrics(page);
  expect(at.actIndex).toBe(0);
  expect(at.station, 'the save names the next station, not the last one').toBe(1);

  // Most of the second station, and then the process is gone. Nothing is written
  // on the way out and nothing needs to be.
  await page.waitForFunction(() => (window.__slowblue!.metrics().time as number) > 1);
  await page.reload();
  await page.waitForFunction(() => window.__slowblue !== undefined);

  // The title screen says where it will drop them, and it is the second station.
  const go = page.locator('button.ui-btn.primary').first();
  await expect(go).toHaveText(/continue/i);
  await expect(go).toHaveText(/station 2\/6/i);

  // ...and pressing it opens exactly that water, not act I from the top.
  await go.click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  const resumed = await metrics(page);
  expect(resumed.act).toBe('water');
  expect(resumed.station).toBe(1);
  expect(resumed.level, 'the world opened at the saved station').toBe(1);
  expect(resumed.campaign).toBe(true);
  expect(errors).toEqual([]);
});

/**
 * ...and a death lands in the same place a closed tab does.
 *
 * The rule the whole change is built on: whatever stopped the run - a lost swarm,
 * a crash, a home button - the earliest the campaign ever asks a player to start
 * again is the station they were in. Act I is the case that used to be different,
 * so act I is the case driven here.
 */
test('resumes the station after a death, exactly as after an interruption', async ({ page }) => {
  await page.goto('/?seed=2026');
  await page.waitForFunction(() => window.__slowblue !== undefined);

  // A circuit put down at act I's third station: the state the test above leaves
  // on disk, written straight in so that losing the swarm is the only thing this
  // one drives.
  await page.evaluate(() => {
    const key = 'tide.profile';
    const p = JSON.parse(localStorage.getItem(key) ?? '{}') as Record<string, unknown>;
    p.saved = {
      position: { act: 0, level: 2 },
      banked: 900,
      cargo: 26,
      actsCleared: 0,
      completed: false,
    };
    localStorage.setItem(key, JSON.stringify(p));
  });
  await page.reload();
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');

  const opened = await metrics(page);
  expect(opened.act).toBe('water');
  expect(opened.station).toBe(2);
  expect(opened.level, 'act I opened at its third station').toBe(2);

  // Lose the whole swarm in act I, which used to be the end of the campaign.
  const after = await page.evaluate(() => {
    const w = window.__slowblue!.world;
    const before = w.run.restarts;
    for (const a of w.swarm.agents) if (a.faction === 0) a.alive = false;
    for (let i = 0; i < 8; i++) w.step(1 / 60);
    return { phase: w.run.phase, level: w.levelIndex, gained: w.run.restarts - before };
  });
  expect(after.phase, 'act I no longer ends on a lost swarm').toBe('running');
  expect(after.gained).toBe(1);
  expect(after.level, 'the station it went wrong in, not the act it is in').toBe(2);

  // ...and the campaign never moved, so a reload after the death lands exactly
  // where a reload before it would have.
  const held = await metrics(page);
  expect(held.actIndex).toBe(0);
  expect(held.station).toBe(2);
  expect(held.banked, 'nothing already banked was taken away').toBe(900);
  expect(held.mode).toBe('playing');
});

/**
 * ...and the third failure costs the act, which is what keeps an act one
 * performance instead of six separately ground-out ones.
 *
 * Driven through the shell because the rollback only exists here: the sim knows
 * how to end a run, and `main.ts` is the only thing that turns that into "the
 * attempt is over" - the campaign back to the act's first station, on the score
 * and the carried life the act was entered with, with a fresh budget.
 */
test('loses the act on the third failure, and gives back the act’s own start', async ({ page }) => {
  await page.goto('/?seed=2026');
  await page.waitForFunction(() => window.__slowblue !== undefined);

  // Act I, third station, two stations of it banked - and a snapshot of what
  // entering the act looked like, which is what losing it has to restore.
  await page.evaluate(() => {
    const key = 'tide.profile';
    const p = JSON.parse(localStorage.getItem(key) ?? '{}') as Record<string, unknown>;
    p.saved = {
      position: { act: 0, level: 2 },
      banked: 900,
      cargo: 26,
      actsCleared: 0,
      completed: false,
      actStart: { cargo: 25, banked: 400 },
      restarts: 0,
    };
    localStorage.setItem(key, JSON.stringify(p));
  });
  await page.reload();
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  expect((await metrics(page)).attempts).toBe(2);

  const lose = async (): Promise<void> => {
    await page.evaluate(() => {
      const w = window.__slowblue!.world;
      for (const a of w.swarm.agents) if (a.faction === 0) a.alive = false;
      for (let i = 0; i < 8; i++) w.step(1 / 60);
    });
  };

  // Two failures are two stations. The campaign holds its ground, and the budget
  // is written down as it is spent - a crash between two of these must not
  // refund one.
  await lose();
  await page.waitForFunction(() => window.__slowblue!.metrics().attempts === 1);
  expect((await metrics(page)).station).toBe(2);
  await lose();
  await page.waitForFunction(() => window.__slowblue!.metrics().attempts === 0);
  const held = await metrics(page);
  expect(held.station).toBe(2);
  expect(held.mode).toBe('playing');

  // The third is the attempt.
  await lose();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
  const lost = await metrics(page);
  expect(lost.actIndex, 'the circuit is not lost, the act is').toBe(0);
  expect(lost.station, 'back to the act’s first station').toBe(0);
  expect(lost.banked, 'the act’s own points go with it').toBe(400);
  expect(lost.cargo, 'and the life it was entered with comes back').toBe(25);
  expect(lost.attempts, 'a fresh attempt').toBe(2);

  // The results screen, and then the act again from its beginning.
  await expect(page.locator('.ui-score')).toBeVisible({ timeout: HANDOVER_TIMEOUT });
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  const again = await metrics(page);
  expect(again.act).toBe('water');
  expect(again.level, 'the act opens at its first station').toBe(0);
  expect(again.restartsLeft).toBe(2);
});

/**
 * The last three stations of act VII cannot be lost at all - not restarted,
 * *nothing*. It is the only water in the game with no failure state, and it is
 * the last thing the player is in.
 */
test('the last water in the campaign cannot be lost', async ({ page }) => {
  await bootAct(page, 'home', 31337);
  const state = await page.evaluate(() => {
    const w = window.__slowblue!.world;
    // Straight to the trench floor: the second half of the act, where nothing ends.
    const last = w.act.levels.length - 1;
    w.reset(w.seed, w.act.script.findIndex((e) => e.level === last));
    const mode = w.failureMode;
    const restarts = w.run.restarts;
    for (const a of w.swarm.agents) if (a.faction === 0) a.alive = false;
    for (let i = 0; i < 8; i++) w.step(1 / 60);
    return { mode, phase: w.run.phase, restarted: w.run.restarts > restarts };
  });
  expect(state.mode).toBe('none');
  expect(state.phase).toBe('running');
  expect(state.restarted).toBe(false);
  expect((await metrics(page)).mode).toBe('playing');
});

/**
 * Slowblue: continuous circuit mode, which is one screen not appearing.
 *
 * §11 unlocks it after a full campaign, and what it does is take the results
 * dialog out of the seam that has one. Every other seam in the circuit is already
 * a film running into the next act's first frame; with this on, so is the seventh
 * - `render/Circle.ts` dissolves the trench floor into act I's opening picture
 * and act I simply arrives there.
 *
 * Driven through the shell rather than asserted on the controller, because the
 * controller has nothing to do with it: the whole feature is four lines in
 * `main.ts` and the absence of a `shell.show('over')`.
 */
test('keeps the circle turning when the player asks it to', async ({ page }) => {
  test.setTimeout(180_000);
  const errors = collectErrors(page);

  await page.goto('/?seed=99');
  await page.waitForFunction(() => window.__slowblue !== undefined);
  // A player who has never closed a circuit is not offered it. Until they have,
  // "the trench floor is not the end of it" is a sentence about somewhere they
  // have not been.
  // The switch lives on the map now, beside the button that starts a run, rather
  // than in a list of preferences three taps away from anything it changes.
  await page.locator('.ui-journey').click();
  await expect(
    page.getByRole('switch', { name: /continuous circuit/i }),
  ).toHaveCount(0);
  await page.getByRole('button', { name: /^back$/i }).click();

  // ...and now one who has, standing at the last act of the next circuit.
  await page.evaluate(() => {
    const profile = JSON.parse(localStorage.getItem('tide.profile') ?? '{}') as Record<
      string,
      unknown
    >;
    profile.unlockedAct = 6;
    profile.cycles = 1;
    localStorage.setItem('tide.profile', JSON.stringify(profile));
  });
  await page.reload();
  await page.waitForFunction(() => window.__slowblue !== undefined);

  // The toggle exists now, and it did not before: that is the unlock, and it is
  // the only part of this feature the player can see before they use it.
  await page.locator('.ui-journey').click();
  const toggle = page.getByRole('switch', { name: /continuous circuit/i });
  await expect(toggle).toBeVisible();
  await toggle.click();
  await expect(toggle).toHaveAttribute('aria-checked', 'true');

  // Enter at act VII, which is the only seam this changes - and no longer any
  // navigation to get there, because the switch and the map are the same screen.
  // The act is picked on the picture, and the button under it plays.
  await page.locator('button.ui-map-act').nth(6).click();
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  await page.waitForFunction(() => (window.__slowblue!.metrics().time as number) > 0.2);
  expect((await metrics(page)).act).toBe('home');

  const before = (await metrics(page)).cycles as number;
  await completeAct(page, 500);

  // Act I, by itself, with no dialog between. The circle closed and kept going.
  await page.waitForFunction(() => window.__slowblue!.metrics().act === 'water', undefined, {
    timeout: HANDOVER_TIMEOUT,
  });
  const round = await metrics(page);
  expect(round.mode).toBe('playing');
  expect(round.actIndex).toBe(0);
  expect(round.campaign).toBe(true);
  // Still a circuit that counted, and still carrying what came round with it.
  expect(round.cycles as number).toBeGreaterThan(before);
  expect(round.count as number).toBeGreaterThan(15);
  await expect(page.locator('.ui')).toBeHidden();
  expect(errors).toEqual([]);
});
