/**
 * GOAL RUSH — PlayScene (the machine itself).
 *
 * Assembles the table from table.config, routes Matter collisions to
 * scoring/economy, runs the hybrid gameplay loop (pinball feeds the slot
 * machine: saucer captures trigger base spins, the drop-target bank
 * triggers golden spins), and handles touch / keyboard / gamepad input.
 *
 * A small testing bridge (window.__goalrush) exposes the game loop to
 * automation — see README "QA / testing hooks".
 */

import * as Phaser from 'phaser';
import {
  BALL as BALL_CFG,
  JACKPOT,
  PALETTE,
  PALETTE_CSS,
  PHYSICS,
  PLUNGER,
  SCORING,
} from '../config/game.config';
import {
  BALL_SPAWN,
  BUMPERS,
  DOME,
  DRAIN,
  DROP_TARGETS,
  FLIPPERS as FLIPPER_DEFS,
  LANES,
  LANE_DIVIDERS,
  POSTS,
  SAUCER,
  SLINGSHOTS,
  SPINNER,
  WALLS,
} from '../config/table.config';
import type { SpinKind, SpinOutcome } from '../config/slots.config';
import { GameState } from '../state/GameState';
import { audio } from '../audio/AudioKit';
import { Flipper } from '../physics/Flipper';
import { Plunger } from '../physics/Plunger';
import { Bumper } from '../physics/Bumper';
import { Slingshot } from '../physics/Slingshot';
import { DropTargetBank } from '../physics/DropTargetBank';
import { Spinner } from '../physics/Spinner';
import { Saucer } from '../physics/Saucer';
import { Ball } from '../physics/Ball';
import { SlotMachine } from '../slots/SlotMachine';
import { Hud } from '../ui/Hud';
import { JackpotFx } from '../ui/JackpotFx';
import { ScoreFx } from '../ui/ScoreFx';
import { TouchControls } from '../ui/TouchControls';

type Phase = 'title' | 'playing' | 'over';

export class PlayScene extends Phaser.Scene {
  private state!: GameState;
  private hud!: Hud;
  private slots!: SlotMachine;
  private jackpotFx!: JackpotFx;
  private ball!: Ball;
  private flippers!: { left: Flipper; right: Flipper };
  private plunger!: Plunger;
  private bumpers: Bumper[] = [];
  private bumperBodies = new Map<number, Bumper>();
  private slings = new Map<string, Slingshot>();
  private dropBank!: DropTargetBank;
  private spinner!: Spinner;
  private saucer!: Saucer;
  private trail!: Phaser.GameObjects.Particles.ParticleEmitter;
  private scoreFx!: ScoreFx;
  private controls!: TouchControls;

  /** Body id → bumper index (for the HAT-TRICK tracker). */
  private bumperIndex = new Map<number, number>();
  /** Spinner passes this ball — N earns a FREE SPIN. */
  private spinnerPasses = 0;
  /** Distinct bumpers hit inside the hat-trick window. */
  private hatTrickHits = new Set<number>();
  private hatTrickAt = 0;
  /** Next credit milestone that awards an extra ball. */
  private extraBallIdx = 0;

  private laneLetterTexts: Phaser.GameObjects.Text[] = [];
  private laneLit = [false, false, false, false];

  private phase: Phase = 'title';
  private saveUntil = 0;
  private saveUsedThisBall = false;
  private combo = 0;
  private lastComboAt = 0;
  private stuckSince = 0;
  private restarting = false;
  private overShownAt = 0;

  private titleOverlay!: Phaser.GameObjects.Container;
  private overOverlay!: Phaser.GameObjects.Container;

  private pointerZones = new Map<number, 'L' | 'R' | 'P'>();
  private swipeStarts = new Map<number, { x: number; y: number; t: number }>();
  private padPrev = { lb: false, rb: false, a: false, x: false };
  private restartHandler = (): void => this.restart();
  /** Fixed-timestep accumulator (physics decoupled from render rate). */
  private accumulator = 0;
  /** Debug counters exposed via the test bridge. */
  private stepCount = 0;
  private lastFrameDelta = 0;
  /** Real-clock timestamp for the accumulator (Phaser clamps its smoothed
   * delta below 30 fps — unusable for real-time physics). */
  private lastRealTime = 0;
  /** Slot watchdog: force-reset a spin that somehow never completes. */
  private slotsBusySince = 0;
  /** Stuck-ball episode counter — nudges escalate before anything wedges. */
  private stuckEpisodes = 0;
  /** Timestamp of the last time the ball was properly moving. */
  private lastBallFastAt = 0;

  constructor() {
    super('Play');
  }

  // ── setup ────────────────────────────────────────────────────────────────

