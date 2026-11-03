import { TILE } from '../config';
import type { TilePos } from '../levels/types';

const LINE_TIME = 1.8;
const FIRST_LINE = 0.25;
/** How long the last radio line stays up before the intro may end. */
const LAST_LINE_HOLD = 1.3;
/** How long the letterbox bars take to come in and go out. */
const BAR_TIME = 0.4;
/** Camera zoom relative to normal at the start of the walk. */
const START_ZOOM = 0.65;
/** The operator walks briskly to the entry, faster than a normal walk. */
export const INTRO_PACE = 1.45;

/**
 * The short cutscene at the start of a level: letterbox bars, the camera pulled back, the
 * operator walking from the drop-off to the entry while radio lines play. Skippable.
 */
export class Intro {
  /** True while the cutscene runs; false once the operator has control. */
  active = true;
  private time = 0;
  private outTime = -1;
  private waypoint = 1;
  private points: { x: number; y: number }[];

  constructor(approach: readonly TilePos[], private lines: string[]) {
    this.points = approach.map((p) => ({ x: p.tx * TILE, y: p.ty * TILE }));
  }

  get start(): { x: number; y: number } {
    return this.points[0];
  }

  /** Where the operator should face at the end: along the last stretch of the approach. */
  get finalFacing(): number {
    const a = this.points[this.points.length - 2] ?? this.points[0];
    const b = this.points[this.points.length - 1];
    return Math.atan2(b.y - a.y, b.x - a.x);
  }

  get walkDone(): boolean {
    return this.waypoint >= this.points.length;
  }

  private get linesDone(): boolean {
    return this.time >= FIRST_LINE + (this.lines.length - 1) * LINE_TIME + LAST_LINE_HOLD;
  }

  /** The radio line currently on screen, if any. */
  get subtitle(): string | null {
    if (this.outTime >= 0) return null;
    const i = Math.min(this.lines.length - 1, Math.floor((this.time - FIRST_LINE) / LINE_TIME));
    return i >= 0 ? this.lines[i] : null;
  }

  /** 0..1, how far the letterbox bars are in. */
  get bars(): number {
    if (this.outTime >= 0) return Math.max(0, 1 - this.outTime / BAR_TIME);
    return Math.min(1, this.time / BAR_TIME);
  }

  /** Camera zoom multiplier: pulled back at first, easing in to normal as the walk ends. */
  get zoom(): number {
    if (!this.active) return 1;
    const k = Math.min(1, (this.waypoint - 1 + this.segmentProgress) / Math.max(1, this.points.length - 1));
    const eased = k * k * (3 - 2 * k);
    return START_ZOOM + (1 - START_ZOOM) * eased;
  }

  private segmentProgress = 0;

  /**
   * Steers the operator. Returns the movement input to apply this frame (zero once arrived).
   */
  update(dt: number, x: number, y: number): { moveX: number; moveY: number } {
    this.time += dt;
    if (this.outTime >= 0) {
      this.outTime += dt;
      if (this.outTime >= BAR_TIME) this.active = false;
      return { moveX: 0, moveY: 0 };
    }
    if (this.walkDone && this.linesDone) {
      this.outTime = 0;
      return { moveX: 0, moveY: 0 };
    }
    if (this.walkDone) return { moveX: 0, moveY: 0 };

    const target = this.points[this.waypoint];
    const prev = this.points[this.waypoint - 1];
    const dx = target.x - x, dy = target.y - y, d = Math.hypot(dx, dy);
    const seg = Math.hypot(target.x - prev.x, target.y - prev.y) || 1;
    this.segmentProgress = 1 - Math.min(1, d / seg);
    if (d < 6) {
      this.waypoint++;
      this.segmentProgress = 0;
      return { moveX: 0, moveY: 0 };
    }
    return { moveX: dx / d, moveY: dy / d };
  }

  /** Jumps to the end: the operator is placed at the entry and control returns. */
  skip(): { x: number; y: number } {
    this.waypoint = this.points.length;
    this.outTime = 0;
    return this.points[this.points.length - 1];
  }
}
