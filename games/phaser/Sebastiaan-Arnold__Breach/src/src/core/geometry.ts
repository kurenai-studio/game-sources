export interface Segment {
  ax: number;
  ay: number;
  bx: number;
  by: number;
}

export interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}

export const DEG = Math.PI / 180;

/** Wraps an angle into [-PI, PI). */
export function wrapAngle(a: number): number {
  a = (a + Math.PI) % (Math.PI * 2);
  if (a < 0) a += Math.PI * 2;
  return a - Math.PI;
}

/** Moves angle `from` towards `to` by at most `maxStep`, taking the short way round. */
export function rotateTowards(from: number, to: number, maxStep: number): number {
  const diff = wrapAngle(to - from);
  if (Math.abs(diff) <= maxStep) return to;
  return from + Math.sign(diff) * maxStep;
}

/**
 * Distance along a ray (origin o, unit direction d) to segment s, or Infinity when it misses.
 */
export function raySegment(ox: number, oy: number, dx: number, dy: number, s: Segment): number {
  const sx = s.bx - s.ax;
  const sy = s.by - s.ay;
  const denom = dx * sy - dy * sx;
  if (Math.abs(denom) < 1e-9) return Infinity;
  const qx = s.ax - ox;
  const qy = s.ay - oy;
  const t = (qx * sy - qy * sx) / denom;
  const u = (qx * dy - qy * dx) / denom;
  if (t >= 0 && u >= 0 && u <= 1) return t;
  return Infinity;
}

/** Distance along a ray (unit direction) to a circle, 0 if the origin is inside, Infinity when it misses. */
export function rayCircle(ox: number, oy: number, dx: number, dy: number, cx: number, cy: number, r: number): number {
  const fx = ox - cx;
  const fy = oy - cy;
  const b = fx * dx + fy * dy;
  const c = fx * fx + fy * fy - r * r;
  if (c <= 0) return 0;
  const disc = b * b - c;
  if (disc < 0) return Infinity;
  const t = -b - Math.sqrt(disc);
  return t >= 0 ? t : Infinity;
}

/** Even-odd point-in-polygon test on a flat [x0, y0, x1, y1, ...] array. */
export function pointInPolygon(px: number, py: number, poly: ArrayLike<number>): boolean {
  let inside = false;
  const n = poly.length;
  for (let i = 0, j = n - 2; i < n; j = i, i += 2) {
    const xi = poly[i], yi = poly[i + 1];
    const xj = poly[j], yj = poly[j + 1];
    if (yi > py !== yj > py && px < ((xj - xi) * (py - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}

export function circleIntersectsRect(cx: number, cy: number, r: number, rect: Rect): boolean {
  const nx = Math.max(rect.x, Math.min(cx, rect.x + rect.w));
  const ny = Math.max(rect.y, Math.min(cy, rect.y + rect.h));
  const dx = cx - nx;
  const dy = cy - ny;
  return dx * dx + dy * dy < r * r;
}
