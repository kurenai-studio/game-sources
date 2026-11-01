// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for the run save: the round trip, junk and refused storage, and a record built from the real growth rules.
import { describe, expect, it } from 'vitest';
import { BASE_ANT, buyLine, emptyLines, runStats } from './economy';
import { addXp, canTake, deriveBuild, drawOffer, emptyStacks, takePower } from './growth';
import { RUN_KEY, clearRun, decodeRun, encodeRun, loadRun, saveRun, type RunSave, type RunStore } from './save';

function memoryStore(): RunStore & { data: Map<string, string> } {
  const data = new Map<string, string>();
  return {
    data,
    getItem: (k) => (data.has(k) ? (data.get(k) as string) : null),
    setItem: (k, v) => {
      data.set(k, v);
    },
    removeItem: (k) => {
      data.delete(k);
    },
  };
}

const throwing: RunStore = {
  getItem: () => {
    throw new Error('refused');
  },
  setItem: () => {
    throw new Error('refused');
  },
  removeItem: () => {
    throw new Error('refused');
  },
};

function sample(): RunSave {
  return {
    v: 1,
    round: 7,
    level: 6,
    xp: 12,
    stacks: { ...emptyStacks(), jaw: 2, fork: 1, lucky: 1 },
    owned: ['twin', 'chitin'],
    nectar: 1830,
    hp: 1240,
    kills: 131,
    pending: 1,
    offer: ['glands', 'shell', 'echo'],
    pickTitle: 'LEVEL UP: PICK ONE',
    ladder: 'colony',
    lines: { ...emptyLines(), damage: 3, health: 1 },
    ledger: { earned: 9400, spent: 7570 },
    daily: null,
    offers: 6,
  };
}

describe('the run save of a Daily run (lane G7, M3)', () => {
  const daily = (): RunSave => ({ ...sample(), ladder: 'pure', daily: '2026-10-25', offers: 4 });

  it('round trips with its day and the offers drawn', () => {
    const store = memoryStore();
    expect(saveRun(store, daily())).toBe(true);
    expect(loadRun(store)).toEqual(daily());
  });

  it('a record from before the daily challenge reads as no Daily run with no offers counted', () => {
    const old: Record<string, unknown> = { ...sample() };
    delete old.daily;
    delete old.offers;
    expect(decodeRun(JSON.stringify(old))).toEqual({ ...sample(), daily: null, offers: 0 });
  });

  it.each([
    [{ daily: '2026-02-30' }],
    [{ daily: 'today' }],
    [{ daily: 20261025 }],
    [{ daily: '2026-10-25', ladder: 'colony' }],
    [{ offers: -1 }],
    [{ offers: 1.5 }],
    [{ offers: '3' }],
  ])('a record with %j does not check out', (change) => {
    expect(decodeRun(JSON.stringify({ ...daily(), ...change }))).toBeNull();
  });
});

