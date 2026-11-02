import { type ScoringEvent } from './types.js';

/**
 * Returns the last event of the play.
 *
 * @param turns The turns that happened during the play.
 * @returns The last event.
 */
function getLastEvent(turns: ScoringEvent[][]): ScoringEvent {
  const lastTurnEvents = turns.at(-1);
  if (!lastTurnEvents || lastTurnEvents.length === 0) {
    throw new Error('No turn events found.');
  }

  return lastTurnEvents.at(-1)!;
}

export default getLastEvent;
