import WeaponBase from './WeaponBase.js';

// 护体环：能量宝石绕玩家旋转，接触伤害（每个敌人有独立受击冷却）
export default class Orbit extends WeaponBase {
  constructor(scene, id, def, level = 1) {
    super(scene, id, def, level);
    this.angle = 0;
    this.orbs = [];
    for (let i = 0; i < 8; i++) {
      this.orbs.push(scene.add.image(0, 0, 'fx-orb-protect').setDepth(7));
    }
  }

  updateExtra(dt) {
    const p = this.scene.player;
    const n = Math.min(8, this.stat('orbs') + (this.evolved ? 2 : 0) + (this.synergy.extraProj || 0));
    const radius = this.stat('radius') * (this.evolved ? 1.3 : 1) * this.area;
    const guardianBonus = (p && p.charConfig && p.charConfig.id === 'guardian') ? 1.30 : 1.0;
    this.angle += this.stat('rotSpeed') * guardianBonus * dt;

    const active = [];
    for (let i = 0; i < this.orbs.length; i++) {
      const orb = this.orbs[i];
      if (i < n) {
        const a = this.angle + i * ((Math.PI * 2) / n);
        orb.setPosition(p.x + Math.cos(a) * radius, p.y + Math.sin(a) * radius).setVisible(true);
        orb.setScale(1.2 * this.area);
        active.push(orb);
      } else {
        orb.setVisible(false);
      }
    }

    const hitDist = 26 * this.area;
    for (const e of this.scene.enemies.getChildren()) {
      if (!e.active) continue;
      e.orbCd = Math.max(0, (e.orbCd || 0) - dt);
      if (e.orbCd > 0) continue;
      for (const orb of active) {
        if (Phaser.Math.Distance.Between(orb.x, orb.y, e.x, e.y) < hitDist) {
          this.scene.dealDamage(e, this.damage);
          e.orbCd = 0.35;
          break;
        }
      }
    }
  }

  destroy() {
    if (this.orbs) {
      for (const orb of this.orbs) {
        if (orb && orb.destroy) orb.destroy();
      }
      this.orbs = [];
    }
  }
}
