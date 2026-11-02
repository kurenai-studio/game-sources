import { expect, test } from 'vitest';

import shuffle from './shuffle.js';

test('returns a new array', () => {
  const original = [1, 2, 3];
  const result = shuffle(original);
  expect(result).not.toBe(original);
  expect(original).toEqual([1, 2, 3]);
});

test('preserves all elements', () => {
  const original = [1, 2, 3, 4, 5];
  const result = shuffle(original);
  expect(result).toHaveLength(original.length);
  expect(result.sort()).toEqual(original.sort());
});

test('handles empty array', () => {
  expect(shuffle([])).toEqual([]);
});

test('handles single element', () => {
  expect(shuffle([42])).toEqual([42]);
});
