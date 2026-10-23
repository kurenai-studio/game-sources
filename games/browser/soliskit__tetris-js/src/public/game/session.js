// Saved games. A save comes from localStorage, which can be corrupted,
// truncated or edited, so it is treated as untrusted input: every field is
// checked, pieces are rebuilt from the built in definitions rather than
// from stored shapes, and anything invalid rejects the whole save.

import { UPCOMING_COUNT } from './gameState.js';
import { position } from './position.js';
import { allPieces } from './tetrominoFactory.js';

/** @typedef {import('./gameState.js').Board} Board */
/** @typedef {import('./gameState.js').Cell} Cell */
/** @typedef {import('./tetromino.js').Tetromino} Tetromino */
/** @typedef {import('./gameManager.js').GameManager} GameManager */
/**
 * @typedef {object} Session
 * @property {Board} gameBoard
 * @property {number} score
 * @property {Tetromino} currentTetromino
 * @property {Tetromino[]} nextTetrominos
 * @property {Tetromino | null} heldTetromino
 * @property {boolean} canHoldTetromino
 * @property {Tetromino[]} bag The pieces left in the shuffled bag, dealt next.
 */

/**
 * @param {GameManager} game
 * @returns {string}
 */
export function serializeSession(game) {
  return JSON.stringify({
    gameBoard: game.gameBoard,
    score: game.score,
    currentTetromino: game.currentTetromino,
    nextTetrominos: game.nextTetrominos,
    heldTetromino: game.heldTetromino,
    canHoldTetromino: game.canHoldTetromino,
    // By color: the type is all a piece in the bag needs.
    bag: (game.factory.bag ?? []).map(piece => piece.color)
  });
}

// Type guards: saved data is untrusted, so every value starts as unknown.

/**
 * @param {unknown} value
 * @returns {value is Record<string, unknown>}
 */
const isObject = value => typeof value === 'object' && value !== null && !Array.isArray(value);

/**
 * @param {unknown} value
 * @returns {value is number}
 */
const isInteger = value => Number.isInteger(value);

/**
 * @param {unknown} value
 * @returns {value is number}
 */
const isSafeInteger = value => Number.isSafeInteger(value);

/**
 * @param {unknown} color
 * @returns {Tetromino | null}
 */
function pieceWithColor(color) {
  return allPieces().find(piece => piece.color === color) ?? null;
}

/**
 * @param {unknown} board
 * @param {number} rows
 * @param {number} columns
 * @returns {Board | null}
 */
function parseBoard(board, rows, columns) {
  if (!Array.isArray(board) || board.length !== rows) return null;
  /** @type {Set<unknown>} */
  const colors = new Set(allPieces().map(piece => piece.color));
  /** @type {Board} */
  const result = [];
  for (const row of board) {
    if (!Array.isArray(row) || row.length !== columns) return null;
    /** @type {Cell[]} */
    const cells = [];
    for (const cell of row) {
      if (!isObject(cell) || typeof cell.isFilled !== 'boolean') return null;
      if (cell.isFilled ? !colors.has(cell.color) : cell.color !== null) return null;
      // Checked just above: a piece color when filled, otherwise null.
      cells.push({ isFilled: cell.isFilled, color: /** @type {string | null} */ (cell.color) });
    }
    // Full rows are cleared as soon as they form, so a saved one is corrupt.
    if (cells.every(cell => cell.isFilled)) return null;
    result.push(cells);
  }
  return result;
}

// A piece in play: its type, rotation and position must be valid and it
// must fit on the board.
/**
 * @param {unknown} data
 * @param {Board} board
 * @returns {Tetromino | null}
 */
function parseActivePiece(data, board) {
  if (!isObject(data) || !isObject(data.position)) return null;
  const piece = pieceWithColor(data.color);
  const { row, column } = data.position;
  if (!piece || !isInteger(row) || !isInteger(column)) return null;
  if (!isInteger(data.rotationState) || data.rotationState < 0 || data.rotationState >= piece.rotations.length) return null;
  piece.rotationState = data.rotationState;
  piece.position = position(row, column);
  return piece.fits(board) ? piece : null;
}

// A queued or held piece only needs a valid type; it enters at spawn.
/**
 * @param {unknown} data
 * @param {number} columns
 * @returns {Tetromino | null}
 */
function parseWaitingPiece(data, columns) {
  if (!isObject(data)) return null;
  return pieceWithColor(data.color)?.spawned(columns) ?? null;
}

// The pieces left in the bag, by color. A bag holds each piece at most once.
/**
 * @param {unknown} colors
 * @returns {Tetromino[] | null}
 */
function parseBag(colors) {
  if (!Array.isArray(colors) || new Set(colors).size !== colors.length) return null;
  const pieces = colors.map(pieceWithColor);
  return pieces.every(piece => piece !== null) ? pieces : null;
}

// Returns the saved game as validated game state, or null when the text is
// missing or anything in it is invalid.
/**
 * @param {string | null} text
 * @param {{ rows: number, columns: number }} size
 * @returns {Session | null}
 */
export function parseSession(text, { rows, columns }) {
  /** @type {unknown} */
  let data = null;
  try {
    // A missing save (null) parses as null and is rejected below.
    data = JSON.parse(/** @type {string} */ (text));
  } catch {
    // Not JSON: data stays null and is rejected below.
  }
  if (!isObject(data)) return null;
  // Older layouts stored a level or left out the remaining bag.
  if (Object.hasOwn(data, 'level')) return null;

  const gameBoard = parseBoard(data.gameBoard, rows, columns);
  if (!gameBoard) return null;
  const { score } = data;
  if (!isSafeInteger(score) || score < 0 || score % 100 !== 0) return null;
  const currentTetromino = parseActivePiece(data.currentTetromino, gameBoard);
  if (!currentTetromino) return null;
  if (!Array.isArray(data.nextTetrominos) || data.nextTetrominos.length !== UPCOMING_COUNT) return null;
  const nextTetrominos = [];
  for (const piece of data.nextTetrominos) {
    const parsed = parseWaitingPiece(piece, columns);
    if (!parsed) return null;
    nextTetrominos.push(parsed);
  }
  let heldTetromino = null;
  if (data.heldTetromino !== null) {
    heldTetromino = parseWaitingPiece(data.heldTetromino, columns);
    if (!heldTetromino) return null;
  }
  if (typeof data.canHoldTetromino !== 'boolean') return null;
  const bag = parseBag(data.bag);
  if (!bag) return null;

  return {
    gameBoard,
    score,
    currentTetromino,
    nextTetrominos,
    heldTetromino,
    canHoldTetromino: data.canHoldTetromino,
    bag
  };
}
