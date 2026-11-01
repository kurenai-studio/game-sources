import { BULLET_DAMAGE, BULLET_SPEED } from "../../constants/gameplay";

export class Bullet extends Phaser.Physics.Arcade.Sprite {
  private damage = BULLET_DAMAGE;

  constructor(scene: Phaser.Scene, x: number, y: number, texture: string) {
    super(scene, x, y, texture);

    scene.add.existing(this);
    scene.physics.add.existing(this);
  }

  /** Must be called after the bullet is added to its physics group. */
  public init(): void {
    this.setVelocityX(BULLET_SPEED * this.scene.responsive.scaleX);
    this.setBounce(0);
    this.setImmovable(true);
    this.setGravity(0, 0);
    this.setScale(this.scene.responsive.scaleFactor);
  }

  public getDamage(): number {
    return this.damage;
  }

  override update(): void {
    if (this.x > this.scene.scale.width + this.displayWidth) {
      this.destroy();
    }
  }
}
