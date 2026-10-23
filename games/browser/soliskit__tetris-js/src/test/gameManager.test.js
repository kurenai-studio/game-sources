import { test } from 'node:test';
import assert from 'node:assert/strict';

import { GameManager, createMemoryStorage } from '../public/game/gameManager.js';
import { GameState, PlayerAction } from '../public/game/gameState.js';
import { position } from '../public/game/position.js';
import { TetrominoFactory, PieceColors } from '../public/game/tetrominoFactory.js';
import {
  createFakeScheduler,
  dropVerticalIIntoColumn9,
  fillRows,
  filled,
  filledCells,
  fixedFactory,
  newGame,
  seededRandom,
  sequenceFactory,
  repeatUntil
} from './helpers.js';

const { cyan, yellow, purple, green, red, orange } = PieceColors;

function snapshot(game) {
  return JSON.stringify({
    state: game.state,
    score: game.score,
    current: game.currentTetromino,
    held: game.heldTetromino,
    next: game.nextTetrominos,
    board: game.gameBoard
  });
}

function landOnSurface(game) {
  repeatUntil(() => game.isOnSurface, () => game.softDrop(), 'the piece landing');
}

// Storage whose writes throw for the listed keys (all keys when omitted).
function failingStorage(failingKeys) {
  const storage = createMemoryStorage();
  const setItem = storage.setItem;
  storage.setItem = (key, value) => {
    if (!failingKeys || failingKeys.includes(key)) throw new Error('QuotaExceededError');
    setItem(key, value);
  };
  return storage;
}

// Starting state

test('a new game manager waits at game over with an empty board and three upcoming pieces [STA-1] [PCE-1] [PLY-8]', () => {
  const scheduler = createFakeScheduler();
  const game = new GameManager({ scheduler, storage: createMemoryStorage() });
  assert.equal(game.state, GameState.gameOver);
  assert.equal(game.rows, 20);
  assert.equal(game.columns, 10);
  assert.equal(filledCells(game), 0);
  assert.equal(game.nextTetrominos.length, 3);
  assert.equal(game.heldTetromino, null);
  assert.equal(game.canHoldTetromino, true);
  assert.equal(game.score, 0);
  assert.equal(game.level, 1);
  assert.equal(scheduler.pending, 0, 'no gravity before a game starts');
});

test('without injected storage it falls back to memory when localStorage is missing [SAF-2]', () => {
  assert.equal(typeof globalThis.localStorage, 'undefined');
  const game = new GameManager({ scheduler: createFakeScheduler() });
  game.highScore = 300;
  assert.equal(game.highScore, 300);
});

// State guards

// Each action on its own, so opposite moves cannot cancel out.
const PLAY_ACTIONS = [PlayerAction.moveLeft, PlayerAction.moveRight, PlayerAction.rotate, PlayerAction.hold, PlayerAction.drop, 'softDrop'];
const perform = (game, action) => (action === 'softDrop' ? game.softDrop() : game.handleAction(action));

test('moves, rotations, holds and drops do nothing at game over [STA-1]', () => {
  for (const action of PLAY_ACTIONS) {
    const game = new GameManager({ scheduler: createFakeScheduler(), storage: createMemoryStorage(), factory: fixedFactory(purple) });
    game.currentTetromino.position = position(5, 3); // room to move every way
    const before = snapshot(game);
    perform(game, action);
    assert.equal(snapshot(game), before, action);
  }
});

test('moves, rotations, holds, drops and gravity do nothing while paused [STA-2]', () => {
  for (const action of PLAY_ACTIONS) {
    const { game, scheduler } = newGame({ factory: fixedFactory(purple) });
    game.softDrop();
    game.handleAction(PlayerAction.pause);
    const before = snapshot(game);
    perform(game, action);
    scheduler.advance(10000);
    assert.equal(snapshot(game), before, action);
  }
});

test('new game is ignored while playing [STA-1]', () => {
  const { game } = newGame();
  game.score = 500;
  game.handleAction(PlayerAction.newGame);
  assert.equal(game.score, 500);
});

test('new game after game over resets the board, score, level and held piece [STA-1]', () => {
  const { game } = newGame();
  game.handleAction(PlayerAction.hold);
  game.gameBoard[19][0] = filled();
  game.score = 2500;
  game.state = GameState.gameOver;
  game.handleAction(PlayerAction.newGame);
  assert.equal(game.state, GameState.playing);
  assert.equal(filledCells(game), 0);
  assert.equal(game.score, 0);
  assert.equal(game.level, 1);
  assert.equal(game.heldTetromino, null);
  assert.equal(game.canHoldTetromino, true);
  assert.equal(game.isSessionSaved, false);
});

test('new game while paused asks first, and once confirmed gives up that game and starts afresh, forgetting its save [STA-1]', () => {
  const { game } = newGame({ factory: fixedFactory(cyan) });
  game.handleAction(PlayerAction.hold);
  fillRows(game, [19], [9]);
  dropVerticalIIntoColumn9(game);
  game.togglePause();
  assert.equal(game.isSessionSaved, true);
  game.handleAction(PlayerAction.newGame);
  assert.equal(game.state, GameState.paused, 'it only asks');
  assert.equal(game.isConfirmingNewGame, true);
  assert.equal(game.score, 100);
  assert.equal(game.isSessionSaved, true);
  game.handleAction(PlayerAction.newGame); // confirms
  assert.equal(game.state, GameState.playing);
  assert.equal(game.isConfirmingNewGame, false);
  assert.equal(filledCells(game), 0);
  assert.equal(game.score, 0);
  assert.equal(game.heldTetromino, null);
  assert.equal(game.isSessionSaved, false);
  assert.notEqual(game.gameLoopTask, null, 'gravity runs');
});

