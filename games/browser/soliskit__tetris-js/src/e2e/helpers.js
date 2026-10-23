// Shared helpers for the browser tests. The page does not expose the game
// object, so tests read what the player sees: the DOM and the canvas pixels.

import { GameManager, createMemoryStorage } from '../public/game/gameManager.js';
import { PlayerAction } from '../public/game/gameState.js';
import { allPieces } from '../public/game/tetrominoFactory.js';

import { PieceColors } from '../public/game/tetrominoFactory.js';

export { PieceColors };

// Locked blocks in test boards. Saves may only hold real piece colors, and
// no test moves a blue piece, so blue cells are always locked blocks.
export const BOARD_COLOR = PieceColors.blue;

// Builds a saved game in Node with the real engine, for the page to continue.
// board: list of [row, column] cells to fill. piece: color of every piece.
export function savedGame({ piece, board = [], position, rotationState = 0, score = 0 }) {
  const storage = createMemoryStorage();
  const shape = allPieces().find(p => p.color === piece);
  const game = new GameManager({
    storage,
    scheduler: { setTimeout: () => 0, clearTimeout() {} },
    factory: { generate: () => shape.copy() }
  });
  game.handleAction(PlayerAction.newGame);
  for (const [row, column] of board) game.gameBoard[row][column] = { isFilled: true, color: BOARD_COLOR };
  if (position) game.currentTetromino.position = position;
  game.currentTetromino.rotationState = rotationState;
  game.score = score;
  game.handleAction(PlayerAction.pause);
  return {
    'tetris.isSessionSaved': 'true',
    'tetris.savedGameSession': storage.getItem('tetris.savedGameSession'),
    'tetris.highScore': '0'
  };
}

// Rows fully filled except the listed columns, as [row, column] cells.
export function rowsExcept(rows, exceptColumns) {
  const cells = [];
  for (const row of rows) for (let column = 0; column < 10; column++) {
    if (!exceptColumns.includes(column)) cells.push([row, column]);
  }
  return cells;
}

// Opens the game with a saved game in storage and continues it (paused).
export async function continueSavedGame(page, saved) {
  await page.addInitScript(values => {
    if (sessionStorage.getItem('seeded')) return;
    sessionStorage.setItem('seeded', '1');
    for (const [key, value] of Object.entries(values)) localStorage.setItem(key, value);
  }, saved);
  await page.goto('/');
  await page.keyboard.press('KeyC');
  await expectLabel(page, 'Resume');
}

export async function expectLabel(page, label) {
  await page.waitForFunction(text => document.getElementById('playPauseButton').getAttribute('aria-label') === text, label);
}

// The piece color at the center of every board cell, or null when empty.
// Ghost pieces are outlines, so their centers read as empty.
export function boardCells(page) {
  return page.evaluate(() => {
    const canvas = document.getElementById('tetris');
    const context = canvas.getContext('2d');
    const size = canvas.width / 10;
    const data = context.getImageData(0, 0, canvas.width, canvas.height).data;
    const rows = [];
    for (let row = 0; row < 20; row++) {
      const cells = [];
      for (let column = 0; column < 10; column++) {
        const x = Math.floor((column + 0.5) * size);
        const y = Math.floor((row + 0.5) * size);
        const i = (y * canvas.width + x) * 4;
        cells.push(data[i + 3] > 200 ? '#' + [0, 1, 2].map(k => data[i + k].toString(16).padStart(2, '0')).join('').toUpperCase() : null);
      }
      rows.push(cells);
    }
    return rows;
  });
}

// [row, column] of every cell showing the given color.
export async function cellsOf(page, color) {
  const cells = await boardCells(page);
  const result = [];
  cells.forEach((row, r) => row.forEach((value, c) => { if (value === color) result.push([r, c]); }));
  return result;
}

export async function filledCount(page) {
  return (await boardCells(page)).flat().filter(Boolean).length;
}

// Whether a canvas has any opaque pixels drawn on it.
export function canvasHasDrawing(page, id) {
  return page.evaluate(id => {
    const canvas = document.getElementById(id);
    const data = canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height).data;
    for (let i = 3; i < data.length; i += 4) if (data[i] > 200) return true;
    return false;
  }, id);
}

export const isChromium = page => page.context().browser().browserType().name() === 'chromium';

// Finger input on the board, in board cell units. Chromium gets real touch
// events through the DevTools Protocol. Playwright cannot drag a finger in
// WebKit, so there the same gestures use the mouse; the game reads both
// through the same pointer events.
export async function boardTouch(page) {
  const box = await page.locator('#tetris').boundingBox();
  const cell = box.width / 10;
  let last = null;
  const point = (column, row) => ({ x: box.x + cell * column, y: box.y + cell * row });
  let send;
  if (isChromium(page)) {
    const cdp = await page.context().newCDPSession(page);
    send = (type, p) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: p ? [p] : [] });
  } else {
    send = async (type, p) => {
      if (type === 'touchStart') { await page.mouse.move(p.x, p.y); await page.mouse.down(); }
      else if (type === 'touchMove') await page.mouse.move(p.x, p.y);
      else await page.mouse.up();
    };
  }
  return {
    cell,
    async down(column, row) { last = point(column, row); await send('touchStart', last); },
    // Moves in small steps, like a real finger.
    async moveBy(columns, rows, steps = 8) {
      const start = last;
      for (let i = 1; i <= steps; i++) {
        last = { x: start.x + (cell * columns * i) / steps, y: start.y + (cell * rows * i) / steps };
        await send('touchMove', last);
      }
    },
    async up() { await send('touchEnd'); }
  };
}

// Collects page errors and console errors, for asserting a clean run.
export function trackErrors(page) {
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
  return errors;
}

// Replaces the Screen Wake Lock API with a fake the test controls. mode:
// 'grant' grants requests at once, 'refuse' rejects them, 'hold' waits for
// window.grantWakeLocks(), 'missing' removes the API. Like the real one, a
// lock fires 'release' when let go; window.revokeWakeLocks() lets every
// lock go the way the system does when the battery runs low.
export async function fakeWakeLock(page, mode) {
  await page.addInitScript(mode => {
    if (mode === 'missing') {
      delete Navigator.prototype.wakeLock;
      delete navigator.wakeLock;
      return;
    }
    window.wakeLocks = [];
    window.wakeLockRequests = 0;
    const pending = [];
    window.grantWakeLocks = () => pending.splice(0).forEach(grant => grant());
    window.revokeWakeLocks = () => window.wakeLocks.forEach(lock => lock.release());
    const request = type => new Promise((resolve, reject) => {
      window.wakeLockRequests++;
      if (mode === 'refuse') {
        reject(new DOMException('Wake lock refused', 'NotAllowedError'));
        return;
      }
      const sentinel = Object.assign(new EventTarget(), {
        type,
        released: false,
        release() {
          if (!this.released) {
            this.released = true;
            this.dispatchEvent(new Event('release'));
          }
          return Promise.resolve();
        }
      });
      const grant = () => { window.wakeLocks.push(sentinel); resolve(sentinel); };
      if (mode === 'hold') pending.push(grant);
      else grant();
    });
    Object.defineProperty(navigator, 'wakeLock', { value: { request }, configurable: true });
  }, mode);
}

// How many wake locks the fake was asked for.
export function wakeLockRequests(page) {
  return page.evaluate(() => window.wakeLockRequests);
}

// How many wake locks the fake has granted, and how many are still held.
export function wakeLockCounts(page) {
  return page.evaluate(() => ({ granted: window.wakeLocks.length, held: window.wakeLocks.filter(lock => !lock.released).length }));
}
