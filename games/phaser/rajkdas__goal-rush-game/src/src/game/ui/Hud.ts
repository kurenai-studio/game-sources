/**
 * GOAL RUSH — in-canvas HUD + announcer.
 *
 * Bottom control panel: [◀ FLIP] CREDITS · JACKPOT · MULT · BALLS [FLIP ▶]
 * (the arrow buttons themselves live in TouchControls, flanking this bar).
 * Announcer: big center-screen call-outs (GOAL!, SAVED!, HAT-TRICK!…)
 * rendered with scale/fade tweens. Text objects are created once and reused
 * — no allocations during play.
 */

import * as Phaser from 'phaser';
import { PALETTE, PALETTE_CSS } from '../config/game.config';
import { HUD_BAR } from '../config/table.config';
import type { GameState } from '../state/GameState';

/** Shared micro-label style for the HUD columns. */
const LABEL = {
  fontFamily: 'sans-serif',
  fontSize: '11px',
  color: '#b8c8ea',
  resolution: 2,
} as const;

/** Max ball icons drawn; beyond that the counter shows +N. */
const MAX_ICONS = 4;

export class Hud {
  private creditsText: Phaser.GameObjects.Text;
  private potText: Phaser.GameObjects.Text;
  private multText: Phaser.GameObjects.Text;
  private multBadge: Phaser.GameObjects.Container;
  private ballIcons: Phaser.GameObjects.Image[] = [];
  private ballsMoreText: Phaser.GameObjects.Text;
  private announceText: Phaser.GameObjects.Text;
  private announceSub: Phaser.GameObjects.Text;
  private comboText: Phaser.GameObjects.Text;
  private announceBusyUntil = 0;

  constructor(
    private scene: Phaser.Scene,
    private state: GameState
  ) {
    const { y, height, col } = HUD_BAR;
    const labelY = y + 14;
    const valueY = y + height - 20;

    // ── Column 1: CREDITS (chip icon + figure) ────────────────────────
    scene.add
      .text(col.credits, labelY, 'CREDITS', { ...LABEL })
      .setOrigin(0.5)
      .setDepth(20);
    scene.add.image(col.credits - 27, valueY, 'atlas', 'chip').setScale(0.85).setDepth(20);
    this.creditsText = scene.add
      .text(col.credits - 15, valueY, '0', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '20px',
        color: PALETTE_CSS.goldSoft,
        stroke: '#3a2a05',
        strokeThickness: 3,
        resolution: 2,
      })
      .setOrigin(0, 0.5)
      .setDepth(20);

