import { expect, test } from 'vitest';

import getTurnCount from './getTurnCount.js';
import { type ScoringEvent } from './types.js';

const event: ScoringEvent = { floorMap: [[]] };

test('returns the number of turns played', () => {
  const turns = [[event], [event], [event]];
  expect(getTurnCount(turns)).toBe(3);
});
