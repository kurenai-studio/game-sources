/**
 * GOAL RUSH — jackpot celebration sequence.
 *
 * The full-fat moment: stadium light sweep (rotating rays), "GOOOAL!"
 * banner, rolling pot counter, confetti storm, camera flash + shake, all
 * timed against the synthesized crowd roar. Objects are created once and
 * reused; the ray sweep uses a single Graphics redrawn per frame.
 */

import * as Phaser from 'phaser';
import { PALETTE, PALETTE_CSS } from '../config/game.config';

export class JackpotFx {
  private overlay: Phaser.GameObjects.Rectangle;
  private rays: Phaser.GameObjects.Graphics;
  private banner: Phaser.GameObjects.Text;
  private sub: Phaser.GameObjects.Text;
  private counter: Phaser.GameObjects.Text;
  private confetti: Phaser.GameObjects.Particles.ParticleEmitter;
  private rayAngle = 0;
  private active = false;

  constructor(private scene: Phaser.Scene) {
    this.overlay = scene.add
      .rectangle(270, 480, 540, 960, PALETTE.bgDeep, 0)
      .setDepth(50);
    this.rays = scene.add.graphics().setDepth(51);
    this.banner = scene.add
      .text(270, 400, 'GOOOAL!', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '74px',
        color: PALETTE_CSS.gold,
        resolution: 2,
      })
      .setOrigin(0.5)
      .setDepth(53)
      .setAlpha(0);
    this.sub = scene.add
      .text(270, 470, 'PROGRESSIVE JACKPOT', {
        fontFamily: 'sans-serif',
        fontSize: '20px',
        color: PALETTE_CSS.white,
        resolution: 2,
      })
      .setOrigin(0.5)
      .setDepth(53)
      .setAlpha(0);
    this.counter = scene.add
      .text(270, 540, '', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '54px',
        color: PALETTE_CSS.lineGreen,
        resolution: 2,
      })
      .setOrigin(0.5)
      .setDepth(53)
      .setAlpha(0);

    this.confetti = scene.add.particles(270, 200, 'atlas', {
      frame: 'confetti',
      lifespan: 2600,
      speed: { min: 160, max: 520 },
      angle: { min: 195, max: 345 },
      gravityY: 420,
      scale: { start: 1.3, end: 0.35 },
      rotate: { min: 0, max: 360 },
      quantity: 18,
      emitting: false,
    });
    this.confetti.setDepth(52);
  }

  /** Run the sequence; `onDone` fires when the stadium settles. */
  play(amount: number, onDone: () => void): void {
    if (this.active) {
      onDone();
      return;
    }
    this.active = true;

    this.overlay.setAlpha(0);
    this.banner.setAlpha(0).setScale(0.4);
    this.sub.setAlpha(0);
    this.counter.setAlpha(0);

    this.scene.tweens.add({
      targets: this.overlay,
      alpha: 0.45,
      duration: 200,
    });
    this.scene.tweens.add({
      targets: this.banner,
      alpha: 1,
      scale: 1,
      duration: 380,
      ease: 'Back.easeOut',
    });
    this.scene.tweens.add({
      targets: this.sub,
      alpha: 1,
      duration: 300,
      delay: 180,
    });
    this.scene.tweens.add({
      targets: this.counter,
      alpha: 1,
      duration: 200,
      delay: 260,
    });

    // Rolling counter.
    const roll = { v: 0 };
    this.scene.tweens.add({
      targets: roll,
      v: amount,
      duration: 1500,
      ease: 'Cubic.easeOut',
      onUpdate: () => this.counter.setText(`+${Math.floor(roll.v)}`),
      onComplete: () => this.counter.setText(`+${amount}`),
    });

    this.confetti.explode(140);
    this.scene.cameras.main.flash(260, 255, 240, 160);
    this.scene.cameras.main.shake(700, 0.008);

    // Ray sweep for ~2.6s (one redraw per frame — never delay:0, Phaser
    // rejects zero-delay timer events and the throw would poison the frame).
    const rayEvent = this.scene.time.addEvent({
      delay: 16,
      repeat: 160,
      callback: () => this.drawRays(),
    });

    this.scene.time.delayedCall(2700, () => {
      rayEvent.remove();
      this.rays.clear();
      this.scene.tweens.add({
        targets: [this.overlay, this.banner, this.sub, this.counter],
        alpha: 0,
        duration: 420,
        onComplete: () => {
          this.active = false;
          onDone();
        },
      });
    });
  }

  /** Rotating light rays from the top of the screen. */
  private drawRays(): void {
    this.rayAngle += 0.045;
    const g = this.rays;
    g.clear();
    g.fillStyle(PALETTE.gold, 0.05);
    const cx = 270;
    const cy = -140;
    for (let i = 0; i < 12; i += 1) {
      const a = this.rayAngle + (i * Math.PI) / 6;
      const w = 0.07 + 0.03 * Math.sin(this.rayAngle * 3 + i);
      g.slice(cx, cy, 900, a - w, a + w, false);
      g.fillPath();
    }
  }
}