test('cancelling the New Game question keeps the paused game, and so does anything else before it is answered [STA-1]', () => {
  let changes = 0;
  const { game } = newGame({ factory: fixedFactory(cyan), onChange: () => { changes += 1; } });
  game.handleAction(PlayerAction.hold);
  game.togglePause();
  game.handleAction(PlayerAction.newGame);
  const before = changes;
  game.cancelNewGame();
  assert.equal(game.isConfirmingNewGame, false);
  assert.equal(changes, before + 1, 'the page hears of it, to close the question');
  assert.equal(game.state, GameState.paused);
  assert.notEqual(game.heldTetromino, null, 'the game is kept');
  game.handleAction(PlayerAction.newGame);
  assert.equal(game.state, GameState.paused, 'the next New Game asks again');
  assert.equal(game.isConfirmingNewGame, true);

  for (const [what, between] of [
    ['an ignored move', game => game.handleAction(PlayerAction.moveLeft)],
    ['a soft drop', game => game.softDrop()],
    ['a continue', game => game.handleAction(PlayerAction.continueGame)]
  ]) {
    const { game } = newGame({ factory: fixedFactory(cyan) });
    game.togglePause();
    game.handleAction(PlayerAction.newGame);
    between(game);
    assert.equal(game.isConfirmingNewGame, false, what);
    game.handleAction(PlayerAction.newGame);
    assert.equal(game.state, GameState.paused, `${what}: the next New Game asks again`);
    assert.equal(game.isConfirmingNewGame, true, what);
  }
  const { game: resumed } = newGame({ factory: fixedFactory(cyan) });
  resumed.togglePause();
  resumed.handleAction(PlayerAction.newGame);
  resumed.togglePause();
  assert.equal(resumed.state, GameState.playing, 'resuming plays on');
  assert.equal(resumed.isConfirmingNewGame, false);
});

test('new game at game over starts at once, without asking [STA-1]', () => {
  const game = new GameManager({ scheduler: createFakeScheduler(), factory: fixedFactory(cyan) });
  assert.equal(game.isConfirmingNewGame, false, 'nothing is asked as the game opens');
  game.handleAction(PlayerAction.newGame);
  assert.equal(game.state, GameState.playing);
  assert.equal(game.isConfirmingNewGame, false);
});

test('the board version counts every change to the locked blocks, and nothing else [DSP-3]', () => {
  const { game, storage } = newGame({ factory: fixedFactory(cyan) });
  const version = () => game.boardVersion;
  const start = version();
  game.handleAction(PlayerAction.moveLeft);
  game.handleAction(PlayerAction.rotate);
  game.softDrop();
  game.handleAction(PlayerAction.hold);
  assert.equal(version(), start, 'moving, turning, dropping and holding change no locked blocks');
  game.handleAction(PlayerAction.drop);
  assert.equal(version(), start + 1, 'a lock');
  fillRows(game, [19], [9]);
  dropVerticalIIntoColumn9(game);
  assert.equal(version(), start + 3, 'a lock, then a line clear');
  game.togglePause();
  game.handleAction(PlayerAction.newGame);
  game.handleAction(PlayerAction.newGame);
  assert.equal(version(), start + 4, 'a new game');
  game.togglePause();
  const restored = new GameManager({ scheduler: createFakeScheduler(), storage });
  const before = restored.boardVersion;
  restored.handleAction(PlayerAction.continueGame);
  assert.equal(restored.boardVersion, before + 1, 'continuing a saved game');
});

// Movement

test('moving left and right stops at the walls [PLY-1] [PCE-6]', () => {
  const { game } = newGame({ factory: fixedFactory(yellow) });
  for (let i = 0; i < 10; i++) game.handleAction(PlayerAction.moveLeft);
  assert.equal(game.currentTetromino.position.column, 0);
  for (let i = 0; i < 10; i++) game.handleAction(PlayerAction.moveRight);
  assert.equal(game.currentTetromino.position.column, 8);
});

test('moving is blocked by locked blocks [PLY-1] [PCE-6]', () => {
  const { game } = newGame({ factory: fixedFactory(yellow) });
  game.gameBoard[1][6] = filled();
  game.handleAction(PlayerAction.moveRight);
  assert.equal(game.currentTetromino.position.column, 4);
  game.handleAction(PlayerAction.moveLeft);
  assert.equal(game.currentTetromino.position.column, 3);
});

test('soft drop moves down one row and restarts the gravity timer [PLY-3]', () => {
  const { game, scheduler } = newGame();
  scheduler.advance(600);
  game.softDrop();
  assert.equal(game.currentTetromino.position.row, 1);
  scheduler.advance(600);
  assert.equal(game.currentTetromino.position.row, 1, 'gravity waits a full interval after a soft drop');
  scheduler.advance(100);
  assert.equal(game.currentTetromino.position.row, 2);
});

test('gravity uses the current level speed [PLY-2]', () => {
  const { game, scheduler } = newGame();
  game.score = 10000; // level 11: 0.5s per row
  game.softDrop(); // restarts gravity with the new speed
  scheduler.advance(500);
  assert.equal(game.currentTetromino.position.row, 2);
});

test('the ghost piece shows where the piece would land without moving it [PLY-5]', () => {
  const { game } = newGame({ factory: fixedFactory(yellow) });
  assert.equal(game.ghostTetromino.position.row, 18);
  game.gameBoard[15][4] = filled();
  assert.deepEqual(game.ghostTetromino.position, position(13, 4));
  assert.equal(game.currentTetromino.position.row, 0);
  assert.notEqual(game.ghostTetromino, game.currentTetromino);
});

test('hard drop lands on the stack and brings in the next piece [PLY-4] [PLY-8]', () => {
  const { game } = newGame({ factory: sequenceFactory([yellow, purple]) });
  game.gameBoard[15][4] = filled();
  const next = game.nextTetrominos[0];
  game.handleAction(PlayerAction.drop);
  for (const [row, column] of [[13, 4], [13, 5], [14, 4], [14, 5]]) {
    assert.ok(game.gameBoard[row][column].isFilled, `${row},${column}`);
    assert.equal(game.gameBoard[row][column].color, yellow);
  }
  assert.equal(game.currentTetromino.color, next.color);
  assert.deepEqual(game.currentTetromino.position, position(0, 3));
  assert.equal(game.nextTetrominos.length, 3);
  assert.equal(game.score, 0);
});

