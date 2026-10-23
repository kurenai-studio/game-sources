import Phaser from 'phaser';
import * as Config from '../config.js';

export default class Cannon {
  constructor(scene, x, isPlayer, terrain) {
    this.scene = scene;
    this.x = x;
    this.isPlayer = isPlayer;
    this.terrain = terrain;

    this.y = terrain.getHeightAt(x);
    this.angle = Config.DEFAULT_ANGLE;
    this.power = Config.DEFAULT_POWER;
    this.hp = Config.CANNON_HP;
    this.targetHp = Config.CANNON_HP;
    this.shield = 0;

    // Destructible parts
    this.barrelDamaged = false;
    this.wheelDamaged = false;

    this.graphics = scene.add.graphics();
    this.draw();
  }

  getEffectiveMaxPower() {
    if (this.barrelDamaged) {
      return Config.MAX_POWER * Config.BARREL_DAMAGE_POWER_REDUCTION;
    }
    return Config.MAX_POWER;
  }

  adjustAngle(delta) {
    if (this.wheelDamaged) return;
    this.angle = Phaser.Math.Clamp(
      this.angle + delta,
      Config.MIN_ANGLE,
      Config.MAX_ANGLE
    );
    this.draw();
  }

  adjustPower(delta) {
    const max = this.getEffectiveMaxPower();
    this.power = Phaser.Math.Clamp(
      this.power + delta,
      Config.MIN_POWER,
      max
    );
  }

  getBarrelTip() {
    const dir = this.isPlayer ? 1 : -1;
    return {
      x: this.x + dir * Math.cos(this.angle) * Config.BARREL_LENGTH,
      y: this.y - Math.sin(this.angle) * Config.BARREL_LENGTH,
    };
  }

  takeDamage(amount) {
    let remaining = amount;
    if (this.shield > 0) {
      const absorbed = Math.min(this.shield, remaining);
      this.shield -= absorbed;
      remaining -= absorbed;
    }
    this.targetHp = Math.max(0, this.targetHp - remaining);
  }

  heal(amount) {
    this.targetHp = Math.min(Config.CANNON_HP, this.targetHp + amount);
  }

  addShield(amount) {
    this.shield += amount;
  }

  damageBarrel() {
    this.barrelDamaged = true;
    // Clamp current power if it exceeds new max
    const max = this.getEffectiveMaxPower();
    if (this.power > max) this.power = max;
  }

  damageWheel() {
    this.wheelDamaged = true;
  }

  updatePosition() {
    this.y = this.terrain.getHeightAt(this.x);
    this.draw();
  }

  draw() {
    this.graphics.clear();

    // Barrel
    const tip = this.getBarrelTip();
    const barrelColor = this.barrelDamaged ? 0x999999 : 0x333333;
    this.graphics.lineStyle(this.barrelDamaged ? 4 : 6, barrelColor);
    this.graphics.lineBetween(this.x, this.y, tip.x, tip.y);

    // Base
    const color = this.isPlayer ? 0x3366cc : 0xcc3333;
    this.graphics.fillStyle(color);
    this.graphics.fillRect(this.x - 15, this.y - 10, 30, 12);

    // Wheels
    const wheelColor = this.wheelDamaged ? 0x999999 : 0x333333;
    this.graphics.fillStyle(wheelColor);
    this.graphics.fillCircle(this.x - 8, this.y, 6);
    this.graphics.fillCircle(this.x + 8, this.y, 6);

    // Wheel damage indicator (X marks)
    if (this.wheelDamaged) {
      this.graphics.lineStyle(2, 0xff0000);
      this.graphics.lineBetween(this.x - 11, this.y - 3, this.x - 5, this.y + 3);
      this.graphics.lineBetween(this.x - 5, this.y - 3, this.x - 11, this.y + 3);
    }

    // HP bar
    this.drawHPBar();

    // Shield indicator
    if (this.shield > 0) {
      this.graphics.lineStyle(2, 0x0066ff, 0.6);
      this.graphics.strokeCircle(this.x, this.y - 5, 20);
    }
  }

  drawHPBar() {
    const barWidth = 40;
    const barHeight = 6;
    const barX = this.x - barWidth / 2;
    const barY = this.y - 35;

    this.hp += (this.targetHp - this.hp) * 0.1;
    if (Math.abs(this.hp - this.targetHp) < 0.5) this.hp = this.targetHp;

    const pct = this.hp / Config.CANNON_HP;
    const hpColor = pct > 0.5 ? 0x00cc00 : pct > 0.25 ? 0xcccc00 : 0xcc0000;

    this.graphics.fillStyle(0x333333);
    this.graphics.fillRect(barX, barY, barWidth, barHeight);
    this.graphics.fillStyle(hpColor);
    this.graphics.fillRect(barX, barY, barWidth * pct, barHeight);
  }

  update() {
    if (Math.abs(this.hp - this.targetHp) > 0.5) {
      this.draw();
    }
  }

  destroy() {
    this.graphics.destroy();
  }

  reset() {
    this.angle = Config.DEFAULT_ANGLE;
    this.power = Config.DEFAULT_POWER;
    this.hp = Config.CANNON_HP;
    this.targetHp = Config.CANNON_HP;
    this.shield = 0;
    this.barrelDamaged = false;
    this.wheelDamaged = false;
    this.y = this.terrain.getHeightAt(this.x);
    this.draw();
  }
}
