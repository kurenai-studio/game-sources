import { expect, test, type Page } from '@playwright/test';
import { boot, collectErrors, metrics } from './helpers';

/**
 * What is left after the settings screen.
 *
 * It was one door on the title screen leading to a list of eleven things, and it
 * is now two surfaces, each one next to the thing it is about: the sound on the
 * glass, and the mode and the wipe on the map that draws the journey they change.
 *
 * These tests exist mostly to prove the *reachability* half of that claim. Moving
 * a control somewhere better and moving it somewhere nobody can find look identical
 * from inside the diff.
 */

const MUTE = '.ui-corner-mix';

/**
 * The title screen, with the audio context already open.
 *
 * No browser starts a sound on a page nobody has touched, so a launch is silent
 * until the first gesture whatever the settings say - which is a state of its own
 * and is tested below. This is the *other* state: a player who has touched the
 * screen once, which is every player by the time they are anywhere but the title,
 * and the one the mute half of this button is about. The press lands in the empty
 * top-left corner - no control is there, and both corner buttons are on the right -
 * so it is a real gesture that asks for nothing except the audio context.
 */
async function touched(page: Page): Promise<void> {
  await page.goto('/?skipIntro');
  await expect(page.locator('.ui-title')).toBeVisible();
  await page.mouse.click(10, 10);
  await expect.poll(async () => (await metrics(page)).audioUnlocked, { timeout: 10_000 }).toBe(true);
}

test('the sound button is on every screen, and mutes on the ones that are not a run', async ({
  page,
}) => {
  const errors = collectErrors(page);
  await touched(page);
  const mute = page.locator(MUTE);

  // The bed plays on the title screen - `pushBed` runs before the mode check in
  // main.ts - so until this button appeared off-run there was no way to stop it
  // without starting a run first.
  await expect(mute).toBeVisible();
  await expect(mute).toHaveAttribute('role', 'switch');
  await expect(mute).toHaveAttribute('aria-checked', 'true');
  // Not a drawer here. Claiming to expand tells a screen reader to wait for a
  // panel that is never coming.
  await expect(mute).not.toHaveAttribute('aria-expanded', /.*/);

  await mute.click();
  await expect(mute).toHaveAttribute('aria-checked', 'false');
  await expect(mute).toHaveClass(/muted/);
  await expect(page.locator('.ui-mix')).toBeHidden();
  expect(await page.evaluate(() => window.__slowblue?.metrics().screen)).toBe('title');
  expect(
    await page.evaluate(() => JSON.parse(localStorage.getItem('tide.settings') ?? '{}').muted),
  ).toBe(true);

  await mute.click();
  await expect(mute).toHaveAttribute('aria-checked', 'true');

  // ...and on the map, which is also not a run.
  await page.locator('.ui-journey').click();
  expect((await metrics(page)).screen).toBe('circuit');
  await expect(mute).toBeVisible();
  await expect(mute).toHaveAttribute('role', 'switch');
  expect(errors).toEqual([]);
});

/**
 * The launch nobody has touched yet, which is every launch.
 *
 * No browser opens an audio context on a page that has had no gesture, so the
 * title screen is silent for a moment however the game is configured - and this is
 * the moment the player is looking at the corner. The press there did the one
 * thing that could not help: it set `muted`, changed nothing anybody could hear,
 * and left the player pressing a second time to undo it. That is the report this
 * test is here for - "I have to press it twice".
 *
 * Both of its claims are about that press, and the second one is the correction to
 * a first attempt at the first. The button must not draw itself as switched off
 * while it waits, because a crossed-out speaker on the opening screen is a game
 * that appears to ship muted - which was the next thing reported, and fairly.
 */
