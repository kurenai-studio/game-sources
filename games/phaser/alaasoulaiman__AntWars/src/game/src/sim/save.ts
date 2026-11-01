// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The run save (CONCEPT_V2 section 2: a run saves at every round break, so a session on the bus continues at home).
// One record in localStorage, written in every break and cleared when the run ends. Every storage touch is guarded:
// Safari can refuse or lose storage, and a record that does not check out reads as no save at all.
import type { KeyValueStore } from './best';
import { isLadder, type Ladder } from './colony';
import { isDayKey } from './daily';
import { LINES, LINE_IDS, PERKS, emptyLines, isLineId, perkCount, type Ledger, type LineId, type PerkId } from './economy';
import { MAX_LEVEL, POWERS, POWER_IDS, canTake, drawOffer, isPowerId, xpToNext, type PowerId } from './growth';

export const RUN_KEY = 'antwars.run.v1';

/** Storage that can also forget a key (the run save ends on a death). localStorage is one. */
export interface RunStore extends KeyValueStore {
  removeItem(key: string): void;
}

/** The browser's localStorage, or null when the browser refuses access. */
export function browserRunStore(): RunStore | null {
  try {
    return typeof window !== 'undefined' && window.localStorage ? window.localStorage : null;
  } catch {
    return null;
  }
}

export interface RunSave {
  v: 1;
  /** The round just cleared: Continue puts the ant in the break after it, with the full countdown. */
  round: number;
  level: number;
  xp: number;
  stacks: Record<PowerId, number>;
  /** Nest perks bought this run, a perk once per buy (lane G8: Thick Chitin up to three times). */
  owned: PerkId[];
  nectar: number;
  hp: number;
  kills: number;
  /** Picks still waiting, the powers on the sheet for the first of them, and the sheet's title. */
  pending: number;
  offer: PowerId[];
  pickTitle: string;
  /** The ladder the run is on; a record from before the Colony has none and reads as Pure (it had no meta). */
  ladder: Ladder;
  /** Slice 4: the nest shop's repeatable lines bought this run; a record from before has none and reads as none bought. */
  lines: Record<LineId, number>;
  /** Slice 4: nectar earned and spent this run; null in a record from before, where it was never counted. */
  ledger: Ledger | null;
  /** Lane G7, M3: the day of a Daily run (always a Pure run), null on any other run and in a record from before. */
  daily: string | null;
  /** Lane G7, M3: pick offers drawn so far, so a Daily run's next offer comes from the same stream after Continue. */
  offers: number;
}

const PERK_IDS: ReadonlyArray<PerkId> = PERKS.map((p) => p.id);

const isInt = (x: unknown, lo: number, hi: number): x is number => typeof x === 'number' && Number.isInteger(x) && x >= lo && x <= hi;

/**
 * The record from its stored text, or null when it is missing, junk, from another version or does not add up. An offer
 * that holds a power already at its cap could never be taken (VG3), so it is drawn again from the saved stacks with roll.
 */
