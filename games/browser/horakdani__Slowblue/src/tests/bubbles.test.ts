import { describe, expect, it } from 'vitest';
import {
  BUBBLE_MAX_MM,
  BUBBLE_MIN_MM,
  bubbleDuration,
  bubbleFrequency,
  bubbleLevel,
  bubbleRadius,
  bubbleRise,
} from '../src/audio/Bubbles';

/**
 * The point of deriving the water sound from a bubble radius is that the radius is the
 * only thing anyone picks - so what is worth pinning down is that the derivation is
 * Minnaert's and not a curve that happens to sound right today, and that every bubble the
 * sampler can produce lands in the band a person hears as water rather than as fizz or as
 * a tone.
 */
describe('bubbles', () => {
  it('is Minnaert resonance, not a tuned curve', () => {
    // f0 = 3.26 / r with r in metres. A 1 mm bubble is the textbook 3.26 kHz.
    expect(bubbleFrequency(1)).toBeCloseTo(3260, 0);
    // ...and the relationship is inverse in the radius, exactly.
    expect(bubbleFrequency(2) * 2).toBeCloseTo(bubbleFrequency(1), 6);
    expect(bubbleFrequency(8) * 4).toBeCloseTo(bubbleFrequency(2), 6);
  });

  it('never divides by zero, however absurd the radius', () => {
    expect(Number.isFinite(bubbleFrequency(0))).toBe(true);
    expect(Number.isFinite(bubbleFrequency(-5))).toBe(true);
  });

  it('makes a big bubble low, long and loud, and a small one the opposite', () => {
    const big = BUBBLE_MAX_MM;
    const small = BUBBLE_MIN_MM;
    expect(bubbleFrequency(big)).toBeLessThan(bubbleFrequency(small));
    expect(bubbleDuration(big)).toBeGreaterThan(bubbleDuration(small));
    expect(bubbleLevel(big)).toBeGreaterThan(bubbleLevel(small));
    // The small one rises further in pitch, which is what makes a gurgle move.
    expect(bubbleRise(small)).toBeGreaterThan(bubbleRise(big));
  });

  /**
   * The two failure modes at the ends of the range: a bubble short enough to be a click,
   * and one long enough to be a note. Both are excluded by construction.
   */
  it('is never a click and never a tone', () => {
    for (let r = 0.1; r <= 40; r += 0.1) {
      const d = bubbleDuration(r);
      expect(d).toBeGreaterThanOrEqual(0.022);
      expect(d).toBeLessThanOrEqual(0.2);
      const rise = bubbleRise(r);
      expect(rise).toBeGreaterThan(1);
      expect(rise).toBeLessThan(1.4);
      expect(bubbleLevel(r)).toBeGreaterThan(0);
      expect(bubbleLevel(r)).toBeLessThan(1.5);
    }
  });

  it('samples radii inside the band, for any depth and any draw', () => {
    for (const depth of [0, 0.25, 0.5, 0.75, 1]) {
      for (let i = 0; i <= 40; i++) {
        const r = bubbleRadius(i / 40, depth);
        expect(r).toBeGreaterThanOrEqual(BUBBLE_MIN_MM);
        expect(r).toBeLessThanOrEqual(BUBBLE_MAX_MM);
        // The audible consequence: everything lands where water lives, not where fizz
        // (above ~5 kHz) or a hum (below ~200 Hz) does.
        const f = bubbleFrequency(r);
        expect(f).toBeGreaterThan(200);
        expect(f).toBeLessThan(5000);
      }
    }
    // Out-of-range draws are clamped rather than extrapolated.
    expect(bubbleRadius(-1, 0)).toBeGreaterThanOrEqual(BUBBLE_MIN_MM);
    expect(bubbleRadius(9, 1)).toBeLessThanOrEqual(BUBBLE_MAX_MM);
  });

  /**
   * Depth is the one thing the campaign has an opinion about, so it has to actually move
   * the sound: the trench floor gets the big low ones, the shallows small bright ones.
   */
  it('makes the deep bigger and lower than the shallows', () => {
    const mean = (depth: number): number => {
      let sum = 0;
      for (let i = 0; i <= 100; i++) sum += bubbleFrequency(bubbleRadius(i / 100, depth));
      return sum / 101;
    };
    expect(mean(1)).toBeLessThan(mean(0) * 0.9);
    expect(bubbleRadius(0, 1)).toBeGreaterThan(bubbleRadius(0, 0));
  });

  it('is monotone in the draw, so a uniform sampler gives a smooth distribution', () => {
    let prev = 0;
    for (let i = 0; i <= 100; i++) {
      const r = bubbleRadius(i / 100, 0.4);
      expect(r).toBeGreaterThanOrEqual(prev);
      prev = r;
    }
  });
});
