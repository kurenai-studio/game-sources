// Port of Model/Position.swift. Positions are treated as immutable values,
// matching Swift struct semantics: always create a new one instead of mutating.

/** @typedef {{ readonly row: number, readonly column: number }} Position */

/**
 * @param {number} row
 * @param {number} column
 * @returns {Position}
 */
export function position(row, column) {
  return { row, column };
}

/**
 * @param {Position} pos
 * @returns {Position}
 */
export function below(pos) {
  return position(pos.row + 1, pos.column);
}
