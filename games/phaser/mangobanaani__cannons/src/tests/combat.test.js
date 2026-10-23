import { describe, it, expect } from 'vitest';
import { calculateDamage } from '../src/game/utils/combat.js';

describe('calculateDamage', () => {
  it('returns max damage for direct hit', () => {
    const dmg = calculateDamage(100, 400, 100, 400, 40, 35);
    expect(dmg).toBe(35);
  });

  it('returns zero outside blast radius', () => {
    const dmg = calculateDamage(100, 400, 200, 400, 40, 35);
    expect(dmg).toBe(0);
  });

  it('returns partial damage for near miss', () => {
    const dmg = calculateDamage(100, 400, 120, 400, 40, 35);
    expect(dmg).toBeGreaterThan(0);
    expect(dmg).toBeLessThan(35);
  });

  it('damage decreases with distance', () => {
    const close = calculateDamage(100, 400, 110, 400, 40, 35);
    const far = calculateDamage(100, 400, 130, 400, 40, 35);
    expect(close).toBeGreaterThan(far);
  });

  it('returns zero for exactly at blast radius', () => {
    const dmg = calculateDamage(100, 400, 140, 400, 40, 35);
    expect(dmg).toBe(0);
  });
});
