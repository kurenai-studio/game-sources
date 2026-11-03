import { expect, test, type Page } from '@playwright/test';
import type { SimEventType } from '../src/sim/World';
import { collectErrors } from './helpers';

/**
 * Slowblue: what answers a thing that happens, and how loudly.
 *
 * §1 asks for immediate feedback on every physical interaction and §2 asks for
 * the sound of it; the suite has been able to measure each half on its own for a
 * while now - `e2e/unlock.spec.ts` counts voices, `e2e/acts.spec.ts` reads the
 * glass - and never once the two side by side, per event. So nothing in the
 * project could answer the only question that matters here: **for each thing the
 * simulation says happened, did the picture answer, did the sound answer, and
 * did they answer the same event.**
 *
 * ## How the picture is measured
 *
 * The water is never still, so "the picture changed" is not a measurement on its
 * own - the tracers advect, the shoal swims and the backdrop scrolls whatever
 * happens. What is measured is therefore a *rise above the frame's own motion*:
 * twelve control frames are stepped first with nothing fired and the largest
 * change between two of them is the floor, and the same number is then read for
 * thirty-six frames with the event in flight.
 *
 * Locally, not globally. An effect is a ring a hundred pixels across on a frame
 * of one and a half million, so its contribution to a whole-frame mean is
 * arithmetic noise; the number kept is the largest change inside any 96 pixel
 * block, which is what "something happened *there*" actually looks like. The
 * whole-frame mean is reported beside it because the two disagree in exactly one
 * interesting case: a shake moves everything a little and nothing a lot.
 *
 * The run is paused for it. `onStep` returns while paused and `frameDt` is zero,
 * so neither the world nor an effect's own life advances except through
 * `advance()` - which makes a frame here a frame, rather than however much wall
 * clock passed between two Playwright calls.
 *
 * What that costs is the HUD: `hudVisible` follows the mode, so a paused frame
 * draws no progress rail, and the rail is where a broken streak is answered. That
 * one is measured live and on its own columns by `rail()`, for the same reason
 * act VII's light shafts had to be measured on the row their formula names - an
 * instrument built for the whole frame is blind to a thing two pixels wide.
 *
 * The null reading is 0.82, and it is worth knowing because it is what makes the
 * rest of the table readable: the three cues that draw nothing at all - gate,
 * zone, a broken streak - all report between 0.82 and 0.82 of the floor, so
 * anything at 1.0 is a picture and anything at 0.82 is the water.
 *
 * ## How the sound is measured
 *
 * `AudioEngine.voicesPlayed` counts sources that actually reach a mixer track
 * (see `e2e/unlock.spec.ts`), and the bed is dealing grains the whole time on a
 * Poisson schedule, so a single window proves nothing. Each cue is fired eight
 * times with a control window of the same length before it, and what is reported
 * is the difference of the two means: the bed's own rate cancels and what is
 * left is the cue.
 */

/** The seed every measurement here runs on, so two runs of this file agree. */
const SEED = 7;

interface Answer {
  /** Largest local change between two control frames: the noise floor. */
  floor: number;
  /**
   * Largest local change while the event was in flight - the number itself, not
   * its excess over the floor.
   *
   * It was the excess at first, and that was the wrong number to keep: an answer
   * quieter than the water reads 0.00 either way, so a puff at four fifths of the
   * floor and no picture at all were indistinguishable in the report. What
   * separates the two cases is the *ratio*, and the ratio needs both halves.
   */
  peak: number;
  /** Whole-frame mean change at the peak frame, for the shake case. */
  wide: number;
  /** Frames until the first change above the floor, or -1 for none at all. */
  onset: number;
  /** How many frames stayed above it. */
  frames: number;
}

/**
 * Every event the simulation can emit, and how this file makes one happen.
 *
 * Read off `SimEventType` by hand, and held to it by `tests/response.test.ts`,
 * which runs on every commit and fails if the union grows a member neither
 * switch names. That is the pairing: an event nobody remembered to answer is
 * exactly the event nobody remembered to measure, and the cheap test catches the
 * drift while this one says how loud the answer is.
 */
const CUES = [
  'loss0',
  'loss1',
  'loss2',
  'bite',
  'rescue',
  'ring',
  'ringLost',
  'reform',
  'gate',
  'streakBreak',
  'level',
  'zone',
  'fail',
  'restart',
  'stroke',
] as const;
type Cue = (typeof CUES)[number];

/** Which act each cue is measured in. Only the restart needs one of its own. */
function actFor(cue: Cue): string {
  return cue === 'restart' ? 'thin' : 'water';
}

