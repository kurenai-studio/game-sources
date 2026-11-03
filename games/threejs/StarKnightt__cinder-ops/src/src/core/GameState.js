import { PLAYER_CONFIG, WEAPONS, PICKUPS, ENEMY_CONFIG } from './Constants.js';

class GameState {
  constructor() {
    this.reset();
  }

  /* Ammo/state for the active weapon. Kept as a getter so every legacy
   * reader (Hud, Combat, tools) keeps working against the per-weapon table. */
  get weapon() {
    return this.weapons[this.activeWeapon];
  }

  reset() {
    this.player = {
      health: PLAYER_CONFIG.HEALTH,
      armor: PLAYER_CONFIG.ARMOR,
      alive: true,
      sprinting: false,
      crouching: false,
      ads: false,
      scoped: false,     // sniper scope stage > 0 (crosshair suppression)
      scopeStage: 0,
      fovTarget: 0,      // 0 = no zoom override; else absolute FOV in deg
      adsEase: 0,        // 0–1 ADS blend (Weapon writes; FOV kick / spread extras)
      bloom: 0,          // accumulated per-shot spread (recovers in Weapon.update)
      spread: WEAPONS.rifle.spread.hip,
      speed: 0,
      grounded: true,
    };
    // Loadout: all four weapons from spawn. Map crates are HP/armor supplies.
    this.weapons = {
      rifle: { mag: WEAPONS.rifle.mag, reserve: WEAPONS.rifle.reserve, reloading: false, owned: true },
      sniper: { mag: WEAPONS.sniper.mag, reserve: WEAPONS.sniper.reserve, reloading: false, owned: true },
      shotgun: { mag: WEAPONS.shotgun.mag, reserve: WEAPONS.shotgun.reserve, reloading: false, owned: true },
      pistol: { mag: WEAPONS.pistol.mag, reserve: WEAPONS.pistol.reserve, reloading: false, owned: true },
    };
    this.activeWeapon = 'rifle';
    this.lastWeapon = 'pistol';
    this.pickups = PICKUPS.map((p) => ({ ...p, taken: false }));
    this.nearbyPickup = null;
    this.game = {
      started: false,
      paused: false,
      isPlaying: false,
      won: false,
      over: false,
      kills: 0,
      remaining: ENEMY_CONFIG.COUNT,
      extractOpen: false,
      isMuted: false,
      grace: PLAYER_CONFIG.GRACE,
      headshots: 0,
      shotsFired: 0,
      shotsHit: 0,
      damageTaken: 0,
      startedAt: 0,
    };
  }

  /** After-action recap. Read-only snapshot for the KIA / extract card. */
  raidStats() {
    const g = this.game;
    const fired = g.shotsFired | 0;
    const hit = g.shotsHit | 0;
    return {
      kills: g.kills | 0,
      headshots: g.headshots | 0,
      shotsHit: hit,
      shotsFired: fired,
      accuracy: fired > 0 ? hit / fired : 0,
      damageTaken: Math.round(g.damageTaken) | 0,
      raidMs: g.startedAt ? Math.max(0, performance.now() - g.startedAt) : 0,
    };
  }

  /** Slot-order list of owned weapons. Scroll and the HUD both walk this. */
  ownedWeapons() {
    return ['rifle', 'sniper', 'shotgun', 'pistol'].filter((id) => this.weapons[id]?.owned);
  }
}

export const gameState = new GameState();
