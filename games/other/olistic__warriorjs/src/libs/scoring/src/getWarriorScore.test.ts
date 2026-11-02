import { expect, test, vi } from 'vitest';

import getLastEvent from './getLastEvent.js';
import getWarriorScore from './getWarriorScore.js';
import { type ScoringEvent } from './types.js';

vi.mock('./getLastEvent.js');

const stubTurns: ScoringEvent[][] = [[{ floorMap: [[]] }]];

test('returns the score of the warrior at the end of the play', () => {
  vi.mocked(getLastEvent).mockReturnValue({ warriorStatus: { score: 42 }, floorMap: [[]] });
  expect(getWarriorScore(stubTurns)).toBe(42);
  expect(getLastEvent).toHaveBeenCalledWith(stubTurns);
});
