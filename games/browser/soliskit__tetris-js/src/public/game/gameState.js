// Port of Model/GameState.swift, Model/PlayerAction.swift and Model/GameCell.swift.

// How many upcoming pieces are known and shown.
export const UPCOMING_COUNT = 3;

export const GameState = Object.freeze(/** @type {const} */ ({
  playing: 'playing',
  paused: 'paused',
  gameOver: 'gameOver'
}));

/** @typedef {typeof GameState[keyof typeof GameState]} GameStateValue */

export const PlayerAction = Object.freeze(/** @type {const} */ ({
  newGame: 'newGame',
  continueGame: 'continueGame',
  pause: 'pause',
  resume: 'resume',
  moveLeft: 'moveLeft',
  moveRight: 'moveRight',
  hold: 'hold',
  rotate: 'rotate',
  rotateCounterclockwise: 'rotateCounterclockwise',
  drop: 'drop'
}));

/** @typedef {typeof PlayerAction[keyof typeof PlayerAction]} PlayerActionValue */

/** @typedef {{ isFilled: boolean, color: string | null }} Cell */
/** @typedef {Cell[][]} Board */

/** @returns {Cell} */
function emptyCell() {
  return { isFilled: false, color: null };
}

/**
 * @param {number} rows
 * @param {number} columns
 * @returns {Board}
 */
export function createBoard(rows, columns) {
  return Array.from({ length: rows }, () => Array.from({ length: columns }, emptyCell));
}

// Port of Support/Array.swift: returns undefined instead of throwing when out
// of bounds. (Arrays already give undefined for a missing index; only a
// missing row needs guarding.)
/**
 * @param {Board} board
 * @param {number} row
 * @param {number} column
 * @returns {Cell | undefined}
 */
export function cellAt(board, row, column) {
  return board[row]?.[column];
}
