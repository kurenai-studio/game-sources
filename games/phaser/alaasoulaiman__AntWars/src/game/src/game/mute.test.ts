// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for the remembered mute switch.
import { describe, expect, it } from 'vitest';
import type { KeyValueStore } from '../sim/best';
import { MUTE_KEY, readMute, writeMute } from './mute';

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

describe('the mute switch', () => {
  it('is sound on until muted, and the mute survives a new read (a reload)', () => {
    const store = memoryStore();
    expect(readMute(store)).toBe(false);
    expect(writeMute(store, true)).toBe(true);
    expect(store.data.get(MUTE_KEY)).toBe('1');
    expect(readMute(store)).toBe(true);
    expect(writeMute(store, false)).toBe(true);
    expect(readMute(store)).toBe(false);
  });
  it.each([['0'], [''], ['true'], ['yes'], ['2']])('a stored %j reads as sound on', (raw) => {
    const store = memoryStore();
    store.data.set(MUTE_KEY, raw);
    expect(readMute(store)).toBe(false);
  });
  it('no storage, or storage that throws, never throws back', () => {
    expect(readMute(null)).toBe(false);
    expect(readMute(throwing)).toBe(false);
    expect(writeMute(null, true)).toBe(false);
    expect(writeMute(throwing, true)).toBe(false);
  });
});
