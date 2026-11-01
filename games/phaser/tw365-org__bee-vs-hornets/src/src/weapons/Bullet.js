/**
 * 子彈實體類別
 */
export class Bullet extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y, texture) {
    super(scene, x, y, texture);
    this.damage = 15;
    this.piercing = false;
    this.isMissile = false;
    this.target = null;
    this.speed = 600;
    this.hitTargets = new Set();
  }

  fire(x, y, vx, vy, damage = 15, piercing = false, isMissile = false, target = null) {
    this.enableBody(true, x, y, true, true);
    this.setVelocity(vx, vy);
    this.damage = damage;
    this.piercing = piercing;
    this.isMissile = isMissile;
    this.target = target;
    this.speed = Math.sqrt(vx * vx + vy * vy) || 500;
    this.hitTargets.clear();

    if (isMissile) {
      this.setRotation(Math.atan2(vy, vx) + Math.PI / 2);
    } else {
      this.rotation = 0;
    }
  }

  preUpdate(time, delta) {
    super.preUpdate(time, delta);

    // 追蹤微導彈尋標邏輯
    if (this.isMissile && this.target && this.target.active) {
      const angleToTarget = Phaser.Math.Angle.Between(this.x, this.y, this.target.x, this.target.y);
      const currentAngle = this.rotation - Math.PI / 2;
      const newAngle = Phaser.Math.Angle.RotateTo(currentAngle, angleToTarget, 0.12);
      
      this.rotation = newAngle + Math.PI / 2;
      this.scene.physics.velocityFromRotation(newAngle, this.speed, this.body.velocity);
    }

    // 超出螢幕邊界自動回收（動態讀取物理世界邊界）
    const bounds = this.scene.physics.world.bounds;
    if (this.y < bounds.y - 30 || this.y > bounds.height + 30 || this.x < bounds.x - 30 || this.x > bounds.width + 30) {
      this.setActive(false);
      this.setVisible(false);
      this.body.stop();
    }
  }
}
