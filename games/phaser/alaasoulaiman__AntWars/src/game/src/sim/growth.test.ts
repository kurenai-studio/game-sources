// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for growth inside a run: the experience curve, the level up pick and every power's numbers.
import { describe, expect, it } from 'vitest';
import { enemiesForRound } from './curve';
import { BASE_ANT, applyPerk } from './economy';
import {
  BLIND_SECONDS,
  EYE_CRIT_STEP,
  GLANDS_RATE_STEP,
  HONEYDEW_HEAL,
  JAW_DAMAGE_STEP,
  LUCKY_CHANCE,
  PICK_TRIM,
  SHELL_HP_STEP,
  STANCE_BLOCK_STEP,
  powerSpec,
  FROST_SECONDS,
  FROST_SLOW,
  BURST_SHARE,
  COMBO_IDS,
  COMBO_LINE,
  FIRE_BURN_SECONDS,
  FIRE_TICK_SECONDS,
  PUDDLE_SECONDS,
  PUDDLE_TICK_SECONDS,
  PUDDLE_TICK_SHARE,
  SPARK_RANGE,
  SPARK_SHARE,
  STEAM_SECONDS,
  antLook,
  burnPerTick,
  combosOf,
  combosUnlockedBy,
  powerLine,
  KILL_XP,
  MAX_LEVEL,
  PICK_READ_MS,
  POWERS,
  POWER_IDS,
  addXp,
  canTake,
  damageTaken,
  deriveBuild,
  drawOffer,
  emptyStacks,
  furyFactor,
  healthAfterPick,
  luckyHit,
  takePower,
  xpForKill,
  xpToNext,
  xpTotalTo,
  type PowerId,
} from './growth';

/** Dash punctuation: an en or em dash, or a double hyphen (built from char codes, so this file holds none). */
const DASHES = new RegExp(`[${String.fromCharCode(0x2013, 0x2014)}]|--`);

/** Stacks with only the given powers taken. */
function stacksOf(taken: Partial<Record<PowerId, number>>) {
  return { ...emptyStacks(), ...taken };
}

describe('the experience curve', () => {
  it.each([
    [1, 10], [2, 18], [3, 26], [4, 34], [5, 42], [6, 50], [7, 58], [8, 66], [9, 74], [10, 82], [11, 90],
  ])('level %i needs %i to level up', (level, need) => {
    expect(xpToNext(level)).toBe(need);
  });

  it('the cap is level 12, the concept\'s 11 level ups, and it has no next level', () => {
    expect(MAX_LEVEL).toBe(12);
    expect(xpToNext(12)).toBeNull();
  });

  it.each([
    [1, 0], [2, 10], [3, 28], [4, 54], [5, 88], [6, 130], [7, 180], [8, 238], [9, 304], [10, 378], [11, 460], [12, 550],
  ])('reaching level %i takes %i in total', (level, total) => {
    expect(xpTotalTo(level)).toBe(total);
  });

  it('the totals are the running sum of the steps', () => {
    for (let level = 1; level < MAX_LEVEL; level++) {
      expect(xpTotalTo(level + 1) - xpTotalTo(level)).toBe(xpToNext(level));
    }
  });

  it.each([0, 13, 1.5, -1, Number.NaN])('level %s is refused', (bad) => {
    expect(() => xpToNext(bad)).toThrow(RangeError);
    expect(() => xpTotalTo(bad)).toThrow(RangeError);
  });

  it('kills give 2 an army ant, 3 a wasp or spider, 1 a termite, 40 the Anteater', () => {
    expect(KILL_XP).toEqual({
      armyAnt: 2, wasp: 3, spider: 3, termite: 1, anteater: 40, beetle: 6, antlion: 5, centipede: 8, ember: 2, moth: 2, mantis: 30, hornet: 35,
    });
    expect(xpForKill('armyAnt')).toBe(2);
    expect(xpForKill('termite')).toBe(1);
  });
});

