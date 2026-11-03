import { expect, test, type Page } from '@playwright/test';
import { loadBundleMaps, type SourceMap } from './sourcemap';

/**
 * The evidence suite: what this game actually costs, measured rather than claimed.
 *
 * Everything in here exists because a criterion was being asserted in prose. The
 * loop is a fixed-timestep accumulator, the render path allocates nothing, the
 * canvas is sharp on retina, the app works with no signal, the player is playing
 * inside three seconds - all of that was true in the README and nowhere else.
 *
 * These tests therefore *print* before they assert. The number in the log is the
 * product; the `expect` under it is a budget loose enough that it cannot start
 * failing for reasons unrelated to what the number says. Both of the floors this
 * file opened with are now budgets - startup a hard 3 s gate, allocation a
 * regression guard - and both were set from a measured baseline rather than
 * chosen, which is what this file is for.
 *
 * The allocation half carries one warning that cost a day to learn and is written
 * out in full at `warmFramePath`: a sampling profile taken before V8 has finished
 * compiling the frame path is not a measurement of the game. It over-reports by
 * an order of magnitude, and its list of sites names whichever builtin the
 * compiler was standing in at the time. A site list from a cold sample is not a
 * list of things to fix.
 *
 * Headless Chromium on a laptop is not a phone, and none of these numbers should
 * be read as one. They are a baseline on one machine that the next change is
 * compared against.
 */

/**
 * The startup gate criterion 5 asks for, and the two segments it is spent on.
 *
 * The criterion says gameplay inside three seconds. What it does not say, and what
 * this file had to be told, is where that clock starts. It starts at the title
 * screen. The studio ident and the sound card in front of it are the game's
 * opening, not its loading: they are kept, deliberately, and they are not charged
 * to this budget - a player is reading and listening through both, and any of it
 * is one tap away from being over.
 *
 * So the same three seconds are asked of two things instead, and both are gated:
 * getting the title screen onto the glass, and getting from the press on it into
 * moving fish. What the budget refuses to cover is the seven seconds the studio's
 * name is on screen. `first launch` below measures those anyway, so the exclusion
 * is a number in the log rather than something this comment merely claims.
 */
const TTI_BUDGET_MS = 3000;
/** Frames per allocation sample. 600 = ten seconds of play at 60 Hz. */
const ALLOC_FRAMES = 600;

declare global {
  interface Window {
    /** Set by the init script in `instrumentStartup`, before any app code runs. */
    __startup?: { ready?: number; tapped?: number; playing?: number };
    /** Installed by `installSteering`: one stroke of a competent player's finger. */
    __steer?: () => void;
  }
}

/* ------------------------------------------------------------------ startup */

/**
 * Installs the startup probe before the document exists.
 *
 * The timing cannot be taken from the outside. `waitForFunction` polls on the
 * driver's clock across a websocket, so what it measures is the round trip plus
 * the poll interval, and both of those are larger than the difference this test
 * is meant to detect. A rAF poll inside the page reads `performance.now()` - a
 * clock whose zero *is* navigation start - on the same frame the condition
 * becomes true.
 *
 * Three marks, because they are three different questions. `ready` is when the
 * game can be tapped: the module has run, the world exists, the title screen is
 * on the glass. `tapped` is when the player pressed play. `playing` is when the
 * fish are moving. A player spends real seconds between the first two reading a
 * screen and the driver spends a websocket round trip, so the budget is measured
 * across `tapped -> playing`, which contains neither.
 *
 * `ready` watches for the primary button rather than for `.ui-title`, because the
 * sound card carries a `.ui-title` of its own - on the launch that actually shows
 * the card, the old condition marked the game ready while the card was still up
 * and nothing was pressable for another three and a half seconds. The card has
 * nothing to press; the title screen does. That is the difference worth reading.
 */
async function instrumentStartup(page: Page): Promise<void> {
  await page.addInitScript(() => {
    const marks: { ready?: number; tapped?: number; playing?: number } = {};
    window.__startup = marks;
    // Capture phase, and the first of the two events that a press produces: what
    // is wanted is the instant the glass was touched, not the instant the shell's
    // own handler got round to it.
    const press = (e: Event): void => {
      const target = e.target instanceof Element ? e.target : null;
      if (marks.tapped !== undefined || target === null) return;
      if (target.closest('button.ui-btn.primary') !== null) marks.tapped = performance.now();
    };
    addEventListener('pointerdown', press, { capture: true });
    addEventListener('click', press, { capture: true });
    const poll = (): void => {
      const play = document.querySelector('button.ui-btn.primary');
      if (marks.ready === undefined && window.__slowblue !== undefined && play !== null) {
        if (play.getClientRects().length > 0) marks.ready = performance.now();
      }
      if (window.__slowblue?.metrics().mode === 'playing') {
        marks.playing = performance.now();
        return;
      }
      requestAnimationFrame(poll);
    };
    requestAnimationFrame(poll);
  });
}

