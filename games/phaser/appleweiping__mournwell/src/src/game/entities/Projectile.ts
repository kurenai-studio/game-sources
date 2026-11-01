import Phaser from 'phaser';
import type { EnemyEntity } from '@/game/entities/Enemy';

export type ProjectileOwner = 'player' | 'enemy';

export class ProjectileEntity extends Phaser.Physics.Arcade.Image {
  readonly owner: ProjectileOwner;
  damage: number;
  readonly maxDistance: number;
  readonly homing: number;
  remainingPierce: number;
  private readonly launchX: number;
  private readonly launchY: number;
  private readonly hitIds = new Set<string>();

  constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    texture: string,
    options: {
      owner: ProjectileOwner;
      damage: number;
      velocityX: number;
      velocityY: number;
      maxDistance: number;
      pierce?: number;
      homing?: number;
      scale?: number;
    },
  ) {
    super(scene, x, y, texture);
    scene.add.existing(this);
    scene.physics.add.existing(this);
    this.owner = options.owner;
    this.damage = options.damage;
    this.maxDistance = options.maxDistance;
    this.remainingPierce = options.pierce ?? 0;
    this.homing = options.homing ?? 0;
    this.launchX = x;
    this.launchY = y;
    this.setVelocity(options.velocityX, options.velocityY);
    this.setScale(options.scale ?? 1);
    this.setDepth(16);
    this.setCircle(Math.max(3, this.width * 0.32), this.width * 0.18, this.height * 0.18);
    this.setDataEnabled();
  }

  updateMotion(delta: number, enemies: readonly EnemyEntity[]): void {
    if (!this.active) return;
    if (this.homing > 0 && this.owner === 'player' && enemies.length > 0) {
      let closest: EnemyEntity | undefined;
      let distance = 280;
      for (const enemy of enemies) {
        if (!enemy.active) continue;
        const candidate = Phaser.Math.Distance.Between(this.x, this.y, enemy.x, enemy.y);
        if (candidate < distance) {
          distance = candidate;
          closest = enemy;
        }
      }
      if (closest) {
        const body = this.body as Phaser.Physics.Arcade.Body;
        const speed = body.velocity.length();
        const current = body.velocity.angle();
        const desired = Phaser.Math.Angle.Between(this.x, this.y, closest.x, closest.y);
        const maxTurn = this.homing * (delta / 1000) * Math.PI * 2;
        const angle = Phaser.Math.Angle.RotateTo(current, desired, maxTurn);
        this.setVelocity(Math.cos(angle) * speed, Math.sin(angle) * speed);
      }
    }
    if (Phaser.Math.Distance.Between(this.launchX, this.launchY, this.x, this.y) > this.maxDistance)
      this.destroy();
  }

  consumeHit(entityId: string): boolean {
    if (this.hitIds.has(entityId)) return false;
    this.hitIds.add(entityId);
    if (this.remainingPierce <= 0) {
      this.destroy();
    } else {
      this.remainingPierce -= 1;
      this.damage *= 0.85;
    }
    return true;
  }
}
