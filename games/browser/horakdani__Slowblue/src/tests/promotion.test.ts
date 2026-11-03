import { describe, expect, it } from 'vitest';
import { accumulateSteps } from '../src/core/GameLoop';
import { Rng } from '../src/core/rng';

/**
 * What the loop does on a display that is not 60 Hz.
 *
 * The accumulator is the reason this game can claim a stable simulation, and the
 * claim has only ever been checked at the rate the machine writing it happened
 * to run. ProMotion is 120 Hz, plenty of Android panels are 90, a tired phone
 * throttles to 30, and a backgrounded tab comes back with a second of debt - the
 * loop has to be right at all of them, and "right" is three separate things:
 * simulated time must track wall-clock time, the catch-up cap must never engage
 * on a healthy frame, and the interpolation factor must stay inside [0, 1) or
 * the renderer is extrapolating into a future the sim has not computed.
 *
 * A browser cannot be asked to run rAF at 120 Hz on demand, so this drives the
 * loop's stepping rule directly - `accumulateSteps` is the same arithmetic
 * `GameLoop.frame` runs, extracted for exactly this. What it cannot see is
 * whether the *display* keeps up; what it can see is whether the sim would be
 * asked to do something impossible, and that is the part that has been assumed.
 */

const DT = 1 / 60;
const MAX_STEPS = 5;
const SECONDS = 60;

interface Cadence {
  hz: number;
  /** Simulated seconds minus wall-clock seconds, in milliseconds. */
  driftMs: number;
  frames: number;
  steps: number;
  /** The worst catch-up burst any single frame was asked for. */
  maxStepsInFrame: number;
  /** Share of frames that render without a new sim state, as a percentage. */
  interpolatedPct: number;
  alphaMin: number;
  alphaMax: number;
}

/**
 * Runs `seconds` of wall clock at a given refresh rate and reports what the
 * loop did with it. `jitter` is the fraction by which a frame's length may vary
 * either way - real vsync is not a metronome, and a rule that only holds for
 * exact intervals is a rule that holds nowhere.
 */
function cadence(hz: number, jitter = 0, seed = 7): Cadence {
  const rng = new Rng(seed);
  const nominal = 1 / hz;
  let acc = 0;
  let simTime = 0;
  let wall = 0;
  let frames = 0;
  let steps = 0;
  let maxStepsInFrame = 0;
  let empty = 0;
  let alphaMin = Infinity;
  let alphaMax = 0;

  while (wall < SECONDS) {
    const elapsed = nominal * (1 + rng.signed() * jitter);
    wall += elapsed;
    const r = accumulateSteps(acc, elapsed, DT, MAX_STEPS);
    acc = r.accumulator;
    simTime += r.steps * DT;
    steps += r.steps;
    frames++;
    if (r.steps === 0) empty++;
    if (r.steps > maxStepsInFrame) maxStepsInFrame = r.steps;
    const alpha = acc / DT;
    if (alpha < alphaMin) alphaMin = alpha;
    if (alpha > alphaMax) alphaMax = alpha;
  }

  return {
    hz,
    driftMs: Math.round((simTime - wall) * 1000),
    frames,
    steps,
    maxStepsInFrame,
    interpolatedPct: Math.round((empty / frames) * 100),
    alphaMin,
    alphaMax,
  };
}

/**
 * Rounds for the log line only. The assertions read the raw numbers, because
 * the interesting bound on alpha is that it is strictly below 1 - and three
 * decimal places round 0.9996 to exactly the value being ruled out.
 */
function report(label: string, row: Cadence): void {
  console.log(
    label,
    JSON.stringify({
      ...row,
      alphaMin: Number(row.alphaMin.toFixed(4)),
      alphaMax: Number(row.alphaMax.toFixed(4)),
    }),
  );
}

describe('refresh rates', () => {
  it('tracks wall-clock time on every panel the game will meet', () => {
    const rows = [30, 60, 90, 120, 144].map((hz) => cadence(hz));
    for (const row of rows) report('[promotion]', row);

    for (const row of rows) {
      // One frame of debt is not drift: the accumulator is *meant* to hold the
      // remainder. Anything past a single step means time is being invented or
      // thrown away, and over a minute that is what would show.
      expect(Math.abs(row.driftMs)).toBeLessThanOrEqual(Math.round(DT * 1000) + 1);
      // The cap exists for a stalled tab. A healthy frame must never reach it,
      // because a frame that does has already dropped simulated time on the
      // floor - `accumulateSteps` empties the accumulator when it saturates.
      expect(row.maxStepsInFrame).toBeLessThan(MAX_STEPS);
      // Alpha is what the renderer interpolates with. At or above 1 it would be
      // drawing a state the sim has not stepped to yet.
      expect(row.alphaMax).toBeLessThan(1);
      expect(row.alphaMin).toBeGreaterThanOrEqual(0);
    }
  });

  it('halves the sim rate on a 120 Hz panel rather than doubling it', () => {
    const promotion = cadence(120);
    // The design decision made visible: a ProMotion phone renders twice per
    // simulated step and interpolates the frame in between. That is what the
    // fixed timestep buys - identical physics on every device - and the cost is
    // that half the frames on such a panel are an interpolation. They are not
    // duplicates: alpha moves, so the picture does.
    expect(promotion.interpolatedPct).toBeGreaterThan(45);
    expect(promotion.interpolatedPct).toBeLessThan(55);
    expect(promotion.maxStepsInFrame).toBe(1);
    expect(promotion.alphaMax).toBeGreaterThan(0.4);
  });

  it('holds through vsync jitter, not just exact intervals', () => {
    const rows = [60, 120].map((hz) => cadence(hz, 0.25));
    for (const row of rows) report('[promotion jitter]', row);
    for (const row of rows) {
      expect(Math.abs(row.driftMs)).toBeLessThanOrEqual(Math.round(DT * 1000) + 1);
      expect(row.maxStepsInFrame).toBeLessThanOrEqual(2);
      expect(row.alphaMax).toBeLessThan(1);
    }
  });

  it('drops the backlog after a stall instead of fast-forwarding the sim', () => {
    // A tab that was away for four seconds, on a 120 Hz panel. `GameLoop.frame`
    // clamps a single elapsed to 0.25 s before it ever reaches this arithmetic,
    // and `resync` zeroes the accumulator on the visibility change - both of
    // those exist so that the fish are where the player left them rather than
    // four seconds downstream.
    const stalled = accumulateSteps(0, 4, DT, MAX_STEPS);
    expect(stalled.steps).toBe(MAX_STEPS);
    expect(stalled.accumulator).toBe(0);
    // And the frame after the stall is an ordinary frame again.
    const next = accumulateSteps(stalled.accumulator, 1 / 120, DT, MAX_STEPS);
    expect(next.steps).toBe(0);
    expect(next.accumulator / DT).toBeLessThan(1);
  });
});