  create(): void {
    this.phase = 'title';
    this.restarting = false;
    this.accumulator = 0;
    this.lastRealTime = 0;
    this.state = new GameState();

    this.matter.world.setGravity(0, PHYSICS.gravityY);
    // Drive the engine ourselves with a fixed-step accumulator so the ball
    // moves at identical real-world speed on 60/120/144 Hz displays (Phaser's
    // default steps Matter once per rendered frame — refresh-rate dependent).
    this.matter.world.autoUpdate = false;

    // Static art (single sprite).
    this.add.image(0, 0, 'field').setOrigin(0, 0).setDepth(0);

    // Static physics from config.
    this.buildWalls();
    this.buildDome();
    this.buildPosts();
    this.buildLaneDividers();
    this.buildLaneSensors();
    this.buildDrain();

    // Dynamic components.
    const sparkles = this.add.particles(0, 0, 'atlas', {
      frame: 'spark',
      lifespan: 420,
      speed: { min: 60, max: 240 },
      scale: { start: 0.9, end: 0 },
      blendMode: 'ADD',
      emitting: false,
    });
    sparkles.setDepth(9);

    this.bumpers = BUMPERS.map((def, i) => {
      const bumper = new Bumper(this, def, sparkles);
      this.bumperBodies.set(bumper.body.id, bumper);
      this.bumperIndex.set(bumper.body.id, i);
      return bumper;
    });

    for (const def of SLINGSHOTS) {
      this.slings.set(def.label, new Slingshot(this, def, sparkles));
    }

    this.dropBank = new DropTargetBank(
      this,
      DROP_TARGETS,
      (index, remaining) => this.onDropHit(index, remaining),
      () => this.onBankComplete()
    );

    this.spinner = new Spinner(this, (speed) => this.onSpinnerPass(speed));
    this.spinner.onRevolution = () => audio.spinnerTick();
    this.saucer = new Saucer(this, () => this.onSaucerCapture());
    this.flippers = {
      left: new Flipper(this, FLIPPER_DEFS[0], () => audio.flipper()),
      right: new Flipper(this, FLIPPER_DEFS[1], () => audio.flipper()),
    };
    this.ball = new Ball(this);
    this.plunger = new Plunger(this, () => (this.ball.active ? this.ball : null));

    // Ball trail.
    this.trail = this.add.particles(0, 0, 'atlas', {
      frame: 'ball-glow',
      lifespan: 280,
      scale: { start: 0.55, end: 0.08 },
      alpha: { start: 0.55, end: 0 },
      blendMode: 'ADD',
      frequency: 20,
      emitting: false,
    });
    this.trail.setDepth(7);
    this.trail.startFollow(this.ball.image);

    // UI + slot machine.
    this.hud = new Hud(this, this.state);
    this.scoreFx = new ScoreFx(this);
    this.controls = new TouchControls(this);
    this.jackpotFx = new JackpotFx(this);
    this.slots = new SlotMachine(
      this,
      () => this.state.multiplier,
      (amount) => {
        this.state.addCredits(amount);
        this.checkExtraBall();
      }
    );

    // Input + flow.
    this.buildInput();
    this.buildTitle();
    this.buildOverOverlay();

    this.matter.world.on('collisionstart', this.onCollision, this);
    this.events.on('plunger-fired', this.launchBall, this);

    // React bridge (game over dialog → restart).
    window.addEventListener('goalrush:restart', this.restartHandler);
    this.events.once('shutdown', () => {
      // Defensive: Phaser tears subsystems down before firing shutdown —
      // an exception here would abort scene.restart() entirely.
      window.removeEventListener('goalrush:restart', this.restartHandler);
      try {
        this.slots?.destroy();
        this.dropBank?.destroy();
        this.matter.world?.off('collisionstart', this.onCollision, this);
        this.events.off('plunger-fired', this.launchBall, this);
      } catch (err) {
        console.warn('GOAL RUSH shutdown cleanup', err);
      }
    });

    this.buildTestBridge();
  }

  private buildWalls(): void {
    for (const w of WALLS) {
      this.matter.add.rectangle(w.x, w.y, w.width, w.height, {
        isStatic: true,
        angle: w.angle ?? 0,
        chamfer: w.chamfer ? { radius: w.chamfer } : undefined,
        restitution: PHYSICS.wallRestitution,
        friction: PHYSICS.wallFriction,
        label: w.label ?? 'wall',
      });
    }
  }

  /** Top arc: static tangent segments along a half-ellipse. */
  private buildDome(): void {
    const steps = DOME.segments;
    for (let i = 0; i <= steps; i += 1) {
      const t = Math.PI + (Math.PI * i) / steps;
      const x = DOME.cx + DOME.rx * Math.cos(t);
      const y = DOME.cy + DOME.ry * Math.sin(t);
      const angle = t + Math.PI / 2; // tangent direction
      const len = ((Math.PI * ((DOME.rx + DOME.ry) / 2)) / steps) * 1.45;
      this.matter.add.rectangle(x, y, len, DOME.thickness, {
        isStatic: true,
        angle,
        chamfer: { radius: DOME.thickness / 2 },
        restitution: PHYSICS.wallRestitution,
        friction: PHYSICS.wallFriction,
        label: 'wall',
      });
    }
  }

  private buildPosts(): void {
    for (const p of POSTS) {
      this.matter.add.circle(p.x, p.y, p.radius, {
        isStatic: true,
        restitution: 0.55,
        friction: 0,
        label: p.label ?? 'post',
      });
      this.add.image(p.x, p.y, 'atlas', 'post').setDepth(4);
    }
  }

