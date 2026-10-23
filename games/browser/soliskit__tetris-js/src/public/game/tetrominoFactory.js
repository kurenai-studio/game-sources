// Port of Support/TetrominoFactory.swift: 7-bag randomizer with SRS wall kicks.
// The Swift version keeps the bag in static state; here it is an instance so
// the random source can be injected (for tests or a future seeded challenge).

import { position } from './position.js';
import { Tetromino } from './tetromino.js';

/** @typedef {import('./position.js').Position} Position */
/** @typedef {import('./tetromino.js').Shape} Shape */

// SwiftUI system colors (iOS light appearance).
export const PieceColors = Object.freeze({
  cyan: '#00C0E8',
  yellow: '#FFCC00',
  purple: '#AF52DE',
  green: '#34C759',
  red: '#FF3B30',
  blue: '#007AFF',
  orange: '#FF9500'
});

/**
 * @param {number[][][]} rows [row, column] offsets for each rotation state
 * @returns {Position[][]}
 */
const kicks = rows => rows.map(row => row.map(([r, c]) => position(r, c)));

const jlstzWallKicks = kicks([
  [[0, 0], [0, -1], [-1, -1], [2, 0], [2, -1]],
  [[0, 0], [0, 1], [1, 1], [-2, 0], [-2, 1]],
  [[0, 0], [0, 1], [-1, 1], [2, 0], [2, 1]],
  [[0, 0], [0, -1], [1, -1], [-2, 0], [-2, -1]]
]);

const iWallKicks = kicks([
  [[0, 0], [0, -2], [0, 1], [1, -2], [-2, 1]],
  [[0, 0], [0, -1], [0, 2], [-2, -1], [1, 2]],
  [[0, 0], [0, 2], [0, -1], [-1, 2], [2, -1]],
  [[0, 0], [0, 1], [0, -2], [2, 1], [-1, -2]]
]);

const oWallKicks = kicks([[[0, 0]]]);

/**
 * @param {string[]} spawn The spawn shape, X for a block.
 * @param {string} color
 * @param {Position[][]} wallKickData
 * @returns {Tetromino}
 */
function piece(spawn, color, wallKickData) {
  /** @type {Shape[]} */
  const rotations = [spawn.map(line => [...line].map(ch => ch === 'X'))];
  while (rotations.length < wallKickData.length) {
    const last = rotations[rotations.length - 1];
    rotations.push(last.map((_, row) => last.map((__, column) => last[last.length - 1 - column][row])));
  }
  return new Tetromino({ rotations, color, wallKickData });
}

/** @returns {Tetromino[]} */
export function allPieces() {
  return [
    piece(['....', 'XXXX', '....', '....'], PieceColors.cyan, iWallKicks),
    piece(['XX', 'XX'], PieceColors.yellow, oWallKicks),
    piece(['.X.', 'XXX', '...'], PieceColors.purple, jlstzWallKicks),
    piece(['.XX', 'XX.', '...'], PieceColors.green, jlstzWallKicks),
    piece(['XX.', '.XX', '...'], PieceColors.red, jlstzWallKicks),
    piece(['X..', 'XXX', '...'], PieceColors.blue, jlstzWallKicks),
    piece(['..X', 'XXX', '...'], PieceColors.orange, jlstzWallKicks)
  ];
}

// Fisher Yates shuffle, in place.
/**
 * @template T
 * @param {T[]} items
 * @param {() => number} random
 * @returns {T[]} The same array.
 */
function shuffle(items, random) {
  // Stryker disable next-line EqualityOperator: also running i = 0 would swap the first item with itself.
  for (let i = items.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [items[i], items[j]] = [items[j], items[i]];
  }
  return items;
}

export class TetrominoFactory {
  /** @param {() => number} [random] Returns numbers in [0, 1). */
  constructor(random = Math.random) {
    this.random = random;
    /** @type {Tetromino[]} */
    this.bag = [];
  }

  /** @returns {Tetromino} */
  generate() {
    if (this.bag.length === 0) {
      this.bag = shuffle(allPieces(), this.random);
    }
    // Never undefined: the bag was just refilled if it was empty.
    return /** @type {Tetromino} */ (this.bag.shift());
  }

  // Starts a full bag, or carries on with the pieces left in a saved one.
  /** @param {Tetromino[]} [pieces] */
  resetBag(pieces = []) {
    this.bag = pieces;
  }
}