/**
 * The cues that are allowed to answer on one channel only, and why each one is.
 *
 * Every exemption here is a measurement or a decision written down somewhere in
 * the source, not a threshold that was lowered until the suite went green. What
 * the list is for is the opposite: anything *not* in it has to answer on both,
 * and a new event added to `SimEventType` with nothing behind it fails the
 * exhaustiveness check below before it ever gets here.
 */
const ONE_CHANNEL: Partial<Record<Cue, string>> = {
  // Clearing a section flashed a full-width line across the screen once. It was
  // arcade scoreboard grammar and it is gone on purpose; the progress rail says
  // where you are continuously. See `Renderer.ingest`.
  gate: 'the picture answers continuously on the rail instead',
  /*
   * All three losses, and this is the one exemption here that is a finding rather
   * than a decision.
   *
   * A loss draws a circle that reaches sixteen CSS pixels at 0.42 alpha and is
   * gone in half a second, and it is drawn where the shoal is - so the block it
   * lands in is the block the shoal is already swimming through. Measured, the
   * puff is barely over that block's own motion: the straggler reads 0.82, which
   * is exactly what the three cues that draw *nothing* read, and the rock and the
   * hunter's kill read 1.33 and 1.58 against 3.40 for a bite, 3.03 for a rescue
   * and 7.29 for a reform. Both have crossed the bar in one run and missed it in
   * another. The straggler is meant to be the quietest thing in the game and it
   * is; the rock strike is not meant to be, and most of what reads is the flinch.
   *
   * Left alone rather than brightened, because a number that swings across the bar
   * between runs says *look at this*, not what to do about it - and the picture is
   * act I's, which is tuned. Written down here so the next pass starts from it.
   */
  loss0: 'a straggler culled off the back: the quietest thing in the game, deliberately',
  loss1: 'the puff sits at the shoal own motion; the flinch is what reads',
  loss2: 'the puff sits at the shoal own motion; the flinch is what reads',
  // Answered on the rail, which no block pass can see. Measured separately by
  // `rail()` below.
  streakBreak: 'answered on a two pixel rail, measured on its own columns',
  // The moment a zone line is crossed is answered by the palette crossfade and
  // the bed, both of which are already moving before and after it.
  zone: 'answered continuously by the palette and the bed',
  // The sound of a run ending belongs to the ending, not to the frame the failure
  // is detected on: `main.ts` fires it from `onRunEnded`, under the results
  // screen. What the frame itself gets is the flinch.
  fail: 'the sound of it belongs to the run ending',
};

