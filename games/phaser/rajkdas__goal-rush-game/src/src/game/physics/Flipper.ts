/**
 * GOAL RUSH — Flipper (static-kinematic, arcade-exact).
 *
 * The bat is a STATIC body that is re-placed every physics sub-step around a
 * fixed world pivot — never integrated, never pushed by the solver, never
 * wedged off its anchor. Two things are painted per step:
 *
 *  1. PLACEMENT — the angle steps toward the pressed/rest target at a fixed
 *     rate (FLIPPER.upRate ≈ 0.24 rad/step, ~84 ms full swing). The per-step
 *     face sweep (~15 px at the tip) stays below the ball Ø (26 px), so the
 *     moving face can never tunnel past the ball: contact is continuous and
 *     every press connects. (The old 0.72 rad/step design swept 45 px/step —
 *     the bat regularly jumped over a resting ball: "flip sometimes fails".)
 *
 *  2. RESOLVER VELOCITY — Matter's collision solver reads a body's velocity
 *     from its position history (position − positionPrev), NOT from the
 *     velocity field. For a dynamic body that is re-placed every step, the
 *     engine's own Verlet integration then displaces it BEYOND the placement,
 *     so the next solver pass sees a polluted, wobble-derivative velocity
 *     (measured ±0.52 rad off-placement — the erratic kicks). A STATIC body
 *     is never integrated, and Body.setPosition/setAngle with
 *     updateVelocity=true + an explicit setVelocity/setAngularVelocity paint
 *     gives the resolver EXACTLY the true swing velocity: pure rotation about
 *     the pivot at FLIPPER.solverUp. The squeeze of the advancing face plus
 *     this painted velocity launch the ball at 12 px/step (pivot side) to
 *     26 px/step (tip) — verified on a standalone Matter harness
 *     (scripts/flipper-kick-tuning.js).
 *
 * AT REST the placement delta is zero, so the derived velocity is zero and
 * the bat is a plain passive wall (cradle/trap on a held-up flipper works).
 */

import * as Phaser from 'phaser';
import { COLLISION, FLIPPER } from '../config/game.config';
import type { FlipperDef } from '../config/table.config';

/** Minimal typing for Phaser's bundled Matter.Body (velocity-aware setters). */
interface BodyLib {
  setPosition(body: MatterJS.BodyType, position: { x: number; y: number }, updateVelocity?: boolean): void;
  setAngle(body: MatterJS.BodyType, angle: number, updateVelocity?: boolean): void;
  setVelocity(body: MatterJS.BodyType, velocity: { x: number; y: number }): void;
  setAngularVelocity(body: MatterJS.BodyType, velocity: number): void;
}
const MatterBody = (Phaser.Physics.Matter as unknown as { Matter: { Body: BodyLib } }).Matter.Body;

export class Flipper {
  readonly image: Phaser.Physics.Matter.Image;
  /** Soft light pool under the bat — makes the flippers readable at a glance
   *  even on the darkened bottom of the pitch (they used to vanish). */
  private readonly glow: Phaser.GameObjects.Image;
  private angle: number;
  private readonly def: FlipperDef;
  private readonly half: number;
  private readonly dir: 1 | -1;
  private pressed = false;

  constructor(
    private scene: Phaser.Scene,
    def: FlipperDef,
    private onSwing: (flipper: Flipper) => void
  ) {
    this.def = def;
    this.half = FLIPPER.length / 2 - FLIPPER.thickness * 0.55;
    this.dir = def.side === 'left' ? 1 : -1;
    this.angle = def.restAngle;

    const { pivot } = def;
    const cx = pivot.x + this.dir * this.half * Math.cos(def.restAngle);
    const cy = pivot.y + this.dir * this.half * Math.sin(def.restAngle);

    const bodyOpts = {
      restitution: 0.05,
      friction: FLIPPER.friction,
      density: FLIPPER.density,
      frictionAir: 0,
      // STATIC + placed by hand every sub-step: the engine never integrates
      // it (no double-step wobble) and the solver never pushes it. The bat
      // collides with the BALL ONLY — the feed rails pass close to the
      // pivots; without this filter their contacts would add solver noise.
      isStatic: true,
      collisionFilter: { category: COLLISION.flipper, mask: COLLISION.ball },
      label: `flipper-${def.side}`,
    };

    this.image = scene.matter.add.image(cx, cy, 'atlas', 'flipper', bodyOpts);
    this.image.setRectangle(FLIPPER.length, FLIPPER.thickness, bodyOpts);
    if (def.side === 'right') this.image.setFlipX(true);
    // Explicit layering: above playfield art (4), below trail (7) and ball (8).
    this.image.setDepth(6);

    this.glow = scene.add
      .image(cx, cy, 'atlas', 'flipper-glow')
      .setDepth(5)
      .setBlendMode(Phaser.BlendModes.ADD)
      .setAlpha(0.38);
    if (def.side === 'right') this.glow.setFlipX(true);
    this.breathe();
    // Initial placement: at rest (zero velocity, pinned to the pivot).
    this.place(0);
  }

