import { test } from 'node:test';
import assert from 'node:assert/strict';

import { GameManager, createMemoryStorage } from '../public/game/gameManager.js';
import { GameState, PlayerAction, createBoard } from '../public/game/gameState.js';
import { position } from '../public/game/position.js';
import { TetrominoFactory, PieceColors } from '../public/game/tetrominoFactory.js';
import { createFakeScheduler, fixedFactory, newGame, pieceByColor, repeatUntil } from './helpers.js';

test('7-bag hands out every piece exactly once per bag [PCE-5]', () => {
  const factory = new TetrominoFactory();
  for (let bag = 0; bag < 3; bag++) {
    const colors = new Set(Array.from({ length: 7 }, () => factory.generate().color));
    assert.equal(colors.size, 7);
  }
});

test('rotations are generated clockwise from the spawn shape [PCE-2] [PCE-4]', () => {
  const t = pieceByColor(PieceColors.purple);
  assert.equal(t.rotations.length, 4);
  const toStrings = shape => shape.map(row => row.map(b => (b ? 'X' : '.')).join(''));
  assert.deepEqual(toStrings(t.rotations[1]), ['.X.', '.XX', '.X.']);
  assert.deepEqual(toStrings(t.rotations[2]), ['...', 'XXX', '.X.']);
  assert.equal(pieceByColor(PieceColors.yellow).rotations.length, 1);
});

test('pieces spawn centered [PCE-3]', () => {
  assert.deepEqual(pieceByColor(PieceColors.cyan).spawned(10).position, position(0, 3));
  assert.deepEqual(pieceByColor(PieceColors.yellow).spawned(10).position, position(0, 4));
  assert.deepEqual(pieceByColor(PieceColors.red).spawned(10).position, position(0, 3));
});

test('wall kick lets an I piece rotate against the left wall [PCE-4]', () => {
  const board = createBoard(20, 10);
  const i = pieceByColor(PieceColors.cyan).spawned(10);
  i.rotate(board); // vertical, in column 2 of its box
  i.position = position(5, -2); // flush against the left wall
  i.rotate(board);
  assert.equal(i.rotationState, 2);
  assert.ok(i.cells.every(cell => cell.column >= 0));
});

test('new game starts playing with three upcoming pieces [STA-1] [PLY-8]', () => {
  const { game } = newGame();
  assert.equal(game.state, GameState.playing);
  assert.equal(game.nextTetrominos.length, 3);
  assert.equal(game.score, 0);
  assert.equal(game.level, 1);
});

test('gravity moves the piece down once per drop interval [PLY-2]', () => {
  const { game, scheduler } = newGame();
  const startRow = game.currentTetromino.position.row;
  scheduler.advance(700);
  assert.equal(game.currentTetromino.position.row, startRow + 1);
});

test('hard drop locks the piece at the ghost position [PLY-4] [PLY-5]', () => {
  const { game } = newGame({ factory: fixedFactory(PieceColors.yellow) });
  game.handleAction(PlayerAction.drop);
  assert.ok(game.gameBoard[19][4].isFilled);
  assert.ok(game.gameBoard[18][5].isFilled);
  assert.equal(game.currentTetromino.position.row, 0);
});

test('clearing four lines scores 800 and saves the session [SCO-1] [SCO-3] [STA-4]', () => {
  const { game, storage } = newGame({ factory: fixedFactory(PieceColors.cyan) });
  for (let row = 16; row < 20; row++) {
    for (let column = 0; column < 9; column++) {
      game.gameBoard[row][column] = { isFilled: true, color: '#fff' };
    }
  }
  game.handleAction(PlayerAction.rotate); // vertical I at column 5
  for (let i = 0; i < 4; i++) game.handleAction(PlayerAction.moveRight);
  game.handleAction(PlayerAction.drop);
  assert.equal(game.score, 800);
  assert.equal(game.highScore, 800);
  assert.ok(game.gameBoard.every(row => row.every(cell => !cell.isFilled)));
  assert.equal(game.isSessionSaved, true);
  assert.ok(storage.getItem('tetris.savedGameSession'));
});

test('lock delay waits 0.5s after landing before locking [PLY-6]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(PieceColors.yellow) });
  repeatUntil(() => game.isOnSurface, () => game.softDrop(), 'the piece landing');
  assert.ok(game.lockDelayTask !== null, 'the soft drop that lands it starts the lock delay');
  scheduler.advance(400);
  assert.ok(!game.gameBoard[19][4].isFilled);
  scheduler.advance(100);
  assert.ok(game.gameBoard[19][4].isFilled);
});

test('moving on the surface resets the lock delay, up to 15 times [PLY-6]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(PieceColors.yellow) });
  repeatUntil(() => game.isOnSurface, () => game.softDrop(), 'the piece landing');
  game.softDrop();
  for (let i = 0; i < 15; i++) {
    scheduler.advance(400);
    game.handleAction(i % 2 === 0 ? PlayerAction.moveLeft : PlayerAction.moveRight);
  }
  assert.equal(game.lockDelayResetCount, 15);
  assert.ok(game.gameBoard.every(row => row.every(cell => !cell.isFilled)));
  scheduler.advance(500);
  assert.ok(game.gameBoard[19].some(cell => cell.isFilled));
});

test('hold swaps once per piece [PLY-7]', () => {
  const { game } = newGame();
  const first = game.currentTetromino;
  const upcoming = game.nextTetrominos[0];
  game.handleAction(PlayerAction.hold);
  assert.equal(game.heldTetromino.color, first.color);
  assert.equal(game.currentTetromino.color, upcoming.color);
  assert.equal(game.canHoldTetromino, false);
  game.handleAction(PlayerAction.hold);
  assert.equal(game.heldTetromino.color, first.color);
});

test('pause saves and continue restores the session [STA-4]', () => {
  const scheduler = createFakeScheduler();
  const storage = createMemoryStorage();
  const game = new GameManager({ scheduler, storage });
  game.handleAction(PlayerAction.newGame);
  game.handleAction(PlayerAction.moveLeft);
  game.handleAction(PlayerAction.pause);
  assert.equal(game.state, GameState.paused);
  assert.equal(game.isSessionSaved, true);

  const restored = new GameManager({ scheduler, storage });
  restored.handleAction(PlayerAction.continueGame);
  assert.equal(restored.state, GameState.paused);
  assert.deepEqual(restored.currentTetromino.position, game.currentTetromino.position);
  assert.deepEqual(restored.currentTetromino, game.currentTetromino);
  restored.togglePause();
  assert.equal(restored.state, GameState.playing);
  restored.handleAction(PlayerAction.rotate);
});

test('topping out ends the game and clears the saved session [STA-3]', () => {
  const { game } = newGame({ factory: fixedFactory(PieceColors.yellow) });
  for (let i = 0; i < 20 && game.state === GameState.playing; i++) {
    game.handleAction(PlayerAction.drop);
  }
  assert.equal(game.state, GameState.gameOver);
  assert.equal(game.isSessionSaved, false);
});

test('drop interval speeds up with level and bottoms out at 0.25s [PLY-2] [SCO-2]', () => {
  const game = new GameManager({ scheduler: createFakeScheduler(), storage: createMemoryStorage() });
  assert.equal(game.standardDropInterval, 0.7);
  game.score = 10000; // level 11
  assert.ok(Math.abs(game.standardDropInterval - 0.5) < 1e-9);
  game.score = 99000; // level 100
  assert.equal(game.standardDropInterval, 0.25);
});
