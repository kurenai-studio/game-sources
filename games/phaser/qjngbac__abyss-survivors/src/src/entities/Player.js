import getData from '../data.js';
import meta from '../meta.js';
import audio from '../audio.js';

// 玩家：属性（被动等级 + 商店强化驱动）、四方向走路动画、受伤（护甲减伤）、复活甲、死亡。
export default class Player extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y, char) {
    super(scene, x, y, 'char-hero-idle');
    scene.add.existing(this);
    scene.physics.add.existing(this);
    this.setDepth(6);
    this.setScale(1.7);
    this.setCollideWorldBounds(true); // 不允许跑出世界边界（否则相机会跟丢）
    this.body.setSize(22, 22, true);
    this.body.setOffset(6, 8);

    const p = getData(scene, 'balance').player;
    this.charConfig = char;
    this.baseHp = p.hp + (char && char.hpBonus ? char.hpBonus : 0);
    this.baseSpeed = p.speed * (1 + (char && char.speedPct ? char.speedPct : 0));
    this.invulnTime = p.invulnTime;
    this.basePickupRadius = p.pickupRadius;
    this.startWeapon = (char && char.weapon) || 'wand';

    // 角色特有增益
    this.charDmgBonus = (char && char.damageBonus) ? (1 + char.damageBonus) : 1;
    this.charCdBonus = (char && char.cooldownBonus) ? char.cooldownBonus : 0;
    this.charCritBonus = (char && char.critBonus) ? char.critBonus : 0;
    this.charPickupBonus = (char && char.pickupBonus) ? (1 + char.pickupBonus) : 1;
    this.charTint = (char && char.tint !== undefined) ? char.tint : 0xffffff;
    if (this.charTint !== 0xffffff) this.setTint(this.charTint);

    // 被动道具等级表（由 UpgradeSystem 写入）；角色初始护甲
    this.passiveLevels = {};
    if (char && char.armor) this.passiveLevels.armor = char.armor;
    // 面朝方向（飞刀等方向性武器使用）
    this.facing = { x: 1, y: 0 };
    this.curDir = 'down';

    // 诅咒修正（升级诅咒选项写入）
    this.curseDmg = 1;    // 伤害倍率
    this.curseTaken = 1;  // 受到伤害倍率
    this.curseCd = 1;     // 冷却倍率
    this.curseDrain = 0;  // 每秒流失生命
    this.hpMulCurse = 1;  // 最大生命倍率

    // 局内/进化模式/宝箱属性强化增益
    this.extraMaxHp = 0;
    this.extraSpeedMul = 1.0;
    this.extraDmgMul = 1.0;
    this.extraArmor = 0;
    this.extraCrit = 0;
    this.extraPickupMul = 1.0;
    this.regenBps = 0;
    this.extraDodge = 0;
    this.extraCritDmg = 1.5;
    this.extraArea = 1.0;
    this.extraLifeSteal = 0;
    this.extraCdMul = 1;

