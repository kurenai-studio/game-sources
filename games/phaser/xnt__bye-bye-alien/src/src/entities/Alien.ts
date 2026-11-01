import Phaser from 'phaser';
import {
  ALIEN_SPEED,
  ALIEN_HP,
  ALIEN_FIRE_RATE,
  ALIEN_BULLET_SPEED,
  ALIEN_DAMAGE,
  GAME_HEIGHT,
} from '../config/game';

export class Alien extends Phaser.Physics.Arcade.Sprite {
  public hp: number;
  public damage: number;
  private lastFired = 0;
  private fireInterval: number;
  private moveDir = 1;

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene, x, y, 'alien');
    this.hp = ALIEN_HP;
    this.damage = ALIEN_DAMAGE;
    this.fireInterval = 1000 / ALIEN_FIRE_RATE;

    scene.add.existing(this);
    scene.physics.add.existing(this);

    // Move left (towards the player)
    this.setVelocityX(-ALIEN_SPEED);

    // Slight vertical drift
    this.moveDir = Math.random() > 0.5 ? 1 : -1;
    this.setVelocityY(this.moveDir * (30 + Math.random() * 50));

    this.setDepth(5);
  }

  update(time: number, _delta: number): void {
    // Bounce off top/bottom edges
    if (this.y < 30) {
      this.moveDir = 1;
      this.setVelocityY(Math.abs(this.body!.velocity.y));
    } else if (this.y > GAME_HEIGHT - 30) {
      this.moveDir = -1;
      this.setVelocityY(-Math.abs(this.body!.velocity.y));
    }

    // Deactivate when past left edge of screen
    if (this.x < -50) {
      this.destroy();
    }
  }

  fire(
    time: number,
    bulletGroup: Phaser.Physics.Arcade.Group,
  ): void {
    if (time < this.lastFired + this.fireInterval) return;

    const bullet = bulletGroup.get(this.x - 18, this.y) as Phaser.Physics.Arcade.Sprite | null;
    if (bullet) {
      bullet.setActive(true).setVisible(true);
      (bullet.body as Phaser.Physics.Arcade.Body).enable = true;
      bullet.setPosition(this.x - 18, this.y);
      bullet.setVelocityX(-ALIEN_BULLET_SPEED);
      bullet.setVelocityY(0);
      this.lastFired = time;

      // auto-cleanup
      this.scene.time.delayedCall(3000, () => {
        if (bullet.active) {
          bullet.setActive(false).setVisible(false);
          (bullet.body as Phaser.Physics.Arcade.Body).enable = false;
        }
      });
    }
  }

  takeDamage(amount: number): boolean {
    this.hp -= amount;
    this.setTint(0xff0000);
    this.scene.time.delayedCall(60, () => this.clearTint());
    return this.hp <= 0;
  }
}
