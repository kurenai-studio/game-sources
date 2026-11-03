import { describe, expect, it } from 'vitest';
import { BREACH_RANK, CAMPAIGNS, DIFFICULTY, SUPPRESSOR_RANK } from '../src/levels/campaigns';
import { hasBreachCharge, newProgress } from '../src/game/progress';
import { WEAPONS } from '../src/game/weapons';

describe('gun roles', () => {
  const vest = Math.max(...DIFFICULTY.map((d) => d.toughness));

  it('suspects get no softer as rank goes up', () => {
    for (let i = 1; i < DIFFICULTY.length; i++) expect(DIFFICULTY[i].toughness).toBeGreaterThanOrEqual(DIFFICULTY[i - 1].toughness);
  });

  it('the rifle stops a vested suspect in one hit and the shotgun can at close range', () => {
    expect(WEAPONS.rifle.damage).toBeGreaterThanOrEqual(vest);
    expect(WEAPONS.shotgun.damage * WEAPONS.shotgun.pellets).toBeGreaterThanOrEqual(vest);
  });

  it('the sniper rifle stops anyone in one hit and outranges everything', () => {
    expect(WEAPONS.sniper.damage).toBeGreaterThanOrEqual(vest + 1);
    for (const w of Object.values(WEAPONS)) if (w.id !== 'sniper') expect(WEAPONS.sniper.range).toBeGreaterThan(w.range);
  });

  it('suppressors fit everything but the shotgun', () => {
    for (const w of Object.values(WEAPONS)) expect(w.suppressible).toBe(w.id !== 'shotgun');
  });

  it('guns are issued in order: shotgun, rifle, sniper rifle, then suppressors', () => {
    expect(CAMPAIGNS.map((c) => c.promotion.unlocks)).toEqual(['shotgun', 'rifle', 'sniper', undefined, undefined, undefined]);
    // The sniper rifle comes with the promotion out of its campaign; suppressors a rank later.
    const sniperRank = CAMPAIGNS.find((c) => c.promotion.unlocks === 'sniper')!.rank + 1;
    expect(SUPPRESSOR_RANK).toBe(sniperRank + 1);
    // The breach charge comes last, a rank after the suppressors.
    expect(BREACH_RANK).toBe(SUPPRESSOR_RANK + 1);
    expect(hasBreachCharge({ ...newProgress(), rank: SUPPRESSOR_RANK })).toBe(false);
    expect(hasBreachCharge({ ...newProgress(), rank: BREACH_RANK })).toBe(true);
  });

  it('every gun says what it is for', () => {
    for (const w of Object.values(WEAPONS)) expect(w.blurb.length).toBeGreaterThan(0);
  });
});
