import { GAME_CONFIG } from '../config.js';
import { soundManager } from '../audio/SoundManager.js';

export class ArmoredHornet extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y) {
    super(scene, x, y, 'hornet_armored');
    this.hp = GAME_CONFIG.ENEMIES.ARMORED.hp;
    this.scoreValue = GAME_CONFIG.ENEMIES.ARMORED.score;
    this.shootTimer = 0;
    this.speedMultiplier = 1.0;
  }

  spawn(x, y, difficulty = null) {
    this.enableBody(true, x, y, true, true);
    if (difficulty) {
      this.speedMultiplier = difficulty.speedMultiplier || 1.0;
      this.hp = GAME_CONFIG.ENEMIES.ARMORED.hp + (difficulty.hpBonus || 0) * 2;
    } else {
      this.speedMultiplier = 1.0;
      this.hp = GAME_CONFIG.ENEMIES.ARMORED.hp;
    }

    const vx = Phaser.Math.Between(-45, 45) * this.speedMultiplier;
    const vy = GAME_CONFIG.ENEMIES.ARMORED.speed * this.speedMultiplier;
    this.setVelocity(vx, vy);
    this.shootTimer = Phaser.Math.Between(1000, 2500);
    this.alpha = 1;
    this.clearTint();
  }

  update(time, delta) {
    if (!this.active) return;

    // 動態讀取物理世界邊界
    const bounds = this.scene.physics.world.bounds;

    // 碰壁反彈
    if (this.x < bounds.x + 30) {
      this.setVelocityX(Math.abs(this.body.velocity.x) || (40 * this.speedMultiplier));
    } else if (this.x > bounds.width - 30) {
      this.setVelocityX(-Math.abs(this.body.velocity.x) || (-40 * this.speedMultiplier));
    }

    // 抵達底部重回頂端
    if (this.y > bounds.height + 30) {
      this.y = bounds.y - 30;
      this.x = Phaser.Math.Between(bounds.x + 40, bounds.width - 40);
    }

    // 定期發射三向毒針
    this.shootTimer -= delta;
    if (this.shootTimer <= 0) {
      this.shootTimer = Phaser.Math.Between(2000, 3200) / this.speedMultiplier;
      this.fireSpread();
    }
  }

  fireSpread() {
    if (!this.active || this.y < 30 || this.y > 550) return;
    const bulletSpeed = 240 * this.speedMultiplier;
    const angles = [Math.PI / 2 - 0.35, Math.PI / 2, Math.PI / 2 + 0.35];
    angles.forEach(rad => {
      this.scene.spawnEnemyBullet(this.x, this.y + 15, rad, bulletSpeed);
    });
  }

  takeDamage(amount) {
    this.hp -= amount;
    this.scene.showHitFlash(this);
    if (this.hp <= 0) {
      this.die();
      return true;
    }
    return false;
  }

  die() {
    soundManager.playExplosion(false);
    this.scene.onEnemyKilled(this);
    this.destroy();
  }
}
