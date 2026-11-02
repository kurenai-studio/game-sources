import { BOSS_TYPES } from './constants.js';

// Boss configuration
export const BOSS_CONFIG = {
  [BOSS_TYPES.FORTRESS]: {
    name: 'FORTRESS',
    health: (level) => 12 + level * 3,
    speed: 0.3,
    chaseSpeed: 0.4,
    oscillationAmplitude: 40,
    canShoot: false,
    livesReward: 1,
    size: 50,
    color: { 
      dark: { main: 0xdc2626, accent: 0xf87171, core: 0x991b1b },
      light: { main: 0x991b1b, accent: 0xdc2626, core: 0x7f1d1d }
    }
  },
  [BOSS_TYPES.HUNTER]: {
    name: 'HUNTER',
    health: (level) => 4 + Math.floor(level * 0.8),
    speed: 0.7,
    chaseSpeed: 0.8,
    oscillationAmplitude: 120,
    canShoot: true,
    shootCooldown: 150,
    bulletSpeed: 5,
    livesReward: 3,
    size: 35,
    color: { 
      dark: { main: 0x7c3aed, accent: 0xa78bfa, core: 0x5b21b6 },
      light: { main: 0x5b21b6, accent: 0x7c3aed, core: 0x4c1d95 }
    }
  },
  [BOSS_TYPES.STORM]: {
    name: 'STORM',
    health: (level) => 6 + level,
    speed: 0.6,
    chaseSpeed: 1.8,
    oscillationAmplitude: 80,
    canShoot: false,
    livesReward: 2,
    size: 45,
    color: { 
      dark: { main: 0xea580c, accent: 0xfb923c, core: 0xc2410c },
      light: { main: 0xc2410c, accent: 0xea580c, core: 0x9a3412 }
    }
  },
  [BOSS_TYPES.PHANTOM]: {
    name: 'PHANTOM',
    health: (level) => 5 + Math.floor(level * 1.2),
    speed: 0.55,
    chaseSpeed: 1.2,
    oscillationAmplitude: 90,
    canShoot: true,
    shootCooldown: 200,
    bulletSpeed: 4.5,
    livesReward: 3,
    size: 38,
    color: { 
      dark: { main: 0x06b6d4, accent: 0x67e8f9, core: 0x0891b2 },
      light: { main: 0x0891b2, accent: 0x06b6d4, core: 0x0e7490 }
    }
  },
  [BOSS_TYPES.VOID]: {
    name: 'VOID',
    health: (level) => 8 + Math.floor(level * 1.5),
    speed: 0.65,
    chaseSpeed: 1.5,
    oscillationAmplitude: 100,
    canShoot: true,
    shootCooldown: 120,
    bulletSpeed: 5.5,
    livesReward: 4,
    size: 42,
    color: { 
      dark: { main: 0x8b5cf6, accent: 0xa78bfa, core: 0x6d28d9 },
      light: { main: 0x6d28d9, accent: 0x8b5cf6, core: 0x5b21b6 }
    }
  }
};

