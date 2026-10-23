import Phaser from "phaser";
import { GRAVITY_Y, GROUND_Y } from "./config";
import { GameContent } from "./ContentLoader";
import type { AttackDef, CharacterDef, FighterStats } from "./types";

export type AttackKind = "light" | "heavy" | "special";

/**
 * A single combatant (player or enemy). Wraps a physics sprite and tracks the
 * live battle state: HP, stamina, attack cooldowns, and facing.
 */
export class Fighter extends Phaser.Physics.Arcade.Sprite {
  readonly def: CharacterDef;
  /** Stats after the stage difficulty multiplier is applied. */
  readonly stats: FighterStats;

  hp: number;
  stamina: number;
  /** +1 faces right, -1 faces left. */
  facing: 1 | -1 = 1;
  /** True while actively blocking (reduces incoming damage, drains stamina). */
  guarding = false;

  private guardVisual: Phaser.GameObjects.Ellipse;

  private cooldowns: Record<AttackKind, number> = { light: 0, heavy: 0, special: 0 };
  /** Remaining time the fighter is locked in an attack animation. */
  private attackLock = 0;
  /** The active attack while attackLock > 0 (used for hit detection timing). */
  private pendingHit?: { kind: AttackKind; attack: AttackDef; resolved: boolean };

  constructor(scene: Phaser.Scene, x: number, def: CharacterDef, difficulty: number) {
    super(scene, x, GROUND_Y, GameContent.textureKey(def));
    scene.add.existing(this);
    scene.physics.add.existing(this);

    this.def = def;
    this.stats = Fighter.scaleStats(def.stats, difficulty);
    this.hp = this.stats.maxHp;
    this.stamina = this.stats.maxStamina;

    this.setOrigin(0.5, 1); // feet at y
    if (def.tint) this.setTint(Phaser.Display.Color.HexStringToColor(def.tint).color);

    // A translucent shield shown while guarding; positioned each frame.
    this.guardVisual = scene.add
      .ellipse(x, GROUND_Y - 96, 46, 120, 0x66ccff, 0.28)
      .setStrokeStyle(3, 0x66ccff, 0.85)
      .setDepth(5)
      .setVisible(false);

    const body = this.body as Phaser.Physics.Arcade.Body;
    body.setGravityY(GRAVITY_Y);
    body.setCollideWorldBounds(true);
    body.setSize(this.width * 0.5, this.height * 0.92);
  }

  /** Multiply offensive/defensive stats so a character can scale across stages. */
  private static scaleStats(base: FighterStats, difficulty: number): FighterStats {
    return {
      maxHp: Math.round(base.maxHp * difficulty),
      maxStamina: base.maxStamina,
      staminaRegen: base.staminaRegen,
      moveSpeed: Math.round(base.moveSpeed * (1 + (difficulty - 1) * 0.25)),
      jumpVelocity: base.jumpVelocity,
    };
  }

  get isAlive(): boolean {
    return this.hp > 0;
  }

  get isAttacking(): boolean {
    return this.attackLock > 0;
  }

  private get onGround(): boolean {
    return (this.body as Phaser.Physics.Arcade.Body).blocked.down;
  }

  /** Can only raise a guard while grounded, not attacking, and with stamina. */
  get canGuard(): boolean {
    return this.stamina > 5 && this.onGround && !this.isAttacking;
  }

  /** Request the guard on/off. Ignored if the fighter can't currently guard. */
  setGuard(on: boolean): void {
    this.guarding = on && this.canGuard;
  }

  /** Turn to face a world x coordinate (usually the opponent). */
  faceTowards(x: number): void {
    this.facing = x >= this.x ? 1 : -1;
    this.setFlipX(this.facing === -1);
  }

  moveHorizontally(dir: -1 | 0 | 1): void {
    // Rooted in place while attacking or blocking.
    if (this.isAttacking || this.guarding) {
      this.setVelocityX(0);
      return;
    }
    this.setVelocityX(dir * this.stats.moveSpeed);
  }

  jump(): void {
    if (this.onGround && !this.isAttacking && !this.guarding) {
      this.setVelocityY(-this.stats.jumpVelocity);
    }
  }

