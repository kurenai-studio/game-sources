/**
 * GOAL RUSH — SPIN saucer.
 *
 * A sensor "hole" that captures the ball (freezes physics on it), runs the
 * slot machine sequence, then ejects the ball back into play. A recapture
 * lockout stops the freshly-ejected ball from instantly triggering again.
 */

import * as Phaser from 'phaser';
import { PALETTE_CSS } from '../config/game.config';
import { SAUCER } from '../config/table.config';
import type { BallRef } from './types';

export class Saucer {
  private lockedUntil = 0;
  private ring: Phaser.GameObjects.Image;
  private label: Phaser.GameObjects.Text;

  constructor(
    private scene: Phaser.Scene,
    private onCapture: () => void
  ) {
    this.ring = scene.add.image(SAUCER.x, SAUCER.y, 'atlas', 'saucer-ring').setDepth(3);
    this.label = scene.add
      .text(SAUCER.x, SAUCER.y, 'SPIN', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '15px',
        color: PALETTE_CSS.gold,
      })
      .setOrigin(0.5)
      .setDepth(4);

    scene.tweens.add({
      targets: this.label,
      scale: 1.14,
      yoyo: true,
      repeat: -1,
      duration: 650,
      ease: 'Sine.easeInOut',
    });

    scene.matter.add.circle(SAUCER.x, SAUCER.y, SAUCER.radius, {
      isStatic: true,
      isSensor: true,
      label: 'saucer',
    });
  }

  /** Try to capture the ball; true if the slot sequence should start. */
  capture(ball: BallRef, time: number): boolean {
    if (time < this.lockedUntil || !ball.active) return false;
    this.lockedUntil = time + 1000; // re-locked until eject finishes
    this.onCapture();

    // Flash the ring.
    this.ring.setScale(1.35);
    this.scene.tweens.add({
      targets: this.ring,
      scale: 1,
      duration: 320,
      ease: 'Back.easeOut',
    });
    return true;
  }

  /** Release the ball back into play after the slot sequence. */
  eject(ball: BallRef, time: number): void {
    ball.image.setPosition(SAUCER.x, SAUCER.y + 6);
    ball.setVelocity(SAUCER.eject.x, SAUCER.eject.y);
    this.lockedUntil = time + SAUCER.recaptureMs;
  }

  get pos(): { x: number; y: number } {
    return { x: SAUCER.x, y: SAUCER.y };
  }
}
