import WeaponBase from './WeaponBase.js';

// 毒孢子：抛出后缓慢追踪最近的敌人，留下移动毒雾领域（持续伤害 + 进化后强减速）
export default class Spore extends WeaponBase {
  constructor(scene, id, def, level = 1) {
    super(scene, id, def, level);
    this.zones = [];
  }

  fire() {
    const count = this.stat('count') + (this.evolved ? 1 : 0) + (this.synergy.extraProj || 0);
    const radius = this.stat('radius') * (this.evolved ? 1.25 : 1) * this.area;
    const duration = this.stat('duration') * (this.evolved ? 1.4 : 1);
    const dmg = this.damage;

    for (let i = 0; i < count; i++) {
      const p = this.scene.player;
      const a = Math.random() * Math.PI * 2;
      const r = Phaser.Math.Between(60, 220);
      const img = this.scene.add.image(p.x + Math.cos(a) * r, p.y + Math.sin(a) * r, 'fx-spore')
        .setDisplaySize(radius, radius)
        .setDepth(3).setAlpha(0.85).setTint(0x7ec850);
      this.zones.push({ x: img.x, y: img.y, radius, duration, dmg, tick: 0, img, ft: 0, slow: this.evolved });
    }
    return true;
  }

  updateExtra(dt) {
    for (let i = this.zones.length - 1; i >= 0; i--) {
      const z = this.zones[i];
      z.duration -= dt;
      z.ft += dt;
      // 毒雾缓慢追击最近的敌人
      const target = this.scene.getNearestEnemies(1)[0];
      if (target) {
        const a = Phaser.Math.Angle.Between(z.x, z.y, target.x, target.y);
        z.x += Math.cos(a) * 55 * dt;
        z.y += Math.sin(a) * 55 * dt;
      }
      z.img.setPosition(z.x, z.y);
      if (z.ft > 0.2) {
        z.ft = 0;
        z.img.setAlpha(z.img.alpha > 0.7 ? 0.6 : 0.85);
      }
      z.tick -= dt;
      if (z.tick <= 0) {
        z.tick = 0.38;
        for (const e of this.scene.enemies.getChildren()) {
          if (e.active && Phaser.Math.Distance.Between(z.x, z.y, e.x, e.y) < z.radius) {
            this.scene.dealDamage(e, z.dmg, true);
            if (z.slow) e.slowUntil = this.scene.time.now + 600; // 腐蚀毒云：强减速
          }
        }
      }
      if (z.duration <= 0) {
        z.img.destroy();
        this.zones.splice(i, 1);
      }
    }
  }

  destroy() {
    if (this.zones) {
      for (const z of this.zones) {
        if (z.img && z.img.destroy) z.img.destroy();
      }
      this.zones = [];
    }
  }
}
