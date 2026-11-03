import { describe, expect, it } from 'vitest';
import { findPath } from '../src/core/pathfinding';

describe('pathfinding', () => {
  // 0 = open, 1 = wall.
  const grid = [
    '00000',
    '01110',
    '00010',
    '11010',
    '00000',
  ];
  const open = (x: number, y: number) => grid[y]?.[x] === '0';

  it('finds a route around walls', () => {
    const path = findPath(5, 5, { tx: 0, ty: 2 }, { tx: 2, ty: 2 }, open)!;
    expect(path.at(-1)).toEqual({ tx: 2, ty: 2 });
    for (const p of path) expect(open(p.tx, p.ty)).toBe(true);
  });

  it('never cuts a wall corner diagonally', () => {
    const path = findPath(5, 5, { tx: 0, ty: 0 }, { tx: 4, ty: 4 }, open)!;
    let prev = { tx: 0, ty: 0 };
    for (const p of path) {
      if (p.tx !== prev.tx && p.ty !== prev.ty) {
        expect(open(p.tx, prev.ty) && open(prev.tx, p.ty)).toBe(true);
      }
      prev = p;
    }
  });

  it('returns null when the goal is unreachable', () => {
    expect(findPath(5, 5, { tx: 0, ty: 0 }, { tx: 2, ty: 1 }, open)).toBeNull();
  });
});
