// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Lane N1, M2 (design note, 2026-10-29): the stats tab's sheet. A table over the bare ant, Strong Jaw x3 with Twin
// Stinger, Front Fang with the Extra Dart line and a Colony run with two Barbed Stingers (and a late run with a row of
// every kind). The numbers are pinned by hand, and the sheet's ant must be the ant GameScene builds from the same run.
import { describe, expect, it } from 'vitest';
import { applyColony, emptyLevels, levelsFor } from './colony';
import { BASE_ANT, emptyLines, runStats, type PerkId } from './economy';
import { deriveBuild, emptyStacks, type PowerId } from './growth';
import { GROUP_TITLES, formatNumber, formatPercent, rowText, statsSheet, type StatRow, type StatsInput } from './stats';

const bare: StatsInput = { ladder: 'pure', colony: emptyLevels(), owned: [], lines: emptyLines(), stacks: emptyStacks(), hp: 600 };
const withPowers = (stacks: Partial<Record<PowerId, number>>) => ({ ...emptyStacks(), ...stacks });

/** The ant exactly as GameScene builds it: metaBase (the colony on a Colony run), runStats on the nest buys, deriveBuild. */
const gameBuild = (i: StatsInput) => deriveBuild(runStats(applyColony(BASE_ANT, levelsFor(i.ladder, i.colony)), i.owned, i.lines), i.stacks);

const stat = (rows: StatRow[], id: string) => rows.find((r) => r.group === 'stat' && r.id === id);
const upgrades = (rows: StatRow[]) => rows.filter((r) => r.group !== 'stat').map((r) => [r.group, r.label, r.value, r.note]);

const twinJaw: StatsInput = { ...bare, stacks: withPowers({ jaw: 3 }), owned: ['twin'] };
const fangDart: StatsInput = { ...bare, stacks: withPowers({ fang: 1 }), lines: { ...emptyLines(), darts: 1 } };
const colonyStingers: StatsInput = { ...bare, ladder: 'colony', colony: { ...emptyLevels(), stinger: 2 } };

// [case, input, dart, shot, darts, damage row, damage note, the upgrade rows]
const TABLE: ReadonlyArray<readonly [string, StatsInput, number, number, number, string, string, ReadonlyArray<readonly string[]>]> = [
  ['the bare ant', bare, 150, 150, 1, '150 a dart, 150 a shot', '', []],
  [
    'Strong Jaw x3 and Twin Stinger',
    twinJaw,
    115.5,
    231,
    2,
    '115.5 a dart, 231 a shot',
    '2 darts a shot',
    [
      ['power', 'Strong Jaw', '3/5', 'Darts hit 13% harder'],
      ['perk', 'Twin Stinger', 'owned', 'Two darts, +10%'],
    ],
  ],
  [
    'Front Fang and the Extra Dart line',
    fangDart,
    112.5,
    337.5,
    3,
    '112.5 a dart, 337.5 a shot',
    '3 darts a shot',
    [
      ['power', 'Front Fang', '1/2', 'One more dart; all darts 25% weaker'],
      ['line', 'Extra Dart', '+1', 'over 1 buy'],
    ],
  ],
  ['a Colony run with two Barbed Stingers', colonyStingers, 158, 158, 1, '158 a dart, 158 a shot', '', [['colony', 'Barbed Stinger', '2/30', '+8 dart damage']]],
];

