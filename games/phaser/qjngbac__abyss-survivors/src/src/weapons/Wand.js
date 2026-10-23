import WeaponBase from './WeaponBase.js';
import getData from '../data.js';

// 魔杖：射向最近的敌人，随等级增加弹数
export default class Wand extends WeaponBase {
  fire() {
    const count = this.stat('projectiles') * (this.evolved ? 2 : 1) + (this.synergy.extraProj || 0);
    const targets = this.scene.getNearestEnemies(count, 520); // 仅锁定屏幕视野内的敌人
    if (!targets.length) return false;

    const player = this.scene.player;
    const speed = getData(this.scene, 'balance').bulletSpeed;
    let fired = 0;
    for (const t of targets) {
      const angle = Phaser.Math.Angle.Between(player.x, player.y, t.x, t.y);
      const b = this.scene.spawnBullet(
        player.x, player.y,
        Math.cos(angle) * speed, Math.sin(angle) * speed,
        this.damage, 'fx-energy-orb'
      );
      if (b) fired++;
    }
    // 子弹池耗尽时 spawnBullet 返回 null：一发都没打出去就不要进入冷却
    return fired > 0;
  }
}
