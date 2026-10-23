import WeaponBase from './WeaponBase.js';

// 圣光鞭：横向长方形区域伤害；进化后同时抽打左右两侧
export default class Whip extends WeaponBase {
  constructor(scene, id, def, level = 1) {
    super(scene, id, def, level);
    this.side = 1;
  }

  fire() {
    // 与玩家索敌上限对齐：范围词条堆满时也不超过 480，避免"鞭子能打到 594 而别的武器只有 380"
    const range = Math.min(480, this.stat('range') * this.area);
    const height = this.stat('height') * this.area;
    const sides = this.evolved ? [1, -1] : [(this.side *= -1)];
    for (const side of sides) {
      const cx = this.scene.player.x + side * range / 2;
      const cy = this.scene.player.y;
      const rect = new Phaser.Geom.Rectangle(cx - range / 2, cy - height / 2, range, height);
      for (const e of this.scene.enemies.getChildren()) {
        if (e.active && Phaser.Geom.Rectangle.Contains(rect, e.x, e.y)) {
          this.scene.dealDamage(e, this.damage);
        }
      }
      this.scene.showWhip(cx, cy, side, range, height);
    }
    return true;
  }
}
