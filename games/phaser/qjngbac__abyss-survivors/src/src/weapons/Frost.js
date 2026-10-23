import WeaponBase from './WeaponBase.js';

// 冰霜新星：以玩家为中心周期爆发寒霜，伤害并减速周围敌人
export default class Frost extends WeaponBase {
  fire() {
    const radius = Math.min(420, this.stat('radius') * (this.evolved ? 1.3 : 1) * this.area);
    const p = this.scene.player;
    for (const e of this.scene.enemies.getChildren()) {
      if (!e.active) continue;
      if (Phaser.Math.Distance.Between(p.x, p.y, e.x, e.y) < radius) {
        this.scene.dealDamage(e, this.damage);
        e.slowUntil = this.scene.time.now + (this.evolved ? 3000 : 2000);
      }
    }
    this.scene.showFrost(p.x, p.y, radius);
    return true;
  }
}
