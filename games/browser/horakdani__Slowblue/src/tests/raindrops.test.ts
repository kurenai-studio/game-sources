import { describe, expect, it } from 'vitest';
import {
  DROP_MAX_MM,
  DROP_MIN_MM,
  dropDuration,
  dropFrequency,
  dropImpactHz,
  dropLevel,
  dropRadius,
  dropRate,
  dropRise,
  patterGrain,
  patterRate,
  sheetAt,
} from '../src/audio/Raindrops';
import { BUBBLE_MIN_MM, bubbleFrequency } from '../src/audio/Bubbles';

/**
 * The claim act VI is built on is that rain is bubbles - the plink is the air the
 * splash entrained, not the impact - so the first thing worth testing is that it
 * really is the same equation act I's water is, at the other end of the range.
 */
describe('raindrops', () => {
  it('is the same Minnaert resonance as the deep sea', () => {
    expect(dropFrequency(1)).toBeCloseTo(bubbleFrequency(1), 6);
    expect(dropFrequency(2) * 2).toBeCloseTo(dropFrequency(1), 6);
    expect(Number.isFinite(dropFrequency(0))).toBe(true);
  });

  /**
   * ...and at a tenth of the size, so the two acts cannot be confused. A drop's
   * bubble is smaller than anything that comes off a rock at forty metres, which
   * is why one is a plink and the other is a bloop.
   */
  it('is an order of magnitude smaller than act I is', () => {
    expect(DROP_MAX_MM).toBeLessThan(BUBBLE_MIN_MM);
    for (let u = 0; u <= 1; u += 0.02) {
      for (const sheet of [0, 0.5, 1]) {
        const f = dropFrequency(dropRadius(u, sheet));
        // Rain lives where it is heard as bright and small.
        expect(f).toBeGreaterThan(1800);
        expect(f).toBeLessThan(11000);
      }
    }
  });

  it('rings for milliseconds, never long enough to be a chime', () => {
    for (let r = DROP_MIN_MM; r <= DROP_MAX_MM; r += 0.02) {
      const d = dropDuration(r);
      expect(d).toBeGreaterThanOrEqual(0.012);
      expect(d).toBeLessThanOrEqual(0.05);
      expect(dropRise(r)).toBeGreaterThan(1);
      expect(dropLevel(r)).toBeGreaterThan(0);
      // The splash sits above the ring, so it is a texture under it rather than a
      // second pitch beside it.
      expect(dropImpactHz(r)).toBeGreaterThan(dropFrequency(r));
    }
  });

  it('deepens in a heavier sheet rather than only getting busier', () => {
    const mean = (sheet: number): number => {
      let sum = 0;
      for (let i = 0; i <= 100; i++) sum += dropRadius(i / 100, sheet);
      return sum / 101;
    };
    expect(mean(1)).toBeGreaterThan(mean(0) * 1.15);
  });
});

describe('the sheet', () => {
  /**
   * Rain does not fall at a rate, and the swing is most of what makes it restful:
   * the texture is always changing and nothing ever *happens*. What must be true
   * is that it stays inside its bounds, moves properly, and does not repeat inside
   * a station.
   */
  it('stays in range and always moves', () => {
    let lo = 1;
    let hi = 0;
    let prev = sheetAt(0);
    for (let t = 0; t < 900; t += 0.25) {
      const s = sheetAt(t);
      expect(s).toBeGreaterThanOrEqual(0);
      expect(s).toBeLessThanOrEqual(1);
      lo = Math.min(lo, s);
      hi = Math.max(hi, s);
      expect(Math.abs(s - prev)).toBeLessThan(0.05);
      prev = s;
    }
    // A swing worth having: about a factor of three in the drop rate.
    expect(hi - lo).toBeGreaterThan(0.4);
  });

  it('does not repeat inside anything anybody will play', () => {
    // The three periods share no factor, so the pattern is ~11 minutes long. Half
    // a period in, it must not have come back to where it started.
    for (const t of [23, 37, 61, 120]) {
      expect(Math.abs(sheetAt(t) - sheetAt(0))).toBeGreaterThan(0.001);
    }
  });
});

describe('the rain schedule', () => {
  it('stays between a leaking gutter and a hiss', () => {
    for (let i = 0; i <= 20; i++) {
      for (const b of [0, 0.5, 1]) {
        const rate = dropRate(i / 20, b);
        // Below about eight a second the ear starts counting; above about
        // twenty-five the rings stop resolving and it collapses into noise.
        expect(rate).toBeGreaterThan(8);
        expect(rate).toBeLessThan(25);
      }
    }
  });

  it('is busier on the out-breath, the way act I water is', () => {
    expect(dropRate(0.5, 0)).toBeGreaterThan(dropRate(0.5, 1));
  });

  it('patters denser and drier than it drops', () => {
    expect(patterRate(0.5)).toBeGreaterThan(dropRate(0.5, 0.5));
    for (let i = 0; i < 200; i++) {
      const g = patterGrain(Math.random, Math.random());
      // High, short and broad: a leaf is not a resonator.
      expect(g.hz).toBeGreaterThan(2400);
      expect(g.q).toBeLessThan(3);
      expect(g.duration).toBeLessThan(0.06);
      expect(Math.abs(g.pan)).toBeLessThanOrEqual(0.9);
    }
  });
});
