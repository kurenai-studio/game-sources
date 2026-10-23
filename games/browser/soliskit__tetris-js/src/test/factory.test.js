import { test } from 'node:test';
import assert from 'node:assert/strict';

import { TetrominoFactory, allPieces, PieceColors } from '../public/game/tetrominoFactory.js';
import { seededRandom } from './helpers.js';

const colorsOf = (factory, count) => Array.from({ length: count }, () => factory.generate().color);

test('there are seven pieces, one per color [PCE-2]', () => {
  const pieces = allPieces();
  assert.equal(pieces.length, 7);
  assert.deepEqual(pieces.map(piece => piece.color).sort(), Object.values(PieceColors).sort());
});

test('7-bag hands out every piece exactly once in each of many bags [PCE-5]', () => {
  const factory = new TetrominoFactory(seededRandom(42));
  for (let bag = 0; bag < 50; bag++) {
    assert.equal(new Set(colorsOf(factory, 7)).size, 7, `bag ${bag}`);
  }
});

test('the same random source gives the same piece order [PCE-5]', () => {
  assert.deepEqual(colorsOf(new TetrominoFactory(seededRandom(7)), 21), colorsOf(new TetrominoFactory(seededRandom(7)), 21));
  assert.notDeepEqual(colorsOf(new TetrominoFactory(seededRandom(7)), 21), colorsOf(new TetrominoFactory(seededRandom(8)), 21));
});

test('the shuffle uses the injected random source [PCE-5]', () => {
  // With random always 0, each Fisher Yates step swaps with index 0.
  const factory = new TetrominoFactory(() => 0);
  const order = allPieces().map(piece => piece.color);
  const expected = order.slice();
  for (let i = expected.length - 1; i > 0; i--) [expected[i], expected[0]] = [expected[0], expected[i]];
  assert.deepEqual(colorsOf(factory, 7), expected);
});

test('every generated piece is a fresh object [PCE-5]', () => {
  const factory = new TetrominoFactory(seededRandom(1));
  const pieces = Array.from({ length: 14 }, () => factory.generate());
  assert.equal(new Set(pieces).size, 14);
  pieces[0].position = { row: 9, column: 9 };
  assert.ok(pieces.slice(1).every(piece => piece.position.row === 0));
});

test('the default factory uses Math.random [PCE-5]', () => {
  const factory = new TetrominoFactory();
  assert.equal(factory.random, Math.random);
  assert.equal(new Set(colorsOf(factory, 7)).size, 7);
});

test('resetting the bag starts a full one, or carries on with the pieces given [PCE-5]', () => {
  const factory = new TetrominoFactory(seededRandom(4));
  colorsOf(factory, 3);
  factory.resetBag();
  assert.equal(new Set(colorsOf(factory, 7)).size, 7, 'a full bag');
  const pieces = allPieces();
  factory.resetBag([pieces[0], pieces[4]]);
  assert.deepEqual(colorsOf(factory, 2), [pieces[0].color, pieces[4].color]);
  assert.equal(new Set(colorsOf(factory, 7)).size, 7, 'then a full bag again');
});

test('the shuffle can leave every piece where it is [PCE-5]', () => {
  // With random just below 1, each step picks its own position.
  const factory = new TetrominoFactory(() => 0.999);
  assert.deepEqual(colorsOf(factory, 7), allPieces().map(piece => piece.color));
});
