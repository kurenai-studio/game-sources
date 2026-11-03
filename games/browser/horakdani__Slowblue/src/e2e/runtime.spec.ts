import { expect, test, type Page } from '@playwright/test';
import { boot, metrics } from './helpers';

/**
 * Slowblue: checks the things only a real animation loop can show - sustained frame
 * rate, the single idle hint that replaces a tutorial, and the clock stopping when
 * the page stops being the player's.
 */
test('holds a usable frame rate with the default shoal', async ({ page }) => {
  await boot(page);
  await page.waitForTimeout(3000);
  const m = await page.evaluate(() => window.__slowblue!.metrics());
  console.log(`[runtime] fps=${m.fps} time=${m.time} count=${m.count} dpr=${m.dpr}`);
  expect(m.time as number).toBeGreaterThan(2);
  // Headless compositing is not a phone, so this is a floor, not a target.
  expect(m.fps as number).toBeGreaterThan(30);
});

test('shows one idle hint after two seconds and drops it on first touch', async ({ page }) => {
  await boot(page);

  const hint = async (): Promise<number> => {
    return (await page.evaluate(() => window.__slowblue!.metrics().hint)) as number;
  };

  // Nothing before the idle threshold.
  expect(await hint()).toBeLessThan(0.2);
  await page.waitForFunction(() => (window.__slowblue!.metrics().hint as number) > 0.8, {
    timeout: 8000,
  });

  const vp = page.viewportSize()!;
  await page.mouse.move(vp.width * 0.5, vp.height * 0.7);
  await page.mouse.down();
  await page.mouse.move(vp.width * 0.6, vp.height * 0.7, { steps: 4 });
  await page.mouse.up();

  // The hint fades on touch and never returns for the rest of the session.
  await page.waitForFunction(() => (window.__slowblue!.metrics().hint as number) < 0.05, {
    timeout: 5000,
  });
  await page.waitForTimeout(2500);
  expect(await hint()).toBeLessThan(0.05);
});

test('holds its frame rate deep in the run, with hunters and standing currents up', async ({
  page,
}) => {
  await boot(page, 4242);
  // Jump the course forward rather than playing the whole campaign to reach the
  // trench: build every authored section at once and light up everything in them.
  const deep = await page.evaluate(() => {
    const t = window.__slowblue!;
    const w = t.world;
    w.obstacles.ensureAhead(-100000);
    for (const s of w.obstacles.sections) {
      for (const h of s.hunterHints) w.predators.spawn(h.x, h.y, h.size, s.id, 0);
      for (const v of s.vortexHints) {
        w.currents.add({ ...v, sectionId: s.id, phase: 0 });
      }
    }
    return {
      predators: w.predators.predators.length,
      vortices: w.currents.vortices.length,
      sections: w.obstacles.sections.length,
    };
  });
  expect(deep.sections).toBeGreaterThan(24);
  expect(deep.predators).toBeGreaterThan(2);
  expect(deep.vortices).toBeGreaterThan(2);

  await page.waitForTimeout(2500);
  const m = await page.evaluate(() => window.__slowblue!.metrics());
  console.log(`[runtime deep] fps=${m.fps} hunters=${m.predators} vortices=${m.vortices}`);
  expect(m.fps as number).toBeGreaterThan(30);
});

/** Holds `count` fingers still for `ms`, through CDP: Playwright's touchscreen is one finger. */
async function holdFingers(page: Page, count: number, ms: number): Promise<void> {
  const client = await page.context().newCDPSession(page);
  const vp = page.viewportSize()!;
  const points = Array.from({ length: count }, (_, i) => ({
    // High on the glass and spread out, away from the shell's own buttons: a tap
    // that lands on the primary would start a run and prove nothing.
    x: (vp.width * (i + 1)) / (count + 1),
    y: vp.height * 0.25,
  }));
  await client.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: points });
  await page.waitForTimeout(ms);
  await client.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await client.detach();
}

const ADMIN_TOGGLE = '.slowblue-admin-toggle';

/**
 * The way into the two panels on a device, and the two ways it must not open.
 *
 * A shipped app has no address bar, so `?debug=1` and `?admin` are not doors there -
 * and the act switcher is the thing an iPad round needs most. The gesture is what
 * replaces them, and the whole of its safety is in what it refuses: a third finger
 * held still for a second and a half, never while a run is live.
 *
 * A player stirs with one finger and sometimes two, which is the first assertion
 * here. The second is the one that matters more, because it is the one that would
 * hand a player a debug sheet in the middle of their own game.
 */
