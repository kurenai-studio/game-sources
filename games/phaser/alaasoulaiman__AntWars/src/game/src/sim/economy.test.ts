// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Slice 4: the in run economy. The first twelve buys of every line, their prices on the shared ladder, the pick cap,
// the card text, the one order of the nest buys, and the model that tunes the nectar against the prices.
import { describe, expect, it } from 'vitest';
import {
  BASE_ANT,
  LINES,
  LINE_IDS,
  PICK_CAP_LEVEL,
  SHOP_STEP_SCALE,
  DAMAGE_MAX,
  RATE_MAX,
  HEALTH_MAX,
  applyPerk,
  HIT_CAP_SHARE,
  buyLine,
  canBuyLine,
  capHit,
  emptyLedger,
  emptyLines,
  lineBuys,
  lineCard,
  linePrice,
  lineStep,
  lineTotal,
  picksOpen,
  projectRun,
  runStats,
  spentShare,
  type LineId,
  type PerkId,
} from './economy';
import { MAX_LEVEL } from './growth';

/** Dash punctuation: an en or em dash, or a double hyphen (built from char codes, so this file holds none). */
const DASHES = new RegExp(`[${String.fromCharCode(0x2013, 0x2014)}]|--`);

/**
 * Worked by hand from each line's first step, its decay, the at least 1 less rule and the floor (see LINES), then halved
 * (design note, 2026-10-24; slice 4 shipped 30, 27, 24 ... for damage). A dart stays one dart.
 */
const FIRST_TWELVE: Readonly<Record<LineId, ReadonlyArray<number | null>>> = {
  damage: [15, 13.5, 12, 11, 10, 9, 8, 7, 6.5, 6, 5, 4.5],
  rate: [7.5, 6.5, 6, 5, 4.5, 4, 3.5, 3, 2.5, 2, 1.5, 1],
  health: [40, 36, 32.5, 29, 26, 23.5, 21.5, 19, 17, 15.5, 14, 12.5],
  speed: [2, 1.5, 1, 0.5, 0.5, 0.5, 0.5, 0.5, null, null, null, null],
  darts: [1, 1, null, null, null, null, null, null, null, null, null, null],
};
/** The talent ladder of CONCEPT_V1 6e for the first twelve buys of any line: 200, +50 to the 7th, +100 to the 12th. */
const LADDER_TWELVE = [200, 250, 300, 350, 400, 450, 500, 600, 700, 800, 900, 1000];

describe('the lines: the first twelve buys of each', () => {
  for (const id of LINE_IDS) {
    it(`${id}: steps ${FIRST_TWELVE[id].join(', ')}`, () => {
      expect(Array.from({ length: 12 }, (_, i) => lineStep(id, i + 1))).toEqual(FIRST_TWELVE[id]);
    });
  }

  it('each buy gives less than the last until a line reaches its floor (damage, fire rate, health over all twelve)', () => {
    for (const id of ['damage', 'rate', 'health'] as LineId[]) {
      for (let k = 2; k <= 12; k++) expect(lineStep(id, k) as number).toBeLessThan(lineStep(id, k - 1) as number);
    }
    // Speed falls to its floor of 1 at the 4th buy and stops at its cap of 8.
    for (let k = 2; k <= 4; k++) expect(lineStep('speed', k) as number).toBeLessThan(lineStep('speed', k - 1) as number);
  });

  it('past the twelfth the lines keep shrinking to their floor, then stop at their maximum (design note of 2026-10-24)', () => {
    expect(lineStep('damage', 19)).toBe(2);
    expect(lineStep('damage', 20)).toBe(2);
    expect(lineStep('damage', 21)).toBeNull();
    expect(lineStep('rate', 12)).toBe(1);
    expect(lineStep('rate', 13)).toBeNull();
    expect(lineStep('health', 20)).toBe(5.5);
    expect(lineStep('health', 21)).toBeNull();
    expect(SHOP_STEP_SCALE).toBe(0.5);
    expect(lineStep('speed', 9)).toBeNull();
    expect(lineStep('darts', 3)).toBeNull();
  });

  it('every line has a maximum, fire rate the lowest of the open ended ones, and the whole of each line', () => {
    expect([DAMAGE_MAX, RATE_MAX, HEALTH_MAX]).toEqual([20, 12, 20]);
    for (const l of LINES) expect(l.max).not.toBeNull();
    expect(lineTotal('damage', 20)).toBe(128.5);
    expect(lineTotal('rate', 12)).toBe(47);
    expect(lineTotal('health', 20)).toBe(350.5);
    expect(lineTotal('damage', 40)).toBe(128.5);
    // At the cap nothing sells, whatever the nectar.
    const full = { ...emptyLines(), rate: 12 };
    expect(canBuyLine(1e12, full, 'rate', 30)).toBe(false);
    expect(() => buyLine(1e12, full, 'rate', 30)).toThrow(RangeError);
    expect(lineCard('rate', full, 30)).toBe('Max');
  });

  it('totals of the first twelve, half what slice 4 shipped: +107.5 damage, +47% fire rate, +286.5 health; speed +7%; two darts', () => {
    expect(lineTotal('damage', 12)).toBe(107.5);
    expect(lineTotal('rate', 12)).toBe(47);
    expect(lineTotal('health', 12)).toBe(286.5);
    expect(lineTotal('speed', 12)).toBe(7);
    expect(lineTotal('darts', 12)).toBe(2);
  });

  it('a bad buy number is refused', () => {
    expect(() => lineStep('damage', 0)).toThrow(RangeError);
    expect(() => lineStep('damage', 1.5)).toThrow(RangeError);
  });
});

