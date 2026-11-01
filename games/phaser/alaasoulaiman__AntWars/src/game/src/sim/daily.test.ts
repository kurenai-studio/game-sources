// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for the daily challenge (lane G7, M3): the seed of a day is pinned, the spawn order and the offers it
// drives are pinned, and the day's best round is kept per day.
import { describe, expect, it } from 'vitest';
import type { KeyValueStore } from './best';
import {
  DAILY_KEY,
  SPAWN_ROLLS,
  againDay,
  dailyOffer,
  dailySeed,
  dailySpawnKinds,
  dayKey,
  dayLabel,
  isDayKey,
  readDailyBest,
  recordDaily,
  spawnRolls,
  streamSeed,
} from './daily';
import { emptyStacks } from './growth';
import { seedOf } from './rng';

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

describe('the seed of a day', () => {
  it('seedOf is pinned (FNV-1a with the murmur3 finish)', () => {
    expect(seedOf('')).toBe(2872998923);
    expect(seedOf('a')).toBe(444641715);
  });

  it('dailySeed is pinned: the same number for the same day on every phone', () => {
    expect(dailySeed('2026-10-25')).toBe(668253784);
    expect(dailySeed('2026-10-26')).toBe(1756140373);
    expect(dailySeed('2027-01-01')).toBe(532401112);
    expect(dailySeed('2026-10-25')).toBe(dailySeed('2026-10-25'));
  });

  it('gives every day of a year its own seed, and every day its own spawn stream', () => {
    const days: string[] = [];
    for (let i = 0; i < 366; i++) days.push(dayKey(new Date(2026, 0, 1 + i, 12)));
    expect(new Set(days).size).toBe(366);
    expect(new Set(days.map(dailySeed)).size).toBe(366);
    expect(new Set(days.map((d) => streamSeed(dailySeed(d), 'spawn', 1))).size).toBe(366);
  });

  it('streams inside a day are apart: round 14 spawns and the first offer are pinned and differ', () => {
    expect(streamSeed(dailySeed('2026-10-25'), 'spawn', 14)).toBe(87762086);
    expect(streamSeed(dailySeed('2026-10-25'), 'offer', 0)).toBe(2373283046);
  });
});

describe('the calendar day', () => {
  it.each([
    [new Date(2026, 9, 25, 0, 0, 1), '2026-10-25'],
    [new Date(2026, 9, 25, 23, 59, 59), '2026-10-25'],
    [new Date(2026, 9, 26, 0, 0, 0), '2026-10-26'],
    [new Date(2027, 0, 5, 9), '2027-01-05'],
  ])('%s is the phone day %s (its own time zone, a new challenge at local midnight)', (d, key) => {
    expect(dayKey(d as Date)).toBe(key);
  });

  it.each([
    ['2026-10-25', true],
    ['2028-02-29', true],
    ['2026-02-29', false],
    ['2026-02-30', false],
    ['2026-13-01', false],
    ['2026-1-5', false],
    ['20261025', false],
    ['', false],
    [null, false],
    [20261025, false],
  ])('%j is a day: %s', (x, ok) => {
    expect(isDayKey(x)).toBe(ok);
  });

  it('shows as a short date', () => {
    expect(dayLabel('2026-10-25')).toBe('Oct 25');
    expect(dayLabel('2027-01-05')).toBe('Jan 5');
    expect(dayLabel('junk')).toBe('junk');
  });
});

describe('the spawn order and the offers a day drives', () => {
  it('every spawn takes six rolls in one order, whatever it turns out to be', () => {
    let n = 0;
    const counter = () => (n++ + 0.5) / 10;
    expect(spawnRolls(counter)).toEqual({ kind: 0.05, pit: 0.15, hole: 0.25, speed: 0.35, shot: 0.45, strafe: 0.55 });
    expect(n).toBe(SPAWN_ROLLS);
  });

  it('round 14 of Oct 25 2026 sends these 20 kinds first, the same on a second phone; Oct 26 sends others', () => {
    const oct25 = [
      'armyAnt', 'armyAnt', 'armyAnt', 'armyAnt', 'armyAnt', 'armyAnt', 'armyAnt', 'moth', 'armyAnt', 'spider',
      'wasp', 'beetle', 'wasp', 'ember', 'armyAnt', 'armyAnt', 'spider', 'beetle', 'armyAnt', 'wasp',
    ];
    expect(dailySpawnKinds('2026-10-25', 14, 20)).toEqual(oct25);
    expect(dailySpawnKinds('2026-10-25', 14, 20)).toEqual(dailySpawnKinds('2026-10-25', 14, 20));
    expect(dailySpawnKinds('2026-10-26', 14, 20)).not.toEqual(oct25);
  });

  it('the first three offers of Oct 25 2026 on a fresh ant are pinned; Oct 26 offers others', () => {
    expect([0, 1, 2].map((n) => dailyOffer('2026-10-25', n, emptyStacks()))).toEqual([
      ['honeydew', 'lucky', 'needle'],
      ['fork', 'fury', 'eye'],
      ['echo', 'eye', 'fury'],
    ]);
    expect(dailyOffer('2026-10-26', 0, emptyStacks())).toEqual(['frost', 'stance', 'fire']);
  });

  it('the same picks give the same offers: an offer depends only on the day, its number and the powers held', () => {
    const held = { ...emptyStacks(), jaw: 2, glands: 1 };
    expect(dailyOffer('2026-10-25', 4, held)).toEqual(dailyOffer('2026-10-25', 4, { ...held }));
    // A power at its cap is never offered.
    const capped = { ...emptyStacks(), needle: 1, hop: 1, lucky: 1, fury: 1, frost: 1 };
    for (let n = 0; n < 20; n++) {
      for (const id of dailyOffer('2026-10-25', n, capped)) expect(['needle', 'hop', 'lucky', 'fury', 'frost']).not.toContain(id);
    }
  });
});

