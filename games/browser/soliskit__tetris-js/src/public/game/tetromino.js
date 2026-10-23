// Port of Model/Tetromino.swift.
// Swift's Tetromino is a value type, so every method that "copies" in Swift
// returns a new instance here. rotations and wallKickData are never mutated
// and are shared between copies.

import { position } from './position.js';
import { cellAt } from './gameState.js';

/** @typedef {import('./position.js').Position} Position */
/** @typedef {import('./gameState.js').Board} Board */
/** @typedef {boolean[][]} Shape */
/**
 * @typedef {object} TetrominoData
 * @property {Shape[]} rotations Every rotation state, clockwise from spawn.
 * @property {string} color
 * @property {Position[][]} wallKickData Kicks to try when turning clockwise from each state.
 * @property {Position} [position]
 * @property {number} [rotationState]
 */

/**
 * @param {Board} gameBoard
 * @param {number} row
 * @param {number} column
 * @returns {boolean} Whether the cell is on the board and empty.
 */
function isFree(gameBoard, row, column) {
  return cellAt(gameBoard, row, column)?.isFilled === false;
}

export class Tetromino {
  /** @param {TetrominoData} data */
  constructor({ rotations, color, wallKickData, position: pos = position(0, 0), rotationState = 0 }) {
    this.color = color;
    this.position = pos;
    this.rotations = rotations;
    this.rotationState = rotationState;
    this.wallKickData = wallKickData;
  }

  get shape() {
    return this.rotations[this.rotationState];
  }

  copy() {
    return new Tetromino({
      color: this.color,
      position: this.position,
      rotations: this.rotations,
      rotationState: this.rotationState,
      wallKickData: this.wallKickData
    });
  }

  /**
   * @param {number} columns
   * @returns {Tetromino}
   */
  spawned(columns) {
    const piece = this.copy();
    const width = this.rotations[0][0].length;
    piece.rotationState = 0;
    piece.position = position(0, Math.max(0, Math.trunc((columns - width) / 2)));
    return piece;
  }

  /**
   * @param {Shape} shape
   * @param {Position} pos
   * @returns {Position[]}
   */
  static cells(shape, pos) {
    /** @type {Position[]} */
    const result = [];
    shape.forEach((blocks, row) => {
      blocks.forEach((filled, column) => {
        if (filled) {
          result.push(position(pos.row + row, pos.column + column));
        }
      });
    });
    return result;
  }

  get cells() {
    return Tetromino.cells(this.shape, this.position);
  }

  /**
   * @param {Shape} shape
   * @param {Position} pos
   * @param {Board} gameBoard
   * @returns {boolean}
   */
  static fits(shape, pos, gameBoard) {
    return Tetromino.cells(shape, pos).every(cell => isFree(gameBoard, cell.row, cell.column));
  }

  /**
   * @param {Board} gameBoard
   * @param {Position} [pos]
   * @returns {boolean}
   */
  fits(gameBoard, pos = this.position) {
    return Tetromino.fits(this.shape, pos, gameBoard);
  }

  // How many rows the piece can fall before it lands. Finds the cells once
  // instead of building new ones for every row checked, since the ghost
  // piece needs this on every redraw.
  /**
   * @param {Board} gameBoard
   * @returns {number}
   */
  dropDistance(gameBoard) {
    const cells = this.cells;
    let rows = 0;
    while (cells.every(cell => isFree(gameBoard, cell.row + rows + 1, cell.column))) {
      rows += 1;
    }
    return rows;
  }

  // Mutating, like the Swift `mutating func rotate`. Tries the asked for
  // direction with its SRS kicks first, then the other direction with its
  // own. Turning counterclockwise uses the clockwise kicks inverted.
  /**
   * @param {Board} gameBoard
   * @param {boolean} [counterclockwise] Turn counterclockwise first.
   */
  rotate(gameBoard, counterclockwise = false) {
    const count = this.rotations.length;
    const clockwise = (this.rotationState + 1) % count;
    const counterClockwise = (this.rotationState + count - 1) % count;
    /** @type {Array<[number, Position[]]>} */
    const attempts = [
      [clockwise, this.wallKickData[this.rotationState]],
      [counterClockwise, this.wallKickData[counterClockwise].map(kick => position(-kick.row, -kick.column))]
    ];
    if (counterclockwise) attempts.reverse();
    for (const [state, kicks] of attempts) {
      for (const kick of kicks) {
        const candidate = position(this.position.row + kick.row, this.position.column + kick.column);
        if (Tetromino.fits(this.rotations[state], candidate, gameBoard)) {
          this.rotationState = state;
          this.position = candidate;
          return;
        }
      }
    }
  }
}