// Line clears and scoring

for (const [lines, points] of [[1, 100], [2, 300], [3, 500], [4, 800]]) {
  test(`clearing ${lines} line${lines > 1 ? 's' : ''} at once scores ${points} [SCO-1]`, () => {
    const { game } = newGame({ factory: fixedFactory(cyan) });
    fillRows(game, Array.from({ length: lines }, (_, i) => 19 - i), [9]);
    dropVerticalIIntoColumn9(game);
    assert.equal(game.score, points);
    assert.equal(filledCells(game), 4 - lines, 'only the unused part of the I piece is left');
  });
}

test('rows above a cleared line move down unchanged [SCO-1]', () => {
  const { game } = newGame({ factory: fixedFactory(cyan) });
  game.gameBoard[10][0] = filled(red);
  game.gameBoard[12][3] = filled(green);
  fillRows(game, [19], [9]);
  dropVerticalIIntoColumn9(game);
  assert.equal(game.gameBoard[11][0].color, red);
  assert.equal(game.gameBoard[13][3].color, green);
  assert.ok(!game.gameBoard[10][0].isFilled);
  assert.ok(!game.gameBoard[12][3].isFilled);
  assert.ok(game.gameBoard[0].every(cell => !cell.isFilled), 'a new empty row appears at the top');
  assert.equal(game.gameBoard.length, 20);
});

test('lines that are not next to each other clear together [SCO-1]', () => {
  const { game } = newGame({ factory: fixedFactory(cyan) });
  fillRows(game, [17, 19], [9]);
  fillRows(game, [18], [0, 9]);
  dropVerticalIIntoColumn9(game);
  assert.equal(game.score, 300);
  const bottom = game.gameBoard[19];
  assert.ok(!bottom[0].isFilled, 'the row with a gap dropped to the bottom');
  assert.ok(bottom.slice(1).every(cell => cell.isFilled));
  assert.ok(game.gameBoard[18][9].isFilled, 'top of the I piece dropped two rows');
  assert.equal(filledCells(game), 10);
});

test('the level goes up every 1000 points and speeds up gravity [SCO-2] [PLY-2]', () => {
  const { game } = newGame({ factory: fixedFactory(cyan) });
  game.score = 900;
  fillRows(game, [19], [9]);
  dropVerticalIIntoColumn9(game);
  assert.equal(game.score, 1000);
  assert.equal(game.level, 2);
  assert.ok(Math.abs(game.standardDropInterval - 0.68) < 1e-9);
});

test('the high score is saved when beaten and kept when not [SCO-3]', () => {
  const storage = createMemoryStorage();
  const { game } = newGame({ storage, factory: fixedFactory(cyan) });
  fillRows(game, [19], [9]);
  dropVerticalIIntoColumn9(game);
  assert.equal(storage.getItem('tetris.highScore'), '100');
  assert.equal(new GameManager({ scheduler: createFakeScheduler(), storage }).highScore, 100);

  const best = createMemoryStorage();
  best.setItem('tetris.highScore', '5000');
  const { game: second } = newGame({ storage: best, factory: fixedFactory(cyan) });
  fillRows(second, [19], [9]);
  dropVerticalIIntoColumn9(second);
  assert.equal(second.score, 100);
  assert.equal(second.highScore, 5000);
});

test('a missing or invalid stored high score reads as 0 [SCO-3] [SAF-2]', () => {
  const storage = createMemoryStorage();
  assert.equal(new GameManager({ scheduler: createFakeScheduler(), storage }).highScore, 0);
  storage.setItem('tetris.highScore', 'not a number');
  assert.equal(new GameManager({ scheduler: createFakeScheduler(), storage }).highScore, 0);
});

test('the game stores everything under names of its own [APP-6]', () => {
  const storage = createMemoryStorage();
  const written = new Set();
  const setItem = storage.setItem;
  storage.setItem = (key, value) => { written.add(key); setItem(key, value); };
  const { game } = newGame({ storage, factory: fixedFactory(cyan) });
  fillRows(game, [19], [9]);
  dropVerticalIIntoColumn9(game);
  game.togglePause();
  assert.deepEqual([...written].sort(), ['tetris.highScore', 'tetris.isSessionSaved', 'tetris.savedGameSession']);
});

test('the engine reports every action and timer, so the page draws only then [DSP-3]', () => {
  let changes = 0;
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow), onChange: () => { changes += 1; } });
  assert.equal(changes, 1, 'new game');
  game.handleAction(PlayerAction.moveLeft);
  game.softDrop();
  game.togglePause();
  game.togglePause();
  assert.equal(changes, 5);
  scheduler.advance(700);
  assert.equal(changes, 6, 'gravity');
});

test('checking for a saved game reads storage once, not on every frame [DSP-3]', () => {
  const storage = createMemoryStorage();
  const getItem = storage.getItem;
  let reads = 0;
  storage.getItem = key => {
    if (key === 'tetris.isSessionSaved') reads += 1;
    return getItem(key);
  };
  const game = new GameManager({ scheduler: createFakeScheduler(), storage, factory: fixedFactory(yellow) });
  for (let frame = 0; frame < 60; frame++) assert.equal(game.isSessionSaved, false);
  assert.equal(reads, 1);
  game.handleAction(PlayerAction.newGame);
  game.togglePause();
  for (let frame = 0; frame < 60; frame++) assert.equal(game.isSessionSaved, true);
  assert.equal(reads, 2, 'read again once after the save');
});

