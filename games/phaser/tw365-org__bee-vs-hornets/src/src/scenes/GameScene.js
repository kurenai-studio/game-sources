import { GAME_CONFIG } from '../config.js';
import { Player } from '../entities/Player.js';
import { Hornet } from '../entities/Hornet.js';
import { ArmoredHornet } from '../entities/ArmoredHornet.js';
import { QueenBoss } from '../entities/QueenBoss.js';
import { WeaponSystem } from '../weapons/WeaponSystem.js';
import { WaveDifficultyManager } from '../systems/WaveDifficultyManager.js';
import { detonatePollen, buzzardStrike } from '../logic/abilities.js';
import { createOnceHitTracker } from '../logic/onceHitTracker.js';
import { HUD } from '../ui/HUD.js';
import { soundManager } from '../audio/SoundManager.js';

export class GameScene extends Phaser.Scene {
  constructor() {
    super('GameScene');
  }

  create() {
    this.score = 0;
    this.wave = 1;
    this.bossActive = false;
    this.currentBoss = null;
    this.stars = [];
    this.difficultyManager = new WaveDifficultyManager(this);

    // 1. 動態視差星空背景
    this.createStarfield();

    // 2. 玩家實體
    this.player = new Player(this, 240, 560);

    // 3. 重武器系統
    this.weaponSystem = new WeaponSystem(this);

    // 4. 敵機與子彈群組（子彈啟用物件池 maxSize 與回收機制）
    this.enemyGroup = this.physics.add.group({ runChildUpdate: true });
    this.enemyBulletGroup = this.physics.add.group({
      maxSize: 80,
      runChildUpdate: false
    });

    // 5. 原生高性能粒子發射器（零 GC 浪費）
    this.sparkParticles = this.add.particles(0, 0, 'particle_spark', {
      speed: { min: -120, max: 120 },
      scale: { start: 1, end: 0 },
      alpha: { start: 1, end: 0 },
      lifespan: { min: 250, max: 450 },
      emitting: false
    }).setDepth(150);

    this.pollenParticles = this.add.particles(0, 0, 'particle_pollen', {
      speed: { min: -180, max: 180 },
      scale: { start: 2.2, end: 0.2 },
      alpha: { start: 1, end: 0 },
      lifespan: { min: 500, max: 1000 },
      emitting: false
    }).setDepth(210);

    // 6. 抬頭顯示器 HUD
    this.hud = new HUD(this);
    this.hud.updateScore(this.score);
    this.hud.updateWeapon(this.weaponSystem.getCurrentWeaponConfig());
    this.hud.updateHp(this.player.hp, this.player.maxHp);
    this.hud.updateBombs(this.player.bombs);

    // 7. 彩蛋掉落物群組 (特級蜂露 Royal Pollen Dew)
    this.dropsGroup = this.physics.add.group();
    this.physics.add.overlap(this.player, this.dropsGroup, this.handleCollectDew, null, this);
    this.buzzardCooldown = 0; // 蜂鷹救援冷卻時間
    this.bossFightTimer = 0;  // Boss 膠著計時器

    // 8. 物理碰撞監聽
    this.physics.add.overlap(
      this.weaponSystem.bullets,
      this.enemyGroup,
      this.handleBulletHitEnemy,
      null,
      this
    );

    this.physics.add.overlap(
      this.player,
      this.enemyGroup,
      this.handlePlayerHitEnemy,
      null,
      this
    );

    this.physics.add.overlap(
      this.player,
      this.enemyBulletGroup,
      this.handlePlayerHitBullet,
      null,
      this
    );

    // 7. 啟動波次敵人生成器
    this.spawnNextWave();
  }

  createStarfield() {
    for (let i = 0; i < 50; i++) {
      const star = this.add.rectangle(
        Phaser.Math.Between(0, 480),
        Phaser.Math.Between(0, 640),
        Phaser.Math.Between(1, 2),
        Phaser.Math.Between(1, 3),
        0xffffff,
        Math.random() * 0.8 + 0.2
      );
      star.speed = Phaser.Math.Between(30, 140);
      this.stars.push(star);
    }
  }

