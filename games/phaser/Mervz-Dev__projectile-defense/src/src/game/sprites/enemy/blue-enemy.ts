import { Enemy } from "./enemy";

export class BlueEnemy extends Enemy {
  private waveFrequency = 0.004; // radians per ms
  private waveSpeed = 60; // px/s at base resolution

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene, x, y, "blue_enemy", {
      name: "WaterEnemy",
      speed: -120,
      health: 4,
      damage: 1,
      scoreValue: 12,
    });
  }

  override update(time: number, delta: number): void {
    super.update(time, delta);
    if (!this.body?.enable) return;

    // Slow, wide vertical wave (velocity-based so it is frame-rate independent).
    this.setVelocityY(
      Math.sin(time * this.waveFrequency) *
        this.waveSpeed *
        this.scene.responsive.scaleY
    );
  }
}
