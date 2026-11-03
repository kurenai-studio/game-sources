import { describe, expect, it } from 'vitest';
import { SNOW_MAX_HZ, SNOW_MIN_HZ, flake, snowRate } from '../src/audio/Snow';
import { bubbleRise } from '../src/audio/Bubbles';

/**
 * Marine snow is the one voice in the campaign that falls and does not arrive,
 * and both halves of that sentence are the design. Everything else in the game
 * either rises (a bubble), sags a little and lands (a crystal), or glides and
 * resolves (a whale). This one is still going down when the envelope runs out.
 */
describe('marine snow', () => {
  it('falls, where the game otherwise rises', () => {
    for (let i = 0; i < 200; i++) {
      const f = flake(Math.random, Math.random(), i % 2 === 0 ? 1 : -1);
      expect(f.glideTo).toBeLessThan(f.hz);
      // A fourth to a seventh: far enough to be a journey rather than a wobble.
      const span = f.hz / f.glideTo;
      expect(span).toBeGreaterThan(1.3);
      expect(span).toBeLessThan(1.9);
    }
    expect(bubbleRise(4)).toBeGreaterThan(1);
  });

  it('is long, quiet, high and never near the middle', () => {
    for (let i = 0; i < 200; i++) {
      const f = flake(Math.random, Math.random(), i % 2 === 0 ? 1 : -1);
      expect(f.duration).toBeGreaterThan(1);
      expect(f.duration).toBeLessThan(2.7);
      expect(f.gain).toBeLessThanOrEqual(1);
      expect(f.hz).toBeGreaterThanOrEqual(SNOW_MIN_HZ * 0.95);
      expect(f.hz).toBeLessThanOrEqual(SNOW_MAX_HZ);
      // A small sound directly in front of you is a sound in a speaker.
      expect(Math.abs(f.pan)).toBeGreaterThanOrEqual(0.45);
      expect(Math.abs(f.pan)).toBeLessThanOrEqual(0.9);
    }
  });

  it('honours the side it is given, so a snowfall is not a leak', () => {
    expect(flake(Math.random, 0.5, 1).pan).toBeGreaterThan(0);
    expect(flake(Math.random, 0.5, -1).pan).toBeLessThan(0);
  });

  it('gets larger and lower on the way down', () => {
    const mean = (depth: number): number => {
      let sum = 0;
      const rand = seq(0.1, 0.4, 0.7, 0.9, 0.2, 0.6);
      for (let i = 0; i < 60; i++) sum += flake(rand, depth, 1).hz;
      return sum / 60;
    };
    expect(mean(1)).toBeLessThan(mean(0));
  });

  /**
   * The density is a hump, and the shape is true: the snow is produced in the
   * sunlit water and most of it is eaten long before the floor. It is also what
   * lets the last station of the campaign be nearly silent, which is what
   * `circle()` needs in order to land.
   */
  it('is thin at the salt line, thick in the middle water and nearly gone on the floor', () => {
    const top = snowRate(0);
    const middle = snowRate(0.55);
    const floor = snowRate(1);
    expect(middle).toBeGreaterThan(top * 2);
    expect(middle).toBeGreaterThan(floor * 2);
    for (let i = 0; i <= 40; i++) {
      const r = snowRate(i / 40);
      expect(r).toBeGreaterThan(0);
      expect(r).toBeLessThan(2);
    }
  });
});

function seq(...values: number[]): () => number {
  let i = 0;
  return () => values[i++ % values.length]!;
}