  /** Gentle idle breathing so the flippers read as live hardware. */
  private breathe(): void {
    this.scene.tweens.add({
      targets: this.glow,
      alpha: { from: 0.26, to: 0.55 },
      yoyo: true,
      repeat: -1,
      duration: 950,
      ease: 'Sine.easeInOut',
    });
  }

  press(): void {
    if (!this.pressed) {
      this.pressed = true;
      this.onSwing(this);
      this.scene.tweens.killTweensOf(this.glow);
      this.scene.tweens.add({
        targets: this.glow,
        alpha: 0.95,
        scaleX: 1.18,
        scaleY: 1.18,
        duration: 70,
        ease: 'Quad.easeOut',
      });
    }
  }

  release(): void {
    if (!this.pressed) return;
    this.pressed = false;
    this.scene.tweens.killTweensOf(this.glow);
    this.scene.tweens.add({
      targets: this.glow,
      alpha: 0.38,
      scaleX: 1,
      scaleY: 1,
      duration: 260,
      ease: 'Quad.easeOut',
      onComplete: () => this.breathe(),
    });
  }

  isPressed(): boolean {
    return this.pressed;
  }

  /** Kinematic drive: step the angle and place the body. Call per sub-step.
   *  ALWAYS places — even at rest — so the body is always exactly on its
   *  anchor with exactly the intended velocity. */
  update(): void {
    const target = this.pressed ? this.def.upAngle : this.def.restAngle;
    const rate = this.pressed ? FLIPPER.upRate : FLIPPER.downRate;
    const solver = this.pressed ? FLIPPER.solverUp : FLIPPER.solverDown;
    const diff = target - this.angle;
    const step = Phaser.Math.Clamp(diff, -rate, rate);
    this.angle += step;
    const moving = Math.abs(step) > 1e-6;
    // The painted angular velocity follows the ACTUAL motion direction, so
    // it is correct for both sides (left up-swing = negative, right = positive)
    // and for mid-swing direction changes.
    const omega = moving ? Math.sign(step) * solver : 0;
    this.place(omega);
  }

  /**
   * Place the body (and its glow) around the world pivot.
   *
   * setPosition/setAngle with updateVelocity=true derive the body's velocity
   * from the placement delta (zero at rest — a repeated identical placement
   * yields exactly zero, so the old explicit zeroing is unnecessary). While
   * moving, an additional setVelocity/setAngularVelocity paint overwrites the
   * *resolver-visible* velocity (Matter reads position − positionPrev) with
   * the tuned full swing speed — pure rotation about the pivot.
   */
  private place(solverOmega: number): void {
    const cx = this.def.pivot.x + this.dir * this.half * Math.cos(this.angle);
    const cy = this.def.pivot.y + this.dir * this.half * Math.sin(this.angle);
    const a = this.angle;

    const body = this.image.body as MatterJS.BodyType | null;
    if (body) {
      MatterBody.setPosition(body, { x: cx, y: cy }, true);
      MatterBody.setAngle(body, a, true);
      if (solverOmega !== 0) {
        // v of the body centre under pure rotation about the pivot:
        // v = ω × r, i.e. dir·half·ω·(−sin a, cos a).
        MatterBody.setVelocity(body, {
          x: this.half * solverOmega * this.dir * -Math.sin(a),
          y: this.half * solverOmega * this.dir * Math.cos(a),
        });
        MatterBody.setAngularVelocity(body, solverOmega);
      }
    }

    // Sync the display objects (no-op for the body: already at cx/cy/angle).
    this.image.setPosition(cx, cy);
    this.image.setAngle(Phaser.Math.RadToDeg(a));
    this.glow.setPosition(cx, cy);
    this.glow.setRotation(a);
  }
}