  update(time, delta) {
    // 捲動星空
    this.stars.forEach(s => {
      s.y += (s.speed * delta) / 1000;
      if (s.y > 640) {
        s.y = 0;
        s.x = Phaser.Math.Between(0, 480);
      }
    });

    // 更新玩家
    if (this.player && this.player.active) {
      this.player.update(time, delta);
      this.hud.updateHp(this.player.hp, this.player.maxHp);
    }

    // 清理越界的敵方子彈（快照遍歷安全回收進物件池，零 GC 負擔）
    const bounds = this.physics.world.bounds;
    this.enemyBulletGroup.getChildren().slice().forEach(b => {
      if (b.active && (b.y > bounds.height + 30 || b.y < bounds.y - 30 || b.x < bounds.x - 30 || b.x > bounds.width + 30)) {
        b.setActive(false);
        b.setVisible(false);
        b.body.stop();
      }
    });

    // 檢查波次敵人是否已清空
    if (!this.bossActive && this.enemyGroup.countActive(true) === 0) {
      this.wave++;
      this.spawnNextWave();
    }

    // 蜂鷹救援冷卻遞減
    if (this.buzzardCooldown > 0) {
      this.buzzardCooldown -= delta;
    }

    // Boss 戰膠著計時
    if (this.bossActive) {
      this.bossFightTimer += delta;
    } else {
      this.bossFightTimer = 0;
    }

    // 檢查天敵彩蛋救援條件：玩家 HP <= 25% 或 Boss 膠著超過 30 秒
    if (this.buzzardCooldown <= 0 && this.player && this.player.active) {
      const isCriticalHp = this.player.hp <= this.player.maxHp * 0.25 && this.enemyGroup.countActive(true) > 0;
      const isBossStalemate = this.bossActive && this.bossFightTimer > 30000;

      if (isCriticalHp || isBossStalemate) {
        this.summonHoneyBuzzard();
      }
    }

    // 更新特級蜂露掉落物 (緩慢旋轉飄落，以 slice 快照安全銷毀)
    this.dropsGroup.getChildren().slice().forEach(drop => {
      if (drop.active && drop.y > bounds.height + 20) {
        drop.destroy();
      }
    });
  }

  spawnNextWave() {
    const diff = this.difficultyManager.getDifficulty(this.wave);

    if (diff.isBossWave) {
      // 每 3 波出現一次女王 Boss
      this.spawnQueenBoss(diff);
    } else {
      // 根據 WaveDifficultyManager 取得動態陣型配置
      const formation = this.difficultyManager.getWaveFormation(this.wave);
      formation.forEach(item => {
        if (item.type === 'ARMORED') {
          const armored = new ArmoredHornet(this, item.x, item.y);
          this.enemyGroup.add(armored, true);
          armored.spawn(item.x, item.y, diff);
        } else {
          const hornet = new Hornet(this, item.x, item.y);
          this.enemyGroup.add(hornet, true);
          hornet.spawn(item.x, item.y, diff);
        }
      });
    }
  }

  spawnQueenBoss(diff = null) {
    this.bossActive = true;
    this.currentBoss = new QueenBoss(this, 240, 110);
    this.enemyGroup.add(this.currentBoss, true);
    this.currentBoss.spawn(240, 110, diff);
    this.hud.showBossHp(true, this.currentBoss.hp, this.currentBoss.maxHp);
  }

  spawnHornetMinion(x, y) {
    const diff = this.difficultyManager ? this.difficultyManager.getDifficulty(this.wave) : null;
    const minion = new Hornet(this, x, y);
    minion.isBossMinion = true;
    this.enemyGroup.add(minion, true);
    minion.spawn(x, y, diff);
  }

  spawnEnemyBullet(x, y, angle, speed = 200) {
    let bullet = this.enemyBulletGroup.get(x, y, 'bullet_enemy');
    if (bullet) {
      bullet.enableBody(true, x, y, true, true);
      this.physics.velocityFromRotation(angle, speed, bullet.body.velocity);
      bullet.rotation = angle - Math.PI / 2;
    }
  }

  // 命中敵機
  handleBulletHitEnemy(bullet, enemy) {
    if (!bullet.active || !enemy.active) return;

    // D4 & D5 規格守門：進場中 (ENTERING) 的工蜂免疫傷害，且子彈直接穿過不被消耗
    if (enemy.state === 'ENTERING') return;

    if (bullet.piercing) {
      if (bullet.hitTargets.has(enemy)) return;
      bullet.hitTargets.add(enemy);
    } else {
      bullet.setActive(false);
      bullet.setVisible(false);
      bullet.body.stop();
    }

    soundManager.playHit();
    enemy.takeDamage(bullet.damage);

    // 如果是 Boss，更新 Boss 血條
    if (this.bossActive && enemy === this.currentBoss) {
      this.hud.showBossHp(true, enemy.hp, enemy.maxHp);
    }
  }

