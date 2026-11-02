import { type ScoringFloorSpace } from './types.js';

/**
 * Checks if the floor is clear.
 *
 * The floor is clear when there are no units other than the warrior.
 *
 * @param floorMap The floor map.
 * @returns Whether the floor is clear or not.
 */
function isFloorClear(floorMap: ScoringFloorSpace[][]): boolean {
  const spaces = floorMap.reduce<ScoringFloorSpace[]>((acc, val) => acc.concat(val), []);
  const unitCount = spaces.filter((space) => !!space.unit).length;
  return unitCount <= 1;
}

export default isFloorClear;
