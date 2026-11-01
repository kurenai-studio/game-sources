import Phaser from 'phaser';
import {
  BOSS_HP,
  BOSS_SPEED,
  BOSS_DAMAGE,
  BOSS_FIRE_RATE,
  BOSS_BULLET_SPEED,
  GAME_HEIGHT,
} from '../config/game';

export class Boss extends Phaser.Physics.Arcade.Sprite {
  public hp: number;
  public maxHp: number;
  public damage: number;
  private lastFired = 0;
  private fireInterval: number;
  private moveDir = 1;
  private arrived = false;
  private targetX = 680; // stop near the right side of the screen

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene, x, y, 'boss');
    this.hp = BOSS_HP;
    this.maxHp = BOSS_HP;
    this.damage = BOSS_DAMAGE;
    this.fireInterval = 1000 / BOSS_FIRE_RATE;

    scene.add.existing(this);
    scene.physics.add.existing(this);

    this.setDepth(6);

    // Entrance: slide in from the right
    this.setVelocityX(-BOSS_SPEED);
  }

  update(time: number, _delta: number): void {
    // Slide left until reaching target X
    if (!this.arrived && this.x <= this.targetX) {
      this.arrived = true;
      this.setVelocityX(0);
      this.setVelocityY(BOSS_SPEED * this.moveDir);
    }

    if (this.arrived) {
      // Patrol up/down
      if (this.y < 80) {
        this.moveDir = 1;
        this.setVelocityY(BOSS_SPEED);
      } else if (this.y > GAME_HEIGHT - 80) {
        this.moveDir = -1;
        this.setVelocityY(-BOSS_SPEED);
      }
    }
  }

  fire(
    time: number,
    bulletGroup: Phaser.Physics.Arcade.Group,
    target: { x: number; y: number },
  ): void {
    if (!this.arrived) return;
    if (time < this.lastFired + this.fireInterval) return;

    const ox = this.x - 40;
    const oy = this.y;
    let dx = target.x - ox;
    let dy = target.y - oy;
    const len = Math.sqrt(dx * dx + dy * dy) || 1;
    dx /= len;
    dy /= len;

    const angles = this.hp <= this.maxHp * 0.5 ? [-0.25, 0, 0.25] : [0];

    for (const a of angles) {
      const cos = Math.cos(a);
      const sin = Math.sin(a);
      const vx = (dx * cos - dy * sin) * BOSS_BULLET_SPEED;
      const vy = (dx * sin + dy * cos) * BOSS_BULLET_SPEED;

      const bullet = bulletGroup.get(ox, oy) as Phaser.Physics.Arcade.Sprite | null;
      if (bullet) {
        bullet.setActive(true).setVisible(true);
        (bullet.body as Phaser.Physics.Arcade.Body).enable = true;
        bullet.setPosition(ox, oy);
        bullet.setVelocity(vx, vy);
        this.scene.time.delayedCall(4000, () => {
          if (bullet.active) {
            bullet.setActive(false).setVisible(false);
            (bullet.body as Phaser.Physics.Arcade.Body).enable = false;
          }
        });
      }
    }
    this.lastFired = time;
  }

  takeDamage(amount: number): boolean {
    this.hp -= amount;
    this.setTint(0xff0000);
    this.scene.time.delayedCall(60, () => this.clearTint());
    return this.hp <= 0;
  }
}
