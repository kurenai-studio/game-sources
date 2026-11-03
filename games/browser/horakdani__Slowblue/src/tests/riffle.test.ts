import { describe, expect, it } from 'vitest';
import {
  RIFFLE_MAX_MM,
  RIFFLE_MIN_MM,
  riffleDuration,
  riffleFrequency,
  riffleLevel,
  riffleRadius,
  riffleRate,
  riffleRise,
  stoneGap,
  stoneKnock,
} from '../src/audio/Riffle';
import { bubbleFrequency } from '../src/audio/Bubbles';
import { dropFrequency, dropRadius } from '../src/audio/Raindrops';

/**
 * Three media out of one equation, and the whole argument for doing it that way
 * is that the results have to be unmistakable for each other. That is a testable
 * claim about three bands, so it is tested rather than believed.
 */
describe('the brook', () => {
  it('is Minnaert, like the sea and the rain', () => {
    expect(riffleFrequency(1)).toBeCloseTo(bubbleFrequency(1), 6);
    expect(Number.isFinite(riffleFrequency(0))).toBe(true);
  });

  it('sits between the rain and the sea, and overlaps neither at its centre', () => {
    const mean = (f: (u: number) => number): number => {
      let sum = 0;
      for (let i = 0; i <= 100; i++) sum += f(i / 100);
      return sum / 101;
    };
    const brook = mean((u) => riffleFrequency(riffleRadius(u, 1)));
    const rain = mean((u) => dropFrequency(dropRadius(u, 0.5)));
    const sea = mean((u) => bubbleFrequency(1.6 + u * 7.9));
    expect(brook).toBeLessThan(rain);
    expect(brook).toBeGreaterThan(sea);
  });

  it('rings for milliseconds and rises, like every bubble in the game', () => {
    for (let r = RIFFLE_MIN_MM; r <= RIFFLE_MAX_MM; r += 0.05) {
      const d = riffleDuration(r);
      expect(d).toBeGreaterThan(0.015);
      expect(d).toBeLessThan(0.08);
      expect(riffleRise(r)).toBeGreaterThan(1);
      expect(riffleLevel(r)).toBeGreaterThan(0);
    }
  });

  /**
   * The geography of the handover, in one number. Fast water folds over more
   * often and traps smaller bubbles; the mouth has stopped folding over at all.
   * Act VI ends at the top of that range and act VII opens at the bottom of it.
   */
  it('brightens and thickens with the current, and slows at the mouth', () => {
    const mean = (flow: number): number => {
      let sum = 0;
      for (let i = 0; i <= 100; i++) sum += riffleFrequency(riffleRadius(i / 100, flow));
      return sum / 101;
    };
    expect(mean(1)).toBeGreaterThan(mean(0) * 1.2);
    expect(riffleRate(1, 0.5)).toBeGreaterThan(riffleRate(0, 0.5) * 1.5);
  });

  it('is the densest layer in the campaign, and still resolvable', () => {
    for (let i = 0; i <= 20; i++) {
      for (const b of [0, 0.5, 1]) {
        const rate = riffleRate(i / 20, b);
        expect(rate).toBeGreaterThan(9);
        expect(rate).toBeLessThan(28);
      }
    }
    expect(riffleRate(1, 0)).toBeGreaterThan(riffleRate(1, 1));
  });

  it('clamps every input', () => {
    expect(riffleRadius(-4, -1)).toBeGreaterThanOrEqual(RIFFLE_MIN_MM);
    expect(riffleRadius(7, 3)).toBeLessThanOrEqual(RIFFLE_MAX_MM);
    expect(Number.isFinite(riffleRate(-2, 9))).toBe(true);
  });
});

describe('stones', () => {
  it('are low, short and fall - the only percussive thing left in the game', () => {
    for (let i = 0; i < 200; i++) {
      const s = stoneKnock(Math.random);
      expect(s.hz).toBeGreaterThan(80);
      expect(s.hz).toBeLessThan(230);
      // A stone that stops has been stopped by something.
      expect(s.glideTo).toBeLessThan(s.hz);
      expect(s.duration).toBeGreaterThan(0.2);
      expect(s.duration).toBeLessThan(0.6);
      expect(Math.abs(s.pan)).toBeLessThanOrEqual(0.75);
    }
  });

  it('comes rarely enough to be an event', () => {
    for (let i = 0; i < 40; i++) {
      expect(stoneGap(Math.random)).toBeGreaterThanOrEqual(22);
      expect(stoneGap(Math.random)).toBeLessThanOrEqual(62);
    }
  });
});
