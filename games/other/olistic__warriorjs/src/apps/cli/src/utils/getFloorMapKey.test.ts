import { type FloorSpace } from '@warriorjs/core';
import { expect, test } from 'vitest';

import getFloorMapKey from './getFloorMapKey.js';

test('returns the floor map key', () => {
  const map: FloorSpace[][] = [
    [{ wall: true }, { wall: true }, { wall: true }, { wall: true }],
    [
      { wall: true },
      { unit: { name: 'Warrior', maxHealth: 20, warrior: true } },
      { unit: { name: 'Sludge', maxHealth: 12 } },
      { wall: true },
    ],
    [{ wall: true }, { wall: true }, { wall: true }, { wall: true }],
  ];
  expect(getFloorMapKey(map)).toBe('@ = Warrior (20 HP)\ns = Sludge (12 HP)\n> = stairs');
});

test('lists warrior first even when not first on the map', () => {
  const map: FloorSpace[][] = [
    [
      { unit: { name: 'Sludge', maxHealth: 12 } },
      { unit: { name: 'Warrior', maxHealth: 20, warrior: true } },
    ],
  ];
  expect(getFloorMapKey(map)).toBe('@ = Warrior (20 HP)\ns = Sludge (12 HP)\n> = stairs');
});

test('deduplicates units', () => {
  const map: FloorSpace[][] = [
    [{ unit: { name: 'Sludge', maxHealth: 12 } }, {}, { unit: { name: 'Sludge', maxHealth: 12 } }],
  ];
  expect(getFloorMapKey(map)).toBe('s = Sludge (12 HP)\n> = stairs');
});
