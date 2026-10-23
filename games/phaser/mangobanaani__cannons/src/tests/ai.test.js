import { describe, it, expect } from 'vitest';
import { calculateAIShot } from '../src/game/utils/ai.js';

describe('calculateAIShot', () => {
  it('returns angle and power', () => {
    const shot = calculateAIShot(680, 400, 120, 400, 0.3, 15);
    expect(shot).toHaveProperty('angle');
    expect(shot).toHaveProperty('power');
  });

  it('angle is between 0 and PI/2', () => {
    for (let i = 0; i < 20; i++) {
      const shot = calculateAIShot(680, 400, 120, 400, 0.3, 15);
      expect(shot.angle).toBeGreaterThan(0);
      expect(shot.angle).toBeLessThan(Math.PI / 2);
    }
  });

  it('power is within valid range', () => {
    for (let i = 0; i < 20; i++) {
      const shot = calculateAIShot(680, 400, 120, 400, 0.3, 15);
      expect(shot.power).toBeGreaterThanOrEqual(1);
      expect(shot.power).toBeLessThanOrEqual(15);
    }
  });

  it('produces varied shots due to randomness', () => {
    const angles = new Set();
    for (let i = 0; i < 20; i++) {
      const shot = calculateAIShot(680, 400, 120, 400, 0.3, 15);
      angles.add(Math.round(shot.angle * 100));
    }
    expect(angles.size).toBeGreaterThan(3);
  });
});
