import Player from '../entities/Player.js';
import Enemy from '../entities/Enemy.js';
import Pickup from '../entities/Pickup.js';
import Wand from '../weapons/Wand.js';
import Knife from '../weapons/Knife.js';
import Whip from '../weapons/Whip.js';
import Axe from '../weapons/Axe.js';
import Orbit from '../weapons/Orbit.js';
import HolyWater from '../weapons/HolyWater.js';
import Lightning from '../weapons/Lightning.js';
import Drain from '../weapons/Drain.js';
import Boomerang from '../weapons/Boomerang.js';
import Spore from '../weapons/Spore.js';
import Laser from '../weapons/Laser.js';
import Frost from '../weapons/Frost.js';
import SpawnDirector from '../systems/SpawnDirector.js';
import Hazards from '../systems/Hazards.js';
import XPSystem from '../systems/XPSystem.js';
import UpgradeSystem from '../systems/UpgradeSystem.js';
import FX from '../fx/Particles.js';
import getData from '../data.js';
import meta from '../meta.js';
import audio from '../audio.js';
import DIFFICULTY_CONFIGS from '../difficulty.js';

const WORLD = 2400;
// 进化模式竞技场：全屏 1280x720，纯净无黑边
const BROTO_W = 1280, BROTO_H = 720;
// 每波时长配置（秒）：波次 1-5 / 6-10 / 11-19 / 20
const BROTO_WAVE_DURATIONS = [20, 22, 24, 26, 28, 30, 30, 30, 30, 30, 35, 38, 40, 42, 45, 45, 48, 50, 52, 60];

// 精英词缀池：精英怪随机携带 1~2 条
const AFFIXES = {
  swift:   { name: '迅捷', speed: 1.45 },
  tough:   { name: '坚韧', hp: 1.6 },
  berserk: { name: '狂暴', damage: 1.5, speed: 1.15 },
  split:   { name: '分裂', split: true },
  vampire: { name: '吸血', healOnHit: 14 }
};

// 诅咒选项：强力但带代价，每局每种只能选一次
const CURSES = [
  { id: 'demon',   name: '恶魔契约', desc: '伤害 +80%，最大生命 -30%',              apply: p => { p.curseDmg = 1.8; p.hpMulCurse = 0.7; } },
  { id: 'frenzy',  name: '狂热',     desc: '冷却 -25%，受到伤害 +25%',              apply: p => { p.curseCd = 0.75; p.curseTaken = 1.25; } },
  { id: 'bloodpact', name: '血债血偿', desc: '伤害 +40%，每秒流失 1.5 生命',        apply: p => { p.curseDmg = Math.max(p.curseDmg, 1.4); p.curseDrain = 1.5; } }
];

export default class GameScene extends Phaser.Scene {
  constructor() { super('GameScene'); }

  create(data) {
    // 强制关闭所有菜单场景，保证战斗画面绝对纯净
    this.scene.stop('MenuScene');
    this.scene.stop('LevelSelectScene');

    const balance = getData(this, 'balance');

    // 是否为土豆兄弟竞技场模式
    this.isBrotato = (data && data.mode === 'brotato');
    this.brotoWave = (data && data.wave) ? data.wave : 1;
    this.brotoMaxWave = 20;
    this.brotoLockedSlots = [false, false, false, false];
    this.brotoWaveDuration = 0; // 当前波次倒计时（秒），在 _startBrotoWave 中设置

    // 难度等级：由主菜单或 data 传入（1: 普通, 2: 困难, 3: 噩梦）
    const reqDiff = (data && typeof data.difficulty === 'number') ? data.difficulty : meta.getDifficulty();
    this.difficulty = Phaser.Math.Clamp(Math.round(reqDiff || 1), 1, 3);
    this.diffConfig = DIFFICULTY_CONFIGS[this.difficulty] || DIFFICULTY_CONFIGS[1];

    // 关卡：由主菜单选择，经 scene 数据或 registry 传入；数据缺失时兜底回第 1 关
    const levelsList = getData(this, 'levels').levels;
    this.levelsTotal = levelsList.length;
    if (this.isBrotato) {
      // 进化模式使用独立的中性配置：绝不能复用 registry 里"上次玩过的经典关卡"，
      // 否则会把无限火力的 0.15 冷却、疯狂成长的 1.6 倍血量、无尽模式的成就/上限成长带进竞技场。
      this.levelId = 0;
      this.levelConfig = { id: 0, name: '进化模式', bossName: '双首领', duration: 0, waves: [], mods: {} };
    } else {
      const reqLevel = (data && typeof data.level === 'number') ? data.level : (this.registry.get('level') || 1);
      this.levelId = Phaser.Math.Clamp(Math.round(reqLevel), 1, this.levelsTotal);
      this.registry.set('level', this.levelId);
      this.levelConfig = levelsList[this.levelId - 1] || levelsList[0];
    }
    this.levelDuration = this.levelConfig.endless ? Infinity : this.levelConfig.duration;
    // 趣味关卡修正器（levels.json 的 mods 字段）与难度修正
    const mods = this.levelConfig.mods || {};
    this.fireRate = mods.cooldown || 1;       // 无限火力：冷却倍率
    this.hpScaleMul = mods.hpScaleMul || 1;   // 疯狂成长：怪物血量成长倍率
    this.intervalMul = (mods.intervalMul || 1) * this.diffConfig.enemy.interval * (balance.intervalBase || 1);

    // 世界与相机
    if (this.isBrotato) {
      this.physics.world.setBounds(0, 0, BROTO_W, BROTO_H);
      this.cameras.main.setBounds(0, 0, BROTO_W, BROTO_H);
    } else {
      this.physics.world.setBounds(0, 0, WORLD, WORLD);
      this.cameras.main.setBounds(0, 0, WORLD, WORLD);
    }

    const worldW = this.isBrotato ? BROTO_W : WORLD;
    const worldH = this.isBrotato ? BROTO_H : WORLD;

    const ground = this.add.tileSprite(worldW / 2, worldH / 2, worldW, worldH, 'tile-ground-base').setDepth(0);
    if (this.levelConfig.tint) ground.setTint(this.levelConfig.tint);
    if (this.isBrotato) {
      this._drawArenaWalls(worldW, worldH);
    } else {
      this.scatterGroundDetails();
    }

    // 实体与系统（角色数据驱动初始武器与属性）
    const charId = meta.getCharacter();
    this.charConfig = getData(this, 'characters').list.find(c => c.id === charId) || getData(this, 'characters').list[0];
    this.player = new Player(this, worldW / 2, worldH / 2, this.charConfig);
    this.cameras.main.startFollow(this.player, true, 0.1, 0.1);

    this.enemies = this.add.group({ classType: Enemy });
    this.bullets = this.physics.add.group({ maxSize: 400 });
    this.enemyBullets = this.physics.add.group({ maxSize: 200 });
    this.pickups = this.add.group({ classType: Pickup });

    this.isMobile = !this.sys.game.device.os.desktop;
    const balData = getData(this, 'balance');
    this.enemyCap = this.isBrotato ? 260 : (this.isMobile ? balData.enemyCaps.mobile : balData.enemyCaps.desktop);
    this.bulletRange = balData.bulletRange;
    // 索敌与弹道统一上限：1280x720 视口纵向可视半径 360，超出即打向屏幕外
    this.aimDist = Math.min(this.bulletRange, 380);
    this.gemAttractAfter = typeof (balData.player && balData.player.gemAutoAttract) === 'number' ? balData.player.gemAutoAttract : 3.5;
    this.magnetSpeed = (balData.gem && balData.gem.magnetSpeed) || 480;

    this.weaponClasses = {
      wand: Wand, knife: Knife, whip: Whip, axe: Axe,
      orbit: Orbit, holywater: HolyWater, lightning: Lightning, drain: Drain,
      boomerang: Boomerang, spore: Spore, laser: Laser, frost: Frost
    };
    this.weaponLevels = {};
    this.weapons = [];

    // === 商店永久强化：武器初始等级（进化模式不生效） ===
    const shopWpLv = (!this.isBrotato ? meta.getShopLevel('weapon_level') : 0) || 0; // 0-2: 额外等级
    this.addWeapon(this.player.startWeapon);
    // 应用锻造强化：把初始武器升级到 shopWpLv+1 级
    if (shopWpLv > 0 && this.weapons[0]) {
      for (let lv = 0; lv < shopWpLv; lv++) {
        this.upgradeSystem = this.upgradeSystem || new UpgradeSystem(this);
        if (this.weapons[0]) {
          const w = this.weapons[0];
          const wpDef = getData(this, 'weapons')[w.id];
          if (w.level < (wpDef ? wpDef.maxLevel : 8)) {
            w.level++;
            this.weaponLevels[w.id] = w.level;
          }
        }
      }
    }

    // === 商店永久强化：额外武器（进化模式不生效，初始始终只有 1 把起始武器） ===
    const shopExtraWp = (!this.isBrotato ? meta.getShopLevel('extra_weapon') : 0) || 0; // 0-2: 额外武器数量
    if (shopExtraWp > 0) {
      const allWpKeys = Object.keys(this.weaponClasses).filter(k => k !== this.player.startWeapon);
      const extras = Phaser.Utils.Array.Shuffle(allWpKeys).slice(0, shopExtraWp);
      extras.forEach(wpId => this.addWeapon(wpId));
    }

    this.rerollCount = 0;
    // === 商店永久强化：命运骰子（免费刷新次数，进化模式不生效）===
    this.freeRerolls = (!this.isBrotato ? meta.getShopLevel('reroll') : 0) || 0;

    this.goblinT = 100;
    this.barrelT = 45;
    if (!this.isBrotato) this.scatterBarrels(10);
    this.spawnDirector = new SpawnDirector(this);
    this.hazards = new Hazards(this);
    this.hazards.spawnAtStart();
    this.xpSystem = new XPSystem(this);
    this.upgradeSystem = new UpgradeSystem(this);
    this.fx = new FX(this);

    // 计时与状态
    this.elapsed = 0;
    this.kills = 0;

    // === 商店永久强化：启动资金（进化模式不生效）===
    this.coins = (!this.isBrotato ? (meta.getShopLevel('start_gold') || 0) * 50 : 0);

    this.gameOver = false;
    this.victory = false;
    this.pendingLevelUps = 0;
    this.levelUpActive = false;
    this._suppressLevelUp = false;
    this._brotoFinalRage = 0;
    this.cursesTaken = {};

    // 土豆兄弟模式：启动第一波
    if (this.isBrotato) {
      this._startBrotoWave(this.brotoWave);
    }

    // 输入：键盘 + 触摸虚拟摇杆（左半屏按住拖动）
    this.input.once('pointerdown', () => audio.unlock());
    // 切出窗口自动暂停（防止挂机被围死）
    const autoPause = () => {
      if (this.scene.isActive() && !this.gameOver && !this.levelUpActive && this.uiScene && !this.uiScene.pauseVisible) {
        this.uiScene.togglePause();
      }
    };
    const onVis = () => { if (document.hidden) autoPause(); };
    this.game.events.on('blur', autoPause);
    document.addEventListener('visibilitychange', onVis);
    this.events.once('shutdown', () => {
      this.game.events.off('blur', autoPause);
      document.removeEventListener('visibilitychange', onVis);
    });
    this.input.keyboard.on('keydown-M', () => {
      const m = audio.toggle();
      this.uiScene.toast(m ? '音效已关闭（M 开启）' : '音效已开启');
    });
    this.keys = this.input.keyboard.addKeys('W,A,S,D,UP,LEFT,DOWN,RIGHT,M,X');
    // 瞄准模式（自动索敌 vs 鼠标光标精准指向）
    this.aimMode = 'auto'; // 'auto' | 'cursor'
    this.input.keyboard.on('keydown-X', () => this.toggleAimMode());

    // 战斗视觉特效层：6件终极羁绊光环、手动瞄准准星
    this.synergyAuraGfx = this.add.graphics().setDepth(4);
    this.crosshairGfx = this.add.graphics().setDepth(25).setVisible(false);

    this.input.addPointer(1);
    this.joystick = { active: false, pointerId: -1, ox: 0, oy: 0, dx: 0, dy: 0 };
    this.input.on('pointerdown', p => {
      if (this.gameOver || this.levelUpActive) return;
      // 触屏只用左半屏当摇杆；鼠标点在 HUD 按钮上时不劫持走位
      if (p.pointerType === 'touch' && p.x > this.scale.width * 0.5) return;
      if (p.pointerType === 'mouse' && this.uiScene && this.uiScene.input.hitTestPointer(p).length > 0) return;
      this.joystick.active = true;
      this.joystick.pointerId = p.id;
      this.joystick.ox = p.x; this.joystick.oy = p.y;
      this.joystick.dx = 0; this.joystick.dy = 0;
    });
    this.input.on('pointermove', p => {
      if (!this.joystick.active || p.id !== this.joystick.pointerId) return;
      const MAX = 60;
      this.joystick.dx = Phaser.Math.Clamp(p.x - this.joystick.ox, -MAX, MAX);
      this.joystick.dy = Phaser.Math.Clamp(p.y - this.joystick.oy, -MAX, MAX);
    });
    this.input.on('pointerup', p => {
      if (p.id === this.joystick.pointerId) this.joystick.active = false;
    });

    // 碰撞。注意：Phaser 组 vs 组的回调参数顺序不保证，必须按对象特征识别角色
    this.physics.add.overlap(this.player, this.enemies, (x, y) => {
      const pl = typeof x.hurt === 'function' ? x : y;
      const enemy = pl === x ? y : x;
      if (enemy.active && !pl.dead && enemy.cfg.damage > 0) {
        pl.hurt(enemy.cfg.damage);
        if (enemy.cfg.healOnHit) enemy.hp = Math.min(enemy.maxHp, enemy.hp + enemy.cfg.healOnHit); // 吸血词缀
      }
    });
    this.physics.add.overlap(this.player, this.pickups, (x, y) => {
      const pl = typeof x.hurt === 'function' ? x : y;
      const pk = pl === x ? y : x;
      this.collectPickup(pk);
    });
    this.physics.add.overlap(this.bullets, this.enemies, (x, y) => {
      const bullet = x.startX !== undefined ? x : y;
      const enemy = bullet === x ? y : x;
      if (!bullet.active || !enemy.active) return;
      if (bullet.hitSet) { // 穿透武器（斧）：每个敌人只结算一次
        if (bullet.hitSet.has(enemy)) return;
        bullet.hitSet.add(enemy);
        this.dealDamage(enemy, bullet.damage);
      } else {
        this.dealDamage(enemy, bullet.damage);
        bullet.disableBody(true, true);
      }
    });
    this.physics.add.overlap(this.player, this.enemyBullets, (x, y) => {
      const eb = x.dmg !== undefined ? x : y;
      const pl = eb === x ? y : x;
      if (!eb.active || pl.dead) return;
      pl.hurt(eb.dmg);
      eb.disableBody(true, true);
    });

    this.scene.launch('UIScene');
    this.uiScene = this.scene.get('UIScene');

    const hzInfo = this.hazards.info();
    if (hzInfo) this.time.delayedCall(500, () => { if (this.uiScene) this.uiScene.toast(hzInfo.warn); });
  }

