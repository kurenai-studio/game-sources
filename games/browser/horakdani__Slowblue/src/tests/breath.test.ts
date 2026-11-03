import { describe, expect, it } from 'vitest';
import {
  BREATH_INHALE,
  BREATH_PERIOD,
  breathAt,
  breathFlow,
  breathPhase,
} from '../src/sim/Breath';

/**
 * The breath is the one clock in the game derived from the player's body rather than
 * from the water, so what is asserted here is the three claims the design rests on:
 * it is the rate it says it is, it *rests* at both ends, and the out-breath is longer
 * than the in-breath. A sine would pass none of the last two.
 */
describe('breath', () => {
  it('is a coherent-breathing rate: 5.45 breaths a minute', () => {
    expect(BREATH_PERIOD).toBe(11);
    expect(60 / BREATH_PERIOD).toBeCloseTo(5.45, 1);
  });

  it('runs from empty through full and back, once per period', () => {
    expect(breathAt(0)).toBeCloseTo(0, 6);
    expect(breathAt(BREATH_PERIOD * BREATH_INHALE)).toBeCloseTo(1, 6);
    expect(breathAt(BREATH_PERIOD)).toBeCloseTo(0, 6);
    // Same phase a hundred breaths later: nothing accumulates, because nothing is state.
    expect(breathAt(BREATH_PERIOD * 100.25)).toBeCloseTo(breathAt(BREATH_PERIOD * 0.25), 10);
  });

  it('never leaves 0..1, and is monotone within each half', () => {
    let prev = -1;
    for (let t = 0; t <= BREATH_PERIOD * BREATH_INHALE; t += 0.05) {
      const v = breathAt(t);
      expect(v).toBeGreaterThanOrEqual(0);
      expect(v).toBeLessThanOrEqual(1);
      expect(v).toBeGreaterThanOrEqual(prev);
      prev = v;
    }
    prev = 2;
    for (let t = BREATH_PERIOD * BREATH_INHALE; t <= BREATH_PERIOD; t += 0.05) {
      const v = breathAt(t);
      expect(v).toBeLessThanOrEqual(prev + 1e-9);
      prev = v;
    }
  });

  /**
   * The property that separates this from a sine, and the reason the picture does not
   * read as a pulse: at the top and the bottom of the breath the swell stops moving
   * completely. A sine's derivative is at its *maximum* through the middle of its
   * range and never zero anywhere the eye is looking.
   */
  it('rests at both turns', () => {
    const eps = 0.02;
    const top = BREATH_PERIOD * BREATH_INHALE;
    const dTop = Math.abs(breathAt(top + eps) - breathAt(top - eps)) / (2 * eps);
    const dBottom = Math.abs(breathAt(eps) - breathAt(-eps)) / (2 * eps);
    // ...against the rate through the middle of the inhale, which is where it is fastest.
    const mid = top * 0.5;
    const dMid = Math.abs(breathAt(mid + eps) - breathAt(mid - eps)) / (2 * eps);
    expect(dTop).toBeLessThan(dMid * 0.05);
    expect(dBottom).toBeLessThan(dMid * 0.05);
  });

  it('exhales for longer than it inhales', () => {
    expect(BREATH_INHALE).toBeLessThan(0.5);
    const inhale = BREATH_PERIOD * BREATH_INHALE;
    const exhale = BREATH_PERIOD - inhale;
    expect(exhale).toBeGreaterThan(inhale * 1.2);
  });

  it('flows positive breathing in and negative breathing out', () => {
    const top = BREATH_PERIOD * BREATH_INHALE;
    expect(breathFlow(top * 0.5)).toBeGreaterThan(0.9);
    expect(breathFlow(top + (BREATH_PERIOD - top) * 0.5)).toBeLessThan(-0.9);
    // Zero at the turns, which is what makes act III's gravity wave reverse at the
    // top and the bottom of the breath rather than mid-swell. `LayeredFlow.waveAt`
    // is the only thing left that reads the flow, and it turns on the sign.
    expect(Math.abs(breathFlow(0))).toBeLessThan(1e-9);
    expect(Math.abs(breathFlow(top))).toBeLessThan(1e-9);
    for (let t = -3; t < 25; t += 0.037) {
      expect(Math.abs(breathFlow(t))).toBeLessThanOrEqual(1.0001);
    }
  });

  it('phases correctly for negative and huge times', () => {
    expect(breathPhase(-BREATH_PERIOD * 0.25)).toBeCloseTo(0.75, 10);
    expect(breathAt(-1)).toBeGreaterThanOrEqual(0);
    expect(Number.isFinite(breathAt(1e6))).toBe(true);
  });
});
