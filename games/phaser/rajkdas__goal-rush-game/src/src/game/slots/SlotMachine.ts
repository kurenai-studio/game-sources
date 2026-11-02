/**
 * GOAL RUSH — Slot machine (reels, anticipation, payline presentation).
 *
 * Presentation layers on top of the rng module:
 *  - three masked reel windows scrolling the 64-stop base strips (or the
 *    longer golden strips), each reel owning TWO prebuilt columns so a
 *    golden spin swaps visuals with zero allocation churn,
 *  - staggered stops with an overshoot ease for the mechanical "clunk",
 *  - JACKPOT ANTICIPATION: when the first two reels land on trophies, the
 *    third reel spins longer, glows and heartbeats — the classic near-miss
 *    tension that makes slots addictive,
 *  - payline flash, symbol pop and win count-up.
 *
 * The outcome is decided UP FRONT (rng.evaluate) and the reels are animated
 * to land on it — identical to how certified slot machines work.
 */

import * as Phaser from 'phaser';
import {
  STRIPS_BASE,
  STRIPS_GOLDEN,
  OFFSIDE_PROBABILITY,
  type SpinOutcome,
  type SpinKind,
  type SymbolId,
} from '../config/slots.config';
import { PALETTE, PALETTE_CSS } from '../config/game.config';
import { symbolFrame } from '../gfx/TextureFactory';
import { audio } from '../audio/AudioKit';
import { evaluate, pickStop, randomInt } from './rng';

const SYM_H = 66;
const WINDOW_W = 78;
const WINDOW_H = SYM_H * 3;

interface Reel {
  /** Column containers, one per strip variant. */
  columns: Record<'base' | 'golden', Phaser.GameObjects.Container>;
  active: 'base' | 'golden';
  scroll: { s: number };
  state: 'idle' | 'spin' | 'stopping' | 'stopped';
  speed: number;
  stopTween: Phaser.Tweens.Tween | null;
  glow: Phaser.GameObjects.Rectangle;
}

type DoneCallback = (outcome: SpinOutcome) => void;

export class SlotMachine {
  private panel!: Phaser.GameObjects.Container;
  /** Full-screen dim behind the panel — focuses attention on the reels. */
  private backdrop!: Phaser.GameObjects.Rectangle;
  private reels: Reel[] = [];
  private outcome: SpinOutcome | null = null;
  private onDone: DoneCallback | null = null;
  /** True once the current outcome's award was handed to the credit sink. */
  private paid = false;
  private resultText!: Phaser.GameObjects.Text;
  private winText!: Phaser.GameObjects.Text;
  private paylineBar!: Phaser.GameObjects.Rectangle;
  private state: 'idle' | 'spinning' | 'presenting' = 'idle';
  private safetyTimer: Phaser.Time.TimerEvent | null = null;
  private heartbeatTimer: Phaser.Time.TimerEvent | null = null;
  /** Timers owned by the current spin lifecycle (cancelled on forceReset). */
  private spinTimers: Phaser.Time.TimerEvent[] = [];
  /**
   * Spin generation token. Every async closure (timer callback, tween
   * completion) captures the token when scheduled and no-ops if it has gone
   * stale. This makes an interrupted spin inert: an orphaned callback can
   * never dereference a nulled `outcome` (an exception inside Clock.update
   * would abort the whole frame and freeze every later timer) and can never
   * corrupt the state of a newer spin.
   */
  private generation = 0;

  constructor(
    private scene: Phaser.Scene,
    private getMultiplier: () => number,
    private addCredits: (amount: number) => void
  ) {
    this.build();
  }

  // ── construction ─────────────────────────────────────────────────────────

  private build(): void {
    const W = 300;
    const H = 340;
    this.backdrop = this.scene.add
      .rectangle(270, 480, 540, 960, 0x04060c, 0.45)
      .setDepth(39)
      .setVisible(false)
      .setAlpha(0);
    this.panel = this.scene.add.container(270, 292).setDepth(40).setVisible(false).setAlpha(0);

    const bg = this.scene.add.graphics();
    bg.fillStyle(PALETTE.bgPanel, 1);
    bg.fillRoundedRect(-W / 2, -H / 2, W, H, 16);
    bg.lineStyle(2.5, PALETTE.gold, 1);
    bg.strokeRoundedRect(-W / 2, -H / 2, W, H, 16);
    bg.lineStyle(1, PALETTE.magenta, 0.6);
    bg.strokeRoundedRect(-W / 2 + 5, -H / 2 + 5, W - 10, H - 10, 12);

    const title = this.scene.add
      .text(0, -H / 2 + 26, '★ STADIUM SLOTS ★', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '21px',
        color: PALETTE_CSS.gold,
      })
      .setOrigin(0.5);