  update(time, delta) {
    if (this.gameOver || this.levelUpActive) return;
    const dt = Math.min(delta, 50) / 1000;
    this.elapsed += dt;

    this.updatePlayerMovement();
    this.spawnDirector.update(dt);
    this.hazards.update(dt);
    for (const w of this.weapons) w.update(dt);
    this.updateEnemies(dt);
    this.updateBullets(dt);
    this.updateEnemyBullets();
    this.updatePickups();
    this.updateRegen(dt);
    this.updateEndlessAchv();
    this.updateCurses(dt);
    this.updateGoblinAndBarrels(dt);
    this.updateNearestCache();
    this.updateCrosshair();
    this.updateSynergyAura(time);
    if (this.isBrotato) this._updateBrotoTimer(dt);
  }

  // 最近敌人缓存：每 100ms 排序一次，避免高频开火时全场排序
  updateNearestCache() {
    if (this.time.now - (this._nearT || 0) < 100) return;
    this._nearT = this.time.now;
    const px = this.player.x, py = this.player.y;
    this._nearSorted = this.enemies.getChildren()
      .filter(e => e.active)
      .sort((a, b) =>
        Phaser.Math.Distance.Between(a.x, a.y, px, py) -
        Phaser.Math.Distance.Between(b.x, b.y, px, py));
  }

  // 诅咒血债：每秒流失生命
  updateCurses(dt) {
    const p = this.player;
    if (p.curseDrain > 0 && !p.dead) {
      p.hp -= p.curseDrain * dt;
      if (p.hp <= 0) { p.hp = 0; p.die(); }
    }
  }

  // 黄金哥布林与木桶的周期生成
  updateGoblinAndBarrels(dt) {
    if (this.isBrotato) return; // 进化竞技场模式怪潮由波次统御，不额外生成野外哥布林与木桶
    this.goblinT -= dt;
    if (this.goblinT <= 0) {
      this.goblinT = Phaser.Math.Between(140, 200);
      const alive = this.enemies.getChildren().some(e => e.active && e.cfg && e.cfg.goldGoblin);
      if (!alive) this.spawnEnemy('goblin');
    }
    this.barrelT -= dt;
    if (this.barrelT <= 0) {
      this.barrelT = 50;
      const n = this.enemies.getChildren().filter(e => e.active && e.cfg && e.cfg.barrel).length;
      for (let i = n; i < 5; i++) {
        const a = Math.random() * Math.PI * 2;
        const r = Phaser.Math.Between(250, 600);
        this.spawnEnemy('barrel',
          Phaser.Math.Clamp(this.player.x + Math.cos(a) * r, 40, WORLD - 40),
          Phaser.Math.Clamp(this.player.y + Math.sin(a) * r, 40, WORLD - 40));
      }
    }
  }

  // ---------- 更新逻辑 ----------

  updatePlayerMovement() {
    const p = this.player;
    let vx = 0, vy = 0;
    if (this.joystick.active) {
      const dx = this.joystick.dx, dy = this.joystick.dy;
      const m = Math.hypot(dx, dy);
      if (m > 0) {
        const strength = Math.min(1, m / 60);
        vx = (dx / m) * strength;
        vy = (dy / m) * strength;
      }
    }
    const k = this.keys;
    if (k.A.isDown || k.LEFT.isDown) vx -= 1;
    if (k.D.isDown || k.RIGHT.isDown) vx += 1;
    if (k.W.isDown || k.UP.isDown) vy -= 1;
    if (k.S.isDown || k.DOWN.isDown) vy += 1;
    const len = Math.hypot(vx, vy);
    if (len > 0) {
      vx = (vx / len) * p.speed;
      vy = (vy / len) * p.speed;
      p.facing.x = vx / p.speed;
      p.facing.y = vy / p.speed;
    }
    p.setVelocity(vx, vy);
    p.playMove(len > 0, vx, vy);
  }

