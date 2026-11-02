import { type ScoringEvent } from './types.js';

/**
 * Returns the number of turns played.
 *
 * @param turns The turns that happened during the play.
 * @returns The turn count.
 */
function getTurnCount(turns: ScoringEvent[][]): number {
  return turns.length;
}

export default getTurnCount;