    // 角色专属鲜明起始被动（基础属性已由 characters.json 初始化，此处仅配置专属独有机制与词条，严防重复叠加）
    const cid = char ? char.id : 'mage';
    if (cid === 'mage') {
      // 法师【奥术涌动】：初始范围 +15%（冷却缩减 -8% 已由 char.cooldownBonus 驱动）
      this.extraArea = (this.extraArea || 1.0) + 0.15;
    } else if (cid === 'rogue') {
      // 影刃刺客【疾影灵猫】：初始闪避 +15%（拾取磁力 +35% 已由 char.pickupBonus 驱动；闪避后 1.5s 迅步爆发由 hurt 触发）
      this.extraDodge = (this.extraDodge || 0) + 0.15;
    } else if (cid === 'monk') {
      // 鲜血僧侣【猩红嗜血】：初始吸血 +3%，生命秒回 +0.4/s（击杀 5% 概率回血由 onEnemyKilled 触发）
      this.extraLifeSteal = (this.extraLifeSteal || 0) + 0.03;
      this.regenBps = (this.regenBps || 0) + 0.4;
    } else if (cid === 'berserker') {
      // 狂战士【血怒狂暴】：暴击 +5% 与护甲 +1 已由 char 配置驱动；残血动态增伤最高 +40% 由 damageMult 实时计算
    } else if (cid === 'paladin') {
      // 圣骑士【神圣壁垒】：护甲 +2 与生命 +25 已由 char 配置驱动；受击 1 秒 50% 减伤神盾由 hurt 触发
    } else if (cid === 'guardian') {
      // 星辉守卫【天体引力】：拾取 +50% 与护甲 +2 已由 char 配置驱动；星辉护体环转速 +30% 由 Orbit 驱动
    } else if (cid === 'alchemist') {
      // 炼金术士【点金秘药】：生命秒回 +0.3/s（拾取 +25% 已由 char.pickupBonus 驱动；击杀 12% 掉落金币由 onEnemyKilled 触发）
      this.regenBps = (this.regenBps || 0) + 0.3;
    } else if (cid === 'thunderlord') {
      // 雷霆领主【雷暴感电】：初始暴击伤害 +30%（1.8x 起步；暴击率 +12% 已由 char.critBonus 驱动）
      this.extraCritDmg = (this.extraCritDmg || 1.5) + 0.30;
    } else if (cid === 'frostmage') {
      // 极寒巫师【深冬之触】：冷却 -10% 已由 char.cooldownBonus 驱动；攻击命中附带 1.5 秒 45% 寒霜减速由 dealDamage 驱动
    } else if (cid === 'ranger') {
      // 逐风游侠【疾风射手】：初始范围 +15%（移速 +12% 与暴击 +8% 已由 char 配置驱动；跑动增伤 10% 由 damageMult 驱动）
      this.extraArea = (this.extraArea || 1.0) + 0.15;
    }

