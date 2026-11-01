import { GAME_CONFIG } from '../config.js';
import { soundManager } from '../audio/SoundManager.js';

export class Hornet extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y) {
    super(scene, x, y, 'hornet_normal');
    this.hp = GAME_CONFIG.ENEMIES.HORNET.hp;
    this.scoreValue = GAME_CONFIG.ENEMIES.HORNET.score;
    this.state = 'FLYING'; // 'FLYING', 'DIVING', 'FLIP_ATTACK', 'ENTERING'
    this.diveTimer = 0;
    this.initialX = x;
    this.initialY = y;
    this.patrolTimer = Math.random() * 100;
    
    // 難度與行為參數
    this.speedMultiplier = 1.0;
    this.shootChance = 0.5;
    this.turnAroundChance = 0;
    this.hasTurnedAround = false; // 單次俯衝僅觸發一次甩尾回馬槍
    this.flipAttackTimer = 0;
  }

  spawn(x, y, difficulty = null) {
    this.enableBody(true, x, y, true, true);
    
    // 導入波次動態難度數值
    if (difficulty) {
      this.speedMultiplier = difficulty.speedMultiplier || 1.0;
      this.bulletSpeedMultiplier = difficulty.bulletSpeedMultiplier || 1.0;
      this.shootChance = difficulty.shootChance || 0.5;
      this.turnAroundChance = difficulty.turnAroundChance || 0;
      this.hp = GAME_CONFIG.ENEMIES.HORNET.hp + (difficulty.hpBonus || 0);
    } else {
      this.speedMultiplier = 1.0;
      this.bulletSpeedMultiplier = 1.0;
      this.shootChance = 0.5;
      this.turnAroundChance = 0;
      this.hp = GAME_CONFIG.ENEMIES.HORNET.hp;
    }

    this.state = 'FLYING';
    this.initialX = x;
    this.initialY = y;
    this.diveTimer = Phaser.Math.Between(2000, 6000);
    this.patrolTimer = Math.random() * 100;
    this.hasTurnedAround = false;
    this.setVelocity(0, 0);
    this.rotation = 0;
    this.alpha = 1;
    this.clearTint();
  }

  update(time, delta) {
    if (!this.active) return;

    if (this.state === 'FLYING') {
      this.patrolTimer += delta * 0.003;
      // 左右小幅編隊飄移
      this.x = this.initialX + Math.sin(this.patrolTimer) * 45;
      this.y = this.initialY + Math.cos(this.patrolTimer * 0.8) * 15;

      this.diveTimer -= delta;
      if (this.diveTimer <= 0) {
        this.startDive();
      }
    } else if (this.state === 'DIVING') {
      const player = this.scene.player;

      // 兇猛 AI 判定：當虎頭蜂越過玩家後方 (Y > player.y + 40)，判定是否發動「越位甩尾回馬槍」
      if (!this.hasTurnedAround && this.turnAroundChance > 0 && player && player.active && this.y > player.y + 40 && this.y < 600) {
        if (Math.random() < this.turnAroundChance) {
          this.startFlipAttack(player);
          return;
        } else {
          // 本次俯衝不再觸發
          this.hasTurnedAround = true;
        }
      }

      // 俯衝超出版面則平滑重返陣形 (ENTERING 狀態)
      if (this.y > 660) {
        this.startEntering();
      } else if (this.y < this.initialY && this.body.velocity.y > 0) {
        // 回到初始高度
        this.state = 'FLYING';
        this.hasTurnedAround = false;
        this.diveTimer = Phaser.Math.Between(2500, 6000);
        this.setVelocity(0, 0);
        this.rotation = 0;
      }
    } else if (this.state === 'FLIP_ATTACK') {
      // 甩尾回馬槍狀態計時 (維持 1.2 秒的背刺逆向狂暴衝鋒)
      this.flipAttackTimer -= delta;

      if (this.flipAttackTimer <= 0 || this.y < -30) {
        // 衝刺結束，由頂部平滑重返陣形
        this.startEntering();
      }
    } else if (this.state === 'ENTERING') {
      // 進場中由 Tween 控制平滑過渡，不接受任何射擊或回馬槍判定
    }
  }

  /**
   * 平滑進場歸隊 (T4 消除瞬移)
   * 從 y = -20 以平滑 easeOut 飛入陣形位置
   */
  startEntering() {
    this.state = 'ENTERING';
    this.hasTurnedAround = false;
    this.setVelocity(0, 0);
    this.rotation = 0;
    this.x = this.initialX;
    this.y = -25;

    this.scene.tweens.add({
      targets: this,
      y: this.initialY,
      duration: 650,
      ease: 'Quad.easeOut',
      onComplete: () => {
        if (!this.active) return;
        this.state = 'FLYING';
        this.diveTimer = Phaser.Math.Between(2500, 6000);
      }
    });
  }

  startDive() {
    this.state = 'DIVING';
    this.hasTurnedAround = false;
    const player = this.scene.player;
    if (player && player.active) {
      const angle = Phaser.Math.Angle.Between(this.x, this.y, player.x, player.y);
      this.rotation = angle - Math.PI / 2;
      const diveSpeed = GAME_CONFIG.ENEMIES.HORNET.speed * 1.5 * this.speedMultiplier;
      this.scene.physics.velocityFromRotation(angle, diveSpeed, this.body.velocity);
      
      // 俯衝瞬間依波次 shootChance 射出一發尾針
      if (Math.random() < this.shootChance) {
        const bulletSpeed = 200 * (this.bulletSpeedMultiplier || 1.0);
        this.scene.spawnEnemyBullet(this.x, this.y + 10, angle, bulletSpeed);
      }
    } else {
      this.setVelocity(0, GAME_CONFIG.ENEMIES.HORNET.speed * this.speedMultiplier);
    }
  }

  /**
   * 越位甩尾回馬槍 (Turn-around Backstab Attack)
   * 虎頭蜂越過玩家後急停轉身 180 度，朝小蜜蜂背部逆向狠毒刺擊！
   */
  startFlipAttack(player) {
    this.state = 'FLIP_ATTACK';
    this.hasTurnedAround = true;
    this.flipAttackTimer = 1200; // 衝刺持續 1.2 秒

    // 短暫減速並急轉身朝向小蜜蜂
    const backstabAngle = Phaser.Math.Angle.Between(this.x, this.y, player.x, player.y);
    this.rotation = backstabAngle - Math.PI / 2;

    // 回馬槍狂暴加速衝擊 (比一般俯衝更快 25%)
    const backstabSpeed = GAME_CONFIG.ENEMIES.HORNET.speed * 1.8 * this.speedMultiplier;
    this.scene.physics.velocityFromRotation(backstabAngle, backstabSpeed, this.body.velocity);

    // 回頭突刺時有 60% 機率逆向發射背刺尾針
    if (Math.random() < 0.6) {
      const bulletSpeed = 220 * (this.bulletSpeedMultiplier || 1.0);
      this.scene.spawnEnemyBullet(this.x, this.y - 10, backstabAngle, bulletSpeed);
    }

    // 發動甩尾時泛出短暫橙紅色兇猛光暈
    this.setTint(0xff5533);
    this.scene.time.delayedCall(300, () => {
      if (this.active) this.clearTint();
    });
  }

  takeDamage(amount) {
    // D4 規格最後防線：進場中 (ENTERING) 的工蜂完全免疫傷害
    if (this.state === 'ENTERING') return false;

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
