/**
 * GOAL RUSH — on-screen touch controls (the visible arrow controllers).
 *
 * The table is played by tapping the screen halves (left flipper / right
 * flipper) and the launch lane (plunger) — but invisible touch zones are
 * undiscoverable. This class paints the affordances:
 *
 *  - two big neon ◀ FLIP / FLIP ▶ buttons in the bottom corners of the
 *    HUD strip, glowing brighter and compressing while their zone is held
 *    (works for touch, mouse, keyboard and gamepad — it simply mirrors the
 *    flipper state every frame);
 *  - a pulsing LAUNCH ▲ pill over the plunger lane whenever the ball is
 *    waiting to be launched, doubling as a charge meter while held.
 *
 * The buttons are visual feedback over the EXISTING input routing — the
 * whole left half still flips, the whole right half still flips — so
 * muscle memory built on any input device keeps working.
 */

import * as Phaser from 'phaser';
import { PALETTE, PALETTE_CSS } from '../config/game.config';
import { FLIP_BUTTONS } from '../config/table.config';

interface Button {
  root: Phaser.GameObjects.Container;
  face: Phaser.GameObjects.Graphics;
  glow: Phaser.GameObjects.Rectangle;
  held: boolean;
}

export class TouchControls {
  private left: Button;
  private right: Button;
  private launchPill: Phaser.GameObjects.Container;
  private launchText!: Phaser.GameObjects.Text;
  private launchGlow!: Phaser.GameObjects.Graphics;

  constructor(private scene: Phaser.Scene) {
    this.left = this.buildButton(FLIP_BUTTONS.left.x, FLIP_BUTTONS.left.y, 'left');
    this.right = this.buildButton(FLIP_BUTTONS.right.x, FLIP_BUTTONS.right.y, 'right');
    this.launchPill = this.buildLaunchPill();
  }

  // ── construction ─────────────────────────────────────────────────────────

  private buildButton(x: number, y: number, side: 'left' | 'right'): Button {
    const root = this.scene.add.container(x, y).setDepth(25);
    const { width: w, height: h } = FLIP_BUTTONS;

    // Outer glow block (alpha animated on press).
    const glow = this.scene.add.rectangle(0, 0, w + 14, h + 14, PALETTE.lineGreen, 0);
    root.add(glow);

    const face = this.scene.add.graphics();
    this.drawButtonFace(face, side, false);
    root.add(face);

    const label = this.scene.add
      .text(0, h / 2 - 9, 'FLIP', {
        fontFamily: 'sans-serif',
        fontSize: '10px',
        color: PALETTE_CSS.dim,
        resolution: 2,
      })
      .setOrigin(0.5);
    root.add(label);

    // Gentle idle breathing so the buttons read as interactive.
    this.scene.tweens.add({
      targets: glow,
      alpha: { from: 0.04, to: 0.14 },
      yoyo: true,
      repeat: -1,
      duration: 1100,
      ease: 'Sine.easeInOut',
    });

    return { root, face, glow, held: false };
  }

  /** Neon button face: rounded panel + double chevron pointing outward. */
  private drawButtonFace(g: Phaser.GameObjects.Graphics, side: 'left' | 'right', held: boolean): void {
    const { width: w, height: h } = FLIP_BUTTONS;
    const col = held ? PALETTE.lineGreen : 0x1c2a44;
    const edge = held ? PALETTE.white : PALETTE.lineGreen;

    g.clear();
    g.fillStyle(col, held ? 0.95 : 0.88);
    g.fillRoundedRect(-w / 2, -h / 2, w, h, 12);
    g.lineStyle(2, edge, 1);
    g.strokeRoundedRect(-w / 2, -h / 2, w, h, 12);
    g.lineStyle(1, PALETTE.white, held ? 0.5 : 0.18);
    g.strokeRoundedRect(-w / 2 + 3, -h / 2 + 3, w - 6, h - 6, 9);

    // Double chevron.
    const dir = side === 'left' ? -1 : 1;
    const cx = dir * 4;
    for (const off of [7, 0]) {
      const ox = cx + dir * off;
      g.lineStyle(3.2, held ? PALETTE.bgDeep : PALETTE.lineGreen, 1);
      g.beginPath();
      g.moveTo(ox + dir * 7, -9);
      g.lineTo(ox - dir * 4, 0);
      g.lineTo(ox + dir * 7, 9);
      g.strokePath();
    }
  }