    this.dead = false;
    this.invulnUntil = 0;
    this.reviveUsed = false; // 复活甲：每局限一次
    this.hp = this.maxHp;
  }

  // 综合瞄准朝向：支持鼠标指针精准指向与移动朝向双模
  get aimAngle() {
    if (this.scene && this.scene.aimMode === 'cursor' && this.scene.input && this.scene.input.activePointer) {
      const ptr = this.scene.input.activePointer;
      if (ptr.x > 0 || ptr.y > 0) {
        const worldPoint = this.scene.cameras.main.getWorldPoint(ptr.x, ptr.y);
        return Phaser.Math.Angle.Between(this.x, this.y, worldPoint.x, worldPoint.y);
      }
    }
    // 自动模式：静止状态下若附近有敌人则智能朝向最近敌人
    if (this.scene && this.scene.getNearestEnemies) {
      const nearest = this.scene.getNearestEnemies(1)[0];
      if (nearest && this.body && this.body.velocity.x === 0 && this.body.velocity.y === 0) {
        return Phaser.Math.Angle.Between(this.x, this.y, nearest.x, nearest.y);
      }
    }
    return Math.atan2(this.facing.y, this.facing.x);
  }

  // 难度系数对角色的影响（难度 2、3 下角色参数略低）
  get diffHpMul() { return (this.scene.diffConfig && this.scene.diffConfig.player.hp) || 1; }
  get diffDmgMul() { return (this.scene.diffConfig && this.scene.diffConfig.player.dmg) || 1; }
  get diffSpeedMul() { return (this.scene.diffConfig && this.scene.diffConfig.player.speed) || 1; }

  // 商店强化等级（进化模式全面隔离外界商店增幅，纯净基础数值起步）
  getShopLv(id) {
    if (this.scene && this.scene.isBrotato) return 0;
    return meta.getShopLevel(id) || 0;
  }

  // 属性硬上限：经典/进化模式恒定，只有无尽模式按生存时间逐档放开
  cap(key, base) {
    return (this.scene && this.scene.statCap) ? this.scene.statCap(key, base) : base;
  }

  // 商店永久强化与局内被动叠加计算（带属性硬上限控制，防止无限滚雪球；上限见 cap()）
  get speed() {
    let rogueSpd = 1.0;
    if (this._rogueBurstUntil && this.scene && this.scene.time && this.scene.time.now < this._rogueBurstUntil) {
      rogueSpd = 1.25; // 影刃刺客成功闪避后 1.5s 迅步爆发 +25% 移速
    }
    const raw = this.baseSpeed * (1 + 0.1 * (this.passiveLevels.boots || 0)) * (1 + 0.05 * this.getShopLv('swift')) * this.diffSpeedMul * (this.extraSpeedMul || 1) * rogueSpd;
    return Math.max(80, Math.min(this.cap('speed', 280), Math.round(raw)));
  }

  get maxHp() {
    const raw = (this.baseHp + 20 * (this.passiveLevels.heart || 0) + 15 * this.getShopLv('vitality') + (this.extraMaxHp || 0));
    const finalVal = Math.round(raw * (this.hpMulCurse || 1) * this.diffHpMul);
    return Math.max(30, Math.min(this.cap('maxHp', 320), finalVal));
  }

  get dmgBonus() {
    return Math.min(this.cap('dmg', 2.4), this.extraDmgMul || 1.0); // 额外伤害倍率上限 2.4 (+140%)
  }

  get damageMult() {
    const effExtraDmg = Math.min(this.cap('dmg', 2.4), Math.max(0.2, this.extraDmgMul || 1.0));
    let base = (1 + 0.1 * (this.passiveLevels.bracelet || 0)) * (1 + 0.05 * this.getShopLv('power')) * (this.curseDmg || 1) * this.charDmgBonus * this.diffDmgMul * effExtraDmg;
    // 狂战士专属：血怒狂暴（生命损失比例转化为全伤害加成，最高 +40%）
    if (this.charConfig && this.charConfig.id === 'berserker') {
      const lostHpFrac = Math.max(0, 1 - (this.hp / Math.max(1, this.maxHp)));
      base *= (1 + lostHpFrac * 0.40);
    }
    // 逐风游侠专属：奔袭蓄力（移动时全伤害加成 +10%）
    if (this.charConfig && this.charConfig.id === 'ranger' && this.body && (this.body.velocity.x !== 0 || this.body.velocity.y !== 0)) {
      base *= 1.10;
    }
    return base;
  }

  get pickupRadius() {
    const raw = this.basePickupRadius * (1 + 0.25 * (this.passiveLevels.magnet || 0)) * (1 + 0.12 * this.getShopLv('magnet')) * this.charPickupBonus * (this.extraPickupMul || 1);
    return Math.max(40, Math.min(this.cap('pickup', 200), Math.round(raw)));
  }

  get cooldownMult() {
    const baseCd = Math.max(0.2, (1 - 0.08 * (this.passiveLevels.hourglass || 0) - this.charCdBonus) * (1 - 0.04 * this.getShopLv('cooldown')) * (this.curseCd || 1) * (this.extraCdMul || 1));
    return Math.min(2, Math.max(this.cap('cdFloor', 0.6), baseCd));
  }

  get critChance() {
    const raw = 0.1 * (this.passiveLevels.coin || 0) + 0.03 * this.getShopLv('luck') + this.charCritBonus + (this.extraCrit || 0);
    return Math.max(0.0, Math.min(this.cap('crit', 0.5), Number(raw.toFixed(3))));
  }

  get luck() {
    return (this.passiveLevels.coin || 0) + this.getShopLv('luck');
  }

  get armor() {
    const raw = (this.passiveLevels.armor || 0) + (this.extraArmor || 0);
    return Math.max(-5, Math.min(this.cap('armor', 7), raw));
  }

  // 闪避几率（Dodge）：上限 40%
  get dodgeRate() {
    return Math.max(0, Math.min(this.cap('dodge', 0.4), Number((this.extraDodge || 0).toFixed(3))));
  }
  set dodgeRate(val) {
    if (typeof val === 'number') this.extraDodge = Math.max(0, Math.min(this.cap('dodge', 0.4), val));
  }

  // 暴击伤害倍率（Crit Damage）：基础 1.5x，上限 2.3x (+130%)
  get critDmgMul() {
    return Math.max(1.2, Math.min(this.cap('critDmg', 2.3), Number((this.extraCritDmg || 1.5).toFixed(2))));
  }
  set critDmgMul(val) {
    if (typeof val === 'number') this.extraCritDmg = Math.max(1.2, Math.min(this.cap('critDmg', 2.3), val));
  }

  // 攻击范围与弹道增幅（Attack Area）：基础 1.0x，上限 1.65x (+65%)
  get attackArea() {
    return Math.max(0.6, Math.min(this.cap('area', 1.65), Number((this.extraArea || 1.0).toFixed(2))));
  }
  set attackArea(val) {
    if (typeof val === 'number') this.extraArea = Math.max(0.6, Math.min(this.cap('area', 1.65), val));
  }

  // 生命吸血（Life Steal）：上限 8% 几率
  get lifeSteal() {
    return Math.max(0, Math.min(this.cap('lifeSteal', 0.08), Number((this.extraLifeSteal || 0).toFixed(3))));
  }
  set lifeSteal(val) {
    if (typeof val === 'number') this.extraLifeSteal = Math.max(0, Math.min(this.cap('lifeSteal', 0.08), val));
  }

  // 由 GameScene 每帧根据速度调用
  playMove(moving, vx, vy) {
    if (this.dead) return;
    try {
      if (!moving) {
        this.anims.stop();
        this.setTexture('char-hero-idle');
        if (this.charTint && this.charTint !== 0xffffff) this.setTint(this.charTint);
        return;
      }
      const dir = Math.abs(vx) >= Math.abs(vy) ? (vx > 0 ? 'right' : 'left') : (vy > 0 ? 'down' : 'up');
      if (dir !== this.curDir) {
        this.curDir = dir;
        this.play(`hero-walk-${dir}`, true);
        if (this.charTint && this.charTint !== 0xffffff) this.setTint(this.charTint);
      } else if (!this.anims.isPlaying) {
        this.play(`hero-walk-${dir}`, true);
        if (this.charTint && this.charTint !== 0xffffff) this.setTint(this.charTint);
      }
    } catch (e) {
      // 动画异常时退化为静帧，绝不让游戏停摆
      this.anims.stop();
      this.setTexture('char-hero-idle');
      if (this.charTint && this.charTint !== 0xffffff) this.setTint(this.charTint);
    }
  }

  hurt(dmg) {
    if (this.dead) return;
    const now = this.scene.time.now;
    if (now < this.invulnUntil) return;

    // 闪避判定（Dodge）：若触发闪避，完全免伤并飘出闪避反馈
    if (Math.random() < (this.dodgeRate || 0)) {
      if (this.charConfig && this.charConfig.id === 'rogue') {
        this._rogueBurstUntil = now + 1500; // 影刃刺客闪避成功获得 1.5 秒疾步加速
      }
      if (this.scene && this.scene.showDodge) {
        this.scene.showDodge(this.x, this.y);
      }
      audio.whoosh();
      return;
    }

    this.invulnUntil = now + this.invulnTime * 1000;

    // 圣骑士专属【神圣壁垒】：受击后 1 秒内受到后续伤害减免 50%
    let incomingDmg = dmg;
    if (this.charConfig && this.charConfig.id === 'paladin') {
      if (this._paladinShieldUntil && now < this._paladinShieldUntil) {
        incomingDmg = Math.max(1, Math.round(incomingDmg * 0.5));
      }
      this._paladinShieldUntil = now + 1000;
    }

    this.hp -= Math.max(1, Math.round(incomingDmg * (this.curseTaken || 1)) - this.armor); // 诅咒增伤 → 护甲减伤，保底 1
    audio.hurt();
    this.setTintFill(0xffffff);
    this.scene.time.delayedCall(80, () => { if (this.active) this.clearTint(); });
    this.scene.cameras.main.shake(120, 0.008);
    if (this.hp <= 0) {
      this.hp = 0;
      this.die();
    }
  }

  heal(n) {
    if (this.dead) return;
    this.hp = Math.min(this.maxHp, this.hp + n);
  }

  die() {
    // 复活甲：商店购买后，每局首次死亡原地满血复活（进化模式不生效）
    if (!this.reviveUsed && this.getShopLv('revive') > 0) {
      this.reviveUsed = true;
      this.dead = false;
      this.hp = this.maxHp;
      this.clearTint();
      this.setAlpha(1);
      this.invulnUntil = this.scene.time.now + 2500;
      audio.revive();
      this.scene.cameras.main.flash(400, 255, 255, 255);
      if (this.scene.uiScene) this.scene.uiScene.toast('⚡ 复活甲生效！无敌 2.5 秒');
      return;
    }
    this.dead = true;
    this.setVelocity(0, 0);
    this.setTint(0x666666);
    this.anims.stop();
    this.scene.triggerGameOver(false);
  }
}
