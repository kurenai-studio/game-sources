import { expect, test } from 'vitest';

import getLastEvent from './getLastEvent.js';
import { type ScoringEvent } from './types.js';

const event = (score: number): ScoringEvent => ({
  warriorStatus: { score },
  floorMap: [[{ unit: undefined }]],
});

test('returns the last event of the play', () => {
  const turns = [[event(1)], [event(2)], [event(3), event(4), event(5)]];
  expect(getLastEvent(turns)).toBe(turns[2][2]);
});