  updateEnemies(dt) {
    for (const e of this.enemies.getChildren()) {
      if (e.active) e.update(dt);
    }
  }

  updateBullets(dt) {
    const range = (this.bulletRange !== undefined) ? this.bulletRange : getData(this, 'balance').bulletRange;
    const px = this.player.x, py = this.player.y;
    for (const b of this.bullets.getChildren()) {
      if (!b.active) continue;
      if (b.isBoomerang) { // 回旋镖：减速 → 折返追踪玩家 → 回到手中消失（全程穿透，去回双程均可命中）
        b.life -= dt;
        b.rotation += b.spin * dt / 60;
        if (b.phase === 'out') {
          b.body.velocity.x *= (1 - 2.0 * dt);
          b.body.velocity.y *= (1 - 2.0 * dt);
          if (b.life <= 2.2) {
            b.phase = 'back';
            if (b.hitSet) b.hitSet.clear(); // 折返重置命中列表，使回程能够再次伤害敌人
            b.damage = Math.max(1, Math.round(b.damage * 0.6)); // 回程只结算 60%，避免"双程全额"导致等效 DPS 翻倍
          }
        } else {
          const a = Phaser.Math.Angle.Between(b.x, b.y, px, py);
          const sp = Math.min(560, Math.hypot(b.body.velocity.x, b.body.velocity.y) + 1500 * dt);
          b.setVelocity(Math.cos(a) * sp, Math.sin(a) * sp);
          if (Phaser.Math.Distance.Between(b.x, b.y, px, py) < 26) {
            if (this.fx && this.fx.dissipateBurst) this.fx.dissipateBurst(b.x, b.y, 0x70d6ff);
            b.disableBody(true, true);
            continue;
          }
        }
        if (b.life <= 0) {
          if (this.fx && this.fx.dissipateBurst) this.fx.dissipateBurst(b.x, b.y, 0x70d6ff);
          b.disableBody(true, true);
          continue;
        }
      }
      if (b.isAxe) { // 斧：伪重力 + 旋转 + 寿命
        b.body.velocity.y += 900 * dt;
        b.rotation += b.spin * dt / 60;
        b.life -= dt;
        if (b.life <= 0) {
          if (this.fx && this.fx.dissipateBurst) this.fx.dissipateBurst(b.x, b.y, 0xef7d57);
          b.disableBody(true, true);
          continue;
        }
      }
      // 玩家远程攻击上限 = aimDist（与可视圈对齐，不追屏外敌人）
      const maxBulletDist = this.aimDist || Math.min(540, range);
      if (Phaser.Math.Distance.Between(b.x, b.y, b.startX, b.startY) > maxBulletDist) {
        if (this.fx && this.fx.dissipateBurst) {
          const tint = b.isKnife ? 0x94b0c2 : (b.isAxe ? 0xef7d57 : (b.isBoomerang ? 0x70d6ff : 0xa5f3fc));
          this.fx.dissipateBurst(b.x, b.y, tint);
        }
        b.disableBody(true, true);
      }
    }
  }

  updateEnemyBullets() {
    for (const b of this.enemyBullets.getChildren()) {
      if (!b.active) continue;
      if (Phaser.Math.Distance.Between(b.x, b.y, b.startX, b.startY) > 540) {
        b.disableBody(true, true);
      }
    }
  }

  updatePickups() {
    const px = this.player.x, py = this.player.y;
    const magnetSpeed = (this.magnetSpeed !== undefined) ? this.magnetSpeed : getData(this, 'balance').gem.magnetSpeed;
    const attractAfter = this.gemAttractAfter || 3.5;
    for (const g of this.pickups.getChildren()) {
      if (!g.active) continue;
      const d = Phaser.Math.Distance.Between(g.x, g.y, px, py);
      if (!g.magnet && g.kind !== 'chest') {
        if (d < this.player.pickupRadius || (this.elapsed - (g.bornAt || 0)) >= attractAfter) {
          g.magnet = true;
        }
      }
      if (g.magnet) this.physics.moveTo(g, px, py, magnetSpeed);
    }
  }

  updateRegen(dt) {
    const lv = this.player.passiveLevels.ring || 0;
    const ringHeal = lv > 0 ? (0.2 * lv * dt) : 0;
    const extraHeal = (this.player.regenBps || 0) * dt;
    const total = ringHeal + extraHeal;
    if (total > 0) this.player.heal(total);
  }

  updateEndlessAchv() {
    if (!this.levelConfig.endless) return;
    if (this.elapsed >= 300) this.unlockAchv('endless5');
    if (this.elapsed >= 600) this.unlockAchv('endless10');
  }

  // ---------- 武器管理 ----------

  // ---------- 武器管理与合成羁绊系统 ----------

  addWeapon(id, level = 1) {
    const def = getData(this, 'weapons')[id];
    if (!def) return null;
    const safeLv = Math.max(1, parseInt(level, 10) || 1);
    const w = new this.weaponClasses[id](this, id, def, safeLv);
    w.level = safeLv;
    this.weapons.push(w);
    // 同名武器可能有多把（进化模式）：等级记录取最高，避免买第二把时把记录冲回 Lv1
    this.weaponLevels[id] = Math.max(this.weaponLevels[id] || 1, safeLv);
    if (this.weapons.length >= 6) this.unlockAchv('full_arsenal');
    return w;
  }

  // 武器合成：合并两把同种类且同等级的武器为更高等级武器
  synthesizeWeapons(id, level) {
    const safeLv = Math.max(1, parseInt(level, 10) || 1);
    const matches = this.weapons.filter(w => w.id === id && w.level === safeLv);
    if (matches.length < 2) return false;
    // 移除第二把
    const idx2 = this.weapons.lastIndexOf(matches[1]);
    if (idx2 !== -1) {
      this.weapons.splice(idx2, 1);
      if (matches[1] && matches[1].destroy) matches[1].destroy();
    }
    // 升级第一把
    const target = matches[0];
    const def = getData(this, 'weapons')[id];
    const maxLv = def ? (def.maxLevel || 8) : 8;
    target.level = Math.min(maxLv, target.level + 1);
    // 同名多把时，等级记录取剩余所有实例的最高值（与 sellWeapon / addWeapon 的口径一致）
    const rest = this.weapons.filter(w => w.id === id).map(w => w.level);
    this.weaponLevels[id] = Math.max(target.level, ...rest);
    audio.evolve();
    this.fx.pickupBurst(this.player.x, this.player.y);
    return true;
  }

  // 武器出售回收：进化模式支持变卖不需要的武器，回收金币并释放栏位（保留至少 1 把武器）
  sellWeapon(index) {
    if (this.weapons.length <= 1) return null;
    if (index < 0 || index >= this.weapons.length) return null;
    const w = this.weapons[index];
    const sellPrice = Math.max(12, Math.round(15 * (w.level || 1)));
    this.weapons.splice(index, 1);
    if (w && w.destroy) w.destroy();
    // 重新计算武器最高等级记录
    const remaining = this.weapons.filter(item => item.id === w.id);
    if (remaining.length > 0) {
      this.weaponLevels[w.id] = Math.max(...remaining.map(item => item.level));
    } else {
      delete this.weaponLevels[w.id];
    }
    this.coins += sellPrice;
    try { audio.coin(); } catch (e) {}
    return { name: w.def.name, price: sellPrice };
  }

  // 武器羁绊检测（持有 3 把同名武器触发初级羁绊，持有 6 把触发终极羁绊；不同武器无羁绊）
  getSynergyBonus(id) {
    const count = this.weapons.filter(w => w.id === id).length;
    const res = { count, tier: 0, dmgMul: 1, cdMul: 1, extraProj: 0, pierce: 0 };
    if (count >= 6) {
      res.tier = 2;
      res.dmgMul = 1.35; // 6件羁绊：伤害 +35%（下调防数值膨胀）
      res.cdMul = 0.82;  // 冷却 -18%
      res.extraProj = 1; // 额外弹道 +1
      res.pierce = 1;
    } else if (count >= 3) {
      res.tier = 1;
      res.dmgMul = 1.15; // 3件羁绊：伤害 +15%
      res.cdMul = 0.92;  // 冷却 -8%
      res.extraProj = 1; // 额外弹道 +1
      res.pierce = 1;
    }
    return res;
  }