  // 玩家撞擊敵機
  handlePlayerHitEnemy(player, enemy) {
    if (!player.active || !enemy.active || player.isInvulnerable) return;

    // D4 規格守門：進場中 (ENTERING) 的工蜂不產生撞擊傷害，雙方皆不受傷
    if (enemy.state === 'ENTERING') return;

    player.takeDamage(25);
    enemy.takeDamage(40);
  }

  // 玩家被敵彈擊中
  handlePlayerHitBullet(player, bullet) {
    if (!player.active || !bullet.active || player.isInvulnerable) return;
    bullet.setActive(false);
    bullet.setVisible(false);
    bullet.body.stop();
    player.takeDamage(20);
  }

  // 擊殺敵機後給分與升級檢查
  onEnemyKilled(enemy) {
    this.addScore(enemy.scoreValue || 100);
    this.createExplosionParticles(enemy.x, enemy.y, 0xff5500);
  }

  onQueenDefeated(boss) {
    this.addScore(boss.scoreValue || 2500);
    this.bossActive = false;
    this.currentBoss = null;
    this.hud.showBossHp(false);
    this.createExplosionParticles(boss.x, boss.y, 0xff00ff, 35);

    // 獎勵全場加分與回血
    this.player.hp = Math.min(this.player.maxHp, this.player.hp + 40);
    if (this.player.bombs < GAME_CONFIG.PLAYER.MAX_BOMBS) {
      this.player.bombs++;
      this.hud.updateBombs(this.player.bombs);
    }
  }

  addScore(points) {
    this.score += points;
    this.hud.updateScore(this.score);

    // 檢查武器升級里程碑
    const upgraded = this.weaponSystem.checkUpgrade(this.score);
    if (upgraded) {
      this.hud.updateWeapon(upgraded);
      this.hud.showUpgradeBanner(upgraded);
    }
  }

  // 花粉必殺技核爆
  triggerPollenSupernova() {
    this.hud.updateBombs(this.player.bombs);

    // 全屏白閃
    const flash = this.add.rectangle(240, 320, 480, 640, 0xffffff, 0.9).setDepth(300);
    this.tweens.add({
      targets: flash,
      alpha: 0,
      duration: 350,
      onComplete: () => flash.destroy()
    });

    // 透過原生粒子發射器爆發金色花粉暴風（零 GC 物件建立開銷）
    for (let i = 0; i < 8; i++) {
      const px = Phaser.Math.Between(40, 440);
      const py = Phaser.Math.Between(100, 550);
      this.pollenParticles.emitParticleAt(px, py, 6);
    }

    // 清除全屏敵彈（回收進物件池，而非 destroy）
    // 清除全場敵方子彈（快照安全回收進物件池）
    this.enemyBulletGroup.getChildren().slice().forEach(b => {
      if (b.active) {
        b.setActive(false);
        b.setVisible(false);
        b.body.stop();
      }
    });

    // 重創或秒殺場上所有合格敵蜂（委託純邏輯 detonatePollen，遵守 D4 ENTERING 免疫守門）
    detonatePollen(this.enemyGroup.getChildren(), {
      minionDamage: GAME_CONFIG.POLLEN?.MINION_DAMAGE || 120,
      bossDamage: GAME_CONFIG.POLLEN?.BOSS_DAMAGE || 200,
      isBoss: enemy => enemy === this.currentBoss,
      onDamaged: (enemy, dmg) => {
        enemy.takeDamage(dmg);
        if (this.bossActive && enemy === this.currentBoss) {
          this.hud.showBossHp(true, this.currentBoss.hp, this.currentBoss.maxHp);
        }
      }
    });
  }

  showHitFlash(sprite) {
    sprite.setTint(0xffffff);
    this.time.delayedCall(60, () => {
      if (!sprite.active) return;
      if (sprite.isEnraged) {
        sprite.setTint(0xff3333);
      } else {
        sprite.clearTint();
      }
    });
  }

  createExplosionParticles(x, y, color = 0xffaa00, count = 12) {
    // 改用原生高效發射器，零 Allocation
    this.sparkParticles.emitParticleAt(x, y, count);
  }

  onPlayerDied() {
    this.time.delayedCall(1000, () => {
      this.scene.start('GameOverScene', { score: this.score, wave: this.wave });
    });
  }

