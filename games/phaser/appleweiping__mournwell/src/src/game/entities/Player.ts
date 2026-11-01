import Phaser from 'phaser';
import { DIRECTION_VECTOR, type Direction, type PlayerStats } from '@/game/types';
import { GameInput } from '@/game/systems/input';

export class PlayerEntity extends Phaser.Physics.Arcade.Sprite {
  readonly controls: GameInput;
  facing: Direction = 'south';
  nextShotAt = 0;
  invulnerableUntil = 0;
  private knockbackUntil = 0;
  private readonly getStats: () => PlayerStats;
  private readonly requestShot: (direction: Direction) => void;

  constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    getStats: () => PlayerStats,
    requestShot: (direction: Direction) => void,
  ) {
    super(scene, x, y, 'player');
    scene.add.existing(this);
    scene.physics.add.existing(this);
    this.getStats = getStats;
    this.requestShot = requestShot;
    this.controls = new GameInput(scene);
    this.setDepth(20);
    this.setCircle(16, 16, 18);
    this.setDrag(900, 900);
    this.setMaxVelocity(350, 350);
  }

  updateControl(time: number): void {
    if (!this.active || !this.body) return;
    const stats = this.getStats();
    const movement = this.controls.movement();
    if (time >= this.knockbackUntil)
      this.setVelocity(movement.x * stats.moveSpeed, movement.y * stats.moveSpeed);
    if (Math.abs(movement.x) > 0.01) this.setFlipX(movement.x < 0);
    this.setRotation(Math.sin(time / 170) * 0.018 * Math.min(1, Math.hypot(movement.x, movement.y)));

    const shooting = this.controls.shooting();
    if (shooting) {
      this.facing = shooting;
      if (time >= this.nextShotAt) {
        this.nextShotAt = time + stats.fireInterval;
        this.requestShot(shooting);
      }
    }

    if (time < this.invulnerableUntil) {
      this.setAlpha(Math.floor(time / 75) % 2 === 0 ? 0.38 : 1);
    } else {
      this.setAlpha(1);
    }
  }

  nudge(direction: Direction, distance = 12): void {
    const vector = DIRECTION_VECTOR[direction];
    this.x += vector.x * distance;
    this.y += vector.y * distance;
  }

  isInvulnerable(time: number): boolean {
    return time < this.invulnerableUntil;
  }

  setInvulnerable(time: number): void {
    this.invulnerableUntil = time;
  }

  applyKnockback(velocityX: number, velocityY: number, until: number): void {
    this.knockbackUntil = until;
    this.setVelocity(velocityX, velocityY);
  }

  override destroy(fromScene?: boolean): void {
    this.controls.destroy();
    super.destroy(fromScene);
  }
}