test('three fingers held off-run open the panels, and one finger never does', async ({ page }) => {
  await page.goto('/?seed=4242');
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await expect(page.locator('.ui-title')).toBeVisible();
  expect(await page.locator(ADMIN_TOGGLE).count()).toBe(0);

  // Longer than the hold, with the finger the game is actually played with.
  await holdFingers(page, 1, 1700);
  expect(await page.locator(ADMIN_TOGGLE).count()).toBe(0);

  await holdFingers(page, 3, 1700);
  await expect(page.locator(ADMIN_TOGGLE)).toBeVisible();
  // Both surfaces, not just the one the gesture is named after: the ⚙ panel is where
  // `p95 work` is read on the glass, and its green overlay is switched on with it.
  await expect(page.locator('.slowblue-debug.enabled')).toBeVisible();
});

test('the gesture stays out of a live run', async ({ page }) => {
  await boot(page, 4242);
  expect((await metrics(page)).mode).toBe('playing');
  await holdFingers(page, 3, 1700);
  expect(await page.locator(ADMIN_TOGGLE).count()).toBe(0);
  // ...and the fingers were still fingers: the water took them, which is what three
  // pointers on the canvas are for.
  expect((await metrics(page)).gestures as number).toBeGreaterThanOrEqual(3);
});

/**
 * The measurement door, which exists because the panel it duplicates cannot be
 * opened where the number matters.
 *
 * An installed PWA launches from its icon with no query string, so `?debug=1`
 * is unreachable on the device and `p95 work` has lived only in the ⚙ panel since
 * f0.12. What is asserted here is the part a console reading cannot check itself:
 * that pinning a rung actually moves the picture (the backing store shrinks by the
 * square of the dpr step) and that it throws the sample window away, so the next
 * reading is about the picture now on screen rather than an average of two.
 *
 * Rungs 2 and 3 are the pair that matters - same particle budget, dpr 1 against 0.8 -
 * because two readings across that step solve `frame = sim + area * draw` on the
 * device instead of borrowing the split from a headless browser.
 */
test('the perf door reads the frame, and pinning a rung resets what it reads', async ({ page }) => {
  await boot(page, 4242);
  await page.waitForTimeout(1500);

  const open = (await page.evaluate(() => window.__slowblue!.perf())) as Record<string, number>;
  expect(open.p95WorkMs).toBeGreaterThan(0);
  expect(open.pinned).toBe(false);
  expect(open.rung).toBe(0);
  expect(open.mpx).toBeGreaterThan(0);
  // The clamp, from the outside: this context asks for deviceScaleFactor 3 and the
  // renderer allocates at 2. A device with a denser panel draws no more pixels than
  // the SE 2 does, which is why the plan's DPR 3 column measures a picture the game
  // never draws. See main.ts `resize`.
  expect(open.dpr).toBe(2);

  // Pinned and read inside one turn, so no frame can run between the two: the point
  // is that the window is empty the instant the ladder moves, not a second later.
  const pinned = (await page.evaluate(() => {
    window.__slowblue!.pinQuality(3);
    return window.__slowblue!.perf();
  })) as Record<string, number>;
  expect(pinned.pinned).toBe(true);
  expect(pinned.rung).toBe(3);
  expect(pinned.p95WorkMs).toBe(0);
  // dpr 0.8 is 0.64 of the area. Rounding on two axes keeps it off the exact figure.
  expect(pinned.mpx / open.mpx).toBeGreaterThan(0.6);
  expect(pinned.mpx / open.mpx).toBeLessThan(0.68);

  // ...and it fills again from the picture that is on screen now.
  await expect
    .poll(async () => (await page.evaluate(() => window.__slowblue!.perf().p95WorkMs)) as number, {
      timeout: 5000,
    })
    .toBeGreaterThan(0);

  // A rung that does not exist is the last one, not a crash: QUALITY_RUNGS is indexed
  // with a non-null assertion, so an unclamped argument would throw inside the resize.
  const over = (await page.evaluate(() => {
    window.__slowblue!.pinQuality(99);
    return window.__slowblue!.perf();
  })) as Record<string, number>;
  expect(over.rung).toBe((over.rungs as number) - 1);

  const released = (await page.evaluate(() => {
    window.__slowblue!.pinQuality(null);
    return window.__slowblue!.perf();
  })) as Record<string, number>;
  expect(released.pinned).toBe(false);
});

/**
 * The same measurement, taken the way it will actually be taken: on the glass.
 *
 * `pinQuality` and `perf()` are console calls, and a console on an iPad is a Mac, a
 * cable, and a hand off the device between readings that are ten seconds of play
 * apart. The ⚙ panel could pin rung 0 and nothing else, so precisely the half that
 * solves the fill/sim split - the pair either side of the dpr step - was the half
 * still tied to a wire. Three taps replace it.
 *
 * Two claims, and the second is the one a console reading cannot make about itself:
 * that the row works the same lever the door does, and that the line the number is
 * copied off carries the area beside it. A p95 without an `mpx` is not comparable to
 * another device's row at all, which is the whole reason the iPad is being measured.
 */
