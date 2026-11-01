import type { GameObj } from 'kaplay'

import { Tag } from '../constants'

/**
 * Checks if level has been solved.
 *
 * @returns - If all the pipes are in the correct position.
 */
export function checkSolution(level: GameObj<unknown>): boolean {
  return level.get(Tag.pipe).reduce((accumulator, pipe) => {
    return accumulator && pipe.type === pipe.solution
  }, true)
}
