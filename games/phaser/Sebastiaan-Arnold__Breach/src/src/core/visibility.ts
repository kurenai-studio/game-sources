import { raySegment, wrapAngle, type Segment } from './geometry';

/**
 * Builds the wall edges of a tile grid as merged line segments. An edge exists wherever a
 * blocking tile meets a non-blocking one; runs along the same line facing the same way merge
 * into one segment, which keeps the raycaster's segment count low.
 */
export function buildWallSegments(
  width: number,
  height: number,
  tileSize: number,
  blocks: (tx: number, ty: number) => boolean,
): Segment[] {
  const solid = (tx: number, ty: number) => tx < 0 || ty < 0 || tx >= width || ty >= height || blocks(tx, ty);
  const segs: Segment[] = [];

  // Horizontal edges between row y-1 and row y.
  for (let y = 0; y <= height; y++) {
    let runStart = -1;
    let runSide = 0;
    for (let x = 0; x <= width; x++) {
      let side = 0;
      if (x < width) {
        const above = solid(x, y - 1);
        const below = solid(x, y);
        side = above === below ? 0 : above ? 1 : -1;
      }
      if (side !== runSide) {
        if (runSide !== 0) segs.push({ ax: runStart * tileSize, ay: y * tileSize, bx: x * tileSize, by: y * tileSize });
        runStart = x;
        runSide = side;
      }
    }
  }

  // Vertical edges between column x-1 and column x.
  for (let x = 0; x <= width; x++) {
    let runStart = -1;
    let runSide = 0;
    for (let y = 0; y <= height; y++) {
      let side = 0;
      if (y < height) {
        const left = solid(x - 1, y);
        const right = solid(x, y);
        side = left === right ? 0 : left ? 1 : -1;
      }
      if (side !== runSide) {
        if (runSide !== 0) segs.push({ ax: x * tileSize, ay: runStart * tileSize, bx: x * tileSize, by: y * tileSize });
        runStart = y;
        runSide = side;
      }
    }
  }

  return segs;
}

export interface RayHit {
  x: number;
  y: number;
  /** Unit direction of the ray that produced this hit. */
  dx: number;
  dy: number;
  /** True when the ray was stopped by a segment rather than by the range limit. */
  blocked: boolean;
}

export interface VisibilityResult {
  /** Flat polygon [x0, y0, x1, y1, ...]. For a cone the first point is the origin. */
  polygon: number[];
  hits: RayHit[];
}

const EPS = 0.0005;

/**
 * Raycast visibility from (ox, oy). With halfFov >= PI this is a full circle; otherwise a cone
 * centred on `facing`. Rays go to every segment endpoint (and just either side of it) plus a
 * uniform sweep so the range arc stays round.
 */
export function visibilityPolygon(
  ox: number,
  oy: number,
  facing: number,
  halfFov: number,
  range: number,
  segments: readonly Segment[],
  sweepStep: number,
): VisibilityResult {
  const full = halfFov >= Math.PI;
  const minX = ox - range, maxX = ox + range, minY = oy - range, maxY = oy + range;
  const near: Segment[] = [];
  for (const s of segments) {
    if (Math.max(s.ax, s.bx) < minX || Math.min(s.ax, s.bx) > maxX) continue;
    if (Math.max(s.ay, s.by) < minY || Math.min(s.ay, s.by) > maxY) continue;
    near.push(s);
  }

  // Angles are stored as offsets from `facing`, in [-halfFov, halfFov] (or [-PI, PI) for a circle).
  const lo = full ? -Math.PI : -halfFov;
  const hi = full ? Math.PI : halfFov;
  const offsets: number[] = [];
  const steps = Math.max(2, Math.ceil((hi - lo) / sweepStep));
  for (let i = 0; i <= steps; i++) {
    if (full && i === steps) break;
    offsets.push(lo + ((hi - lo) * i) / steps);
  }
  const r2 = range * range;
  const addEndpoint = (px: number, py: number) => {
    const ddx = px - ox, ddy = py - oy;
    if (ddx * ddx + ddy * ddy > r2) return;
    const off = wrapAngle(Math.atan2(ddy, ddx) - facing);
    for (const o of [off - EPS, off, off + EPS]) {
      if (full) offsets.push(wrapAngle(o));
      else if (o >= lo && o <= hi) offsets.push(o);
    }
  };
  for (const s of near) {
    addEndpoint(s.ax, s.ay);
    addEndpoint(s.bx, s.by);
  }
  offsets.sort((a, b) => a - b);

  const polygon: number[] = full ? [] : [ox, oy];
  const hits: RayHit[] = [];
  let last = NaN;
  for (const off of offsets) {
    if (off === last) continue;
    last = off;
    const a = facing + off;
    const dx = Math.cos(a);
    const dy = Math.sin(a);
    let best = range;
    for (const s of near) {
      const t = raySegment(ox, oy, dx, dy, s);
      if (t < best) best = t;
    }
    const x = ox + dx * best;
    const y = oy + dy * best;
    polygon.push(x, y);
    hits.push({ x, y, dx, dy, blocked: best < range });
  }
  return { polygon, hits };
}

/** Nearest segment hit along a ray, capped at maxDist. */
export function castRay(
  ox: number,
  oy: number,
  dx: number,
  dy: number,
  maxDist: number,
  segments: readonly Segment[],
): number {
  let best = maxDist;
  for (const s of segments) {
    const t = raySegment(ox, oy, dx, dy, s);
    if (t < best) best = t;
  }
  return best;
}
