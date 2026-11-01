// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for the Colony between runs: the copied cost ladder, the first ten steps of every upgrade, the bank, the
// ladders, the stored records, and the upgrades through the real perk and power builders.
import { describe, expect, it } from 'vitest';
import { BASE_ANT, NECTAR_PER_HIT, applyPerk, nectarGain } from './economy';
import { damageTaken, deriveBuild, emptyStacks } from './growth';
import {
  BEST_KEYS,
  COLONY_KEY,
  COST_LADDER_LENGTH,
  LADDER_KEY,
  LADDER_NAME,
  UPGRADES,
  UPGRADE_IDS,
  applyColony,
  armorCut,
  armoredDamage,
  bankAfterRun,
  buyUpgrade,
  canBuyUpgrade,
  decodeColony,
  emptyColony,
  emptyLevels,
  encodeColony,
  levelsFor,
  loadColony,
  loadLadder,
  nectarBonus,
  nextCost,
  saveColony,
  saveLadder,
  totalSteps,
  upgradeCost,
  upgradeLine,
  type UpgradeId,
} from './colony';
import { BEST_KEY, readBest, recordRun, type KeyValueStore } from './best';

const DASHES = new RegExp(`[${String.fromCharCode(0x2013, 0x2014)}]|--`);

function memoryStore(): KeyValueStore & { data: Map<string, string> } {
  const data = new Map<string, string>();
  return {
    data,
    getItem: (k) => (data.has(k) ? (data.get(k) as string) : null),
    setItem: (k, v) => {
      data.set(k, v);
    },
  };
}
const throwing: KeyValueStore = {
  getItem: () => {
    throw new Error('refused');
  },
  setItem: () => {
    throw new Error('refused');
  },
};

const levelsOf = (taken: Partial<Record<UpgradeId, number>>) => ({ ...emptyLevels(), ...taken });
const sumCosts = (n: number) => Array.from({ length: n }, (_, i) => upgradeCost(i + 1) as number).reduce((a, b) => a + b, 0);

describe('the cost ladder (CONCEPT_V1 6e)', () => {
  it.each([
    [1, 200], [2, 250], [3, 300], [4, 350], [5, 400], [6, 450], [7, 500], [8, 600], [9, 700], [10, 800],
  ])('upgrade %i costs %i', (n, cost) => {
    expect(upgradeCost(n)).toBe(cost);
  });

  it.each([
    [7, 500], [12, 1000], [22, 3000], [36, 10000], [46, 20000], [61, 50000], [81, 150000], [96, 300000], [113, 640000], [125, 1000000],
  ])('the band ending at upgrade %i costs %i', (n, cost) => {
    expect(upgradeCost(n)).toBe(cost);
  });

  it('the first 10 cost 4,550, the first 20 cost 21,650, the first 50 about 377,000', () => {
    expect(sumCosts(10)).toBe(4550);
    expect(sumCosts(20)).toBe(21650);
    expect(sumCosts(50)).toBe(376950);
  });

  it('never falls, and ends after 125', () => {
    for (let n = 2; n <= COST_LADDER_LENGTH; n++) expect(upgradeCost(n) as number).toBeGreaterThan(upgradeCost(n - 1) as number);
    expect(upgradeCost(126)).toBeNull();
    expect(() => upgradeCost(0)).toThrow(RangeError);
    expect(() => upgradeCost(1.5)).toThrow(RangeError);
  });

  it('the six lines hold exactly the 125 steps of the ladder', () => {
    expect(UPGRADES.reduce((s, u) => s + u.max, 0)).toBe(COST_LADDER_LENGTH);
  });
});

