import WeaponBase from './WeaponBase.js';

// 吸血指环：以玩家为中心，对范围内多个敌人伸出血色虹吸之链，汲取生命治疗自身
export default class Drain extends WeaponBase {
  constructor(scene, id, def, level = 1) {
    super(scene, id, def, level);
    // 环绕暗红光环微光（随玩家移动，展示吸血辐射领域，不加最外圈红线）
    this.circle = scene.add.circle(0, 0, 160, 0x9b111e, 0.10)
      .setDepth(2);
  }

  updateExtra(dt) {
    const p = this.scene.player;
    const r = Math.min(this.aimCap, this.stat('radius') * (this.evolved ? 1.35 : 1) * this.area);
    if (this.circle) {
      this.circle.setPosition(p.x, p.y).setRadius(r).setVisible(!p.dead);
    }
  }

  fire() {
    const p = this.scene.player;
    if (p.dead) return false;

    // 1 级攻击 2 个目标，随等级提升攻击更多，进化翻倍
    const targetCount = (this.stat('targets') || 2) * (this.evolved ? 2 : 1) + (this.synergy.extraProj || 0);
    const radius = Math.min(this.aimCap, this.stat('radius') * (this.evolved ? 1.35 : 1) * this.area);

    const inRange = [];
    for (const e of this.scene.enemies.getChildren()) {
      if (!e.active) continue;
      const d = Phaser.Math.Distance.Between(p.x, p.y, e.x, e.y);
      if (d <= radius) {
        inRange.push({ e, d });
      }
    }
    if (!inRange.length) return false;

    // 优先吸取距离最近的多个目标
    inRange.sort((a, b) => a.d - b.d);
    const chosen = inRange.slice(0, targetCount);

    let dealtTotal = 0;
    for (const item of chosen) {
      const e = item.e;
      const dmg = this.scene.dealDamage(e, this.damage);
      dealtTotal += dmg;
      this.showSiphonFx(p.x, p.y, e.x, e.y);
    }

    if (dealtTotal > 0) {
      const frac = this.evolved ? 0.6 : (this.stat('healFrac') || 0.25);
      // 单次施放治疗上限 = 8% 最大生命：避免"目标数 × 单发伤害 × 0.6"导致每秒治疗远超血量上限（站桩不死）
      const healCap = Math.max(1, Math.round(p.maxHp * 0.08));
      const healAmt = Math.min(healCap, Math.max(1, Math.round(dealtTotal * frac)));
      p.heal(healAmt);
    }

    return true;
  }

  // 血色虹吸链与血珠回流动画演出
  showSiphonFx(px, py, ex, ey) {
    const line = this.scene.add.graphics().setDepth(8);
    line.lineStyle(4, 0x880808, 0.7);
    line.lineBetween(px, py, ex, ey);
    line.lineStyle(2, 0xff3333, 0.95);
    line.lineBetween(px, py, ex, ey);

    const hitOrb = this.scene.add.circle(ex, ey, 6, 0xff3333, 0.9).setDepth(8);
    const bloodOrb = this.scene.add.circle(ex, ey, 4, 0xffffff, 0.95).setDepth(9);

    this.scene.tweens.add({
      targets: bloodOrb,
      x: px,
      y: py,
      duration: 140,
      ease: 'Quad.easeIn',
      onComplete: () => { bloodOrb.destroy(); }
    });

    this.scene.tweens.add({
      targets: [line, hitOrb],
      alpha: 0,
      duration: 120,
      onComplete: () => {
        line.destroy();
        hitOrb.destroy();
      }
    });
  }

  destroy() {
    if (this.circle && this.circle.destroy) {
      this.circle.destroy();
      this.circle = null;
    }
  }
}
