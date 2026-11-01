// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for the How to play card's first run rule and its four items (lane G7, M2).
import { describe, expect, it } from 'vitest';
import type { KeyValueStore } from '../sim/best';
import { HOWTO_ITEMS, HOWTO_KEY, readHowToSeen, writeHowToSeen } from './howto';

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

describe('the How to play card shows once', () => {
  it('is not seen on a fresh phone, seen after it is closed, and stays seen on the next read (a reload)', () => {
    const store = memoryStore();
    expect(readHowToSeen(store)).toBe(false);
    expect(writeHowToSeen(store)).toBe(true);
    expect(store.data.get(HOWTO_KEY)).toBe('1');
    expect(readHowToSeen(store)).toBe(true);
  });

  it.each([['0'], [''], ['true'], ['yes'], [' 1']])('a stored %j reads as not seen (only "1" counts)', (raw) => {
    const store = memoryStore();
    store.data.set(HOWTO_KEY, raw);
    expect(readHowToSeen(store)).toBe(false);
  });

  it('no storage, or storage that refuses, reads as not seen and the write says it failed', () => {
    expect(readHowToSeen(null)).toBe(false);
    expect(writeHowToSeen(null)).toBe(false);
    expect(readHowToSeen(throwing)).toBe(false);
    expect(writeHowToSeen(throwing)).toBe(false);
  });

  it('uses its own key, never the mute or the save keys', () => {
    expect(HOWTO_KEY).toBe('antwars.howto.v1');
  });
});

describe('what the card teaches', () => {
  it('names the stick, the shop between rounds, the picks and the nest, in that order', () => {
    expect(HOWTO_ITEMS.map((i) => i.id)).toEqual(['stick', 'shop', 'picks', 'nest']);
    expect(HOWTO_ITEMS[1].line).toContain('Between rounds');
  });

  it('every line is short and holds no dash punctuation', () => {
    for (const i of HOWTO_ITEMS) {
      expect(i.line.length).toBeLessThanOrEqual(100);
      expect(i.line).not.toMatch(/[\u2013\u2014]|--| - /);
      expect(i.title).not.toMatch(/[\u2013\u2014]|--| - /);
    }
  });
});
