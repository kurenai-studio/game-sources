import type { GameMode } from './constants';

/**
 * Represents a tile value. -1 means empty (during animation), otherwise an
 * index into the tile emoji array.
 */
export type TileType = number;

/**
 * Grid coordinates.
 */
export interface Position {
  readonly col: number;
  readonly row: number;
}

/**
 * Describes a single tile movement produced by gravity.
 */
export interface TileMovement {
  /** Target grid position. */
  readonly to: Position;
  /** Source row before gravity; -1 means the tile was spawned above the board. */
  readonly fromRow: number;
  /** Source column before gravity. */
  readonly fromCol: number;
  /** Whether this tile was newly spawned at the top. */
  readonly isNew: boolean;
}

/**
 * Describes the result of processing matches in a single step.
 */
export interface MatchResult {
  /** Positions of tiles that were matched. */
  readonly matchedPositions: readonly Position[];
  /** Total score awarded for these matches. */
  readonly score: number;
}

/**
 * Describes an animation currently running on a tile.
 */
export interface TileAnimation {
  /** Current visual x offset in pixels. */
  readonly offsetX: number;
  /** Current visual y offset in pixels. */
  readonly offsetY: number;
  /** Current scale (1 = normal). */
  readonly scale: number;
  /** Current opacity (1 = fully visible). */
  readonly opacity: number;
}

/**
 * Mutable tile state used by the renderer.
 */
export interface TileState {
  /** Logical tile value. */
  value: TileType;
  /** Visual animation state. */
  anim: TileAnimation;
}

/**
 * A particle used for visual effects.
 */
export interface Particle {
  /** Horizontal position in pixels. */
  x: number;
  /** Vertical position in pixels. */
  y: number;
  /** Horizontal velocity. */
  vx: number;
  /** Vertical velocity. */
  vy: number;
  /** Remaining lifetime in seconds. */
  life: number;
  /** Starting lifetime in seconds. */
  maxLife: number;
  /** Particle radius in pixels. */
  radius: number;
  /** Hue for HSL color. */
  hue: number;
}

/**
 * Complete game state.
 */
export interface GameState {
  /** Logical grid. */
  grid: TileType[][];
  /** Currently selected tile, if any. */
  selected: Position | null;
  /** Current score. */
  score: number;
  /** Current level in level mode. */
  level: number;
  /** Current game mode. */
  mode: GameMode;
  /** Remaining moves in level mode. */
  movesLeft: number | null;
  /** Remaining seconds in time mode. */
  timeLeft: number | null;
  /** Score target for level mode. */
  targetScore: number | null;
  /** Whether the game is currently processing animations. */
  busy: boolean;
  /** Whether the game has ended. */
  gameOver: boolean;
  /** Whether the game was won. */
  won: boolean;
  /** Cursor position for keyboard navigation, null when using pointer input. */
  cursor: Position | null;
}