  // 获取当前所有已激活的羁绊描述列表（用于商店和UI展示）
  getActiveSynergies() {
    const counts = {};
    for (const w of this.weapons) {
      counts[w.id] = (counts[w.id] || 0) + 1;
    }
    const list = [];
    const SYNERGY_NAMES = {
      wand:       { name: '魔杖',   3: '【秘法共鸣 3】法术伤害 +15%，魔杖弹道 +1', 6: '【天界大魔导 6】法术伤害 +35%，魔杖弹道 +1，冷却 -18%' },
      knife:      { name: '飞刀',   3: '【千刃之舞 3】攻击速度 +15%，飞刀伤害 +15%', 6: '【极影万刃 6】攻击速度 +35%，飞刀伤害 +35%，贯穿全场' },
      axe:        { name: '旋转斧', 3: '【狂暴旋风 3】近战伤害 +15%，旋转速度 +10%', 6: '【撼地裂斩 6】近战伤害 +35%，斧头体型扩大 1.4 倍' },
      whip:       { name: '圣光鞭', 3: '【圣辉庇护 3】全伤害 +15%，受击减免 +1 点', 6: '【神圣审判 6】全伤害 +35%，受击减免 +2 点，范围扩大 40%' },
      orbit:      { name: '护体环', 3: '【星辰守御 3】星体伤害 +15%，旋转半径 +15%', 6: '【恒星耀斑 6】星体伤害 +35%，全场阻隔远程敌弹' },
      holywater:  { name: '圣水',   3: '【炼金狂潮 3】燃烧伤害 +15%，持续时间 +20%', 6: '【灭世圣炎 6】烈焰伤害 +35%，燃烧面积扩大 40%' },
      lightning:  { name: '闪电',   3: '【狂雷天罚 3】雷电伤害 +15%，连锁目标 +1', 6: '【神明雷暴 6】雷电伤害 +35%，连锁目标 +2，范围雷击' },
      drain:      { name: '吸血环', 3: '【鲜血契印 3】伤害 +15%，全吸血 +3%', 6: '【永生血皇 6】伤害 +35%，全吸血 +6%，最大生命 +30' },
      boomerang:  { name: '回旋镖', 3: '【双生回旋 3】回旋镖伤害 +15%，弹道 +1', 6: '【狂风绝息 6】回旋镖伤害 +35%，弹道 +1，穿透全场' },
      spore:      { name: '毒孢子', 3: '【剧毒蔓延 3】毒雾伤害 +15%，爆炸范围 +15%', 6: '【天灾疫病 6】毒雾伤害 +35%，剧毒大范围弥漫' },
      laser:      { name: '激光',   3: '【聚能聚焦 3】激光穿透伤害 +15%，光束宽度 +25%', 6: '【湮灭光束 6】激光伤害 +35%，激光全屏扫射光爆' },
      frost:      { name: '冰霜',   3: '【极寒领域 3】冰霜伤害 +15%，全场减速至 70%', 6: '【绝对零度 6】冰霜伤害 +35%，冷却 -30%，碎骨冰爆' }
    };

    for (const [id, c] of Object.entries(counts)) {
      if (c >= 3 && SYNERGY_NAMES[id]) {
        const syn = SYNERGY_NAMES[id];
        list.push({
          id,
          name: syn.name,
          count: c,
          tier: c >= 6 ? 2 : 1,
          desc: c >= 6 ? syn[6] : syn[3]
        });
      }
    }
    return list;
  }

  // 切换瞄准模式（自动索敌 vs 鼠标光标手动指向）
  toggleAimMode() {
    if (this.isMobile) return; // 手动光标瞄准只适用于键鼠
    this.aimMode = (this.aimMode === 'auto') ? 'cursor' : 'auto';
    if (this.uiScene && this.uiScene.updateAimButton) {
      this.uiScene.updateAimButton(this.aimMode);
    }
    if (this.uiScene && this.uiScene.toast) {
      this.uiScene.toast(this.aimMode === 'cursor' ? '瞄准模式：手动光标 (X 键切换)' : '瞄准模式：全自动索敌 (X 键切换)');
    }
    if (this.aimMode === 'auto' && this.crosshairGfx) {
      this.crosshairGfx.setVisible(false);
    }
  }

  // 准星渲染（仅在手动光标模式且非移动端显示）
  updateCrosshair() {
    if (!this.crosshairGfx) return;
    if (this.aimMode !== 'cursor' || this.isMobile || this.gameOver || (this.player && this.player.dead)) {
      this.crosshairGfx.setVisible(false);
      return;
    }
    const ptr = this.input.activePointer;
    if (!ptr) {
      this.crosshairGfx.setVisible(false);
      return;
    }
    const wp = this.cameras.main.getWorldPoint(ptr.x, ptr.y);
    this.crosshairGfx.setVisible(true);
    this.crosshairGfx.clear();
    // 战术准星：中心圆环 + 四向刻度线
    this.crosshairGfx.lineStyle(1.5, 0x00ffff, 0.75);
    this.crosshairGfx.strokeCircle(wp.x, wp.y, 7);
    this.crosshairGfx.fillStyle(0x00ffff, 0.9);
    this.crosshairGfx.fillCircle(wp.x, wp.y, 1.5);
    this.crosshairGfx.lineBetween(wp.x - 13, wp.y, wp.x - 5, wp.y);
    this.crosshairGfx.lineBetween(wp.x + 5, wp.y, wp.x + 13, wp.y);
    this.crosshairGfx.lineBetween(wp.x, wp.y - 13, wp.x, wp.y - 5);
    this.crosshairGfx.lineBetween(wp.x, wp.y + 5, wp.x, wp.y + 13);
  }

  // 6件终极羁绊角色专属光环特效
  updateSynergyAura(time) {
    if (!this.synergyAuraGfx || !this.player || this.player.dead) {
      if (this.synergyAuraGfx) this.synergyAuraGfx.clear();
      return;
    }
    const counts = {};
    for (const w of this.weapons) counts[w.id] = (counts[w.id] || 0) + 1;
    const hasTier2 = Object.values(counts).some(c => c >= 6);
    if (!hasTier2) {
      this.synergyAuraGfx.clear();
      return;
    }
    this.synergyAuraGfx.clear();
    const px = this.player.x, py = this.player.y;
    const t = time / 1000;
    const r1 = 28 + Math.sin(t * 3.2) * 3;
    const r2 = 38 + Math.cos(t * 2.6) * 4;

    // 终极羁绊金色华丽光环
    this.synergyAuraGfx.lineStyle(2, 0xffd700, 0.45 + Math.sin(t * 4) * 0.15);
    this.synergyAuraGfx.strokeCircle(px, py, r1);
    this.synergyAuraGfx.lineStyle(1.5, 0xffea00, 0.28 + Math.cos(t * 3) * 0.1);
    this.synergyAuraGfx.strokeCircle(px, py, r2);

    // 4 颗围绕角色旋转的星芒粒子
    for (let i = 0; i < 4; i++) {
      const ang = t * 2.2 + (i * Math.PI / 2);
      const sx = px + Math.cos(ang) * (r2 + 2);
      const sy = py + Math.sin(ang) * (r2 + 2);
      this.synergyAuraGfx.fillStyle(0xfff59d, 0.85);
      this.synergyAuraGfx.fillCircle(sx, sy, 2.5);
    }
  }

  get passiveCount() {
    return Object.keys(this.player.passiveLevels).length;
  }

  // 属性硬上限逐档放开：只作用于无尽模式（每生存 2 分钟 +12%，最多翻倍），经典与进化模式恒为基准值
  statCap(key, base) {
    if (!this.levelConfig || !this.levelConfig.endless) return base;
    const rel = 1 + Math.min(1, Math.floor(this.elapsed / 120) * 0.12);
    return key === 'cdFloor' ? Math.max(0.3, base / rel) : base * rel;
  }

  spawnBullet(x, y, vx, vy, damage, texture = 'fx-energy-orb') {
    const b = this.bullets.get(x, y, texture);
    if (!b) return null;
    b.setTexture(texture);
    b.setActive(true).setVisible(true);
    b.setDepth(7);
    b.damage = damage;
    b.startX = x; b.startY = y;
    b.isAxe = false;
    b.isBoomerang = false;
    b.isKnife = (texture === 'fx-knife');
    b.phase = 'out';
    b.spin = 0;
    b.life = 0;
    b.hitSet = null;
    b.setRotation(0);
    const area = (this.player && this.player.attackArea) ? this.player.attackArea : 1.0;
    if (texture === 'fx-energy-orb') {
      b.setScale(0.85 * area);
      b.enableBody(true, x, y, true, true);
      b.body.setCircle(8, 8, 8);
      b.setBlendMode(Phaser.BlendModes.ADD);
      b.setTint(0x44d4ff);
    } else {
      b.setScale(1.75 * area); // 飞刀/飞斧等保留原比例
      b.enableBody(true, x, y, true, true);
      b.setBlendMode(Phaser.BlendModes.NORMAL);
      b.clearTint();
    }
    b.setVelocity(vx, vy);
    audio.shoot();
    return b;
  }

  spawnEnemyBullet(x, y, vx, vy, dmg, texture = 'fx-energy-orb', tint = 0xff7043) {
    const b = this.enemyBullets.get(x, y, texture);
    if (!b) return null;
    b.setTexture(texture).setActive(true).setVisible(true).setDepth(7);
    if (tint) b.setTint(tint); else b.clearTint();
    b.setBlendMode(Phaser.BlendModes.ADD);
    b.enableBody(true, x, y, true, true);

    // 圆球判定与尺寸重调（全模式远程攻击均为圆球）：
    // 进化模式：子弹显眼突出（缩放 1.35x，约 43px 视觉直径），核心碰撞圆半径 9（直径 18px，判定公平合理，杜绝原本范围过大的问题）
    // 关卡模式：经典光球（缩放 0.75x，约 24px 视觉直径），核心碰撞圆半径 7（直径 14px）
    if (this.isBrotato) {
      b.setScale(1.35);
      b.body.setCircle(9, 7, 7);
    } else {
      b.setScale(0.75);
      b.body.setCircle(7, 9, 9);
    }

    b.setVelocity(vx, vy);
    b.dmg = dmg;
    b.startX = x; b.startY = y;
    return b;
  }

