import { test } from 'node:test';
import assert from 'node:assert/strict';

import { below, position } from '../public/game/position.js';
import { GameState, PlayerAction, cellAt, createBoard } from '../public/game/gameState.js';

test('position creates a row and column pair [PCE-1]', () => {
  assert.deepEqual(position(3, 7), { row: 3, column: 7 });
});

test('below returns a new position one row down without changing the original [PCE-1]', () => {
  const start = position(2, 5);
  const next = below(start);
  assert.deepEqual(next, position(3, 5));
  assert.notEqual(next, start);
  assert.deepEqual(start, position(2, 5));
});

test('createBoard makes rows of empty, independent cells [PCE-1]', () => {
  const board = createBoard(20, 10);
  assert.equal(board.length, 20);
  assert.ok(board.every(row => row.length === 10));
  assert.ok(board.flat().every(cell => cell.isFilled === false && cell.color === null));
  board[0][0].isFilled = true;
  assert.equal(board[0][1].isFilled, false);
  assert.equal(board[1][0].isFilled, false);
});

test('cellAt returns the cell inside the board and undefined outside it [PCE-1]', () => {
  const board = createBoard(20, 10);
  assert.equal(cellAt(board, 0, 0), board[0][0]);
  assert.equal(cellAt(board, 19, 9), board[19][9]);
  for (const [row, column] of [[-1, 0], [0, -1], [20, 0], [0, 10], [25, 25]]) {
    assert.equal(cellAt(board, row, column), undefined, `${row},${column}`);
  }
});

test('game states and player actions are fixed lists [STA-1] [INP-1]', () => {
  assert.deepEqual(Object.values(GameState).sort(), ['gameOver', 'paused', 'playing']);
  assert.deepEqual(
    Object.values(PlayerAction).sort(),
    ['continueGame', 'drop', 'hold', 'moveLeft', 'moveRight', 'newGame', 'pause', 'resume', 'rotate', 'rotateCounterclockwise']
  );
  assert.ok(Object.isFrozen(GameState));
  assert.ok(Object.isFrozen(PlayerAction));
});