interface StartupTimings {
  readyMs: number;
  tappedMs: number;
  playingMs: number;
  domContentLoadedMs: number;
  loadMs: number;
  scriptKb: number;
  scriptMs: number;
  transferredKb: number;
}

/** Loads the page, taps start the way `helpers.boot` does, and reads the marks. */
async function timeStartup(page: Page, url = '/'): Promise<StartupTimings> {
  await page.goto(url);
  await page.waitForFunction(() => window.__startup?.ready !== undefined);
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__startup?.playing !== undefined);

  return page.evaluate(() => {
    const marks = window.__startup!;
    const nav = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
    const res = performance.getEntriesByType('resource') as PerformanceResourceTiming[];
    const script = res.find((r) => r.name.endsWith('.js') && !r.name.endsWith('sw.js'));
    const kb = (n: number): number => Math.round(n / 102.4) / 10;
    return {
      readyMs: Math.round(marks.ready!),
      tappedMs: Math.round(marks.tapped!),
      playingMs: Math.round(marks.playing!),
      domContentLoadedMs: Math.round(nav.domContentLoadedEventEnd),
      loadMs: Math.round(nav.loadEventEnd),
      // Transfer size is 0 for a cache hit, which is the point of measuring warm.
      scriptKb: kb(script?.transferSize ?? 0),
      scriptMs: Math.round(script?.duration ?? 0),
      transferredKb: kb(nav.transferSize + res.reduce((sum, r) => sum + r.transferSize, 0)),
    };
  });
}

/** The gated pair, pulled out because two tests below assert the same two things. */
function segments(t: StartupTimings): { toTitleMs: number; toPlayMs: number } {
  return { toTitleMs: t.readyMs, toPlayMs: t.playingMs - t.tappedMs };
}

test.describe('startup', () => {
  test('reaches gameplay, cold and warm, inside a stated budget', async ({ page, context }) => {
    await instrumentStartup(page);

    const cold = await timeStartup(page);
    console.log(
      `[startup cold] ${JSON.stringify({ ...cold, ...segments(cold), budgetMs: TTI_BUDGET_MS })}`,
    );

    // Warm is what an installed app does on every launch after the first: the
    // worker is active, the bundle is in the cache, nothing is transferred. It is
    // the number the 2-3 second criterion is really about, and it is only
    // reachable *after* a load that the worker was allowed to see.
    await page.evaluate(async () => {
      await navigator.serviceWorker.ready;
    });
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    const warm = await timeStartup(page);
    console.log(
      `[startup warm] ${JSON.stringify({ ...warm, ...segments(warm), budgetMs: TTI_BUDGET_MS })}`,
    );

    // The budget, no longer a floor. Both halves of the launch are held to the
    // same three seconds: reaching a title screen that can be pressed, and the
    // press itself turning into moving fish. The bundle is precached and the
    // sourcemap is off the wire, so this is now a number the machine that has to
    // pass it does pass - with room, which is what makes a regression legible.
    expect(cold.readyMs).toBeLessThan(TTI_BUDGET_MS);
    expect(warm.readyMs).toBeLessThan(TTI_BUDGET_MS);
    expect(cold.playingMs - cold.tappedMs).toBeLessThan(TTI_BUDGET_MS);
    expect(warm.playingMs - warm.tappedMs).toBeLessThan(TTI_BUDGET_MS);
    // Warm has no excuse at all: nothing is transferred, so the whole launch
    // fits inside the budget end to end.
    expect(warm.playingMs).toBeLessThan(TTI_BUDGET_MS);
    // And the guard that was here before the budget was, kept because the budget
    // is generous where this segment is not: pressing play costs tens of
    // milliseconds today, so three seconds would not notice it becoming one.
    expect(cold.playingMs - cold.readyMs).toBeLessThan(1500);
    await context.close();
  });

  /**
   * What the very first launch costs, ident and sound card included.
   *
   * Reported, not gated, and the two are the same decision: the opening is kept,
   * so the seconds it takes are not a defect to hold a budget against - but they
   * are also not seconds to leave unmeasured, because "the budget starts at the
   * title screen" is only honest if the part in front of it has a number too.
   *
   * The run is unhurried on purpose. Both screens are one tap from over, and an
   * impatient player is the fast case; this is the slow one, which is the ceiling.
   * `?intro=full&sound=ask` is how an automated browser asks for the launch a
   * phone gets - webdriver skips both by default, which is why every other spec
   * in this suite arrives straight at the title.
   */
  test('reports what the first launch costs before the title screen', async ({ page, context }) => {
    await instrumentStartup(page);
    const first = await timeStartup(page, '/?intro=full&sound=ask');
    console.log(
      `[startup first launch] ${JSON.stringify({ ...first, ...segments(first), budgetMs: TTI_BUDGET_MS })}`,
    );

    // Not a budget - a check that the number above is of the thing it says. The
    // ident is 7.1 s and the card holds for 3.6 s after it, so a title screen
    // that arrived before the ident ended means neither actually played.
    expect(first.readyMs).toBeGreaterThan(7100);
    // The budgeted segment is the budgeted segment on this launch too.
    expect(first.playingMs - first.tappedMs).toBeLessThan(TTI_BUDGET_MS);
    await context.close();
  });
});