  // 圣光鞭视觉：尺寸即判定矩形（宽高由武器侧乘好 attackArea）
  showWhip(cx, cy, side, range, height) {
    const img = this.add.image(cx, cy, 'fx-whip-slash')
      .setDisplaySize(range, height)
      .setFlipX(side < 0)
      .setDepth(7)
      .setAlpha(0.95);
    this.tweens.add({ targets: img, alpha: 0, duration: 160, onComplete: () => img.destroy() });
  }

  // 武器进化：标记 + 演出
  evolveWeapon(id) {
    const w = this.weapons.find(w => w.id === id);
    if (!w || w.evolved) return;
    w.evolved = true;
    audio.evolve();
    this.fx.pickupBurst(this.player.x, this.player.y);
    this.cameras.main.flash(250, 255, 220, 150);
    const def = getData(this, 'weapons')[id];
    if (def && def.evolve) this.uiScene.toast('武器进化：' + def.evolve.name);
  }

  // 圆形范围伤害（受攻击范围 attackArea 影响）
  dealDamageArea(x, y, radius, dmg) {
    const area = (this.player && this.player.attackArea) ? this.player.attackArea : 1.0;
    const effRadius = radius * area;
    for (const e of this.enemies.getChildren()) {
      if (e.active && Phaser.Math.Distance.Between(x, y, e.x, e.y) < effRadius) {
        this.dealDamage(e, dmg);
      }
    }
  }

  // 激光束视觉：从玩家指向目标方向的长条光束（高度即判定宽度，视觉=判定）
  showLaser(x, y, angle, length, height) {
    const img = this.add.image(x, y, 'fx-laser')
      .setOrigin(0, 0.5)
      .setRotation(angle)
      .setDisplaySize(length, height)
      .setDepth(8)
      .setBlendMode(Phaser.BlendModes.ADD)
      .setAlpha(0.9);
    this.tweens.add({ targets: img, alpha: 0, duration: 180, onComplete: () => img.destroy() });
  }

  // 冰霜新星视觉：扩散冰蓝圆环（半径即伤害判定半径）
  showFrost(x, y, radius) {
    const r = radius;
    const ring = this.add.circle(x, y, r * 0.3, 0x9bd7ff, 0.45).setDepth(8);
    this.tweens.add({
      targets: ring, radius: r, alpha: 0, duration: 320,
      onComplete: () => ring.destroy()
    });
  }

  lightningStrike(x, y) {
    const img = this.add.image(x, y - 24, 'fx-lightning-zig').setScale(1.7).setDepth(9); // 扩大 1.7 倍
    this.tweens.add({
      targets: img,
      alpha: 0,
      duration: 200,
      onComplete: () => img.destroy()
    });
    this.fx.pickupBurst(x, y);
  }

  // 巨魔王践踏特效：扩散冲击圈 + 震屏
  slamFx(x, y) {
    const ring = this.add.circle(x, y, 40, 0xef7d57, 0.5).setDepth(8);
    this.tweens.add({
      targets: ring,
      radius: 240,
      alpha: 0,
      duration: 350,
      onComplete: () => ring.destroy()
    });
    audio.slam();
    this.cameras.main.shake(200, 0.015);
  }

  // 带暴击判定的统一伤害入口，返回实际造成的伤害
  dealDamage(enemy, base, isDot = false) {
    let dmg = base;
    const crit = Math.random() < this.player.critChance;
    if (crit) {
      const critMul = (this.player && this.player.critDmgMul) ? this.player.critDmgMul : 1.5;
      dmg *= critMul;
      try { audio.crit(); } catch (e) { audio.hit(); }
    } else {
      audio.hit();
    }
    dmg = Math.round(dmg);
    enemy.takeDamage(dmg);
    this.showDamage(enemy.x, enemy.y, dmg, crit, isDot);

    // 极寒巫师专属【深冬之触】：命中给怪物附加 1.5s 寒霜减速 (降低移速 45%) 并染成冰蓝色
    if (this.player && this.player.charConfig && this.player.charConfig.id === 'frostmage' && enemy && enemy.active) {
      enemy.slowUntil = this.time.now + 1500;
      enemy._wasSlowed = true;
      if (enemy.flashUntil <= this.time.now) enemy.setTint(0x70d6ff);
    }

    // 生命吸血（Life Steal）：命中触发吸血回血（内置 0.12s 节流）
    if (this.player && (this.player.lifeSteal || 0) > 0 && Math.random() < this.player.lifeSteal) {
      const now = this.time.now;
      if (!this._lastStealTime || now - this._lastStealTime > 120) {
        this._lastStealTime = now;
        this.player.heal(1);
      }
    }

    return dmg;
  }

  // ---------- 生成 ----------

  scatterGroundDetails() {
    const tint = (this.levelConfig && this.levelConfig.tint) || 0xffffff;
    for (let i = 0; i < 150; i++) {
      const n = Phaser.Math.Between(1, 3);
      this.add.image(
        Phaser.Math.Between(40, WORLD - 40),
        Phaser.Math.Between(40, WORLD - 40),
        `tile-ground-detail-${n}`
      ).setDepth(1).setAlpha(0.75).setTint(tint);
    }
  }

  spawnEnemy(type, x, y, hpMul) {
    const cfgBase = getData(this, 'enemies').enemies[type];
    if (!cfgBase) return;
    if (this.enemies.countActive(true) >= this.enemyCap && cfgBase.behavior !== 'boss') return;
    const e = this.enemies.get();
    if (!e) return;

    if (x === undefined) {
      if (this.isBrotato) {
        // 进化模式：从 1120×680 竞技场边缘包抄刷出
        const side = Phaser.Math.Between(0, 3);
        const margin = 20;
        if (side === 0) {
          x = Phaser.Math.Between(margin, BROTO_W - margin);
          y = margin;
        } else if (side === 1) {
          x = Phaser.Math.Between(margin, BROTO_W - margin);
          y = BROTO_H - margin;
        } else if (side === 2) {
          x = margin;
          y = Phaser.Math.Between(margin, BROTO_H - margin);
        } else {
          x = BROTO_W - margin;
          y = Phaser.Math.Between(margin, BROTO_H - margin);
        }
      } else {
        const angle = Math.random() * Math.PI * 2;
        const r = 720;
        x = Phaser.Math.Clamp(this.player.x + Math.cos(angle) * r, 30, WORLD - 30);
        y = Phaser.Math.Clamp(this.player.y + Math.sin(angle) * r, 30, WORLD - 30);
      }
    }
    // 小怪成长：进化模式基于波次平滑缩放，普通模式基于时间
    const minutes = this.elapsed / 60;
    const diffE = (this.diffConfig && this.diffConfig.enemy) || { hp: 1, dmg: 1, speed: 1 };

    // 进化模式小怪全方位提升与严格硬上限（前两波温和热身，后续波次显著提升速度与生命）
    let evoWaveHp = 1;
    let evoWaveDmg = 1;
    let evoWaveSpeed = 1;
    if (this.isBrotato) {
      const wave = this.brotoWave || 1;
      if (wave === 1) {
        evoWaveHp = 0.85; // 第 1 波小怪生命降至 85%，温和热身
        evoWaveDmg = 0.90;
        evoWaveSpeed = 1.0;
      } else if (wave === 2) {
        evoWaveHp = 1.0;
        evoWaveDmg = 1.0;
        evoWaveSpeed = 1.0;
      } else {
        // 第 3 波起：移动速度、血量、攻击全方位提升，且每项均有硬上限
        evoWaveHp = Math.min(2.8, 1 + (wave - 2) * 0.11);       // 生命上限 2.8x
        evoWaveDmg = Math.min(2.0, 1 + (wave - 2) * 0.055);     // 伤害上限 2.0x
        evoWaveSpeed = Math.min(1.42, 1 + (wave - 2) * 0.028);  // 移速上限 1.42x (+42%)
      }
    }

    const timeHpScale = this.isBrotato ? 1.0 : (1 + minutes * 0.22);
    const timeDmgScale = this.isBrotato ? 1.0 : (1 + minutes * 0.05);
    const hpScale = timeHpScale * this.hpScaleMul * (hpMul || 1) * diffE.hp * evoWaveHp;
    const dmgScale = Math.min(3.0, timeDmgScale * diffE.dmg * evoWaveDmg);
    // 怪物移速硬上限 190（基准小怪 55~120，即使高波次+高难度最高也不超过 190，保留走位空间）
    const finalSpeed = Math.min(190, Math.round(cfgBase.speed * diffE.speed * evoWaveSpeed));
    let cfg = {
      ...cfgBase,
      id: type,
      damage: Math.round(cfgBase.damage * dmgScale),
      speed: finalSpeed
    };
    // 精英词缀：精英怪随机携带 1~2 条（进化模式按波次，经典按关卡进度/无尽；不再依赖"上次玩过的关卡"）
    if (cfgBase.elite) {
      const two = this.isBrotato
        ? (this.brotoWave >= 8)
        : (this.levelConfig.endless || this.levelId >= 4);
      const picked = Phaser.Utils.Array.Shuffle(Object.keys(AFFIXES)).slice(0, two ? 2 : 1);
      const names = [];
      for (const k of picked) {
        const a = AFFIXES[k];
        if (a.hp) cfg.hp = Math.round(cfg.hp * a.hp);
        if (a.speed) cfg.speed = Math.round(cfg.speed * a.speed);
        if (a.damage) cfg.damage = Math.round(cfg.damage * a.damage);
        if (a.split) cfg.split = true;
        if (a.healOnHit) cfg.healOnHit = a.healOnHit;
        if (a.tint !== undefined) cfg.tint = a.tint;
        names.push(a.name);
      }
      cfg.affixName = names.join('·') + ' ' + cfgBase.name;
    }
    e.spawn(x, y, cfg, hpScale);
    if (cfgBase.behavior === 'boss') {
      audio.boss();
      if (!this.isBrotato) this.uiScene.flashBoss(cfgBase.name);
    }
  }

