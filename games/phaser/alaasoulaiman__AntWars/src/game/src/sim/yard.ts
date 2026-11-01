// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The Yard's fixed ground as plain data: the spawn holes and the three rocks, and the steering that takes a walker
// round a rock instead of into it. The collision itself is Phaser's (static circles); this is what walkers aim at.
import { SOFT_EDGE, WORLD_H, WORLD_W } from '../game/tuning';

export interface Point {
  x: number;
  y: number;
}
export interface Circle extends Point {
  r: number;
}

/** The nest sits in the middle of the Yard. */
export const NEST_AT: Readonly<Point> = { x: WORLD_W / 2, y: WORLD_H / 2 };

/**
 * Three rocks that block the ant and every walker (wasps fly over them, CONCEPT_V2 section 5). Placed away from the
 * nest so a loop round the nest stays open, away from the holes and the edge band, so each makes a loop of its own.
 */
export const ROCKS: ReadonlyArray<Circle> = [
  { x: 390, y: 640, r: 70 },
  { x: 1150, y: 1560, r: 80 },
  { x: 500, y: 1820, r: 64 },
];

/** Twelve spawn holes in the edge band: three on each long side's ends and three down each side. */
export function spawnHoles(): Point[] {
  const m = SOFT_EDGE * 0.62;
  const out: Point[] = [];
  for (const x of [WORLD_W * 0.18, WORLD_W * 0.5, WORLD_W * 0.82]) out.push({ x, y: m }, { x, y: WORLD_H - m });
  for (const y of [WORLD_H * 0.2, WORLD_H * 0.5, WORLD_H * 0.8]) out.push({ x: m, y }, { x: WORLD_W - m, y });
  return out;
}

/** Room a walker keeps from a rock's edge when it steers round it. */
export const STEER_MARGIN = 6;

/** True when a body of radius r at (x, y) touches a rock (within 2 units of its edge). */
export function rockContact(x: number, y: number, r: number, rocks: ReadonlyArray<Circle> = ROCKS): boolean {
  return rockTouching(x, y, r, rocks) !== null;
}

/** The rock a body of radius r at (x, y) touches (within 2 units of its edge), or null. */
export function rockTouching(x: number, y: number, r: number, rocks: ReadonlyArray<Circle> = ROCKS): Circle | null {
  for (const c of rocks) if (Math.hypot(x - c.x, y - c.y) <= c.r + r + 2) return c;
  return null;
}

/**
 * VG3: a spider strafing in its web band can press into a rock and park there. A walker that touches a rock and moves
 * slower than STALL_SPEED for STALL_SECONDS gets a sidestep of SIDESTEP_SECONDS along the rock's edge.
 */
export const STALL_SECONDS = 2;
export const STALL_SPEED = 15;
export const SIDESTEP_SECONDS = 1;

export interface Stall {
  /** Seconds pressed on a rock while barely moving. */
  stalledFor: number;
  /** Seconds of sidestep still to run. */
  sidestepLeft: number;
}

/** One frame of the stall watch: sidestep is true on every frame of a sidestep, started only on its first. */
export function stallStep(s: Readonly<Stall>, onRock: boolean, speed: number, dt: number): Stall & { sidestep: boolean; started: boolean } {
  if (s.sidestepLeft > 0) return { stalledFor: 0, sidestepLeft: Math.max(0, s.sidestepLeft - dt), sidestep: true, started: false };
  if (!onRock || speed >= STALL_SPEED) return { stalledFor: 0, sidestepLeft: 0, sidestep: false, started: false };
  const stalledFor = s.stalledFor + dt;
  if (stalledFor >= STALL_SECONDS) return { stalledFor: 0, sidestepLeft: SIDESTEP_SECONDS, sidestep: true, started: true };
  return { stalledFor, sidestepLeft: 0, sidestep: false, started: false };
}

/** The sidestep's heading: along the rock's edge at the walker's spot, one way round or the other by sign. */
export function sidestepHeading(px: number, py: number, rock: Readonly<Circle>, sign: number): Point {
  const nx = px - rock.x;
  const ny = py - rock.y;
  const d = Math.hypot(nx, ny) || 1;
  const k = sign < 0 ? -1 : 1;
  return { x: (-ny / d) * k, y: (nx / d) * k };
}

/**
 * The way a walker of radius r at (px, py) heads for (tx, ty): straight when no rock blocks the line, otherwise along
 * the tangent of the nearest blocking rock on the side the line already passes (dead centre goes one fixed way).
 * Pressed against a rock it slides along it. A unit vector, or 0, 0 when it already stands on the target.
 */
export function steerAround(px: number, py: number, tx: number, ty: number, r: number, rocks: ReadonlyArray<Circle> = ROCKS): Point {
  const dx = tx - px;
  const dy = ty - py;
  const dist = Math.hypot(dx, dy);
  if (dist < 1e-6) return { x: 0, y: 0 };
  const ux = dx / dist;
  const uy = dy / dist;
  let block: Circle | null = null;
  let blockAlong = Infinity;
  for (const c of rocks) {
    const cx = c.x - px;
    const cy = c.y - py;
    const along = cx * ux + cy * uy;
    if (along <= 0 || along - c.r > dist) continue;
    const off = Math.abs(ux * cy - uy * cx);
    if (off < c.r + r + STEER_MARGIN && along < blockAlong) {
      block = c;
      blockAlong = along;
    }
  }
  if (!block) return { x: ux, y: uy };
  const cx = block.x - px;
  const cy = block.y - py;
  const d = Math.hypot(cx, cy);
  const clear = block.r + r + STEER_MARGIN;
  const half = Math.asin(Math.min(1, clear / Math.max(d, 1e-6)));
  const toward = Math.atan2(cy, cx);
  // The rock sits to the left of the line when the cross product is positive: pass it on the right, and the reverse.
  const left = ux * cy - uy * cx > 0;
  const ang = left ? toward - half : toward + half;
  return { x: Math.cos(ang), y: Math.sin(ang) };
}
