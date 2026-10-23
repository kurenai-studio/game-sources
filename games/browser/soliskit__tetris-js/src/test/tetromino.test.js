import { test } from 'node:test';
import assert from 'node:assert/strict';

import { createBoard } from '../public/game/gameState.js';
import { position } from '../public/game/position.js';
import { PieceColors } from '../public/game/tetrominoFactory.js';
import { filled, pieceByColor, shapeStrings } from './helpers.js';

// Standard Super Rotation System states: spawn, clockwise, 180, counterclockwise.
const SRS_SHAPES = {
  cyan: [
    ['....', 'XXXX', '....', '....'],
    ['..X.', '..X.', '..X.', '..X.'],
    ['....', '....', 'XXXX', '....'],
    ['.X..', '.X..', '.X..', '.X..']
  ],
  yellow: [['XX', 'XX']],
  purple: [['.X.', 'XXX', '...'], ['.X.', '.XX', '.X.'], ['...', 'XXX', '.X.'], ['.X.', 'XX.', '.X.']],
  green: [['.XX', 'XX.', '...'], ['.X.', '.XX', '..X'], ['...', '.XX', 'XX.'], ['X..', 'XX.', '.X.']],
  red: [['XX.', '.XX', '...'], ['..X', '.XX', '.X.'], ['...', 'XX.', '.XX'], ['.X.', 'XX.', 'X..']],
  blue: [['X..', 'XXX', '...'], ['.XX', '.X.', '.X.'], ['...', 'XXX', '..X'], ['.X.', '.X.', 'XX.']],
  orange: [['..X', 'XXX', '...'], ['.X.', '.X.', '.XX'], ['...', 'XXX', 'X..'], ['XX.', '.X.', '.X.']]
};

for (const [name, expected] of Object.entries(SRS_SHAPES)) {
  test(`${name} piece has the standard rotation states [PCE-2]`, () => {
    const piece = pieceByColor(PieceColors[name]);
    assert.deepEqual(piece.rotations.map(shapeStrings), expected);
    for (const rotation of piece.rotations) {
      assert.equal(rotation.flat().filter(Boolean).length, 4, 'every rotation has four blocks');
    }
  });
}

test('every piece spawns in its first rotation, centered in the top rows [PCE-3]', () => {
  const expectedColumns = { cyan: 3, yellow: 4, purple: 3, green: 3, red: 3, blue: 3, orange: 3 };
  for (const [name, column] of Object.entries(expectedColumns)) {
    const piece = pieceByColor(PieceColors[name]);
    piece.rotationState = piece.rotations.length - 1;
    piece.position = position(12, 0);
    const spawned = piece.spawned(10);
    assert.equal(spawned.rotationState, 0, name);
    assert.deepEqual(spawned.position, position(0, column), name);
    assert.ok(spawned.cells.every(cell => cell.row <= 1), `${name} starts in the top two rows`);
  }
});

test('copy is an independent piece that shares the rotation data [PCE-2]', () => {
  const original = pieceByColor(PieceColors.purple);
  original.position = position(4, 4);
  const copy = original.copy();
  assert.deepEqual(copy, original);
  copy.position = position(9, 9);
  copy.rotationState = 2;
  assert.deepEqual(original.position, position(4, 4));
  assert.equal(original.rotationState, 0);
  assert.equal(copy.rotations, original.rotations);
  assert.equal(copy.wallKickData, original.wallKickData);
});

test('cells are the board positions of the current rotation [PCE-2]', () => {
  const t = pieceByColor(PieceColors.purple);
  t.position = position(5, 2);
  assert.deepEqual(t.cells, [position(5, 3), position(6, 2), position(6, 3), position(6, 4)]);
  t.rotationState = 1;
  assert.deepEqual(t.cells, [position(5, 3), position(6, 3), position(6, 4), position(7, 3)]);
});