// The piece part of the engine's safety check. One rule for what a piece is,
// used for the falling piece (playing or paused) and for every upcoming piece.
// The expected shapes are built here, apart from the pieces being checked, so
// a damaged piece can never be compared against itself.
/**
 * @param {string[]} spawn The spawn shape, X for a block.
 * @param {number} turns How many rotation states the piece has.
 * @returns {boolean[][][]}
 */
function expectedRotations(spawn, turns) {
  const rotations = [spawn.map(line => [...line].map(ch => ch === 'X'))];
  while (rotations.length < turns) {
    const last = rotations[rotations.length - 1];
    rotations.push(last.map((_, row) => last.map((__, column) => last[last.length - 1 - column][row])));
  }
  return rotations;
}

// Keyed by the piece's fixed color.
const EXPECTED = new Map([
  ['#00C0E8', expectedRotations(['....', 'XXXX', '....', '....'], 4)],
  ['#FFCC00', expectedRotations(['XX', 'XX'], 1)],
  ['#AF52DE', expectedRotations(['.X.', 'XXX', '...'], 4)],
  ['#34C759', expectedRotations(['.XX', 'XX.', '...'], 4)],
  ['#FF3B30', expectedRotations(['XX.', '.XX', '...'], 4)],
  ['#007AFF', expectedRotations(['X..', 'XXX', '...'], 4)],
  ['#FF9500', expectedRotations(['..X', 'XXX', '...'], 4)]
]);

/**
 * @param {unknown} list
 * @returns {boolean} Whether it is an array with every index present.
 */
function isDense(list) {
  if (!Array.isArray(list)) return false;
  for (let index = 0; index < list.length; index++) {
    if (!Object.hasOwn(list, index)) return false;
  }
  return true;
}

/**
 * @param {unknown} actual
 * @param {boolean[]} expected
 * @returns {boolean}
 */
function sameRow(actual, expected) {
  return isDense(actual) && /** @type {unknown[]} */ (actual).length === expected.length
    && expected.every((filled, column) => /** @type {unknown[]} */ (actual)[column] === filled);
}

/**
 * @param {unknown} actual
 * @param {boolean[][]} expected
 * @returns {boolean}
 */
function sameShape(actual, expected) {
  return isDense(actual) && /** @type {unknown[]} */ (actual).length === expected.length
    && expected.every((row, index) => sameRow(/** @type {unknown[]} */ (actual)[index], row));
}

/**
 * @param {unknown} piece
 * @returns {boolean[][][] | undefined} The expected rotations for this piece's kind, if it has one.
 */
function expectedFor(piece) {
  const data = /** @type {{ color?: unknown } | null | undefined} */ (piece);
  return typeof data?.color === 'string' ? EXPECTED.get(data.color) : undefined;
}

/**
 * An upcoming piece is a real piece: a known kind with every rotation state
 * as the game defines it. Where it waits does not matter.
 * @param {unknown} piece
 * @returns {boolean}
 */
export function isValidPiece(piece) {
  const expected = expectedFor(piece);
  if (!expected) return false;
  const rotations = /** @type {{ rotations?: unknown }} */ (piece).rotations;
  return isDense(rotations) && /** @type {unknown[]} */ (rotations).length === expected.length
    && expected.every((shape, index) => sameShape(/** @type {unknown[]} */ (rotations)[index], shape));
}

/**
 * @param {unknown[]} pieces
 * @returns {boolean} Whether every entry is present and a valid piece.
 */
export function isValidPieceList(pieces) {
  return isDense(pieces) && pieces.every(isValidPiece);
}

/**
 * The falling piece is a real piece in a real rotation, with four blocks on
 * empty cells of the board. Checks its own blocks, not what it reports.
 * @param {unknown} piece
 * @param {Board} board
 * @returns {boolean}
 */
export function isValidFallingPiece(piece, board) {
  const expected = expectedFor(piece);
  if (!expected) return false;
  const { rotationState, position, rotations } = /** @type {{ rotationState?: unknown, position?: { row?: unknown, column?: unknown }, rotations?: unknown }} */ (piece);
  const row = position?.row;
  const column = position?.column;
  if (!Number.isInteger(row) || !Number.isInteger(column)) return false;
  // A whole-number index only: expected has no entry for -1, 0.5 or 4.
  const shape = Number.isInteger(rotationState) ? expected[/** @type {number} */ (rotationState)] : undefined;
  if (!shape || !isDense(rotations) || !sameShape(/** @type {unknown[]} */ (rotations)[/** @type {number} */ (rotationState)], shape)) return false;
  return shape.every((blocks, r) => blocks.every((filled, c) => !filled || board[/** @type {number} */ (row) + r]?.[/** @type {number} */ (column) + c]?.isFilled === false));
}
