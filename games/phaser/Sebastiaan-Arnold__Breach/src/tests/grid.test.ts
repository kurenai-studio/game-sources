import { describe, expect, it } from 'vitest';
import { parseLevel, blocksSight } from '../src/core/grid';
import { RANGE_MAP } from '../src/levels/academy/range';

describe('level parsing', () => {
  it('detects door orientation from the surrounding walls', () => {
    const lvl = parseLevel(['#####', '#.D.#', '##D##', '#...#', '#####']);
    expect(lvl.doors).toEqual([
      { tx: 2, ty: 1, orientation: 'v' },
      { tx: 2, ty: 2, orientation: 'h' },
    ]);
  });

  it('parses the Range', () => {
    const lvl = parseLevel(RANGE_MAP);
    expect(RANGE_MAP.every((r) => r.length === lvl.width)).toBe(true);
    expect(lvl.doors.length).toBeGreaterThan(5);
    // Kill house markers sit on dark floor.
    const mover = lvl.markers.find((m) => m.kind === 'mover')!;
    expect(lvl.dark[mover.ty * lvl.width + mover.tx]).toBe(true);
  });
});

describe('floor materials', () => {
  it('water and glass block movement but not sight, and water is lit like the outdoors', () => {
    const lvl = parseLevel(['#####', '#%gD#', '#ggg#', '#####']);
    const t = (x: number, y: number) => lvl.tiles[y * lvl.width + x];
    expect([t(1, 1), t(2, 1)]).toEqual(['water', 'glass']);
    for (const k of [t(1, 1), t(2, 1)]) expect(blocksSight(k)).toBe(false);
    expect(lvl.material[1 * lvl.width + 1]).toBe('water');
    // A door set in glass reads its orientation from the panes either side.
    expect(lvl.doors[0].orientation).toBe('h');
  });

  it('the middle of a block of stacked containers outdoors counts as outdoors', () => {
    const lvl = parseLevel(['#######', '#=====#', '#=TTT=#', '#=TTT=#', '#=TTT=#', '#=====#', '#######']);
    expect(lvl.material[3 * lvl.width + 3]).toBe('concrete');
  });

  it('parses materials and gives doors the indoor floor', () => {
    const lvl = parseLevel(['#####', '#="~#', '##D##', '#...#', '#####']);
    const m = (x: number, y: number) => lvl.material[y * lvl.width + x];
    expect([m(1, 1), m(2, 1), m(3, 1)]).toEqual(['concrete', 'grass', 'tile']);
    expect(m(2, 2)).toBe('wood');
    expect(lvl.tiles[2 * lvl.width + 2]).toBe('floor');
  });
});
