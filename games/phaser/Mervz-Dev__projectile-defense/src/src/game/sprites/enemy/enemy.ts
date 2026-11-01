export interface EnemyTraits {
  name?: string;
  speed?: number;
  health?: number;
  damage?: number;
  scoreValue?: number;
}

const HIT_FLASH_MS = 80;
const DEATH_TWEEN_MS = 120;

export class Enemy extends Phaser.Physics.Arcade.Sprite {
  protected traits: Required<EnemyTraits>;
  private isDying = false;

  constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    texture: string,
    traits: EnemyTraits = {}
  ) {
    super(scene, x, y, texture);

    scene.add.existing(this);
    scene.physics.add.existing(this);

    this.traits = {
      name: traits.name ?? "Enemy",
      speed: traits.speed ?? -150,
      health: traits.health ?? 1,
      damage: traits.damage ?? 1,
      scoreValue: traits.scoreValue ?? 100,
    };
  }

  /**
   * Must be called AFTER the enemy is added to its physics group: an Arcade
   * group applies its body defaults (velocity 0, immovable false, ...) to every
   * child it receives, which would undo anything set here beforehand.
   */
  public init(): void {
    this.setVelocityX(this.traits.speed * this.scene.responsive.scaleX);
    this.setBounce(0);
    this.setImmovable(true);
    this.setGravity(0, 0);
    this.setSize(this.width * 0.7, this.height * 0.7);
    this.setScale(this.scene.responsive.scaleFactor);
  }

  public takeDamage(
    amount: number = 1,
    onDestroy: (score: number) => void
  ): void {
    if (this.isDying) return;

    this.traits.health -= amount;

    if (this.traits.health > 0) {
      this.flash();
      return;
    }

    this.die(onDestroy);
  }

  public getDamage(): number {
    return this.traits.damage;
  }

  override update(_time: number, _delta: number): void {
    // Fallback cleanup if an enemy somehow slips past the left sensor.
    if (this.x < -this.displayWidth) {
      this.destroy();
    }
  }

  private flash(): void {
    // tintFill only renders on WebGL; the alpha dip shows on Canvas as well.
    this.setTintFill(0xffffff);
    this.setAlpha(0.5);
    this.scene.time.delayedCall(HIT_FLASH_MS, () => {
      if (!this.active) return;
      this.clearTint();
      this.setAlpha(1);
    });
  }

  private die(onDestroy: (score: number) => void): void {
    this.isDying = true;
    // Stop physics immediately so nothing else can hit it while it pops.
    this.disableBody(false, false);
    onDestroy(this.traits.scoreValue);

    this.scene.tweens.add({
      targets: this,
      scale: this.scale * 1.3,
      alpha: 0,
      duration: DEATH_TWEEN_MS,
      ease: "Quad.easeOut",
      onComplete: () => this.destroy(),
    });
  }
}
