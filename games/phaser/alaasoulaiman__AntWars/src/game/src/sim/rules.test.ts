// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for the roster (section 5), the shooting rule (section 4), the nest shop (section 3) and the best round.
import { describe, expect, it } from 'vitest';
import { PREDATOR_SPEED_CAP, enemyHealth } from './curve';
import { PREDATORS, pickPredator, predatorHealth, predatorSpeedShare, type PredatorKind } from './roster';
import {
  BASE_ANT,
  PERKS,
  applyPerk,
  buyPerk,
  canBuy,
  critChance,
  fireIntervalSeconds,
  killNectar,
  perkCount,
  shopState,
  trackLeftNest,
  type PerkId,
} from './economy';
import { BEST_KEY, readBest, recordRun, type KeyValueStore } from './best';

const KINDS: PredatorKind[] = ['armyAnt', 'wasp', 'spider', 'termite'];
const ROLLS = [0, 0.05, 0.1, 0.17, 0.2, 0.29, 0.31, 0.36, 0.42, 0.45, 0.5, 0.9, 0.999];

describe('roster', () => {
  it('no predator ever passes 94 percent of the ant', () => {
    for (const kind of KINDS) {
      for (let round = 1; round <= 60; round++) {
        for (const roll of ROLLS) expect(predatorSpeedShare(kind, round, roll)).toBeLessThanOrEqual(PREDATOR_SPEED_CAP);
      }
    }
  });

  it.each([
    [1, ['armyAnt']], [4, ['armyAnt']], [6, ['armyAnt', 'wasp']], [7, ['armyAnt', 'wasp', 'ember']],
    [8, ['armyAnt', 'wasp', 'spider', 'ember']], [11, ['armyAnt', 'wasp', 'spider', 'ember', 'moth']],
    [12, ['armyAnt', 'wasp', 'spider', 'beetle', 'ember', 'moth']],
  ])('round %i spawns only %j', (round, allowed) => {
    const seen = new Set(ROLLS.map((roll) => pickPredator(round as number, roll)));
    expect([...seen].sort()).toEqual([...(allowed as string[])].sort());
  });

  it.each([5, 10, 15, 20])('breather round %i is all termites', (round) => {
    for (const roll of ROLLS) expect(pickPredator(round, roll)).toBe('termite');
  });

  it('health scales off the round curve, termites keep 1 HP', () => {
    expect(predatorHealth('armyAnt', enemyHealth(1))).toBe(150);
    expect(predatorHealth('wasp', enemyHealth(6))).toBe(390);
    expect(predatorHealth('spider', enemyHealth(8))).toBe(1275);
    expect(predatorHealth('termite', enemyHealth(30))).toBe(1);
  });

  it('the breather termite is weak: its bite does at most a sixth of an army ant bite', () => {
    expect(PREDATORS.termite.biteDamage * 6).toBeLessThanOrEqual(PREDATORS.armyAnt.biteDamage);
    expect(PREDATORS.termite.fixedHp).toBe(1);
  });

  it('every predator has its own speed, health, damage and behaviour', () => {
    const behaviours = new Set(KINDS.map((k) => PREDATORS[k].behaviour));
    expect(behaviours.size).toBe(KINDS.length);
    for (const k of KINDS) expect(PREDATORS[k].biteDamage + PREDATORS[k].shotDamage).toBeGreaterThan(0);
  });
});

describe('shooting rule (section 4)', () => {
  it('moving fires at half the rate of standing still', () => {
    expect(fireIntervalSeconds(BASE_ANT, true)).toBeCloseTo(2 * fireIntervalSeconds(BASE_ANT, false), 9);
  });
  it('crits only while standing still', () => {
    expect(critChance(true)).toBe(0);
    expect(critChance(false)).toBeGreaterThan(0);
  });
});

