import { describe, expect, test } from 'vitest';

import { EAST, NORTH, SOUTH, WEST } from './absoluteDirections.js';
import { getDirectionOfLocation, getDistanceOfLocation, translateLocation } from './location.js';

describe('translateLocation', () => {
  test('translates the given location by the given offset', () => {
    expect(translateLocation([1, 2], [2, -1])).toEqual([3, 1]);
  });
});

describe('getDirectionOfLocation', () => {
  test('returns the direction from a given location to another given location', () => {
    expect(getDirectionOfLocation([1, 1], [1, 2])).toEqual(NORTH);
    expect(getDirectionOfLocation([2, 2], [1, 2])).toEqual(EAST);
    expect(getDirectionOfLocation([1, 3], [1, 2])).toEqual(SOUTH);
    expect(getDirectionOfLocation([0, 2], [1, 2])).toEqual(WEST);
  });
});

describe('getDistanceOfLocation', () => {
  test('returns the distance between the two given locations', () => {
    expect(getDistanceOfLocation([5, 3], [1, 2])).toBe(5);
    expect(getDistanceOfLocation([4, 2], [1, 2])).toBe(3);
  });
});