export function decodeRun(raw: string | null, roll: () => number = Math.random): RunSave | null {
  if (raw === null) return null;
  let o: unknown;
  try {
    o = JSON.parse(raw);
  } catch {
    return null;
  }
  if (typeof o !== 'object' || o === null || Array.isArray(o)) return null;
  const r = o as Record<string, unknown>;
  if (r.v !== 1) return null;
  if (!isInt(r.round, 1, 100000) || !isInt(r.level, 1, MAX_LEVEL) || !isInt(r.kills, 0, 10000000)) return null;
  const need = xpToNext(r.level);
  if (!isInt(r.xp, 0, need === null ? 0 : need - 1)) return null;
  if (typeof r.nectar !== 'number' || !Number.isFinite(r.nectar) || r.nectar < 0) return null;
  if (typeof r.hp !== 'number' || !Number.isFinite(r.hp) || r.hp <= 0) return null;
  if (typeof r.stacks !== 'object' || r.stacks === null || Array.isArray(r.stacks)) return null;
  const rawStacks = r.stacks as Record<string, unknown>;
  if (Object.keys(rawStacks).some((k) => !isPowerId(k))) return null;
  const stacks = {} as Record<PowerId, number>;
  for (const p of POWERS) {
    // The slice 4 elements came after the first saves: a record without them has none.
    const n = rawStacks[p.id] ?? (p.id === 'fire' || p.id === 'spark' ? 0 : undefined);
    if (!isInt(n, 0, p.max === null ? 100000 : p.max)) return null;
    stacks[p.id] = n;
  }
  // Lane G8: a perk shows once per buy, so Thick Chitin may repeat up to its max; a record from before holds each once.
  if (!Array.isArray(r.owned) || r.owned.some((id) => !PERK_IDS.includes(id as PerkId))) return null;
  if (PERKS.some((p) => perkCount(r.owned as PerkId[], p.id) > p.max)) return null;
  if (!isInt(r.pending, 0, 1000)) return null;
  if (!Array.isArray(r.offer) || r.offer.length > 3 || r.offer.some((id) => !isPowerId(id)) || new Set(r.offer).size !== r.offer.length) return null;
  if ((r.pending > 0) !== (r.offer.length > 0)) return null;
  if (typeof r.pickTitle !== 'string' || r.pickTitle.length > 60) return null;
  const ladder = r.ladder === undefined ? 'pure' : r.ladder;
  if (!isLadder(ladder)) return null;
  const lines = emptyLines();
  if (r.lines !== undefined) {
    if (typeof r.lines !== 'object' || r.lines === null || Array.isArray(r.lines)) return null;
    const rawLines = r.lines as Record<string, unknown>;
    if (Object.keys(rawLines).some((k) => !isLineId(k))) return null;
    for (const l of LINES) {
      const n = rawLines[l.id] ?? 0;
      if (!isInt(n, 0, l.max === null ? 100000 : l.max)) return null;
      lines[l.id] = n;
    }
  }
  let ledger: Ledger | null = null;
  if (r.ledger !== undefined && r.ledger !== null) {
    const g = r.ledger as Record<string, unknown>;
    const ok = (x: unknown) => typeof x === 'number' && Number.isFinite(x) && x >= 0;
    if (typeof g !== 'object' || !ok(g.earned) || !ok(g.spent)) return null;
    ledger = { earned: g.earned as number, spent: g.spent as number };
  }
  // Lane G7, M3: a record from before the daily challenge is no Daily run and has drawn no counted offers.
  const daily = r.daily === undefined || r.daily === null ? null : r.daily;
  if (daily !== null && (!isDayKey(daily) || ladder !== 'pure')) return null;
  const offers = r.offers === undefined ? 0 : r.offers;
  if (!isInt(offers, 0, 1000000)) return null;
  let offer = [...(r.offer as PowerId[])];
  if (offer.some((id) => !canTake(stacks, id))) offer = drawOffer(stacks, roll);
  return {
    v: 1,
    round: r.round,
    level: r.level,
    xp: r.xp,
    stacks,
    owned: [...(r.owned as PerkId[])],
    nectar: r.nectar,
    hp: r.hp,
    kills: r.kills,
    pending: r.pending,
    offer,
    pickTitle: r.pickTitle,
    ladder,
    lines,
    ledger,
    daily,
    offers,
  };
}

/** The stored text of a record; the power stacks always in the table's order. */
export function encodeRun(save: Readonly<RunSave>): string {
  const stacks = {} as Record<PowerId, number>;
  for (const id of POWER_IDS) stacks[id] = save.stacks[id];
  const lines = {} as Record<LineId, number>;
  for (const id of LINE_IDS) lines[id] = save.lines[id];
  return JSON.stringify({ ...save, stacks, lines });
}

/** Writes the record; false when there is no storage or it refused. */
export function saveRun(store: KeyValueStore | null, save: Readonly<RunSave>): boolean {
  if (!store) return false;
  try {
    store.setItem(RUN_KEY, encodeRun(save));
    return true;
  } catch {
    return false;
  }
}

/** The saved run, or null when there is none, it cannot be read or it does not check out. */
export function loadRun(store: KeyValueStore | null, roll: () => number = Math.random): RunSave | null {
  if (!store) return null;
  try {
    return decodeRun(store.getItem(RUN_KEY), roll);
  } catch {
    return null;
  }
}

/** Ends the save (a death, or a new run from the title); false when there is no storage or it refused. */
export function clearRun(store: RunStore | null): boolean {
  if (!store) return false;
  try {
    store.removeItem(RUN_KEY);
    return true;
  } catch {
    return false;
  }
}
