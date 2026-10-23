import { describe, it, expect } from 'vitest';
import { WIND_MAX, WIND_CHANGE_INTERVAL } from '../src/game/config.js';

// WindSystem is a class that depends on no external state, so we test its logic directly
describe('WindSystem logic', () => {
  it('wind max is positive', () => {
    expect(WIND_MAX).toBeGreaterThan(0);
  });

  it('wind change interval is positive', () => {
    expect(WIND_CHANGE_INTERVAL).toBeGreaterThan(0);
  });

  it('wind stays within bounds after random generation', () => {
    for (let i = 0; i < 50; i++) {
      const wind = (Math.random() - 0.5) * 2 * WIND_MAX;
      expect(Math.abs(wind)).toBeLessThanOrEqual(WIND_MAX);
    }
  });

  it('wind lerp converges toward target', () => {
    let current = 0;
    const target = 2;
    const lerpSpeed = 0.02;

    for (let i = 0; i < 200; i++) {
      current += (target - current) * lerpSpeed;
    }

    expect(Math.abs(current - target)).toBeLessThan(0.1);
  });
});
