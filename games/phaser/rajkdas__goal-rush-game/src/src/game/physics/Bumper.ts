/**
 * GOAL RUSH — Pop Bumper.
 *
 * A static post that whacks the ball straight away from its center on
 * contact (velocity kick, the classic pop-bumper behaviour), with a flash,
 * particles and a per-bumper cooldown so a resting ball is not kicked every
 * frame.
 */

import * as Phaser from 'phaser';
import { BUMPER as CFG } from '../config/game.config';
import type { BumperDef } from '../config/table.config';
import type { BallRef } from './types';

export class Bumper {
  readonly image: Phaser.GameObjects.Image;
  /** Static circle body (used for collision routing by body id). */
  readonly body: MatterJS.BodyType;
  private lastKick = -9999;
  private flash: Phaser.GameObjects.Image;

  constructor(
    private scene: Phaser.Scene,
    private def: BumperDef,
    private particles: Phaser.GameObjects.Particles.ParticleEmitter
  ) {
    this.image = scene.add
      .image(def.x, def.y, 'atlas', 'bumper')
      .setTint(def.tint)
      .setDepth(4);
    this.flash = scene.add
      .image(def.x, def.y, 'atlas', 'bumper-flash')
      .setDepth(5)
      .setAlpha(0);

    this.body = scene.matter.add.circle(def.x, def.y, def.radius, {
      isStatic: true,
      restitution: 0.6,
      friction: 0,
      label: 'bumper',
    }) as MatterJS.BodyType;

    // Neon bloom halo (WebGL only — graceful no-op on canvas renderer).
    if (this.image.postFX) {
      this.image.postFX.addGlow(def.tint, 2, 0, false);
    }
  }

  /** True if this bumper may kick again (cooldown elapsed). */
  canKick(time: number): boolean {
    return time - this.lastKick >= CFG.cooldownMs;
  }

  /** Kick the ball away from the bumper center + juice. */
  kick(ball: BallRef, time: number): void {
    this.lastKick = time;
    const dx = ball.x - this.def.x;
    const dy = ball.y - this.def.y;
    const len = Math.max(1, Math.hypot(dx, dy));
    ball.setVelocity((dx / len) * CFG.kick, (dy / len) * CFG.kick);

    this.flash.setAlpha(1).setScale(0.7);
    this.scene.tweens.add({
      targets: this.flash,
      alpha: 0,
      scale: 1.5,
      duration: 220,
      ease: 'Quad.easeOut',
    });
    this.image.setScale(1.18);
    this.scene.tweens.add({
      targets: this.image,
      scale: 1,
      duration: 160,
      ease: 'Quad.easeOut',
    });
    this.particles.explode(10, this.def.x, this.def.y);
  }
}