describe('the first ten steps of every upgrade', () => {
  const steps = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  // The design note of 2026-10-24 halved every step below; the prices and the caps stay.
  it('Barbed Stinger: +4 dart damage a step from 150', () => {
    expect(steps.map((k) => applyColony(BASE_ANT, levelsOf({ stinger: k })).damage)).toEqual([154, 158, 162, 166, 170, 174, 178, 182, 186, 190]);
  });
  it('Royal Diet: +12.5 max health a step from 600, the total rounded to a whole point', () => {
    expect(steps.map((k) => applyColony(BASE_ANT, levelsOf({ diet: k })).maxHp)).toEqual([613, 625, 638, 650, 663, 675, 688, 700, 713, 725]);
  });
  it('Plated Back: 1 percent less damage taken a step', () => {
    expect(steps.map((k) => +armorCut(levelsOf({ plates: k })).toFixed(4))).toEqual([0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1]);
    const cut60 = steps.map((k) => armoredDamage(60, armorCut(levelsOf({ plates: k }))));
    [59.4, 58.8, 58.2, 57.6, 57, 56.4, 55.8, 55.2, 54.6, 54].forEach((v, i) => expect(cut60[i]).toBeCloseTo(v, 9));
  });
  it('Plated Back takes something off every hit at every step, a termite bite of 8 too (VG4)', () => {
    let last = armoredDamage(8, 0);
    expect(last).toBe(8);
    for (let k = 1; k <= 15; k++) {
      const now = armoredDamage(8, armorCut(levelsOf({ plates: k })));
      expect(now).toBeLessThan(last);
      expect(now).toBeGreaterThanOrEqual(1);
      last = now;
    }
    expect(armoredDamage(8, armorCut(levelsOf({ plates: 1 })))).toBeCloseTo(7.92, 12);
    expect(last).toBeCloseTo(6.8, 12);
  });
  it('Long Legs: half a percent faster a step from 250', () => {
    expect(steps.map((k) => +applyColony(BASE_ANT, levelsOf({ legs: k })).speed.toFixed(3))).toEqual([251.25, 252.5, 253.75, 255, 256.25, 257.5, 258.75, 260, 261.25, 262.5]);
  });
  it('Rapid Venom: 1 percent faster fire a step from 0.42 s', () => {
    expect(steps.map((k) => +applyColony(BASE_ANT, levelsOf({ venom: k })).fireInterval.toFixed(4))).toEqual([
      0.4158, 0.4118, 0.4078, 0.4038, 0.4, 0.3962, 0.3925, 0.3889, 0.3853, 0.3818,
    ]);
  });
  it('Sweet Tooth: 2.5 percent more nectar a step', () => {
    expect(steps.map((k) => +nectarBonus(levelsOf({ sweet: k })).toFixed(4))).toEqual([1.025, 1.05, 1.075, 1.1, 1.125, 1.15, 1.175, 1.2, 1.225, 1.25]);
  });
  it('Sweet Tooth: what a hit and a bead pay is what the card says, step by step (VG4: step 1 once paid 11 for a 10)', () => {
    expect(nectarGain(NECTAR_PER_HIT, nectarBonus(levelsOf({ sweet: 1 })))).toBeCloseTo(10.25, 12);
    expect(nectarGain(50, nectarBonus(levelsOf({ sweet: 1 })))).toBeCloseTo(51.25, 12);
    for (let k = 1; k <= 20; k++) {
      const paid = nectarGain(NECTAR_PER_HIT, nectarBonus(levelsOf({ sweet: k })));
      expect(paid / NECTAR_PER_HIT - 1).toBeCloseTo(0.025 * k, 12);
      expect(upgradeLine('sweet', BASE_ANT, levelsOf({ sweet: k - 1 }))).toContain(`+${+(2.5 * k).toFixed(1)}%`);
    }
  });
  it.each(UPGRADE_IDS.map((id) => [id]))('%s: the first ten steps bought on that line alone cost the ladder 200 to 800', (id) => {
    let state = { bank: 1_000_000, levels: emptyLevels() };
    const paid: number[] = [];
    for (let k = 0; k < 10; k++) {
      const before = state.bank;
      state = buyUpgrade(state, id);
      paid.push(before - state.bank);
    }
    expect(paid).toEqual([200, 250, 300, 350, 400, 450, 500, 600, 700, 800]);
    expect(state.levels[id]).toBe(10);
  });
});