describe('adding experience', () => {
  it.each([
    [{ level: 1, xp: 0 }, 9, { level: 1, xp: 9, ups: 0 }],
    [{ level: 1, xp: 0 }, 10, { level: 2, xp: 0, ups: 1 }],
    [{ level: 1, xp: 5 }, 30, { level: 3, xp: 7, ups: 2 }],
    [{ level: 4, xp: 33 }, 1, { level: 5, xp: 0, ups: 1 }],
    [{ level: 11, xp: 80 }, 10, { level: 12, xp: 0, ups: 1 }],
    [{ level: 1, xp: 0 }, 550, { level: 12, xp: 0, ups: 11 }],
    [{ level: 1, xp: 0 }, 100000, { level: 12, xp: 0, ups: 11 }],
    [{ level: 12, xp: 0 }, 50, { level: 12, xp: 0, ups: 0 }],
    [{ level: 3, xp: 2 }, 0, { level: 3, xp: 2, ups: 0 }],
  ])('%j plus %i gives %j', (state, gain, expected) => {
    expect(addXp(state, gain)).toEqual(expected);
  });

  it.each([-1, Number.NaN, Number.POSITIVE_INFINITY])('a gain of %s is refused', (bad) => {
    expect(() => addXp({ level: 1, xp: 0 }, bad)).toThrow(RangeError);
  });

  it('the real round curve: round 1 (6 army ants) gives level 2, rounds 1 to 4 give level 5', () => {
    const r1 = enemiesForRound(1) * KILL_XP.armyAnt;
    expect(r1).toBe(12);
    expect(addXp({ level: 1, xp: 0 }, r1)).toMatchObject({ level: 2, ups: 1 });
    const r1to4 = [1, 2, 3, 4].reduce((sum, r) => sum + enemiesForRound(r) * KILL_XP.armyAnt, 0);
    expect(r1to4).toBe(90);
    expect(addXp({ level: 1, xp: 0 }, r1to4)).toMatchObject({ level: 5, ups: 4 });
  });
});

describe('the level up pick', () => {
  it('a card reads before a press counts (the sheet itself holds the Yard until the tap: sim/pause.test.ts)', () => {
    expect(PICK_READ_MS).toBe(300);
  });

  it('there are 16 powers (slice 4 adds Fire Venom and Spark Venom), each with its own name and a plain one line effect', () => {
    expect(POWERS.length).toBe(16);
    expect(new Set(POWER_IDS).size).toBe(16);
    expect(new Set(POWERS.map((p) => p.name)).size).toBe(16);
    for (const p of POWERS) {
      expect(p.line.length).toBeGreaterThan(10);
      expect(p.line.length).toBeLessThanOrEqual(44);
      expect(p.line).not.toMatch(DASHES);
      expect(p.line.includes(String.fromCharCode(10))).toBe(false);
      expect(p.name).not.toMatch(DASHES);
    }
  });

  it.each([
    ['jaw', 5], ['glands', 4], ['shell', 3], ['honeydew', null], ['eye', 3], ['fang', 2], ['fork', 2],
    ['echo', 3], ['needle', 1], ['hop', 1], ['lucky', 1], ['fury', 1], ['frost', 1], ['stance', 2],
  ] as const)('%s stacks up to %s', (id, max) => {
    expect(POWERS.find((p) => p.id === id)?.max).toBe(max);
  });

  it('three different powers, drawn from the roll', () => {
    expect(drawOffer(emptyStacks(), () => 0)).toEqual(['jaw', 'glands', 'shell']);
    expect(drawOffer(emptyStacks(), () => 0.999)).toEqual(['spark', 'fire', 'stance']);
    let seed = 7;
    const roll = () => {
      seed = (seed * 16807) % 2147483647;
      return seed / 2147483647;
    };
    for (let i = 0; i < 200; i++) {
      const offer = drawOffer(emptyStacks(), roll);
      expect(offer.length).toBe(3);
      expect(new Set(offer).size).toBe(3);
    }
  });

  it('a power at its cap is never offered; Honeydew is always left', () => {
    let stacks = emptyStacks();
    for (const p of POWERS) if (p.max !== null) stacks = { ...stacks, [p.id]: p.max };
    expect(drawOffer(stacks, () => 0.5)).toEqual(['honeydew']);
    const some = stacksOf({ lucky: 1, needle: 1, fury: 1 });
    for (let i = 0; i < 50; i++) {
      const offer = drawOffer(some, () => (i % 10) / 10);
      expect(offer).not.toContain('lucky');
      expect(offer).not.toContain('needle');
      expect(offer).not.toContain('fury');
    }
  });

  it('taking a power adds one, leaves the old stacks alone, and stops at the cap', () => {
    const before = emptyStacks();
    const after = takePower(before, 'fang');
    expect(after.fang).toBe(1);
    expect(before.fang).toBe(0);
    const two = takePower(after, 'fang');
    expect(canTake(two, 'fang')).toBe(false);
    expect(() => takePower(two, 'fang')).toThrow(RangeError);
    let honey = emptyStacks();
    for (let i = 0; i < 20; i++) honey = takePower(honey, 'honeydew');
    expect(honey.honeydew).toBe(20);
  });
});

