import { type FloorSpace } from '@warriorjs/core';
import { expect, test } from 'vitest';

import getFloorMap from './getFloorMap.js';

test('renders floor map from FloorSpace grid', () => {
  const map: FloorSpace[][] = [
    [{ wall: true }, { wall: true }, { wall: true }, { wall: true }],
    [
      { wall: true },
      { unit: { name: 'Warrior', maxHealth: 20, warrior: true } },
      {},
      { wall: true },
    ],
    [{ wall: true }, { wall: true }, { wall: true }, { wall: true }],
  ];
  expect(getFloorMap(map)).toBe(
    '\u2554\u2550\u2550\u2557\n\u2551@ \u2551\n\u255a\u2550\u2550\u255d',
  );
});

test('renders stairs and units', () => {
  const map: FloorSpace[][] = [
    [{ wall: true }, { wall: true }, { wall: true }, { wall: true }, { wall: true }],
    [
      { wall: true },
      { unit: { name: 'Warrior', maxHealth: 20, warrior: true } },
      {},
      { stairs: true },
      { wall: true },
    ],
    [{ wall: true }, { wall: true }, { wall: true }, { wall: true }, { wall: true }],
  ];
  expect(getFloorMap(map)).toBe(
    '\u2554\u2550\u2550\u2550\u2557\n\u2551@ >\u2551\n\u255a\u2550\u2550\u2550\u255d',
  );
});
