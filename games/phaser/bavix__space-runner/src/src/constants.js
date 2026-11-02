// Game Constants
export const PLAYER_SIZE = 20;
export const PLAYER_SPEED = 3.5;
export const BULLET_SIZE = 4;
export const BULLET_SPEED = 10;
export const ASTEROID_SIZE = 15;
export const COMET_SIZE = 12;
export const FAST_ENEMY_SIZE = 8;
export const BIG_ENEMY_SIZE = 22;
export const ENERGY_SIZE = 6;
export const POWERUP_SIZE = 7;
export const SPAWN_RATE = 0.015;
export const ENERGY_SPAWN_RATE = 0.008;
export const POWERUP_SPAWN_RATE = 0.004;
export const HYPERSPEED_DURATION = 5000;
export const HYPERSPEED_MULTIPLIER = 2;
export const SHOOT_COOLDOWN = 120;
export const COMBO_TIMEOUT = 1200;
export const BOSS_SPAWN_SCORE = 100;
export const TRIPLE_SHOT_DURATION = 8000;
export const AUTO_AIM_DURATION = 3000;
export const MAGNET_DURATION = 6000;
export const MAGNET_RADIUS = 200;
export const MAGNET_MAX_PULL_SPEED = 12;
export const MAGNET_MIN_PULL_SPEED = 2;
export const SLOW_MOTION_DURATION = 5000;
export const POWERUP_PARTICLES_COUNT = 30;
export const POWERUP_TEXT_SIZE = 9;
export const SHIELD_DURATION = 10000;
export const INFINITE_DURATION = 999999999;
export const EXPLOSION_PARTICLES_COUNT = 30;
export const BOSS_KILL_PARTICLES_COUNT = 70;
export const BOSS_KILL_PARTICLES_COUNT_2 = 50;
export const ENERGY_PARTICLES_COUNT = 15;
export const BOSS_HIT_PARTICLES_COUNT = 25;
export const LEVEL_UP_PARTICLES_COUNT = 50;
export const DAMAGE_PARTICLES_COUNT = 50;
export const BOSS_SPAWN_PARTICLES_COUNT = 50;
export const FLOATING_TEXT_SIZES = {
  SMALL: 7,
  NORMAL: 8,
  MEDIUM: 9,
  LARGE: 10,
  XLARGE: 12,
  XXLARGE: 14
};
export const SLOW_MOTION_FACTOR = 0.4;
export const MULTI_KILL_WINDOW = 2000;

export const BOSS_TYPES = {
  FORTRESS: 'fortress',
  HUNTER: 'hunter',
  STORM: 'storm',
  PHANTOM: 'phantom',
  VOID: 'void'
};

export { COLOR_PATHS } from './constants/colorPaths.js';
export { 
  POWERUP_TYPES, 
  PARTICLE_TYPES, 
  OBSTACLE_TYPES, 
  PLAYER_STATES
} from './constants/gameParams.js';

