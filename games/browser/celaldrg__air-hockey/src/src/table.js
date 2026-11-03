// Table geometry in table units. The table is portrait: x runs 0..WIDTH from
// left to right, y runs 0..LENGTH from top to bottom. Player 0 sits at the
// bottom and defends the goal on y = LENGTH; player 1 sits at the top and
// defends the goal on y = 0.

export const WIDTH = 1;
export const LENGTH = 1.6;
export const HALF = LENGTH / 2;
export const CORNER_RADIUS = 0.12;
export const GOAL_WIDTH = 0.32;
export const GOAL_LEFT = (WIDTH - GOAL_WIDTH) / 2;
export const GOAL_RIGHT = GOAL_LEFT + GOAL_WIDTH;
export const PUCK_RADIUS = 0.035;
export const MALLET_RADIUS = 0.06;

/**
 * Clamps a value into [min, max].
 * @param {number} v
 * @param {number} min
 * @param {number} max
 * @returns {number}
 */
export function clamp(v, min, max) {
  return v < min ? min : v > max ? max : v;
}

/**
 * Returns the centre of the corner arc whose zone contains (x, y), or null
 * when the point is not in a corner zone.
 * @param {number} x
 * @param {number} y
 * @returns {{x: number, y: number} | null}
 */
export function cornerCentre(x, y) {
  const c = CORNER_RADIUS;
  const cx = x < c ? c : x > WIDTH - c ? WIDTH - c : null;
  const cy = y < c ? c : y > LENGTH - c ? LENGTH - c : null;
  return cx === null || cy === null ? null : { x: cx, y: cy };
}

/**
 * Clamps a mallet centre so the whole mallet stays inside the table and in
 * its owner's half (side 0 = bottom half, side 1 = top half).
 * @param {number} x
 * @param {number} y
 * @param {0 | 1} side
 * @returns {{x: number, y: number}}
 */
export function clampMallet(x, y, side) {
  const r = MALLET_RADIUS;
  const minY = side === 1 ? r : HALF + r;
  const maxY = side === 1 ? HALF - r : LENGTH - r;
  const px = clamp(x, r, WIDTH - r);
  const py = clamp(y, minY, maxY);
  const c = cornerCentre(px, py);
  if (!c) return { x: px, y: py };
  const dx = px - c.x;
  const dy = py - c.y;
  const d = Math.hypot(dx, dy);
  const rho = CORNER_RADIUS - r;
  if (d <= rho) return { x: px, y: py };
  return { x: c.x + (dx / d) * rho, y: c.y + (dy / d) * rho };
}

/**
 * Home (rest) position of a player's mallet.
 * @param {0 | 1} side
 * @returns {{x: number, y: number}}
 */
export function homePosition(side) {
  return { x: WIDTH / 2, y: side === 1 ? 0.2 : LENGTH - 0.2 };
}
