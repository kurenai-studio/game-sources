export const MIN_GRID = 3;
export const MAX_GRID = 7;
const GRID_GROWTH_INTERVAL = 3;
const PATTERN_BASE = 2;
const PATTERN_GRID_RATIO = 0.4;

export const START_TIME_MS = 60_000;
export const WARNING_MS = 10_000;
export const TICK_MS = 100;
export const TIME_BONUS_BASE_MS = 3_000;
const TIME_BONUS_PER_EXTRA_TILE_MS = 500;
export const MAX_BONUS_MS = 11_000;

export const LOCK_IN_MS = 300;
export const FEEDBACK_CORRECT_MS = 1_000;
export const FEEDBACK_WRONG_MS = 1_600;
const REVEAL_BASE_MS = 900;
const REVEAL_PER_TILE_MS = 200;
export const MAX_REVEAL_MS = 2_500;

/**
 * Returns the grid size (cells per side) for the given round.
 *
 * @param round - One-based round number.
 * @returns Grid size, grown every {@link GRID_GROWTH_INTERVAL} rounds and capped at {@link MAX_GRID}.
 */
export function getGridSize(round: number): number {
  const growth = Math.floor((round - 1) / GRID_GROWTH_INTERVAL);
  return Math.min(MIN_GRID + growth, MAX_GRID);
}

/**
 * Returns how many cells a round asks the player to memorize.
 *
 * @param round - One-based round number.
 * @returns Pattern size, growing with the round and capped at {@link PATTERN_GRID_RATIO} of the grid.
 */
export function getPatternSize(round: number): number {
  const cells = getGridSize(round) ** 2;
  const cap = Math.floor(cells * PATTERN_GRID_RATIO);
  return Math.min(round + PATTERN_BASE, cap);
}

/**
 * Returns how long the pattern stays visible.
 *
 * @param patternSize - Number of lit cells in the pattern.
 * @returns Reveal duration in milliseconds, capped at {@link MAX_REVEAL_MS}.
 */
export function getRevealDuration(patternSize: number): number {
  return Math.min(
    REVEAL_BASE_MS + patternSize * REVEAL_PER_TILE_MS,
    MAX_REVEAL_MS,
  );
}

/**
 * Returns the clock bonus granted for clearing a round in Timed mode.
 *
 * Scales with the number of tiles the round asks the player to hold, not
 * with the round number: difficulty grows with span, so a round-30 linear
 * bonus would be far too generous on the easy 3x3 opening and stingy on the
 * 7x7 endgame. Early rounds clear the clock faster than it drains; the
 * endgame pays for the extra deliberation a longer pattern needs.
 *
 * @param round - One-based round number that was just cleared.
 * @returns Bonus time in milliseconds, capped at {@link MAX_BONUS_MS}.
 */
export function getTimeBonus(round: number): number {
  const extraTiles = Math.max(getPatternSize(round) - getPatternSize(1), 0);
  return Math.min(
    TIME_BONUS_BASE_MS + extraTiles * TIME_BONUS_PER_EXTRA_TILE_MS,
    MAX_BONUS_MS,
  );
}
