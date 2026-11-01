import { Enemy } from "./enemy";

export class GreenEnemy extends Enemy {
  private flickerFrequency = 0.02; // radians per ms
  private flickerSpeed = 40; // px/s at base resolution

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene, x, y, "green_enemy", {
      name: "GreenEnemy",
      speed: -320,
      health: 1,
      damage: 2,
      scoreValue: 8,
    });
  }

  override update(time: number, delta: number): void {
    super.update(time, delta);
    if (!this.body?.enable) return;

    // Fast, small vertical flicker (velocity-based so it is frame-rate independent).
    this.setVelocityY(
      Math.sin(time * this.flickerFrequency) *
        this.flickerSpeed *
        this.scene.responsive.scaleY
    );
  }
}
