import {
  WIDTH, LENGTH, HALF, CORNER_RADIUS, GOAL_LEFT, GOAL_RIGHT,
  PUCK_RADIUS, MALLET_RADIUS, cornerCentre,
} from '../src/table.js';

const EPS = 1e-9;

/** True if the puck centre is in a legal place: on the table or inside a goal mouth. */
export function puckOnTable(p) {
  const r = PUCK_RADIUS;
  const inMouthX = p.x > GOAL_LEFT && p.x < GOAL_RIGHT;
  if (inMouthX && (p.y < r || p.y > LENGTH - r)) {
    const s = p.y < HALF ? p.y : LENGTH - p.y;
    if (s < -r) return false;
    if (s <= 0) return p.x >= GOAL_LEFT + r - EPS && p.x <= GOAL_RIGHT - r + EPS;
    return Math.hypot(p.x - GOAL_LEFT, s) >= r - EPS && Math.hypot(p.x - GOAL_RIGHT, s) >= r - EPS;
  }
  if (p.x < r - EPS || p.x > WIDTH - r + EPS || p.y < r - EPS || p.y > LENGTH - r + EPS) return false;
  const c = cornerCentre(p.x, p.y);
  return !c || Math.hypot(p.x - c.x, p.y - c.y) <= CORNER_RADIUS - r + EPS;
}

/** True if a mallet centre keeps the whole mallet in its half and on the table. */
export function malletInHalf(m, side) {
  const r = MALLET_RADIUS;
  const minY = side === 1 ? r : HALF + r;
  const maxY = side === 1 ? HALF - r : LENGTH - r;
  if (m.x < r - EPS || m.x > WIDTH - r + EPS || m.y < minY - EPS || m.y > maxY + EPS) return false;
  const c = cornerCentre(m.x, m.y);
  return !c || Math.hypot(m.x - c.x, m.y - c.y) <= CORNER_RADIUS - r + EPS;
}

/** Angle in radians between two vectors. */
export function angleBetween(ax, ay, bx, by) {
  const d = (ax * bx + ay * by) / (Math.hypot(ax, ay) * Math.hypot(bx, by));
  return Math.acos(Math.max(-1, Math.min(1, d)));
}