/* --------------------------------------------------------------- allocation */

interface HeapNode {
  callFrame: { functionName: string; url: string; lineNumber: number; columnNumber: number };
  selfSize: number;
  children: HeapNode[];
}

/** Loaded once: 2.3 MB of JSON, and both allocation tests want the same names. */
const bundleMaps: Map<string, SourceMap> = loadBundleMaps();

/**
 * Turns one sampled frame into something a person can go and open.
 *
 * A minified frame is `sample @ index-CnLPu3j1.js:2`, and every frame in the
 * bundle is on line 2 - so the file and line say nothing and the name says
 * whatever survived mangling. With the map on disk the same frame becomes
 * `sample @ FlowField.ts:77`, which is the difference between a number and a
 * work item. The mangled name is kept alongside when the map disagrees, because
 * the map names the *expression* at that column and V8 names the *function*, and
 * seeing both is what tells you an attribution is inlined rather than real.
 */
function describeFrame(f: HeapNode['callFrame']): string {
  const file = f.url.split('/').pop() ?? '(anonymous)';
  const fn = f.functionName === '' ? '(top level)' : f.functionName;
  const origin = bundleMaps.get(file)?.lookup(f.lineNumber, f.columnNumber);
  if (origin === null || origin === undefined) {
    // Builtins have no url and no mapping: `Math.hypot` reports as `hypot @ :0`.
    return `${fn} @ ${file === '' ? '(builtin)' : file}:${f.lineNumber + 1}`;
  }
  const named = origin.name !== null && origin.name !== fn ? `${fn} (${origin.name})` : fn;
  return `${named} @ ${origin.source}:${origin.line}`;
}

/** Flattens V8's sampling profile into `site -> bytes`, deepest frame wins. */
function allocationSites(root: HeapNode): Map<string, number> {
  const out = new Map<string, number>();
  const walk = (node: HeapNode): void => {
    if (node.selfSize > 0) {
      const key = describeFrame(node.callFrame);
      out.set(key, (out.get(key) ?? 0) + node.selfSize);
    }
    for (const child of node.children) walk(child);
  };
  walk(root);
  return out;
}

function totalBytes(sites: Map<string, number>): number {
  let sum = 0;
  for (const bytes of sites.values()) sum += bytes;
  return sum;
}

/**
 * Bytes allocated per frame, with the stacks that allocated them.
 *
 * V8's sampling heap profiler is the right instrument here and a heap-size delta
 * is the wrong one: what criterion 3 forbids is *allocation*, and a heap that
 * ends the run the size it started can have churned megabytes through the
 * nursery on the way. Sampling counts allocations as they happen, with the stack
 * that made each one, which is also the only form of this measurement that says
 * what to go and fix.
 *
 * The frames are driven through `__slowblue.advance` rather than rAF, so the count
 * is exact and the driver's own traffic is not inside the window. One
 * `advance(1/60)` is one fixed step, one event drain, one render and the bed
 * push - the whole per-frame path the game actually runs.
 *
 * The empty loop is measured first and subtracted, so the harness is not in the
 * number. The names in the list are what survived minification: methods keep
 * their names, standalone functions do not, so a `Qt` is a real site that this
 * measurement cannot name without a sourcemap reader.
 */
