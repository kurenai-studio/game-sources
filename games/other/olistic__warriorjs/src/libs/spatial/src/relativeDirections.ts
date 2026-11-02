import { ABSOLUTE_DIRECTIONS, type AbsoluteDirection } from './absoluteDirections.js';
import { type Location, type RelativeOffset } from './location.js';

export const FORWARD = 'forward';
export const RIGHT = 'right';
export const BACKWARD = 'backward';
export const LEFT = 'left';

/**
 * The relative directions in clockwise order.
 */
export const RELATIVE_DIRECTIONS = [FORWARD, RIGHT, BACKWARD, LEFT] as const;

/** A relative direction. */
export type RelativeDirection = (typeof RELATIVE_DIRECTIONS)[number];

/**
 * Checks if the given direction is a valid relative direction.
 *
 * @param direction The direction.
 *
 * @throws Will throw if the direction is not valid.
 */
export function verifyRelativeDirection(direction: string): asserts direction is RelativeDirection {
  if (!RELATIVE_DIRECTIONS.includes(direction as RelativeDirection)) {
    throw new Error(
      `Unknown direction: '${direction}'. Should be one of: '${FORWARD}', '${RIGHT}', '${BACKWARD}' or '${LEFT}'.`,
    );
  }
}

/**
 * Returns the relative direction for a given direction, with reference to a
 * another direction (reference direction).
 *
 * @param direction The direction (absolute).
 * @param referenceDirection The reference direction (absolute).
 *
 * @returns The relative direction.
 */
export function getRelativeDirection(
  direction: AbsoluteDirection,
  referenceDirection: AbsoluteDirection,
): RelativeDirection {
  const index =
    (ABSOLUTE_DIRECTIONS.indexOf(direction) -
      ABSOLUTE_DIRECTIONS.indexOf(referenceDirection) +
      RELATIVE_DIRECTIONS.length) %
    RELATIVE_DIRECTIONS.length;
  return RELATIVE_DIRECTIONS[index];
}

/**
 * Returns the relative offset for a given location, with reference to another
 * location (reference location) and direction (reference direction).
 *
 * @param location The location.
 * @param referenceLocation The reference location.
 * @param referenceDirection The reference direction (absolute).
 *
 * @returns The relative offset as [forward, right].
 */
export function getRelativeOffset(
  [x1, y1]: Location,
  [x2, y2]: Location,
  referenceDirection: AbsoluteDirection,
): RelativeOffset {
  const [deltaX, deltaY] = [x1 - x2, y1 - y2];

  if (referenceDirection === 'north') {
    return [-deltaY, deltaX];
  }

  if (referenceDirection === 'east') {
    return [deltaX, deltaY];
  }

  if (referenceDirection === 'south') {
    return [deltaY, -deltaX];
  }

  return [-deltaX, -deltaY];
}

/**
 * Rotates the given relative offset in the given direction.
 *
 * @param offset The relative offset as [forward, right].
 * @param direction The direction (relative direction).
 *
 * @returns The rotated offset as [forward, right].
 */
export function rotateRelativeOffset(
  [forward, right]: RelativeOffset,
  direction: RelativeDirection,
): RelativeOffset {
  if (direction === FORWARD) {
    return [forward, right];
  }

  if (direction === RIGHT) {
    return [-right, forward];
  }

  if (direction === BACKWARD) {
    return [-forward, -right];
  }

  return [right, -forward];
}
