import getLastEvent from './getLastEvent.js';
import isFloorClear from './isFloorClear.js';
import { type ScoringEvent } from './types.js';

/**
 * Returns the bonus for clearing the level.
 *
 * @param turns The turns that happened during the play.
 * @param warriorScore The score of the warrior.
 * @param timeBonus The time bonus.
 * @returns The clear bonus.
 */
function getClearBonus(turns: ScoringEvent[][], warriorScore: number, timeBonus: number): number {
  const lastEvent = getLastEvent(turns);
  if (!isFloorClear(lastEvent.floorMap)) {
    return 0;
  }

  return Math.round((warriorScore + timeBonus) * 0.2);
}

export default getClearBonus;