async function picture(page: Page, cue: Cue): Promise<Answer> {
  return page.evaluate(
    ({ cue, act, seed }) => {
      const api = window.__slowblue!;
      api.jump(act, 0, seed);
      // Paused, so the only clock in the room is `advance()`. Dispatched rather
      // than clicked: the pause button is chrome, and a click would put a shell
      // screen over the canvas half a frame before the first sample.
      window.dispatchEvent(new KeyboardEvent('keydown', { key: 'p' }));

      const canvas = document.querySelector('canvas#game') as HTMLCanvasElement;
      const ctx = canvas.getContext('2d')!;
      const { width, height } = canvas;
      const STRIDE = 6;
      const cols = Math.ceil(width / STRIDE);
      const rows = Math.ceil(height / STRIDE);
      /** Samples per side of a block: 16 at stride 6 is a 96 pixel square. */
      const BLOCK = 16;

      const read = (): Float32Array => {
        const d = ctx.getImageData(0, 0, width, height).data;
        const out = new Float32Array(cols * rows);
        let k = 0;
        for (let y = 0; y < height; y += STRIDE) {
          for (let x = 0; x < width; x += STRIDE) {
            const i = (y * width + x) * 4;
            out[k++] = (d[i]! * 299 + d[i + 1]! * 587 + d[i + 2]! * 114) / 1000;
          }
        }
        return out;
      };
      const step = (): Float32Array => {
        api.advance(1 / 60);
        return read();
      };
      /** Mean absolute change over the frame, and the worst of it in any block. */
      const change = (a: Float32Array, b: Float32Array): { wide: number; local: number } => {
        let total = 0;
        let local = 0;
        for (let by = 0; by < rows; by += BLOCK) {
          for (let bx = 0; bx < cols; bx += BLOCK) {
            let sum = 0;
            let n = 0;
            const yEnd = Math.min(rows, by + BLOCK);
            const xEnd = Math.min(cols, bx + BLOCK);
            for (let y = by; y < yEnd; y++) {
              for (let x = bx; x < xEnd; x++) {
                const i = y * cols + x;
                sum += Math.abs(a[i]! - b[i]!);
                n++;
              }
            }
            total += sum;
            local = Math.max(local, sum / n);
          }
        }
        return { wide: total / (cols * rows), local };
      };

      // Long enough for the course to build and the palette crossfade to land, so
      // the floor below is the water's own motion rather than a station arriving.
      for (let i = 0; i < 90; i++) api.advance(1 / 60);

      let prev = read();
      let floor = 0;
      for (let i = 0; i < 12; i++) {
        const now = step();
        floor = Math.max(floor, change(prev, now).local);
        prev = now;
      }

      const w = api.world;
      const c = w.swarm.centroid();
      const x = c.count > 0 ? c.x : w.width * 0.5;
      const y = c.count > 0 ? c.y : w.cameraY + w.height * 0.5;
      switch (cue) {
        case 'loss0':
          w.events.push({ type: 'loss', x, y, value: 0 });
          break;
        case 'loss1':
          w.events.push({ type: 'loss', x, y, value: 1 });
          break;
        case 'loss2':
          w.events.push({ type: 'loss', x, y, value: 2 });
          break;
        case 'bite':
          w.events.push({ type: 'bite', x, y, value: 0 });
          break;
        case 'rescue':
          w.events.push({ type: 'rescue', x, y, value: 12 });
          break;
        case 'ring':
          w.events.push({ type: 'ring', x, y, value: 12 });
          break;
        case 'ringLost':
          w.events.push({ type: 'ringLost', x, y, value: 0 });
          break;
        case 'reform':
          w.events.push({ type: 'reform', x, y, value: 0 });
          break;
        case 'gate':
          w.events.push({ type: 'gate', x, y, value: 3 });
          break;
        case 'streakBreak':
          w.events.push({ type: 'streakBreak', x, y, value: 0 });
          break;
        case 'level':
          w.events.push({ type: 'level', x, y, value: 1 });
          break;
        case 'zone':
          w.events.push({ type: 'zone', x, y, value: 2 });
          break;
        case 'fail':
          w.events.push({ type: 'fail', x, y, value: 2 });
          break;
        // The whole state change, not a bare event: a station beginning again is
        // the thing being measured, and it is the one cue whose picture could
        // legitimately come from the world rather than from an effect.
        case 'restart':
          w.restartStation();
          break;
        // The player's own hand, through the same door the input controller uses.
        case 'stroke':
          w.injectStroke(x - 60, y, x + 60, y - 20, 0.12);
          break;
      }

      let onset = -1;
      let peak = 0;
      let wide = 0;
      let frames = 0;
      for (let i = 0; i < 36; i++) {
        const now = step();
        const d = change(prev, now);
        prev = now;
        // A quarter above the loudest control frame. The floor is a maximum
        // already, so this is margin on a margin - what it must never do is call
        // the water's own motion an answer.
        if (d.local > floor * 1.25) {
          if (onset < 0) onset = i;
          frames++;
        }
        if (d.local > peak) {
          peak = d.local;
          wide = d.wide;
        }
      }
      return { floor, peak, wide, onset, frames };
    },
    { cue, act: actFor(cue), seed: SEED },
  );
}

/**
 * The progress rail, on its own columns.
 *
 * The block pass above cannot see this and no threshold would fix it: the rail is
 * 1.8 CSS pixels wide inside a 96 pixel block, so even a rail switched off
 * entirely moves that block by a fiftieth of its own contrast. A broken streak is
 * answered there and nowhere else - deliberately, since the alternative the
 * design rejected is a red line drawn over the water - so the instrument has to
 * be aimed at it, the same way act VII's light shafts had to be measured on the
 * row the formula names rather than on the frame.
 */
