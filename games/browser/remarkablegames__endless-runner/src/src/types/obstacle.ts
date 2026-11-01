/**
 * Obstacle type - represents different obstacle categories.
 * Each type requires a specific player action to avoid.
 */
export type ObstacleType = 'GROUND' | 'AIRBORNE' | 'FULL_LANE';

/**
 * Player action type - represents the action the player is currently performing.
 * Used for input lockout and state validation.
 */
export type PlayerAction = 'LANE_CHANGE' | 'JUMP' | 'DUCK' | 'NONE';