test('a game saved in another tab can be continued once storage reports the change [STA-4]', () => {
  const storage = createMemoryStorage();
  const game = new GameManager({ scheduler: createFakeScheduler(), storage });
  assert.equal(game.isSessionSaved, false);
  const otherTab = new GameManager({ scheduler: createFakeScheduler(), storage, factory: fixedFactory(yellow) });
  otherTab.handleAction(PlayerAction.newGame);
  otherTab.togglePause();
  game.storageChanged();
  assert.equal(game.isSessionSaved, true);
  game.handleAction(PlayerAction.continueGame);
  assert.equal(game.state, GameState.paused);
  assert.equal(game.currentTetromino.color, yellow);
});

test('the session is saved after a line clear but not after a plain lock [STA-4]', () => {
  const { game, storage } = newGame({ factory: fixedFactory(cyan) });
  game.handleAction(PlayerAction.drop);
  assert.equal(game.isSessionSaved, false);
  assert.equal(storage.getItem('tetris.savedGameSession'), null);
  fillRows(game, [19], [9]);
  dropVerticalIIntoColumn9(game);
  assert.equal(game.score, 100);
  assert.equal(game.isSessionSaved, true);
  assert.ok(JSON.parse(storage.getItem('tetris.savedGameSession')).gameBoard);
});

// Lock delay

test('a piece brought to rest by gravity locks 0.5s after touching down [PLY-6]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow) });
  repeatUntil(() => game.isOnSurface, () => scheduler.advance(700), 'the piece landing by gravity');
  assert.notEqual(game.lockDelayTask, null, 'the lock delay starts on touchdown');
  scheduler.advance(499);
  assert.equal(filledCells(game), 0);
  scheduler.advance(1);
  assert.equal(filledCells(game), 4);
});

test('moving off a ledge cancels the lock delay and the piece keeps falling [PLY-6]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow) });
  game.gameBoard[10][5] = filled();
  landOnSurface(game);
  game.softDrop(); // lands on the ledge
  assert.notEqual(game.lockDelayTask, null);
  game.handleAction(PlayerAction.moveLeft);
  assert.equal(game.lockDelayTask, null);
  assert.equal(game.isOnSurface, false);
  scheduler.advance(700);
  assert.equal(game.currentTetromino.position.row, 9);
});

test('reaching a new lowest row resets the lock delay move count [PLY-6]', () => {
  const { game } = newGame({ factory: fixedFactory(yellow) });
  game.gameBoard[10][5] = filled();
  landOnSurface(game);
  game.softDrop();
  game.handleAction(PlayerAction.moveLeft); // off the ledge counts as a reset
  assert.equal(game.lockDelayResetCount, 1);
  game.softDrop();
  assert.equal(game.lockDelayResetCount, 0);
});

test('the counterclockwise action turns the piece the other way [PCE-4] [INP-1]', () => {
  const { game } = newGame({ factory: fixedFactory(purple) });
  game.handleAction(PlayerAction.rotateCounterclockwise);
  assert.equal(game.currentTetromino.rotationState, 3);
  game.handleAction(PlayerAction.rotate);
  assert.equal(game.currentTetromino.rotationState, 0);
});

test('turning counterclockwise on the surface restarts the lock delay too [PLY-6]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(purple) });
  landOnSurface(game);
  scheduler.advance(400);
  game.handleAction(PlayerAction.rotateCounterclockwise);
  assert.equal(game.currentTetromino.rotationState, 3);
  assert.equal(game.lockDelayResetCount, 1);
  scheduler.advance(400);
  assert.equal(filledCells(game), 0);
  scheduler.advance(100);
  assert.equal(filledCells(game), 4);
});

test('rotating on the surface restarts the lock delay [PLY-6]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(purple) });
  landOnSurface(game);
  game.softDrop();
  scheduler.advance(400);
  game.handleAction(PlayerAction.rotate); // kicks up one row to fit
  assert.equal(game.currentTetromino.rotationState, 1);
  assert.equal(game.lockDelayResetCount, 1);
  scheduler.advance(400);
  assert.equal(filledCells(game), 0, 'still unlocked 0.8s after landing');
  scheduler.advance(100);
  assert.equal(filledCells(game), 4);
});

test('once the 15 resets are used up, landing locks immediately [PLY-6]', () => {
  const { game } = newGame({ factory: fixedFactory(yellow) });
  repeatUntil(() => game.currentTetromino.position.row === 17, () => game.softDrop(), 'the piece one row above the floor');
  game.lockDelayResetCount = 15;
  game.lowestRowReached = 18; // as if a turn had lifted it off the floor
  game.softDrop();
  assert.equal(filledCells(game), 4);
  assert.equal(game.lockDelayTask, null);
  assert.equal(game.currentTetromino.position.row, 0);
});

test('moving onto a ledge starts the lock delay at once, without using a reset [PLY-6]', () => {
  const faults = [];
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow), onFault: fault => faults.push(fault) });
  game.gameBoard[7][3] = filled();
  for (let i = 0; i < 5; i++) game.softDrop(); // rows 5 and 6, just above the ledge's row
  assert.equal(game.lockDelayTask, null);
  game.handleAction(PlayerAction.moveLeft);
  assert.notEqual(game.lockDelayTask, null);
  assert.equal(game.lockDelayResetCount, 0);
  scheduler.advance(499);
  assert.equal(filledCells(game), 1);
  scheduler.advance(1);
  assert.equal(filledCells(game), 5);
  assert.deepEqual(faults, []);
});

test('turning onto a ledge starts the lock delay at once [PLY-6]', () => {
  const faults = [];
  const { game, scheduler } = newGame({ factory: fixedFactory(purple), onFault: fault => faults.push(fault) });
  game.gameBoard[8][4] = filled();
  for (let i = 0; i < 5; i++) game.softDrop();
  assert.equal(game.lockDelayTask, null);
  game.handleAction(PlayerAction.rotate); // the stem now points down at the ledge
  assert.equal(game.currentTetromino.rotationState, 1);
  assert.equal(game.isOnSurface, true);
  assert.notEqual(game.lockDelayTask, null);
  scheduler.advance(500);
  assert.equal(filledCells(game), 5);
  assert.deepEqual(faults, []);
});

