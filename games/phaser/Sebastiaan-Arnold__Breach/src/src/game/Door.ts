import Phaser from 'phaser';
import { COLORS, NOISE, TILE } from '../config';
import { DEG, type Segment } from '../core/geometry';
import type { DoorSpec } from '../core/grid';

export type DoorState = 'closed' | 'open';

const PASSABLE_ANGLE = 70 * DEG;
const OPEN_SPEED = 2.2;
const CLOSE_SPEED = 2.6;

/**
 * A door is a leaf pivoting on a hinge at one side of its tile. Its leaf is a real line segment
 * in the line-of-sight system, so the room behind it opens up gradually as it swings.
 */
export class Door {
  readonly tx: number;
  readonly ty: number;
  readonly hingeX: number;
  readonly hingeY: number;
  readonly closedAngle: number;
  readonly cx: number;
  readonly cy: number;
  state: DoorState = 'closed';

  private angle: number;
  private targetAngle: number;
  private speed = 0;
  private swingDir = 1;
  private gfx: Phaser.GameObjects.Graphics;
  private dirty = true;

  constructor(scene: Phaser.Scene, readonly spec: DoorSpec, depth: number) {
    this.tx = spec.tx;
    this.ty = spec.ty;
    this.cx = spec.tx * TILE + TILE / 2;
    this.cy = spec.ty * TILE + TILE / 2;
    if (spec.orientation === 'h') {
      this.hingeX = spec.tx * TILE;
      this.hingeY = this.cy;
      this.closedAngle = 0;
    } else {
      this.hingeX = this.cx;
      this.hingeY = spec.ty * TILE;
      this.closedAngle = 90 * DEG;
    }
    this.angle = this.targetAngle = this.closedAngle;
    this.gfx = scene.add.graphics().setDepth(depth);
  }

  get blocksMovement(): boolean {
    return Math.abs(this.angle - this.closedAngle) < PASSABLE_ANGLE;
  }

  segment(): Segment {
    return {
      ax: this.hingeX,
      ay: this.hingeY,
      bx: this.hingeX + Math.cos(this.angle) * TILE,
      by: this.hingeY + Math.sin(this.angle) * TILE,
    };
  }

  /** Opens or closes the door for someone standing at (fromX, fromY). Returns the noise radius. */
  toggle(fromX: number, fromY: number): number {
    if (this.state === 'closed') {
      // Doors swing away from whoever opens them.
      if (this.spec.orientation === 'h') this.swingDir = fromY < this.cy ? 1 : -1;
      else this.swingDir = fromX < this.cx ? -1 : 1;
      this.state = 'open';
      this.targetAngle = this.closedAngle + this.swingDir * 90 * DEG;
      this.speed = OPEN_SPEED;
      return NOISE.doorOpen;
    }
    this.state = 'closed';
    this.targetAngle = this.closedAngle;
    this.speed = CLOSE_SPEED;
    return NOISE.doorClose;
  }

  update(dt: number): void {
    if (this.angle !== this.targetAngle) {
      const diff = this.targetAngle - this.angle;
      const step = this.speed * dt;
      this.angle = Math.abs(diff) <= step ? this.targetAngle : this.angle + Math.sign(diff) * step;
      this.dirty = true;
    }
    if (this.dirty) this.draw();
  }

  private draw(): void {
    this.dirty = false;
    const g = this.gfx;
    const s = this.segment();
    const dx = (s.bx - s.ax) / TILE, dy = (s.by - s.ay) / TILE;
    g.clear();
    g.lineStyle(6, 0x000000, 0.3);
    g.lineBetween(s.ax + 1.5, s.ay + 2.5, s.bx + 1.5, s.by + 2.5);
    g.lineStyle(6, COLORS.door, 1);
    g.lineBetween(s.ax, s.ay, s.bx, s.by);
    g.lineStyle(1, COLORS.doorEdge, 0.9);
    g.lineBetween(s.ax + dx * 3, s.ay + dy * 3, s.bx - dx * 3, s.by - dy * 3);
    // Hinge and handle.
    g.fillStyle(0x3f3f46, 1);
    g.fillCircle(s.ax, s.ay, 3);
    g.fillStyle(0xd4d4d8, 1);
    g.fillCircle(s.bx - dx * 5, s.by - dy * 5, 1.8);
  }
}
