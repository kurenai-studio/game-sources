import Phaser from 'phaser';
import { COLORS } from '../config';
import { rayCircle } from '../core/geometry';
import type { StationId } from '../levels/academy/range';

export type TargetKind = 'suspect' | 'civilian';
export type TargetState = 'hidden' | 'up' | 'down';

export interface TargetOpts {
  kind: TargetKind;
  x: number;
  y: number;
  station: StationId;
  /** Lies flat until the operator first sees it, then springs up. */
  popup: boolean;
  /** Seconds before a downed target stands back up; 0 means it stays down. */
  respawn: number;
  rail?: { x0: number; x1: number; speed: number };
}

const RADIUS = 11;
const RAIL_TICK = 0.55;

/** A cardboard target on the Range. Real enemies will share its visibility and hit rules. */
export class Target {
  /** Cardboard props never bleed; people (enemies and civilians, from the first mission) do. */
  readonly prop: boolean = true;
  readonly kind: TargetKind;
  readonly station: StationId;
  state: TargetState;
  x: number;
  y: number;
  /** Civilian targets remember being hit so the debrief can count them. */
  wasHit = false;

  private container: Phaser.GameObjects.Container;
  private gfx: Phaser.GameObjects.Graphics;
  private popTimer = -1;
  private downTimer = 0;
  private railDir = 1;
  private railTimer = 0;
  private seen = false;

  constructor(private scene: Phaser.Scene, private opts: TargetOpts, depth: number) {
    this.kind = opts.kind;
    this.station = opts.station;
    this.x = opts.x;
    this.y = opts.y;
    this.state = opts.popup ? 'hidden' : 'up';
    this.gfx = scene.add.graphics();
    this.container = scene.add.container(this.x, this.y, [this.gfx]).setDepth(depth).setVisible(false);
    this.redraw();
  }

  get alive(): boolean {
    return this.state !== 'down';
  }

  /** Distance along a ray to this target, or Infinity. Only standing targets can be hit. */
  hitTest(ox: number, oy: number, dx: number, dy: number): number {
    if (this.state !== 'up') return Infinity;
    return rayCircle(ox, oy, dx, dy, this.x, this.y, RADIUS);
  }

  /** Cardboard goes down to any hit. Returns true if this hit took it down. */
  hit(): boolean {
    if (this.state !== 'up') return false;
    this.state = 'down';
    this.wasHit = true;
    this.downTimer = this.opts.respawn;
    this.redraw();
    this.scene.tweens.add({ targets: this.container, scale: 0.8, duration: 160, ease: 'Quad.Out' });
    return true;
  }

  /**
   * @param visible whether the operator can currently see this spot
   * @returns true when the rail target made a noise this frame
   */
  update(dt: number, visible: boolean, px: number, py: number): boolean {
    this.container.setVisible(visible);
    // Targets are set up facing the shooter: turn towards the operator the first time they're seen.
    if (visible && !this.seen) {
      this.seen = true;
      this.container.rotation = Math.atan2(py - this.y, px - this.x);
    }
    let noisy = false;

    if (this.state === 'hidden') {
      if (visible && this.popTimer < 0) this.popTimer = 0.22;
      if (this.popTimer >= 0 && (this.popTimer -= dt) <= 0) {
        this.state = 'up';
        this.container.rotation = Math.atan2(py - this.y, px - this.x);
        this.redraw();
        this.container.setScale(0.35);
        this.scene.tweens.add({ targets: this.container, scale: 1, duration: 180, ease: 'Back.Out' });
      }
    } else if (this.state === 'down' && this.opts.respawn > 0) {
      if ((this.downTimer -= dt) <= 0) {
        this.state = 'up';
        this.redraw();
        this.container.setScale(0.35);
        this.scene.tweens.add({ targets: this.container, scale: 1, duration: 180, ease: 'Back.Out' });
      }
    }

    const rail = this.opts.rail;
    if (rail && this.state !== 'down') {
      this.x += this.railDir * rail.speed * dt;
      if (this.x > rail.x1 || this.x < rail.x0) {
        this.x = Phaser.Math.Clamp(this.x, rail.x0, rail.x1);
        this.railDir *= -1;
      }
      if ((this.railTimer -= dt) <= 0) {
        this.railTimer = RAIL_TICK;
        noisy = true;
      }
      this.container.x = this.x;
      if (this.state === 'up') this.container.rotation = Math.atan2(py - this.y, px - this.x);
    }
    return noisy;
  }

  private redraw(): void {
    const g = this.gfx;
    const color = this.kind === 'suspect' ? COLORS.suspect : COLORS.civilian;
    g.clear();
    if (this.state === 'hidden') {
      // Lying flat, face down: just the back of the cardboard.
      g.fillStyle(0x000000, 0.25);
      g.fillRect(-12, -1, 26, 7);
      g.fillStyle(COLORS.cardboard, 0.95);
      g.fillRect(-13, -3, 26, 6);
      g.fillStyle(0x7a5f37, 0.8);
      g.fillRect(-13, -3, 26, 1);
      return;
    }
    const down = this.state === 'down';
    const a = down ? 0.45 : 1;
    if (!down) {
      g.fillStyle(0x000000, 0.28);
      g.fillEllipse(1.5, 2.5, 20, 28);
    }
    // A printed figure on cardboard, cut out along its outline.
    if (this.kind === 'suspect') {
      g.lineStyle(4, 0x7f1d1d, a);
      g.lineBetween(0, -8, 11, -2);
      g.fillStyle(0x111111, a);
      g.fillRect(8.5, -4.5, 11, 4.5);
      g.fillStyle(0x6b7280, a);
      g.fillRect(9, -4, 10, 3.5);
    } else {
      // Hands up.
      g.fillStyle(0xe7c9a0, a);
      g.fillCircle(3, -12, 2.6);
      g.fillCircle(3, 12, 2.6);
    }
    g.fillStyle(COLORS.cardboard, a);
    g.fillEllipse(0, 0, 17, 27);
    g.fillStyle(color, a);
    g.fillEllipse(0, 0, 13, 23);
    g.fillStyle(0x000000, 0.18 * a);
    g.fillEllipse(-2, 0, 7, 19);
    g.fillStyle(this.kind === 'suspect' ? 0x2b2b2b : 0x8b5e3c, a);
    g.fillCircle(1, 0, 5.5);
    g.fillStyle(0xffffff, 0.15 * a);
    g.fillCircle(0, -1.5, 2.4);
    if (down && this.kind === 'civilian') {
      g.lineStyle(3, COLORS.suspect, 0.9);
      g.lineBetween(-8, -8, 8, 8);
      g.lineBetween(-8, 8, 8, -8);
    }
  }
}
