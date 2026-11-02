/**
 * GOAL RUSH — Plunger (spring launcher).
 *
 * Hold to charge, release to launch. Charge maps to launch speed with a
 * quadratic curve (fine control at the top, like a real spring). The cap
 * sprite visually compresses while charging.
 */

import * as Phaser from 'phaser';
import { PALETTE, PLUNGER } from '../config/game.config';
import { BALL_SPAWN } from '../config/table.config';
import type { BallRef } from './types';

export class Plunger {
  private charge = 0;
  private charging = false;
  private cap: Phaser.GameObjects.Image;
  private chargeBar: Phaser.GameObjects.Graphics;

  constructor(
    private scene: Phaser.Scene,
    private getBall: () => BallRef | null
  ) {
    this.cap = scene.add.image(BALL_SPAWN.x, 930, 'atlas', 'plunger-cap').setDepth(6);
    this.chargeBar = scene.add.graphics().setDepth(6);
  }

  /** True when the active ball is resting in the launch lane. */
  ballInLane(): boolean {
    const ball = this.getBall();
    return !!ball && ball.active && ball.x > 490 && ball.y > 820;
  }

  /** Current charge 0..1 (for the on-screen launch meter). */
  getCharge(): number {
    return this.charging ? this.charge : 0;
  }

  press(): void {
    if (this.ballInLane()) this.charging = true;
  }

  release(): void {
    if (!this.charging) return;
    this.charging = false;
    const ball = this.getBall();
    if (ball && ball.active && this.ballInLane()) {
      const power = this.charge;
      const speed = Phaser.Math.Linear(PLUNGER.minSpeed, PLUNGER.maxSpeed, power * power);
      ball.setVelocity(Phaser.Math.FloatBetween(-0.25, 0.25), -speed);
      this.scene.events.emit('plunger-fired', power);
    }
    this.charge = 0;
    this.draw();
  }

  update(deltaMs: number): void {
    if (this.charging) {
      this.charge = Math.min(1, this.charge + deltaMs / PLUNGER.chargeMs);
    }
    // Cap follows the charge (compressing spring look).
    this.cap.y = 930 + this.charge * 15;
    this.draw();
  }

  private draw(): void {
    const g = this.chargeBar;
    g.clear();
    if (this.charge <= 0) return;
    const x = 528;
    const h = 120 * this.charge;
    g.fillStyle(PALETTE.magenta, 0.9);
    g.fillRoundedRect(x - 5, 900 - h, 10, h, 5);
    g.lineStyle(1, PALETTE.white, 0.35);
    g.strokeRoundedRect(x - 7, 778, 14, 124, 7);
  }
}