describe('buying and banking', () => {
  it('one price for every card: the next upgrade of any line is the next rung', () => {
    const levels = levelsOf({ stinger: 3, diet: 2, plates: 1 });
    expect(totalSteps(levels)).toBe(6);
    expect(nextCost(levels)).toBe(500);
    const s = buyUpgrade({ bank: 500, levels }, 'legs');
    expect(s.bank).toBe(0);
    expect(s.levels.legs).toBe(1);
    expect(nextCost(s.levels)).toBe(600);
  });
  it('refuses a bank that is short and a line that is full', () => {
    expect(canBuyUpgrade({ bank: 199, levels: emptyLevels() }, 'stinger')).toBe(false);
    expect(() => buyUpgrade({ bank: 199, levels: emptyLevels() }, 'stinger')).toThrow(RangeError);
    const full = { bank: 1e9, levels: levelsOf({ legs: 10 }) };
    expect(canBuyUpgrade(full, 'legs')).toBe(false);
    expect(canBuyUpgrade(full, 'stinger')).toBe(true);
  });
  it('every line full: no next price, nothing to buy', () => {
    const all = emptyLevels();
    for (const u of UPGRADES) all[u.id] = u.max;
    expect(nextCost(all)).toBeNull();
    for (const id of UPGRADE_IDS) expect(canBuyUpgrade({ bank: 1e12, levels: all }, id)).toBe(false);
  });
  it('a run banks the whole nectar it still holds, never less than nothing', () => {
    expect(bankAfterRun(0, 1234)).toBe(1234);
    expect(bankAfterRun(500, 99.9)).toBe(599);
    expect(bankAfterRun(500, -3)).toBe(500);
  });
  it('Pure uses no upgrades; Colony uses its own', () => {
    const own = levelsOf({ stinger: 4 });
    expect(levelsFor('pure', own)).toEqual(emptyLevels());
    expect(levelsFor('colony', own)).toEqual(own);
    expect(applyColony(BASE_ANT, levelsFor('pure', own))).toEqual({ ...BASE_ANT });
    expect(LADDER_NAME).toEqual({ colony: 'COLONY', pure: 'PURE' });
  });
  it('armor never takes a real hit below 1 and leaves no hit as it was', () => {
    expect(armoredDamage(1, 0.3)).toBe(1);
    expect(armoredDamage(0, 0.3)).toBe(0);
    expect(armoredDamage(60, 0)).toBe(60);
  });
});

describe('the upgrades through the real perk and power builders', () => {
  it('a Thick Chitin buy multiplies the colony health; the powers stack on the colony damage', () => {
    const colony = applyColony(BASE_ANT, levelsOf({ diet: 4, stinger: 5 }));
    expect(colony.maxHp).toBe(650);
    expect(colony.damage).toBe(170);
    const chitin = applyPerk(colony, 'chitin');
    // Lane G8: 650 x (1 + 2/15) = 736.7, so 737 (x2.5 = 1,625 before).
    expect(chitin.maxHp).toBe(737);
    const build = deriveBuild(chitin, { ...emptyStacks(), jaw: 1, shell: 1 });
    // 737 x (1 + 2/15) and 170 x (1 + 2/15): the picks trimmed by a third.
    expect(build.maxHp).toBe(835);
    expect(build.damage).toBeCloseTo(170 * (1 + 2 / 15), 9);
  });
  it('Quick Mandibles and Rapid Venom multiply; Long Legs reaches the build', () => {
    const colony = applyColony(BASE_ANT, levelsOf({ venom: 5, legs: 4 }));
    const build = deriveBuild(applyPerk(colony, 'quick'), emptyStacks());
    expect(build.fireInterval).toBeCloseTo(0.42 / 1.05 / 1.1, 9);
    expect(build.speed).toBeCloseTo(255, 9);
  });
  it('Plated Back cuts after Stone Stance: 60 standing still with two stances and five plates', () => {
    const build = deriveBuild(BASE_ANT, { ...emptyStacks(), stance: 2 });
    const stance = damageTaken(60, build, false);
    expect(stance).toBe(44);
    expect(armoredDamage(stance, armorCut(levelsOf({ plates: 5 })))).toBeCloseTo(41.8, 9);
  });
});

describe('the cards', () => {
  it.each([
    ['stinger', {}, 'Dart damage 150 to 154'],
    ['diet', { diet: 2 }, 'Max health 625 to 638'],
    ['plates', {}, 'Damage taken cut 0% to 1%'],
    ['legs', { legs: 10 }, 'Move speed +5%, Max'],
    ['venom', { venom: 1 }, 'Fire rate +1% to +2%'],
    ['sweet', { sweet: 3 }, 'Nectar +7.5% to +10%'],
  ] as Array<[UpgradeId, Partial<Record<UpgradeId, number>>, string]>)('%s %j reads %s', (id, taken, line) => {
    expect(upgradeLine(id, BASE_ANT, levelsOf(taken))).toBe(line);
  });
  it('names and lines are ours, with no dash punctuation', () => {
    for (const u of UPGRADES) {
      expect(DASHES.test(u.name)).toBe(false);
      expect(DASHES.test(upgradeLine(u.id, BASE_ANT, emptyLevels()))).toBe(false);
    }
  });
});