async function sampleAllocations(
  page: Page,
  label: string,
): Promise<{ perFrame: number; sites: [string, number][] }> {
  const client = await page.context().newCDPSession(page);
  await client.send('HeapProfiler.enable');

  await client.send('HeapProfiler.startSampling', { samplingInterval: 128 });
  await page.evaluate((n) => {
    for (let i = 0; i < n; i++) void i;
  }, ALLOC_FRAMES);
  const idle = await client.send('HeapProfiler.stopSampling');

  await client.send('HeapProfiler.startSampling', { samplingInterval: 128 });
  await page.evaluate((n) => {
    const tide = window.__slowblue!;
    for (let i = 0; i < n; i++) {
      if (i % 12 === 0) window.__steer!();
      tide.advance(1 / 60);
    }
  }, ALLOC_FRAMES);
  const busy = await client.send('HeapProfiler.stopSampling');
  await client.detach();

  const idleBytes = totalBytes(allocationSites(idle.profile.head as HeapNode));
  const sites = allocationSites(busy.profile.head as HeapNode);
  const bytes = totalBytes(sites) - idleBytes;
  const perFrame = Math.round(bytes / ALLOC_FRAMES);
  const top = [...sites.entries()].sort((a, b) => b[1] - a[1]).slice(0, 10);

  console.log(
    `[allocation ${label}] ${JSON.stringify({
      frames: ALLOC_FRAMES,
      perFrameBytes: perFrame,
      totalKb: Math.round(bytes / 1024),
      idleKb: Math.round(idleBytes / 1024),
    })}`,
  );
  for (const [site, size] of top) {
    console.log(`[allocation ${label} site] ${site} = ${Math.round(size / ALLOC_FRAMES)} B/frame`);
  }
  return { perFrame, sites: top };
}

async function playFrom(page: Page, seed: number): Promise<void> {
  await page.goto(`/?seed=${seed}`);
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
}

/**
 * Puts a finger on the glass, in the one way that keeps a run alive.
 *
 * Both allocation tests need a shoal that is still being played ten seconds from
 * now, and neither of them had one: with nobody steering, the forced drift takes
 * the ground back and `sweptAway` ends the run part-way through the sample. The
 * previous version of this file measured that without noticing, because nothing
 * asked afterwards whether the game was still running.
 *
 * So the probe steers. A stroke from the shoal to a point up the course is
 * exactly what `InputController` hands the world when a person drags, and it is
 * signed by `act.direction` for the same reason everything else in the sim is -
 * "forward" is down the screen for half the campaign. This also puts the gesture
 * path inside the sample, which the comment below has always claimed and which
 * was in truth only ever in the frames before it.
 */
async function installSteering(page: Page): Promise<void> {
  await page.evaluate(() => {
    window.__steer = () => {
      const w = window.__slowblue!.world;
      const c = w.swarm.centroid();
      if (c.count === 0) return;
      // The nearest un-absorbed mandatory ring ahead, chosen exactly as
      // `tests/bot.ts` chooses it. A finger that only pushes up the course is not
      // a player: it flies past the dashed rings, and act I ends the run on the
      // first one it loses. That is what this probe was doing - `ringMissed`,
      // every time, about four seconds into a ten-second sample.
      let ringX: number | null = null;
      let bestDy = Infinity;
      for (const p of w.rescue.pods) {
        if (p.merged || !p.required) continue;
        const dy = w.u(p.y) - w.u(c.y);
        if (dy < -140 || dy > 700) continue;
        if (dy < bestDy) {
          bestDy = dy;
          ringX = p.x;
        }
      }
      const errX = (ringX ?? c.x) - c.x;
      if (Math.abs(errX) > 12) {
        w.injectStroke(c.x, c.y, c.x + Math.max(-110, Math.min(110, errX)), c.y, 0.09);
      } else if (w.behindFraction(w.worldToScreenY(c.y)) > 0.6) {
        w.injectStroke(c.x, c.y, c.x, c.y + w.act.direction * 90, 0.09);
      }
    };
  });
}

/**
 * Runs the frame path until V8 has finished compiling it, and no further.
 *
 * This is the single most important line in the allocation measurement and it was
 * absent from the first version of it, which is why that version reported ten
 * times the real number. A cold V8 allocates while it *learns* a function -
 * feedback vectors, inline caches, the optimised code itself - and the sampler
 * counts all of it. Worse, it counts it against whatever builtin happens to be on
 * the stack, so the first list of sites this file printed blamed `Math.hypot` for
 * 103 B/frame. Replacing every `Math.hypot` in the game with `Math.sqrt` moved
 * that line off the list and left the total exactly where it was: the bytes were
 * never hypot's, they were the compiler's, and the site list of an unwarmed
 * sample is not a list of things to fix.
 *
 * Three thousand frames is where the number stops moving. The run is restarted
 * whenever it ends, because a warm-up that dies at frame 400 warms the game-over
 * screen rather than the game.
 */
