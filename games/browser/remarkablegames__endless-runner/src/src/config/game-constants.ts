import type { DifficultyConfig } from '../types/difficulty-config';
import type { LaneIndex } from '../types/input';
import type { MusicTrackId } from '../types/music-track';

/**
 * Default music loop order. Playback wraps to the first item after the last.
 */
export const MUSIC_TRACKS: MusicTrackId[] = [
  'intro2',
  'verse1',
  'chorus1',
  'chorus3',
  'chorus3',
  'chorus2',
  'outro1',
  'verse1',
  'verse2',
  'bridge1',
  'bridge2',
  'chorus5',
  'chorus3',
  'chorus3',
  'chorus4',
  'outro1',
];

/**
 * Track dimensions in world units.
 */
export const TRACK_WIDTH = 8;
export const TRACK_LENGTH = 175;

/**
 * Distance from the center lane to the outer lane centers.
 * Kept slightly inside the track edges so the player and obstacles stay on
 * the visible path instead of overhanging the sides.
 */
export const LANE_CENTER_OFFSET = 1.6;

/**
 * X-axis positions for the three lanes.
 * Evenly spaced for consistent lane switching.
 */
export const LANE_X_POSITIONS: Record<LaneIndex, number> = {
  0: -LANE_CENTER_OFFSET, // Left lane
  1: 0, // Center lane
  2: LANE_CENTER_OFFSET, // Right lane
};

/**
 * Default difficulty configuration.
 */
export const DIFFICULTY_CONFIG: DifficultyConfig = {
  /** Base forward speed (world units per second). */
  baseSpeed: 12,
  /** Maximum forward speed cap. Tuned to keep late-game reaction windows playable. */
  maxSpeed: 35,
  /** Speed increase interval in seconds (per SC-008). */
  speedIncreaseInterval: 30,
  /** Base obstacle spawn density (obstacles per second). */
  baseDensity: 0.85,
  /** Maximum obstacle spawn density. Kept below the point where hard patterns chain unfairly. */
  maxDensity: 2.8,
  /** Duration to reach max density in seconds so the hardest phase ramps in more gradually. */
  densityRampDuration: 105,
};

/**
 * Lane transition duration in seconds.
 * Time to smoothly lerp between lanes.
 */
export const LANE_TRANSITION_DURATION = 0.15;

/**
 * Jump duration in seconds.
 */
export const JUMP_DURATION = 0.6;

/**
 * Duck duration in seconds.
 */
export const DUCK_DURATION = 0.5;

/**
 * Jump height in world units.
 */
export const JUMP_HEIGHT = 3;

/**
 * Duck height reduction in world units.
 */
export const DUCK_HEIGHT_REDUCTION = 1.5;

/**
 * Input lockout duration in milliseconds.
 * Kept short so repeated lane changes still feel responsive.
 */
export const INPUT_LOCKOUT_DURATION = 50;

/**
 * Obstacle spawn distance ahead of player.
 */
export const OBSTACLE_SPAWN_Z = 55;

/**
 * Minimum world-space gap between obstacle patterns.
 * Prevents late-game spawn cadence from collapsing as speed increases.
 */
export const MIN_PATTERN_SPACING = 16;

/**
 * Obstacle cleanup distance behind player.
 * Obstacles passing this point are returned to pool.
 */
export const OBSTACLE_CLEANUP_Z = -10;

/**
 * Collision detection tolerance.
 * Used for bounding box intersection checks.
 */
export const COLLISION_TOLERANCE = 0.1;

/**
 * Player Z position in world units.
 * Camera target point for the player.
 */
export const PLAYER_Z = 8;