describe('the run save', () => {
  it('round trips through storage under its own key', () => {
    const store = memoryStore();
    expect(saveRun(store, sample())).toBe(true);
    expect(store.data.has(RUN_KEY)).toBe(true);
    expect(RUN_KEY).toBe('antwars.run.v1');
    expect(loadRun(store)).toEqual(sample());
  });

  it('is null, not a fresh run, when nothing was saved; clearing ends it', () => {
    const store = memoryStore();
    expect(loadRun(store)).toBeNull();
    saveRun(store, sample());
    expect(clearRun(store)).toBe(true);
    expect(loadRun(store)).toBeNull();
  });

  it('no storage, or storage that throws, never throws back', () => {
    expect(loadRun(null)).toBeNull();
    expect(saveRun(null, sample())).toBe(false);
    expect(clearRun(null)).toBe(false);
    expect(loadRun(throwing)).toBeNull();
    expect(saveRun(throwing, sample())).toBe(false);
    expect(clearRun(throwing)).toBe(false);
  });

  it.each(['', 'null', '{', '[]', '42', '"run"', '{"v":2}', '{"v":1}'])('junk %j reads as no save', (raw) => {
    expect(decodeRun(raw)).toBeNull();
  });

  it.each([
    ['round 0', { round: 0 }],
    ['level 13', { level: 13 }],
    ['xp at the next level', { level: 6, xp: 50 }],
    ['xp at the cap', { level: 12, xp: 1 }],
    ['negative nectar', { nectar: -1 }],
    ['health 0 (a dead run)', { hp: 0 }],
    ['a power past its cap', { stacks: { ...emptyStacks(), lucky: 2 } }],
    ['an unknown power', { stacks: { ...emptyStacks(), laser: 1 } }],
    ['a missing power', { stacks: { jaw: 1 } }],
    ['a one time perk twice', { owned: ['twin', 'twin'] }],
    ['Thick Chitin past its three buys (lane G8)', { owned: ['chitin', 'chitin', 'chitin', 'chitin'] }],
    ['an unknown perk', { owned: ['jetpack'] }],
    ['a pick waiting with no offer', { pending: 1, offer: [] }],
    ['an offer with no pick waiting', { pending: 0, offer: ['jaw'] }],
    ['an unknown power on offer', { offer: ['jaw', 'laser'] }],
    ['four on offer', { offer: ['jaw', 'glands', 'shell', 'echo'] }],
    ['an unknown ladder', { ladder: 'gold' }],
    ['an unknown shop line', { lines: { ...emptyLines(), laser: 1 } }],
    ['a line past its cap', { lines: { ...emptyLines(), speed: 9 } }],
    ['a line bought a fraction', { lines: { ...emptyLines(), damage: 1.5 } }],
    ['lines that are a list', { lines: [1, 2] }],
    ['a negative spend', { ledger: { earned: 10, spent: -1 } }],
    ['a ledger with no earned', { ledger: { spent: 4 } }],
  ])('a record with %s reads as no save', (_name, change) => {
    expect(decodeRun(JSON.stringify({ ...sample(), ...change }))).toBeNull();
  });

  it('keeps Thick Chitin bought three times (lane G8: a perk once per buy)', () => {
    const owned = ['chitin', 'twin', 'chitin', 'chitin'];
    expect(decodeRun(JSON.stringify({ ...sample(), owned }))?.owned).toEqual(owned);
  });

  it('an offer holding powers already at their caps is drawn again on load (VG3), the pick still waiting', () => {
    const capped = { ...sample(), stacks: { ...emptyStacks(), needle: 1, hop: 1, lucky: 1 }, pending: 1, offer: ['needle', 'hop', 'lucky'] };
    const store = memoryStore();
    store.setItem(RUN_KEY, JSON.stringify(capped));
    const loaded = loadRun(store, () => 0);
    expect(loaded).not.toBeNull();
    expect(loaded?.pending).toBe(1);
    expect(loaded?.offer).toEqual(['jaw', 'glands', 'shell']);
    for (const id of loaded?.offer ?? []) expect(canTake(loaded!.stacks, id)).toBe(true);
    const mixed = decodeRun(JSON.stringify({ ...capped, offer: ['jaw', 'lucky'] }), () => 0.999);
    expect(mixed?.offer).toEqual(['spark', 'fire', 'stance']);
    const fine = decodeRun(JSON.stringify(sample()), () => 0);
    expect(fine?.offer).toEqual(sample().offer);
  });

  it('a record from before slice 4 (no lines, no ledger) reads as nothing bought and a ledger never counted', () => {
    const old: Record<string, unknown> = { ...sample() };
    delete old.lines;
    delete old.ledger;
    expect(decodeRun(JSON.stringify(old))).toEqual({ ...sample(), lines: emptyLines(), ledger: null });
    // A line missing from the record reads as not bought; the rest of the record is kept.
    expect(decodeRun(JSON.stringify({ ...sample(), lines: { damage: 2 } }))?.lines).toEqual({ ...emptyLines(), damage: 2 });
  });

  it('a record from before slice 4 with no fire or spark stack reads them as 0, the rest kept', () => {
    const s = sample();
    const stacks: Record<string, number> = { ...s.stacks };
    delete stacks.fire;
    delete stacks.spark;
    expect(decodeRun(JSON.stringify({ ...s, stacks }))).toEqual(s);
    // Any other power missing still means the record does not check out.
    delete stacks.jaw;
    expect(decodeRun(JSON.stringify({ ...s, stacks }))).toBeNull();
  });

  it('a record from before the Colony (no ladder) reads as a Pure run, the rest kept', () => {
    const old: Record<string, unknown> = { ...sample() };
    delete old.ladder;
    expect(decodeRun(JSON.stringify(old))).toEqual({ ...sample(), ladder: 'pure' });
    expect(decodeRun(JSON.stringify(sample()))?.ladder).toBe('colony');
  });

  it('the stored text lists the powers in the table order whatever order they came in', () => {
    const s = sample();
    const shuffled = { ...s, stacks: Object.fromEntries(Object.entries(s.stacks).reverse()) as RunSave['stacks'] };
    expect(Object.keys(shuffled.stacks)[0]).toBe('spark');
    expect(encodeRun(shuffled)).toBe(encodeRun(s));
  });

  it('a record made by the real growth and shop rules round trips', () => {
    const xp = addXp({ level: 1, xp: 0 }, 140);
    let stacks = emptyStacks();
    stacks = takePower(stacks, 'shell');
    stacks = takePower(stacks, 'echo');
    const bought = buyLine(5000, emptyLines(), 'health', 5);
    const perks = runStats(BASE_ANT, new Set(['chitin'] as const), bought.levels);
    const build = deriveBuild(perks, stacks);
    let seed = 3;
    const offer = drawOffer(stacks, () => {
      seed = (seed * 48271) % 2147483647;
      return seed / 2147483647;
    });
    const save: RunSave = {
      v: 1, round: 6, level: xp.level, xp: xp.xp, stacks, owned: ['chitin'], nectar: 960, hp: build.maxHp, kills: 70,
      pending: 1, offer, pickTitle: 'LEVEL UP: PICK ONE', ladder: 'pure', lines: bought.levels, ledger: { earned: 5000, spent: 5000 - bought.nectar },
      daily: null, offers: 3,
    };
    expect(xp).toEqual({ level: 6, xp: 10, ups: 5 });
    // (600 + 40) x (1 + 2/15) for one Thick Chitin buy (lane G8), then x (1 + 2/15) for Hearty Shell: the shop line goes
    // in before Thick Chitin multiplies.
    expect(build.maxHp).toBe(822);
    const store = memoryStore();
    saveRun(store, save);
    expect(loadRun(store)).toEqual(save);
  });
});
