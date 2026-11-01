/**
 * Game constants shared across the project.
 */

/** Number of rows and columns on the board. */
export const GRID_SIZE = 8;

/** Number of different tile types available. */
export const TILE_TYPES = 6;

/** Tile emojis used in the game. */
export const EMOJIS: readonly string[] = ['🍭', '🌈', '🦄', '⭐', '💎', '🍬'];

/** Score awarded per matched tile. */
export const BASE_MATCH_SCORE = 10;

/** Multiplier applied for each additional tile beyond 3. */
export const COMBO_MULTIPLIER = 1.5;

/** Base target score for level mode. */
export const BASE_LEVEL_TARGET_SCORE = 1000;

/** Target score increase per level. */
export const LEVEL_TARGET_INCREMENT = 500;

/** Starting move limit for level mode. */
export const BASE_LEVEL_MOVES = 20;

/** Moves removed per level. */
export const LEVEL_MOVE_DECREMENT = 1;

/** Minimum move limit for level mode. */
export const MIN_LEVEL_MOVES = 10;

/** Current mode configuration. */
export interface ModeConfig {
  /** Time limit in seconds, or null for no timer. */
  readonly timeLimit: number | null;
  /** Move limit, or null for unlimited moves. */
  readonly moveLimit: number | null;
  /** Score target, or null for no target. */
  readonly targetScore: number | null;
}

/** Supported game modes. */
export type GameMode = 'endless' | 'levels' | 'time';

/** Mode configurations. */
export const MODES: Readonly<Record<GameMode, ModeConfig>> = {
  endless: {
    moveLimit: null,
    targetScore: null,
    timeLimit: null,
  },
  levels: {
    moveLimit: 20,
    targetScore: 1000,
    timeLimit: null,
  },
  time: {
    moveLimit: null,
    targetScore: null,
    timeLimit: 60,
  },
};