describe('the stored colony, ladder and best rounds', () => {
  it('round trips the colony; junk and refused storage read as a fresh colony', () => {
    const store = memoryStore();
    const state = { bank: 4321, levels: levelsOf({ stinger: 2, sweet: 1 }) };
    expect(saveColony(store, state)).toBe(true);
    expect(store.data.has(COLONY_KEY)).toBe(true);
    expect(loadColony(store)).toEqual(state);
    for (const junk of ['', '{', 'null', '[]', '{"v":2,"bank":1,"levels":{}}']) expect(decodeColony(junk)).toBeNull();
    expect(decodeColony(null)).toBeNull();
    expect(loadColony(throwing)).toEqual(emptyColony());
    expect(loadColony(null)).toEqual(emptyColony());
    expect(saveColony(throwing, state)).toBe(false);
    expect(decodeColony(encodeColony(state))).toEqual(state);
  });
  it.each([
    ['a bank that is not a whole number', '{"v":1,"bank":"abc","levels":{"stinger":3,"diet":2}}', { bank: 0, levels: { stinger: 3, diet: 2 } }],
    ['a negative bank', '{"v":1,"bank":-1,"levels":{"legs":4}}', { bank: 0, levels: { legs: 4 } }],
    ['a bank with a fraction', '{"v":1,"bank":1.5,"levels":{}}', { bank: 0, levels: {} }],
    ['one level past its cap', '{"v":1,"bank":1,"levels":{"legs":11,"stinger":3}}', { bank: 1, levels: { stinger: 3 } }],
    ['one level that is junk', '{"v":1,"bank":9,"levels":{"stinger":3,"diet":"x","venom":2}}', { bank: 9, levels: { stinger: 3, venom: 2 } }],
    ['a line it does not know', '{"v":1,"bank":1,"levels":{"wings":1,"sweet":2}}', { bank: 1, levels: { sweet: 2 } }],
    ['levels that are a list', '{"v":1,"bank":7,"levels":[]}', { bank: 7, levels: {} }],
  ])('one bad field (%s) takes its default and keeps the rest (VG4)', (_name, raw, want) => {
    const w = want as { bank: number; levels: Partial<Record<UpgradeId, number>> };
    expect(decodeColony(raw as string)).toEqual({ bank: w.bank, levels: levelsOf(w.levels) });
  });
  it('a stored colony missing a line reads that line as 0', () => {
    expect(decodeColony('{"v":1,"bank":10,"levels":{"stinger":3}}')).toEqual({ bank: 10, levels: levelsOf({ stinger: 3 }) });
  });
  it('the ladder is Colony until Pure is chosen, and survives refused storage', () => {
    const store = memoryStore();
    expect(loadLadder(store)).toBe('colony');
    expect(saveLadder(store, 'pure')).toBe(true);
    expect(store.data.get(LADDER_KEY)).toBe('pure');
    expect(loadLadder(store)).toBe('pure');
    store.data.set(LADDER_KEY, 'weird');
    expect(loadLadder(store)).toBe('colony');
    expect(loadLadder(throwing)).toBe('colony');
    expect(saveLadder(throwing, 'pure')).toBe(false);
  });
  it('each ladder keeps its own best round; Pure keeps the slice 1 key', () => {
    expect(BEST_KEYS.pure).toBe(BEST_KEY);
    const store = memoryStore();
    store.data.set(BEST_KEY, '9');
    expect(readBest(store, BEST_KEYS.colony)).toBeNull();
    expect(recordRun(store, 4, BEST_KEYS.colony)).toEqual({ best: 4, isNew: true, saved: true });
    expect(readBest(store, BEST_KEYS.pure)).toBe(9);
    expect(readBest(store, BEST_KEYS.colony)).toBe(4);
    expect(recordRun(store, 7, BEST_KEYS.pure)).toEqual({ best: 9, isNew: false, saved: true });
  });
});
