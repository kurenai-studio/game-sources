/**
 * GOAL RUSH — the ball.
 *
 * Thin wrapper around a Matter circle image with lifecycle helpers:
 * spawn/drain/capture (static + hidden while the slot machine runs) and a
 * per-frame speed clamp that prevents tunneling through thin walls.
 *
 * Phaser's Matter GameObjects sync their rigid body with the sprite
 * transform (x/y setters, setStatic, setVelocity), so no raw Matter calls
 * are needed here.
 */

import type Phaser from 'phaser';
import { BALL as CFG, COLLISION, PHYSICS } from '../config/game.config';
import { BALL_SPAWN } from '../config/table.config';
import type { BallRef } from './types';

export class Ball implements BallRef {
  readonly image: Phaser.Physics.Matter.Image;
  active = false;

  constructor(scene: Phaser.Scene) {
    this.image = scene.matter.add.image(BALL_SPAWN.x, BALL_SPAWN.y, 'atlas', 'ball', {
      label: 'ball',
      collisionFilter: { category: COLLISION.ball },
    });
    this.image.setCircle(CFG.radius, {
      label: 'ball',
      density: CFG.density,
      restitution: CFG.restitution,
      friction: CFG.friction,
      frictionAir: CFG.frictionAir,
      frictionStatic: CFG.frictionStatic,
      collisionFilter: { category: COLLISION.ball },
    });
    this.image.setDepth(8);
    this.image.setVisible(false);
    this.image.setStatic(true);
    if (this.image.postFX) {
      this.image.postFX.addGlow(0x9fffc8, 1.2, 0, false);
    }
  }

  get x(): number {
    return this.image.x;
  }

  get y(): number {
    return this.image.y;
  }

  setVelocity(x: number, y: number): void {
    this.image.setVelocity(x, y);
  }

  /** Place a fresh ball into the launch lane. */
  spawn(): void {
    this.image.setVisible(true);
    this.active = true;
    this.image.setPosition(BALL_SPAWN.x, BALL_SPAWN.y);
    this.image.setStatic(false);
    this.image.setVelocity(0, 0);
    this.image.setAngularVelocity(0);
  }

  /** Capture by the saucer: freeze + hide. */
  capture(): void {
    if (!this.active) return;
    this.active = false;
    this.image.setVelocity(0, 0);
    this.image.setStatic(true);
    this.image.setVisible(false);
  }

  /** Release from the saucer at a position with an impulse. */
  releaseAt(x: number, y: number, vx: number, vy: number): void {
    this.image.setVisible(true);
    this.active = true;
    this.image.setPosition(x, y);
    this.image.setStatic(false);
    this.image.setVelocity(vx, vy);
  }

  /** Ball left the playfield. */
  retire(): void {
    this.active = false;
    this.image.setVelocity(0, 0);
    this.image.setStatic(true);
    this.image.setVisible(false);
  }

  /** Clamp speed so a fast ball cannot skip through 12-16 px walls. */
  clampSpeed(): void {
    const body = this.image.body;
    if (!body || !this.active) return;
    const v = body.velocity;
    const speed = Math.hypot(v.x, v.y);
    if (speed > PHYSICS.maxBallSpeed) {
      const k = PHYSICS.maxBallSpeed / speed;
      this.image.setVelocity(v.x * k, v.y * k);
    }
  }

  /** True when the ball rests in the launch lane. */
  inLane(): boolean {
    return this.active && this.x > 490 && this.y > 820;
  }
}
