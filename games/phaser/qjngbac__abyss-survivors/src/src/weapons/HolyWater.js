import WeaponBase from './WeaponBase.js';

// 圣水：向随机近处投掷，落地形成持续火焰地带，圈内敌人周期性受击
export default class HolyWater extends WeaponBase {
  constructor(scene, id, def, level = 1) {
    super(scene, id, def, level);
    this.zones = [];
  }

  fire() {
    const count = this.stat('count') + (this.evolved ? 2 : 0) + (this.synergy.extraProj || 0);
    const radius = this.stat('radius') * (this.evolved ? 1.3 : 1) * this.area;
    const duration = this.stat('duration') * (this.evolved ? 1.5 : 1);
    const dmg = this.damage;

    for (let i = 0; i < count; i++) {
      const p = this.scene.player;
      const a = Math.random() * Math.PI * 2;
      const r = Phaser.Math.Between(40, 190);
      const x = p.x + Math.cos(a) * r;
      const y = p.y + Math.sin(a) * r;
      const img = this.scene.add.image(x, y, 'fx-flame-ground')
        .setDisplaySize(radius * 2, radius * 2)
        .setDepth(2).setAlpha(0.95);
      this.zones.push({ x, y, radius, duration, dmg, tick: 0, img, ft: 0 });
    }
    return true;
  }

  updateExtra(dt) {
    for (let i = this.zones.length - 1; i >= 0; i--) {
      const z = this.zones[i];
      z.duration -= dt;
      z.ft += dt;
      if (z.ft > 0.18) {
        z.ft = 0;
        z.img.setTexture(Math.random() < 0.5 ? 'fx-flame-ground' : 'fx-flame-ground-2');
      }
      z.tick -= dt;
      if (z.tick <= 0) {
        z.tick = 0.38;
        for (const e of this.scene.enemies.getChildren()) {
          if (e.active && Phaser.Math.Distance.Between(z.x, z.y, e.x, e.y) < z.radius) {
            this.scene.dealDamage(e, z.dmg, true);
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
