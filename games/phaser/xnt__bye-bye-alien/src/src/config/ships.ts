/**
 * Ship definitions — easy to extend with new ships in the future.
 */
export interface ShipStats {
  name: string;
  description: string;  // short flavour text for selection screen
  textureKey: string;   // key used for the sprite texture
  bulletTextureKey: string; // key used for the bullet texture
  speed: number;        // pixels / second
  handling: number;     // turning responsiveness multiplier
  damage: number;       // per bullet
  hp: number;
  fireRate: number;     // shots per second
  bulletSpeed: number;  // pixels / second
}

export const SHIP_KEYS = ['f35', 'valkyrie', 'titan', 'spectre'] as const;
export type ShipKey = (typeof SHIP_KEYS)[number];

export const SHIPS: Record<ShipKey, ShipStats> = {
  f35: {
    name: 'F-35 Lightning',
    description: 'Balanced all-rounder. Reliable in every situation.',
    textureKey: 'f35',
    bulletTextureKey: 'bullet_f35',
    speed: 300,
    handling: 1.0,
    damage: 10,
    hp: 100,
    fireRate: 5,
    bulletSpeed: 500,
  },

  valkyrie: {
    name: 'Valkyrie',
    description: 'Fast interceptor. Fragile but overwhelming fire rate.',
    textureKey: 'valkyrie',
    bulletTextureKey: 'bullet_valkyrie',
    speed: 420,
    handling: 1.3,
    damage: 6,
    hp: 60,
    fireRate: 9,
    bulletSpeed: 600,
  },

  titan: {
    name: 'Titan',
    description: 'Heavy gunship. Slow but devastating firepower and thick armour.',
    textureKey: 'titan',
    bulletTextureKey: 'bullet_titan',
    speed: 180,
    handling: 0.7,
    damage: 22,
    hp: 200,
    fireRate: 2.5,
    bulletSpeed: 380,
  },

  spectre: {
    name: 'Spectre',
    description: 'Stealth striker. Precise long-range shots with moderate survivability.',
    textureKey: 'spectre',
    bulletTextureKey: 'bullet_spectre',
    speed: 260,
    handling: 0.9,
    damage: 18,
    hp: 80,
    fireRate: 3.5,
    bulletSpeed: 700,
  },
};

/** Maxed-out stats used during the UFO disguise power-up. */
export const POWERUP_STATS: ShipStats = {
  name: 'UFO Disguise',
  description: 'Alien tech overload — all stats maxed!',
  textureKey: 'powerup_disguise',
  bulletTextureKey: 'bullet_powerup',
  speed: 450,
  handling: 1.4,
  damage: 30,
  hp: 250,
  fireRate: 10,
  bulletSpeed: 700,
};
