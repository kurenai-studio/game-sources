import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { loadSave, updateSave } from '@/game/systems/storage';

const values = new Map<string, string>();

beforeEach(() => {
  values.clear();
  vi.stubGlobal('localStorage', {
    getItem: (key: string) => values.get(key) ?? null,
    setItem: (key: string, value: string) => values.set(key, value),
  });
});

afterEach(() => vi.unstubAllGlobals());

describe('save validation', () => {
  it('treats a missing or invalid best time as no record', () => {
    values.set('mournwell.save.v1', JSON.stringify({ version: 1, runs: 3, wins: 1 }));
    expect(loadSave().bestTimeMs).toBeNull();
    values.set('mournwell.save.v1', JSON.stringify({ version: 1, bestTimeMs: -50 }));
    expect(loadSave().bestTimeMs).toBeNull();
  });

  it('preserves a valid zero or positive best time', () => {
    values.set('mournwell.save.v1', JSON.stringify({ version: 1, bestTimeMs: 0 }));
    expect(loadSave().bestTimeMs).toBe(0);
    values.set('mournwell.save.v1', JSON.stringify({ version: 1, bestTimeMs: 91_250 }));
    expect(loadSave().bestTimeMs).toBe(91_250);
  });

  it('round-trips an updated record through the validated schema', () => {
    updateSave({ runs: 2, wins: 1, bestTimeMs: 91_250, wellscript: 14 });
    expect(loadSave()).toMatchObject({ runs: 2, wins: 1, bestTimeMs: 91_250, wellscript: 14 });
  });
});
