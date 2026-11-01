import { GAME_CONFIG } from '../config.js';
import { soundManager } from '../audio/SoundManager.js';
import { shouldSummonMinions } from '../logic/minionCap.js';

export class QueenBoss extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y) {
    super(scene, x, y, 'hornet_queen');
    this.maxHp = GAME_CONFIG.ENEMIES.QUEEN.hp;
    this.hp = this.maxHp;
    this.scoreValue = GAME_CONFIG.ENEMIES.QUEEN.score;
    this.patternTimer = 0;
    this.spiralAngle = 0;
    this.isEnraged = false;
    this.speedMultiplier = 1.0;
  }

  spawn(x, y, difficulty = null) {
    this.enableBody(true, x, y, true, true);
    if (difficulty) {
      this.speedMultiplier = difficulty.speedMultiplier || 1.0;
      // Boss 血量隨波次加成（第 6 波、第 9 波等輪替登場時更耐打）
      const extraHp = Math.max(0, difficulty.wave - 3) * 60;
      this.maxHp = GAME_CONFIG.ENEMIES.QUEEN.hp + extraHp;
    } else {
      this.speedMultiplier = 1.0;
      this.maxHp = GAME_CONFIG.ENEMIES.QUEEN.hp;
    }

    this.hp = this.maxHp;
    this.isEnraged = false;
    this.setVelocity(80 * this.speedMultiplier, 0);
    this.patternTimer = 1000;
    this.alpha = 1;
    this.setScale(1.2);
    this.clearTint();
  }

  update(time, delta) {
    if (!this.active) return;

    // 左右來回移動
    const moveSpeed = (this.isEnraged ? 140 : 80) * this.speedMultiplier;
    if (this.x < 80) {
      this.setVelocityX(moveSpeed);
    } else if (this.x > 400) {
      this.setVelocityX(-moveSpeed);
    }

    // 狂暴判斷 (HP < 40%)
    if (!this.isEnraged && this.hp < this.maxHp * 0.4) {
      this.isEnraged = true;
      this.setTint(0xff3333);
      soundManager.playUpgrade();
    }

    // 招式輪迴
    this.patternTimer -= delta;
    if (this.patternTimer <= 0) {
      this.patternTimer = (this.isEnraged ? 1000 : 1800) / this.speedMultiplier;
      this.castSkill();
    }
  }

  castSkill() {
    if (!this.active) return;
    const rnd = Math.random();

    if (rnd < 0.5) {
      // 招式 1: 8 方向螺旋擴散彈幕
      const bulletSpeed = 180 * this.speedMultiplier;
      for (let i = 0; i < 8; i++) {
        const rad = this.spiralAngle + (i * Math.PI) / 4;
        this.scene.spawnEnemyBullet(this.x, this.y + 20, rad, bulletSpeed);
      }
      this.spiralAngle += 0.25;
    } else if (rnd < 0.8) {
      // 招式 2: 直衝玩家的扇形追蹤尾針
      if (this.scene.player && this.scene.player.active) {
        const baseAngle = Phaser.Math.Angle.Between(this.x, this.y, this.scene.player.x, this.scene.player.y);
        const bulletSpeed = 260 * this.speedMultiplier;
        [-0.2, 0, 0.2].forEach(offset => {
          this.scene.spawnEnemyBullet(this.x, this.y + 20, baseAngle + offset, bulletSpeed);
        });
      }
    } else {
      // 招式 3: 召喚兩隻工蜂護衛（限定計算此 Boss 召喚的 isBossMinion 護衛，上限 4 隻，由 shouldSummonMinions 守護）
      const activeBossMinions = this.scene.enemyGroup.getChildren().slice().filter(e => e.active && e.isBossMinion).length;
      if (shouldSummonMinions(activeBossMinions, 4)) {
        this.scene.spawnHornetMinion(this.x - 40, this.y);
        this.scene.spawnHornetMinion(this.x + 40, this.y);
      }
    }
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
    soundManager.playExplosion(true);
    this.scene.onQueenDefeated(this);
    this.destroy();
  }
}