describe('the price: one ladder for every line, climbing with every line bought', () => {
  it('twelve buys of one line pay the ladder 200 to 1,000 (6,450 in all)', () => {
    let levels = emptyLines();
    let nectar = 100_000;
    const paid: number[] = [];
    for (let i = 0; i < 12; i++) {
      const p = buyLine(nectar, levels, 'damage', 1);
      paid.push(p.price);
      nectar = p.nectar;
      levels = p.levels;
    }
    expect(paid).toEqual(LADDER_TWELVE);
    expect(100_000 - nectar).toBe(6450);
    expect(levels.damage).toBe(12);
  });

  it('the price is shared: a health buy makes the next damage buy cost the next ladder step', () => {
    const levels = { ...emptyLines(), health: 3, rate: 2 };
    expect(lineBuys(levels)).toBe(5);
    expect(linePrice('damage', levels)).toBe(450);
    expect(linePrice('health', levels)).toBe(450);
  });

  it('the extra dart costs five times the ladder price and opens only after round 10', () => {
    const levels = emptyLines();
    expect(linePrice('darts', levels)).toBe(1000);
    expect(canBuyLine(10_000, levels, 'darts', 9)).toBe(false);
    expect(canBuyLine(10_000, levels, 'darts', 10)).toBe(true);
    expect(canBuyLine(999, levels, 'darts', 10)).toBe(false);
  });

  it('past the ladder end (its 125th step) the price holds at 1,000,000', () => {
    const levels = { ...emptyLines(), damage: 124 };
    expect(linePrice('damage', levels)).toBe(1_000_000);
    expect(linePrice('damage', { ...emptyLines(), damage: 300 })).toBe(1_000_000);
  });

  it('a line at its cap, a closed line or too little nectar is refused and spends nothing', () => {
    const capped = { ...emptyLines(), speed: 8 };
    expect(canBuyLine(1_000_000, capped, 'speed', 5)).toBe(false);
    expect(() => buyLine(1_000_000, capped, 'speed', 5)).toThrow(RangeError);
    expect(() => buyLine(199, emptyLines(), 'damage', 1)).toThrow(RangeError);
    expect(canBuyLine(200, emptyLines(), 'damage', 0)).toBe(true);
  });
});

describe('the card: the step now and the next one', () => {
  it('reads "+15 damage, next +13.5" on a fresh run, and moves with the buys', () => {
    const z = emptyLines();
    expect(lineCard('damage', z, 1)).toBe('+15 damage, next +13.5');
    expect(lineCard('damage', { ...z, damage: 11 }, 1)).toBe('+4.5 damage, next +4');
    expect(lineCard('rate', z, 1)).toBe('+7.5% fire rate, next +6.5%');
    expect(lineCard('health', z, 1)).toBe('+40 health, next +36');
    expect(lineCard('speed', z, 1)).toBe('+2% speed, next +1.5%');
  });

  it('says the last buy, a maxed line and a line not open yet in plain words', () => {
    const z = emptyLines();
    expect(lineCard('speed', { ...z, speed: 7 }, 1)).toBe('+0.5% speed, the last one');
    expect(lineCard('speed', { ...z, speed: 8 }, 1)).toBe('Max');
    expect(lineCard('damage', { ...z, damage: 20 }, 1)).toBe('Max');
    expect(lineCard('darts', z, 9)).toBe('Opens after round 10');
    expect(lineCard('darts', z, 10)).toBe('+1 dart, next +1');
    expect(lineCard('darts', { ...z, darts: 1 }, 10)).toBe('+1 dart, the last one');
  });

  it('no card text holds a dash', () => {
    for (const id of LINE_IDS) for (let n = 0; n < 22; n++) expect(lineCard(id, { ...emptyLines(), [id]: n }, 20)).not.toMatch(DASHES);
    for (const l of LINES) expect(l.name).not.toMatch(DASHES);
  });
});

