// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Where a dart starts and what it touches at point blank, as plain functions. VG3 found darts that started 22 units
// out and moved about 16 more before their first overlap test, so a predator sitting on the ant could never be hit.

export interface Disc {
  x: number;
  y: number;
  r: number;
}

/** A dart leaves from the ant's centre; side by side darts (Twin Stinger, Front Fang) sit `side` units across the aim. */
export function dartOrigin(antX: number, antY: number, ang: number, side: number): { x: number; y: number } {
  return { x: antX - Math.sin(ang) * side, y: antY + Math.cos(ang) * side };
}

/**
 * The first disc a dart of radius dartR touches while it moves `reach` units from (x, y) along the unit vector
 * (ux, uy): its index, the nearest along the path first, or -1 for none. A disc the dart starts inside counts at once.
 * The Yard runs this at launch over the dart's first step, so nothing between the ant and that step is skipped.
 */
export function firstTouched(x: number, y: number, ux: number, uy: number, reach: number, dartR: number, discs: ReadonlyArray<Disc>): number {
  let best = -1;
  let bestAt = Infinity;
  for (let i = 0; i < discs.length; i++) {
    const c = discs[i];
    const R = c.r + dartR;
    const cx = c.x - x;
    const cy = c.y - y;
    const along = cx * ux + cy * uy;
    const off2 = cx * cx + cy * cy - along * along;
    if (off2 > R * R) continue;
    const half = Math.sqrt(R * R - off2);
    const enter = along - half;
    const leave = along + half;
    if (leave < 0 || enter > reach) continue;
    const at = Math.max(0, enter);
    if (at < bestAt) {
      bestAt = at;
      best = i;
    }
  }
  return best;
}

/** The rectangle of the Yard the camera shows (Phaser's worldView). */
export interface ViewRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

/**
 * Design note, 2026-10-24: the ant shoots only what the player can see. A predator (a disc of radius r) counts as
 * on screen the moment any part of it is inside the camera's view; aim, echoes, hops, sparks and dart hits read this.
 */
export function inView(x: number, y: number, r: number, view: Readonly<ViewRect>): boolean {
  return x + r >= view.x && x - r <= view.x + view.width && y + r >= view.y && y - r <= view.y + view.height;
}

/** Design note, 2026-10-24: hits landing on one target within this long of the last show one number, the total. */
export const HIT_GROUP_MS = 500;

export interface HitGroup {
  total: number;
  /** When the group's last hit landed, in milliseconds. */
  lastAt: number;
}

/** A hit joins its target's group when it lands within the window of the group's last hit; otherwise it starts a new one. */
export function groupHit(group: Readonly<HitGroup> | null, amount: number, now: number): { group: HitGroup; joined: boolean } {
  if (group !== null && now - group.lastAt <= HIT_GROUP_MS) return { group: { total: group.total + amount, lastAt: now }, joined: true };
  return { group: { total: amount, lastAt: now }, joined: false };
}
