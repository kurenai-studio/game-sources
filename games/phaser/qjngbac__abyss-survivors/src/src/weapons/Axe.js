import WeaponBase from './WeaponBase.js';

// 旋转斧：向上抛出、受重力下坠，穿透一切（每把斧对每个敌人只结算一次）
export default class Axe extends WeaponBase {
  fire() {
    const count = this.stat('projectiles') * (this.evolved ? 2 : 1) + (this.synergy.extraProj || 0);
    const p = this.scene.player;
    const aimBiasX = (p.aimAngle !== undefined) ? Math.cos(p.aimAngle) * 140 : 0;
    for (let i = 0; i < count; i++) {
      const vx = (i - (count - 1) / 2) * 90 + Phaser.Math.Between(-25, 25) + aimBiasX;
      const b = this.scene.spawnBullet(p.x, p.y, vx, -480, this.damage, 'fx-axe');
      if (!b) continue;
      b.isAxe = true;
      b.spin = Phaser.Math.Between(0, 1) ? 540 : -540;
      if (this.evolved || this.synergy.tier >= 2) b.setScale(2.4);
      b.hitSet = new Set();
      b.life = 3.0;
    }
    return true;
  }
}
