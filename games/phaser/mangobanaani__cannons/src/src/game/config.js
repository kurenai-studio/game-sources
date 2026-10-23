export const GAME_WIDTH = 800;
export const GAME_HEIGHT = 600;
export const GRAVITY = 0.3;

// Power and angle
export const MAX_POWER = 15;
export const MIN_POWER = 2;
export const DEFAULT_POWER = 8;
export const DEFAULT_ANGLE = Math.PI / 4;
export const ANGLE_STEP = 0.02;
export const POWER_STEP = 0.3;
export const MIN_ANGLE = 10 * Math.PI / 180;
export const MAX_ANGLE = 80 * Math.PI / 180;

// Cannon
export const CANNON_HP = 100;
export const BARREL_LENGTH = 25;
export const PLAYER_X_PERCENT = 0.15;
export const AI_X_PERCENT = 0.85;

// Cooldown (ms)
export const PLAYER_COOLDOWN = 2000;
export const AI_COOLDOWN_MIN = 3000;
export const AI_COOLDOWN_MAX = 4000;

// Projectile
export const PROJECTILE_RADIUS = 4;
export const TRAIL_LENGTH = 20;

// Weapons
export const WEAPONS = {
  standard: {
    name: 'Standard',
    key: '1',
    blastRadius: 40,
    damage: 35,
    craterDepth: 30,
    speedMultiplier: 1,
    projectileCount: 1,
  },
  bigBlast: {
    name: 'Big Blast',
    key: '2',
    blastRadius: 70,
    damage: 20,
    craterDepth: 50,
    speedMultiplier: 0.7,
    projectileCount: 1,
  },
  cluster: {
    name: 'Cluster Bomb',
    key: '3',
    blastRadius: 30,
    damage: 15,
    craterDepth: 20,
    speedMultiplier: 0.9,
    projectileCount: 3,
    splitAltitude: 0.6, // fraction of descent when it splits
  },
};

export const WEAPON_KEYS = ['standard', 'bigBlast', 'cluster'];

// Wind
export const WIND_MAX = 3;
export const WIND_CHANGE_INTERVAL = 5000; // ms
export const WIND_LERP_SPEED = 0.02;
export const WIND_ACCEL = 0.005; // velocity change per frame per unit of wind

// Terrain
export const TERRAIN_MIN_Y = 300;
export const TERRAIN_MAX_Y = 500;

// Terrain types
export const TERRAIN_TYPES = {
  earth: { craterMultiplier: 1.0, color: 0x8B6914, grassColor: 0x4a7c3f },
  sand: { craterMultiplier: 1.5, color: 0xC2B280, grassColor: 0x8B8B3A },
  rock: { craterMultiplier: 0.5, color: 0x666666, grassColor: 0x555555 },
};

// Water
export const WATER_LEVEL = 570; // y position
export const WATER_COLOR = 0x2266aa;

// Power-ups
export const POWERUP_INTERVAL_MIN = 15000;
export const POWERUP_INTERVAL_MAX = 20000;
export const POWERUP_FALL_SPEED = 1;
export const POWERUP_TYPES = {
  health: { value: 25, color: 0x00cc00, label: '+HP' },
  damage: { value: 1.5, duration: 10000, color: 0xcc0000, label: 'DMG' },
  shield: { value: 15, color: 0x0066cc, label: 'SHD' },
};

// Match
export const ROUNDS_TO_WIN = 3;
export const MAX_ROUNDS = 5;

// Prediction line
export const PREDICTION_STEPS = 60;
export const PREDICTION_DOT_SPACING = 3;
// Matter.js effective gravity per frame: gravity_y * scale(0.001) * delta_ms(16.667)^2
export const PREDICTION_GRAVITY = GRAVITY * 0.001 * (1000 / 60) ** 2;

// Camera
export const CAMERA_LERP = 0.05;

// Screen shake
export const SHAKE_DURATION_BASE = 200;
export const SHAKE_INTENSITY_BASE = 0.008;

// Day/night tint per round
export const ROUND_TINTS = [
  0xffffff, // day
  0xffe0b0, // sunset
  0xb0c0ff, // dusk
  0x8090cc, // night
  0xffd0d0, // dawn
];

// Destructible parts
export const BARREL_DAMAGE_POWER_REDUCTION = 0.5; // max power multiplier when barrel hit
export const WHEEL_DAMAGE_ANGLE_LOCK = true;
