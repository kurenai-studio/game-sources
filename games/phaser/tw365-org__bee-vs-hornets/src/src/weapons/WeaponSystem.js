import { GAME_CONFIG } from '../config.js';
import { Bullet } from './Bullet.js';
import { soundManager } from '../audio/SoundManager.js';

export class WeaponSystem {
  constructor(scene) {
    this.scene = scene;
    this.currentLevel = 0;
    this.lastFiredTime = 0;

    // 建立子彈物件群組 (Pool)
    this.bullets = scene.physics.add.group({
      classType: Bullet,
      maxSize: 60,
      runChildUpdate: true
    });
  }

  // 依當前分數檢查並升級武器
  checkUpgrade(score) {
    let targetLevel = 0;
    if (score >= GAME_CONFIG.WEAPONS.LV3.scoreRequired) {
      targetLevel = 3;
    } else if (score >= GAME_CONFIG.WEAPONS.LV2.scoreRequired) {
      targetLevel = 2;
    } else if (score >= GAME_CONFIG.WEAPONS.LV1.scoreRequired) {
      targetLevel = 1;
    }

    if (targetLevel > this.currentLevel) {
      this.currentLevel = targetLevel;
      soundManager.playUpgrade();
      return this.getCurrentWeaponConfig();
    }
    return null;
  }

  getCurrentWeaponConfig() {
    switch (this.currentLevel) {
      case 1: return GAME_CONFIG.WEAPONS.LV1;
      case 2: return GAME_CONFIG.WEAPONS.LV2;
      case 3: return GAME_CONFIG.WEAPONS.LV3;
      default: return GAME_CONFIG.WEAPONS.LV0;
    }
  }

  // 發射武器
  fire(x, y, time) {
    const cfg = this.getCurrentWeaponConfig();
    if (time < this.lastFiredTime + cfg.fireRate) {
      return false;
    }
    this.lastFiredTime = time;

    switch (this.currentLevel) {
      case 0: // 雙針 (Dual Needles)
        this.spawnBullet(x - 8, y - 10, 0, -cfg.speed, cfg.damage, 'bullet_needle');
        this.spawnBullet(x + 8, y - 10, 0, -cfg.speed, cfg.damage, 'bullet_needle');
        break;

      case 1: // 5 向散彈 (Nectar Spread)
        cfg.spreadAngles.forEach(deg => {
          const rad = Phaser.Math.DegToRad(deg - 90);
          const vx = Math.cos(rad) * cfg.speed;
          const vy = Math.sin(rad) * cfg.speed;
          this.spawnBullet(x, y - 10, vx, vy, cfg.damage, 'bullet_spread');
        });
        break;

      case 2: // 雙針 + 2枚導彈 (Stalker Missiles)
        this.spawnBullet(x - 6, y - 10, 0, -cfg.speed, 18, 'bullet_needle');
        this.spawnBullet(x + 6, y - 10, 0, -cfg.speed, 18, 'bullet_needle');
        
        // 尋找最近敵人
        const target1 = this.findNearestEnemy(x - 20, y);
        const target2 = this.findNearestEnemy(x + 20, y);
        this.spawnBullet(x - 16, y, -80, -220, cfg.damage, 'bullet_missile', false, true, target1);
        this.spawnBullet(x + 16, y, 80, -220, cfg.damage, 'bullet_missile', false, true, target2);
        break;

      case 3: // 等離子重砲 (Plasma Cannon) + 雙軌護航散彈
        this.spawnBullet(x, y - 18, 0, -cfg.speed, cfg.damage, 'bullet_plasma', true);
        this.spawnBullet(x - 14, y, -120, -cfg.speed * 0.9, 20, 'bullet_spread');
        this.spawnBullet(x + 14, y, 120, -cfg.speed * 0.9, 20, 'bullet_spread');
        break;
    }

    soundManager.playShoot(this.currentLevel);
    return true;
  }

  spawnBullet(x, y, vx, vy, damage, texture, piercing = false, isMissile = false, target = null) {
    let bullet = this.bullets.get();
    if (!bullet) {
      bullet = new Bullet(this.scene, x, y, texture);
      this.bullets.add(bullet, true);
    }
    bullet.setTexture(texture);
    bullet.fire(x, y, vx, vy, damage, piercing, isMissile, target);
    return bullet;
  }

  findNearestEnemy(x, y) {
    if (!this.scene.enemyGroup) return null;
    let nearest = null;
    let minDist = Infinity;
    this.scene.enemyGroup.getChildren().slice().forEach(enemy => {
      if (enemy.active && enemy.y > 0 && enemy.y < 580) {
        const d = Phaser.Math.Distance.Between(x, y, enemy.x, enemy.y);
        if (d < minDist) {
          minDist = d;
          nearest = enemy;
        }
      }
    });
    return nearest;
  }
}
