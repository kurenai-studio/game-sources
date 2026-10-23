import Phaser from 'phaser';
import * as Config from '../config.js';

const MatterBody = Phaser.Physics.Matter.Matter.Body;

export default class Projectile {
  constructor(scene, x, y, vx, vy, options = {}) {
    this.scene = scene;
    this.trail = [];
    this.alive = true;
    this.options = options;
    this.peakY = y; // Track highest point for cluster split

    this.body = scene.matter.add.circle(x, y, Config.PROJECTILE_RADIUS, {
      frictionAir: 0,
      friction: 0,
      restitution: 0,
      collisionFilter: { group: -1 },
      label: 'projectile',
    });

    MatterBody.setVelocity(this.body, { x: vx, y: vy });
    this.graphics = scene.add.graphics();
  }

  getPosition() {
    return this.body.position;
  }

  getVelocity() {
    return this.body.velocity;
  }

  applyWind(wind) {
    if (!this.alive) return;
    const vel = this.body.velocity;
    MatterBody.setVelocity(this.body, {
      x: vel.x + wind * Config.WIND_ACCEL,
      y: vel.y,
    });
  }

  updateTrail() {
    if (!this.alive) return;
    const pos = this.body.position;

    // Track peak
    if (pos.y < this.peakY) {
      this.peakY = pos.y;
    }

    this.trail.push({ x: pos.x, y: pos.y });
    if (this.trail.length > Config.TRAIL_LENGTH) {
      this.trail.shift();
    }

    this.graphics.clear();

    const isCluster = this.options.isCluster;
    const trailColor = isCluster ? 0xff3300 : 0xff6600;

    for (let i = 0; i < this.trail.length; i++) {
      const alpha = (i + 1) / this.trail.length;
      const radius = Config.PROJECTILE_RADIUS * alpha * 0.8;
      this.graphics.fillStyle(trailColor, alpha * 0.4);
      this.graphics.fillCircle(this.trail[i].x, this.trail[i].y, radius);
    }

    this.graphics.fillStyle(0x222222);
    this.graphics.fillCircle(pos.x, pos.y, Config.PROJECTILE_RADIUS);
  }

  destroy() {
    this.alive = false;
    if (this.body) {
      this.scene.matter.world.remove(this.body);
    }
    if (this.graphics) {
      this.graphics.destroy();
    }
  }
}