  private buildLaneDividers(): void {
    for (const d of LANE_DIVIDERS) {
      this.matter.add.rectangle(d.x, d.y, d.width, d.height, {
        isStatic: true,
        angle: d.angle ?? 0,
        chamfer: d.chamfer ? { radius: d.chamfer } : undefined,
        restitution: PHYSICS.wallRestitution,
        friction: PHYSICS.wallFriction,
        label: 'wall',
      });
    }
  }

  private buildLaneSensors(): void {
    LANES.forEach((lane, i) => {
      this.matter.add.circle(lane.x, lane.y, 15, {
        isStatic: true,
        isSensor: true,
        label: `lane-${i}`,
      });
      const txt = this.add
        .text(lane.x, lane.y, lane.letter, {
          fontFamily: '"Arial Black", sans-serif',
          fontSize: '30px',
          color: PALETTE_CSS.laneIdle,
          stroke: '#0a0f1e',
          strokeThickness: 4,
          resolution: 2,
        })
        .setOrigin(0.5)
        .setDepth(4);
      txt.setShadow(0, 2, '#04060c', 6, true, true);
      this.laneLetterTexts.push(txt);
    });
    this.laneLit = [false, false, false, false];
  }

  private buildDrain(): void {
    this.matter.add.rectangle(DRAIN.x, DRAIN.y, DRAIN.width, DRAIN.height, {
      isStatic: true,
      isSensor: true,
      label: 'drain',
    });
  }

  // ── input ────────────────────────────────────────────────────────────────

  private buildInput(): void {
    const kb = this.input.keyboard;
    if (!kb) return;
    kb.addCapture('SPACE,UP,DOWN,LEFT,RIGHT');
    kb.on('keydown', () => audio.unlock());

    const pressGroup = (keys: string[], down: () => void, up: () => void): void => {
      for (const key of keys) {
        kb.on(`keydown-${key}`, down);
        kb.on(`keyup-${key}`, up);
      }
    };

    pressGroup(['Z', 'A', 'LEFT'], () => this.flippers.left.press(), () => this.flippers.left.release());
    pressGroup(
      ['M', 'L', 'RIGHT'],
      () => this.flippers.right.press(),
      () => this.flippers.right.release()
    );
    pressGroup(
      ['SPACE', 'DOWN'],
      () => this.plunger.press(),
      () => this.plunger.release()
    );
    kb.on('keydown-N', () => this.nudge());
    kb.on('keydown-UP', () => this.nudge());

    // Touch: left/right halves flip, lane region charges the plunger.
    this.input.addPointer(3);
    this.input.on('pointerdown', (p: Phaser.Input.Pointer) => {
      audio.unlock();
      if (this.phase === 'title') {
        this.startGame();
        return;
      }
      if (this.phase === 'over') {
        this.tryRestartFromCanvas();
        return;
      }
      if (p.x > 482) {
        this.pointerZones.set(p.id, 'P');
        this.plunger.press();
        return;
      }
      if (p.x < 270) {
        this.pointerZones.set(p.id, 'L');
        this.flippers.left.press();
      } else {
        this.pointerZones.set(p.id, 'R');
        this.flippers.right.press();
      }
      this.swipeStarts.set(p.id, { x: p.x, y: p.y, t: p.event.timeStamp });
    });
    const release = (p: Phaser.Input.Pointer): void => {
      const zone = this.pointerZones.get(p.id);
      if (zone === 'L') this.flippers.left.release();
      if (zone === 'R') this.flippers.right.release();
      if (zone === 'P') this.plunger.release();
      this.pointerZones.delete(p.id);
      // Swipe = nudge.
      const start = this.swipeStarts.get(p.id);
      if (start) {
        const dt = p.event.timeStamp - start.t;
        const dist = Math.hypot(p.x - start.x, p.y - start.y);
        if (dt < 260 && dist > 46) this.nudge();
        this.swipeStarts.delete(p.id);
      }
    };
    this.input.on('pointerup', release);
    this.input.on('pointerupoutside', release);

    // Gamepad connect hint.
    window.addEventListener('gamepadconnected', this.onGamepadConnected);
    this.events.once('shutdown', () =>
      window.removeEventListener('gamepadconnected', this.onGamepadConnected)
    );
  }

  private onGamepadConnected = (): void => {
    if (this.phase === 'playing') this.hud.announce('GAMEPAD READY', PALETTE_CSS.lineGreen);
  };

  private pollGamepad(): void {
    const nav = navigator as Navigator & { getGamepads?: () => (Gamepad | null)[] };
    if (!nav.getGamepads) return;
    const pads = nav.getGamepads();
    const pad = pads.find((p) => p && p.connected);
    if (!pad) return;

    const lb = pad.buttons[4]?.pressed ?? false;
    const rb = pad.buttons[5]?.pressed ?? false;
    const a = pad.buttons[0]?.pressed ?? false;
    const x = pad.buttons[2]?.pressed ?? false;

    if (lb !== this.padPrev.lb) {
      if (lb) this.flippers.left.press();
      else this.flippers.left.release();
    }
    if (rb !== this.padPrev.rb) {
      if (rb) this.flippers.right.press();
      else this.flippers.right.release();
    }
    if (a !== this.padPrev.a) {
      if (a) this.plunger.press();
      else this.plunger.release();
    }
    if (x && !this.padPrev.x) this.nudge();
    this.padPrev = { lb, rb, a, x };
  }