describe('the stats tab sheet (lane N1, M2)', () => {
  it.each(TABLE)('%s: the dart, the shot, the darts, the damage row and every upgrade owned', (_name, input, dart, shot, darts, value, note, ups) => {
    const sheet = statsSheet(input);
    expect(sheet.numbers.dart).toBeCloseTo(dart, 9);
    expect(sheet.numbers.shot).toBeCloseTo(shot, 9);
    expect(sheet.numbers.darts).toBe(darts);
    expect(stat(sheet.rows, 'damage')).toEqual({ group: 'stat', id: 'damage', label: 'Damage', value, note });
    expect(upgrades(sheet.rows)).toEqual(ups);
    // The sheet's ant is the game's ant for the same run: the same builders, nothing retyped.
    expect(sheet.build).toEqual(gameBuild(input));
    expect(sheet.numbers.dart).toBe(gameBuild(input).damage);
  });

  it('the bare ant, row by row: crit, fire rate standing and moving, speed, health and damage taken', () => {
    const sheet = statsSheet(bare);
    expect(sheet.rows.map((r) => [r.id, r.label, r.value, r.note])).toEqual([
      ['damage', 'Damage', '150 a dart, 150 a shot', ''],
      ['crit', 'Crit', '10% standing still', 'x2 damage, not while moving'],
      ['rate', 'Fire rate', '2.38 still, 1.19 moving', 'shots a second'],
      ['speed', 'Speed', '100%', ''],
      ['health', 'Health', '600 / 600', ''],
      ['taken', 'Damage taken', 'full', 'no hit takes more than 120'],
    ]);
    expect(sheet.numbers).toMatchObject({ darts: 1, volleys: 1, angled: 0, crit: 0.1, speed: 1, hp: 600, maxHp: 600, block: 0, armor: 0, hitCap: 120, fury: 1 });
    expect(sheet.numbers.rateStill).toBeCloseTo(1 / 0.42, 12);
    expect(sheet.numbers.rateMoving).toBeCloseTo(1 / 0.84, 12);
  });

  it('a Pure run (a Daily run is one) ignores the colony: two Barbed Stingers banked, 150 a dart and no Colony row', () => {
    const sheet = statsSheet({ ...colonyStingers, ladder: 'pure' });
    expect(sheet.numbers.dart).toBe(150);
    expect(sheet.rows.some((r) => r.group === 'colony')).toBe(false);
  });

  it('a late run lists a row of every kind, the powers in the order of the cards, the perks, the lines and the colony', () => {
    const input: StatsInput = {
      ladder: 'colony',
      colony: { ...emptyLevels(), diet: 1, plates: 2, legs: 2, venom: 3, sweet: 1 },
      owned: ['chitin', 'chitin', 'quick'] as PerkId[],
      lines: { ...emptyLines(), damage: 2, rate: 2, health: 1, speed: 1 },
      stacks: withPowers({ glands: 2, eye: 1, echo: 1, stance: 1, honeydew: 2, fork: 1, fury: 1 }),
      hp: 300,
    };
    const sheet = statsSheet(input);
    expect(sheet.build).toEqual(gameBuild(input));
    // 600 + 12.5 rounds to 613, +40 bought is 653, two Thick Chitins x(1 + 4/15) is 827.13, rounded 827.
    expect(sheet.numbers.maxHp).toBe(827);
    // 150 + 15 + 13.5 bought, times 0.9 for one Echo Sting.
    expect(sheet.numbers.dart).toBeCloseTo(160.65, 9);
    expect(sheet.numbers.shot).toBeCloseTo(321.3, 9);
    expect(sheet.numbers.hitCap).toBe(165);
    expect(sheet.rows.filter((r) => r.group === 'stat').map((r) => [r.id, r.value, r.note])).toEqual([
      ['damage', '160.7 a dart, 321.3 a shot', '2 volleys, +2 angled darts, Fury x1.42 now'],
      ['crit', '16.7% standing still', 'x2 damage, not while moving'],
      ['rate', '3.14 still, 1.57 moving', 'shots a second, 2 volleys each'],
      ['speed', '103%', 'Long Legs +1%, Speed buys +2%'],
      ['health', '300 / 827', ''],
      ['taken', '13.3% less standing still, 2% less always', 'no hit takes more than 165'],
    ]);
    expect(sheet.rows.filter((r) => r.group !== 'stat').map(rowText)).toEqual([
      'Quick Glands 2/4',
      'Honeydew x2',
      'Keen Eye 1/3',
      'Fork Darts 1/2',
      'Echo Sting 1/3',
      'Fury Glands 1/1',
      'Stone Stance 1/2',
      'Thick Chitin 2/3',
      'Quick Mandibles',
      'Dart Damage +28.5 over 2 buys',
      'Fire Rate +14% over 2 buys',
      'Max Health +40 over 1 buy',
      'Speed +2% over 1 buy',
      'Royal Diet 1/30',
      'Plated Back 2/15',
      'Long Legs 2/10',
      'Rapid Venom 3/20',
      'Sweet Tooth 1/20',
    ]);
    // What each colony step gives on its own, kept in the row's note (Royal Diet: 600 + 12.5 rounds to 613).
    expect(sheet.rows.filter((r) => r.group === 'colony').map((r) => [r.label, r.note])).toEqual([
      ['Royal Diet', '+13 max health'],
      ['Plated Back', '2% less damage taken'],
      ['Long Legs', '+1% speed'],
      ['Rapid Venom', '+3% fire rate'],
      ['Sweet Tooth', '+2.5% nectar'],
    ]);
  });

  it('the health row follows the run: current health rounds up as the HUD shows it, and only Fury Glands reads it', () => {
    expect(stat(statsSheet({ ...bare, hp: 431.2 }).rows, 'health')?.value).toBe('432 / 600');
    expect(statsSheet({ ...bare, hp: 1 }).numbers.dart).toBe(150);
    const fury = statsSheet({ ...bare, stacks: withPowers({ fury: 1 }), hp: 300 });
    expect(fury.numbers.fury).toBeCloseTo(1 + (2 / 3) * 0.5, 12);
    expect(stat(fury.rows, 'damage')?.note).toBe('Fury x1.33 now');
  });

  it('lists the upgrade groups in one order, each heading once', () => {
    expect(GROUP_TITLES.map(([g]) => g)).toEqual(['power', 'perk', 'line', 'colony']);
    expect(new Set(GROUP_TITLES.map(([, t]) => t)).size).toBe(4);
  });

  it.each([
    [150, 1, '150'],
    [115.50000000000001, 1, '115.5'],
    [230.99999999999997, 1, '231'],
    [1234.56, 1, '1,234.6'],
    [1000000, 0, '1,000,000'],
    [2.380952, 2, '2.38'],
    [-0.00001, 1, '0'],
    [0, 2, '0'],
  ])('formats %f to %i decimals as %s', (n, digits, text) => {
    expect(formatNumber(n, digits)).toBe(text);
  });

  it('formats shares as percents', () => {
    expect(formatPercent(0.1)).toBe('10%');
    expect(formatPercent(2 / 15)).toBe('13.3%');
    expect(formatPercent(1.0302)).toBe('103%');
    expect(formatPercent(0.025)).toBe('2.5%');
  });
});