describe('every power changes exactly its numbers (from the base ant)', () => {
  const base = deriveBuild(BASE_ANT, emptyStacks());

  it('no powers: the base ant, one volley, no extras', () => {
    expect(base).toEqual({
      maxHp: 600, damage: 150, fireInterval: 0.42, darts: 1, speed: 250, critChance: 0.1, volleys: 1, forkPairs: 0,
      pierce: false, hops: 0, lucky: 0, fury: false, frost: false, fire: false, spark: false, block: 0,
    });
  });

  it.each([
    // The design note of 2026-10-24 trimmed what each pick gives by a third: two thirds of 20, 15, 20, 10 percent a stack.
    [{ jaw: 1 }, { damage: 170 }],
    [{ jaw: 5 }, { damage: 250 }],
    [{ glands: 1 }, { fireInterval: 0.42 / 1.1 }],
    [{ glands: 4 }, { fireInterval: 0.42 / 1.4 }],
    [{ shell: 1 }, { maxHp: 680 }],
    [{ shell: 3 }, { maxHp: 840 }],
    [{ eye: 1 }, { critChance: 0.1 + 0.2 / 3 }],
    [{ eye: 3 }, { critChance: 0.3 }],
    [{ fang: 1 }, { darts: 2, damage: 112.5 }],
    [{ fang: 2 }, { darts: 3, damage: 84.375 }],
    [{ fork: 1 }, { forkPairs: 1 }],
    [{ fork: 2 }, { forkPairs: 2 }],
    [{ echo: 1 }, { volleys: 2, damage: 135, fireInterval: 0.42 / 0.85 }],
    [{ echo: 3 }, { volleys: 4, damage: 150 * 0.729, fireInterval: 0.42 / (0.85 * 0.85 * 0.85) }],
    [{ needle: 1 }, { pierce: true }],
    [{ hop: 1 }, { hops: 2 }],
    [{ lucky: 1 }, { lucky: 1 / 12 }],
    [{ fury: 1 }, { fury: true }],
    [{ frost: 1 }, { frost: true }],
    [{ stance: 1 }, { block: 0.4 / 3 }],
    [{ stance: 2 }, { block: 0.8 / 3 }],
    [{ honeydew: 3 }, {}],
  ] as const)('%j sets %j and nothing else', (taken, changed) => {
    const b = deriveBuild(BASE_ANT, stacksOf(taken));
    for (const key of Object.keys(base) as Array<keyof typeof base>) {
      const want = key in changed ? (changed as Record<string, unknown>)[key] : base[key];
      if (typeof want === 'number') expect(b[key]).toBeCloseTo(want, 9);
      else expect(b[key]).toBe(want);
    }
  });

  it('powers stack on top of the nest perks: Twin Stinger plus two Front Fangs is four darts', () => {
    const twin = applyPerk(BASE_ANT, 'twin');
    expect(deriveBuild(twin, stacksOf({ fang: 2 })).darts).toBe(4);
    // Lane G8: one Thick Chitin buy is 680, three Hearty Shells x1.4 on it; Quick Mandibles /1.1.
    const chitin = applyPerk(BASE_ANT, 'chitin');
    expect(deriveBuild(chitin, stacksOf({ shell: 3 })).maxHp).toBe(952);
    const quick = applyPerk(BASE_ANT, 'quick');
    expect(deriveBuild(quick, stacksOf({ glands: 2 })).fireInterval).toBeCloseTo(0.42 / 1.1 / 1.2, 9);
  });

  it.each([
    [600, 600, 1], [300, 600, 1 + 1 / 3], [6, 600, 1.66], [0, 600, 1 + 2 / 3], [700, 600, 1], [10, 0, 1],
  ])('Fury Glands at %i of %i health deals x%s', (hp, max, factor) => {
    expect(furyFactor(hp, max)).toBeCloseTo(factor, 9);
  });

  it.each([
    ['a first hit under the chance (1 in 12 since the trim)', true, false, 0.08, true],
    ['a first hit just over the chance', true, false, 0.0834, false],
    ['a second hit', false, false, 0, false],
    ['the boss, first hit', true, true, 0, false],
  ] as const)('Lucky Sting rolls only on a first hit (VG3 note 4): %s', (_name, first, boss, roll, expected) => {
    const lucky = deriveBuild(BASE_ANT, stacksOf({ lucky: 1 }));
    expect(luckyHit(lucky, first, boss, roll)).toBe(expected);
    expect(luckyHit(base, first, boss, roll)).toBe(false);
  });

  it('Stone Stance cuts a hit only while standing still, never to 0', () => {
    const one = deriveBuild(BASE_ANT, stacksOf({ stance: 1 }));
    const two = deriveBuild(BASE_ANT, stacksOf({ stance: 2 }));
    expect(damageTaken(60, one, false)).toBe(52);
    expect(damageTaken(60, one, true)).toBe(60);
    expect(damageTaken(60, two, false)).toBe(44);
    expect(damageTaken(1, two, false)).toBe(1);
    expect(damageTaken(0, two, false)).toBe(0);
    expect(damageTaken(60, base, false)).toBe(60);
  });

  it.each([
    ['shell', 300, 600, 680, 380],
    ['shell', 600, 600, 680, 680],
    ['honeydew', 100, 600, 600, 260],
    ['honeydew', 500, 600, 600, 600],
    ['jaw', 250, 600, 600, 250],
  ] as const)('after %s, %i health with a max of %i, the max now %i, gives %i health', (id, hp, oldMax, newMax, expected) => {
    expect(healthAfterPick(id, hp, oldMax, newMax)).toBe(expected);
  });
});

