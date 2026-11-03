import { describe, expect, it } from 'vitest';
import { endCareer, isUnlocked, newProgress, recordSuccess, settleAbandonedMission, unlockedWeapons } from '../src/game/progress';
import { CAMPAIGNS, type CampaignDef } from '../src/levels/campaigns';
import { LEVELS } from '../src/levels';

describe('campaign progress', () => {
  const campaigns: CampaignDef[] = [
    { id: 'a', title: 'A', blurb: '', rank: 0, levels: ['a1'], promotion: { minStars: 1, note: [] } },
    { id: 'b', title: 'B', blurb: '', rank: 1, levels: ['b1', 'b2'], promotion: { minStars: 5, unlocks: 'rifle', note: [] } },
  ];

  it('unlocks levels in order and campaigns by rank', () => {
    const p = newProgress();
    expect(isUnlocked(p, 'a1', campaigns)).toBe(true);
    expect(isUnlocked(p, 'b1', campaigns)).toBe(false);
    expect(recordSuccess(p, 'a1', 2, campaigns)?.id).toBe('a');
    expect(p.rank).toBe(1);
    expect(isUnlocked(p, 'b1', campaigns)).toBe(true);
    expect(isUnlocked(p, 'b2', campaigns)).toBe(false);
  });

  it('promotes only with every level done and enough stars, and keeps best stars', () => {
    const p = { ...newProgress(), rank: 1 };
    expect(recordSuccess(p, 'b1', 3, campaigns)).toBeNull();
    expect(recordSuccess(p, 'b2', 1, campaigns)).toBeNull();
    expect(p.rank).toBe(1);
    expect(recordSuccess(p, 'b1', 1, campaigns)).toBeNull();
    expect(p.stars.b1).toBe(3);
    expect(recordSuccess(p, 'b2', 2, campaigns)?.id).toBe('b');
    expect(p.rank).toBe(2);
    expect(unlockedWeapons(p, campaigns)).toEqual(['pistol', 'rifle']);
  });

  it('every campaign level exists and promotion is reachable', () => {
    const ids = new Set(LEVELS.map((l) => l.id));
    for (const c of CAMPAIGNS) {
      for (const id of c.levels) expect(ids.has(id)).toBe(true);
      expect(c.promotion.minStars).toBeLessThanOrEqual(c.levels.length * 3);
    }
  });
});

describe('realism careers', () => {
  it('going down resets to Recruit and stays in realism mode', () => {
    const p = { ...newProgress(true), rank: 2, stars: { a: 3, b: 2 }, completed: ['a', 'b'] };
    const record = endCareer(p, 'b');
    expect(record).toEqual({ rank: 2, stars: 5, levelId: 'b' });
    expect(p).toEqual(newProgress(true));
  });

  it('a mission still deployed on load counts as going down, but only in realism mode', () => {
    const real = { ...newProgress(true), rank: 1, deployed: 'harbour-lane' };
    expect(settleAbandonedMission(real)?.levelId).toBe('harbour-lane');
    expect(real.rank).toBe(0);
    const normal = { ...newProgress(false), rank: 1, deployed: 'harbour-lane' };
    expect(settleAbandonedMission(normal)).toBeNull();
    expect(normal.rank).toBe(1);
  });

  it('finishing a mission clears the deployment', () => {
    const p = { ...newProgress(true), rank: 1, deployed: 'harbour-lane' };
    recordSuccess(p, 'harbour-lane', 2);
    expect(p.deployed).toBeNull();
  });
});