describe("the day's best round", () => {
  it('starts with none, keeps the best of the day, and a new day starts over', () => {
    const store = memoryStore();
    expect(readDailyBest(store, '2026-10-25')).toBeNull();
    expect(recordDaily(store, '2026-10-25', 5)).toEqual({ best: 5, isNew: true, saved: true });
    expect(recordDaily(store, '2026-10-25', 3)).toEqual({ best: 5, isNew: false, saved: true });
    expect(recordDaily(store, '2026-10-25', 7)).toEqual({ best: 7, isNew: true, saved: true });
    expect(readDailyBest(store, '2026-10-25')).toBe(7);
    expect(recordDaily(store, '2026-10-26', 2)).toEqual({ best: 2, isNew: true, saved: true });
    expect(readDailyBest(store, '2026-10-26')).toBe(2);
    expect(readDailyBest(store, '2026-10-25')).toBeNull();
    expect(JSON.parse(store.data.get(DAILY_KEY) as string)).toEqual({ day: '2026-10-26', best: 2 });
  });

  it('a run from an older day than the one kept keeps nothing and changes nothing', () => {
    const store = memoryStore();
    recordDaily(store, '2026-10-26', 4);
    expect(recordDaily(store, '2026-10-25', 9)).toEqual({ best: 9, isNew: false, saved: false });
    expect(readDailyBest(store, '2026-10-26')).toBe(4);
  });

  it('junk, no storage, or storage that refuses reads as none and saves nothing', () => {
    const store = memoryStore();
    store.data.set(DAILY_KEY, '{not json');
    expect(readDailyBest(store, '2026-10-25')).toBeNull();
    store.data.set(DAILY_KEY, JSON.stringify({ day: '2026-10-25', best: 0 }));
    expect(readDailyBest(store, '2026-10-25')).toBeNull();
    expect(readDailyBest(null, '2026-10-25')).toBeNull();
    expect(recordDaily(null, '2026-10-25', 3)).toEqual({ best: 3, isNew: true, saved: false });
    expect(readDailyBest(throwing, '2026-10-25')).toBeNull();
    expect(recordDaily(throwing, '2026-10-25', 3)).toEqual({ best: 3, isNew: true, saved: false });
  });
});

describe('PLAY AGAIN on a death screen (VG7)', () => {
  it.each([
    ['a Daily run of today plays today again', '2026-10-25', '2026-10-25', '2026-10-25'],
    ['a Daily run of yesterday (the ant fell after midnight) plays today, not yesterday', '2026-10-25', '2026-10-26', '2026-10-26'],
    ['a Daily run from a day ahead of the phone (its clock went back) plays today', '2026-10-27', '2026-10-26', '2026-10-26'],
    ['a Daily run of last year plays today', '2025-12-31', '2026-01-01', '2026-01-01'],
    ['a normal run stays a normal run', null, '2026-10-26', null],
    ['no real day carried stays a normal run', 'today', '2026-10-26', null],
    ['a number is no day', 20261025, '2026-10-26', null],
  ])('%s', (_what, runDay, today, plays) => {
    expect(againDay(runDay, today as string)).toBe(plays);
  });

  it('never hands back a day that is not today', () => {
    for (let i = 0; i < 400; i++) {
      const run = dayKey(new Date(2026, 0, 1 + i, 12));
      const today = dayKey(new Date(2026, 0, 1 + ((i * 7) % 400), 12));
      const plays = againDay(run, today);
      expect(plays).toBe(today);
    }
  });
});
