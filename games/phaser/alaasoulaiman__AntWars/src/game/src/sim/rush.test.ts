// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for lane G9, M4 (design note, 2026-10-25): the termite rush gets harder each time it comes back,
// counted by appearance (round 5 is the first, round 15 the second), the first rush as before, every part capped.
import { describe, expect, it } from 'vitest';
import { BREATHER_COUNT, BREATHER_SPAWN_GAP, MAX_ALIVE, breatherAppearance, breatherByAppearance, roundPlan, spawnGapSeconds } from './curve';
import { dailySpawnKinds } from './daily';
import { PREDATORS } from './roster';

// [appearance, round, termites, the rush's own gap s, the round's gap s, bite share, shots to drop one]
// Lane N1, design note of 2026-10-29: from round 6 no round spawns slower than the horde gap of its number, so the
// round's gap is the faster of the rush's own and the horde's (0.27 s at round 15 before, the horde's 0.2438 now; the
// 0.1 s floor from round 35). The own gap (breatherByAppearance) is unchanged.
const TABLE = [
  [1, 5, 40, 0.3, 0.3, 1, 1],
  [2, 15, 48, 0.27, 0.243837489558, 1.15, 1],
  [3, 35, 56, 0.243, 0.1, 1.3, 2],
  [4, 45, 64, 0.2187, 0.1, 1.45, 2],
  [5, 55, 72, 0.19683, 0.1, 1.6, 2],
  [6, 65, 80, 0.177147, 0.1, 1.75, 3],
  [7, 85, 88, 0.1594323, 0.1, 1.9, 3],
  [8, 95, 96, 0.15, 0.1, 2, 3],
] as const;

describe('the termite rush by appearance (lane G9, M4)', () => {
  it.each(TABLE)('appearance %i is round %i: %i termites, %f s apart on their own, %f s in the round, at most 20 alive', (n, round, count, own, gap) => {
    const p = roundPlan(round);
    expect(p.kind).toBe('breather');
    expect(p.total).toBe(count);
    const ownGap = breatherByAppearance(n).gap;
    expect(ownGap).toBeCloseTo(own, 9);
    expect(p.spawnGap).toBeCloseTo(gap, 9);
    expect(p.spawnGap).toBe(round >= 6 ? Math.min(ownGap, spawnGapSeconds(round)) : ownGap);
    expect(p.aliveCap).toBe(MAX_ALIVE);
  });

  it.each(TABLE)('appearance %i (round %i, %i termites, %f s on their own, %f s in the round): a bite of x%f of the first rush, %i shots to drop one', (n, round, _count, _own, _gap, bite, hits) => {
    expect(breatherAppearance(round)).toBe(n);
    const spec = breatherByAppearance(n);
    expect(spec.bite).toBeCloseTo(bite, 9);
    expect(spec.hits).toBe(hits);
    const p = roundPlan(round);
    expect(p.termiteBite).toBeCloseTo(bite, 9);
    expect(p.termiteHits).toBe(hits);
    // The scene's bite: the termite's own bite times the share, rounded (8 at the first rush, 16 at the cap).
    expect(PREDATORS.termite.biteDamage).toBe(8);
    expect(Math.round(PREDATORS.termite.biteDamage * p.termiteBite)).toBe([8, 9, 10, 12, 13, 14, 15, 16][n - 1]);
  });

  it('the first rush is exactly as before; each later one is harder on count, pace and bite up to the caps, never a wall', () => {
    expect(breatherByAppearance(1)).toEqual({ count: BREATHER_COUNT, gap: BREATHER_SPAWN_GAP, bite: 1, hits: 1 });
    for (let n = 2; n <= 8; n++) {
      const a = breatherByAppearance(n - 1);
      const b = breatherByAppearance(n);
      expect(b.count).toBeGreaterThan(a.count);
      expect(b.gap).toBeLessThan(a.gap);
      expect(b.bite).toBeGreaterThan(a.bite);
      expect(b.hits).toBeGreaterThanOrEqual(a.hits);
    }
    for (let n = 1; n <= 60; n++) {
      const s = breatherByAppearance(n);
      expect(s.count).toBeLessThanOrEqual(100);
      expect(s.gap).toBeGreaterThanOrEqual(0.15);
      expect(s.bite).toBeLessThanOrEqual(2);
      expect(s.hits).toBeLessThanOrEqual(3);
    }
    expect(breatherByAppearance(30)).toEqual({ count: 100, gap: 0.15, bite: 2, hits: 3 });
    expect(() => breatherByAppearance(0)).toThrow(RangeError);
  });

  it('counts appearances, not round numbers: the boss rounds between keep their place and take no count', () => {
    const rush: number[] = [];
    for (let r = 1; r <= 100; r++) if (roundPlan(r).kind === 'breather') rush.push(r);
    expect(rush).toEqual([5, 15, 35, 45, 55, 65, 85, 95]);
    expect(rush.map((r) => breatherAppearance(r))).toEqual([1, 2, 3, 4, 5, 6, 7, 8]);
    for (const r of [10, 20, 25, 30, 50]) {
      expect(roundPlan(r).kind).toBe('boss');
      expect(roundPlan(r).termiteBite).toBe(1);
      expect(roundPlan(r).termiteHits).toBe(1);
    }
    expect(roundPlan(6).termiteHits).toBe(1);
  });

  it('the Daily order is unchanged: a bigger rush draws its extra termites after the same first 40 from the same stream', () => {
    for (const r of [5, 15, 35]) {
      const n = roundPlan(r).total;
      const kinds = dailySpawnKinds('2026-10-25', r, n);
      expect(kinds.length).toBe(n);
      expect(kinds.slice(0, 40)).toEqual(dailySpawnKinds('2026-10-25', r, 40));
      expect(new Set(kinds)).toEqual(new Set(['termite']));
    }
  });
});
