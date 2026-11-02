/**
 * GOAL RUSH — Spinner (virtual).
 *
 * The original design pinned a physical blade in the left orbit and let the
 * ball come to rest on it — riding the slowly-turning blade for ages. This
 * version is PURE DETECTION: a static sensor spans the lane, the ball rolls
 * through untouched, and the blade you see is a plain (physics-free) image
 * spun procedurally: each pass kicks its angular velocity up in proportion
 * to the ball's speed, then it decays like a real freewheeling blade.
 *
 * Every pass awards credits and ticks the progressive pot; the blade's
 * accumulated revolutions replay the classic spinner ratchet sound.
 */

import * as Phaser from 'phaser';
import { SPINNER as CFG } from '../config/table.config';

export class Spinner {
  /** Physics-free blade graphic (rotated procedurally). */
  readonly image: Phaser.GameObjects.Image;
  private hub: Phaser.GameObjects.Image;
  private glow: Phaser.GameObjects.Image;
  private spinVel = 0;
  private lastAngle = 0;
  private accumulated = 0;
  private lastPassAt = -9999;

  constructor(
    scene: Phaser.Scene,
    private onPass: (speed: number) => void
  ) {
    // Detection sensor across the lane — the ball never touches a body.
    scene.matter.add.rectangle(CFG.x, CFG.y, CFG.sensor.width, CFG.sensor.height, {
      isStatic: true,
      isSensor: true,
      label: 'spinner',
    });

    // Lane halo so the loop shot reads as a target.
    this.glow = scene.add
      .image(CFG.x, CFG.y, 'atlas', 'ball-glow')
      .setScale(2.1, 1.7)
      .setAlpha(0.28)
      .setDepth(2)
      .setTint(0xff77bb);

    this.image = scene.add
      .image(CFG.x, CFG.y, 'atlas', 'spinner-blade')
      .setScale(1.5)
      .setDepth(5);
    this.hub = scene.add
      .image(CFG.x, CFG.y, 'atlas', 'post')
      .setScale(0.5)
      .setDepth(6);

    // Idle attract: a lazy drift so the blade is never frozen.
    this.spinVel = 0.35;
    this.lastAngle = this.image.rotation;
  }

  /**
   * A transit was detected. `speed` is the ball's speed in px/tick — it
   * drives how hard the blade gets flicked. Returns true when the pass was
   * counted (inside the cooldown window it is ignored).
   */
  pass(time: number, speed: number): boolean {
    if (time - this.lastPassAt < CFG.cooldownMs) return false;
    this.lastPassAt = time;
    this.spinVel = Phaser.Math.Clamp(2.2 + speed * 0.28, 3, 10.5);
    this.hub.setScale(0.72);
    this.scenePunch();
    this.onPass(speed);
    return true;
  }

  private scenePunch(): void {
    // Tiny scale pop on the glow — a physical "thwack" without physics.
    this.glow.setScale(2.5, 2.0);
  }

  /** Frame update: integrate rotation, decay velocity, ratchet sound. */
  update(deltaMs: number, time: number): void {
    const dt = deltaMs / 1000;
    // Exponential decay toward the idle drift speed.
    const idle = 0.35;
    this.spinVel = Phaser.Math.Linear(this.spinVel, idle, 1 - Math.pow(0.14, dt));
    const angle = this.image.rotation + this.spinVel * dt;
    this.image.setRotation(angle);

    // Ratchet: fire the tick once per accumulated full revolution.
    let delta = angle - this.lastAngle;
    if (delta > Math.PI) delta -= Math.PI * 2;
    if (delta < -Math.PI) delta += Math.PI * 2;
    this.lastAngle = angle;
    this.accumulated += Math.abs(delta);
    if (this.accumulated >= Math.PI * 2) {
      this.accumulated -= Math.PI * 2;
      if (this.spinVel > 1.2) this.onRevolution?.();
    }

    // Relax the pass pop-ups.
    this.glow.setScale(
      Phaser.Math.Linear(this.glow.scaleX, 2.1, 1 - Math.pow(0.02, dt)),
      Phaser.Math.Linear(this.glow.scaleY, 1.7, 1 - Math.pow(0.02, dt))
    );
    this.hub.setScale(Phaser.Math.Linear(this.hub.scaleX, 0.5, 1 - Math.pow(0.001, dt)));
    void time;
  }

  /** Revolution sound hook (assigned by the scene). */
  onRevolution: (() => void) | null = null;
}
