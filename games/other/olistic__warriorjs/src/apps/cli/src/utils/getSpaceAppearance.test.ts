import { describe, expect, test } from 'vitest';

import getSpaceAppearance from './getSpaceAppearance.js';

describe('getSpaceAppearance', () => {
  const grid = { totalRows: 3, totalCols: 4 };

  test('returns warrior appearance', () => {
    const result = getSpaceAppearance(
      { unit: { name: 'Warrior', maxHealth: 20, warrior: true } },
      1,
      1,
      grid.totalRows,
      grid.totalCols,
    );
    expect(result).toEqual({ character: '@', color: 'cyan' });
  });

  test('returns enemy appearance', () => {
    const result = getSpaceAppearance(
      { unit: { name: 'Sludge', maxHealth: 12 } },
      1,
      1,
      grid.totalRows,
      grid.totalCols,
    );
    expect(result).toEqual({ character: 's', color: 'red' });
  });

  test('returns stairs appearance', () => {
    const result = getSpaceAppearance({ stairs: true }, 1, 2, grid.totalRows, grid.totalCols);
    expect(result).toEqual({ character: '>', color: 'yellow' });
  });

  test('returns empty space appearance', () => {
    const result = getSpaceAppearance({}, 1, 1, grid.totalRows, grid.totalCols);
    expect(result).toEqual({ character: ' ', color: undefined });
  });

  describe('wall characters', () => {
    test('top-left corner', () => {
      const result = getSpaceAppearance({ wall: true }, 0, 0, grid.totalRows, grid.totalCols);
      expect(result).toEqual({ character: '\u2554', color: 'gray' });
    });

    test('top-right corner', () => {
      const result = getSpaceAppearance({ wall: true }, 0, 3, grid.totalRows, grid.totalCols);
      expect(result).toEqual({ character: '\u2557', color: 'gray' });
    });

    test('bottom-left corner', () => {
      const result = getSpaceAppearance({ wall: true }, 2, 0, grid.totalRows, grid.totalCols);
      expect(result).toEqual({ character: '\u255a', color: 'gray' });
    });

    test('bottom-right corner', () => {
      const result = getSpaceAppearance({ wall: true }, 2, 3, grid.totalRows, grid.totalCols);
      expect(result).toEqual({ character: '\u255d', color: 'gray' });
    });

    test('horizontal wall (top edge)', () => {
      const result = getSpaceAppearance({ wall: true }, 0, 1, grid.totalRows, grid.totalCols);
      expect(result).toEqual({ character: '\u2550', color: 'gray' });
    });

    test('horizontal wall (bottom edge)', () => {
      const result = getSpaceAppearance({ wall: true }, 2, 1, grid.totalRows, grid.totalCols);
      expect(result).toEqual({ character: '\u2550', color: 'gray' });
    });

    test('vertical wall (left edge)', () => {
      const result = getSpaceAppearance({ wall: true }, 1, 0, grid.totalRows, grid.totalCols);
      expect(result).toEqual({ character: '\u2551', color: 'gray' });
    });

    test('vertical wall (right edge)', () => {
      const result = getSpaceAppearance({ wall: true }, 1, 3, grid.totalRows, grid.totalCols);
      expect(result).toEqual({ character: '\u2551', color: 'gray' });
    });
  });
});