async function warmFramePath(page: Page, frames: number): Promise<void> {
  await page.evaluate((n) => {
    const tide = window.__slowblue!;
    for (let i = 0; i < n; i++) {
      if (i % 60 === 0 && tide.metrics().mode !== 'playing') tide.jump(tide.world.act.key);
      if (i % 12 === 0) window.__steer!();
      tide.advance(1 / 60);
    }
  }, frames);
}

/** Frames of play before the sampler is switched on. See `warmFramePath`. */
const ALLOC_WARMUP_FRAMES = 3000;

/**
 * The per-frame allocation budget, in bytes.
 *
 * Warm, steered and still running, the whole path - one fixed step, one event
 * drain, one render, one bed push - measures about 35 B/frame on an open station
 * and about 108 B/frame with every hunter in act I alive. Six kilobytes a second
 * at the worst of it, which is a minor GC every several minutes and the "zero"
 * criterion 3 can actually mean on this runtime. `tests/allocation.test.ts`
 * guards the simulation half of the same path without a browser, so a regression
 * in the sim is caught by `npm test` rather than only here.
 *
 * Four hundred is roughly four times the measurement, and that headroom is the
 * instrument rather than slack. A sampling profiler estimates, and the shoal size
 * varies with what the steering manages to rescue; a guard tight enough to notice
 * ten bytes would fail on its own arithmetic and be switched off inside a week.
 * What it catches is a regression of *kind* - a `.map()` or an object literal per
 * agent per frame - and at fifty agents that is thousands of bytes, not tens.
 */
const ALLOC_BUDGET_BYTES = 400;

/**
 * Reports the run's phase after a sample, and prints what it ended as if it did.
 *
 * `World.step` returns almost immediately once a run is over, so a sample that
 * straddles the end measures a stopped game, divides by 600 anyway, and passes
 * for the best possible reason. Both tests here were doing exactly that: the
 * shoal was flying past the mandatory rings and losing on `ringMissed` about four
 * seconds into a ten-second window. Nothing asked, so nothing said.
 */
async function stillPlaying(page: Page, label: string): Promise<string | number | boolean | null> {
  const state = await page.evaluate(() => {
    const m = window.__slowblue!.metrics();
    return { phase: m.phase, reason: m.reason, count: m.count, level: m.level };
  });
  console.log(`[allocation ${label} state] ${JSON.stringify(state)}`);
  return state.phase;
}

test.describe('allocation', () => {
  // Three thousand warm-up frames cost about forty-five seconds of real rendering
  // at this device scale, which is most of the file's default minute before the
  // sample has even started. The warm-up is the measurement - see `warmFramePath`
  // - so the limit moves rather than the frame count.
  test.describe.configure({ timeout: 180_000 });

  /**
   * The opening station: one shoal, one course, nothing else on screen. The
   * floor of the measurement - whatever this costs, every frame of the game
   * costs at least that.
   */
  test('allocates nothing measurable in an open frame', async ({ page }) => {
    await playFrom(page, 12345);
    await installSteering(page);
    await warmFramePath(page, ALLOC_WARMUP_FRAMES);

    const { perFrame } = await sampleAllocations(page, 'open');
    expect(await stillPlaying(page, 'open')).toBe('running');
    expect(perFrame).toBeLessThan(ALLOC_BUDGET_BYTES);
  });

  /**
   * The worst frame the game has, built rather than played: every authored
   * section of act I at once, every hunter in them alive, every standing
   * current turning, and a finger on the glass. This is where a per-frame `new`
   * would show up if one existed - the particle and tracer paths only run when
   * something is happening.
   */
  test('allocates nothing measurable in the busiest frame the act has', async ({ page }) => {
    await playFrom(page, 4242);
    await installSteering(page);
    // Warmed before the scene is built rather than after: the warm-up restarts the
    // run when it ends, and a restart would sweep away every hunter placed here.
    await warmFramePath(page, ALLOC_WARMUP_FRAMES);

    const scene = await page.evaluate(() => {
      const w = window.__slowblue!.world;
      w.obstacles.ensureAhead(-100000);
      for (const s of w.obstacles.sections) {
        for (const h of s.hunterHints) w.predators.spawn(h.x, h.y, h.size, s.id, 0);
        for (const v of s.vortexHints) w.currents.add({ ...v, sectionId: s.id, phase: 0 });
      }
      // Every hunter in the act, all at once, eats a starting shoal well inside
      // the ten seconds this samples - and a run that ends mid-sample measures the
      // game-over screen, quietly, which is what the previous version of this test
      // did. The shoal is topped up instead of the failure system being reached
      // into: a large shoal is a state the game genuinely reaches through rescues,
      // and it is also strictly more work per frame, which is what "busiest" means.
      const c = w.swarm.centroid();
      w.swarm.spawnShoal(140, c.x, c.y, 90);
      // Long enough to settle the new fish into the shoal and no longer: the
      // sample's own loop keeps steering from here on.
      for (let i = 0; i < 60; i++) {
        if (i % 12 === 0) window.__steer!();
        window.__slowblue!.advance(1 / 60);
      }
      return { predators: w.predators.predators.length, vortices: w.currents.vortices.length };
    });
    expect(scene.predators).toBeGreaterThan(2);
    expect(scene.vortices).toBeGreaterThan(2);

    const { perFrame } = await sampleAllocations(page, 'deep');
    expect(await stillPlaying(page, 'deep')).toBe('running');
    expect(perFrame).toBeLessThan(ALLOC_BUDGET_BYTES);
  });
});

