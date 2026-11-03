import { describe, expect, it } from 'vitest';
import {
  WING_MAX_M,
  WING_MIN_M,
  wingDuration,
  wingFrequency,
  wingLevel,
  wingQ,
  wingSpan,
  wingTipSpeed,
  wingbeatRate,
} from '../src/audio/Wings';

/**
 * Same contract `tests/bubbles.test.ts` holds the water to, one medium up: the
 * span is the only thing anyone picks, so what is worth pinning down is that
 * everything audible really is derived from it, that the derivations land on real
 * birds, and that every wing the sampler can produce is a whoosh rather than a
 * click, a tone or a rumble.
 */
describe('wings', () => {
  it('puts real birds on the allometric line', () => {
    // A 1.2 m gull beats at about 3.4/s and a 0.24 m seabird at about 14.
    expect(wingbeatRate(1.2)).toBeGreaterThan(3);
    expect(wingbeatRate(1.2)).toBeLessThan(4);
    expect(wingbeatRate(0.24)).toBeGreaterThan(12);
    expect(wingbeatRate(0.24)).toBeLessThan(17);
  });

  it('converges on one tip speed, which is why every wing sounds related', () => {
    // Step 2 of the derivation: U = 8 * span^0.1, i.e. almost size-independent.
    // Across a sixfold range of span the tip speed must not even double.
    const slow = wingTipSpeed(WING_MAX_M);
    const fast = wingTipSpeed(WING_MIN_M);
    expect(slow / fast).toBeLessThan(2);
    expect(fast).toBeGreaterThan(4);
    expect(slow).toBeLessThan(12);
  });

  it('lands the noise band where wing noise actually is', () => {
    // Trailing-edge Strouhal: a gull around 200 Hz, a small seabird near 900.
    expect(wingFrequency(1.2)).toBeGreaterThan(150);
    expect(wingFrequency(1.2)).toBeLessThan(280);
    expect(wingFrequency(0.24)).toBeGreaterThan(650);
    expect(wingFrequency(0.24)).toBeLessThan(1100);
  });

  it('keeps the whoosh a fixed multiple of the beat, without tuning it', () => {
    // Both relations carry the same span^-0.9, so the ratio is a constant. A flock
    // is therefore in tune with its own rhythm as a consequence, not a decision.
    const ratio = (s: number): number => wingFrequency(s) / wingbeatRate(s);
    expect(ratio(0.3)).toBeCloseTo(ratio(1.2), 6);
  });

  it('never divides by zero, however absurd the span', () => {
    for (const s of [0, -3, 1e-9]) {
      expect(Number.isFinite(wingbeatRate(s))).toBe(true);
      expect(Number.isFinite(wingFrequency(s))).toBe(true);
      expect(Number.isFinite(wingDuration(s))).toBe(true);
    }
  });

  it('makes a big wing slow, low, long and loud, and a small one the opposite', () => {
    const big = WING_MAX_M;
    const small = WING_MIN_M;
    expect(wingbeatRate(big)).toBeLessThan(wingbeatRate(small));
    expect(wingFrequency(big)).toBeLessThan(wingFrequency(small));
    expect(wingDuration(big)).toBeGreaterThan(wingDuration(small));
    expect(wingLevel(big)).toBeGreaterThan(wingLevel(small));
    // ...and the small one is the tighter, more whistle-like band.
    expect(wingQ(small)).toBeGreaterThan(wingQ(big));
  });

  it('is never a click and never a drone', () => {
    for (let s = 0.05; s <= 3; s += 0.01) {
      const d = wingDuration(s);
      expect(d).toBeGreaterThanOrEqual(0.02);
      expect(d).toBeLessThanOrEqual(0.16);
      expect(wingLevel(s)).toBeGreaterThan(0);
      expect(wingLevel(s)).toBeLessThan(1.5);
      expect(wingQ(s)).toBeGreaterThan(0.5);
      expect(wingQ(s)).toBeLessThan(3);
    }
  });

  it('samples spans inside the band, for any altitude and any draw', () => {
    for (const alt of [0, 0.25, 0.5, 0.75, 1]) {
      for (let i = 0; i <= 40; i++) {
        const s = wingSpan(i / 40, alt);
        expect(s).toBeGreaterThanOrEqual(WING_MIN_M);
        expect(s).toBeLessThanOrEqual(WING_MAX_M);
        // The audible consequence: every wing lands where a rush of air lives, not
        // in the rumble below it or the hiss above.
        const f = wingFrequency(s);
        expect(f).toBeGreaterThan(150);
        expect(f).toBeLessThan(1400);
      }
    }
    expect(wingSpan(-1, 0)).toBeGreaterThanOrEqual(WING_MIN_M);
    expect(wingSpan(9, 1)).toBeLessThanOrEqual(WING_MAX_M);
  });

  /**
   * Altitude is what the act has an opinion about, so it has to move the sound:
   * the spray is small quick seabirds, the tropopause is enormous slow wings. This
   * is the ascent audible in the air with the picture ignored.
   */
  it('makes the heights bigger and slower than the spray', () => {
    const meanRate = (alt: number): number => {
      let sum = 0;
      for (let i = 0; i <= 100; i++) sum += wingbeatRate(wingSpan(i / 100, alt));
      return sum / 101;
    };
    expect(meanRate(1)).toBeLessThan(meanRate(0) * 0.75);
    expect(wingSpan(0, 1)).toBeGreaterThan(wingSpan(0, 0));
  });

  it('is monotone in the draw, so a uniform sampler gives a smooth distribution', () => {
    let prev = 0;
    for (let i = 0; i <= 100; i++) {
      const s = wingSpan(i / 100, 0.4);
      expect(s).toBeGreaterThanOrEqual(prev);
      prev = s;
    }
  });
});
