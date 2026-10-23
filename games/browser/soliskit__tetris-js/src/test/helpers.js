// Shared test helpers. node --test also loads this file, which has no tests.
//
// Loops in tests are always bounded: a broken game must make a test fail,
// never hang it.

import assert from 'node:assert/strict';

import { GameManager, createMemoryStorage } from '../public/game/gameManager.js';
import { PlayerAction } from '../public/game/gameState.js';
import { allPieces } from '../public/game/tetrominoFactory.js';

// Manual clock so timer driven behavior (gravity, lock delay) is deterministic.
export function createFakeScheduler() {
  let now = 0;
  let nextHandle = 1;
  const timers = new Map();
  return {
    setTimeout(callback, ms) {
      const handle = nextHandle++;
      timers.set(handle, { callback, at: now + ms });
      return handle;
    },
    clearTimeout(handle) {
      timers.delete(handle);
    },
    advance(ms) {
      const end = now + ms;
      for (let fired = 0; ; fired++) {
        assert.ok(fired < 10000, 'timers keep firing without time passing');
        const due = [...timers.entries()].filter(([, t]) => t.at <= end).sort((a, b) => a[1].at - b[1].at)[0];
        if (!due) break;
        const [handle, timer] = due;
        timers.delete(handle);
        now = timer.at;
        timer.callback();
      }
      now = end;
    },
    get pending() {
      return timers.size;
    }
  };
}

// Calls step until done() is true, failing after limit steps.
export function repeatUntil(done, step, what, limit = 100) {
  for (let i = 0; i < limit; i++) {
    if (done()) return;
    step();
  }
  assert.fail(`${what} did not happen within ${limit} steps`);
}

export function pieceByColor(color) {
  return allPieces().find(piece => piece.color === color);
}

// Factory that always hands out the same piece type.
export function fixedFactory(color) {
  return { generate: () => pieceByColor(color) };
}

// Factory that hands out the given colors in order, then repeats. newGame
// restarts it after the manager's constructor has used some pieces, so the
// sequence starts with the first piece of the new game.
export function sequenceFactory(colors) {
  let index = 0;
  return {
    generate: () => pieceByColor(colors[index++ % colors.length]),
    restart: () => { index = 0; }
  };
}

// Deterministic random numbers in [0, 1).
export function seededRandom(seed) {
  let state = seed;
  return () => {
    state = (state * 1103515245 + 12345) % 2147483648;
    return state / 2147483648;
  };
}

export function newGame(options = {}) {
  const scheduler = options.scheduler ?? createFakeScheduler();
  const storage = options.storage ?? createMemoryStorage();
  const game = new GameManager({ ...options, scheduler, storage });
  options.factory?.restart?.();
  game.handleAction(PlayerAction.newGame);
  return { game, scheduler, storage };
}

export function filled(color = '#fff') {
  return { isFilled: true, color };
}

// Fills the given rows completely except for the listed columns.
export function fillRows(game, rows, exceptColumns = []) {
  for (const row of rows) {
    for (let column = 0; column < game.columns; column++) {
      if (!exceptColumns.includes(column)) game.gameBoard[row][column] = filled();
    }
  }
}

export function filledCells(game) {
  return game.gameBoard.flat().filter(cell => cell.isFilled).length;
}

// Drops the current I piece vertically into column 9. It must have just spawned.
export function dropVerticalIIntoColumn9(game) {
  game.handleAction(PlayerAction.rotate); // vertical, column 5
  for (let i = 0; i < 4; i++) game.handleAction(PlayerAction.moveRight);
  game.handleAction(PlayerAction.drop);
}

// Renders a shape as strings, for readable assertions.
export function shapeStrings(shape) {
  return shape.map(row => row.map(block => (block ? 'X' : '.')).join(''));
}
