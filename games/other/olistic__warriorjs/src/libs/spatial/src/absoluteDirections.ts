import { type AbsoluteOffset, type RelativeOffset } from './location.js';
import { RELATIVE_DIRECTIONS, type RelativeDirection } from './relativeDirections.js';

export const NORTH = 'north';
export const EAST = 'east';
export const SOUTH = 'south';
export const WEST = 'west';

/**
 * The absolute directions in clockwise order.
 */
export const ABSOLUTE_DIRECTIONS = [NORTH, EAST, SOUTH, WEST] as const;

/** An absolute direction. */
export type AbsoluteDirection = (typeof ABSOLUTE_DIRECTIONS)[number];

/**
 * Checks if the given direction is a valid absolute direction.
 *
 * @param direction The direction.
 *
 * @throws Will throw if the direction is not valid.
 */
export function verifyAbsoluteDirection(direction: string): asserts direction is AbsoluteDirection {
  if (!ABSOLUTE_DIRECTIONS.includes(direction as AbsoluteDirection)) {
    throw new Error(
      `Unknown direction: '${direction}'. Should be one of: '${NORTH}', '${EAST}', '${SOUTH}' or '${WEST}'.`,
    );
  }
}

/**
 * Returns the absolute direction for a given direction, with reference to
 * another direction (reference direction).
 *
 * @param direction The direction (relative).
 * @param referenceDirection The reference direction (absolute).
 *
 * @returns The absolute direction.
 */
export function getAbsoluteDirection(
  direction: RelativeDirection,
  referenceDirection: AbsoluteDirection,
): AbsoluteDirection {
  const index =
    (ABSOLUTE_DIRECTIONS.indexOf(referenceDirection) + RELATIVE_DIRECTIONS.indexOf(direction)) % 4;
  return ABSOLUTE_DIRECTIONS[index];
}

/**
 * Returns the absolute offset for a given relative offset with reference
 * to a given direction (reference direction).
 *
 * @param offset The relative offset as [forward, right].
 * @param referenceDirection The reference direction (absolute).
 *
 * @returns The absolute offset as [deltaX, deltaY].
 */
export function getAbsoluteOffset(
  [forward, right]: RelativeOffset,
  referenceDirection: AbsoluteDirection,
): AbsoluteOffset {
  if (referenceDirection === NORTH) {
    return [right, -forward];
  }

  if (referenceDirection === EAST) {
    return [forward, right];
  }

  if (referenceDirection === SOUTH) {
    return [-right, forward];
  }

  return [-forward, -right];
}