describe('the picks trimmed by a third (design note of 2026-10-24)', () => {
  it('each pick gives two thirds of what it gave, and its card says the number it gives', () => {
    expect(PICK_TRIM).toBeCloseTo(2 / 3, 12);
    const says = (id: PowerId, n: number) => expect(powerSpec(id).line).toContain(`${Math.round(n * 100)}%`);
    expect(JAW_DAMAGE_STEP).toBeCloseTo(0.2 * (2 / 3), 12);
    says('jaw', JAW_DAMAGE_STEP);
    expect(GLANDS_RATE_STEP).toBeCloseTo(0.1, 12);
    says('glands', GLANDS_RATE_STEP);
    says('shell', SHELL_HP_STEP);
    says('honeydew', HONEYDEW_HEAL);
    says('eye', EYE_CRIT_STEP);
    says('stance', STANCE_BLOCK_STEP);
    expect(LUCKY_CHANCE).toBeCloseTo(1 / 12, 12);
    expect(powerSpec('lucky').line).toContain('1 foe in 12');
    expect(furyFactor(0, 600)).toBeCloseTo(1 + 2 / 3, 12);
    expect(powerSpec('fury').line).toContain('2% per 3%');
  });
});

describe('slice 4: elements on the darts, the combos a second element unlocks, and the ant look', () => {
  const st = (taken: Partial<Record<PowerId, number>>) => ({ ...emptyStacks(), ...taken });

  it('fire burns 30 percent more of the hit in four ticks over 2 s; spark arcs 40 percent to one foe within 220', () => {
    expect(burnPerTick(150)).toBe(11.25);
    expect(burnPerTick(150) * (FIRE_BURN_SECONDS / FIRE_TICK_SECONDS)).toBeCloseTo(45, 12);
    expect(SPARK_SHARE).toBe(0.4);
    expect(SPARK_RANGE).toBe(220);
    expect(deriveBuild(BASE_ANT, st({ fire: 1 })).fire).toBe(true);
    expect(deriveBuild(BASE_ANT, st({ spark: 1 })).spark).toBe(true);
    expect(deriveBuild(BASE_ANT, st({ frost: 1 })).fire).toBe(false);
  });

  it.each([
    [{ frost: 1, spark: 1 }, { puddle: true, steam: false, burst: false }],
    [{ fire: 1, frost: 1 }, { puddle: false, steam: true, burst: false }],
    [{ fire: 1, spark: 1 }, { puddle: false, steam: false, burst: true }],
    [{ fire: 1, frost: 1, spark: 1 }, { puddle: true, steam: true, burst: true }],
    [{ fire: 1 }, { puddle: false, steam: false, burst: false }],
    [{}, { puddle: false, steam: false, burst: false }],
  ])('elements %j unlock %j', (taken, want) => {
    expect(combosOf(st(taken as Partial<Record<PowerId, number>>))).toEqual(want);
  });

  it('the pick card says what a second element unlocks, in one plain line', () => {
    expect(combosUnlockedBy('spark', st({ frost: 1 }))).toEqual(['puddle']);
    expect(combosUnlockedBy('fire', st({ frost: 1, spark: 1 }))).toEqual(['steam', 'burst']);
    expect(combosUnlockedBy('frost', st({}))).toEqual([]);
    expect(combosUnlockedBy('spark', st({ spark: 1, frost: 1 }))).toEqual([]);
    expect(combosUnlockedBy('jaw', st({ frost: 1 }))).toEqual([]);
    expect(powerLine('spark', st({ frost: 1 }))).toBe('Combo: 1 in 5 kills leave a shock puddle for 3 s');
    expect(powerLine('frost', st({ fire: 1 }))).toBe('Combo: 1 in 5 kills leave steam that blinds foes');
    expect(powerLine('spark', st({ fire: 1 }))).toBe('Combo: 1 in 5 kills burst in flame on foes near');
    // Design note, 2026-10-24: every element card says the chance.
    for (const id of ['fire', 'frost', 'spark'] as PowerId[]) expect(powerLine(id, st({}))).toMatch(/^1 in 5 hits /);
    expect(powerLine('fire', st({})).length).toBeLessThanOrEqual(44);
    expect(powerLine('jaw', st({}))).toBe('Darts hit 13% harder');
    for (const c of COMBO_IDS) expect(COMBO_LINE[c]).not.toMatch(DASHES);
  });

  it('Frost Sap slows a foe to exactly 60 percent of its speed for 1.5 s (VG5: the number itself is pinned)', () => {
    expect(FROST_SLOW).toBe(0.6);
    expect(FROST_SECONDS).toBe(1.5);
  });

  it('the puddle lasts 3 s and a second inside it costs a foe one dart; the burst takes 60 percent of a dart', () => {
    expect(PUDDLE_SECONDS).toBe(3);
    expect(PUDDLE_TICK_SHARE * (1 / PUDDLE_TICK_SECONDS)).toBeCloseTo(1, 12);
    expect(BURST_SHARE).toBe(0.6);
    expect(STEAM_SECONDS).toBe(2.5);
    expect(BLIND_SECONDS).toBe(1);
  });

  it.each([
    [1, 600, {}, { plates: 0, aura: [], rim: null }],
    [4, 900, { fire: 1 }, { plates: 1, aura: [0xff6d2e], rim: 0x9effa1 }],
    [8, 1500, { spark: 1 }, { plates: 2, aura: [0xfff176], rim: 0xc9b6ff }],
    [12, 2400, { fire: 1, frost: 1, spark: 1 }, { plates: 3, aura: [0xff6d2e, 0x81d4fa, 0xfff176], rim: 0xffd34d }],
    [3, 899, { frost: 1 }, { plates: 0, aura: [0x81d4fa], rim: null }],
  ])('the look at level %i with %i max health and %j', (level, hp, taken, want) => {
    expect(antLook(level as number, hp as number, st(taken as Partial<Record<PowerId, number>>))).toEqual(want);
  });
});
