import WeaponBase from './WeaponBase.js';

// 闪电：随机劈向场上的敌人，瞬时伤害 + 闪电视觉
export default class Lightning extends WeaponBase {
  fire() {
    const strikes = this.stat('strikes') + (this.evolved ? 3 : 0) + (this.synergy.tier ? (this.synergy.tier * 2) : 0);
    const p = this.scene.player;
    const maxDist = Math.min(420, this.aimCap * Math.min(1.2, this.area)); // 只劈可视圈内的怪
    const inRange = this.scene.enemies.getChildren().filter(e => e.active && Phaser.Math.Distance.Between(p.x, p.y, e.x, e.y) <= maxDist);
    if (!inRange.length) return false;

    Phaser.Utils.Array.Shuffle(inRange);
    const targets = inRange.slice(0, strikes);
    for (const e of targets) {
      this.scene.dealDamage(e, this.damage);
      this.scene.lightningStrike(e.x, e.y);
      const splashR = (this.evolved || this.synergy.tier >= 2) ? 85 : 45;
      const splashDmg = Math.round(this.damage * (this.evolved ? 0.5 : 0.35));
      this.scene.dealDamageArea(e.x, e.y, splashR * this.area, splashDmg);
    }
    return true;
  }
}