  // 大自然食物鏈彩蛋：召喚東方蜂鷹 (Oriental Honey Buzzard) 救援
  summonHoneyBuzzard() {
    this.buzzardCooldown = GAME_CONFIG.EASTER?.COOLDOWN || 45000;
    soundManager.playEagleCall();

    // 螢幕上方橫幅提示自然守護者登場
    const buzzardBanner = this.add.text(240, 200, '★ 大自然食物鏈：天敵蜂鷹降臨！★\n[ ORIENTAL HONEY BUZZARD RESCUE ]', {
      fontFamily: '"Press Start 2P", monospace, sans-serif',
      fontSize: '10px',
      color: '#ffd700',
      align: 'center',
      stroke: '#3e1f07',
      strokeThickness: 4
    }).setOrigin(0.5).setDepth(260);

    this.tweens.add({
      targets: buzzardBanner,
      alpha: 0,
      y: 170,
      duration: 2200,
      onComplete: () => buzzardBanner.destroy()
    });

    // 建立蜂鷹實體（由右上天際破雲俯衝掠過）
    const buzzard = this.physics.add.sprite(520, -60, 'easter_honey_buzzard').setDepth(250);
    buzzard.setScale(1.4);

    // 蜂鷹單次命中追蹤器（由 createOnceHitTracker 實例化，取代裸 Set）
    const buzzardTracker = createOnceHitTracker();

    // 蜂鷹俯衝掠食軌跡動畫
    this.tweens.add({
      targets: buzzard,
      x: -100,
      y: 680,
      duration: 2200,
      ease: 'Quad.easeInOut',
      onUpdate: () => {
        // 蜂鷹飛行時在身後留下一串金色微風火花
        this.sparkParticles.emitParticleAt(buzzard.x, buzzard.y - 15, 2);

        // 掠過途徑肅清普通虎頭蜂並重創 Boss (委託純邏輯 buzzardStrike，遵守 D4 免疫與 range)
        buzzardStrike(this.enemyGroup.getChildren(), buzzard, {
          tracker: buzzardTracker,
          range: GAME_CONFIG.EASTER?.RANGE || 95,
          bossDamage: GAME_CONFIG.EASTER?.BOSS_DAMAGE || 250,
          minionDamage: GAME_CONFIG.EASTER?.MINION_DAMAGE || 150,
          isBoss: enemy => enemy === this.currentBoss,
          distanceFn: (x1, y1, x2, y2) => Phaser.Math.Distance.Between(x1, y1, x2, y2),
          onDamaged: (enemy, dmg) => {
            enemy.takeDamage(dmg);
            if (this.bossActive && enemy === this.currentBoss) {
              this.hud.showBossHp(true, this.currentBoss.hp, this.currentBoss.maxHp);
            }
          }
        });
      },
      onComplete: () => {
        buzzard.destroy();
      }
    });

    // 清除全場敵方毒針彈幕 (快照安全回收)
    this.enemyBulletGroup.getChildren().slice().forEach(b => {
      if (b.active) {
        b.setActive(false);
        b.setVisible(false);
        b.body.stop();
      }
    });

    // 蜂鷹在場中央空投一顆高營養「特級蜂露 (Royal Pollen Dew)」給小蜜蜂
    this.time.delayedCall(800, () => {
      const dew = this.dropsGroup.create(240, 150, 'item_honey_dew');
      dew.setVelocity(0, 90);
      dew.setDepth(205);

      // 閃爍呼吸光暈
      this.tweens.add({
        targets: dew,
        scale: { from: 1.4, to: 0.9 },
        yoyo: true,
        repeat: -1,
        duration: 400
      });
    });
  }

  // 小蜜蜂拾取特級蜂露
  handleCollectDew(player, dew) {
    if (!dew.active) return;
    dew.destroy();
    soundManager.playHeal();

    // 回復 50 點生命值並補充 1 顆核彈
    player.hp = Math.min(player.maxHp, player.hp + 50);
    if (player.bombs < GAME_CONFIG.PLAYER.MAX_BOMBS) {
      player.bombs++;
    }
    this.hud.updateHp(player.hp, player.maxHp);
    this.hud.updateBombs(player.bombs);

    // 爆發綠金花粉治癒特效
    for (let i = 0; i < 15; i++) {
      const angle = Phaser.Math.FloatBetween(0, Math.PI * 2);
      const dist = Phaser.Math.FloatBetween(20, 50);
      const healSpark = this.add.rectangle(player.x, player.y, 4, 4, 0x00ffcc).setDepth(206);
      this.tweens.add({
        targets: healSpark,
        x: player.x + Math.cos(angle) * dist,
        y: player.y + Math.sin(angle) * dist,
        alpha: 0,
        duration: 500,
        onComplete: () => healSpark.destroy()
      });
    }
  }
}
