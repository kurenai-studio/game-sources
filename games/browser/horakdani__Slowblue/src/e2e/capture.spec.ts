import { expect, test } from '@playwright/test';
import { collectErrors, shootScreen, WRITING_SCREENS } from './helpers';

/**
 * Slowblue: captures the states that matter into docs/screens/. Doubles as a smoke
 * test for mid-run rendering (rocks, pods, hunters, results), which the other spec
 * never reaches because it only plays the first couple of seconds.
 *
 * The capture half only happens when it is asked for - `npm run screens`, or
 * `SLOWBLUE_SCREENS=1` on any playwright run. These eleven are the only screenshots
 * in the repo that are *tracked*, and rewriting them on every `npm run verify`
 * meant a verify that changed nothing still left eleven modified binaries behind
 * and put them in the next diff. The smoke test is what belongs in verify; the
 * regeneration is an act, and acts get asked for.
 */
const SEED = 12345;

test('captures the key states', async ({ page }) => {
  const errors = collectErrors(page);

  await page.goto(`/?seed=${SEED}`);
  await page.waitForFunction(() => window.__slowblue !== undefined);

  // 0. The title: one sentence of premise, one button, held water behind it.
  await page.waitForFunction(() => (window.__slowblue!.metrics().fps as number) > 0);
  await shootScreen(page, 'docs/screens/00-title.png');

  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');

  // 1. Opening frame: shoal, no explanation, nothing to read.
  await page.evaluate(() => window.__slowblue!.advance(1.2));
  await shootScreen(page, 'docs/screens/01-start.png');

  // 2. The wow moment: one arc drag, the whole shoal bends around the current.
  await page.evaluate(() => {
    const t = window.__slowblue!;
    const w = t.world;
    const y = w.screenToWorldY(window.innerHeight * 0.58);
    for (let i = 0; i < 14; i++) {
      const x0 = window.innerWidth * (0.16 + 0.05 * i);
      const x1 = window.innerWidth * (0.16 + 0.05 * (i + 1));
      const bend = Math.sin((i / 14) * Math.PI) * -40;
      w.injectStroke(x0, y - bend, x1, y - bend * 1.1, 0.05);
      t.advance(1 / 60);
    }
    t.advance(0.2);
  });
  await shootScreen(page, 'docs/screens/02-first-drag.png');

  // 3+4. Let a scripted player reach a rock and then a rescue pod.
  await page.evaluate(() => {
    const t = window.__slowblue!;
    const w = t.world;
    const widest = (lineY: number): number => {
      let best = { c: w.width * 0.5, w: 0 };
      let start: number | null = null;
      for (let x = 4; x <= w.width - 4; x += 6) {
        const open = w.obstacles.hit(x, lineY, 1) === null;
        if (open && start === null) start = x;
        if ((!open || x > w.width - 10) && start !== null) {
          const width = x - start;
          if (width > best.w) best = { c: start + width / 2, w: width };
          start = null;
        }
      }
      return best.c;
    };
    let cooldown = 0;
    const play = (seconds: number, greedy: boolean, stop?: () => boolean): void => {
      for (let i = 0; i < seconds * 60; i++) {
        if (w.run.phase !== 'running') return;
        if (stop !== undefined && stop()) return;
        cooldown -= 1 / 60;
        if (cooldown <= 0) {
          cooldown = 0.1;
          const c = w.swarm.centroid();
          const next = w.obstacles.sections.find((s) => !s.passed && s.lineY < c.y);
          if (next !== undefined && c.count > 0) {
            let targetX = widest(next.lineY);
            if (greedy) {
              const pod = w.rescue.pods.find((p) => !p.merged && p.y < c.y && c.y - p.y < 420);
              if (pod !== undefined) targetX = pod.x;
            }
            const err = targetX - c.x;
            if (Math.abs(err) > 12) {
              w.injectStroke(c.x, c.y, c.x + Math.max(-110, Math.min(110, err)), c.y, 0.4);
            } else if (w.worldToScreenY(c.y) > w.height * 0.62) {
              w.injectStroke(c.x, c.y, c.x, c.y - 90, 0.4);
            }
          }
        }
        t.advance(1 / 60);
      }
    };
    // Keep the play loop on the window so the next step can continue the same run.
    (window as unknown as { __play: typeof play }).__play = play;
    // Play until there is actually rock on the glass, rather than for a number
    // of seconds that used to be one.
    //
    // This was `play(11, false)` and it shot open water. `tools/onboarding.sweep.ts`
    // is what said why: the first obstacle of the campaign reaches the frame at
    // 12.8-15.6 s depending on the seed, so a screen named for a rock was being
    // taken between one and four seconds before any rock existed. A wall-clock
    // number cannot know that; the condition can, and it is the same shape as the
    // one the rescue shot below already uses.
    // The band is where a wall composes rather than where it first exists: a
    // blob whose *centre* has come a third of the way down the frame is a wall
    // the shoal is visibly arriving at, and the top quarter is the banner's.
    play(24, false, () =>
      w.obstacles.sections.some((s) =>
        s.blobs.some((b) => {
          const y = w.worldToScreenY(b.y);
          return y > w.height * 0.3 && y < w.height * 0.55;
        }),
      ),
    );
  });
  expect(await page.evaluate(() => window.__slowblue!.world.run.phase)).toBe('running');
  await shootScreen(page, 'docs/screens/03-rock.png');

  // Same bot, now greedy, stopping the moment a pod's contact ring starts filling.
  const rescueState = await page.evaluate(() => {
    const w = window.__slowblue!.world;
    const play = (
      window as unknown as {
        __play: (s: number, g: boolean, stop?: () => boolean) => void;
      }
    ).__play;
    play(26, true, () => w.rescue.pods.some((p) => !p.merged && p.contact > 0.18));
    const pod = w.rescue.pods.find((p) => !p.merged && p.contact > 0.18);
    return { phase: w.run.phase, contact: pod?.contact ?? 0, rescued: w.run.rescued };
  });
  await shootScreen(page, 'docs/screens/04-rescue.png');
  expect(rescueState.phase).toBe('running');
  // Either mid-contact or already merged - both prove the rescue loop ran.
  expect(rescueState.contact > 0 || rescueState.rescued > 0).toBe(true);

  // 5. The split: shoal torn in two around a rock, a pod waiting in each channel.
  const splitState = await page.evaluate(() => {
    const t = window.__slowblue!;
    const w = t.world;
    w.reset(3);
    let cooldown = 0;
    for (let i = 0; i < 60 * 40; i++) {
      const c = w.swarm.centroid();
      if (c.count === 0) break;
      const rock = w.obstacles.sections.find(
        (s) => s.kind === 'rock' && !s.passed && s.lineY < c.y && c.y - s.lineY < 700,
      );
      cooldown -= 1 / 60;
      if (cooldown <= 0) {
        cooldown = 0.1;
        const fwd = w.worldToScreenY(c.y) > w.height * 0.55 ? -70 : -25;
        if (rock !== undefined) {
          let core = rock.blobs[0]!;
          for (const b of rock.blobs) if (b.r > core.r) core = b;
          const approach = c.y - rock.lineY;
          if (approach > 380) {
            const err = Math.max(-100, Math.min(100, core.x - c.x));
            w.injectStroke(c.x, c.y, c.x + err, c.y + fwd, 0.35);
          } else {
            w.injectStroke(c.x - 20, c.y, c.x - 110, c.y + fwd, 0.3);
            w.injectStroke(c.x + 20, c.y, c.x + 110, c.y + fwd, 0.3);
          }
        } else {
          w.injectStroke(c.x, c.y, c.x, c.y - 90, 0.4);
        }
      }
      t.advance(1 / 60);
      if (w.swarm.spread() > 118 && rock !== undefined && c.y - rock.lineY < 260) break;
    }
    return { spread: Math.round(w.swarm.spread()), phase: w.run.phase };
  });
  await shootScreen(page, 'docs/screens/06-split.png');
  expect(splitState.phase).toBe('running');

  // 6. The deep: a standing vortex and a hunter, in the zone that owns them.
  const deepState = await page.evaluate(() => {
    const t = window.__slowblue!;
    const w = t.world;
    w.reset(9);
    // Fast-forward the camera to the deep instead of playing four minutes to it.
    for (let i = 0; i < 60 * 3; i++) t.advance(1 / 60);
    const c = w.swarm.centroid();
    w.currents.add({
      x: w.width * 0.42,
      y: c.y - 210,
      radius: w.width * 0.34,
      strength: 150,
      sectionId: -1,
      phase: 0,
    });
    w.predators.spawn(w.width * 0.66, c.y - 130, 17, -1, 0);
    for (let i = 0; i < 60; i++) t.advance(1 / 60);
    return { predators: w.predators.predators.length, phase: w.run.phase };
  });
  expect(deepState.predators).toBeGreaterThan(0);
  await shootScreen(page, 'docs/screens/07-hunter.png');

  // 7. The reward: act I flown to its end, caught just after the shoal breaks out
  // into air. The sequence runs on the renderer's own clock, so this waits in wall
  // time rather than stepping the simulation - the water has already stopped.
  await page.evaluate(() => {
    const t = window.__slowblue!;
    t.restart(21);
    const w = t.world;
    const c = w.swarm.centroid();
    w.events.push({ type: 'complete', x: w.width * 0.5, y: c.y, value: 5 });
    w.run.complete();
  });
  // Read before the wait, not after it.
  //
  // This assertion used to sit under the screenshot and it was a race it
  // sometimes lost: finishing act I of the *campaign* hands over to act II, and
  // the handover starts a new run whose `completed` is false again. Four and a
  // half seconds is long enough for the ending to settle into its picture and
  // near enough to the handover that which of the two the read lands on is a coin
  // toss. The picture is not affected - the frame is still the surface - so this
  // was a flake in `npm run verify` reporting nothing about the game.
  expect(await page.evaluate(() => window.__slowblue!.metrics().completed)).toBe(true);
  await page.waitForTimeout(4600);
  await shootScreen(page, 'docs/screens/09-surface.png');

  // 8. Failure: one line of why, the score, and two ways back in.
  //
  // Through the `?act=` door rather than by restarting, and that is not tidiness.
  // The completed dive above was act I *of the campaign*, so it has already handed
  // over - restarting here would deal act II's air and shoot the water act's
  // results screen in the wrong act's language.
  await page.goto(`/?act=water&seed=${SEED}`);
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  await page.evaluate(() => window.__slowblue!.world.run.fail('sweptAway'));
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
  await expect(page.locator('.ui-score')).toBeVisible();
  await page.waitForTimeout(120);
  await shootScreen(page, 'docs/screens/05-game-over.png');

  /*
   * 10-11. The title and the circuit map of a player who has been round once.
   *
   * These two were shot by hand once and then nothing regenerated them, which
   * went unnoticed until act IV's verb changed and the act list carried on
   * printing the old one - a screen in the documentation making a claim the game
   * had stopped making. The map is where the campaign describes itself: how many
   * acts there are, how far round the player is, and what the act under the
   * cursor asks of them. It is exactly the screen that must not be a photograph
   * of an older build.
   *
   * The station record is written out rather than left to whatever this file
   * happened to play, and it is written *full*, because that is the only value
   * consistent with the rest of the fixture: `unlockedAct` can only ever be
   * raised by finishing an act, and a closed circuit means every one of them was
   * finished. A map with unflown stations on it needs a player who has not been
   * all the way round, which is `e2e/campaign.spec.ts`'s fixture, not this one.
   */
  await page.evaluate(() => {
    const profile = JSON.parse(localStorage.getItem('tide.profile') ?? '{}') as Record<
      string,
      unknown
    >;
    profile.unlockedAct = 6;
    profile.cycles = 1;
    profile.bestCampaign = 48210;
    profile.bestCargo = 214;
    profile.stations = { water: 6, air: 6, thin: 6, orbit: 6, reentry: 6, rain: 6, home: 6 };
    localStorage.setItem('tide.profile', JSON.stringify(profile));
  });
  await page.goto(`/?seed=${SEED}`);
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await page.waitForFunction(() => (window.__slowblue!.metrics().fps as number) > 0);
  await shootScreen(page, 'docs/screens/10-title.png');

  await page.getByRole('button', { name: /^the circuit\b/i }).click();
  await expect(page.locator('button.ui-map-act')).toHaveCount(7);
  await expect(page.locator('button.ui-map-act.locked')).toHaveCount(0);
  // The map is the screen; a shot of it without the world drawn is a shot of the
  // screen this one replaced.
  await expect(page.locator('svg.ui-map-world')).toBeVisible();
  // A closed circuit, so the bottom of the map - the join between act VII's last
  // stop and act I's first - is lit too.
  await expect(page.locator('path.ui-map-flown.close')).toHaveCount(1);
  await expect(page.locator('circle.ui-map-station.on')).toHaveCount(42);
  await shootScreen(page, 'docs/screens/11-circuit.png');

  console.log(
    WRITING_SCREENS
      ? 'docs/screens/: eleven screens rewritten'
      : 'docs/screens/: left alone - `npm run screens` regenerates them',
  );
  expect(errors).toEqual([]);
});
