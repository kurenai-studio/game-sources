import { type AbsoluteDirection, EAST, NORTH, SOUTH, WEST } from './absoluteDirections.js';

/** A location as [x, y]. */
export type Location = [number, number];

/** An absolute offset as [deltaX, deltaY]. */
export type AbsoluteOffset = [number, number];

/** A relative offset as [forward, right]. */
export type RelativeOffset = [number, number];

/**
 * Translates the given location by a given offset.
 *
 * @param location The location as [x, y].
 * @param offset The offset as [deltaX, deltaY].
 *
 * @returns The translated location.
 */
export function translateLocation([x, y]: Location, [deltaX, deltaY]: AbsoluteOffset): Location {
  return [x + deltaX, y + deltaY];
}

/**
 * Returns the direction of a location from another location (reference
 * location).
 *
 * @param location The location as [x, y].
 * @param referenceLocation The reference location as [x, y].
 *
 * @returns The direction.
 */
export function getDirectionOfLocation([x1, y1]: Location, [x2, y2]: Location): AbsoluteDirection {
  if (Math.abs(x2 - x1) > Math.abs(y2 - y1)) {
    if (x1 > x2) {
      return EAST;
    }

    return WEST;
  }

  if (y1 > y2) {
    return SOUTH;
  }

  return NORTH;
}

/**
 * Returns the Manhattan distance of a location from another location (reference
 * location).
 *
 * @param location The location as [x, y].
 * @param referenceLocation The reference location as [x, y].
 *
 * @returns The distance between the locations.
 */
export function getDistanceOfLocation([x1, y1]: Location, [x2, y2]: Location): number {
  return Math.abs(x2 - x1) + Math.abs(y2 - y1);
}
