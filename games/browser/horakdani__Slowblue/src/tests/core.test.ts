import { describe, expect, it } from 'vitest';
import { SampleRing, accumulateSteps } from '../src/core/GameLoop';
import { Rng, hashSeed } from '../src/core/rng';
import { limitScale, smoothstep } from '../src/core/math';

describe('fixed timestep', () => {
  const dt = 1 / 60;

  it('converts wall-clock time into whole fixed steps', () => {
    expect(accumulateSteps(0, 1 / 30, dt, 5).steps).toBe(2);
    expect(accumulateSteps(0, 1 / 60, dt, 5).steps).toBe(1);
    expect(accumulateSteps(0, 1 / 200, dt, 5).steps).toBe(0);
  });

  it('carries the remainder so no simulated time is lost', () => {
    let acc = 0;
    let total = 0;
    for (let i = 0; i < 600; i++) {
      const r = accumulateSteps(acc, 1 / 90, dt, 5);
      acc = r.accumulator;
      total += r.steps;
    }
    // 600 frames at 90fps = 6.667s of simulated time ~= 400 steps at 60Hz
    // (float accumulation may land one step short of the exact boundary).
    expect(total).toBeGreaterThanOrEqual(399);
    expect(total).toBeLessThanOrEqual(400);
  });

  it('caps catch-up work and drops the backlog after a long stall', () => {
    const r = accumulateSteps(0, 10, dt, 5);
    expect(r.steps).toBe(5);
    expect(r.accumulator).toBe(0);
  });
});

/**
 * The p95 the iOS gate is written against ("p95 frame time under 16.7 ms on the
 * heaviest scene"). A percentile is the one debug reading nobody can eyeball for
 * plausibility on a phone, so the arithmetic is pinned here instead: the failure this
 * guards against is a ring that quietly reports the padding it was initialised with,
 * or an off-by-one that returns the max and turns a passing device into a failing one.
 */
describe('frame-time percentiles', () => {
  it('reads the nearest rank, not the maximum', () => {
    const r = new SampleRing();
    // 1..100: p95 is the 95th smallest, and the top five must not reach it.
    for (let i = 1; i <= 100; i++) r.push(i);
    expect(r.percentile(0.95)).toBe(95);
    expect(r.percentile(0.5)).toBe(50);
    expect(r.percentile(1)).toBe(100);
  });

  it('ignores the unfilled tail while the ring is still filling', () => {
    const r = new SampleRing();
    // Three samples and 297 empty slots. A percentile over the whole buffer would
    // read 0 (the Float64Array's own zeroes) or Infinity (the sort padding); over
    // what has actually been pushed it reads 9.
    r.push(4);
    r.push(9);
    r.push(2);
    expect(r.percentile(0.95)).toBe(9);
    expect(r.percentile(0)).toBe(2);
  });

  it('forgets samples older than the window', () => {
    const r = new SampleRing();
    for (let i = 0; i < 300; i++) r.push(50);
    expect(r.percentile(0.95)).toBe(50);
    // A full window of the heavy scene, then a full window of the cheap one, with one
    // 900 ms stall at the seam. Reading 3 proves two things at once: the 50s were
    // evicted rather than averaged in, and a single stall does not reach the 95th rank.
    // Walking out of a heavy scene must not keep failing the gate five seconds later.
    for (let i = 0; i < 300; i++) r.push(i === 0 ? 900 : 3);
    expect(r.percentile(0.95)).toBe(3);
  });

  it('reads zero before the first frame', () => {
    expect(new SampleRing().percentile(0.95)).toBe(0);
  });

  /**
   * What `GameLoop.resetSamples` is for, and why a reading taken right after a
   * quality-ladder move has to start from empty.
   *
   * Moving a rung changes what a frame costs - rungs 3 and 4 reallocate the backing
   * store - and without this the next five seconds of percentile are a blend of two
   * different pictures. That is the same class of error the ladder readout was added
   * to stop: a number that looks like a measurement and is an average of two.
   */
  it('starts over when cleared, keeping nothing from before', () => {
    const r = new SampleRing();
    for (let i = 0; i < 300; i++) r.push(50);
    r.clear();
    expect(r.percentile(0.95)).toBe(0);
    // ...and the first sample after a clear is the whole of the reading, rather than
    // the 95th rank of a window that still remembers the old resolution.
    r.push(3);
    expect(r.percentile(0.95)).toBe(3);
  });
});

describe('Rng', () => {
  it('is reproducible for a given seed', () => {
    const a = new Rng(1234);
    const b = new Rng(1234);
    const as = Array.from({ length: 50 }, () => a.next());
    const bs = Array.from({ length: 50 }, () => b.next());
    expect(as).toEqual(bs);
  });

  it('differs between seeds and stays in range', () => {
    const a = new Rng(1);
    const b = new Rng(2);
    let diff = 0;
    for (let i = 0; i < 100; i++) {
      const x = a.next();
      const y = b.next();
      expect(x).toBeGreaterThanOrEqual(0);
      expect(x).toBeLessThan(1);
      if (x !== y) diff++;
    }
    expect(diff).toBeGreaterThan(90);
  });

  it('forks deterministically per salt', () => {
    expect(new Rng(7).fork(3).next()).toBe(new Rng(7).fork(3).next());
    expect(new Rng(7).fork(3).next()).not.toBe(new Rng(7).fork(4).next());
  });

  it('hashes seed strings stably', () => {
    expect(hashSeed('tide')).toBe(hashSeed('tide'));
    expect(hashSeed('tide')).not.toBe(hashSeed('tidf'));
  });
});

describe('math', () => {
  it('limits vector magnitude without changing direction', () => {
    const s = limitScale(300, 400, 100);
    expect(s * 500).toBeCloseTo(100, 6);
    expect(limitScale(3, 4, 100)).toBe(1);
    expect(limitScale(0, 0, 100)).toBe(1);
  });

  it('smoothsteps between edges', () => {
    expect(smoothstep(0, 1, -1)).toBe(0);
    expect(smoothstep(0, 1, 2)).toBe(1);
    expect(smoothstep(0, 1, 0.5)).toBeCloseTo(0.5, 6);
  });
});
