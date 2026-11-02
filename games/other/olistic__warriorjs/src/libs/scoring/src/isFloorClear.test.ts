import { expect, test } from 'vitest';

import isFloorClear from './isFloorClear.js';

test('considers clear when there are no units other than the warrior', () => {
  const floorMap = [
    [{}, {}],
    [{ unit: 'warrior' }, {}],
  ];
  expect(isFloorClear(floorMap)).toBe(true);
});

test("doesn't consider clear when there are other units apart from the warrior", () => {
  const floorMap = [
    [{}, {}],
    [{ unit: 'warrior' }, { unit: 'foo' }],
  ];
  expect(isFloorClear(floorMap)).toBe(false);
});
