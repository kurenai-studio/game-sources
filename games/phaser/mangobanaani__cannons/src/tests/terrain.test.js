import { describe, it, expect } from 'vitest';
import { generateHeightmap, carveCrater } from '../src/game/utils/terrain.js';

describe('generateHeightmap', () => {
  it('returns array of correct length', () => {
    const hm = generateHeightmap(100, 300, 500);
    expect(hm.length).toBe(100);
  });

  it('all values within min/max range', () => {
    const hm = generateHeightmap(200, 300, 500);
    for (const h of hm) {
      expect(h).toBeGreaterThanOrEqual(300);
      expect(h).toBeLessThanOrEqual(500);
    }
  });

  it('produces varied terrain', () => {
    const hm = generateHeightmap(100, 300, 500);
    const unique = new Set(hm.map(h => Math.round(h)));
    expect(unique.size).toBeGreaterThan(5);
  });
});

describe('carveCrater', () => {
  it('lowers terrain at impact center', () => {
    const hm = new Array(100).fill(400);
    carveCrater(hm, 50, 20, 30, 600);
    expect(hm[50]).toBeGreaterThan(400);
  });

  it('does not affect terrain outside radius', () => {
    const hm = new Array(100).fill(400);
    carveCrater(hm, 50, 10, 30, 600);
    expect(hm[0]).toBe(400);
    expect(hm[99]).toBe(400);
  });

  it('crater is deepest at center', () => {
    const hm = new Array(100).fill(400);
    carveCrater(hm, 50, 20, 30, 600);
    expect(hm[50]).toBeGreaterThan(hm[40]);
  });

  it('does not push terrain below maxY', () => {
    const hm = new Array(100).fill(590);
    carveCrater(hm, 50, 20, 30, 600);
    for (const h of hm) {
      expect(h).toBeLessThanOrEqual(600);
    }
  });
});
