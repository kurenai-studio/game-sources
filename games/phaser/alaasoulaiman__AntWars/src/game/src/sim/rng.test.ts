// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The seeded random behind the element chances: pinned rolls, the same seed the same rolls, and a fair one in five.
import { describe, expect, it } from 'vitest';
import { makeRng } from './rng';
import { ELEMENT_CHANCE, elementProc } from './growth';

describe('the seeded random', () => {
  it('seed 1 gives the published mulberry32 rolls', () => {
    const r = makeRng(1);
    const got = [r(), r(), r(), r(), r()].map((x) => +x.toFixed(10));
    expect(got).toEqual([0.6270739406, 0.0027357212, 0.52744704, 0.9810509675, 0.9683778982]);
  });

  it('the same seed rolls the same, another seed differs, every roll in [0, 1)', () => {
    const a = makeRng(99);
    const b = makeRng(99);
    const c = makeRng(100);
    const ra = Array.from({ length: 50 }, () => a());
    const rb = Array.from({ length: 50 }, () => b());
    const rc = Array.from({ length: 50 }, () => c());
    expect(ra).toEqual(rb);
    expect(ra).not.toEqual(rc);
    for (const x of ra) {
      expect(x).toBeGreaterThanOrEqual(0);
      expect(x).toBeLessThan(1);
    }
  });
});

describe('the element chance: one hit (or kill) in five', () => {
  it('is 0.2, and a roll under it procs', () => {
    expect(ELEMENT_CHANCE).toBe(0.2);
    expect(elementProc(0)).toBe(true);
    expect(elementProc(0.1999)).toBe(true);
    expect(elementProc(0.2)).toBe(false);
    expect(elementProc(0.999)).toBe(false);
  });

  it('seed 42 procs on the 5th, 15th and 19th of its first 20 rolls', () => {
    const r = makeRng(42);
    const pattern = Array.from({ length: 20 }, () => (elementProc(r()) ? '1' : '0')).join('');
    expect(pattern).toBe('00001000000000100010');
  });

  it('over 100,000 rolls of seed 7 it procs 20 percent of the time, within half a point', () => {
    const r = makeRng(7);
    let n = 0;
    for (let i = 0; i < 100_000; i++) if (elementProc(r())) n += 1;
    expect(Math.abs(n / 100_000 - 0.2)).toBeLessThan(0.005);
  });
});
