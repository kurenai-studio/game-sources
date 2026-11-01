export const START_HEALTH = 10;

export const PLAYER_SPEED = 400;
export const SHOOT_COOLDOWN_MS = 350;

export const BULLET_SPEED = 400;
export const BULLET_DAMAGE = 1;

// Enemies spawn every SPAWN_INTERVAL_START_MS at first; the interval shrinks
// by SPAWN_INTERVAL_STEP_MS after each spawn until it reaches the minimum.
export const SPAWN_INTERVAL_START_MS = 2000;
export const SPAWN_INTERVAL_MIN_MS = 700;
export const SPAWN_INTERVAL_STEP_MS = 100;
