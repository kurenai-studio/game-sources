import { renderHook } from '@testing-library/react';
import { STORAGE_KEY } from 'src/utils/storage';

import { useBestScore } from './useBestScore';

function storedBest(mode: 'classic' | 'timed'): number {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (raw === null) {
    return 0;
  }
  return (JSON.parse(raw) as { best: Record<string, number> }).best[mode] ?? 0;
}

describe('useBestScore', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('reports a record on fresh storage', () => {
    const { result } = renderHook(() => useBestScore('classic', 5));

    expect(result.current.record).toBe(true);
    expect(result.current.best).toBe(5);
    expect(storedBest('classic')).toBe(5);
  });

  it('does not report a record for a zero score', () => {
    const { result } = renderHook(() => useBestScore('classic', 0));

    expect(result.current.record).toBe(false);
    expect(result.current.best).toBe(0);
  });

  it('persists a new record', () => {
    const { result } = renderHook(() => useBestScore('classic', 7));

    expect(result.current.record).toBe(true);
    expect(result.current.best).toBe(7);
    expect(storedBest('classic')).toBe(7);
  });

  it('keeps the previous record when the score is lower', () => {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({ best: { classic: 10, timed: 0 }, volume: 0.5 }),
    );

    const { result } = renderHook(() => useBestScore('classic', 4));

    expect(result.current.record).toBe(false);
    expect(result.current.best).toBe(10);
    expect(storedBest('classic')).toBe(10);
  });

  it('does not beat an equal score', () => {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({ best: { classic: 10, timed: 0 }, volume: 0.5 }),
    );

    const { result } = renderHook(() => useBestScore('classic', 10));

    expect(result.current.record).toBe(false);
    expect(result.current.best).toBe(10);
  });

  it('tracks each mode separately', () => {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({ best: { classic: 10, timed: 3 }, volume: 0.5 }),
    );

    const { result } = renderHook(() => useBestScore('timed', 4));

    expect(result.current.record).toBe(true);
    expect(result.current.best).toBe(4);
    expect(storedBest('classic')).toBe(10);
    expect(storedBest('timed')).toBe(4);
  });
});