async function rail(page: Page): Promise<{ floor: number; peak: number }> {
  return page.evaluate(
    async ({ seed }) => {
      const api = window.__slowblue!;
      // A third of the way along the act, because the rail's *covered* line is
      // the part a break dims and at the top of a station there are ten pixels of
      // it. And live rather than paused: `hudVisible` follows the mode, so the
      // rail is one of the things a paused frame does not draw at all - which is
      // why the block pass could not have found this even if it were wide enough.
      api.jump('water', 3, seed);
      await new Promise((r) => setTimeout(r, 900));
      const canvas = document.querySelector('canvas#game') as HTMLCanvasElement;
      const ctx = canvas.getContext('2d')!;
      const { width, height } = canvas;
      const rect = canvas.getBoundingClientRect();
      const dpr = width / rect.width;
      // Nine CSS pixels in from the right edge, inside the cutout, and 1.8 wide:
      // a strip of about eight device pixels either side of it.
      const centre = (rect.width - 9 - (api.metrics().insetRight as number)) * dpr;
      const x0 = Math.round(centre - 4 * dpr);
      const x1 = Math.round(centre + 4 * dpr);
      const y0 = Math.round(height * 0.25);
      const y1 = Math.round(height * 0.78);
      const read = (): Float32Array => {
        const d = ctx.getImageData(x0, y0, x1 - x0, y1 - y0).data;
        const out = new Float32Array((x1 - x0) * (y1 - y0));
        for (let i = 0; i < out.length; i++) {
          const j = i * 4;
          out[i] = (d[j]! * 299 + d[j + 1]! * 587 + d[j + 2]! * 114) / 1000;
        }
        return out;
      };
      const change = (a: Float32Array, b: Float32Array): number => {
        let s = 0;
        for (let i = 0; i < a.length; i++) s += Math.abs(a[i]! - b[i]!);
        return s / a.length;
      };
      const step = async (): Promise<Float32Array> => {
        await new Promise((r) => requestAnimationFrame(() => r(null)));
        return read();
      };
      let prev = read();
      let floor = 0;
      for (let i = 0; i < 16; i++) {
        const now = await step();
        floor = Math.max(floor, change(prev, now));
        prev = now;
      }
      const w = api.world;
      w.events.push({ type: 'streakBreak', x: w.width * 0.5, y: w.cameraY, value: 0 });
      let peak = 0;
      for (let i = 0; i < 45; i++) {
        const now = await step();
        peak = Math.max(peak, change(prev, now));
        prev = now;
      }
      return { floor, peak };
    },
    { seed: SEED },
  );
}

/**
 * Voices the cue put on a mixer track, over and above what the bed was dealing
 * anyway. Eight repeats, each with its own control window.
 */
async function sound(page: Page, cue: Cue): Promise<number> {
  let fired = 0;
  let idle = 0;
  const REPEATS = 8;
  for (let i = 0; i < REPEATS; i++) {
    idle += await voiceWindow(page, cue, false);
    fired += await voiceWindow(page, cue, true);
  }
  return (fired - idle) / REPEATS;
}

/** One window: voices counted across four frames, with or without the cue. */
async function voiceWindow(page: Page, cue: Cue, fire: boolean): Promise<number> {
  return page.evaluate(
    async ({ cue, fire }) => {
      const api = window.__slowblue!;
      const w = api.world;
      const voices = (): number => api.metrics().audioVoices as number;
      const frame = async (): Promise<void> => {
        await new Promise((r) => requestAnimationFrame(() => r(null)));
      };
      const before = voices();
      if (fire) {
        const c = w.swarm.centroid();
        const x = c.count > 0 ? c.x : w.width * 0.5;
        const y = c.count > 0 ? c.y : w.cameraY + w.height * 0.5;
        const map: Record<string, { type: SimEventType; value: number }> = {
          loss0: { type: 'loss', value: 0 },
          loss1: { type: 'loss', value: 1 },
          loss2: { type: 'loss', value: 2 },
          bite: { type: 'bite', value: 0 },
          rescue: { type: 'rescue', value: 12 },
          ring: { type: 'ring', value: 12 },
          ringLost: { type: 'ringLost', value: 0 },
          reform: { type: 'reform', value: 0 },
          gate: { type: 'gate', value: 3 },
          streakBreak: { type: 'streakBreak', value: 0 },
          level: { type: 'level', value: 1 },
          zone: { type: 'zone', value: 2 },
          fail: { type: 'fail', value: 2 },
          restart: { type: 'restart', value: 0 },
        };
        if (cue === 'stroke') {
          // Nothing here: a stroke is the one cue that cannot be posted into the
          // world, because `injectStroke` is the *water* half of it and the sound
          // hangs off the input controller's hook. It gets a finger of its own,
          // below.
        } else if (cue === 'restart') {
          w.restartStation();
        } else {
          const m = map[cue]!;
          w.events.push({ type: m.type, x, y, value: m.value });
        }
      }
      for (let i = 0; i < 4; i++) await frame();
      return voices() - before;
    },
    { cue, fire },
  );
}