    this.panel.add([bg, title]);

    const startX = -92;
    for (let i = 0; i < 3; i += 1) {
      this.panel.add(this.buildReel(i, startX + i * 92, -46));
    }

    // Payline marker (middle row).
    this.paylineBar = this.scene.add
      .rectangle(0, -46 + SYM_H, 264, 4, PALETTE.gold, 0.85)
      .setDepth(1);
    this.paylineBar.setVisible(false);
    this.panel.add(this.paylineBar);

    this.resultText = this.scene.add
      .text(0, 86, '', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '16px',
        color: PALETTE_CSS.white,
        align: 'center',
        wordWrap: { width: 270 },
      })
      .setOrigin(0.5);
    this.winText = this.scene.add
      .text(0, 120, '', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '28px',
        color: PALETTE_CSS.lineGreen,
      })
      .setOrigin(0.5);
    // Small rules footer so the generous pay model is visible in-game.
    const footer = this.scene.add
      .text(0, H / 2 - 16, 'ANY PAIR PAYS · TROPHY ×3 = JACKPOT · BLANK = OFFSIDE?', {
        fontFamily: 'sans-serif',
        fontSize: '10px',
        color: PALETTE_CSS.dim,
      })
      .setOrigin(0.5);
    this.panel.add([this.resultText, this.winText, footer]);
  }

  private buildReel(index: number, x: number, y: number): Phaser.GameObjects.Container {
    const holder = this.scene.add.container(x, y);

    const frame = this.scene.add.graphics();
    frame.fillStyle(0x05080f, 1);
    frame.fillRect(-WINDOW_W / 2, -SYM_H * 1.5, WINDOW_W, WINDOW_H);
    frame.lineStyle(2, PALETTE.steel, 1);
    frame.strokeRect(-WINDOW_W / 2, -SYM_H * 1.5, WINDOW_W, WINDOW_H);
    holder.add(frame);

    // Anticipation glow behind the frame.
    const glow = this.scene.add
      .rectangle(0, 0, WINDOW_W + 10, WINDOW_H + 10, PALETTE.gold, 0)
      .setDepth(-1);
    holder.add(glow);

    const columns = {
      base: this.buildColumn(STRIPS_BASE[index]),
      golden: this.buildColumn(STRIPS_GOLDEN[index]),
    };
    columns.golden.setVisible(false);
    holder.add(columns.base);
    holder.add(columns.golden);

    // Geometry mask = exact 3-row window (world coordinates).
    const maskG = this.scene.make.graphics({}, false);
    maskG.fillStyle(0xffffff, 1);
    maskG.fillRect(
      this.panel.x + x - WINDOW_W / 2,
      this.panel.y + y - SYM_H * 1.5,
      WINDOW_W,
      WINDOW_H
    );
    columns.base.setMask(maskG.createGeometryMask());
    columns.golden.setMask(maskG.createGeometryMask());

    this.reels.push({
      columns,
      active: 'base',
      scroll: { s: 0 },
      state: 'idle',
      speed: 0,
      stopTween: null,
      glow,
    });
    return holder;
  }

  /** A vertical strip of symbols + 3 wrap copies, seam-free scrolling. */
  private buildColumn(strip: SymbolId[]): Phaser.GameObjects.Container {
    const column = this.scene.add.container(0, 0);
    const total = strip.length + 3;
    for (let j = 0; j < total; j += 1) {
      const img = this.scene.add.image(0, j * SYM_H, 'atlas', symbolFrame(strip[j % strip.length]));
      img.setScale(60 / 64);
      column.add(img);
    }
    return column;
  }

  // ── spin lifecycle ───────────────────────────────────────────────────────

  get busy(): boolean {
    return this.state !== 'idle';
  }

  /** Last evaluated outcome (test bridge / QA introspection). */
  get lastOutcome(): SpinOutcome | null {
    return this.outcome;
  }

  /**
   * Run a spin. `kind` selects base or golden strips. The outcome is
   * evaluated immediately, then presented; `onDone` fires when the panel
   * closes (with the outcome for downstream scoring / jackpot FX).
   */
  spin(kind: SpinKind, onDone: DoneCallback): void {
    if (this.busy) return;
    const strips = kind === 'golden' ? STRIPS_GOLDEN : STRIPS_BASE;
    const stops = strips.map((strip) => pickStop(strip));
    this.outcome = evaluate(stops, strips, kind);
    // OFFSIDE draw: a blank line (no pair, no near-miss) may be flagged by the
    // referee — the presentation shows it and the table resets the G-O-A-L
    // multiplier. A miss is a risk, not a dead pause.
    if (!this.outcome.jackpot && this.outcome.baseWin === 0 && !this.outcome.nearMiss) {
      this.outcome.offside = randomInt(100) < OFFSIDE_PROBABILITY * 100;
    }
    this.paid = false;
    this.onDone = onDone;
    this.state = 'spinning';
    this.clearSpinTimers();
    this.generation += 1;
    const gen = this.generation;

    // Swap to the right column set.
    this.reels.forEach((reel) => {
      reel.active = kind;
      reel.columns.base.setVisible(kind === 'base');
      reel.columns.golden.setVisible(kind === 'golden');
      this.applyScroll(reel);
    });

    // Panel intro.
    this.panel.setVisible(true).setScale(0.85).setAlpha(0);
    this.backdrop.setVisible(true);
    this.scene.tweens.add({
      targets: this.backdrop,
      alpha: 0.45,
      duration: 200,
    });
    this.scene.tweens.add({
      targets: this.panel,
      alpha: 1,
      scale: 1,
      duration: 240,
      ease: 'Back.easeOut',
    });
    this.resultText
      .setText(kind === 'golden' ? '★ GOLDEN SPIN ★' : 'GOOD LUCK!')
      .setColor(kind === 'golden' ? PALETTE_CSS.gold : PALETTE_CSS.dim);
    this.winText.setText('');
    this.paylineBar.setVisible(false);

    const anticipation =
      this.outcome.line[0] === 'trophy' && this.outcome.line[1] === 'trophy';

    // Safety net: never let a bug soft-lock the game.
    this.safetyTimer?.remove();
    this.safetyTimer = this.scene.time.addEvent({ delay: 9000, callback: () => this.forceFinish() });

    this.reels.forEach((reel, i) => {
      this.delay(90 * i, () => {
        if (gen !== this.generation) return;
        reel.state = 'spin';
        reel.speed = 0;
        reel.stopTween?.remove();
        reel.stopTween = null;
        audio.reelStart();
      });
    });

    const baseSpin = [820, 1180, 1560];
    this.reels.forEach((reel, i) => {
      let spinDelay = baseSpin[i];
      if (anticipation && i === 2) spinDelay += 1900;
      // Capture the stop index by value: even if this timer somehow survives
      // a reset, the closure can no longer dereference a nulled outcome.
      const stop = this.outcome!.stops[i];
      this.delay(spinDelay, () => {
        if (gen !== this.generation) return;
        this.stopReel(reel, i, stop);
      });
    });

    if (anticipation) {
      this.delay(baseSpin[1] + 300, () => {
        if (gen !== this.generation) return;
        this.scene.tweens.add({
          targets: this.reels[2].glow,
          alpha: { from: 0.12, to: 0.4 },
          yoyo: true,
          repeat: 6,
          duration: 220,
        });
        this.heartbeatTimer?.remove();
        this.heartbeatTimer = this.scene.time.addEvent({
          delay: 640,
          repeat: 4,
          callback: () => audio.heartbeat(),
        });
      });
    }
  }

  private stopReel(reel: Reel, index: number, stop: number): void {
    if (reel.state !== 'spin' || !this.outcome) return;
    reel.state = 'stopping';
    const stripLen = (this.outcome?.kind === 'golden' ? STRIPS_GOLDEN : STRIPS_BASE)[index].length;
    const current = reel.scroll.s;
    let target = stop - 1;
    while (target < current + 3) target += stripLen;

    const dist = target - current;
    reel.stopTween = this.scene.tweens.add({
      targets: reel.scroll,
      s: target,
      duration: 380 + dist * 6,
      ease: 'Cubic.easeOut',
      onUpdate: () => this.applyScroll(reel),
      onComplete: () => {
        reel.state = 'stopped';
        reel.scroll.s = this.wrap(stop - 1, stripLen);
        this.applyScroll(reel);
        audio.reelStop(index);
        this.scene.cameras.main.shake(40, 0.0012);
        if (this.reels.every((r) => r.state === 'stopped')) this.present();
      },
    });
  }

  private wrap(s: number, len: number): number {
    return ((s % len) + len) % len;
  }

  /** Position both columns for the current scroll value. */
  private applyScroll(reel: Reel): void {
    const sBase = this.wrap(reel.scroll.s, STRIPS_BASE[0].length);
    reel.columns.base.y = -sBase * SYM_H;
    const sGolden = this.wrap(reel.scroll.s, STRIPS_GOLDEN[0].length);
    reel.columns.golden.y = -sGolden * SYM_H;
  }

  private forceFinish(): void {
    if (this.state !== 'spinning' || !this.outcome) return;
    const strips = this.outcome.kind === 'golden' ? STRIPS_GOLDEN : STRIPS_BASE;
    this.reels.forEach((reel, i) => {
      reel.stopTween?.remove();
      reel.stopTween = null;
      reel.state = 'stopped';
      reel.scroll.s = this.wrap(this.outcome!.stops[i] - 1, strips[i].length);
      this.applyScroll(reel);
    });
    this.present();
  }

  // ── presentation ─────────────────────────────────────────────────────────

  private present(): void {
    if (this.state !== 'spinning' || !this.outcome) return;
    this.state = 'presenting';
    this.heartbeatTimer?.remove();
    this.safetyTimer?.remove();
    const outcome = this.outcome;
    const gen = this.generation;

    const finish = (delayMs: number): void => {
      this.delay(delayMs, () => {
        if (gen !== this.generation) return;
        this.scene.tweens.add({
          targets: this.panel,
          alpha: 0,
          scale: 0.9,
          duration: 240,
          onComplete: () => {
            if (gen !== this.generation) return;
            this.panel.setVisible(false);
            this.scene.tweens.add({
              targets: this.backdrop,
              alpha: 0,
              duration: 200,
              onComplete: () => {
                if (gen !== this.generation) return;
                this.backdrop.setVisible(false);
              },
            });
            this.state = 'idle';
            this.onDone?.(outcome);
            this.onDone = null;
            this.clearSpinTimers();
          },
        });
      });
    };

    if (outcome.jackpot) {
      // Full jackpot celebration is owned by the PlayScene FX layer.
      this.paid = true; // paid via the onDone → claimJackpot path
      this.resultText.setText('TROPHY ×3').setColor(PALETTE_CSS.gold);
      this.winText.setText('JACKPOT!').setColor(PALETTE_CSS.gold);
      this.flashPayline();
      audio.jackpot();
      finish(1400);
      return;
    }

    if (outcome.baseWin > 0) {
      const mult = this.getMultiplier();
      const total = outcome.baseWin * mult;
      this.paid = true;
      this.addCredits(total);
      this.resultText
        .setText(`${outcome.label}${mult > 1 ? `  ×${mult}` : ''}`)
        .setColor(outcome.trophyPair ? PALETTE_CSS.gold : PALETTE_CSS.white);
      this.winText.setColor(
        total >= 800 || outcome.trophyPair ? PALETTE_CSS.gold : PALETTE_CSS.lineGreen
      );
      this.flashPayline();
      this.countUp(this.winText, total);
      audio.win(total >= 800 || outcome.trophyPair ? 'big' : 'small');
      this.popWinningSymbols(outcome);
      if (total >= 800 || outcome.trophyPair) this.confetti();
      finish(1100 + Math.min(1200, total / 3));
      return;
    }

    if (outcome.nearMiss) {
      this.resultText.setText('ONE TROPHY AWAY!').setColor(PALETTE_CSS.magenta);
      this.winText.setText('SO CLOSE…').setColor(PALETTE_CSS.magenta);
      this.flashPayline(PALETTE.magenta);
      audio.blip(240);
      finish(1500);
      return;
    }

    if (outcome.offside) {
      this.resultText.setText('OFFSIDE!').setColor(PALETTE_CSS.red);
      this.winText.setText('MULTIPLIER RESET').setColor(PALETTE_CSS.red);
      this.flashPayline(PALETTE.red);
      audio.blip(190);
      this.scene.cameras.main.shake(140, 0.002);
      finish(1400);
      return;
    }

    this.resultText.setText('NO WIN — SPIN AGAIN').setColor(PALETTE_CSS.dim);
    finish(800);
  }

  private flashPayline(color: number = PALETTE.gold): void {
    this.paylineBar.setFillStyle(color, 0.9).setVisible(true);
    this.scene.tweens.add({
      targets: this.paylineBar,
      alpha: { from: 1, to: 0.25 },
      yoyo: true,
      repeat: 5,
      duration: 140,
      onComplete: () => this.paylineBar.setAlpha(0.9),
    });
  }

  /** Pop the payline symbols on each reel (image index = stop index). */
  private popWinningSymbols(outcome: SpinOutcome): void {
    outcome.line.forEach((sym, i) => {
      if (sym !== outcome.line[0]) return;
      const column = this.reels[i].columns[outcome.kind];
      const img = column.list[outcome.stops[i]] as Phaser.GameObjects.Image | undefined;
      if (!img) return;
      this.scene.tweens.add({
        targets: img,
        scaleX: { from: 0.94, to: 1.1 },
        scaleY: { from: 0.94, to: 1.1 },
        yoyo: true,
        repeat: 3,
        duration: 160,
      });
    });
  }

  private countUp(text: Phaser.GameObjects.Text, total: number): void {
    const counter = { v: 0 };
    this.scene.tweens.add({
      targets: counter,
      v: total,
      duration: Math.min(1400, 400 + total / 4),
      ease: 'Cubic.easeOut',
      onUpdate: () => text.setText(`+${Math.floor(counter.v)}`),
      onComplete: () => text.setText(`+${total}`),
    });
  }

  private confetti(): void {
    const emitter = this.scene.add.particles(270, 292, 'atlas', {
      frame: 'confetti',
      lifespan: 1500,
      speed: { min: 220, max: 460 },
      angle: { min: 200, max: 340 },
      gravityY: 520,
      scale: { start: 1.1, end: 0.4 },
      rotate: { min: 0, max: 360 },
      quantity: 14,
      emitting: false,
    });
    emitter.setDepth(45);
    emitter.explode(48);
    this.scene.time.delayedCall(1800, () => emitter.destroy());
  }

  /** Per-frame reel drive (only while a reel is in free-spin state). */
  update(deltaMs: number): void {
    const deltaS = deltaMs / 1000;
    for (const reel of this.reels) {
      if (reel.state !== 'spin') continue;
      reel.speed = Math.min(26, reel.speed + 2.2); // symbols / second
      reel.scroll.s += reel.speed * deltaS;
      this.applyScroll(reel);
    }
  }

  destroy(): void {
    this.generation += 1;
    this.clearSpinTimers();
    this.safetyTimer?.remove();
    this.heartbeatTimer?.remove();
  }

  /** Hard reset used by the scene watchdog — the reels must never lock up. */
  forceReset(): void {
    // Invalidate every in-flight closure of the current spin, then cancel its
    // timers outright — orphaned callbacks must never fire after this.
    this.generation += 1;
    this.clearSpinTimers();
    this.reels.forEach((reel) => {
      reel.stopTween?.remove();
      reel.stopTween = null;
      reel.state = 'stopped';
    });
    this.safetyTimer?.remove();
    this.heartbeatTimer?.remove();
    this.safetyTimer = null;
    this.heartbeatTimer = null;
    this.panel.setVisible(false);
    this.backdrop.setVisible(false).setAlpha(0);
    this.panel.setAlpha(0);
    this.state = 'idle';
    const cb = this.onDone;
    const oc = this.outcome;
    this.onDone = null;
    this.outcome = null;
    // An interrupted spin still owes its award: the outcome was decided the
    // moment the reels were set in motion, so pay any pending win BEFORE the
    // completion callback (which handles jackpots through the FX layer).
    if (oc && !this.paid) {
      this.paid = true;
      if (oc.baseWin > 0 && !oc.jackpot) {
        this.addCredits(oc.baseWin * this.getMultiplier());
      }
    }
    if (cb && oc) cb(oc);
  }

  /** delayedCall tracked so an interrupted spin can cancel it. */
  private delay(ms: number, fn: () => void): Phaser.Time.TimerEvent {
    const ev = this.scene.time.delayedCall(ms, fn);
    this.spinTimers.push(ev);
    return ev;
  }

  /** Cancel all pending spin-lifecycle timers. */
  private clearSpinTimers(): void {
    this.spinTimers.forEach((t) => t.remove());
    this.spinTimers.length = 0;
  }
}