  // ── title / game over ────────────────────────────────────────────────────

  private buildTitle(): void {
    const c = this.add.container(0, 0).setDepth(70);
    const shade = this.add.rectangle(270, 480, 540, 960, PALETTE.bgDeep, 0.78);
    const ballIcon = this.add.image(270, 236, 'atlas', 'ball').setScale(2.4);
    const t1 = this.add
      .text(270, 320, 'GOAL', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '88px',
        color: PALETTE_CSS.lineGreen,
        resolution: 2,
      })
      .setOrigin(0.5);
    const t2 = this.add
      .text(270, 402, 'RUSH', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '88px',
        color: PALETTE_CSS.gold,
        resolution: 2,
      })
      .setOrigin(0.5);
    const sub = this.add
      .text(270, 470, 'PINBALL  ×  SLOTS', {
        fontFamily: 'sans-serif',
        fontSize: '22px',
        color: PALETTE_CSS.white,
        resolution: 2,
      })
      .setOrigin(0.5);
    const best =
      this.state.best > 0
        ? this.add
            .text(270, 520, `BEST  ${this.state.best.toLocaleString()}`, {
              fontFamily: '"Arial Black", sans-serif',
              fontSize: '20px',
              color: PALETTE_CSS.goldSoft,
              resolution: 2,
            })
            .setOrigin(0.5)
        : null;
    const cta = this.add
      .text(270, 610, 'TAP TO KICK OFF', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '30px',
        color: PALETTE_CSS.magenta,
        resolution: 2,
      })
      .setOrigin(0.5);
    const hints = this.add
      .text(
        270,
        740,
        'Z / ←  LEFT FLIPPER      M / →  RIGHT FLIPPER\nSPACE  HOLD TO LAUNCH      N  NUDGE\nTOUCH: TAP ARROWS / SIDES TO FLIP · HOLD LANE TO LAUNCH · SWIPE TO NUDGE',
        {
          fontFamily: 'sans-serif',
          fontSize: '14px',
          color: PALETTE_CSS.dim,
          align: 'center',
          lineSpacing: 8,
          resolution: 2,
        }
      )
      .setOrigin(0.5);
    c.add([shade, ballIcon, t1, t2, sub, cta, hints]);
    if (best) c.add(best);
    this.tweens.add({
      targets: cta,
      alpha: { from: 1, to: 0.35 },
      yoyo: true,
      repeat: -1,
      duration: 620,
      ease: 'Sine.easeInOut',
    });
    this.titleOverlay = c;
  }

  private buildOverOverlay(): void {
    const c = this.add.container(0, 0).setDepth(70).setVisible(false);
    const shade = this.add.rectangle(270, 480, 540, 960, PALETTE.bgDeep, 0.82);
    const t1 = this.add
      .text(270, 330, 'FULL TIME!', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '58px',
        color: PALETTE_CSS.gold,
        resolution: 2,
      })
      .setOrigin(0.5);
    this.overOverlayData = {
      credits: this.add
        .text(270, 420, '', {
          fontFamily: '"Arial Black", sans-serif',
          fontSize: '38px',
          color: PALETTE_CSS.lineGreen,
          resolution: 2,
        })
        .setOrigin(0.5),
      note: this.add
        .text(270, 480, '', {
          fontFamily: 'sans-serif',
          fontSize: '17px',
          color: PALETTE_CSS.dim,
          resolution: 2,
        })
        .setOrigin(0.5),
    };
    const cta = this.add
      .text(270, 600, 'TAP TO PLAY AGAIN', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '26px',
        color: PALETTE_CSS.magenta,
        resolution: 2,
      })
      .setOrigin(0.5);
    c.add([shade, t1, this.overOverlayData.credits, this.overOverlayData.note, cta]);
    this.tweens.add({
      targets: cta,
      alpha: { from: 1, to: 0.35 },
      yoyo: true,
      repeat: -1,
      duration: 620,
      ease: 'Sine.easeInOut',
    });
    this.overOverlay = c;
  }

  private overOverlayData!: {
    credits: Phaser.GameObjects.Text;
    note: Phaser.GameObjects.Text;
  };

  private startGame(): void {
    if (this.phase !== 'title') return;
    this.phase = 'playing';
    this.titleOverlay.setVisible(false);
    this.state.startGame();
    this.saveUsedThisBall = false; // fresh ball life — save re-armed
    audio.whistle();
    this.cameras.main.flash(220, 80, 255, 160);
    this.spawnBall();
  }

  private spawnBall(): void {
    this.ball.spawn();
    this.trail.emitting = true;
    this.spinnerPasses = 0;
    this.hatTrickHits.clear();
    this.hud.announce('BALL ON', PALETTE_CSS.white, 'hold to charge · release to launch');
  }

  private launchBall(power: number): void {
    if (!this.ball.inLane()) return;
    const speed = Phaser.Math.Linear(PLUNGER.minSpeed, PLUNGER.maxSpeed, power * power);
    this.ball.setVelocity(Phaser.Math.FloatBetween(-0.25, 0.25), -speed);
    this.saveUntil = this.time.now + BALL_CFG.saveWindowMs;
    audio.plunger();
  }

  private nudge(): void {
    if (this.phase !== 'playing' || !this.ball.active) return;
    const v = this.ball.image.body?.velocity ?? { x: 0, y: 0 };
    this.ball.setVelocity(v.x + Phaser.Math.FloatBetween(-1.4, 1.4), v.y - 1.7);
    this.cameras.main.shake(90, 0.004);
    audio.nudge();
  }

  // ── scoring events ───────────────────────────────────────────────────────

  private bumpCombo(): void {
    const now = this.time.now;
    this.combo = now - this.lastComboAt <= SCORING.comboWindowMs ? this.combo + 1 : 1;
    this.lastComboAt = now;
  }

  /**
   * Award table credits: applies the G-O-A-L multiplier, floats a popup at
   * the point of impact, and checks the extra-ball milestones.
   */
  private award(amount: number, x?: number, y?: number, popup = true): number {
    const total = amount * this.state.multiplier;
    this.state.addCredits(total);
    if (popup) {
      const px = x ?? this.ball.x;
      const py = y ?? this.ball.y;
      const label =
        this.state.multiplier > 1 ? `+${total} ×${this.state.multiplier}` : `+${total}`;
      this.scoreFx.pop(
        px,
        py,
        label,
        this.state.multiplier > 1 ? PALETTE_CSS.gold : PALETTE_CSS.white
      );
    }
    this.checkExtraBall();
    return total;
  }

  /** Credit milestones award an extra ball (capped). */
  private checkExtraBall(): void {
    const thresholds = SCORING.extraBallThresholds;
    while (
      this.extraBallIdx < thresholds.length &&
      this.state.credits >= thresholds[this.extraBallIdx]
    ) {
      this.extraBallIdx += 1;
      if (this.state.addBall(SCORING.maxBalls)) {
        this.hud.announce('EXTRA BALL!', PALETTE_CSS.lineGreen, 'bonus ball added');
        audio.win('big');
        this.cameras.main.flash(200, 53, 240, 139);
      }
    }
  }

  /** Confetti burst used by big table bonuses (hat-trick etc.). */
  private confettiAt(x: number, y: number): void {
    const emitter = this.add.particles(x, y, 'atlas', {
      frame: 'confetti',
      lifespan: 1200,
      speed: { min: 180, max: 380 },
      angle: { min: 210, max: 330 },
      gravityY: 480,
      scale: { start: 0.9, end: 0.35 },
      rotate: { min: 0, max: 360 },
      quantity: 10,
      emitting: false,
    });
    emitter.setDepth(45);
    emitter.explode(30);
    this.time.delayedCall(1500, () => emitter.destroy());
  }

  private onBumperHit(index: number): void {
    this.bumpCombo();
    const bonus = this.combo > 1 ? SCORING.comboBonus * (this.combo - 1) : 0;
    const b = this.bumpers[index];
    const bx = b ? b.image.x : this.ball.x;
    const by = b ? b.image.y : this.ball.y;
    this.award(SCORING.bumper + bonus, bx, by);
    this.state.contributePot(JACKPOT.contributions.bumper);
    audio.bumper(this.combo);
    this.hud.showCombo(this.combo);
    this.cameras.main.shake(55, 0.0014);

    // HAT-TRICK: all three distinct bumpers inside the window → big bonus.
    const now = this.time.now;
    if (now - this.hatTrickAt > SCORING.hatTrickWindowMs) {
      this.hatTrickAt = now;
      this.hatTrickHits.clear();
    }
    this.hatTrickHits.add(index);
    if (this.hatTrickHits.size >= 3) {
      this.hatTrickHits.clear();
      const total = this.award(SCORING.hatTrickBonus, bx, by - 26);
      this.hud.announce('HAT-TRICK!', PALETTE_CSS.gold, `all three bumpers · +${total}`);
      audio.win('big');
      audio.whistle();
      this.cameras.main.shake(240, 0.005);
      this.confettiAt(bx, by - 40);
    }
  }

  private onSlingHit(): void {
    this.bumpCombo();
    const bonus = this.combo > 1 ? SCORING.comboBonus * (this.combo - 1) : 0;
    this.award(SCORING.slingshot + bonus, this.ball.x, this.ball.y);
    this.state.contributePot(JACKPOT.contributions.slingshot);
    audio.sling();
  }

  private onSpinnerPass(speed: number): void {
    void speed;
    this.award(SCORING.spinnerPass, SPINNER.x + 26, SPINNER.y - 12);
    this.state.contributePot(JACKPOT.contributions.spinnerPass);
    this.spinnerPasses += 1;
    if (this.spinnerPasses >= SCORING.freeSpinPasses) {
      if (!this.slots.busy) {
        this.spinnerPasses = 0;
        this.hud.announce('FREE SPIN!', PALETTE_CSS.magenta, 'spinner loop bonus');
        audio.win('small');
        this.triggerSpin('base');
      }
    } else if (this.spinnerPasses === SCORING.freeSpinPasses - 1) {
      this.hud.announce('ONE MORE LOOP…', PALETTE_CSS.dim, 'free spin almost earned');
    }
  }

  private onDropHit(_index: number, remaining: number): void {
    this.award(SCORING.dropTarget, this.ball.x, this.ball.y);
    this.state.contributePot(JACKPOT.contributions.dropTarget);
    audio.blip(520);
    if (remaining === 1) this.dropBank.markHot();
  }

  private onBankComplete(): void {
    this.award(SCORING.bankComplete, this.ball.x, this.ball.y - 20);
    this.state.contributePot(JACKPOT.contributions.goalLanesComplete);
    this.hud.announce('GOLDEN SPIN!', PALETTE_CSS.gold, 'trophy odds boosted');
    this.triggerSpin('golden');
  }

  private onSaucerCapture(): void {
    this.award(SCORING.saucer, SAUCER.x, SAUCER.y - 22);
    this.state.contributePot(JACKPOT.contributions.saucer);
    audio.blip(660);
    this.ball.capture();
    this.trail.emitting = false;
    if (!this.triggerSpin('base')) {
      // Defensive fallback: reels were busy after all — bounce the ball out.
      this.time.delayedCall(150, () => this.ejectBall());
    }
  }

  /** Release the ball from the saucer back into play. */
  private ejectBall(): void {
    if (!this.ball.active && this.phase === 'playing') {
      this.ball.releaseAt(SAUCER.x, SAUCER.y + 6, SAUCER.eject.x, SAUCER.eject.y);
      this.saucer.eject(this.ball, this.time.now);
      this.trail.emitting = true;
    }
  }

  private triggerSpin(kind: SpinKind): boolean {
    if (this.slots.busy) return false;
    this.state.registerSpin();
    // Mid-table bumpers sit under the reel panel and their post-FX glow
    // bleeds through — hide them for the duration of the spin.
    this.bumpers.forEach((b) => b.image.setVisible(false));
    this.slots.spin(kind, (outcome) => this.onSpinDone(kind, outcome));
    return true;
  }

  private onSpinDone(kind: SpinKind, outcome: SpinOutcome): void {
    this.bumpers.forEach((b) => b.image.setVisible(true));
    const eject = (): void => {
      if (kind === 'base') this.ejectBall();
    };
    // OFFSIDE: a losing spin can flag the referee — the G-O-A-L multiplier
    // is wiped. A miss is never a dead pause: it is a risk.
    if (outcome.offside && this.state.multiplier > 1) {
      this.state.setMultiplier(1);
      this.hud.announce('OFFSIDE!', PALETTE_CSS.red, 'blank line · multiplier reset');
      audio.blip(180);
      this.cameras.main.flash(180, 255, 51, 85);
    }
    if (outcome.jackpot) {
      const won = this.state.claimJackpot();
      this.jackpotFx.play(won, eject);
      return;
    }
    this.time.delayedCall(220, eject);
  }

  private onLaneLetter(index: number): void {
    if (this.laneLit[index]) return;
    this.laneLit[index] = true;
    const txt = this.laneLetterTexts[index];
    txt.setColor(PALETTE_CSS.lineGreen);
    txt.setShadow(0, 0, PALETTE_CSS.lineGreen, 14, true, true);
    this.tweens.add({ targets: txt, scale: { from: 1.4, to: 1 }, duration: 220, ease: 'Back.easeOut' });
    this.award(SCORING.laneLetter, LANES[index].x, LANES[index].y + 26);
    this.state.contributePot(JACKPOT.contributions.laneLetter);
    audio.lane(index);

    if (this.laneLit.every(Boolean)) {
      this.state.setMultiplier(this.state.multiplier + 1);
      this.award(SCORING.goalLanesComplete, 270, 210);
      this.state.contributePot(JACKPOT.contributions.goalLanesComplete);
      this.hud.announce(`GOAL! ×${this.state.multiplier}`, PALETTE_CSS.gold, 'all awards boosted');
      audio.win('small');
      this.time.delayedCall(650, () => this.resetLaneLetters());
    }
  }

  private resetLaneLetters(): void {
    this.laneLit = [false, false, false, false];
    this.laneLetterTexts.forEach((txt) => {
      txt.setColor(PALETTE_CSS.laneIdle);
      txt.setShadow(0, 2, '#04060c', 6, true, true);
    });
  }

  // ── ball flow ────────────────────────────────────────────────────────────

  private onDrain(): void {
    this.trail.emitting = false;
    const now = this.time.now;

    // Ball save: ONLY the short kick-off grace window (3 s) and at most ONE
    // save per ball life. A drain through the flipper gap once the ball is
    // genuinely in play always costs a ball — the counter must go down.
    if (now < this.saveUntil && !this.saveUsedThisBall) {
      this.saveUsedThisBall = true;
      this.hud.announce('BALL SAVED!', PALETTE_CSS.lineGreen, 'kick-off grace · once per ball');
      audio.blip(980);
      this.ball.retire();
      this.time.delayedCall(420, () => this.spawnBall());
      return;
    }

    audio.drain();
    const remaining = this.state.loseBall();
    this.state.setMultiplier(1);
    this.resetLaneLetters();
    this.combo = 0;

    if (remaining > 0) {
      this.hud.announce('GOAL CONCEDED!', PALETTE_CSS.red, `${remaining} ball${remaining > 1 ? 's' : ''} left`);
      this.ball.retire();
      this.saveUsedThisBall = false; // next ball = fresh life, save re-armed
      this.time.delayedCall(1500, () => this.spawnBall());
    } else {
      this.ball.retire();
      this.endGame();
    }
  }

  private endGame(): void {
    this.phase = 'over';
    const credits = this.state.credits;
    const newBest = credits > this.state.best;
    this.state.gameOver();
    this.hud.announce('FULL TIME!', PALETTE_CSS.gold);
    const rank =
      credits >= 9000
        ? 'LEGEND'
        : credits >= 4000
          ? 'PRO'
          : credits >= 1500
            ? 'SEMI-PRO'
            : 'ROOKIE';
    this.overOverlayData.credits.setText(`${credits.toLocaleString()} CREDITS`);
    const spinNote =
      this.state.spins > 0
        ? `${this.state.spins} slot spin${this.state.spins > 1 ? 's' : ''} played`
        : 'hit the SPIN saucer to spin the reels!';
    this.overOverlayData.note.setText(
      `${rank} · ${spinNote}${newBest ? ' · NEW BEST!' : ` · BEST ${this.state.best.toLocaleString()}`}`
    );
    if (newBest && credits > 0) {
      audio.win('big');
      audio.whistle();
    }
    this.time.delayedCall(900, () => {
      this.overOverlay.setVisible(true).setAlpha(0);
      this.tweens.add({ targets: this.overOverlay, alpha: 1, duration: 320 });
      this.overShownAt = this.time.now;
    });
  }

  private tryRestartFromCanvas(): void {
    if (this.time.now - this.overShownAt < 800) return;
    this.restart();
  }

  private restart(): void {
    if (this.restarting || this.phase !== 'over') return;
    this.restarting = true;
    this.overOverlay.setVisible(false);
    this.scene.restart();
  }

  // ── collisions ───────────────────────────────────────────────────────────

  private onCollision(
    event: MatterJS.IEventCollision<Phaser.Physics.Matter.World>
  ): void {
    if (!this.ball.active) return;
    const time = this.time.now;
    for (const pair of event.pairs) {
      const a = pair.bodyA as MatterJS.BodyType;
      const b = pair.bodyB as MatterJS.BodyType;
      const ballBody = a.label === 'ball' ? a : b.label === 'ball' ? b : null;
      if (!ballBody) continue;
      const other = ballBody === a ? b : a;

      switch (other.label) {
        case 'bumper': {
          const bumper = this.bumperBodies.get(other.id);
          if (bumper && bumper.canKick(time)) {
            bumper.kick(this.ball, time);
            this.onBumperHit(this.bumperIndex.get(other.id) ?? 0);
          }
          break;
        }
        case 'sling-left':
        case 'sling-right': {
          const sling = this.slings.get(other.label);
          if (sling && sling.canKick(time)) {
            sling.kick(this.ball, time);
            this.onSlingHit();
          }
          break;
        }
        case 'drop': {
          const index = this.dropBank.indexFromBody(other);
          if (index >= 0) this.dropBank.hit(index);
          break;
        }
        case 'spinner': {
          const v = this.ball.image.body?.velocity ?? { x: 0, y: 0 };
          this.spinner.pass(time, Math.hypot(v.x, v.y));
          break;
        }
        case 'saucer':
          // The saucer only accepts the ball while the reels are free —
          // otherwise a spin-in-flight would orphan the capture forever.
          if (!this.slots.busy) this.saucer.capture(this.ball, time);
          break;
        case 'drain':
          this.onDrain();
          break;
        default:
          if (other.label.startsWith('lane-')) {
            this.onLaneLetter(Number(other.label.slice(5)));
          }
          break;
      }
    }
  }

  // ── frame loop ───────────────────────────────────────────────────────────

  update(_time: number, delta: number): void {
    // Real elapsed time — Phaser clamps its smoothed delta on slow frames,
    // which would put the physics into slow motion below ~30 fps.
    const now = performance.now();
    if (this.lastRealTime === 0) this.lastRealTime = now;
    const realDelta = now - this.lastRealTime;
    this.lastRealTime = now;
    this.lastFrameDelta = realDelta;
    void delta;
    // ── fixed-timestep physics ─────────────────────────────────────
    this.accumulator = Math.min(
      this.accumulator + Math.min(realDelta, PHYSICS.accumulatorClampMs),
      PHYSICS.accumulatorClampMs
    );
    let steps = 0;
    while (this.accumulator >= PHYSICS.fixedStepMs && steps < PHYSICS.maxSubSteps) {
      this.physicsSubstep();
      this.matter.world.step(PHYSICS.fixedStepMs);
      this.accumulator -= PHYSICS.fixedStepMs;
      steps += 1;
      this.stepCount += 1;
    }

    // ── per-frame systems ──────────────────────────────────────────
    this.plunger?.update(realDelta);
    this.slots?.update(realDelta);
    this.pollGamepad();

    // Virtual spinner blade + on-screen controls mirror.
    this.spinner?.update(realDelta, this.time.now);
    this.controls?.sync(this.flippers.left.isPressed(), this.flippers.right.isPressed());
    this.controls?.setLaunchHint(this.plunger.ballInLane() && !this.slots.busy);
    this.controls?.updateLaunchCharge(this.plunger.getCharge());

    // Slot watchdog: a spin must never outlive 12 s (runs regardless of the
    // ball state — a captured ball must not disable the guard).
    if (this.slots?.busy) {
      if (this.slotsBusySince === 0) this.slotsBusySince = this.time.now;
      else if (this.time.now - this.slotsBusySince > 12000) {
        this.slotsBusySince = 0;
        this.slots.forceReset();
      }
    } else {
      this.slotsBusySince = 0;
    }

    if (this.phase !== 'playing' || !this.ball?.active) return;

    // Combo decay.
    if (this.time.now - this.lastComboAt > SCORING.comboWindowMs) this.combo = 0;

    // Anti-stuck watchdog: a motionless ball gets escalating nudges.
    const v = this.ball.image.body?.velocity ?? { x: 0, y: 0 };
    const speed = Math.hypot(v.x, v.y);
    if (speed > 2) this.lastBallFastAt = this.time.now;
    // A nudge that failed to free the ball within 5 s escalates the next one.
    if (this.time.now - this.lastBallFastAt > 5000) this.stuckEpisodes = 0;
    if (speed < 0.45 && !this.ball.inLane()) {
      if (this.stuckSince === 0) this.stuckSince = this.time.now;
      else if (this.time.now - this.stuckSince > 3800) {
        this.stuckSince = 0;
        this.stuckEpisodes += 1;
        const power = this.stuckEpisodes >= 3 ? 5.5 : 1.9; // escalate
        this.ball.setVelocity(
          Phaser.Math.FloatBetween(-power * 0.7, power * 0.7),
          -power
        );
        this.cameras.main.shake(80, 0.003);
      }
    } else {
      this.stuckSince = 0;
    }
  }

  /** One deterministic 60 Hz physics step: controllers first, then engine. */
  private physicsSubstep(): void {
    this.flippers?.left.update();
    this.flippers?.right.update();
    this.ball?.clampSpeed();
  }

  // ── automation bridge (agent-browser E2E, QA) ────────────────────────────

  private buildTestBridge(): void {
    const bridge = {
      start: (): void => this.startGame(),
      phase: (): Phase => this.phase,
      state: (): Record<string, number | boolean> => ({
        credits: this.state.credits,
        pot: this.state.pot,
        balls: this.state.balls,
        multiplier: this.state.multiplier,
        spins: this.state.spins,
        running: this.state.running,
      }),
      plunge: (power = 0.85): boolean => {
        if (!this.ball.inLane()) return false;
        this.launchBall(power);
        return true;
      },
      flip: (side: 'left' | 'right', down: boolean): void => {
        const flipper = side === 'left' ? this.flippers.left : this.flippers.right;
        if (down) flipper.press();
        else flipper.release();
      },
      nudge: (): void => this.nudge(),
      spin: (kind: SpinKind): boolean => {
        if (this.slots.busy) return false;
        this.triggerSpin(kind);
        return true;
      },
      /** QA: force-interrupt a spin, as the 12 s watchdog would. */
      forceResetSlots: (): void => this.slots.forceReset(),
      /** QA: the last spin's evaluated outcome (line, win, label). */
      slotOutcome: (): Record<string, unknown> | null => {
        const o = this.slots.lastOutcome;
        return o
          ? {
              line: o.line,
              baseWin: o.baseWin,
              jackpot: o.jackpot,
              label: o.label,
              kind: o.kind,
              nearMiss: o.nearMiss,
              offside: o.offside,
            }
          : null;
      },
      ballPos: (): { x: number; y: number } | null =>
        this.ball.active ? { x: this.ball.x, y: this.ball.y } : null,
      /** Physics QA dump: every body's label, position and angle. */
      dumpBodies: (): Array<Record<string, unknown>> =>
        (this.matter.world.localWorld as unknown as {
          bodies: MatterJS.BodyType[];
        }).bodies.map((b) => ({
          label: b.label,
          x: Math.round(b.position.x * 10) / 10,
          y: Math.round(b.position.y * 10) / 10,
          angle: Math.round(b.angle * 1000) / 1000,
          isStatic: b.isStatic ?? false,
          av: Math.round((b.angularVelocity ?? 0) * 1000) / 1000,
        })),
      /** QA: teleport the ball with a velocity (flipper-kick verification
       *  under headless throttling — no wall-clock dependence). */
      ballPlace: (x: number, y: number, vx = 0, vy = 0): boolean => {
        if (this.phase !== 'playing') return false;
        this.ball.releaseAt(x, y, vx, vy);
        return true;
      },
      debug: (): Record<string, unknown> => ({
        fps: this.game.loop.actualFps,
        frameDelta: this.lastFrameDelta,
        physicsSteps: this.stepCount,
        accumulator: Math.round(this.accumulator * 100) / 100,
        ballVx: this.ball.image.body?.velocity.x ?? 0,
        ballVy: this.ball.image.body?.velocity.y ?? 0,
        ballStatic: (this.ball.image.body as MatterJS.BodyType | null)?.isStatic ?? true,
        bodyY: this.ball.image.body?.position.y ?? -1,
        imgY: this.ball.image.y,
        imgVisible: this.ball.image.visible,
        active: this.ball.active,
        slotBusy: this.slots.busy,
        slotState: (this.slots as unknown as { state?: string }).state ?? '?',
      }),
    };
    (window as unknown as Record<string, unknown>).__goalrush = bridge;
  }
}
