import {
  WIDTH, LENGTH, CORNER_RADIUS, GOAL_LEFT, GOAL_RIGHT,
  PUCK_RADIUS, MALLET_RADIUS, clampMallet, cornerCentre,
} from './table.js';

/** Fixed physics time step in seconds. */
export const STEP = 1 / 120;
export const MAX_PUCK_SPEED = 3.6;
export const FRICTION = 0.3;
export const WALL_RESTITUTION = 0.9;
export const MALLET_RESTITUTION = 0.9;
export const HIT_RADIUS = PUCK_RADIUS + MALLET_RADIUS;

/**
 * @typedef {{x: number, y: number, vx: number, vy: number}} Puck
 * @typedef {{x: number, y: number, px: number, py: number, vx: number, vy: number}} Mallet
 *   px/py hold the position at the start of the current step.
 * @typedef {{type: 'wall' | 'post' | 'hit', speed: number}} PhysicsEvent
 */

/**
 * Limits a body's speed to `max` without changing its direction.
 * @param {{vx: number, vy: number}} body
 * @param {number} [max]
 */
export function capSpeed(body, max = MAX_PUCK_SPEED) {
  const s = Math.hypot(body.vx, body.vy);
  if (s > max) {
    body.vx *= max / s;
    body.vy *= max / s;
  }
}

/**
 * Applies light exponential air-table friction for `dt` seconds.
 * @param {Puck} puck
 * @param {number} dt
 */
export function applyFriction(puck, dt) {
  const k = Math.exp(-FRICTION * dt);
  puck.vx *= k;
  puck.vy *= k;
}

/**
 * Reflects the velocity about the inward normal (nx, ny) when the puck moves
 * into the surface, keeping the angle and scaling the speed by `e`.
 */
function bounce(puck, nx, ny, e) {
  const dot = puck.vx * nx + puck.vy * ny;
  if (dot >= 0) return;
  puck.vx = (puck.vx - 2 * dot * nx) * e;
  puck.vy = (puck.vy - 2 * dot * ny) * e;
}

/** Reflects the puck off the corner arc around centre c; true if it hit. */
function collideCorner(puck, c) {
  const dx = puck.x - c.x;
  const dy = puck.y - c.y;
  const d = Math.hypot(dx, dy);
  const rho = CORNER_RADIUS - PUCK_RADIUS;
  if (d <= rho) return false;
  const nx = dx / d;
  const ny = dy / d;
  const inside = Math.max(0, 2 * rho - d);
  puck.x = c.x + nx * inside;
  puck.y = c.y + ny * inside;
  bounce(puck, -nx, -ny, WALL_RESTITUTION);
  return true;
}

/**
 * Bounces the puck off a goal post (a point at (postX, lineY)). The puck is
 * traced back along its path to the exact contact point, so the bounce uses
 * the true contact normal; it then travels the backed-up distance along the
 * reflected direction. Works in (x, s) where s is the depth into the table.
 */
function collidePost(puck, postX, lineY, dir) {
  const r = PUCK_RADIUS;
  const qx = puck.x - postX;
  const qs = (puck.y - lineY) * dir;
  const speed = Math.hypot(puck.vx, puck.vy);
  const ux = speed > 1e-9 ? puck.vx / speed : 0;
  const us = speed > 1e-9 ? (puck.vy * dir) / speed : 0;
  const qu = qx * ux + qs * us;
  // Moving away already (pushed in by a mallet): just push out radially.
  const back = qu > 0 ? 0 : qu + Math.sqrt(Math.max(0, qu * qu - (qx * qx + qs * qs) + r * r));
  const cx = qx - ux * back;
  const cs = qs - us * back;
  const cl = Math.hypot(cx, cs) || 1;
  const nx = cx / cl;
  const ns = cs / cl;
  bounce(puck, nx, ns * dir, WALL_RESTITUTION);
  const after = Math.hypot(puck.vx, puck.vy);
  const ox = after > 1e-9 ? puck.vx / after : nx;
  const os = after > 1e-9 ? (puck.vy * dir) / after : ns;
  puck.x = postX + nx * r + ox * back;
  puck.y = lineY + (ns * r + os * back) * dir;
}