test('a new piece that appears resting on the stack starts its lock delay at once [PLY-6]', () => {
  const faults = [];
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow), onFault: fault => faults.push(fault) });
  for (let i = 0; i < 4; i++) game.handleAction(PlayerAction.moveLeft);
  game.gameBoard[2][4] = filled(); // under where the next piece appears
  game.handleAction(PlayerAction.drop);
  assert.equal(game.currentTetromino.position.row, 0);
  assert.notEqual(game.lockDelayTask, null);
  scheduler.advance(499);
  assert.equal(filledCells(game), 5);
  scheduler.advance(1);
  assert.equal(filledCells(game), 9);
  assert.deepEqual(faults, []);
});

test('a held piece swapped in resting on the stack starts its lock delay at once [PLY-6] [PLY-7]', () => {
  const faults = [];
  const { game, scheduler } = newGame({ factory: sequenceFactory([purple, yellow, green]), onFault: fault => faults.push(fault) });
  game.handleAction(PlayerAction.hold); // holds T, plays O
  for (let i = 0; i < 4; i++) game.handleAction(PlayerAction.moveLeft);
  game.handleAction(PlayerAction.drop); // O locks, plays S
  game.gameBoard[2][4] = filled(); // under where the T appears
  game.handleAction(PlayerAction.hold);
  assert.equal(game.currentTetromino.color, purple);
  assert.notEqual(game.lockDelayTask, null);
  scheduler.advance(500);
  assert.equal(filledCells(game), 9);
  assert.deepEqual(faults, []);
});

// Hold

test('the first hold stores the piece at its spawn state and brings in the next one [PLY-7]', () => {
  const { game } = newGame({ factory: sequenceFactory([purple, yellow, green, red, orange]) });
  game.handleAction(PlayerAction.rotate);
  game.handleAction(PlayerAction.moveLeft);
  game.softDrop();
  game.handleAction(PlayerAction.hold);
  assert.equal(game.heldTetromino.color, purple);
  assert.equal(game.heldTetromino.rotationState, 0);
  assert.deepEqual(game.heldTetromino.position, position(0, 3));
  assert.equal(game.currentTetromino.color, yellow);
  assert.deepEqual(game.nextTetrominos.map(piece => piece.color), [green, red, orange]);
});

test('hold is available again after the next piece locks, and swaps back [PLY-7]', () => {
  const { game } = newGame({ factory: sequenceFactory([purple, yellow, green, red]) });
  game.handleAction(PlayerAction.hold); // holds T, plays O
  assert.equal(game.canHoldTetromino, false);
  game.handleAction(PlayerAction.drop); // O locks, plays S
  assert.equal(game.canHoldTetromino, true);
  game.handleAction(PlayerAction.hold);
  assert.equal(game.heldTetromino.color, green);
  assert.equal(game.currentTetromino.color, purple);
  assert.deepEqual(game.currentTetromino.position, position(0, 3));
});

test('holding when the held piece has no room to spawn ends the game [PLY-7] [STA-3]', () => {
  const { game, scheduler } = newGame({ factory: sequenceFactory([purple, yellow, green]) });
  game.handleAction(PlayerAction.hold);
  game.handleAction(PlayerAction.drop);
  fillRows(game, [1], [0, 1, 2, 6, 7, 8, 9]); // blocks where the held T would appear
  game.handleAction(PlayerAction.hold);
  assert.equal(game.state, GameState.gameOver);
  assert.equal(game.isSessionSaved, false);
  assert.equal(scheduler.pending, 0, 'gravity and lock delay stopped');
});

// Pause and continue

test('pause freezes gravity until resumed [STA-2]', () => {
  const { game, scheduler } = newGame();
  game.togglePause();
  assert.equal(game.state, GameState.paused);
  scheduler.advance(5000);
  assert.equal(game.currentTetromino.position.row, 0);
  game.togglePause();
  assert.equal(game.state, GameState.playing);
  scheduler.advance(700);
  assert.equal(game.currentTetromino.position.row, 1);
});

test('pausing during the lock delay cancels it and counts as a reset, and resuming starts it again [STA-2] [PLY-6]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow) });
  landOnSurface(game);
  game.togglePause();
  assert.equal(game.lockDelayTask, null);
  assert.equal(game.lockDelayResetCount, 1);
  scheduler.advance(5000);
  assert.equal(filledCells(game), 0);
  game.togglePause();
  assert.notEqual(game.lockDelayTask, null);
  scheduler.advance(499);
  assert.equal(filledCells(game), 0);
  scheduler.advance(1);
  assert.equal(filledCells(game), 4);
});

test('resuming a resting piece whose resets are used up locks it at once [STA-2] [PLY-6]', () => {
  const { game } = newGame({ factory: fixedFactory(yellow) });
  landOnSurface(game);
  game.lockDelayResetCount = 15;
  game.togglePause();
  game.togglePause();
  assert.equal(filledCells(game), 4);
  assert.equal(game.state, GameState.playing);
  assert.notEqual(game.gameLoopTask, null, 'the next piece falls');
});

test('resuming into a lock that ends the game leaves no timers running [STA-2] [STA-3] [SAF-4]', () => {
  const faults = [];
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow), onFault: fault => faults.push(fault) });
  game.togglePause();
  fillRows(game, [...Array(18).keys()].map(row => row + 2), [0]); // the piece rests at the top
  game.lockDelayResetCount = 15;
  game.togglePause();
  assert.equal(game.state, GameState.gameOver);
  assert.equal(scheduler.pending, 0);
  assert.deepEqual(faults, []);
});

test('toggling pause does nothing at game over [STA-2]', () => {
  const game = new GameManager({ scheduler: createFakeScheduler(), storage: createMemoryStorage() });
  game.togglePause();
  assert.equal(game.state, GameState.gameOver);
});