test('fits checks walls, floor, the space above the board and locked blocks [PCE-6] [PCE-1]', () => {
  const board = createBoard(20, 10);
  const o = pieceByColor(PieceColors.yellow);
  assert.ok(o.fits(board, position(0, 0)));
  assert.ok(o.fits(board, position(18, 8)));
  assert.ok(!o.fits(board, position(0, -1)), 'left wall');
  assert.ok(!o.fits(board, position(0, 9)), 'right wall');
  assert.ok(!o.fits(board, position(19, 0)), 'floor');
  assert.ok(!o.fits(board, position(-1, 0)), 'above the board');
  board[10][5] = filled();
  assert.ok(!o.fits(board, position(9, 4)), 'overlaps a locked block');
  assert.ok(o.fits(board, position(8, 4)), 'rests on top of it');
});

test('fits uses the current position by default [PCE-6]', () => {
  const board = createBoard(20, 10);
  const o = pieceByColor(PieceColors.yellow);
  o.position = position(18, 0);
  assert.ok(o.fits(board));
  board[19][1] = filled();
  assert.ok(!o.fits(board));
});

test('drop distance is how many rows the piece falls before it lands [PLY-5]', () => {
  const board = createBoard(20, 10);
  const o = pieceByColor(PieceColors.yellow);
  o.position = position(0, 4);
  assert.equal(o.dropDistance(board), 18);
  board[15][5] = filled();
  assert.equal(o.dropDistance(board), 13);
  o.position = position(13, 4);
  assert.equal(o.dropDistance(board), 0);
  assert.deepEqual(o.position, position(13, 4), 'the piece itself does not move');
});

test('rotating in open space turns clockwise through all four states and back [PCE-4]', () => {
  const board = createBoard(20, 10);
  const t = pieceByColor(PieceColors.purple);
  t.position = position(8, 4);
  for (const expected of [1, 2, 3, 0]) {
    t.rotate(board);
    assert.equal(t.rotationState, expected);
    assert.deepEqual(t.position, position(8, 4), 'no kick needed');
  }
});

test('rotating counterclockwise in open space turns through all four states the other way [PCE-4]', () => {
  const board = createBoard(20, 10);
  const t = pieceByColor(PieceColors.purple);
  t.position = position(8, 4);
  for (const expected of [3, 2, 1, 0]) {
    t.rotate(board, true);
    assert.equal(t.rotationState, expected);
    assert.deepEqual(t.position, position(8, 4), 'no kick needed');
  }
});

test('the O piece never changes when rotated [PCE-4]', () => {
  const board = createBoard(20, 10);
  const o = pieceByColor(PieceColors.yellow);
  o.position = position(8, 4);
  o.rotate(board);
  o.rotate(board, true);
  assert.equal(o.rotationState, 0);
  assert.deepEqual(o.position, position(8, 4));
});

test('a J piece kicks left off the right wall [PCE-4]', () => {
  const board = createBoard(20, 10);
  const j = pieceByColor(PieceColors.blue);
  j.rotationState = 3;
  j.position = position(10, 8); // vertical, flush against the right wall
  assert.ok(j.cells.some(cell => cell.column === 9));
  j.rotate(board);
  assert.equal(j.rotationState, 0);
  assert.deepEqual(j.position, position(10, 7));
  assert.ok(j.fits(board));
});

test('wall kick lets an I piece rotate against the right wall [PCE-4]', () => {
  const board = createBoard(20, 10);
  const i = pieceByColor(PieceColors.cyan);
  i.rotationState = 1;
  i.position = position(5, 7); // vertical in column 9
  i.rotate(board);
  assert.equal(i.rotationState, 2);
  assert.ok(i.fits(board));
  assert.ok(i.cells.every(cell => cell.column <= 9));
});

test('when clockwise is blocked, rotation falls back to counterclockwise [PCE-4]', () => {
  const board = createBoard(20, 10);
  for (const [row, column] of [[9, 4], [12, 4], [12, 5]]) board[row][column] = filled();
  const t = pieceByColor(PieceColors.purple);
  t.position = position(10, 4);
  t.rotate(board);
  assert.equal(t.rotationState, 3);
  assert.deepEqual(t.position, position(10, 5));
  assert.ok(t.fits(board));
});

test('turning counterclockwise, a J piece kicks right off the left wall [PCE-4]', () => {
  const board = createBoard(20, 10);
  const j = pieceByColor(PieceColors.blue);
  j.rotationState = 1;
  j.position = position(10, -1); // vertical, flush against the left wall
  assert.ok(j.cells.some(cell => cell.column === 0) && j.fits(board));
  j.rotate(board, true);
  assert.equal(j.rotationState, 0, 'turned counterclockwise, not clockwise');
  assert.deepEqual(j.position, position(10, 0));
  assert.ok(j.fits(board));
});

