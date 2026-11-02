/**
 * GOAL RUSH — floating score popups.
 *
 * Every scoring event throws a little "+N" into the air at the point of
 * impact (colour-coded, with a ×MULT tag when the G-O-A-L multiplier is
 * boosting table awards). Text objects are pooled and recycled — a burst of
 * bumper hits allocates nothing after warm-up.
 */

import * as Phaser from 'phaser';
import { PALETTE_CSS } from '../config/game.config';

const POOL_SIZE = 14;
const LIFETIME_MS = 900;

export class ScoreFx {
  private pool: Phaser.GameObjects.Text[] = [];
  private free: boolean[] = [];

  constructor(private scene: Phaser.Scene) {
    for (let i = 0; i < POOL_SIZE; i += 1) {
      this.pool.push(
        scene.add
          .text(0, 0, '', {
            fontFamily: '"Arial Black", sans-serif',
            fontSize: '19px',
            color: PALETTE_CSS.white,
            stroke: '#04060c',
            strokeThickness: 4,
            resolution: 2,
          })
          .setOrigin(0.5)
          .setDepth(15)
          .setAlpha(0)
      );
      this.free.push(true);
    }
  }

  /** Emit a popup at a world position. */
  pop(x: number, y: number, content: string, color: string = PALETTE_CSS.white, big = false): void {
    let idx = this.free.indexOf(true);
    if (idx === -1) idx = 0; // pool exhausted: recycle the first slot
    const text = this.pool[idx];
    this.free[idx] = false;

    // Steer popups away from the rails so they never clip off-canvas.
    const px = Phaser.Math.Clamp(x, 60, 480);
    const py = Phaser.Math.Clamp(y, 60, 880);

    this.scene.tweens.killTweensOf(text);
    text
      .setText(content)
      .setColor(color)
      .setPosition(px, py)
      .setAlpha(1)
      .setScale(big ? 1.15 : 0.9)
      .setAngle(Phaser.Math.FloatBetween(-6, 6));

    this.scene.tweens.add({
      targets: text,
      y: py - 46,
      scale: big ? 1.35 : 1,
      duration: LIFETIME_MS,
      ease: 'Cubic.easeOut',
    });
    this.scene.tweens.add({
      targets: text,
      alpha: 0,
      delay: LIFETIME_MS * 0.55,
      duration: LIFETIME_MS * 0.45,
      onComplete: () => {
        this.free[idx] = true;
      },
    });
  }
}