  spawnPickup(x, y, kind, xp, texture) {
    // 场上拾取物上限：无尽模式长局防止无限积累（超限时回收落地最久的经验宝石）
    if (this.pickups.countActive(true) >= 240) {
      let oldest = null;
      for (const p of this.pickups.getChildren()) {
        if (p.active && p.kind === 'gem' && (!oldest || (p.bornAt || 0) < (oldest.bornAt || 0))) oldest = p;
      }
      if (oldest) oldest.despawn();
    }
    const g = this.pickups.get();
    if (!g) return;
    if (kind === 'gem' && xp > 0 && this.diffConfig && this.diffConfig.xpMul > 1) {
      xp = Math.max(1, Math.round(xp * this.diffConfig.xpMul));
    }
    g.spawn(x, y, kind, xp, texture);
  }

  // ---------- 战斗结算 ----------

  // 索敌上限统一为可视圈（aimDist），攻击范围词条最多再放大 20%，且不超过 420
  getNearestEnemies(n, maxDist) {
    this.updateNearestCache();
    const px = this.player.x, py = this.player.y;
    const cap = this.aimDist || 380;
    const area = (this.player && this.player.attackArea) ? this.player.attackArea : 1.0;
    const effDist = Math.min(420, Math.min(maxDist || cap, cap) * Math.min(1.2, area));
    const res = [];
    for (const e of (this._nearSorted || [])) {
      if (!e.active) continue;
      const d = Phaser.Math.Distance.Between(px, py, e.x, e.y);
      if (d <= effDist) {
        res.push(e);
        if (res.length >= n) break;
      } else {
        break; // _nearSorted 已按距离升序排列，超出距离后直接退出
      }
    }
    return res;
  }

  // 伤害飘字与暴击特写（暴击变大变黄震动，持续DOT伤害柔和缩小，普通伤害节流90ms）
  showDamage(x, y, dmg, crit, isDot = false) {
    const now = this.time.now;
    if (isDot) {
      if (!this._dotDmgT) this._dotDmgT = 0;
      if (now < this._dotDmgT) return;
      this._dotDmgT = now + 90;
    } else if (!crit) {
      if (now < (this._dmgT || 0)) return;
      this._dmgT = now + 90;
    } else {
      // 暴击特写：屏幕轻微顿挫震动（节流 110ms，避免高频暴击导致晃眼眩晕）
      if (!this._lastCritShake || now - this._lastCritShake > 110) {
        this._lastCritShake = now;
        this.cameras.main.shake(80, 0.005);
      }
      if (this.fx && this.fx.critBurst) {
        this.fx.critBurst(x, y);
      }
    }

    const t = this.add.text(
      x + Phaser.Math.Between(-10, 10),
      y - (crit ? 18 : (isDot ? 10 : 14)),
      crit ? `⚡${dmg}!` : String(dmg),
      {
        fontFamily: '"Microsoft YaHei", sans-serif',
        fontSize: crit ? '24px' : (isDot ? '11px' : '13px'),
        color: crit ? '#ffe600' : (isDot ? '#a8e6cf' : '#f4f4f4'),
        fontStyle: crit ? 'bold' : 'normal',
        stroke: crit ? '#7c2d12' : '#000000',
        strokeThickness: crit ? 4 : (isDot ? 2 : 3)
      }
    ).setOrigin(0.5).setDepth(crit ? 12 : (isDot ? 9 : 10)).setAlpha(isDot ? 0.8 : 1);

    if (crit) {
      t.setScale(0.7);
      this.tweens.add({
        targets: t,
        scale: 1.35,
        duration: 85,
        ease: 'Back.easeOut',
        onComplete: () => {
          if (t && t.active) {
            this.tweens.add({
              targets: t,
              scale: 1.0,
              duration: 110
            });
          }
        }
      });
      this.tweens.add({
        targets: t,
        y: y - 56,
        alpha: 0,
        duration: 620,
        ease: 'Quad.easeOut',
        onComplete: () => t.destroy()
      });
    } else if (isDot) {
      this.tweens.add({
        targets: t,
        y: y - 26,
        alpha: 0,
        duration: 380,
        ease: 'Linear',
        onComplete: () => t.destroy()
      });
    } else {
      this.tweens.add({
        targets: t,
        y: y - 38,
        alpha: 0,
        duration: 450,
        onComplete: () => t.destroy()
      });
    }
  }

  // 闪避飘字反馈
  showDodge(x, y) {
    const t = this.add.text(
      x + Phaser.Math.Between(-8, 8),
      y - 20,
      '闪避!',
      {
        fontFamily: '"Microsoft YaHei", sans-serif',
        fontSize: '18px',
        color: '#38bdf8',
        fontStyle: 'bold',
        stroke: '#000000', strokeThickness: 3
      }
    ).setOrigin(0.5).setDepth(12);
    this.tweens.add({
      targets: t,
      y: y - 52,
      alpha: 0,
      duration: 550,
      onComplete: () => t.destroy()
    });
  }

  // 木桶散布：关卡开始时铺在地图各处
  scatterBarrels(n) {
    for (let i = 0; i < n; i++) {
      this.spawnEnemy('barrel',
        Phaser.Math.Between(200, WORLD - 200),
        Phaser.Math.Between(200, WORLD - 200));
    }
  }

  onEnemyKilled(enemy) {
    this.kills++;
    audio.kill();
    this.fx.killBurst(enemy.x, enemy.y);

    // 鲜血僧侣专属【猩红嗜血】：击杀敌人 5% 概率立即恢复 1 点生命
    if (this.player && this.player.charConfig && this.player.charConfig.id === 'monk' && Math.random() < 0.05) {
      this.player.heal(1);
    }
    // 炼金术士专属【点金秘药】：击杀敌人 12% 概率额外掉落 1 枚金币
    if (this.player && this.player.charConfig && this.player.charConfig.id === 'alchemist' && Math.random() < 0.12) {
      this.spawnPickup(enemy.x, enemy.y, 'coin', 0, 'item-coin');
    }

    if (this.kills >= 100) this.unlockAchv('kill100');
    if (this.kills >= 500) this.unlockAchv('kill500');

    if (enemy.cfg.behavior === 'boss') { // Boss：金币奖励；死神系解锁成就
      const reward = Math.round(25 * ((this.diffConfig && this.diffConfig.goldMul) || 1));
      this.coins += reward;
      if (enemy.cfg.bossKind === 'reaper') this.unlockAchv('reaper_slayer');
      if (this.isBrotato) {
        // 进化模式 Boss 掉落 12 金币与战地宝箱
        const isBoss = true;
        const count = isBoss ? 12 : 3;
        for (let i = 0; i < count; i++) {
          this.spawnPickup(enemy.x + Phaser.Math.Between(-24, 24), enemy.y + Phaser.Math.Between(-24, 24), 'coin', 0, 'item-coin');
        }
        this.spawnPickup(enemy.x, enemy.y, 'chest', 0, 'ui-chest');
        enemy.despawn();
        // 进化模式第 20 波终幕：必须消灭全部存活 Boss 才提前登顶通关！
        if (this.brotoWave >= this.brotoMaxWave) {
          const remainingBosses = this.enemies.getChildren().some(e => e.active && e !== enemy && e.cfg && e.cfg.behavior === 'boss');
          if (!remainingBosses) {
            if (this.uiScene) this.uiScene.toast('👑 终幕双首领已被全数消灭！进化登顶！');
            this.brotoWaveActive = false;
            this.time.delayedCall(800, () => this._endBrotoWave());
          } else {
            if (this.uiScene) this.uiScene.toast('⚡ 击破一名终幕首领！继续击杀剩余首领！');
          }
        } else {
          this.brotoWaveActive = false;
          this._endBrotoWave();
        }
        return;
      } else if (!this.levelConfig.endless) {
        enemy.despawn();
        this.triggerGameOver(true);
        return;
      } else {
        enemy.despawn();
        this.uiScene.toast('Boss 已被击败！金币 +' + reward);
        return;
      }
    }
    if (enemy.cfg.goldGoblin) { // 黄金哥布林：大额奖励
      for (let i = 0; i < 6; i++) this.spawnPickup(enemy.x + Phaser.Math.Between(-40, 40), enemy.y + Phaser.Math.Between(-40, 40), 'coin', 0, 'item-coin');
      this.spawnPickup(enemy.x, enemy.y, 'gem', 30, 'item-gem-xp-3');
      this.spawnPickup(enemy.x + 20, enemy.y, 'chicken', 0, 'item-chicken');
      this.unlockAchv('goblin_hunter');
      this.uiScene.toast('黄金哥布林！大量奖励');
      enemy.despawn();
      return;
    }
    if (enemy.cfg.barrel) { // 木桶：随机战利品，概率炸桶
      const r = Math.random();
      if (r < 0.4) for (let i = 0; i < 3; i++) this.spawnPickup(enemy.x + Phaser.Math.Between(-14, 14), enemy.y + Phaser.Math.Between(-14, 14), 'coin', 0, 'item-coin');
      else if (r < 0.65) this.spawnPickup(enemy.x, enemy.y, 'chicken', 0, 'item-chicken');
      else if (r < 0.85) this.spawnPickup(enemy.x, enemy.y, 'gem', 8, 'item-gem-xp-2');
      else { // 炸药桶：AOE 清场
        this.dealDamageArea(enemy.x, enemy.y, 220, 260);
        this.slamFx(enemy.x, enemy.y);
        audio.slam();
      }
      enemy.despawn();
      return;
    }
    if (enemy.cfg.split) { // 分裂词缀：死亡裂成两只蝙蝠
      for (let i = 0; i < 2; i++) this.spawnEnemy('bat', enemy.x + Phaser.Math.Between(-30, 30), enemy.y + Phaser.Math.Between(-30, 30));
    }

    // ===== 进化模式：金币掉落减少 1.5 倍，宝箱掉落速度减少 3 倍 =====
    if (this.isBrotato) {
      // 金币掉落：精英怪 3 金币，血厚怪 1 金币，普通怪 60% 掉 1 金币
      const count = enemy.cfg.elite ? 3 : (enemy.cfg.hp >= 20 ? 1 : (Math.random() < 0.60 ? 1 : 0));
      for (let i = 0; i < count; i++) {
        this.spawnPickup(
          enemy.x + Phaser.Math.Between(-22, 22),
          enemy.y + Phaser.Math.Between(-22, 22),
          'coin', 0, 'item-coin'
        );
      }
      // 经验宝石：进化模式的唯一升级来源（掉率低于经典模式，成长仍以波次商店为主）
      if (Math.random() < 0.55) {
        const tex = enemy.cfg.xp >= 5 ? 'item-gem-xp-3' : enemy.cfg.xp >= 3 ? 'item-gem-xp-2' : 'item-gem-xp';
        this.spawnPickup(
          enemy.x + Phaser.Math.Between(-16, 16),
          enemy.y + Phaser.Math.Between(-16, 16),
          'gem', enemy.cfg.xp, tex
        );
      }
      // 精英怪 33% 掉落宝箱 (原 100%)，小怪 1.2% (原 4%)
      if ((enemy.cfg.elite && Math.random() < 0.33) || Math.random() < 0.012) {
        this.spawnPickup(enemy.x, enemy.y, 'chest', 0, 'ui-chest');
      }
      enemy.despawn();
      return;
    }

    if (enemy.cfg.elite) { // 精英掉宝箱 + 撒金币：拾取立即升级
      this.spawnPickup(enemy.x, enemy.y, 'chest', 0, 'ui-chest');
      for (let i = 0; i < 3; i++) this.spawnPickup(enemy.x + (i - 1) * 26, enemy.y, 'coin', 0, 'item-coin');
      enemy.despawn();
      return;
    }

    const luck = this.player.luck;
    const roll = Math.random();
    if (roll < 0.02 + 0.01 * luck) this.spawnPickup(enemy.x, enemy.y, 'chicken', 0, 'item-chicken');
    else if (roll < 0.10 + 0.02 * luck) this.spawnPickup(enemy.x, enemy.y, 'coin', 0, 'item-coin');
    else {
      const tex = enemy.cfg.xp >= 5 ? 'item-gem-xp-3' : enemy.cfg.xp >= 3 ? 'item-gem-xp-2' : 'item-gem-xp';
      this.spawnPickup(enemy.x, enemy.y, 'gem', enemy.cfg.xp, tex);
    }
    enemy.despawn();
  }

