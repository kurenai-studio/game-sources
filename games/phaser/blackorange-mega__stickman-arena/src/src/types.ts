/**
 * Data model for the game's content.
 *
 * Everything a designer needs to add or tweak a character or a stage lives in
 * the JSON files under `public/content/`. These interfaces describe the exact
 * shape those JSON files must follow, so the editor will warn you if a field is
 * missing or mistyped.
 */

/** A single melee attack a fighter can perform. */
export interface AttackDef {
  /** Display name, e.g. "Jab". */
  name: string;
  /** HP removed from the target on a clean hit. */
  damage: number;
  /** Stamina spent to perform the attack. No stamina => attack fails. */
  staminaCost: number;
  /** Horizontal reach in pixels from the fighter's center. */
  range: number;
  /** Minimum time between uses, in milliseconds. */
  cooldown: number;
}

/** Core numeric stats shared by every fighter. */
export interface FighterStats {
  maxHp: number;
  maxStamina: number;
  /** Stamina recovered per second while not attacking. */
  staminaRegen: number;
  /** Horizontal movement speed in pixels/second. */
  moveSpeed: number;
  /** Upward jump impulse (higher = jumps higher). */
  jumpVelocity: number;
}

/**
 * A complete character definition (playable hero OR enemy/boss).
 * One JSON file per character in `public/content/characters/`.
 */
export interface CharacterDef {
  /** Unique id, must match the filename and be referenced by stages. */
  id: string;
  name: string;
  description: string;
  /**
   * Path to the character image, relative to the `public/` folder.
   * Swap this for your own PNG/SVG to use a custom sprite.
   */
  sprite: string;
  /** Tint applied to the sprite as a hex string, e.g. "#ff5050". */
  tint?: string;
  stats: FighterStats;
  /** Light + heavy basic attacks. */
  attacks: {
    light: AttackDef;
    heavy: AttackDef;
  };
  /** A signature high-cost move. */
  special: AttackDef;
}

/** One stage / level in the campaign. */
export interface StageDef {
  /** 1-based stage number. */
  id: number;
  name: string;
  /** id of the CharacterDef used as this stage's opponent. */
  enemy: string;
  /**
   * Difficulty multiplier applied to the enemy's stats so the same character
   * can be reused as a tougher version in later stages. 1 = base stats.
   */
  difficulty: number;
  /** Background fill color for the arena, hex string. */
  background: string;
  /** Optional flavor text shown before the fight. */
  intro?: string;
}

/** The full campaign definition from `public/content/stages.json`. */
export interface CampaignDef {
  /** id of the CharacterDef the player controls. */
  player: string;
  stages: StageDef[];
}
