// 怪物：配置驱动。行为模式见 enemies.json 的 behavior 字段：
// chase（追击）/ ranged（保持距离射箭）/ charger（蓄力冲锋）/ boss（多阶段狂暴）/
// flee（逃跑：黄金哥布林）/ barrel（木桶：静止可破坏）
export default class Enemy extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y) {
    super(scene, x, y, 'enemy-bat-fly-1');
    scene.add.existing(this);
    scene.physics.add.existing(this);
  }

  spawn(x, y, cfg, hpScale) {
    this.enableBody(true, x, y, true, true);
    this.cfg = cfg;
    this.setTexture(cfg.texture);
    const scaleFactor = (cfg.scale || 1) * 1.65;
    this.setScale(scaleFactor);
    this.maxHp = Math.round(cfg.hp * hpScale); // Boss 血量倍率由 GameScene 传入（无尽模式逐次递增）
    this.hp = this.maxHp;
    this.speed = cfg.speed;
    this.ft = 0; this.fi = 0;
    this.baseTint = cfg.tint || 0xffffff;
    this.baseAlpha = cfg.alpha !== undefined ? cfg.alpha : 1;
    this.setTint(this.baseTint);
    this.enraged = false;
    this.life = cfg.despawnAfter || 0;
    this.setAlpha(this.baseAlpha);
    if (cfg.affixName) { // 精英词缀名标签
      this.affixText = this.scene.add.text(x, y - 34, cfg.affixName, {
        fontFamily: '"Microsoft YaHei", sans-serif', fontSize: '11px',
        color: '#ffd7a0', stroke: '#000000', strokeThickness: 3
      }).setOrigin(0.5).setDepth(9);
    } else this.affixText = null;
    this.body.setSize(
      Math.max(12, Math.round(this.displayWidth * 0.55)),
      Math.max(12, Math.round(this.displayHeight * 0.6)), true);
    this.ai = 'stalk'; this.aiT = cfg.dashEvery || 0;
    this.shootT = cfg.shootInterval || 2;
    this.ringT = 2.5; this.sumT = 4;
    this.flashUntil = 0;
    this.slowUntil = 0;
    this.setDepth(5);
  }

  update(dt) {
    if (!this.active || !this.cfg) return;
    const s = this.scene, p = s.player;

    if (this.affixText) this.affixText.setPosition(this.x, this.y - this.displayHeight / 2 - 10);

    // Boss 狂暴阶段：血量低于 50% 时提速 + 变红 + 缩短技能间隔
    if (this.cfg.behavior === 'boss' && !this.enraged && this.hp <= this.maxHp * 0.5) {
      this.enraged = true;
      this.baseTint = 0xff5050;
      this.setTint(this.baseTint);
      this.speed *= 1.3;
      if (this.cfg.ringInterval) this.cfg.ringInterval *= 0.6;
      if (this.cfg.slamInterval) this.cfg.slamInterval *= 0.6;
      if (this.cfg.dashEvery) this.cfg.dashEvery *= 0.55;
      s.onBossEnrage(this);
    }

    // 两帧动画交替
    if (this.cfg.frames) {
      this.ft += dt;
      if (this.ft > 0.22) { this.ft = 0; this.fi = 1 - this.fi; }
      this.setTexture(this.cfg.frames[this.fi]);
    }

    if (p.dead) { this.setVelocity(0, 0); return; }
    const d = Phaser.Math.Distance.Between(this.x, this.y, p.x, p.y);
    const isSlowed = this.scene.time.now < (this.slowUntil || 0);
    const slowF = isSlowed ? 0.55 : 1; // 被毒雾/冰霜减速
    if (!isSlowed && this._wasSlowed) {
      this._wasSlowed = false;
      if (this.scene.time.now >= (this.flashUntil || 0)) this.setTint(this.baseTint);
    } else if (isSlowed && !this._wasSlowed) {
      this._wasSlowed = true;
      if (this.scene.time.now >= (this.flashUntil || 0)) this.setTint(0x70d6ff);
    }

    switch (this.cfg.behavior) {
      case 'ranged': {
        if (d > 320) s.physics.moveTo(this, p.x, p.y, this.speed * slowF);
        else if (d < 230) { // 拉开距离
          const a = Phaser.Math.Angle.Between(p.x, p.y, this.x, this.y);
          this.setVelocity(Math.cos(a) * this.speed * slowF, Math.sin(a) * this.speed * slowF);
        } else this.setVelocity(0, 0);
        this.shootT -= dt;
        if (this.shootT <= 0 && d < 420) {
          this.shootT = this.cfg.shootInterval;
          const a = Phaser.Math.Angle.Between(this.x, this.y, p.x, p.y);
          s.spawnEnemyBullet(this.x, this.y,
            Math.cos(a) * this.cfg.bulletSpeed, Math.sin(a) * this.cfg.bulletSpeed,
            Math.round(this.cfg.damage * 0.8), 'fx-energy-orb', 0xff7043);
        }
        break;
      }
      case 'charger': {
        this.aiT -= dt;
        if (this.ai === 'stalk') {
          s.physics.moveTo(this, p.x, p.y, this.speed * 0.6 * slowF);
          if (d < 300) { this.ai = 'telegraph'; this.aiT = 0.5; this.setTintFill(0xd42a2a); }
        } else if (this.ai === 'telegraph') {
          this.setVelocity(0, 0);
          if (this.aiT <= 0) {
            const a = Phaser.Math.Angle.Between(this.x, this.y, p.x, p.y);
            const dash = Math.min(430, Math.round(this.speed * 5)) * slowF;
            this.setVelocity(Math.cos(a) * dash, Math.sin(a) * dash);
            this.ai = 'dash'; this.aiT = 0.9; this.setTint(this.baseTint);
          }
        } else if (this.ai === 'dash') {
          if (this.aiT <= 0) { this.ai = 'rest'; this.aiT = 1.2; this.setVelocity(0, 0); }
        } else { // rest
          this.setVelocity(0, 0);
          if (this.aiT <= 0) this.ai = 'stalk';
        }
        break;
      }
      case 'boss': {
        const kind = this.cfg.bossKind;
        if (kind === 'boarKing') { // 野猪王：周期性闪白蓄力后高速冲撞 + 召唤野猪群
          this.aiT -= dt;
          if (this.ai === 'stalk') {
            s.physics.moveTo(this, p.x, p.y, this.speed * slowF);
            if (this.aiT <= 0) { this.ai = 'telegraph'; this.aiT = 0.6; this.setTintFill(0xd42a2a); }
          } else if (this.ai === 'telegraph') {
            this.setVelocity(0, 0);
            if (this.aiT <= 0) {
              const a = Phaser.Math.Angle.Between(this.x, this.y, p.x, p.y);
              const dash = Math.min(470, Math.round(this.speed * 5.2)) * slowF;
              this.setVelocity(Math.cos(a) * dash, Math.sin(a) * dash);
              this.ai = 'dash'; this.aiT = 0.8; this.setTint(this.baseTint);
            }
          } else if (this.ai === 'dash') {
            if (this.aiT <= 0) { this.ai = 'chill'; this.aiT = 1.2; this.setVelocity(0, 0); }
          } else { // chill
            this.setVelocity(0, 0);
            if (this.aiT <= 0) { this.ai = 'stalk'; this.aiT = this.cfg.dashEvery; }
          }
          this.sumT -= dt;
          if (this.sumT <= 0) {
            this.sumT = this.cfg.summonInterval;
            for (let i = 0; i < 3; i++) {
              s.spawnEnemy('boar', this.x + Phaser.Math.Between(-100, 100), this.y + Phaser.Math.Between(-100, 100));
            }
          }
          break;
        }
        if (d > 170) s.physics.moveTo(this, p.x, p.y, this.speed * slowF);
        else this.setVelocity(0, 0);
        if (kind === 'trollKing') { // 巨魔王：召唤僵尸 + 近身践踏（震屏 AOE）
          this.sumT -= dt;
          if (this.sumT <= 0) {
            this.sumT = this.cfg.summonInterval;
            for (let i = 0; i < 3; i++) {
              s.spawnEnemy('zombie', this.x + Phaser.Math.Between(-110, 110), this.y + Phaser.Math.Between(-110, 110));
            }
          }
          this.ringT -= dt;
          if (this.ringT <= 0) {
            this.ringT = this.cfg.slamInterval;
            s.slamFx(this.x, this.y);
            if (d < 240 && !p.dead) p.hurt(Math.max(1, Math.round(this.cfg.damage * 0.6)));
          }
        } else { // 死神：环形弹幕 + 召唤蝙蝠
          this.ringT -= dt;
          if (this.ringT <= 0) {
            this.ringT = this.cfg.ringInterval;
            const ringDmg = Math.max(1, Math.round(this.cfg.damage * 0.5));
            for (let i = 0; i < 12; i++) {
              const a = (i / 12) * Math.PI * 2;
              s.spawnEnemyBullet(this.x, this.y, Math.cos(a) * 180, Math.sin(a) * 180, ringDmg, 'fx-energy-orb', 0xff4dd2);
            }
          }
          this.sumT -= dt;
          if (this.sumT <= 0) {
            this.sumT = this.cfg.summonInterval;
            for (let i = 0; i < 5; i++) {
              s.spawnEnemy('bat', this.x + Phaser.Math.Between(-90, 90), this.y + Phaser.Math.Between(-90, 90));
            }
          }
        }
        break;
      }
      case 'flee': { // 黄金哥布林：拼命逃跑，超时消失
        this.life -= dt;
        const a = Phaser.Math.Angle.Between(p.x, p.y, this.x, this.y);
        this.setVelocity(Math.cos(a) * this.speed * slowF, Math.sin(a) * this.speed * slowF);
        if (this.life <= 0) { this.despawn(); return; }
        break;
      }
      case 'barrel': { // 木桶：静止不动
        this.setVelocity(0, 0);
        break;
      }
      default: // chase
        s.physics.moveTo(this, p.x, p.y, this.speed * slowF);
    }
  }

  takeDamage(dmg) {
    if (!this.active) return;
    this.hp -= dmg;
    // 受击白闪：短暂半透明眨一下（40ms）；同一只怪 180ms 内不重复触发，
    // 密集围攻下也只是偶尔眨一下，不会全场白呼呼
    const now = this.scene.time.now;
    if (now >= (this.flashUntil || 0)) {
      this.flashUntil = now + 180; // 两次白闪最小间隔
      this.setTintFill(0xffffff);
      this.setAlpha(0.55);
      // 45ms 后恢复；期间因 180ms 冷却不会有新闪烁，无条件恢复是安全的
      this.scene.time.delayedCall(45, () => {
        if (this.active) {
          const isSlowed = this.scene.time.now < (this.slowUntil || 0);
          this.setTint(isSlowed ? 0x70d6ff : this.baseTint);
          this.setAlpha(this.baseAlpha);
        }
      });
    }
    if (this.hp <= 0) this.scene.onEnemyKilled(this);
  }

  despawn() {
    if (this.affixText) { this.affixText.destroy(); this.affixText = null; }
    this.disableBody(true, true);
  }
}