  private buildLaunchPill(): Phaser.GameObjects.Container {
    const root = this.scene.add.container(509, 806).setDepth(25).setVisible(false);
    const w = 44;
    const h = 30;

    this.launchGlow = this.scene.add.graphics();
    root.add(this.launchGlow);

    const face = this.scene.add.graphics();
    face.fillStyle(0x1c2a44, 0.88);
    face.fillRoundedRect(-w / 2, -h / 2, w, h, 10);
    face.lineStyle(2, PALETTE.magenta, 1);
    face.strokeRoundedRect(-w / 2, -h / 2, w, h, 10);
    // Up chevron.
    face.lineStyle(3, PALETTE.magenta, 1);
    face.beginPath();
    face.moveTo(-6, -1);
    face.lineTo(0, -8);
    face.lineTo(6, -1);
    face.strokePath();
    root.add(face);

    this.launchText = this.scene.add
      .text(0, 7, 'HOLD', {
        fontFamily: 'sans-serif',
        fontSize: '9px',
        color: PALETTE_CSS.magenta,
        resolution: 2,
      })
      .setOrigin(0.5);
    root.add(this.launchText);

    this.scene.tweens.add({
      targets: root,
      y: 802,
      yoyo: true,
      repeat: -1,
      duration: 620,
      ease: 'Sine.easeInOut',
    });

    return root;
  }

  // ── per-frame state mirror ───────────────────────────────────────────────

  /** Mirror the true flipper input state onto the visuals (cheap; no allocation). */
  sync(leftHeld: boolean, rightHeld: boolean): void {
    if (this.left.held !== leftHeld) {
      this.left.held = leftHeld;
      this.drawButtonFace(this.left.face, 'left', leftHeld);
      this.left.root.setScale(leftHeld ? 0.93 : 1);
      this.left.glow.setAlpha(leftHeld ? 0.4 : 0.08);
      this.scene.tweens.killTweensOf(this.left.glow);
      if (!leftHeld) this.restartBreath(this.left.glow);
    }
    if (this.right.held !== rightHeld) {
      this.right.held = rightHeld;
      this.drawButtonFace(this.right.face, 'right', rightHeld);
      this.right.root.setScale(rightHeld ? 0.93 : 1);
      this.right.glow.setAlpha(rightHeld ? 0.4 : 0.08);
      this.scene.tweens.killTweensOf(this.right.glow);
      if (!rightHeld) this.restartBreath(this.right.glow);
    }
  }

  private restartBreath(glow: Phaser.GameObjects.Rectangle): void {
    this.scene.tweens.add({
      targets: glow,
      alpha: { from: 0.04, to: 0.14 },
      yoyo: true,
      repeat: -1,
      duration: 1100,
      ease: 'Sine.easeInOut',
    });
  }

  /** Show/hide the LAUNCH affordance (only while the ball waits in the lane). */
  setLaunchHint(visible: boolean): void {
    if (this.launchPill.visible !== visible) {
      this.launchPill.setVisible(visible);
    }
  }

  /** Redraw the launch charge ring (0..1). */
  updateLaunchCharge(charge: number): void {
    if (!this.launchPill.visible || charge <= 0) return;
    const w = 44;
    const h = 30;
    this.launchGlow.clear();
    this.launchGlow.fillStyle(PALETTE.magenta, 0.55);
    this.launchGlow.fillRoundedRect(-w / 2, h / 2 + 4, w * Phaser.Math.Clamp(charge, 0, 1), 4, 2);
    this.launchText.setText(charge > 0.97 ? 'FIRE!' : 'HOLD');
  }
}
