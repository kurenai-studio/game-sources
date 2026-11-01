// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The best round, kept in localStorage. Every storage touch is guarded: Safari can refuse or lose storage.

export interface KeyValueStore {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
}

export const BEST_KEY = 'antwars.bestRound.v1';

/** The browser's localStorage, or null when the browser refuses access. */
export function browserStore(): KeyValueStore | null {
  try {
    return typeof window !== 'undefined' && window.localStorage ? window.localStorage : null;
  } catch {
    return null;
  }
}

/** The saved best round, or null when there is none or it cannot be read. Each ladder passes its own key. */
export function readBest(store: KeyValueStore | null, key: string = BEST_KEY): number | null {
  if (!store) return null;
  try {
    const raw = store.getItem(key);
    if (raw === null) return null;
    const n = Number(raw);
    return Number.isInteger(n) && n >= 1 ? n : null;
  } catch {
    return null;
  }
}

export interface RunRecord {
  /** The best round after this run, counting this run even when the save failed. */
  best: number;
  /** True when this run beat the saved best (or there was none). */
  isNew: boolean;
  /** False when the new best could not be written. */
  saved: boolean;
}

/** Records a finished run that reached the given round, under its ladder's key. */
export function recordRun(store: KeyValueStore | null, roundReached: number, key: string = BEST_KEY): RunRecord {
  const previous = readBest(store, key);
  if (previous !== null && previous >= roundReached) return { best: previous, isNew: false, saved: true };
  let saved = false;
  if (store) {
    try {
      store.setItem(key, String(roundReached));
      saved = true;
    } catch {
      saved = false;
    }
  }
  return { best: roundReached, isNew: true, saved };
}
