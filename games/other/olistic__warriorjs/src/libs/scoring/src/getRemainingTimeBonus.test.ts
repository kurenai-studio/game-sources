import { expect, test, vi } from 'vitest';

import getRemainingTimeBonus from './getRemainingTimeBonus.js';
import getTurnCount from './getTurnCount.js';
import { type ScoringEvent } from './types.js';

vi.mock('./getTurnCount.js');

const stubTurns: ScoringEvent[][] = [[{ floorMap: [[]] }]];

test('subtracts the number of turns played from the initial time bonus', () => {
  vi.mocked(getTurnCount).mockReturnValue(3);
  expect(getRemainingTimeBonus(stubTurns, 10)).toBe(7);
  expect(getTurnCount).toHaveBeenCalledWith(stubTurns);
});

test("doesn't go below zero", () => {
  vi.mocked(getTurnCount).mockReturnValue(11);
  expect(getRemainingTimeBonus(stubTurns, 10)).toBe(0);
  expect(getTurnCount).toHaveBeenCalledWith(stubTurns);
});