test('the pin row moves the ladder, and the panel line carries the area', async ({ page }) => {
  await page.goto('/?debug=1&seed=4242');
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await page.locator('.slowblue-debug-toggle').click();

  const pin = (label: string) =>
    page.locator('.slowblue-debug-pins button').filter({ hasText: new RegExp(`^${label}$`) });

  const open = (await page.evaluate(() => window.__slowblue!.perf())) as Record<string, number>;
  expect(open.pinned).toBe(false);
  // The ladder needs 2.5 s under 45 fps to step down and this is the title screen a
  // moment after boot, so a rung other than 0 here is a broken test, not a slow host.
  expect(open.rung).toBe(0);
  await expect(pin('off')).toHaveClass(/on/);

  await pin('q3').click();
  const pinned = (await page.evaluate(() => window.__slowblue!.perf())) as Record<string, number>;
  expect(pinned.pinned).toBe(true);
  expect(pinned.rung).toBe(3);
  // The step itself, through the row: dpr 0.8 is 0.64 of the area, rounding on two
  // axes keeping it off the exact figure. Same assertion as the door's, same reason.
  expect(pinned.mpx / open.mpx).toBeGreaterThan(0.6);
  expect(pinned.mpx / open.mpx).toBeLessThan(0.68);

  const stats = page.locator('.slowblue-debug-stats');
  await expect(stats).toContainText('rung 3/4');
  await expect(stats).toContainText('pinned');
  await expect(stats).toContainText(/mpx \d+\.\d\d {2}zone \d+/);
  await expect(pin('q3')).toHaveClass(/on/);

  // The row asks the game which rung is held rather than remembering it, so the other
  // door moving the ladder lights the right button. Two memories would disagree, and
  // the one on screen would be the one believed.
  await page.evaluate(() => window.__slowblue!.pinQuality(2));
  await expect(pin('q2')).toHaveClass(/on/);
  await expect(pin('q3')).not.toHaveClass(/on/);

  await pin('off').click();
  const released = (await page.evaluate(() => window.__slowblue!.perf())) as Record<string, number>;
  expect(released.pinned).toBe(false);
  // Released, not reset: the ladder stays where it was let go of, and the line says so
  // without the word that would make a reading look pinned when it is not.
  expect(released.rung).toBe(2);
  await expect(stats).not.toContainText('pinned');
});

/**
 * The run that goes on without the player, which is the iPad case.
 *
 * `visibilitychange` is the whole of the lifecycle on a phone and half of it on a
 * tablet: Split View and Slide Over leave the page *visible* while the player is
 * in the app beside it, so nothing hides, nothing fires, and the ocean keeps
 * running with a hunter in it. The claim here is the one thing that proves the
 * gap is closed - not that a screen changed, but that the simulation clock stops.
 *
 * `blur` is dispatched rather than provoked because a headless browser has no
 * second app to switch to; it is the same event WebKit sends, and it is the same
 * compromise `unlock.spec.ts` makes with `visibilitychange`. What is *not*
 * simulated is the pause itself - the assertions read `time`, which only the loop
 * can move.
 */
test('stops the run when the page loses focus, and waits to be told to go on', async ({ page }) => {
  await boot(page, 4242);
  await page.waitForTimeout(600);
  const running = Number((await metrics(page)).time);
  expect(running).toBeGreaterThan(0.2);

  // The other app takes the keyboard. The page is still visible - no
  // `visibilitychange` here, which is exactly what makes this case its own.
  await page.evaluate(() => window.dispatchEvent(new Event('blur')));
  expect((await metrics(page)).mode).toBe('paused');
  const parked = Number((await metrics(page)).time);
  await page.waitForTimeout(700);
  // Better than a whole second of frames later, the clock has not moved.
  expect(Number((await metrics(page)).time)).toBe(parked);

  // Coming back is not resuming: a player handed a live ocean has already lost
  // whatever happened while they were reading. The same rule backgrounding follows.
  await page.evaluate(() => window.dispatchEvent(new Event('focus')));
  await page.waitForTimeout(400);
  expect((await metrics(page)).mode).toBe('paused');
  expect(Number((await metrics(page)).time)).toBe(parked);

  // ...and now they say so.
  await page.keyboard.press('Escape');
  expect((await metrics(page)).mode).toBe('playing');
  await expect
    .poll(async () => Number((await metrics(page)).time), { timeout: 5000 })
    .toBeGreaterThan(parked);
});