/* ------------------------------------------------------------------ offline */

/**
 * A wait with a deadline this file controls.
 *
 * `waitForFunction`'s own timeout does not fire on a page that finished loading
 * with nothing on it - the condition is never going to become true, no new
 * document is coming, and the wait sits there until the *test* times out, which
 * is exactly the shape of every offline failure measured here. Racing it against
 * a timer keeps a negative result a result, and a fast one.
 */
function deadline<T>(pending: Promise<T>, fallback: T, ms = 6000): Promise<T> {
  return Promise.race([
    pending.catch(() => fallback),
    new Promise<T>((resolve) => setTimeout(() => resolve(fallback), ms)),
  ]);
}

test.describe('offline', () => {
  /**
   * The install-then-fly scenario, which is the one that actually happens.
   *
   * A player opens the game once, the worker installs, and the *next* launch is
   * on a plane. Nothing re-fetches anything in between, so whatever the install
   * step did not put in the cache is not there.
   *
   * It used to fail here, and failed in the worst available way: the hashed
   * bundle was requested by a page the worker did not yet control, so the `fetch`
   * handler never saw it, and the install step precached four URLs that did not
   * include it. Offline, the module script then matched the worker's `/index.html`
   * last resort - answered 200, with a page of HTML in the body. No failed
   * request, no console error, no game. A blank screen that looked like a fast
   * load. The build now writes its asset list into the worker, and the last
   * resort answers navigations only.
   */
  test('a cold install with no network', async ({ page, context }) => {
    await page.goto('/');
    await page.evaluate(async () => {
      await navigator.serviceWorker.ready;
    });

    const failures: string[] = [];
    page.on('requestfailed', (r) => failures.push(new URL(r.url()).pathname));
    await context.setOffline(true);
    await page.reload({ waitUntil: 'commit' });
    const booted = await deadline(
      page.waitForFunction(() => window.__slowblue !== undefined).then(() => true),
      false,
    );
    // Snapshotted before the deliberate miss below joins the list.
    const bootFailures = failures.slice();

    // What the bundle request actually gets: the precached module, out of the
    // cache, as JavaScript. This is the assertion the whole phase is about.
    const asset = await deadline(
      page.evaluate(async () => {
        const src = document.querySelector('script[type=module]')?.getAttribute('src') ?? '';
        const res = await fetch(src);
        return { src, status: res.status, type: res.headers.get('content-type') ?? '' };
      }),
      { src: '', status: 0, type: 'unreachable' },
    );
    // And what a genuinely missing asset gets, which is the other half of the fix:
    // an error. The shell is no longer handed out to anything that is not a
    // navigation, so a script the cache has never heard of fails loudly instead of
    // arriving as HTML with a 200 on it.
    const missing = await deadline(
      page.evaluate(async () => {
        try {
          const res = await fetch('/assets/nothing-was-ever-built-here.js');
          return { status: res.status, type: res.headers.get('content-type') ?? '' };
        } catch {
          return { status: 0, type: 'rejected' };
        }
      }),
      { status: -1, type: 'unreachable' },
    );
    const state = await deadline(
      page.evaluate(() => document.readyState),
      'unreachable',
    );
    const playable = booted
      ? await page
          .locator('button.ui-btn.primary')
          .first()
          .isVisible()
          .catch(() => false)
      : false;
    console.log(
      `[offline cold] ${JSON.stringify({ booted, playable, state, asset, missing, bootFailures })}`,
    );

    expect(state).toBe('complete');
    expect(booted).toBe(true);
    expect(playable).toBe(true);
    expect(asset.status).toBe(200);
    expect(asset.type).toContain('javascript');
    expect(missing.status).toBe(0);
  });

  /**
   * The same flight, one launch later.
   *
   * The second load goes through the worker, so every asset it asks for is
   * cached on the way past. This is the case that already works, and it is here
   * so that the fix to the case above is measured as a change to the cold path
   * and not as a change to this one.
   */
  test('a second launch with no network', async ({ page, context }) => {
    await page.goto('/');
    await page.evaluate(async () => {
      await navigator.serviceWorker.ready;
    });
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    await context.setOffline(true);
    await page.reload({ waitUntil: 'commit' });
    const booted = await deadline(
      page.waitForFunction(() => window.__slowblue !== undefined).then(() => true),
      false,
    );
    const playable = booted
      ? await page
          .locator('button.ui-btn.primary')
          .first()
          .isVisible()
          .catch(() => false)
      : false;
    console.log(`[offline warm] ${JSON.stringify({ booted, playable })}`);

    expect(booted).toBe(true);
    expect(playable).toBe(true);
  });
});

