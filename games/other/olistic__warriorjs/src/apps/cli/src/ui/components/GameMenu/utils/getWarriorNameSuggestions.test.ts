import { expect, test, vi } from 'vitest';

import shuffle from '../../../../utils/shuffle.js';
import getWarriorNameSuggestions from './getWarriorNameSuggestions.js';

vi.mock('../../../../utils/shuffle.js', () => ({
  default: vi.fn((arr: unknown[]) => arr),
}));

test('returns shuffled list of warrior names', () => {
  getWarriorNameSuggestions();
  expect(shuffle).toHaveBeenCalledWith(expect.arrayContaining(['Aldric', 'Brenna', 'Cedric']));
});
