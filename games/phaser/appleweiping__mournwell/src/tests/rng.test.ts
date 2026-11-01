import { describe, expect, it } from 'vitest';
import { createReadableSeed, SeededRng } from '@/game/systems/rng';

describe('SeededRng', () => {
  it('replays an identical sequence for the same seed', () => {
    const first = new SeededRng('ASH-BELL-0042');
    const second = new SeededRng('ASH-BELL-0042');
    expect(Array.from({ length: 128 }, () => first.next())).toEqual(
      Array.from({ length: 128 }, () => second.next()),
    );
  });

  it('isolates derived random streams', () => {
    const root = new SeededRng('MOTH-WICK-9090');
    const drops = root.fork('drops');
    const decor = root.fork('decor');
    expect(Array.from({ length: 8 }, () => drops.int(0, 999))).not.toEqual(
      Array.from({ length: 8 }, () => decor.int(0, 999)),
    );
    expect(root.fork('drops').int(0, 999)).toBe(new SeededRng('MOTH-WICK-9090::drops').int(0, 999));
  });

  it('keeps integer values inside inclusive bounds', () => {
    const rng = new SeededRng('BOUNDS');
    const values = Array.from({ length: 10_000 }, () => rng.int(-3, 7));
    expect(Math.min(...values)).toBe(-3);
    expect(Math.max(...values)).toBe(7);
  });

  it('always creates a readable seed with an unsigned four-digit suffix', () => {
    const seeds = Array.from({ length: 1_000 }, () => createReadableSeed());
    expect(
      seeds.every((seed) =>
        /^(ASH|BELL|MOTH|WICK|SILT|VEIL|BONE|HUSH)-(ASH|BELL|MOTH|WICK|SILT|VEIL|BONE|HUSH)-\d{4}$/.test(
          seed,
        ),
      ),
    ).toBe(true);
  });
});