    // ── Column 2: progressive JACKPOT (center) ─────────────────────────
    scene.add
      .text(col.jackpot, labelY, 'JACKPOT', {
        ...LABEL,
        color: PALETTE_CSS.gold,
        fontSize: '11px',
      })
      .setOrigin(0.5)
      .setDepth(20);
    this.potText = scene.add
      .text(col.jackpot, valueY, '500', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '22px',
        color: PALETTE_CSS.jackpot,
        stroke: '#3a2a05',
        strokeThickness: 4,
        resolution: 2,
      })
      .setOrigin(0.5)
      .setDepth(20);
    scene.tweens.add({
      targets: this.potText,
      scale: { from: 1, to: 1.05 },
      yoyo: true,
      repeat: -1,
      duration: 900,
      ease: 'Sine.easeInOut',
    });

    // ── Column 3: win MULTIPLIER badge ────────────────────────────────
    scene.add
      .text(col.mult, labelY, 'MULT', LABEL)
      .setOrigin(0.5)
      .setDepth(20);
    this.multBadge = scene.add.container(col.mult, valueY).setDepth(20);
    const badgeBg = scene.add.graphics();
    badgeBg.fillStyle(PALETTE.magenta, 0.22);
    badgeBg.fillRoundedRect(-28, -16, 56, 32, 9);
    badgeBg.lineStyle(2, PALETTE.magenta, 0.95);
    badgeBg.strokeRoundedRect(-28, -16, 56, 32, 9);
    this.multText = scene.add
      .text(0, 0, '×1', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '19px',
        color: PALETTE_CSS.magenta,
        resolution: 2,
      })
      .setOrigin(0.5);
    this.multBadge.add([badgeBg, this.multText]);

    // ── Column 4: BALLS in play ────────────────────────────────────────
    scene.add
      .text(col.balls, labelY, 'BALLS', LABEL)
      .setOrigin(0.5)
      .setDepth(20);
    for (let i = 0; i < MAX_ICONS; i += 1) {
      const icon = scene.add
        .image(col.balls - (MAX_ICONS - 1) * 9 + i * 18, valueY, 'atlas', 'ball-mini')
        .setDepth(20);
      this.ballIcons.push(icon);
    }
    this.ballsMoreText = scene.add
      .text(col.balls + (MAX_ICONS - 1) * 9 + 12, valueY, '', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '15px',
        color: PALETTE_CSS.lineGreen,
        resolution: 2,
      })
      .setOrigin(0, 0.5)
      .setDepth(20);

    // Announcer (center screen).
    this.announceText = scene.add
      .text(270, 600, '', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '52px',
        color: PALETTE_CSS.lineGreen,
        resolution: 2,
      })
      .setOrigin(0.5)
      .setDepth(60)
      .setAlpha(0);
    this.announceSub = scene.add
      .text(270, 648, '', {
        fontFamily: 'sans-serif',
        fontSize: '19px',
        color: PALETTE_CSS.white,
        resolution: 2,
      })
      .setOrigin(0.5)
      .setDepth(60)
      .setAlpha(0);
    this.announceSub.setShadow(0, 2, '#04060c', 6, true, true);
    this.announceText.setShadow(0, 3, '#04060c', 8, true, true);
    this.comboText = scene.add
      .text(230, 250, '', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '26px',
        color: PALETTE_CSS.magenta,
        resolution: 2,
      })
      .setOrigin(0.5)
      .setDepth(60)
      .setAlpha(0);

    // Wire state.
    state.bus.on('credits', (credits: number) => this.setCredits(credits));
    state.bus.on('pot', (pot: number) => this.setPot(pot));
    state.bus.on('balls', (balls: number) => this.setBalls(balls));
    state.bus.on('multiplier', (mult: number) => this.setMultiplier(mult));
    this.setCredits(state.credits);
    this.setPot(state.pot);
    this.setBalls(state.balls);
    this.setMultiplier(state.multiplier);
  }

  private setCredits(credits: number): void {
    this.creditsText.setText(credits.toLocaleString());
    this.punch(this.creditsText);
  }

  private setPot(pot: number): void {
    this.potText.setText(pot.toLocaleString());
  }

  private setBalls(balls: number): void {
    // Always show the full icon rack (dimmed when out of play) — the classic
    // pinball "balls remaining" strip, readable even before the first launch.
    const lit = Math.min(balls, MAX_ICONS);
    this.ballIcons.forEach((icon, i) => {
      icon.setVisible(true);
      icon.setAlpha(i < lit ? 1 : 0.18);
    });
    this.ballsMoreText.setText(balls > MAX_ICONS ? `+${balls - MAX_ICONS}` : '');
  }

  private setMultiplier(mult: number): void {
    this.multText.setText(`×${mult}`);
    this.punch(this.multBadge);
  }

  private punch(target: Phaser.GameObjects.GameObject & { scale: number }): void {
    this.scene.tweens.add({
      targets: target,
      scale: { from: 1.25, to: 1 },
      duration: 220,
      ease: 'Back.easeOut',
    });
  }

  /** Big center announcement. */
  announce(main: string, color: string = PALETTE_CSS.lineGreen, sub = ''): void {
    const now = this.scene.time.now;
    if (now < this.announceBusyUntil) {
      // Collapse the previous call-out instantly, then show the new one.
      this.scene.tweens.killTweensOf([this.announceText, this.announceSub]);
    }
    this.announceBusyUntil = now + 1200;
    this.announceText.setText(main).setColor(color).setAlpha(1).setScale(0.5);
    this.announceSub.setText(sub).setAlpha(1);
    this.scene.tweens.add({
      targets: this.announceText,
      scale: 1,
      duration: 260,
      ease: 'Back.easeOut',
    });
    this.scene.tweens.add({
      targets: [this.announceText, this.announceSub],
      alpha: 0,
      delay: 950,
      duration: 320,
    });
  }

  /** Combo counter near the bumper cluster. */
  showCombo(combo: number): void {
    if (combo < 2) return;
    this.comboText.setText(`COMBO ×${combo}`).setAlpha(1).setScale(1.2).setAngle(-4);
    this.scene.tweens.add({
      targets: this.comboText,
      scale: 1,
      angle: 0,
      duration: 200,
      ease: 'Back.easeOut',
    });
    this.scene.tweens.add({
      targets: this.comboText,
      alpha: 0,
      delay: 700,
      duration: 380,
    });
  }
}