  // 成就解锁（首次解锁时发奖励金币并弹提示）
  unlockAchv(id) {
    const def = getData(this, 'achievements').list.find(a => a.id === id);
    if (!def) return;
    if (meta.unlockAchievement(id)) {
      meta.addGold(def.reward);
      if (this.uiScene) this.uiScene.toast('成就解锁：' + def.name + '（+' + def.reward + ' 金币）');
    }
  }

  collectPickup(pk) {
    if (!pk.active || this.gameOver) return;
    this.fx.pickupBurst(pk.x, pk.y);
    if (pk.kind === 'gem') {
      audio.gem();
      const ups = this.xpSystem.add(pk.xp);
      if (ups > 0) this.onLevelUp();
    } else if (pk.kind === 'coin') {
      audio.coin();
      // === 商店永久强化：点金术（金币掉落加成，进化模式不生效）===
      const greedBonus = !this.isBrotato ? (1 + 0.1 * (meta.getShopLevel('greed') || 0)) : 1.0;
      // 进化模式金币减少 1.5 倍（基础 3 金币，普通模式为 5 金币）
      const baseCoin = this.isBrotato ? 3 : 5;
      // 难度金币加成对拾取同样生效（此前只作用于 Boss 奖励，与界面文案不符）
      const diffGold = (this.diffConfig && this.diffConfig.goldMul) || 1;
      this.coins += Math.round(baseCoin * greedBonus * diffGold);
      if (this.coins >= 150) this.unlockAchv('rich');
    } else if (pk.kind === 'chest') {
      audio.heal();
      try { audio.coin(); } catch (e) {}
      if (this.isBrotato) {
        const bonusCoins = Phaser.Math.Between(15, 25);
        this.coins += bonusCoins;
        this.player.heal(20);
        const buffs = [
          { name: '力量涌动', run: p => { p.extraDmgMul = (p.extraDmgMul || 1) * 1.04; }, text: '伤害 +4%' },
          { name: '体魄强韧', run: p => { p.extraMaxHp = (p.extraMaxHp || 0) + 10; p.heal(10); }, text: '生命上限 +10' },
          { name: '疾行之风', run: p => { p.extraSpeedMul = (p.extraSpeedMul || 1) * 1.04; }, text: '移速 +4%' },
          { name: '硬化重铠', run: p => { p.extraArmor = (p.extraArmor || 0) + 1; }, text: '护甲 +1 点' },
          { name: '致命专注', run: p => { p.extraCrit = (p.extraCrit || 0) + 0.03; }, text: '暴击 +3%' },
          { name: '轻灵身法', run: p => { p.dodgeRate = (p.dodgeRate || 0) + 0.025; }, text: '闪避 +2.5%' },
          { name: '磁能矩阵', run: p => { p.extraPickupMul = (p.extraPickupMul || 1) * 1.12; }, text: '磁力 +12%' },
          { name: '灵光乍现', run: p => { p.extraCdMul = (p.extraCdMul || 1) * 0.965; }, text: '冷却 -3.5%' }
        ];
        const buff = Phaser.Utils.Array.GetRandom(buffs);
        try {
          buff.run(this.player, this);
        } catch (e) {
          console.warn('Chest buff apply error:', e);
        }
        if (this.uiScene) {
          this.uiScene.toast(`🎁 开启宝箱！+${bonusCoins} 金币，${buff.name}（${buff.text}）！`);
        }
      } else {
        this.player.heal(30);
        this.onLevelUp(); // 经典模式：宝箱 = 立即升级
      }
    } else if (pk.kind === 'chicken') {
      audio.heal();
      this.player.heal(20);
    }
    pk.despawn();
  }

  // 升级选项重掷：先消耗免费次数（商店购买），再花费局内金币，次数越多越贵
  rerollCost() { return this.freeRerolls > 0 ? 0 : 20 + this.rerollCount * 15; }

  rerollLevelUps() {
    if (!this.levelUpActive || this.gameOver) return false;
    const cost = this.rerollCost();
    if (cost === 0) {
      this.freeRerolls--;
    } else {
      if (this.coins < cost) return false;
      this.coins -= cost;
    }
    this.rerollCount++;
    audio.reroll();
    this.uiScene.showLevelUp(this.upgradeSystem.roll3());
    return true;
  }

  // 接受诅咒选项
  takeCurse(id) {
    const c = CURSES.find(c => c.id === id);
    if (!c || this.cursesTaken[id]) return;
    this.cursesTaken[id] = true;
    c.apply(this.player);
    audio.evolve();
    this.uiScene.toast('诅咒接受：' + c.name);
  }

  // Boss 狂暴演出
  onBossEnrage(boss) {
    audio.boss();
    this.cameras.main.shake(250, 0.012);
    this.uiScene.toast('⚠ ' + (boss.cfg.name || 'Boss') + ' 进入狂暴！');
  }

  // ---------- 升级流程 ----------

  onLevelUp() {
    if (this.gameOver) return;
    this.pendingLevelUps++;
    if (!this.levelUpActive && !this._suppressLevelUp) this.processLevelUps();
  }

  processLevelUps() {
    this.levelUpActive = true;
    audio.levelup();
    this.scene.pause();
    this.uiScene.showLevelUp(this.upgradeSystem.roll3());
  }

  chooseUpgrade(opt) {
    if (this.gameOver || !this.levelUpActive) return;
    this.upgradeSystem.apply(opt);
    if (opt.kind === 'weapon' && this.weaponLevels[opt.id] >= getData(this, 'weapons')[opt.id].maxLevel) {
      this.unlockAchv('weapon_max');
    }
    this.pendingLevelUps--;
    if (this.pendingLevelUps > 0) {
      this.processLevelUps();
    } else {
      this.levelUpActive = false;
      this.scene.resume();
    }
  }

  // ---------- 结束 ----------

