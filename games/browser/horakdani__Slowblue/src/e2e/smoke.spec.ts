import { expect, test } from '@playwright/test';
import { boot, bootAct, collectErrors, completeAct, metrics } from './helpers';

test.describe('Slowblue mobile smoke', () => {
  test('loads, fills the viewport, and runs without console errors', async ({ page }) => {
    const errors = collectErrors(page);
    await boot(page);

    const canvas = page.locator('canvas#game');
    await expect(canvas).toBeVisible();
    const box = await canvas.boundingBox();
    const vp = page.viewportSize()!;
    expect(box!.width).toBeGreaterThan(vp.width - 2);
    expect(box!.height).toBeGreaterThan(vp.height - 2);

    const m = await metrics(page);
    expect(m.phase).toBe('running');
    expect(m.count as number).toBeGreaterThan(15);
    expect(m.seed).toBe(12345);
    expect(errors).toEqual([]);
  });

  test('the shell owns the viewport before a run and hands it back on start', async ({ page }) => {
    const errors = collectErrors(page);
    await page.goto('/?seed=12345');
    await page.waitForFunction(() => window.__slowblue !== undefined);

    // Title: the shell is up over a held first frame. Nothing in the run moves
    // or expires until the player actually starts it.
    await expect(page.locator('.ui')).toBeVisible();
    await expect(page.locator('canvas#game')).toBeHidden();
    expect((await metrics(page)).mode).toBe('attract');
    const held = (await metrics(page)).time;
    await page.waitForTimeout(350);
    expect((await metrics(page)).time).toBe(held);

    await page.locator('button.ui-btn.primary').first().click();
    await expect(page.locator('.ui')).toBeHidden();
    await expect(page.locator('canvas#game')).toBeVisible();
    await expect(page.locator('.ui-corner-pause')).toBeVisible();
    expect((await metrics(page)).mode).toBe('playing');
    await page.waitForFunction(() => (window.__slowblue!.metrics().time as number) > 0.2);
    expect(errors).toEqual([]);
  });

  test('a drag moves the water and the water moves the shoal', async ({ page }) => {
    const errors = collectErrors(page);
    await boot(page);
    const vp = page.viewportSize()!;

    const before = await metrics(page);
    expect(before.fieldMeanSpeed as number).toBeLessThan(0.01);

    const y = vp.height * 0.62;
    await page.mouse.move(vp.width * 0.22, y);
    await page.mouse.down();
    for (let i = 1; i <= 12; i++) {
      await page.mouse.move(vp.width * (0.22 + 0.05 * i), y);
      await page.waitForTimeout(16);
    }
    await page.mouse.up();

    const during = await metrics(page);
    expect(during.gestures as number).toBe(1);
    expect(during.fieldMeanSpeed as number).toBeGreaterThan(0.5);

    await page.waitForTimeout(450);
    const after = await metrics(page);
    // The shoal must have been carried to the right by the current.
    expect((after.centroidX as number) - (before.centroidX as number)).toBeGreaterThan(8);
    expect(errors).toEqual([]);
  });

  test('the page never scrolls or bounces', async ({ page }) => {
    await boot(page);
    const vp = page.viewportSize()!;
    await page.mouse.move(vp.width * 0.5, vp.height * 0.3);
    await page.mouse.down();
    await page.mouse.move(vp.width * 0.5, vp.height * 0.9, { steps: 10 });
    await page.mouse.up();
    const scroll = await page.evaluate(() => ({
      x: window.scrollX,
      y: window.scrollY,
      overflowY: getComputedStyle(document.body).overflowY,
      touchAction: getComputedStyle(document.querySelector('canvas#game')!).touchAction,
      docHeight: document.documentElement.scrollHeight,
      innerHeight: window.innerHeight,
    }));
    expect(scroll.x).toBe(0);
    expect(scroll.y).toBe(0);
    expect(scroll.overflowY).toBe('hidden');
    expect(scroll.touchAction).toBe('none');
    expect(scroll.docHeight).toBeLessThanOrEqual(scroll.innerHeight + 1);
  });

  test('a failed run offers the same water and new water, one tap each', async ({ page }) => {
    const errors = collectErrors(page);
    await boot(page);

    await page.evaluate(() => window.__slowblue!.world.run.fail('depleted'));
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
    await expect(page.locator('.ui-score')).toBeVisible();

    // First primary button: replay the same seed.
    await page.locator('button.ui-btn.primary').first().click();
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
    let m = await metrics(page);
    expect(m.seed).toBe(12345);
    expect(m.count as number).toBeGreaterThan(15);
    expect(m.time as number).toBeLessThan(1);

    // Second primary button: deal new water.
    await page.evaluate(() => window.__slowblue!.world.run.fail('depleted'));
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
    await page.locator('button.ui-btn.primary').nth(1).click();
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
    m = await metrics(page);
    expect(m.seed).not.toBe(12345);
    expect(errors).toEqual([]);
  });

  test('a run can be paused, resumed and abandoned', async ({ page }) => {
    const errors = collectErrors(page);
    await boot(page);

    await page.locator('.ui-corner-pause').click();
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'paused');
    const frozen = (await metrics(page)).time as number;
    await page.waitForTimeout(400);
    // A paused world does not advance.
    expect((await metrics(page)).time).toBe(frozen);

    await page.keyboard.press('Escape');
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
    await page.waitForTimeout(250);
    expect((await metrics(page)).time as number).toBeGreaterThan(frozen);

    await page.locator('.ui-corner-pause').click();
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'paused');
    await page.getByRole('button', { name: /quit/i }).click();
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'attract');
    await expect(page.locator('.ui-title')).toBeVisible();
    expect(errors).toEqual([]);
  });

  /**
   * The mixer on the glass, and the three things about it that are the feature:
   * it holds the water instead of pausing the game, it names the layers of the
   * act you are standing in, and what it changes is written down.
   *
   * The last of those used to be checked by opening the settings screen and
   * finding the same switch off there. There is no second mixer any more - it was
   * deleted with that screen - so the assertion goes to the store instead, which
   * is what the two copies were ever really being compared through.
   */
  test('the in-game mixer holds the water and names this act', async ({ page }) => {
    const errors = collectErrors(page);
    await boot(page);

    const drawer = page.locator('.ui-mix');
    await expect(drawer).toBeHidden();
    await page.locator('.ui-corner-mix').click();
    await expect(drawer).toBeVisible();
    // Not the pause screen: `mode` stays `playing`, so the HUD stays and the
    // audio graph is never parked - which is the whole reason for the drawer.
    expect((await metrics(page)).mode).toBe('playing');
    await expect(page.locator('.ui')).toBeHidden();
    // ...and the simulation is held, so nothing eats the shoal while somebody
    // takes a minute over a slider.
    const held = (await metrics(page)).time as number;
    await page.waitForTimeout(500);
    expect((await metrics(page)).time).toBe(held);

    // Act I, named as act I. The bed heading and the body layer are both the
    // deep's, not a generic "water".
    await expect(drawer.locator('.ui-mix-title')).toHaveText(/the deep/i);
    await expect(drawer.getByRole('switch', { name: /bubbles/i })).toBeVisible();
    // ...and act I has no motion layer, so the drawer does not draw a dead one.
    await expect(drawer.getByRole('switch', { name: /marine snow/i })).toHaveCount(0);

    // A layer switched off in the drawer is stored off, and is still off after
    // the drawer has been closed and reopened.
    await drawer.getByRole('switch', { name: /bubbles/i }).click();
    await expect(drawer.getByRole('switch', { name: /bubbles/i })).toHaveAttribute(
      'aria-checked',
      'false',
    );
    expect(
      await page.evaluate(
        () => JSON.parse(localStorage.getItem('tide.settings') ?? '{}').audio.ocean.enabled,
      ),
    ).toBe(false);
    await drawer.getByRole('button', { name: /close/i }).click();
    await expect(drawer).toBeHidden();
    await page.locator('.ui-corner-mix').click();
    await expect(drawer.getByRole('switch', { name: /bubbles/i })).toHaveAttribute(
      'aria-checked',
      'false',
    );
    expect(errors).toEqual([]);
  });

  /**
   * A fader has to survive being dragged.
   *
   * It did not. The slider passes `rerender = false` precisely so that Shell does
   * not redraw the node under the player's finger - but the change still went out
   * through `applySettings`, which called `setSettings` straight back, which called
   * `renderMix`, which called `replaceChildren`. The input was destroyed on the
   * first `input` event of the drag and the drag died with it. The guard that was
   * meant to prevent this named the settings screen, so it covered the mixer that
   * screen owned and left this one - which lives on `playing` - unprotected.
   *
   * The assertion that matters is node identity, not the value: a value can change
   * from one click on the track, which is what made the bug survive a tap test.
   */
  test('a fader can be dragged, and is not torn out mid-drag', async ({ page }) => {
    const errors = collectErrors(page);
    await boot(page);
    await page.locator('.ui-corner-mix').click();

    const slider = page.locator('.ui-mix input[type=range]').first();
    await expect(slider).toBeVisible();
    const box = (await slider.boundingBox())!;
    const y = box.y + box.height / 2;

    // Tag the live node. If the panel is rebuilt, the replacement will not have it.
    await slider.evaluate((el) => el.setAttribute('data-drag-witness', '1'));

    // Inside the track, not on its edge: a press on the boundary misses the input
    // altogether and the whole drag becomes a no-op that still passes a node check.
    await page.mouse.move(box.x + box.width * 0.9, y);
    await page.mouse.down();
    // Several moves, because one is a click and the bug only bit once the second
    // event arrived at a node that was no longer in the document.
    for (const at of [0.7, 0.5, 0.3, 0.15]) {
      await page.mouse.move(box.x + box.width * at, y, { steps: 4 });
    }
    await page.mouse.up();

    await expect(page.locator('.ui-mix input[data-drag-witness]')).toHaveCount(1);
    const value = Number(await slider.inputValue());
    expect(value).toBeGreaterThan(0);
    expect(value).toBeLessThan(40);
    // ...and the drag actually reached the engine rather than only the thumb.
    const stored = await page.evaluate(
      () => JSON.parse(localStorage.getItem('tide.settings') ?? '{}').audio.ocean.volume,
    );
    expect(stored).toBeCloseTo(value / 100, 2);
    expect(errors).toEqual([]);
  });

  test('the mixer follows the act it is standing in', async ({ page }) => {
    const errors = collectErrors(page);
    await bootAct(page, 'orbit');
    await page.locator('.ui-corner-mix').click();

    const drawer = page.locator('.ui-mix');
    await expect(drawer.locator('.ui-mix-title')).toHaveText(/orbit/i);
    // §13's three sounds, named. None of them can be in act I and none of act I's
    // can be here - which is the whole bug this drawer made visible.
    await expect(drawer.getByRole('switch', { name: /heartbeat/i })).toBeVisible();
    await expect(drawer.getByRole('switch', { name: /whistler/i })).toBeVisible();
    await expect(drawer.getByRole('switch', { name: /whale song/i })).toHaveCount(0);
    expect(errors).toEqual([]);
  });

  /**
   * Settings survive a reload - now gathered from the three places they ended up
   * in rather than from the one list they used to share.
   *
   * A fader and a track switch in the drawer, which is inside a run, and the mute
   * on the glass, which is the only one reachable from the title screen. Between
   * them they cover both shapes the store now holds: a number and a boolean.
   */
  test('settings persist across a reload', async ({ page }) => {
    const errors = collectErrors(page);
    await boot(page);
    await page.locator('.ui-corner-mix').click();
    const drawer = page.locator('.ui-mix');

    const oceanVolume = page.locator('#audio-ocean-volume');
    await oceanVolume.fill('37');
    await expect(oceanVolume).toHaveValue('37');

    const danger = drawer.getByRole('switch', { name: /danger/i });
    await expect(danger).toHaveAttribute('aria-checked', 'true');
    await danger.click();
    await expect(
      drawer.getByRole('switch', { name: /danger/i }),
    ).toHaveAttribute('aria-checked', 'false');

    await drawer.getByRole('button', { name: /close/i }).click();

    await page.goto('/?seed=12345&second=1');
    await page.waitForFunction(() => window.__slowblue !== undefined);
    expect(
      await page.evaluate(() => JSON.parse(localStorage.getItem('tide.settings') ?? '{}')),
    ).toMatchObject({
      audio: { ocean: { volume: 0.37 }, danger: { enabled: false } },
    });

    // ...and the one that can be set without a run at all.
    //
    // The tap in the corner of the screen first, because on a page nobody has
    // touched this button is not a mute: no browser has opened an audio context
    // yet, the game is silent already, and the press means "let me hear it"
    // rather than "stop". A player is past that the moment they touch anything -
    // which is what this is - and from there the corner is the mute it was. See
    // `e2e/shell.spec.ts`.
    await page.mouse.click(10, 10);
    await expect.poll(async () => (await metrics(page)).audioUnlocked).toBe(true);
    await page.locator('.ui-corner-mix').click();
    await page.goto('/?seed=12345&third=1');
    await page.waitForFunction(() => window.__slowblue !== undefined);
    await expect(page.locator('.ui-corner-mix')).toHaveClass(/muted/);
    expect(errors).toEqual([]);
  });

  test('a personal best survives a reload', async ({ page }) => {
    await boot(page);
    await page.evaluate(() => {
      window.__slowblue!.world.run.score = 4321;
      window.__slowblue!.world.run.fail('depleted');
    });
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
    await expect(page.locator('.ui-record')).toBeVisible();

    await page.reload();
    await page.waitForFunction(() => window.__slowblue !== undefined);
    expect((await metrics(page)).bestScore as number).toBeGreaterThan(4000);
    await expect(page.locator('.ui-best')).toBeVisible();
  });

  test('touch input drives the simulation too', async ({ page }) => {
    await boot(page, 777);
    const vp = page.viewportSize()!;
    const client = await page.context().newCDPSession(page);
    const y = vp.height * 0.6;
    await client.send('Input.dispatchTouchEvent', {
      type: 'touchStart',
      touchPoints: [{ x: vp.width * 0.25, y }],
    });
    for (let i = 1; i <= 8; i++) {
      await client.send('Input.dispatchTouchEvent', {
        type: 'touchMove',
        touchPoints: [{ x: vp.width * (0.25 + 0.06 * i), y }],
      });
      await page.waitForTimeout(16);
    }
    await client.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    const m = await metrics(page);
    expect(m.gestures as number).toBeGreaterThanOrEqual(1);
    expect(m.fieldMeanSpeed as number).toBeGreaterThan(0.5);
  });

  test('touch unlocks audio again after a mobile interruption', async ({ page }) => {
    await page.addInitScript(() => {
      const audioWindow = window as typeof window & {
        __audioProbe?: AudioContext;
      };
      Object.defineProperty(audioWindow.navigator, 'audioSession', {
        configurable: true,
        value: { type: 'auto' },
      });
      const Native = audioWindow.AudioContext;
      audioWindow.AudioContext = class extends Native {
        constructor() {
          super();
          audioWindow.__audioProbe = this;
        }
      } as typeof AudioContext;
    });
    await boot(page, 888);
    await page.waitForFunction(
      () =>
        (window as typeof window & { __audioProbe?: AudioContext }).__audioProbe?.state ===
        'running',
    );
    // `playback`, which overrules the hardware silent switch. This asserted
    // `ambient` for a while, and the web build that shipped with it was silent on
    // every iPhone kept on silent - which is most of them. See `setAudioSession`.
    expect(
      await page.evaluate(
        () =>
          (
            navigator as Navigator & {
              audioSession?: { type: string };
            }
          ).audioSession?.type,
      ),
    ).toBe('playback');

    // Suspended by hand, and that is the whole reason the tap below is still
    // required. The engine recovers itself from WebKit's `interrupted` - a call
    // arriving - and deliberately from nothing else, because every other route
    // into a stopped context is one somebody asked for. See `onStateChange`.
    await page.evaluate(async () => {
      await (window as typeof window & { __audioProbe?: AudioContext }).__audioProbe?.suspend();
    });
    expect(
      await page.evaluate(
        () => (window as typeof window & { __audioProbe?: AudioContext }).__audioProbe?.state,
      ),
    ).toBe('suspended');

    const vp = page.viewportSize()!;
    await page.touchscreen.tap(vp.width * 0.5, vp.height * 0.6);
    await page.waitForFunction(
      () =>
        (window as typeof window & { __audioProbe?: AudioContext }).__audioProbe?.state ===
        'running',
    );
  });

  test('telemetry export produces local JSON only', async ({ page }) => {
    await boot(page);
    const requests: string[] = [];
    page.on('request', (r) => {
      if (!r.url().startsWith('http://127.0.0.1:4173')) requests.push(r.url());
    });
    await page.evaluate(() => window.__slowblue!.world.run.fail('depleted'));
    // The run record is written on the frame that observes the phase change.
    await page.waitForFunction(() => {
      const parsed = JSON.parse(window.__slowblue!.exportTelemetry()) as { runs: unknown[] };
      return parsed.runs.length > 0;
    });
    const json = await page.evaluate(() => window.__slowblue!.exportTelemetry());
    const parsed = JSON.parse(json) as { runs: unknown[]; version: number };
    expect(parsed.version).toBe(1);
    expect(parsed.runs.length).toBeGreaterThan(0);
    expect(requests).toEqual([]);
  });

  test('an act played on its own gets its own mission-complete ending', async ({ page }) => {
    // Through the `?act=` door, so this is one act rather than the first leg of a
    // circuit - which is the only way act I still has an ending of its own.
    await bootAct(page, 'water', 6000);
    await completeAct(page);
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
    // The pause button goes with the water: for the length of the ending there is
    // nothing on the glass but the sequence.
    await expect(page.locator('.ui-corner-pause')).toBeHidden();
    const surface = page.locator('.ui.surfaced');
    // The whole surfacing sequence - lift, ascent, breach, sky - runs before the
    // results arrive. Six and a half seconds of it, deliberately.
    await expect(surface).toBeVisible({ timeout: 12_000 });
    await expect(surface.locator('.ui-complete-kicker')).toHaveText(
      /mission complete/i,
    );
    await expect(surface.locator('.ui-heading')).toHaveText(/surface/i);
  });

  /**
   * The seam, and the thing the whole campaign is: an act that was flown to its
   * end is not a run that finished. Nothing is put over the picture and nothing is
   * asked of the player - the film plays out and the next act's water is simply
   * there.
   */
  test('a finished act hands over to the next one without a dialog', async ({ page }) => {
    const errors = collectErrors(page);
    await boot(page, 6000);
    expect((await metrics(page)).act).toBe('water');
    const carried = (await metrics(page)).count as number;

    await completeAct(page);
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
    // Nothing on the glass for the length of the film: no panel, no pause button.
    await expect(page.locator('.ui-corner-pause')).toBeHidden();
    await expect(page.locator('.ui')).toBeHidden();

    await page.waitForFunction(() => window.__slowblue!.metrics().act === 'air', null, {
      timeout: 15_000,
    });
    const m = await metrics(page);
    expect(m.mode).toBe('playing');
    expect(m.actIndex).toBe(1);
    expect(m.actsCleared).toBe(1);
    // The gold does not restart: act II opens on what act I handed over.
    expect(m.cargo as number).toBe(carried);
    expect(m.count as number).toBeGreaterThan(15);
    // ...and the shell never came up at any point in between.
    await expect(page.locator('.ui')).toBeHidden();
    expect(errors).toEqual([]);
  });

  /**
   * §12: runs started from the admin surface or the dev door never touch personal
   * records. The door plays the real act in the real world - that is the point of
   * it - so the profile is the only thing that has to stay honest.
   */
  test('an act opened through the dev door touches no record', async ({ page }) => {
    await boot(page, 4242);
    await page.evaluate(() => {
      window.__slowblue!.world.run.earned = 5555;
      window.__slowblue!.world.run.recomputeScore(0);
      window.__slowblue!.world.run.fail('depleted');
    });
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
    const earned = (await metrics(page)).bestScore as number;
    expect(earned).toBeGreaterThanOrEqual(5555);

    await bootAct(page, 'orbit', 4242);
    await page.evaluate(() => {
      window.__slowblue!.world.run.earned = 99_999;
      window.__slowblue!.world.run.recomputeScore(0);
      window.__slowblue!.world.run.fail('depleted');
    });
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
    await expect(page.locator('.ui-score')).toBeVisible();
    const after = await metrics(page);
    // The results screen still shows what happened. The profile does not.
    expect(after.bestScore).toBe(earned);
    expect(after.campaign).toBe(false);
    await expect(page.locator('.ui-record')).toBeHidden();
  });

  test('ships an installable manifest and an offline worker', async ({ page }) => {
    await page.goto('/');
    const manifest = await page.evaluate(async () => {
      const res = await fetch('/manifest.webmanifest');
      return { ok: res.ok, body: (await res.json()) as Record<string, unknown> };
    });
    expect(manifest.ok).toBe(true);
    expect(manifest.body.name).toBe('Slowblue');
    expect((manifest.body.icons as unknown[]).length).toBeGreaterThanOrEqual(3);
    const sw = await page.evaluate(async () => (await fetch('/sw.js')).ok);
    expect(sw).toBe(true);
  });
});
