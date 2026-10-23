import WeaponBase from './WeaponBase.js';

export default class Laser extends WeaponBase {
  fire() {
    const beams = this.stat('beams') + (this.evolved ? 2 : 0) + (this.synergy.extraProj || 0);
    const p = this.scene.player;
    let targets = [];
    if (this.scene.aimMode === 'cursor' && this.scene.input && this.scene.input.activePointer) {
      if (this.scene.getNearestEnemies(1).length === 0) return false;
      const ptr = this.scene.input.activePointer;
      const wp = this.scene.cameras.main.getWorldPoint(ptr.x, ptr.y);
      targets.push({ x: wp.x, y: wp.y });
      if (beams > 1) {
        targets.push(...this.scene.getNearestEnemies(beams - 1));
      }
    } else {
      targets = this.scene.getNearestEnemies(beams);
    }
    if (!targets.length) return false;
    const length = Math.min(420, this.aimCap * Math.min(1.2, this.area));
    const beamH = (this.evolved ? 26 : 14) * this.area;
    const halfWidth = beamH / 2;
    const used = new Set();
    for (const t of targets) {
      const a = Phaser.Math.Angle.Between(p.x, p.y, t.x, t.y);
      // 沿光束方向伤害所有敌人
      const cos = Math.cos(a), sin = Math.sin(a);
      for (const e of this.scene.enemies.getChildren()) {
        if (!e.active || used.has(e)) continue;
        const dx = e.x - p.x, dy = e.y - p.y;
        const proj = dx * cos + dy * sin;
        if (proj > 0 && proj < length) {
          const perp = Math.abs(-dx * sin + dy * cos);
          if (perp < halfWidth) { this.scene.dealDamage(e, this.damage); used.add(e); }
        }
      }
      this.scene.showLaser(p.x, p.y, a, length, beamH);
    }
    return true;
  }
}
