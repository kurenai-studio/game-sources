import { expect, test, vi } from 'vitest';

import getClearBonus from './getClearBonus.js';
import getLastEvent from './getLastEvent.js';
import isFloorClear from './isFloorClear.js';
import { type ScoringEvent } from './types.js';

vi.mock('./getLastEvent.js');
vi.mock('./isFloorClear.js');

const stubTurns: ScoringEvent[][] = [[{ floorMap: [[]] }]];
const stubFloorMap = [[{ unit: undefined }]];

test('returns the 20% of the sum of the warrior score and the time bonus with clear level', () => {
  vi.mocked(getLastEvent).mockReturnValue({ floorMap: stubFloorMap });
  vi.mocked(isFloorClear).mockReturnValue(true);
  expect(getClearBonus(stubTurns, 3, 2)).toBe(1);
  expect(getLastEvent).toHaveBeenCalledWith(stubTurns);
  expect(isFloorClear).toHaveBeenCalledWith(stubFloorMap);
});

test('returns zero if the level is not clear', () => {
  vi.mocked(getLastEvent).mockReturnValue({ floorMap: stubFloorMap });
  vi.mocked(isFloorClear).mockReturnValue(false);
  expect(getClearBonus(stubTurns, 3, 2)).toBe(0);
  expect(getLastEvent).toHaveBeenCalledWith(stubTurns);
  expect(isFloorClear).toHaveBeenCalledWith(stubFloorMap);
});