describe('nest shop (section 3)', () => {
  it('sells the three perks at the concept prices', () => {
    expect(PERKS.map((p) => [p.id, p.price])).toEqual([['chitin', 2500], ['twin', 2000], ['quick', 3000]]);
  });

  // Lane G8: one buy of Thick Chitin is 600 x (1 + 2/15) = 680; Twin Stinger adds a dart and marks the shot as shared.
  it.each([
    ['chitin', { maxHp: 680 }],
    ['twin', { darts: 2, twin: true }],
  ] as const)('%s changes the stats', (id, expected) => {
    expect(applyPerk(BASE_ANT, id)).toMatchObject(expected);
  });

  it('quick mandibles fire 10 percent faster', () => {
    const quick = applyPerk(BASE_ANT, 'quick');
    expect(1 / quick.fireInterval).toBeCloseTo(1.1 / BASE_ANT.fireInterval, 9);
  });

  it('applyPerk leaves the base ant alone', () => {
    applyPerk(BASE_ANT, 'chitin');
    expect(BASE_ANT.maxHp).toBe(600);
  });

  it('refuses a perk you cannot afford or already own', () => {
    expect(canBuy(1999, new Set(), 'twin')).toBe(false);
    expect(canBuy(2000, new Set(), 'twin')).toBe(true);
    const after = buyPerk(2600, new Set(), 'twin');
    expect(after.nectar).toBe(600);
    expect(after.owned).toEqual(['twin']);
    expect(canBuy(99999, after.owned, 'twin')).toBe(false);
    expect(() => buyPerk(100, new Set(), 'quick')).toThrow(RangeError);
  });

  it('sells Thick Chitin three times at 2,500 each, then refuses it (lane G8)', () => {
    let state = { nectar: 10000, owned: [] as PerkId[] };
    for (let k = 1; k <= 3; k++) {
      expect(canBuy(state.nectar, state.owned, 'chitin')).toBe(true);
      state = buyPerk(state.nectar, state.owned, 'chitin');
      expect(perkCount(state.owned, 'chitin')).toBe(k);
    }
    expect(state.nectar).toBe(2500);
    expect(canBuy(99999, state.owned, 'chitin')).toBe(false);
    expect(() => buyPerk(99999, state.owned, 'chitin')).toThrow(RangeError);
    expect(PERKS.map((p) => [p.id, p.max])).toEqual([['chitin', 3], ['twin', 1], ['quick', 1]]);
  });

  it('a kill up close pays the bonus', () => {
    expect(killNectar(50, 400)).toBe(50);
    expect(killNectar(50, 100)).toBe(100);
  });
});

class MemoryStore implements KeyValueStore {
  data = new Map<string, string>();
  getItem(key: string): string | null {
    return this.data.has(key) ? (this.data.get(key) as string) : null;
  }
  setItem(key: string, value: string): void {
    this.data.set(key, value);
  }
}

class BrokenStore implements KeyValueStore {
  getItem(): string | null {
    throw new Error('storage refused');
  }
  setItem(): void {
    throw new Error('storage refused');
  }
}

describe('best round', () => {
  it('is null, not zero, when nothing was saved', () => {
    expect(readBest(new MemoryStore())).toBeNull();
    expect(readBest(null)).toBeNull();
  });

  it('keeps the highest round reached', () => {
    const store = new MemoryStore();
    expect(recordRun(store, 4)).toEqual({ best: 4, isNew: true, saved: true });
    expect(recordRun(store, 3)).toEqual({ best: 4, isNew: false, saved: true });
    expect(recordRun(store, 9)).toEqual({ best: 9, isNew: true, saved: true });
    expect(store.getItem(BEST_KEY)).toBe('9');
  });

  it('ignores junk in storage', () => {
    const store = new MemoryStore();
    store.setItem(BEST_KEY, 'banana');
    expect(readBest(store)).toBeNull();
  });

  it('survives a store that throws', () => {
    const broken = new BrokenStore();
    expect(readBest(broken)).toBeNull();
    expect(recordRun(broken, 6)).toEqual({ best: 6, isNew: true, saved: false });
  });
});

describe('the nest shop opens only between rounds (feel round 1, polish round)', () => {
  it.each([
    ['break', true, false, 'open'],
    ['break', true, true, 'open'],
    ['break', false, true, 'closed'],
    ['active', true, true, 'locked'],
    // The round found the ant standing in the nest (its spawn at round 1): no line.
    ['active', true, false, 'closed'],
    ['active', false, true, 'closed'],
    ['active', false, false, 'closed'],
    ['intro', true, false, 'closed'],
    ['intro', false, false, 'closed'],
    ['dead', true, true, 'closed'],
    ['dead', false, false, 'closed'],
  ] as const)('phase %s, in the nest %s, left the nest this round %s: %s', (phase, inNest, left, want) => {
    expect(shopState(phase, inNest, left)).toBe(want);
  });

  it('the spawn at round 1 shows no line; it shows once the ant has left the nest and come back', () => {
    let left = false;
    const frame = (phase: 'intro' | 'active' | 'break', inNest: boolean) => {
      left = trackLeftNest(left, phase, inNest);
      return shopState(phase, inNest, left);
    };
    expect(frame('intro', true)).toBe('closed');
    left = false; // round 1 starts: the director resets it, the ant still on its spawn
    expect(frame('active', true)).toBe('closed');
    expect(frame('active', true)).toBe('closed');
    expect(frame('active', false)).toBe('closed');
    expect(frame('active', true)).toBe('locked');
    // The countdown runs out with the ant in the open shop: the next round shows nothing until it leaves and returns.
    expect(frame('break', true)).toBe('open');
    left = false;
    expect(frame('active', true)).toBe('closed');
    expect(frame('active', false)).toBe('closed');
    expect(frame('active', true)).toBe('locked');
  });
});