/**
 * Handles one goal mouth: the posts while the puck overlaps the goal line and
 * the pocket side walls once its centre is past the line.
 * @param {Puck} puck
 * @param {1 | -1} dir 1 for the top goal (y = 0), -1 for the bottom goal.
 * @returns {'wall' | 'post' | null}
 */
function collideMouth(puck, dir) {
  const r = PUCK_RADIUS;
  const lineY = dir === 1 ? 0 : LENGTH;
  const s = (puck.y - lineY) * dir; // depth into the table
  if (s >= r) return null;
  if (s > 0) {
    for (const postX of [GOAL_LEFT, GOAL_RIGHT]) {
      if (Math.hypot(puck.x - postX, s) < r) {
        collidePost(puck, postX, lineY, dir);
        return 'post';
      }
    }
    return null;
  }
  if (puck.x < GOAL_LEFT + r) {
    puck.x = 2 * (GOAL_LEFT + r) - puck.x;
    bounce(puck, 1, 0, WALL_RESTITUTION);
    return 'wall';
  }
  if (puck.x > GOAL_RIGHT - r) {
    puck.x = 2 * (GOAL_RIGHT - r) - puck.x;
    bounce(puck, -1, 0, WALL_RESTITUTION);
    return 'wall';
  }
  return null;
}

/**
 * Resolves collisions of the puck with the rim: straight walls, rounded
 * corners, goal posts and goal pocket walls. Positions are mirrored back into
 * the table and the velocity is reflected with WALL_RESTITUTION.
 * @param {Puck} puck
 * @returns {'wall' | 'post' | null} What was hit, if anything.
 */
export function collideWalls(puck) {
  const r = PUCK_RADIUS;
  const c = cornerCentre(puck.x, puck.y);
  if (c) return collideCorner(puck, c) ? 'wall' : null;
  let hit = null;
  if (puck.x < r) {
    puck.x = 2 * r - puck.x;
    bounce(puck, 1, 0, WALL_RESTITUTION);
    hit = 'wall';
  } else if (puck.x > WIDTH - r) {
    puck.x = 2 * (WIDTH - r) - puck.x;
    bounce(puck, -1, 0, WALL_RESTITUTION);
    hit = 'wall';
  }
  if (puck.x > GOAL_LEFT && puck.x < GOAL_RIGHT) {
    return collideMouth(puck, 1) || collideMouth(puck, -1) || hit;
  }
  if (puck.y < r) {
    puck.y = 2 * r - puck.y;
    bounce(puck, 0, 1, WALL_RESTITUTION);
    hit = 'wall';
  } else if (puck.y > LENGTH - r) {
    puck.y = 2 * (LENGTH - r) - puck.y;
    bounce(puck, 0, -1, WALL_RESTITUTION);
    hit = 'wall';
  }
  return hit;
}

/**
 * Returns which player scored: 0 when the whole puck is past the top goal
 * line, 1 when it is past the bottom goal line, otherwise null. The pocket
 * walls keep a puck that is past the line between the posts.
 * @param {Puck} puck
 * @returns {0 | 1 | null}
 */
export function goalScorer(puck) {
  if (puck.y < -PUCK_RADIUS) return 0;
  if (puck.y > LENGTH + PUCK_RADIUS) return 1;
  return null;
}

/**
 * Earliest fraction t in [0, 1] of a step at which two circles whose centre
 * offset is (qx, qy) + t * (dx, dy) touch (distance = radius). Returns 0 when
 * they already overlap and null when they do not meet during the step.
 * @param {number} qx
 * @param {number} qy
 * @param {number} dx
 * @param {number} dy
 * @param {number} radius
 * @returns {number | null}
 */
export function sweptHitTime(qx, qy, dx, dy, radius) {
  const c = qx * qx + qy * qy - radius * radius;
  if (c <= 0) return 0;
  const b = qx * dx + qy * dy;
  if (b >= 0) return null;
  const a = dx * dx + dy * dy;
  const disc = b * b - a * c;
  if (disc < 0) return null;
  const t = (-b - Math.sqrt(disc)) / a;
  return t <= 1 ? t : null;
}

