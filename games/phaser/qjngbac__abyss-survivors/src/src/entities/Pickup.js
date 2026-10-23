// 拾取物：经验宝石（3 档颜色）/ 金币 / 烤鸡腿 / 精英宝箱。磁吸由 GameScene 每帧驱动。
export default class Pickup extends Phaser.Physics.Arcade.Sprite {
  constructor(scene) {
    super(scene, 0, 0, 'item-gem-xp');
    scene.add.existing(this);
    scene.physics.add.existing(this);
  }

  spawn(x, y, kind, xp, texture) {
    this.enableBody(true, x, y, true, true);
    this.kind = kind;
    this.setTexture(texture || kind);
    this.xp = xp || 1;
    this.magnet = false;
    this.bornAt = (this.scene && this.scene.elapsed) || 0;
    this.setVelocity(0, 0);
    this.setScale(kind === 'chest' ? 1.8 : 1.5);
    this.setDepth(4);
  }

  despawn() {
    this.disableBody(true, true);
  }
}