/* -------------------------------------------------------------------- pixels */

interface Sharpness {
  scale: number;
  devicePixelRatio: number;
  /** What `main.ts` handed the renderer: `clamp(dpr, 1, 2) * dprScale`. */
  renderedDpr: number;
  /** Backing-store pixels per physical pixel. 1 is native, below 1 is upscaled. */
  nativeRatio: number;
  /** Median hard-edge transition, in physical pixels. */
  edgePx: number;
  /** The same edge in CSS pixels: how much of a layout pixel the edge smears. */
  edgeCssPx: number;
  edges: number;
  /** Mean cost of one step-and-render at this resolution, in milliseconds. */
  frameMs: number;
}

/**
 * Measures how wide a hard edge lands, in the pixels the screen actually has.
 *
 * The canvas backing store cannot answer this. Reading it back reports the
 * resolution the game *chose* - which is the clamp under test - and says nothing
 * about what the compositor then did to reach the panel. A page screenshot is
 * taken at the device scale factor, after the upscale, which is where the
 * softness introduced by `clamp(dpr, 1, 2)` on a 3x display becomes visible.
 *
 * The art is hard flat vector by doctrine, so a correctly resolved edge is one
 * partially covered pixel between two plateaus. The scan below counts exactly
 * that: a monotone luminance ramp of at least 40 levels with flat ground on both
 * sides. Anything gradual - the backdrop bands, a halo - fails the flatness test
 * and is not counted, which is why the sample count is reported too.
 */
async function measureSharpness(page: Page, scale: number): Promise<Sharpness> {
  const shot = (await page.screenshot()).toString('base64');
  const scan = await page.evaluate(async (b64) => {
    const img = new Image();
    img.src = `data:image/png;base64,${b64}`;
    await img.decode();
    const cv = document.createElement('canvas');
    cv.width = img.naturalWidth;
    cv.height = img.naturalHeight;
    const ctx = cv.getContext('2d')!;
    ctx.drawImage(img, 0, 0);
    const { data, width, height } = ctx.getImageData(0, 0, cv.width, cv.height);

    const luma = (x: number, y: number): number => {
      const i = (y * width + x) * 4;
      return 0.2126 * data[i]! + 0.7152 * data[i + 1]! + 0.0722 * data[i + 2]!;
    };

    const widths: number[] = [];
    const FLAT = 2;
    const STEP = 6;
    const EDGE = 40;
    for (let y = Math.round(height * 0.2); y < height * 0.8; y += 3) {
      let x = 2;
      while (x < width - 6) {
        if (Math.abs(luma(x, y) - luma(x - 1, y)) > FLAT) {
          x++;
          continue;
        }
        // Flat ground here; walk a monotone run of real steps.
        const start = luma(x, y);
        const dir = Math.sign(luma(x + 1, y) - start);
        let end = x;
        while (end < width - 3 && Math.abs(luma(end + 1, y) - luma(end, y)) > STEP) {
          if (Math.sign(luma(end + 1, y) - luma(end, y)) !== dir) break;
          end++;
        }
        const span = end - x;
        const delta = Math.abs(luma(end, y) - start);
        // Flat ground on the far side too, or this is a gradient, not an edge.
        const settled = Math.abs(luma(Math.min(width - 1, end + 1), y) - luma(end, y)) <= FLAT;
        if (span > 0 && span <= 6 && delta >= EDGE && settled) widths.push(span);
        x = end + 1;
      }
    }
    widths.sort((a, b) => a - b);
    return { median: widths[Math.floor(widths.length / 2)] ?? 0, count: widths.length };
  }, shot);

  const geometry = await page.evaluate(() => {
    const canvas = document.getElementById('game') as HTMLCanvasElement;
    const rect = canvas.getBoundingClientRect();
    // What a frame costs here. The sim inside `advance` is resolution-blind, so
    // the difference between two scales is the drawing alone - which is the
    // number the clamp was set to protect and has never been held against it.
    const t0 = performance.now();
    for (let i = 0; i < 300; i++) window.__slowblue!.advance(1 / 60);
    const frameMs = (performance.now() - t0) / 300;
    return {
      backing: canvas.width,
      css: rect.width,
      dpr: window.devicePixelRatio,
      rendered: window.__slowblue!.metrics().dpr as number,
      frameMs,
    };
  });

  const round = (n: number): number => Math.round(n * 100) / 100;
  return {
    scale,
    devicePixelRatio: geometry.dpr,
    renderedDpr: round(geometry.rendered),
    nativeRatio: round(geometry.backing / (geometry.css * geometry.dpr)),
    edgePx: scan.median,
    edgeCssPx: round(scan.median / geometry.dpr),
    edges: scan.count,
    frameMs: round(geometry.frameMs),
  };
}