  /** Attempt an attack. Returns false if on cooldown, guarding, or out of stamina. */
  tryAttack(kind: AttackKind): boolean {
    if (this.isAttacking || this.guarding) return false;
    if (this.cooldowns[kind] > 0) return false;

    const attack = this.attackFor(kind);
    if (this.stamina < attack.staminaCost) return false;

    this.stamina -= attack.staminaCost;
    this.cooldowns[kind] = attack.cooldown;
    this.attackLock = kind === "special" ? 420 : 260;
    this.pendingHit = { kind, attack, resolved: false };
    this.setVelocityX(0);

    // A small lunge + color pop for feedback.
    this.scene.tweens.add({
      targets: this,
      x: this.x + this.facing * 22,
      duration: 110,
      yoyo: true,
      ease: "Quad.easeOut",
    });
    return true;
  }

  private attackFor(kind: AttackKind): AttackDef {
    return kind === "special" ? this.def.special : this.def.attacks[kind];
  }

  /**
   * If this fighter is mid-attack and the strike frame has landed, returns the
   * attack to resolve against a target (once). Otherwise undefined.
   */
  takeActiveHit(): AttackDef | undefined {
    if (!this.pendingHit || this.pendingHit.resolved) return undefined;
    // Resolve at the midpoint of the attack lock — the "contact" frame.
    if (this.attackLock <= (this.pendingHit.kind === "special" ? 210 : 130)) {
      this.pendingHit.resolved = true;
      return this.pendingHit.attack;
    }
    return undefined;
  }

  /**
   * Apply incoming damage. A raised guard cuts damage and knockback sharply but
   * chips away stamina. Returns the damage actually dealt and whether it was
   * blocked, so the scene can draw the right feedback.
   */
  receiveDamage(amount: number, fromDir: 1 | -1): { damage: number; guarded: boolean } {
    if (!this.isAlive) return { damage: 0, guarded: false };

    const guarded = this.guarding;
    const dealt = guarded ? Math.max(1, Math.round(amount * 0.3)) : amount;
    this.hp = Math.max(0, this.hp - dealt);

    if (guarded) {
      // Blocking bleeds stamina; enough chip damage breaks the guard.
      this.stamina = Math.max(0, this.stamina - 14);
      if (this.stamina <= 0) this.guarding = false;
      this.setVelocityX(fromDir * 60);
    } else {
      this.setVelocityX(fromDir * 160);
      this.setVelocityY(-160);
      this.scene.tweens.add({
        targets: this,
        alpha: 0.35,
        duration: 60,
        yoyo: true,
        repeat: 2,
        onComplete: () => this.setAlpha(1),
      });
    }

    if (!this.isAlive) {
      this.setVelocityX(0);
      this.guarding = false;
      this.setAngle(this.facing === 1 ? -90 : 90); // topple over
    }
    return { damage: dealt, guarded };
  }

  /** Per-frame update: tick cooldowns, regen stamina, keep upright. */
  preUpdate(time: number, delta: number): void {
    super.preUpdate(time, delta);
    if (!this.isAlive) {
      this.guardVisual.setVisible(false);
      return;
    }

    for (const k of Object.keys(this.cooldowns) as AttackKind[]) {
      this.cooldowns[k] = Math.max(0, this.cooldowns[k] - delta);
    }
    if (this.attackLock > 0) this.attackLock = Math.max(0, this.attackLock - delta);

    // Holding guard steadily drains stamina; running dry drops it.
    if (this.guarding) {
      this.stamina = Math.max(0, this.stamina - (20 * delta) / 1000);
      if (this.stamina <= 0) this.guarding = false;
    }

    // Regenerate stamina only when neither attacking nor guarding.
    if (!this.isAttacking && !this.guarding && this.stamina < this.stats.maxStamina) {
      this.stamina = Math.min(
        this.stats.maxStamina,
        this.stamina + (this.stats.staminaRegen * delta) / 1000
      );
    }

    // Keep the shield glued to the front of the fighter.
    this.guardVisual.setVisible(this.guarding);
    this.guardVisual.setPosition(this.x + this.facing * 22, this.y - 96);
  }
}