test('continue restores the board, score, level and every piece [STA-4]', () => {
  const storage = createMemoryStorage();
  const { game } = newGame({ storage, factory: sequenceFactory([purple, yellow, green, red, orange, cyan]) });
  game.handleAction(PlayerAction.hold);
  game.handleAction(PlayerAction.moveLeft);
  game.gameBoard[19][2] = filled(red);
  game.score = 1200; // level 2
  game.handleAction(PlayerAction.pause);

  const restored = new GameManager({ scheduler: createFakeScheduler(), storage });
  restored.handleAction(PlayerAction.continueGame);
  assert.equal(restored.state, GameState.paused);
  assert.equal(restored.score, 1200);
  assert.equal(restored.level, 2);
  assert.equal(restored.gameBoard[19][2].color, red);
  assert.deepEqual(restored.currentTetromino, game.currentTetromino);
  assert.deepEqual(restored.heldTetromino, game.heldTetromino);
  assert.deepEqual(restored.nextTetrominos.map(piece => piece.color), game.nextTetrominos.map(piece => piece.color));
  assert.equal(restored.canHoldTetromino, false);
});

test('every game starts with a full bag, so its first seven pieces are all different [PCE-5] [STA-1]', () => {
  for (let seed = 1; seed <= 20; seed++) {
    const { game } = newGame({ factory: new TetrominoFactory(seededRandom(seed)) });
    for (let round = 1; round <= 2; round++) {
      const colors = [game.currentTetromino.color];
      for (let i = 0; i < 6; i++) {
        game.handleAction(PlayerAction.drop);
        colors.push(game.currentTetromino.color);
      }
      assert.equal(new Set(colors).size, 7, `seed ${seed}, game ${round}`);
      repeatUntil(() => game.state === GameState.gameOver, () => game.handleAction(PlayerAction.drop), 'the game ending');
      game.handleAction(PlayerAction.newGame);
    }
  }
});

test('continue carries on with the saved bag, so each piece still comes once per seven [PCE-5] [STA-4]', () => {
  const storage = createMemoryStorage();
  const { game } = newGame({ storage, factory: new TetrominoFactory(seededRandom(5)) });
  game.handleAction(PlayerAction.drop);
  game.handleAction(PlayerAction.pause);
  const saved = game.factory.bag.map(piece => piece.color);
  assert.equal(saved.length, 2);

  const restored = new GameManager({ scheduler: createFakeScheduler(), storage, factory: new TetrominoFactory(seededRandom(99)) });
  restored.handleAction(PlayerAction.continueGame);
  restored.togglePause();
  for (const color of saved) {
    restored.handleAction(PlayerAction.drop);
    assert.equal(restored.nextTetrominos.at(-1).color, color);
  }
});

test('Continue refuses a save without a bag and leaves the current bag alone [PCE-5] [STA-6]', () => {
  const storage = createMemoryStorage();
  const { game } = newGame({ storage, factory: new TetrominoFactory(seededRandom(5)) });
  game.handleAction(PlayerAction.pause);
  const data = JSON.parse(storage.getItem('tetris.savedGameSession'));
  delete data.bag;
  storage.setItem('tetris.savedGameSession', JSON.stringify(data));

  // Its constructor has already dealt from this bag.
  const restored = new GameManager({ scheduler: createFakeScheduler(), storage, factory: new TetrominoFactory(seededRandom(6)) });
  const bag = [...restored.factory.bag];
  restored.handleAction(PlayerAction.continueGame);
  assert.equal(restored.state, GameState.gameOver);
  assert.equal(restored.isSessionSaved, false);
  assert.deepEqual(restored.factory.bag, bag);
});

test('continue without a saved game stays at game over [STA-4]', () => {
  const game = new GameManager({ scheduler: createFakeScheduler(), storage: createMemoryStorage() });
  game.handleAction(PlayerAction.continueGame);
  assert.equal(game.state, GameState.gameOver);
  assert.equal(game.isSessionSaved, false);
});

test('continue with a corrupted save stays at game over and forgets it [STA-4] [SAF-1]', () => {
  const storage = createMemoryStorage();
  storage.setItem('tetris.isSessionSaved', 'true');
  storage.setItem('tetris.savedGameSession', '{not json');
  const game = new GameManager({ scheduler: createFakeScheduler(), storage });
  game.handleAction(PlayerAction.continueGame);
  assert.equal(game.state, GameState.gameOver);
  assert.equal(game.isSessionSaved, false);
});

test('continue is ignored while a game is running [STA-4]', () => {
  const { game } = newGame();
  game.handleAction(PlayerAction.moveLeft);
  const before = snapshot(game);
  game.handleAction(PlayerAction.continueGame);
  assert.equal(snapshot(game), before);
});

// Game over

test('topping out stops all timers [STA-3]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow) });
  repeatUntil(() => game.state !== GameState.playing, () => game.handleAction(PlayerAction.drop), 'the game ending');
  assert.equal(game.state, GameState.gameOver);
  assert.equal(scheduler.pending, 0);
  const before = snapshot(game);
  scheduler.advance(10000);
  assert.equal(snapshot(game), before);
});

// Storage failures

test('a failing session save does not break pausing [SAF-2]', () => {
  const { game } = newGame({ storage: failingStorage(['tetris.savedGameSession']) });
  game.handleAction(PlayerAction.pause);
  assert.equal(game.state, GameState.paused);
  assert.equal(game.isSessionSaved, false);
});

test('the game keeps working when storage rejects every write [SAF-2]', () => {
  const scheduler = createFakeScheduler();
  const game = new GameManager({ scheduler, storage: failingStorage(), factory: fixedFactory(cyan) });
  game.handleAction(PlayerAction.newGame);
  assert.equal(game.state, GameState.playing);
  fillRows(game, [19], [9]);
  dropVerticalIIntoColumn9(game);
  assert.equal(game.score, 100);
  game.togglePause();
  game.togglePause();
  scheduler.advance(700);
  assert.equal(game.state, GameState.playing);
});

