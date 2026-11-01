// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The mute switch, remembered on the phone. Every storage touch is guarded; a missing or odd value reads as sound on.
import type { KeyValueStore } from '../sim/best';

export const MUTE_KEY = 'antwars.mute.v1';

/** True only when the phone remembers a mute ("1"); anything else, or storage that refuses, is sound on. */
export function readMute(store: KeyValueStore | null): boolean {
  if (!store) return false;
  try {
    return store.getItem(MUTE_KEY) === '1';
  } catch {
    return false;
  }
}

/** Remembers the switch; false when there is no storage or it refused (the switch still works for this visit). */
export function writeMute(store: KeyValueStore | null, muted: boolean): boolean {
  if (!store) return false;
  try {
    store.setItem(MUTE_KEY, muted ? '1' : '0');
    return true;
  } catch {
    return false;
  }
}