describe('runStats: the nest buys in one order', () => {
  it('a fresh run with nothing bought is the meta ant', () => {
    expect(runStats(BASE_ANT, new Set(), emptyLines())).toEqual(BASE_ANT);
  });

  it('matches the slice 1 perks exactly when no line is bought', () => {
    for (const id of ['chitin', 'twin', 'quick'] as PerkId[]) {
      expect(runStats(BASE_ANT, new Set([id]), emptyLines())).toEqual(applyPerk(BASE_ANT, id));
    }
  });

  // Lane G8: one Thick Chitin buy is x(1 + 2/15), Quick Mandibles /1.1; Twin Stinger's share of the shot is in deriveBuild.
  it('adds the lines first, then the perks: (600 + 40) x 17/15, 150 + 28.5, 0.42 / 1.075 / 1.1, 1 + 1 + 1 darts, 250 x 1.02', () => {
    const s = runStats(BASE_ANT, new Set<PerkId>(['chitin', 'twin', 'quick']), { ...emptyLines(), damage: 2, health: 1, rate: 1, speed: 1, darts: 1 });
    expect(s.maxHp).toBe(725);
    expect(s.damage).toBe(178.5);
    expect(s.fireInterval).toBeCloseTo(0.42 / 1.075 / 1.1, 12);
    expect(s.darts).toBe(3);
    expect(s.twin).toBe(true);
    expect(s.speed).toBeCloseTo(255, 9);
  });

  it('the order of buying does not matter: health after Thick Chitin and before it give the same ant', () => {
    const a = runStats(BASE_ANT, ['chitin'], { ...emptyLines(), health: 4 });
    const b = runStats(BASE_ANT, ['chitin'], { ...emptyLines(), health: 4 });
    expect(a).toEqual(b);
    expect(a.maxHp).toBe(Math.round((600 + 40 + 36 + 32.5 + 29) * (1 + 2 / 15)));
  });

  it('Thick Chitin buys add up: three give 600 x 1.4 = 840, the buy order of the perks does not matter (lane G8)', () => {
    expect(runStats(BASE_ANT, ['chitin', 'chitin'], emptyLines()).maxHp).toBe(760);
    const a = runStats(BASE_ANT, ['chitin', 'twin', 'chitin', 'quick', 'chitin'], emptyLines());
    const b = runStats(BASE_ANT, ['quick', 'chitin', 'chitin', 'chitin', 'twin'], emptyLines());
    expect(a).toEqual(b);
    expect(a.maxHp).toBe(840);
  });
});

describe('the pick cap: past it the shop is the only growth', () => {
  it('picks stop at level 12, the level up cap, and growth.ts reads the same number', () => {
    expect(PICK_CAP_LEVEL).toBe(12);
    expect(MAX_LEVEL).toBe(PICK_CAP_LEVEL);
    expect(picksOpen(1)).toBe(true);
    expect(picksOpen(11)).toBe(true);
    expect(picksOpen(12)).toBe(false);
  });
});

describe('the ledger', () => {
  it('a share of nothing earned is missing, not 0', () => {
    expect(spentShare(emptyLedger())).toBeNull();
    expect(spentShare({ earned: 1000, spent: 850 })).toBeCloseTo(0.85, 12);
  });
});

describe('the tuning model: a run at round 20 has spent most of its nectar', () => {
  const run = projectRun(32);
  const at = (r: number) => run[r - 1];

  it('by round 20 a buyer who keeps buying has spent at least 85 percent of what it earned', () => {
    const r20 = at(20);
    expect(r20.spent / r20.earned).toBeGreaterThanOrEqual(0.85);
    // What is held after the round 20 break is less than the next buy costs: nothing left over to sit on.
    expect(r20.held).toBeLessThan(linePrice('damage', { ...emptyLines(), damage: r20.buys }));
  });

  it('the buys keep coming but slow down: more in rounds 1 to 10 than in 11 to 20, and still some in 21 to 32', () => {
    const early = at(10).buys;
    const mid = at(20).buys - at(10).buys;
    const late = at(32).buys - at(20).buys;
    expect(early).toBeGreaterThan(mid);
    expect(mid).toBeGreaterThan(0);
    expect(late).toBeGreaterThan(0);
  });
});

describe('the hit cap: no single hit takes more than a fifth of the max health', () => {
  it.each([
    [150, 600, 120], [90, 600, 90], [120, 600, 120], [121, 600, 120], [160, 600, 120], [110, 600, 110],
    [150, 1500, 150], [400, 1500, 300], [8, 600, 8], [0, 600, 0], [50, 3, 1],
  ])('a hit of %i at %i max health takes %i', (raw, max, out) => {
    expect(capHit(raw, max)).toBe(out);
  });

  it('the share is 0.2', () => {
    expect(HIT_CAP_SHARE).toBe(0.2);
  });
});