/** Pushes the puck out of the mallet's end position if they overlap. */
function separate(puck, m, nx, ny) {
  const dx = puck.x - m.x;
  const dy = puck.y - m.y;
  const d = Math.hypot(dx, dy);
  if (d >= HIT_RADIUS) return;
  const ux = d > 1e-9 ? dx / d : nx;
  const uy = d > 1e-9 ? dy / d : ny;
  puck.x = m.x + ux * HIT_RADIUS;
  puck.y = m.y + uy * HIT_RADIUS;
}

/**
 * Swept puck-mallet collision for one step. The mallet is treated as
 * infinitely heavy: the puck's velocity relative to the mallet is reflected
 * about the contact normal. On contact the puck is moved to its end-of-step
 * position and the relative normal speed (>= 0) is returned; otherwise -1.
 */
function hitMallet(puck, m, dt) {
  const mdx = m.x - m.px;
  const mdy = m.y - m.py;
  const t = sweptHitTime(puck.x - m.px, puck.y - m.py,
    puck.vx * dt - mdx, puck.vy * dt - mdy, HIT_RADIUS);
  if (t === null) return -1;
  const cx = puck.x + puck.vx * dt * t;
  const cy = puck.y + puck.vy * dt * t;
  let nx = cx - (m.px + mdx * t);
  let ny = cy - (m.py + mdy * t);
  const nd = Math.hypot(nx, ny) || 1;
  nx /= nd;
  ny /= nd;
  const mvx = mdx / dt;
  const mvy = mdy / dt;
  const rvx = puck.vx - mvx;
  const rvy = puck.vy - mvy;
  const vn = rvx * nx + rvy * ny;
  if (vn < 0) {
    puck.vx = mvx + rvx - (1 + MALLET_RESTITUTION) * vn * nx;
    puck.vy = mvy + rvy - (1 + MALLET_RESTITUTION) * vn * ny;
    capSpeed(puck);
  }
  puck.x = cx + puck.vx * dt * (1 - t);
  puck.y = cy + puck.vy * dt * (1 - t);
  separate(puck, m, nx, ny);
  return Math.max(0, -vn);
}

/**
 * Moves a mallet toward a target with a speed limit, keeping it in its half
 * and inside the table. Its velocity is derived from the movement.
 * @param {Mallet} m
 * @param {number} tx Target x.
 * @param {number} ty Target y.
 * @param {number} maxSpeed Units per second.
 * @param {0 | 1} side
 * @param {number} dt
 */
export function moveMallet(m, tx, ty, maxSpeed, side, dt) {
  const t = clampMallet(tx, ty, side);
  m.px = m.x;
  m.py = m.y;
  let dx = t.x - m.x;
  let dy = t.y - m.y;
  const d = Math.hypot(dx, dy);
  const maxD = maxSpeed * dt;
  if (d > maxD) {
    dx *= maxD / d;
    dy *= maxD / d;
  }
  const p = clampMallet(m.x + dx, m.y + dy, side);
  m.x = p.x;
  m.y = p.y;
  m.vx = (m.x - m.px) / dt;
  m.vy = (m.y - m.py) / dt;
}

/**
 * Creates a mallet at rest at (x, y).
 * @param {number} x
 * @param {number} y
 * @returns {Mallet}
 */
export function createMallet(x, y) {
  return { x, y, px: x, py: y, vx: 0, vy: 0 };
}

/**
 * Advances the puck by one step against mallets that have already been moved
 * this step: friction, speed cap, swept mallet hits and rim collisions.
 * @param {Puck} puck
 * @param {Mallet[]} mallets Mallets whose px/py hold their start positions.
 * @param {number} dt
 * @returns {PhysicsEvent[]}
 */
export function stepPuck(puck, mallets, dt) {
  const events = [];
  applyFriction(puck, dt);
  capSpeed(puck);
  let contact = false;
  for (const m of mallets) {
    const speed = hitMallet(puck, m, dt);
    if (speed < 0) continue;
    contact = true;
    if (speed > 0) events.push({ type: 'hit', speed });
    break;
  }
  if (!contact) {
    puck.x += puck.vx * dt;
    puck.y += puck.vy * dt;
  }
  const wall = collideWalls(puck);
  if (wall) events.push({ type: wall, speed: Math.hypot(puck.vx, puck.vy) });
  return events;
}