test.describe('pixels', () => {
  /**
   * What `clamp(dpr, 1, 2)` costs on the displays it clamps.
   *
   * The clamp is a performance decision - a 3x phone asked to fill its own
   * panel draws 2.25 times the pixels of a 2x one - and the question it has
   * never been asked is what it costs on the glass. This runs the same station
   * at 1x, 2x and 3x and measures the edge each one lands.
   */
  test('holds edge sharpness across 1x, 2x and 3x displays', async ({ browser }) => {
    const results: Sharpness[] = [];
    for (const scale of [1, 2, 3]) {
      const context = await browser.newContext({
        viewport: { width: 390, height: 844 },
        deviceScaleFactor: scale,
        hasTouch: true,
        isMobile: true,
      });
      const page = await context.newPage();
      await page.goto('/?seed=12345');
      await page.waitForFunction(() => window.__slowblue !== undefined);
      await page.locator('button.ui-btn.primary').first().click();
      await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
      // The same frame of the same seed on all three, so only the pixels differ.
      await page.evaluate(() => {
        for (let i = 0; i < 300; i++) window.__slowblue!.advance(1 / 60);
      });
      results.push(await measureSharpness(page, scale));
      await context.close();
    }
    for (const r of results) console.log(`[pixels] ${JSON.stringify(r)}`);

    // What lifting the clamp would cost, from the two points that differ only in
    // backing-store area. The sim inside `advance` is the same work at every
    // resolution, so `frame = sim + area * draw` with area 1 and 4 solves for
    // both terms, and a 3x panel drawn natively is area 9.
    const draw = (results[1]!.frameMs - results[0]!.frameMs) / 3;
    const sim = results[0]!.frameMs - draw;
    const round = (n: number): number => Math.round(n * 100) / 100;
    console.log(
      `[pixels clamp] ${JSON.stringify({
        simMs: round(sim),
        drawMsAt1x: round(draw),
        measuredAt2x: results[1]!.frameMs,
        projectedNative3x: round(sim + 9 * draw),
        frameBudgetMs: 16.7,
      })}`,
    );

    // 1x and 2x are inside the clamp and must be native.
    expect(results[0]!.nativeRatio).toBe(1);
    expect(results[1]!.nativeRatio).toBe(1);
    // 3x is the one the clamp bites: two thirds of the panel's own resolution.
    expect(results[2]!.nativeRatio).toBeCloseTo(2 / 3, 2);
    // Enough hard edges on screen for the median to mean anything.
    for (const r of results) expect(r.edges).toBeGreaterThan(30);
    // And the finding: an edge on a 3x phone is no sharper, in the layout pixels
    // the design is drawn in, than the same edge on a 2x one - measured at 1.33
    // against 1.0 CSS pixels. The assertion is the half of that which cannot
    // wobble on a median of integer pixel counts; the log carries the rest.
    expect(results[2]!.edgeCssPx).toBeGreaterThanOrEqual(results[1]!.edgeCssPx);
    // The two clamped scales draw the same backing store, so they must cost the
    // same. This is the clamp doing its job, stated as a number.
    expect(Math.abs(results[2]!.frameMs - results[1]!.frameMs)).toBeLessThan(
      results[1]!.frameMs * 0.35,
    );
  });
});
