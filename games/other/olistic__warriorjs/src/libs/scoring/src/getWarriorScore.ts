import getLastEvent from './getLastEvent.js';
import { type ScoringEvent } from './types.js';

/**
 * Returns the score of the warrior.
 *
 * @param turns The turns that happened during the play.
 * @returns The score of the warrior.
 */
function getWarriorScore(turns: ScoringEvent[][]): number {
  const lastEvent = getLastEvent(turns);
  if (!lastEvent.warriorStatus) {
    throw new Error('Last event has no warrior status.');
  }

  return lastEvent.warriorStatus.score;
}

export default getWarriorScore;
