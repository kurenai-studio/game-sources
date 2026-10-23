import WeaponBase from './WeaponBase.js';

// 飞刀：朝玩家面朝方向快速连发，多把时扇形散开
export default class Knife extends WeaponBase {
  fire() {
    const count = this.stat('projectiles') * (this.evolved ? 2 : 1) + (this.synergy.extraProj || 0);
    const p = this.scene.player;
    const base = (p.aimAngle !== undefined) ? p.aimAngle : Math.atan2(p.facing.y, p.facing.x);
    const speed = 520;

    for (let i = 0; i < count; i++) {
      const angle = base + (i - (count - 1) / 2) * 0.14;
      const b = this.scene.spawnBullet(
        p.x, p.y,
        Math.cos(angle) * speed, Math.sin(angle) * speed,
        this.damage, 'fx-knife'
      );
      if (b && (this.evolved || this.synergy.pierce)) b.hitSet = new Set(); // 进化或羁绊穿透
    }
    return true;
  }
}
