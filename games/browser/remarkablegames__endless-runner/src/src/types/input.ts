/**
 * Lane index type - represents the three discrete lanes.
 * Lane 0 = left, Lane 1 = center, Lane 2 = right
 */
export type LaneIndex = 0 | 1 | 2;

/**
 * Input direction type - represents player input directions.
 * Maps to 4-directional movement: left/right lane switching, up/jump, down/duck
 */
export type InputDirection = 'LEFT' | 'RIGHT' | 'UP' | 'DOWN';