  triggerGameOver(victory, forfeit) {
    if (this.gameOver) return;
    this.gameOver = true;
    this.victory = !!victory;
    // 强制关闭升级弹窗，避免结算画面与卡片叠层
    this.levelUpActive = false;
    this.pendingLevelUps = 0;
    this.uiScene.hideLevelUp();
    if (this.isBrotato) {
      // 进化模式：自成一套进度（setEvoBest），绝不写经典关卡的 cleared / 最佳纪录 / 成就。
      // 之前这里会复用 registry 里"上次玩过的经典关卡 id"，导致进化登顶被记成通关某经典关。
    } else if (this.levelConfig && this.levelConfig.endless) {
      // 无尽模式（第 14 关）：阵亡或放弃时记录最佳生存时间
      meta.setBest(this.levelId, this.elapsed, true, this.difficulty);
    } else if (victory) { // 通关解锁下一关 + 相关成就（按难度独立记录关卡进度与最佳耗时）
      if (!this.levelConfig.fun) meta.setCleared(this.levelId, this.difficulty);
      meta.setBest(this.levelId, this.elapsed, false, this.difficulty);
      if (this.levelId === 1) this.unlockAchv('clear1');
      if (this.levelId >= 13) this.unlockAchv('clear_all');
    }
    if (this.isBrotato) {
      // 进化模式：局内金币用于波次军备商店，不可带回局外！
      // 带出金币 = 击杀数，但按波次设上限，避免刷金速度远超经典模式
      this.brotatoGoldCap = 150 + (this.brotoWave || 1) * 20;
      this.brotatoGoldEarned = Math.min(Math.max(0, this.kills || 0), this.brotatoGoldCap);
      meta.addGold(this.brotatoGoldEarned);
    } else {
      meta.addGold(this.coins); // 普通关卡模式：本局金币存入银行
    }
    this.enemies.getChildren().forEach(e => { if (e.active) e.setVelocity(0, 0); });
    this.uiScene.showGameOver(this.victory, this.elapsed, this.kills, !!forfeit);
  }

  // ---------- 土豆兄弟竞技场模式 ----------

  // 绘制竞技场围墙（视觉装饰用）
  _drawArenaWalls(w, h) {
    const g = this.add.graphics().setDepth(2);
    // 外围厚框
    g.lineStyle(12, 0x3a2a1a, 1);
    g.strokeRect(6, 6, w - 12, h - 12);
    g.lineStyle(4, 0x6b4a2a, 0.8);
    g.strokeRect(14, 14, w - 28, h - 28);
    // 四角装饰
    const corners = [[0,0],[w,0],[0,h],[w,h]];
    corners.forEach(([cx,cy]) => {
      g.fillStyle(0x6b4a2a, 0.9);
      g.fillRect(cx < w/2 ? cx : cx-20, cy < h/2 ? cy : cy-20, 20, 20);
    });
    // 简单地面装饰
    for (let i = 0; i < 30; i++) {
      const x = Phaser.Math.Between(40, w - 40);
      const y = Phaser.Math.Between(40, h - 40);
      const n = Phaser.Math.Between(1, 3);
      this.add.image(x, y, `tile-ground-detail-${n}`).setDepth(1).setAlpha(0.6);
    }
  }

  // 开始某波次
  _startBrotoWave(wave) {
    this.brotoWave = wave;
    const dur = BROTO_WAVE_DURATIONS[Math.min(wave - 1, BROTO_WAVE_DURATIONS.length - 1)];
    this.brotoWaveDuration = dur;
    this.brotoWaveTimer = dur;
    this.brotoWaveActive = true;
    // 通知 UIScene 刷新波次显示
    if (this.uiScene) {
      const isBoss = wave >= this.brotoMaxWave;
      this.uiScene.toast(isBoss ? `⚔ 终幕决战！Boss 来袭！` : `▶ 第 ${wave} 波开始！`);
    }
    // 宝箱爆率减少 3 倍：取消波次开局无条件赠送宝箱，战地宝箱空投间隔从 20s 增加至 60s
    this._brotoChestTimer = 60;

    // Boss 波：第 10 波精英突袭，第 20 波终极 Boss
    if (wave >= this.brotoMaxWave) {
      this.time.delayedCall(1500, () => {
        this.spawnEnemy('reaper', BROTO_W / 2 - 200, BROTO_H / 2);
        this.spawnEnemy('trollKing', BROTO_W / 2 + 200, BROTO_H / 2);
      });
    } else if (wave === 10) {
      this.time.delayedCall(1000, () => this.spawnEnemy('troll', BROTO_W / 2, BROTO_H / 2 - 150));
    }
  }

  // 每帧更新倒计时与周期性宝箱空投（在 update 中调用）
  _updateBrotoTimer(dt) {
    if (!this.brotoWaveActive || this.gameOver || this.levelUpActive) return;
    this.brotoWaveTimer -= dt;

    // 战斗中每 60 秒空投一个战地宝箱 (原 20 秒，空投频率减少 3 倍)
    this._brotoChestTimer = (this._brotoChestTimer || 60) - dt;
    if (this._brotoChestTimer <= 0) {
      this._brotoChestTimer = 60;
      this.spawnPickup(
        Phaser.Math.Between(160, BROTO_W - 160),
        Phaser.Math.Between(140, BROTO_H - 140),
        'chest', 0, 'ui-chest'
      );
      if (this.uiScene) this.uiScene.toast('🎁 战地宝箱空投降临！速去开启！');
    }

    if (this.brotoWaveTimer <= 0) {
      if (this.brotoWave >= this.brotoMaxWave) {
        // 终幕波不设时限：登顶只认"全歼双首领"，不允许靠躲 60 秒过关。
        // 但为避免低 DPS 构筑陷入"打不死也死不了"的永久僵持，每 20 秒给存活首领叠一层狂暴。
        this.brotoWaveTimer = 20;
        // 每 20 秒叠一层（1.25 倍率），封顶 10 层（约 9.3 倍伤害），避免数值失控
        const RAGE_CAP = 10;
        const stacked = this._brotoFinalRage < RAGE_CAP;
        if (stacked) this._brotoFinalRage++;
        let raged = 0;
        if (stacked) {
          this.enemies.getChildren().forEach(e => {
            if (e.active && e.cfg && e.cfg.behavior === 'boss') {
              e.cfg.damage = Math.max(1, Math.round(e.cfg.damage * 1.25));
              e.speed = Math.round(e.speed * 1.08);
              raged++;
            }
          });
        }
        if (this.uiScene) {
          // 提示按真实倍率（1.25^n）换算，而不是层数×25%
          const pct = Math.round((Math.pow(1.25, this._brotoFinalRage) - 1) * 100);
          this.uiScene.toast(raged > 0
            ? `⚔ 终幕僵持！首领狂暴 ${this._brotoFinalRage} 层（伤害 +${pct}%）`
            : (stacked ? '⚔ 终幕：全歼双首领才能登顶！' : `⚔ 首领狂暴已达 ${RAGE_CAP} 层上限，尽快结束战斗！`));
        }
        return;
      }
      this.brotoWaveActive = false;
      this._endBrotoWave();
    }
  }

  // 波次结束：清场 + 强力吸取掉落金币 + 弹出进化强化商店
  _endBrotoWave() {
    if (this.gameOver) return;
    this.brotoWaveActive = false;
    // 清退存活小怪（保留 boss）并清除遗留子弹
    this.enemies.getChildren().forEach(e => {
      if (e.active && e.cfg && e.cfg.behavior !== 'boss') {
        this.fx.killBurst(e.x, e.y);
        e.despawn();
      }
    });
    this.enemyBullets.getChildren().forEach(b => { if (b.active) b.disableBody(true, true); });
    // 吸铁石：全场拾取物加速飞向玩家
    this.pickups.getChildren().forEach(pk => {
      if (pk.active) { pk.magnet = true; }
    });
    audio.coin();
    if (this.uiScene) {
      this.uiScene.toast(`第 ${this.brotoWave} 波守卫成功！全场金币自动回收`);
    }
    // 稍等吸取动画后，结算金币，回复生命，记录最高波次，弹出进化商店
    this.time.delayedCall(700, () => {
      if (this.gameOver) return;
      // 强制结算所有剩余拾取物（期间暂存升级弹窗，避免与商店界面重叠冲突）
      this._suppressLevelUp = true;
      this.pickups.getChildren().forEach(pk => {
        if (pk.active) this.collectPickup(pk);
      });
      this._suppressLevelUp = false;
      // 第 20 波终幕：守卫成功即直接登顶通关，不再进入无意义的商店
      if (this.brotoWave >= this.brotoMaxWave) {
        meta.setEvoBest(this.brotoMaxWave);
        this.triggerGameOver(true);
        return;
      }
      // 战后休整：自然恢复 35% 最大生命
      this.player.heal(Math.round(this.player.maxHp * 0.35));
      meta.setEvoBest(this.brotoWave);

      this.scene.pause();
      const weaponIds = this.weapons.map(w => w.id);
      this.scene.launch('WaveShopOverlay', {
        wave: this.brotoWave,
        maxWave: this.brotoMaxWave,
        coins: this.coins,
        lockedSlots: this.brotoLockedSlots,
        lockedItems: this.brotoLockedItems,
        weaponIds
      });
    });
  }

  // WaveShop 关闭后回调：开始下一波（由 WaveShopOverlay._startNextWave 调用）
  startNextBrotoWave(nextWave) {
    this.scene.resume();
    if (!this.scene.isActive('UIScene')) this.scene.launch('UIScene');
    if (nextWave > this.brotoMaxWave) {
      // 第 20 波 Boss 被击败 → 通关结算
      this.triggerGameOver(true);
      return;
    }
    if (this.pendingLevelUps > 0 && !this.levelUpActive) {
      this.processLevelUps();
    }
    this._startBrotoWave(nextWave);
  }
}