test('memory storage keeps values as strings [SAF-2]', () => {
  const storage = createMemoryStorage();
  assert.equal(storage.getItem('missing'), null);
  storage.setItem('n', 42);
  assert.equal(storage.getItem('n'), '42');
  storage.removeItem('n');
  assert.equal(storage.getItem('n'), null);
});

// Random play

test('in 200 random games the rules always hold [SAF-6] [PCE-6] [SAF-4]', () => {
  const random = seededRandom(2024);
  const actions = [PlayerAction.moveLeft, PlayerAction.moveRight, PlayerAction.rotate, PlayerAction.hold];
  const validGains = new Set([0, 100, 300, 500, 800]);
  let gamesOver = 0;
  for (let round = 0; round < 200; round++) {
    const { game, scheduler } = newGame({ factory: new TetrominoFactory(random) });
    for (let step = 0; step < 2000 && game.state !== GameState.gameOver; step++) {
      const before = game.score;
      const roll = random();
      if (roll < 0.5) game.handleAction(actions[Math.floor(random() * actions.length)]);
      else if (roll < 0.53) game.handleAction(PlayerAction.drop);
      else if (roll < 0.6) game.softDrop();
      else if (roll < 0.61) { game.togglePause(); game.togglePause(); }
      else scheduler.advance(Math.floor(random() * 400));

      assert.ok(validGains.has(game.score - before), `score went from ${before} to ${game.score}`);
      assert.equal(game.level, Math.floor(game.score / 1000) + 1);
      assert.equal(game.gameBoard.length, 20);
      assert.ok(game.gameBoard.every(row => row.length === 10));
      assert.equal(game.nextTetrominos.length, 3);
      if (game.state === GameState.playing) {
        assert.ok(game.currentTetromino.fits(game.gameBoard), `round ${round} step ${step}: piece overlaps`);
        assert.ok(game.ghostTetromino.fits(game.gameBoard));
        assert.ok(game.ghostTetromino.position.row >= game.currentTetromino.position.row);
      }
    }
    if (game.state === GameState.gameOver) gamesOver++;
    assert.deepEqual(game.faults, [], `round ${round}: the invariant monitor never fires in legal play`);
  }
  assert.ok(gamesOver > 100, `most games played to the end (${gamesOver} of 200)`);
});

// Found by mutation testing: each test below catches a wrong change that
// the tests above let through.

test('saves use the storage keys of earlier versions, so saves on devices keep working [STA-4] [SCO-3]', () => {
  const { game, storage } = newGame({ factory: fixedFactory(cyan) });
  fillRows(game, [19], [9]);
  dropVerticalIIntoColumn9(game);
  assert.equal(storage.getItem('tetris.highScore'), '100');
  assert.equal(storage.getItem('tetris.isSessionSaved'), 'true');
  assert.ok(storage.getItem('tetris.savedGameSession'));
});

test('by default gravity runs on the browser timers, and a soft drop replaces the pending tick [PLY-2] [PLY-3]', t => {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  const game = new GameManager({ storage: createMemoryStorage() });
  game.handleAction(PlayerAction.newGame);
  t.mock.timers.tick(600);
  game.softDrop();
  t.mock.timers.tick(100); // the old tick would have been due now
  assert.equal(game.currentTetromino.position.row, 1);
  t.mock.timers.tick(600);
  assert.equal(game.currentTetromino.position.row, 2);
});

test('a new game starts with a fresh lock delay, whatever the last game left behind [PLY-6] [STA-1]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow) });
  game.lockDelayResetCount = 15;
  game.lowestRowReached = 19;
  game.state = GameState.gameOver;
  game.stopGameLoop();
  game.handleAction(PlayerAction.newGame);
  landOnSurface(game);
  game.softDrop();
  assert.equal(filledCells(game), 0, 'waits instead of locking at once');
  scheduler.advance(500);
  assert.equal(filledCells(game), 4);
});

test('continuing a saved game starts with a fresh lock delay [PLY-6] [STA-4]', () => {
  const storage = createMemoryStorage();
  newGame({ storage, factory: fixedFactory(yellow) }).game.togglePause();
  const scheduler = createFakeScheduler();
  const game = new GameManager({ scheduler, storage, factory: fixedFactory(yellow) });
  game.lockDelayResetCount = 15;
  game.lowestRowReached = 19;
  game.handleAction(PlayerAction.continueGame);
  game.togglePause();
  landOnSurface(game);
  game.softDrop();
  assert.equal(filledCells(game), 0, 'waits instead of locking at once');
  scheduler.advance(500);
  assert.equal(filledCells(game), 4);
});

test('if a save fails after an earlier one worked, the old save is no longer offered [STA-4] [SAF-2]', () => {
  const storage = createMemoryStorage();
  const setItem = storage.setItem;
  let savesFail = false;
  storage.setItem = (key, value) => {
    if (savesFail && key === 'tetris.savedGameSession') throw new Error('QuotaExceededError');
    setItem(key, value);
  };
  const { game } = newGame({ storage });
  game.togglePause();
  assert.equal(game.isSessionSaved, true);
  game.togglePause();
  savesFail = true;
  game.togglePause();
  assert.equal(game.isSessionSaved, false);
});

test('a soft drop that ends the game leaves no timers running [STA-3] [SAF-4]', () => {
  const faults = [];
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow), onFault: fault => faults.push(fault) });
  fillRows(game, [...Array(18).keys()].map(row => row + 2), [0]);
  game.lockDelayResetCount = 15; // the landing locks at once
  game.softDrop();
  assert.equal(game.state, GameState.gameOver);
  assert.equal(scheduler.pending, 0);
  assert.deepEqual(faults, []);
});

test('after a piece locks, the next piece waits a full gravity interval before falling [PLY-2] [PLY-6]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow) });
  repeatUntil(() => game.isOnSurface, () => scheduler.advance(700), 'the piece landing by gravity');
  scheduler.advance(500); // locks; the next piece appears
  assert.equal(filledCells(game), 4);
  assert.equal(game.currentTetromino.position.row, 0);
  scheduler.advance(699);
  assert.equal(game.currentTetromino.position.row, 0);
  scheduler.advance(1);
  assert.equal(game.currentTetromino.position.row, 1);
});

