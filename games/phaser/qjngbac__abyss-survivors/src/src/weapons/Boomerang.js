import WeaponBase from './WeaponBase.js';

// 回旋镖：掷出后减速转向飞回玩家，去回双程都可造成伤害（穿透）
export default class Boomerang extends WeaponBase {
  fire() {
    const count = this.stat('projectiles') * (this.evolved ? 2 : 1) + (this.synergy.extraProj || 0);
    const p = this.scene.player;
    const speed = 480;

    for (let i = 0; i < count; i++) {
      const angle = (i / count) * Math.PI * 2 + Math.PI / 4;
      const b = this.scene.spawnBullet(
        p.x, p.y,
        Math.cos(angle) * speed, Math.sin(angle) * speed,
        this.damage, 'fx-boomerang'
      );
      if (!b) continue;
      b.isBoomerang = true;
      b.phase = 'out';
      b.life = 4.0;
      b.hitSet = new Set();
      b.spin = 720;
    }
    return true;
  }
}