test('when counterclockwise is blocked, rotation falls back to clockwise [PCE-4]', () => {
  const board = createBoard(20, 10);
  for (const [row, column] of [[9, 6], [12, 6], [12, 5]]) board[row][column] = filled();
  const t = pieceByColor(PieceColors.purple);
  t.position = position(10, 4);
  t.rotate(board, true);
  assert.equal(t.rotationState, 1);
  assert.deepEqual(t.position, position(10, 3));
  assert.ok(t.fits(board));
});

test('a piece that cannot rotate anywhere stays exactly as it was [PCE-4]', () => {
  const board = createBoard(20, 10);
  for (let row = 0; row < 20; row++) {
    for (let column = 0; column < 10; column++) {
      const isPieceRow = row === 11 && column >= 3 && column <= 6;
      if (!isPieceRow) board[row][column] = filled();
    }
  }
  const i = pieceByColor(PieceColors.cyan);
  i.position = position(10, 3);
  assert.ok(i.fits(board));
  i.rotate(board);
  i.rotate(board, true);
  assert.equal(i.rotationState, 0);
  assert.deepEqual(i.position, position(10, 3));
});

// The standard SRS wall kick tables, as (x, y) offsets with y pointing up,
// for turning clockwise from each state (0 to R, R to 2, 2 to L, L to 0).
const SRS_KICKS_JLSTZ = [
  [[0, 0], [-1, 0], [-1, 1], [0, -2], [-1, -2]],
  [[0, 0], [1, 0], [1, -1], [0, 2], [1, 2]],
  [[0, 0], [1, 0], [1, 1], [0, -2], [1, -2]],
  [[0, 0], [-1, 0], [-1, -1], [0, 2], [-1, 2]]
];
const SRS_KICKS_I = [
  [[0, 0], [-2, 0], [1, 0], [-2, -1], [1, 2]],
  [[0, 0], [-1, 0], [2, 0], [-1, 2], [2, -1]],
  [[0, 0], [2, 0], [-1, 0], [2, 1], [-1, -2]],
  [[0, 0], [1, 0], [-2, 0], [1, -2], [-2, 1]]
];
// The game uses rows that count down the screen, so y flips sign.
const asPositions = table => table.map(kicks => kicks.map(([x, y]) => position(0 - y, x)));

test('wall kicks match the standard SRS tables for every piece [PCE-4]', () => {
  for (const name of ['purple', 'green', 'red', 'blue', 'orange']) {
    assert.deepEqual(pieceByColor(PieceColors[name]).wallKickData, asPositions(SRS_KICKS_JLSTZ), name);
  }
  assert.deepEqual(pieceByColor(PieceColors.cyan).wallKickData, asPositions(SRS_KICKS_I));
  assert.deepEqual(pieceByColor(PieceColors.yellow).wallKickData, [[position(0, 0)]]);
});

test('each piece has its fixed color [PCE-2]', () => {
  assert.deepEqual({ ...PieceColors }, {
    cyan: '#00C0E8', yellow: '#FFCC00', purple: '#AF52DE', green: '#34C759', red: '#FF3B30', blue: '#007AFF', orange: '#FF9500'
  });
  const shapes = { cyan: 'I', yellow: 'O', purple: 'T', green: 'S', red: 'Z', blue: 'J', orange: 'L' };
  for (const [name, letter] of Object.entries(shapes)) {
    assert.deepEqual(shapeStrings(pieceByColor(PieceColors[name]).shape), SRS_SHAPES[name][0], `${letter} is ${name}`);
  }
});

test('the counterclockwise fallback uses the inverted kicks, including their rows [PCE-4]', () => {
  const board = createBoard(20, 10);
  for (const [row, column] of [[12, 5], [13, 6], [9, 4], [12, 4]]) board[row][column] = filled();
  const j = pieceByColor(PieceColors.blue);
  j.position = position(10, 4);
  j.rotate(board);
  assert.equal(j.rotationState, 3);
  assert.deepEqual(j.position, position(9, 5), 'kicked one column right and one row up');
});
