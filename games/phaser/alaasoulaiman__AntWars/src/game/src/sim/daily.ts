// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Lane G7, M3: the daily challenge. One seed per calendar day, the same on every phone that day. It drives the spawn
// order (each round its own stream, a fixed number of rolls a spawn) and the picks offered (each offer its own stream),
// so two players who take the same picks meet the same predators in the same order and are offered the same powers.
// A Daily run is a Pure run (the bare ant, nothing banked) with its own best round for its day.
import type { KeyValueStore, RunRecord } from './best';
import { drawOffer, type PowerId, type PowerStacks } from './growth';
import { makeRng, seedOf } from './rng';
import { pickPredator, type PredatorKind } from './roster';

export const DAILY_KEY = 'antwars.daily.v1';

const pad = (n: number) => String(n).padStart(2, '0');

/** The phone's calendar day as YYYY-MM-DD in its own time zone, so the challenge turns over at local midnight. */
export function dayKey(d: Date): string {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

/** True only for a real calendar day written YYYY-MM-DD (2026-02-30 and 2026-1-5 are not). */
export function isDayKey(x: unknown): x is string {
  if (typeof x !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(x)) return false;
  const [y, m, d] = x.split('-').map(Number);
  const t = new Date(Date.UTC(y, m - 1, d));
  return y >= 2000 && y <= 9999 && t.getUTCFullYear() === y && t.getUTCMonth() === m - 1 && t.getUTCDate() === d;
}

/**
 * PLAY AGAIN on a death screen: the day the next run plays (VG7). A Daily run of today plays today again; a Daily run
 * of any other day (the ant fell after midnight) plays today's challenge, never a fresh run of yesterday's under the
 * DAILY tag; any other run (null, or no real day) starts a normal run.
 */
export function againDay(runDay: unknown, today: string): string | null {
  if (!isDayKey(runDay)) return null;
  if (runDay === today) return runDay;
  return isDayKey(today) ? today : null;
}

/** The day's seed: one 32 bit number for the day, the same on every phone. */
export function dailySeed(day: string): number {
  return seedOf(`antwars-daily:${day}`);
}

/** A stream inside the day: the spawn rolls of round n, the n-th pick offer, the element chances. */
export type DailyStream = 'spawn' | 'offer' | 'chance';
export function streamSeed(seed: number, stream: DailyStream, n: number): number {
  return seedOf(`${seed}:${stream}:${n}`);
}

/**
 * The rolls one spawn takes: always these six, in this order, whatever the spawn turns out to be (a boss takes no kind
 * roll, only an antlion needs a pit roll), so no spawn ever shifts the rolls of the spawns after it.
 */
export const SPAWN_ROLLS = 6;
export interface SpawnRolls {
  kind: number;
  pit: number;
  hole: number;
  speed: number;
  shot: number;
  strafe: number;
}
export function spawnRolls(next: () => number): SpawnRolls {
  const kind = next();
  const pit = next();
  const hole = next();
  const speed = next();
  const shot = next();
  const strafe = next();
  return { kind, pit, hole, speed, shot, strafe };
}

/** The kinds the first n spawns of a horde round roll on a day, as the Yard rolls them (the pin for two players). */
export function dailySpawnKinds(day: string, round: number, n: number): PredatorKind[] {
  const next = makeRng(streamSeed(dailySeed(day), 'spawn', round));
  const out: PredatorKind[] = [];
  for (let i = 0; i < n; i++) out.push(pickPredator(round, spawnRolls(next).kind));
  return out;
}

/** The n-th pick offer of a Daily run for the powers the run holds, as the Yard draws it. */
export function dailyOffer(day: string, n: number, stacks: PowerStacks): PowerId[] {
  return drawOffer(stacks, makeRng(streamSeed(dailySeed(day), 'offer', n)));
}

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/** The day as the title and the death screen show it: Oct 25. */
export function dayLabel(day: string): string {
  if (!isDayKey(day)) return day;
  const [, m, d] = day.split('-').map(Number);
  return `${MONTHS[m - 1]} ${d}`;
}

/** The best round of the given day, or null when that day has none yet (or the stored record is another day's or junk). */
export function readDailyBest(store: KeyValueStore | null, day: string): number | null {
  if (!store) return null;
  try {
    const raw = store.getItem(DAILY_KEY);
    if (raw === null) return null;
    const o = JSON.parse(raw) as { day?: unknown; best?: unknown };
    if (!o || o.day !== day || !isDayKey(o.day)) return null;
    return typeof o.best === 'number' && Number.isInteger(o.best) && o.best >= 1 ? o.best : null;
  } catch {
    return null;
  }
}

/**
 * Records a Daily run that reached the given round on its day. The phone keeps the newest day only: a better round
 * replaces that day's best, a new day starts over, and a run from a day older than the stored one keeps nothing.
 */
export function recordDaily(store: KeyValueStore | null, day: string, roundReached: number): RunRecord {
  let storedDay: string | null = null;
  if (store) {
    try {
      const raw = store.getItem(DAILY_KEY);
      const o = raw === null ? null : (JSON.parse(raw) as { day?: unknown });
      storedDay = o && isDayKey(o.day) ? o.day : null;
    } catch {
      storedDay = null;
    }
  }
  if (storedDay !== null && storedDay > day) return { best: roundReached, isNew: false, saved: false };
  const previous = readDailyBest(store, day);
  if (previous !== null && previous >= roundReached) return { best: previous, isNew: false, saved: true };
  let saved = false;
  if (store) {
    try {
      store.setItem(DAILY_KEY, JSON.stringify({ day, best: roundReached }));
      saved = true;
    } catch {
      saved = false;
    }
  }
  return { best: roundReached, isNew: true, saved };
}
