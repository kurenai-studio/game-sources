import { describe, expect, it } from 'vitest';
import { BELL, bellStatus, tollBell } from '@/game/systems/bell';

describe('toll bell', () => {
  it('trades resolve for a burst and starts the cooldown', () => {
    const result = tollBell(100, 5_000, 0);
    expect(result).toEqual({
      rung: true,
      hp: 100 - BELL.cost,
      readyAt: 5_000 + BELL.cooldownMs,
      damage: BELL.damage,
      staggerUntil: 5_000 + BELL.staggerMs,
    });
  });

  it('stays silent while it is still humming', () => {
    expect(tollBell(100, 5_000, 6_000)).toEqual({ rung: false, blockedBy: 'cooldown' });
    expect(bellStatus(100, 5_000, 6_000)).toEqual({ ready: false, readyInMs: 1_000, blockedBy: 'cooldown' });
    expect(bellStatus(100, 6_000, 6_000).ready).toBe(true);
  });

  it('can never be the thing that kills you', () => {
    expect(tollBell(BELL.cost, 0, 0)).toEqual({ rung: false, blockedBy: 'resolve' });
    expect(tollBell(BELL.cost + 1, 0, 0)).toMatchObject({ rung: true, hp: 1 });
    // ringing repeatedly from full resolve always leaves you standing
    let hp = 100;
    let readyAt = 0;
    for (let now = 0; now < 120_000; now += 500) {
      const result = tollBell(hp, now, readyAt);
      if (result.rung) {
        hp = result.hp;
        readyAt = result.readyAt;
      }
      expect(hp).toBeGreaterThan(0);
    }
    expect(hp).toBeLessThanOrEqual(BELL.cost);
  });

  it('one toll is enough to clear a weak first-depth room but not a Tollmother', () => {
    // base hit points: siltling 40, ashmoth 34; the Tollmother has 920
    expect(BELL.damage).toBeGreaterThanOrEqual(40);
    expect(BELL.damage * 6).toBeLessThan(920);
  });
});