test('the first press on a launch nobody has touched turns the sound on, not off', async ({
  page,
}) => {
  const errors = collectErrors(page);
  await page.goto('/?skipIntro');
  const mute = page.locator(MUTE);
  await expect(page.locator('.ui-title')).toBeVisible();

  // Nothing has been asked for and nothing is playing. Chromium's own autoplay
  // policy is doing this, not the test: no context has been allowed to open.
  expect((await metrics(page)).audioUnlocked).toBe(false);
  // ...and the corner does not report that as a setting. No slash, no dimming and
  // no "off" for a screen reader: the sound is on, the browser is the one waiting,
  // and the wait is over on the first touch of anything.
  await expect(mute).not.toHaveClass(/muted/);
  await expect(mute).toHaveAttribute('aria-checked', 'true');
  expect(
    await page.evaluate(() => JSON.parse(localStorage.getItem('tide.settings') ?? '{}').muted),
  ).toBeFalsy();

  await mute.click();
  await expect
    .poll(async () => (await metrics(page)).audioUnlocked, { timeout: 10_000 })
    .toBe(true);
  await expect(mute).toHaveAttribute('aria-checked', 'true');
  await expect(mute).not.toHaveClass(/muted/);
  expect(
    await page.evaluate(() => JSON.parse(localStorage.getItem('tide.settings') ?? '{}').muted),
  ).toBe(false);
  // And it is audible, not merely permitted: the bed is dealing voices into the
  // mixer, which `tick` only does while the context is genuinely running. The
  // floor is well above the handful the graph is built holding - see
  // `e2e/unlock.spec.ts`, which is also where the note on polling a Poisson
  // scheduler rather than sampling it lives.
  await expect
    .poll(async () => Number((await metrics(page)).audioVoices), { timeout: 20_000 })
    .toBeGreaterThan(20);
  expect(errors).toEqual([]);
});

test('in a run the same button is the drawer again, not a mute', async ({ page }) => {
  const errors = collectErrors(page);
  await boot(page);
  const mute = page.locator(MUTE);
  await expect(mute).toBeVisible();
  await expect(mute).toHaveAttribute('aria-expanded', 'false');
  await expect(mute).not.toHaveAttribute('role', 'switch');

  await mute.click();
  await expect(page.locator('.ui-mix')).toBeVisible();
  await expect(mute).toHaveAttribute('aria-expanded', 'true');
  // Opening the drawer must not have muted anything on the way past.
  expect(
    await page.evaluate(() => JSON.parse(localStorage.getItem('tide.settings') ?? '{}').muted),
  ).toBeFalsy();
  expect(errors).toEqual([]);
});

/**
 * What the drawer opens saying, and how big the thing you drag actually is.
 *
 * Two claims that are made in three files between them and are true in none of
 * them alone. The bed's held layers are switched off in `config/settings.ts`, the
 * act's own names for them come from `audio/Beds.ts`, and whether the row you see
 * agrees with either is a question only the built page can answer - which is
 * exactly the gap the dead `.ui-audio-toggle` rules sat in for four commits.
 *
 * The size is here rather than in the census next door because the census reports
 * the smallest live control in the shell and this is a claim about one control:
 * the fader is the row, all of it, and a change that quietly puts a column back
 * around it would pass every other test in the suite.
 */
test('the drawer opens with the held layers down, and the fader is the whole row', async ({
  page,
}) => {
  const errors = collectErrors(page);
  await boot(page);
  await page.locator(MUTE).click();
  await expect(page.locator('.ui-mix')).toBeVisible();

  // Act I, in the act's own words. Five layers and four game tracks, and the two
  // layers that never stop are the two that start off.
  const rows = page.locator('.ui-mix-list .ui-audio-track');
  await expect(rows).toHaveCount(9);
  const layer = (name: string): ReturnType<typeof page.getByRole> =>
    page.getByRole('switch', { name: new RegExp(`^${name}$`, 'i') });
  await expect(layer('Bubbles')).toHaveAttribute('aria-checked', 'true');
  await expect(layer('Deep drone')).toHaveAttribute('aria-checked', 'false');
  await expect(layer('Surface shimmer')).toHaveAttribute('aria-checked', 'false');
  await expect(layer('Distant bells')).toHaveAttribute('aria-checked', 'true');
  await expect(layer('Whale song')).toHaveAttribute('aria-checked', 'true');
  // ...and it is the stored setting that says so, not a class on a button.
  const stored = await page.evaluate(
    () => JSON.parse(localStorage.getItem('tide.settings') ?? '{}').audio,
  );
  expect(stored.drone.enabled).toBe(false);
  expect(stored.shimmer.enabled).toBe(false);
  expect(stored.ocean.enabled).toBe(true);

  // The fader is a finger tall and most of the drawer wide, and it stops clear of
  // the chip rather than under it.
  const row = rows.first();
  const box = await row.locator('input[type=range]').boundingBox();
  const chipBox = await row.locator('button').boundingBox();
  expect(box!.height).toBeGreaterThanOrEqual(44);
  expect(box!.width).toBeGreaterThan(180);
  expect(box!.x + box!.width).toBeLessThanOrEqual(chipBox!.x);

  // Dragging the row's own line moves that level and nothing else, and it is
  // written down where the next act will find it.
  await page.mouse.move(box!.x + box!.width * 0.5, box!.y + box!.height / 2);
  await page.mouse.down();
  await page.mouse.move(box!.x + box!.width * 0.25, box!.y + box!.height / 2, { steps: 8 });
  await page.mouse.up();
  await expect
    .poll(async () =>
      page.evaluate(
        () => JSON.parse(localStorage.getItem('tide.settings') ?? '{}').audio.ocean.volume,
      ),
    )
    .toBeLessThan(0.4);
  expect(
    await page.evaluate(
      () => JSON.parse(localStorage.getItem('tide.settings') ?? '{}').audio.ambience.volume,
    ),
  ).toBe(1);
  expect(errors).toEqual([]);
});