test('a hard drop gives the next piece a full gravity interval [PLY-2] [PLY-4]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow) });
  scheduler.advance(600);
  game.handleAction(PlayerAction.drop);
  scheduler.advance(699);
  assert.equal(game.currentTetromino.position.row, 0);
  scheduler.advance(1);
  assert.equal(game.currentTetromino.position.row, 1);
});

test('moves, rotations and pauses in the air do not use up lock delay resets [PLY-6] [STA-2]', () => {
  const { game } = newGame({ factory: fixedFactory(purple) });
  game.softDrop();
  game.softDrop();
  for (let i = 0; i < 20; i++) game.handleAction([PlayerAction.moveLeft, PlayerAction.moveRight, PlayerAction.rotate][i % 3]);
  game.togglePause();
  game.togglePause();
  assert.equal(game.lockDelayResetCount, 0);
});

test('the 16th move on the surface does not extend the lock delay [PLY-6]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow) });
  landOnSurface(game);
  game.softDrop();
  for (let i = 0; i < 15; i++) {
    scheduler.advance(400);
    game.handleAction(i % 2 === 0 ? PlayerAction.moveLeft : PlayerAction.moveRight);
  }
  assert.equal(game.lockDelayResetCount, 15);
  scheduler.advance(400);
  game.handleAction(PlayerAction.moveLeft); // 16th
  scheduler.advance(100);
  assert.equal(filledCells(game), 4, 'locked 0.5s after the 15th reset');
});

test('pressing rotate when the piece cannot turn does not extend the lock delay [PLY-6]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow) });
  landOnSurface(game);
  game.softDrop();
  scheduler.advance(400);
  game.handleAction(PlayerAction.rotate); // the O piece never turns
  assert.equal(game.lockDelayResetCount, 0);
  scheduler.advance(100);
  assert.equal(filledCells(game), 4);
});

test('a rotation that kicks the piece down to a new lowest row resets the lock delay count [PLY-6]', () => {
  const { game } = newGame({ factory: fixedFactory(purple) });
  for (const [row, column] of [[15, 8], [18, 8], [15, 2], [15, 4], [17, 5]]) game.gameBoard[row][column] = filled();
  game.currentTetromino.position = position(15, 4);
  game.lowestRowReached = 15;
  game.softDrop(); // resting: the lock delay starts
  assert.notEqual(game.lockDelayTask, null);
  game.lockDelayResetCount = 5;
  game.handleAction(PlayerAction.rotate);
  assert.equal(game.currentTetromino.position.row, 17, 'kicked two rows down');
  assert.ok(game.lockDelayResetCount <= 1, `count was ${game.lockDelayResetCount}`);
});

test('a line clear that ends the game does not leave a save to continue [STA-3] [STA-4]', () => {
  const { game } = newGame({ factory: fixedFactory(cyan) });
  fillRows(game, [19], [9]);
  for (const row of [0, 1]) for (const column of [3, 4, 5, 6]) game.gameBoard[row][column] = filled();
  game.currentTetromino.rotationState = 1;
  game.currentTetromino.position = position(2, 7); // vertical in column 9
  game.handleAction(PlayerAction.drop);
  assert.equal(game.score, 100);
  assert.equal(game.state, GameState.gameOver);
  assert.equal(game.isSessionSaved, false);
});

test('continue is ignored during a game even when a save exists [STA-4]', () => {
  const { game } = newGame();
  game.togglePause();
  game.togglePause();
  game.handleAction(PlayerAction.moveLeft);
  const before = snapshot(game);
  game.handleAction(PlayerAction.continueGame);
  assert.equal(snapshot(game), before);
});

test('a piece swapped in from hold starts with a fresh lock delay [PLY-6] [PLY-7]', () => {
  const { game, scheduler } = newGame({ factory: fixedFactory(yellow) });
  game.handleAction(PlayerAction.hold);
  game.handleAction(PlayerAction.drop); // hold is available again
  landOnSurface(game);
  game.lockDelayResetCount = 15;
  game.lowestRowReached = 19;
  game.handleAction(PlayerAction.hold); // the held piece comes in at the top
  landOnSurface(game);
  game.softDrop();
  assert.equal(filledCells(game), 4, 'only the first piece is locked');
  scheduler.advance(500);
  assert.equal(filledCells(game), 8);
});

test('a first hold that brings in a piece with no room ends the game with no timers [STA-3] [PLY-7]', () => {
  const faults = [];
  const { game, scheduler } = newGame({ factory: sequenceFactory([purple, yellow]), onFault: fault => faults.push(fault) });
  for (let i = 0; i < 5; i++) game.softDrop();
  game.gameBoard[0][4] = filled(); // where the next piece appears
  game.handleAction(PlayerAction.hold);
  assert.equal(game.state, GameState.gameOver);
  assert.equal(scheduler.pending, 0);
  assert.deepEqual(faults, []);
});

test('holding during the lock delay when the held piece has no room ends the game with no timers [PLY-6] [PLY-7] [STA-3]', () => {
  const faults = [];
  const { game, scheduler } = newGame({ factory: sequenceFactory([purple, yellow, green]), onFault: fault => faults.push(fault) });
  game.handleAction(PlayerAction.hold);
  game.handleAction(PlayerAction.drop);
  landOnSurface(game);
  game.softDrop(); // starts the lock delay
  assert.notEqual(game.lockDelayTask, null);
  fillRows(game, [1], [0, 1, 2, 6, 7, 8, 9]); // blocks where the held T would appear
  game.handleAction(PlayerAction.hold);
  assert.equal(game.state, GameState.gameOver);
  assert.equal(scheduler.pending, 0);
  assert.deepEqual(faults, []);
});
