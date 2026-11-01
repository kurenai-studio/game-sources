// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Lane G7, M2: the How to play card shows by itself once, on the first title a phone sees; after that only its button
// opens it. The phone remembers that it was seen. Every storage touch is guarded; a missing or odd value reads as not
// seen (the card shows), and storage that refuses never stops the game.
import type { KeyValueStore } from '../sim/best';

export const HOWTO_KEY = 'antwars.howto.v1';

/** True only when the phone remembers the card as seen ("1"); anything else, or storage that refuses, is not seen. */
export function readHowToSeen(store: KeyValueStore | null): boolean {
  if (!store) return false;
  try {
    return store.getItem(HOWTO_KEY) === '1';
  } catch {
    return false;
  }
}

/** Remembers the card as seen; false when there is no storage or it refused (the card may show again next visit). */
export function writeHowToSeen(store: KeyValueStore | null): boolean {
  if (!store) return false;
  try {
    store.setItem(HOWTO_KEY, '1');
    return true;
  } catch {
    return false;
  }
}

/** The four things the card teaches, in order: the stick, the shop between rounds, the picks, the nest. */
export const HOWTO_ITEMS: ReadonlyArray<{ id: 'stick' | 'shop' | 'picks' | 'nest'; title: string; line: string }> = [
  { id: 'stick', title: 'THE STICK', line: 'Drag anywhere on the screen to move. Stand still to shoot at full speed.' },
  { id: 'shop', title: 'THE SHOP', line: 'Between rounds, walk to the nest and buy upgrades before the countdown ends.' },
  { id: 'picks', title: 'THE PICKS', line: 'Each level up offers three powers. Tap the one you want.' },
  { id: 'nest', title: 'THE NEST', line: 'When the ant falls, a Colony run banks its nectar. Spend it in the nest on upgrades that last.' },
];