/**
 * The mode and the wipe, on the map.
 *
 * The one switch left changes what the game *is* rather than how it looks, so it
 * is chosen beside the button that commits to a run. The wipe is at the foot of
 * the same screen for the reason the old one was not: forty-two stations are drawn
 * directly above it, so "the whole journey?" has a subject.
 *
 * On a fresh profile neither is offered, so what this pins down is the empty case:
 * the map is a map with nothing hanging off it, and no list is held open for rows
 * that are not there yet.
 */
test('the circuit map offers neither the mode nor the wipe on a fresh profile', async ({
  page,
}) => {
  const errors = collectErrors(page);
  await page.goto('/?skipIntro');
  await page.locator('.ui-journey').click();

  // The map is a map first, and it opens with the map: no heading over a picture
  // that captions itself. The name it used to carry is on the dialog, where a
  // reader still gets it and nothing on the screen has to spend height on it.
  await expect(page.locator('.ui-heading')).toHaveCount(0);
  await expect(page.locator('.ui-panel')).toHaveAttribute('aria-label', /the circuit/i);
  await expect(page.locator('svg.ui-map-world')).toBeVisible();

  // Locked until a circuit has been closed: offering to remove the results screen
  // to somebody who has never reached one is offering nothing. With that the only
  // mode left, the list holding it is not built at all.
  await expect(
    page.getByRole('switch', { name: /continuous circuit/i }),
  ).toHaveCount(0);
  await expect(page.locator('.ui-list')).toHaveCount(0);
  // ...and so is the wipe, on a profile with nothing in it to lose.
  await expect(page.locator('.ui-btn.danger')).toHaveCount(0);
  expect(errors).toEqual([]);
});

test('the wipe asks twice, clears both stores, and disarms when left', async ({ page }) => {
  const errors = collectErrors(page);
  await page.goto('/?skipIntro');
  await page.evaluate(() => {
    localStorage.setItem(
      'tide.profile',
      JSON.stringify({
        version: 3,
        bestScore: 1200,
        bestDepth: 0,
        bestGates: 0,
        bestShoal: 0,
        deepestZone: 0,
        bestLevel: 0,
        completions: 1,
        runs: 3,
        totalRescued: 0,
        totalReforms: 0,
        totalSeconds: 0,
        seenHints: [],
        unlockedAct: 2,
        saved: null,
        bestCampaign: 900,
        bestCargo: 12,
        cycles: 1,
        stations: { water: 6, air: 3, thin: 0, orbit: 0, reentry: 0, rain: 0, home: 0 },
      }),
    );
    localStorage.setItem('tide.telemetry.v1', JSON.stringify({ runs: [{ seed: 1 }] }));
  });
  await page.goto('/?skipIntro&second=1');
  await page.locator('.ui-journey').click();

  // A closed circuit unlocks the second switch.
  await expect(
    page.getByRole('switch', { name: /continuous circuit/i }),
  ).toBeVisible();

  const danger = page.locator('.ui-btn.danger');
  await expect(danger).toHaveText(/erase every station/i);
  await danger.click();
  await expect(danger).toHaveText(/whole journey/i);

  // Leaving disarms it. A confirm that is still armed when you come back is a
  // confirm that goes off on a stray tap three screens later.
  await page.getByRole('button', { name: /^back$/i }).click();
  await page.locator('.ui-journey').click();
  await expect(page.locator('.ui-btn.danger')).toHaveText(/erase every station/i);

  await page.locator('.ui-btn.danger').click();
  await page.locator('.ui-btn.danger').click();

  // Both stores. A button that says it is erasing the whole journey and leaves a
  // row per run behind in telemetry is lying to somebody on a shared device.
  await expect
    .poll(async () =>
      page.evaluate(() => JSON.parse(localStorage.getItem('tide.profile') ?? 'null')?.runs ?? 0),
    )
    .toBe(0);
  expect(
    await page.evaluate(
      () => JSON.parse(localStorage.getItem('tide.telemetry.v1') ?? '{}').runs?.length ?? 0,
    ),
  ).toBe(0);
  expect(errors).toEqual([]);
});