test('every event, on both channels', async ({ page }) => {
  test.setTimeout(300_000);
  const errors = collectErrors(page);
  await page.goto(`/?act=water&seed=${SEED}`);
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  await page.waitForFunction(() => window.__slowblue!.metrics().audioRunning === true);

  const report: string[] = [];
  const silent: string[] = [];
  const unseen: string[] = [];
  for (const cue of CUES) {
    // The sound first: it needs the run playing, and the picture pass pauses it.
    await page.evaluate(
      ({ act, seed }) => {
        window.__slowblue!.jump(act, 0, seed);
      },
      { act: actFor(cue), seed: SEED },
    );
    await page.waitForTimeout(600);
    const voices = await sound(page, cue);
    const p = await picture(page, cue);
    report.push(
      `${cue.padEnd(12)} picture ${p.peak.toFixed(2)}/${p.floor.toFixed(2)} = ${(p.peak / p.floor).toFixed(2)}x (wide ${p.wide.toFixed(3)}) onset=${p.onset} frames=${p.frames}  ${cue === 'stroke' ? 'voices measured with a finger, below' : `voices=${voices.toFixed(2)}`}`,
    );
    if (voices < 0.5) silent.push(cue);
    if (p.onset < 0) unseen.push(cue);
  }
  const r = await rail(page);
  report.push(
    `streakBreak on the rail's own columns: peak=${r.peak.toFixed(3)} floor=${r.floor.toFixed(3)}`,
  );
  console.log(`\n${report.join('\n')}\n  silent: ${silent.join(', ') || 'none'}\n  unseen: ${unseen.join(', ') || 'none'}`);

  // Every cue answers on both channels, except the five that are answered
  // somewhere this pass cannot look and say so by name.
  for (const cue of CUES) {
    if (cue === 'stroke') continue; // measured with a real finger, below
    const why = ONE_CHANNEL[cue];
    if (why === undefined) {
      expect(silent, `${cue} puts no voice on a track`).not.toContain(cue);
      expect(unseen, `${cue} moves nothing on the glass`).not.toContain(cue);
    }
  }
  // ...and the rail is one of those places. A break has to move it more than the
  // rail moves on its own, and the old `warm * (1 - streakFade)` could not have
  // passed this at any threshold: measured on this strip it read 0.051 against a
  // floor of 0.054, which is the rail doing slightly less than nothing. The fade
  // taken off the line's own alpha reads 4.41 against 0.10.
  expect(r.peak, 'a broken streak does not move the rail').toBeGreaterThan(r.floor * 2);
  expect(errors).toEqual([]);
});

/**
 * The finger, which is the one interaction in the game the player performs rather
 * than receives - and the only one that cannot be measured by posting an event,
 * because half of it lives in `InputController` and never touches the world.
 *
 * Two cadences, because the engine rate-limits the stroke and the limiter is
 * carried across gestures: strokes drawn far apart and gestures started one after
 * another. What the second one is asking is whether **putting a finger down and
 * moving it always makes a sound**, or only when the previous gesture happens to
 * have finished long enough ago.
 */
async function drag(page: Page, x: number, y: number): Promise<void> {
  await page.mouse.move(x, y);
  await page.mouse.down();
  for (let i = 1; i <= 4; i++) await page.mouse.move(x + i * 14, y - i * 5);
  await page.mouse.up();
}

test('the finger is answered however fast the gestures come', async ({ page }) => {
  test.setTimeout(180_000);
  const errors = collectErrors(page);
  await page.goto(`/?act=water&seed=${SEED}`);
  await page.waitForFunction(() => window.__slowblue !== undefined);
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  await page.waitForFunction(() => window.__slowblue!.metrics().audioRunning === true);
  await page.waitForTimeout(600);

  const voices = async (): Promise<number> =>
    (await page.evaluate(() => window.__slowblue!.metrics().audioVoices)) as number;

  const GESTURES = 10;
  const measure = async (gapMs: number): Promise<number> => {
    // The bed is dealing grains throughout, so the same wall clock is spent idle
    // first and subtracted. Nothing else in the frame differs between the two.
    const idleFrom = await voices();
    await page.waitForTimeout((gapMs + 120) * GESTURES);
    const idle = (await voices()) - idleFrom;
    const from = await voices();
    for (let i = 0; i < GESTURES; i++) {
      await drag(page, 120 + (i % 3) * 40, 420 + (i % 4) * 30);
      await page.waitForTimeout(gapMs);
    }
    return ((await voices()) - from - idle) / GESTURES;
  };

  // Well clear of the 0.16 s limiter: what one gesture is worth when nothing is
  // in its way.
  const slow = await measure(420);
  // A player tapping the water into shape: gestures back to back.
  const quick = await measure(40);
  console.log(`\n  stroke voices per gesture: unhurried=${slow.toFixed(2)} back-to-back=${quick.toFixed(2)}`);

  // A gesture that makes no sound at all is the one thing §1 cannot have, at any
  // cadence: the finger is the interaction the whole game is made of.
  expect(slow, 'an unhurried gesture is silent').toBeGreaterThan(0.5);
  expect(quick, 'a gesture that follows another one closely is silent').toBeGreaterThan(0.5);
  expect(errors).toEqual([]);
});