/**
 * Setting off again, which is the map's other exit and is not the wipe.
 *
 * The two sit one press apart at the foot of the same screen and do opposite
 * things to a player's record - this one keeps every bit of it and throws away
 * only the circuit in progress. So what is asserted is the difference: that the
 * button appears only once there is a journey to put down, that it asks first,
 * that arming one question disarms the other, and that pressing it through opens
 * act I with the record still on disk.
 */
test('the map offers to start the journey again, and keeps the record when it does', async ({
  page,
}) => {
  const errors = collectErrors(page);

  // Nothing to put down yet: a fresh profile is offered no such thing.
  await page.goto('/?skipIntro');
  await page.locator('.ui-journey').click();
  await expect(
    page.getByRole('button', { name: /start a new journey/i }),
  ).toHaveCount(0);
  await page.getByRole('button', { name: /^back$/i }).click();

  // ...and now a circuit two acts in, with a record behind it.
  await page.evaluate(() => {
    localStorage.setItem(
      'tide.profile',
      JSON.stringify({
        version: 3,
        bestScore: 4200,
        runs: 9,
        unlockedAct: 2,
        cycles: 0,
        saved: {
          position: { act: 2, level: 3 },
          banked: 8800,
          cargo: 41,
          actsCleared: 2,
          completed: false,
          actStart: { cargo: 38, banked: 6100 },
          restarts: 1,
        },
        stations: { water: 6, air: 6, thin: 3, orbit: 0, reentry: 0, rain: 0, home: 0 },
      }),
    );
  });
  await page.goto('/?skipIntro&second=1');
  await page.locator('.ui-journey').click();

  const again = page.locator('.ui-btn.ui-restart');
  await expect(again).toBeVisible();
  await expect(again).toHaveText(/start a new journey/i);
  // It is not the destructive one, and must never be dressed as it.
  await expect(again).not.toHaveClass(/danger/);

  // Arming it disarms the wipe below, so the screen never asks two questions.
  const danger = page.locator('.ui-btn.danger');
  await danger.click();
  await expect(danger).toHaveText(/whole journey/i);
  await again.click();
  await expect(again).toHaveText(/back to act i/i);
  await expect(danger).toHaveText(/erase every station/i);

  // Leaving disarms it too.
  await page.getByRole('button', { name: /^back$/i }).click();
  await page.locator('.ui-journey').click();
  const armed = page.locator('.ui-btn.ui-restart');
  await expect(armed).toHaveText(/start a new journey/i);

  // Pressed through, it opens act I from the top - and takes nothing with it.
  await armed.click();
  await armed.click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  const m = await metrics(page);
  expect(m.act).toBe('water');
  expect(m.actIndex).toBe(0);
  expect(m.station).toBe(0);
  expect(m.banked).toBe(0);
  expect(m.campaign).toBe(true);
  expect(m.attempts, 'a fresh attempt').toBe(2);

  // The record is untouched: this is a restart, not a wipe.
  const kept = await page.evaluate(
    () => JSON.parse(localStorage.getItem('tide.profile') ?? '{}') as Record<string, unknown>,
  );
  expect(kept.bestScore).toBe(4200);
  expect(kept.runs).toBe(9);
  expect(kept.unlockedAct).toBe(2);
  expect(kept.stations).toMatchObject({ water: 6, air: 6, thin: 3 });
  expect(errors).toEqual([]);
});

/** The door that is gone, and must stay gone. */
test('there is no settings screen left to reach', async ({ page }) => {
  const errors = collectErrors(page);
  await page.goto('/?skipIntro');
  await expect(page.getByRole('button', { name: /^settings$/i })).toHaveCount(0);
  await boot(page);
  await page.locator('.ui-corner-pause').click();
  await expect(page.getByRole('button', { name: /^settings$/i })).toHaveCount(0);
  expect(errors).toEqual([]);
});
