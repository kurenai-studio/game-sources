import { TAU } from '../core/math';
import type { Blob } from '../sim/ObstacleSystem';

/**
 * One continuous visual mass built from a connected group of collision circles.
 *
 * The simulation deliberately keeps circles for cheap avoidance. Rendering those
 * circles one by one exposes the implementation as a row of beads, so the renderer
 * never sees their individual outlines: it sees only this shared outer hull.
 */
export interface StoneMass {
  /** Closed outline in world coordinates: x, y, x, y... */
  points: Float32Array;
  /**
   * The mass's lit edge: the run of the hull that faces up the course, resampled at
   * a fixed spacing, as `x, y, nx, ny` in world coordinates (`n` points outward).
   *
   * Slowblue: this is the one piece of geometry that turns a silhouette into a rock.
   * A dark shape with a bright line along its leading edge reads as a lit solid; the
   * same shape without one reads as a hole in the water. It is also where anything
   * growing on the stone has to be planted, so it is computed once per mass - masses
   * are cached for the life of a run - rather than re-derived every frame.
   */
  crest: Float32Array;
  minY: number;
  maxY: number;
  minX: number;
  maxX: number;
  centreX: number;
  centreY: number;
  /**
   * One blob of a moving section, or null for everything that stands still.
   *
   * Every coordinate in this object is in *home* space, so the whole of the
   * motion is one number - `massShift` - and the paint applies it with a single
   * translate rather than by adding an offset to forty coordinates in six
   * functions, which is the version of this that would have got one of them
   * wrong.
   */
  mover: Blob | null;
  /**
   * The mass's own puffs, as `x, y, r` triples - cloud only, empty for stone.
   *
   * Rock is painted with washes clipped to its silhouette, because rock has a
   * surface. Cloud has no surface; what it has is *lobes*, and the shading that
   * makes a cumulus read is the shadow one lobe throws on the next. Handing the
   * circles back is what lets `RockPaint` paint that as a single union fill,
   * which is the only way to draw interior detail on a blob mass without the
   * seams decision 28 was written about.
   */
  lobes: Float32Array;
}

/** Distance between crest samples, in px. Fine enough to plant kelp on. */
export const CREST_STEP = 15;
/**
 * How far an edge's outward normal must lean up the course to count as crest.
 * At 0 the "lit edge" wraps round to the flanks and the rim light becomes an
 * outline, which is a cartoon; this keeps it to the face light would actually hit.
 */
const CREST_FACING = -0.26;

interface Point {
  x: number;
  y: number;
}

/** Blobs hold still between resizes, so their merged silhouette can be reused. */
let MASS_CACHE = new WeakMap<Blob, StoneMass>();

/** Where a blob sits at phase zero. Its own x for everything that never moves. */
function home(b: Blob): number {
  return b.hx ?? b.x;
}

/** The component, at rest. One allocation per mass, and a mass is built once. */
function atHome(component: readonly Blob[]): Blob[] {
  return component.map((b) => ({ x: home(b), y: b.y, r: b.r }));
}

/**
 * How far a mass has walked from where its silhouette was built, in world px.
 *
 * Zero for every still rock in the game, which is all but a handful, so the
 * translate in `paintStone` is skipped entirely on the common path.
 */
export function massShift(mass: StoneMass): number {
  const m = mass.mover;
  return m === null || m.hx === undefined ? 0 : m.x - m.hx;
}

/**
 * Drops every cached silhouette. Called when the world is rescaled.
 *
 * This cache used to say blobs were immutable for the life of a run, and that was
 * true until `World.resize` started rescaling every x and r so a rotation would not
 * fling the shoal into a wall. A mass holds *world* coordinates derived from those
 * blobs, and nothing here can see them change - so after a turn of the device the
 * rock was drawn at the old width while its collision circles had moved to the new
 * one. That is precisely the report: a rock you swim straight through, and a wall
 * where the water looks open. Rebuilding is cheap because a resize is rare, and the
 * shape comes back the same way it was authored - `stonePick` hashes the position,
 * so the silhouette is a function of where the rock now is, not of when it was
 * built.
 */
export function invalidateStoneMasses(): void {
  MASS_CACHE = new WeakMap<Blob, StoneMass>();
}

/**
 * Merge every touching group into one stable, smooth silhouette.
 *
 * A convex hull is intentional here. The collision circles overlap deeply, and
 * preserving every small inward scallop is precisely what made a wall look built
 * from circles. The hull keeps the large authored gesture while removing the
 * mechanical joints between its parts.
 */
export function stoneMasses(
  blobs: readonly Blob[],
  verts: number,
  vertsSmall: number,
  jag: number,
  cloud = false,
): StoneMass[] {
  const out = new Set<StoneMass>();

  for (const seed of blobs) {
    const cached = MASS_CACHE.get(seed);
    if (cached !== undefined) {
      out.add(cached);
      continue;
    }

    const component: Blob[] = [];
    const pending: Blob[] = [seed];
    const found = new Set<Blob>(pending);
    while (pending.length > 0) {
      const current = pending.pop()!;
      component.push(current);
      for (const candidate of blobs) {
        if (found.has(candidate)) continue;
        // Home positions, not live ones. A moving section's two walls are two
        // components at every phase, but only if the walk is asked at the phase
        // they were authored at: sample it half open and the outer end of a wall
        // has drifted out of touch with its own middle, and one rock is cached as
        // three. Everything static answers `home` with its own x.
        const dx = home(candidate) - home(current);
        const dy = candidate.y - current.y;
        const reach = candidate.r + current.r;
        if (dx * dx + dy * dy <= reach * reach * 1.02) {
          found.add(candidate);
          pending.push(candidate);
        }
      }
    }

    /*
     * Slowblue: a moving mass is built where it *lives* and drawn where it *is*.
     *
     * The silhouette is a hull, a resampled crest and a set of position-keyed
     * details, and re-deriving all of that every frame is both an allocation in
     * the render path and - because `stonePick` and `hash2` seed the surface from
     * position - a rock whose crenellation boils as it walks. So the geometry is
     * computed once, at the section's authored position, and `paintStone`
     * translates it by however far the section has moved. See `Blob.hx`.
     */
    const moving = component.some((b) => b.hx !== undefined);
    const mass = cloud
      ? buildCloudMass(moving ? atHome(component) : component, verts, jag)
      : buildMass(moving ? atHome(component) : component, verts, vertsSmall, jag);
    mass.mover = moving ? component[0]! : null;
    for (const blob of component) MASS_CACHE.set(blob, mass);
    out.add(mass);
  }

  return [...out];
}

/**
 * Slowblue: cloud is the one mass in the game whose silhouette is **not** a hull.
 *
 * A convex hull is right for rock, and the reasoning is in `stoneMasses` above:
 * the collision circles are an implementation detail and a hull hides them. Run a
 * cumulus through the same code and you get a smooth lozenge, because convexity
 * is precisely the property a cloud does not have - what makes a cumulus legible
 * at a glance is that it is *bumpy*, and every bump is a place the outline turns
 * back on itself.
 *
 * So a cloud's outline is the union of its puffs, sampled radially: for each
 * angle around the mass, how far out does the furthest puff reach. That is a
 * star-shaped polygon, which buys three things at once - it is genuinely
 * non-convex, so lumps survive; it can never fall inside a collision circle, so
 * the drawn edge is never tighter than the edge the flock is actually stopped by;
 * and its vertices come out already sorted by angle, which is what makes the
 * crest below as cheap as the convex one.
 *
 * The wobble is two octaves rather than the hull's one, and it is applied here
 * instead of per-puff, because on a shape this soft a per-puff wobble is invisible
 * and a per-outline one is the difference between vapour and a balloon.
 */
function buildCloudMass(blobs: readonly Blob[], verts: number, jag: number): StoneMass {
  // Radius-weighted centre: guaranteed inside the biggest puff, so no ray can
  // miss the union and collapse the outline to nothing.
  let cx = 0;
  let cy = 0;
  let weight = 0;
  let reach = 0;
  for (const b of blobs) {
    cx += b.x * b.r;
    cy += b.y * b.r;
    weight += b.r;
  }
  cx /= weight || 1;
  cy /= weight || 1;
  for (const b of blobs) reach = Math.max(reach, Math.hypot(b.x - cx, b.y - cy) + b.r);

  // Angular resolution scaled to the mass: a puff on a wide deck must still get
  // several samples across it, or a bank turns back into a smooth wall.
  const count = Math.max(verts * 2, Math.min(120, Math.round((reach * TAU) / 11)));
  const phase = ((Math.round(cx) * 0.031 + Math.round(cy) * 0.017) % TAU) + TAU;
  const hull: Point[] = [];
  for (let i = 0; i < count; i++) {
    const a = (i / count) * TAU;
    const dx = Math.cos(a);
    const dy = Math.sin(a);
    let support = 0;
    for (const b of blobs) {
      const ox = b.x - cx;
      const oy = b.y - cy;
      const along = ox * dx + oy * dy;
      const perp2 = ox * ox + oy * oy - along * along;
      const inside = b.r * b.r - perp2;
      if (inside <= 0) continue;
      const t = along + Math.sqrt(inside);
      if (t > support) support = t;
    }
    // Outward only, exactly as `roughen` is: drawing a cloud a little larger than
    // it collides is a soft edge, drawing it smaller is invisible cloud.
    const wobble =
      1 + jag * (0.62 * Math.sin(a * 3 + phase) + 0.38 * Math.sin(a * 7 - phase * 1.7) + 1);
    const r = Math.max(4, support) * wobble;
    hull.push({ x: cx + dx * r, y: cy + dy * r });
  }

  const mass = pack(hull, cloudCrest(hull, { x: cx, y: cy }));
  const lobes = new Float32Array(blobs.length * 3);
  for (let i = 0; i < blobs.length; i++) {
    const b = blobs[i]!;
    lobes[i * 3] = b.x;
    lobes[i * 3 + 1] = b.y;
    lobes[i * 3 + 2] = b.r;
  }
  mass.lobes = lobes;
  return mass;
}

/**
 * The lit top of a cloud.
 *
 * Same claim as the stone's crest - the contiguous run of the outline that faces
 * up the course - resting on a different guarantee. A convex hull's edge normals
 * rotate monotonically; a star polygon's *radial* directions do, by construction,
 * so the up-facing run is still one unbroken arc and the radius direction is a
 * perfectly good normal for something with no hard surface to be normal to.
 */
function cloudCrest(outline: readonly Point[], centre: Point): Float32Array {
  const n = outline.length;
  if (n < 6) return new Float32Array(0);
  const up: boolean[] = [];
  const nx: number[] = [];
  const ny: number[] = [];
  for (const p of outline) {
    const dx = p.x - centre.x;
    const dy = p.y - centre.y;
    const d = Math.hypot(dx, dy) || 1;
    nx.push(dx / d);
    ny.push(dy / d);
    up.push(dy / d < CREST_FACING);
  }
  let start = -1;
  for (let i = 0; i < n; i++) {
    if (up[i] === true && up[(i + n - 1) % n] === false) {
      start = i;
      break;
    }
  }
  if (start < 0) return new Float32Array(0);
  const out: number[] = [];
  for (let step = 0; step < n; step++) {
    const i = (start + step) % n;
    if (up[i] !== true) break;
    out.push(outline[i]!.x, outline[i]!.y, nx[i]!, ny[i]!);
  }
  return new Float32Array(out);
}

function buildMass(blobs: readonly Blob[], verts: number, vertsSmall: number, jag: number): StoneMass {
  const samples: Point[] = [];

  for (const blob of blobs) {
    const count = blob.r >= 26 ? verts : vertsSmall;
    const pick = stonePick(blob.x, blob.y);
    const phase = pick * 0.73 + blob.x * 0.0017 + blob.y * 0.0011;
    const stretch = 0.035 + (pick & 3) * 0.009;
    const cp = Math.cos(phase);
    const sp = Math.sin(phase);

    for (let i = 0; i < count; i++) {
      const a = (i / count) * TAU;
      const drift =
        Math.sin(a * 2 + pick * 1.7) * 0.7 + Math.sin(a * 3 + pick * 2.9 + 0.6) * 0.3;
      const radius = blob.r * (1 + jag * drift);
      const lx = Math.cos(a) * radius * (1 + stretch);
      const ly = Math.sin(a) * radius * (1 - stretch);
      samples.push({
        x: blob.x + lx * cp - ly * sp,
        y: blob.y + lx * sp + ly * cp,
      });
    }
  }

  const hull = roughen(convexHull(samples));
  let centreX = 0;
  let centreY = 0;
  for (const p of hull) {
    centreX += p.x;
    centreY += p.y;
  }
  const centre = { x: centreX / hull.length, y: centreY / hull.length };
  return pack(hull, buildCrest(hull, centre));
}

/** Outline + crest -> the record everything downstream reads. */
function pack(outline: readonly Point[], crest: Float32Array): StoneMass {
  const points = new Float32Array(outline.length * 2);
  let centreX = 0;
  let centreY = 0;
  let minY = Infinity;
  let maxY = -Infinity;
  let minX = Infinity;
  let maxX = -Infinity;
  for (let i = 0; i < outline.length; i++) {
    const p = outline[i]!;
    points[i * 2] = p.x;
    points[i * 2 + 1] = p.y;
    centreX += p.x;
    centreY += p.y;
    minY = Math.min(minY, p.y);
    maxY = Math.max(maxY, p.y);
    minX = Math.min(minX, p.x);
    maxX = Math.max(maxX, p.x);
  }
  return {
    points,
    crest,
    minY,
    maxY,
    minX,
    maxX,
    centreX: centreX / outline.length,
    centreY: centreY / outline.length,
    lobes: NO_LOBES,
    // Filled in by `stoneMasses`, which is the only thing that knows whether the
    // component it just hulled belongs to a section that moves.
    mover: null,
  };
}

/** Stone has no lobes; one shared empty array rather than one per mass. */
const NO_LOBES = new Float32Array(0);

/**
 * The contiguous arc of the hull that faces up the course, resampled evenly.
 *
 * A convex outline's edge normals rotate monotonically all the way round it, so the
 * up-facing edges are always one unbroken run - the only work is finding where that
 * run starts, which is the first up-facing edge whose predecessor is not one.
 */
function buildCrest(hull: readonly Point[], centre: Point): Float32Array {
  const n = hull.length;
  if (n < 3) return new Float32Array(0);

  const facing = new Float64Array(n * 2);
  const up: boolean[] = [];
  for (let i = 0; i < n; i++) {
    const a = hull[i]!;
    const b = hull[(i + 1) % n]!;
    const ex = b.x - a.x;
    const ey = b.y - a.y;
    const len = Math.hypot(ex, ey) || 1;
    let nx = ey / len;
    let ny = -ex / len;
    // Orient outward against the mass's own centre rather than against a winding
    // order: the hull builder's orientation is an implementation detail, and a
    // silently inverted normal would light the back of every rock in the game.
    const mx = (a.x + b.x) * 0.5 - centre.x;
    const my = (a.y + b.y) * 0.5 - centre.y;
    if (nx * mx + ny * my < 0) {
      nx = -nx;
      ny = -ny;
    }
    facing[i * 2] = nx;
    facing[i * 2 + 1] = ny;
    up.push(ny < CREST_FACING);
  }

  let start = -1;
  for (let i = 0; i < n; i++) {
    if (up[i] === true && up[(i + n - 1) % n] === false) {
      start = i;
      break;
    }
  }
  if (start < 0) return new Float32Array(0);

  const out: number[] = [];
  for (let step = 0; step < n; step++) {
    const i = (start + step) % n;
    if (up[i] !== true) break;
    const a = hull[i]!;
    const b = hull[(i + 1) % n]!;
    const nx = facing[i * 2]!;
    const ny = facing[i * 2 + 1]!;
    const len = Math.hypot(b.x - a.x, b.y - a.y);
    const count = Math.max(1, Math.round(len / CREST_STEP));
    // The last sample of an edge is the first of the next one, so it is left off.
    for (let k = 0; k < count; k++) {
      const t = k / count;
      out.push(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, nx, ny);
    }
    if (step === n - 1 || up[(i + 1) % n] !== true) {
      out.push(b.x, b.y, nx, ny);
    }
  }
  return new Float32Array(out);
}

/**
 * Puts the lumps back on a hull.
 *
 * Slowblue: the convex hull is what stopped a wall from reading as a row of beads, and it
 * cost the rock every irregularity it had - a chain of circles hulls into a capsule,
 * and a capsule with a lit top edge reads as a plastic lozenge, which is exactly what
 * the first lit version looked like. This pushes every hull point *outward* along its
 * own radius by a smoothly varying amount, keyed to its index so a long wall gets
 * several lumps along its length rather than two fat ends.
 *
 * Outward only, and capped: drawing a rock slightly larger than its collision circles
 * is safe (the shoal simply never touches the drawn edge), drawing it smaller would
 * put invisible stone in open water.
 */
export const ROUGHEN_MAX = 12;

function roughen(hull: Point[]): Point[] {
  const n = hull.length;
  if (n < 6) return hull;
  let minX = Infinity;
  let maxX = -Infinity;
  let minY = Infinity;
  let maxY = -Infinity;
  let cx = 0;
  let cy = 0;
  for (const p of hull) {
    minX = Math.min(minX, p.x);
    maxX = Math.max(maxX, p.x);
    minY = Math.min(minY, p.y);
    maxY = Math.max(maxY, p.y);
    cx += p.x;
    cy += p.y;
  }
  cx /= n;
  cy /= n;
  // Scaled by the mass's *narrow* side: a bump has to be a feature of the rock's
  // thickness, not of how long a wall happens to be.
  const amp = Math.max(3, Math.min(ROUGHEN_MAX, Math.min(maxX - minX, maxY - minY) * 0.28));
  const phase = ((Math.round(cx) * 0.037 + Math.round(cy) * 0.021) % TAU) + TAU;
  return hull.map((p, i) => {
    const bump =
      amp *
      (0.6 * (0.5 + 0.5 * Math.sin(i * 1.93 + phase)) +
        0.4 * (0.5 + 0.5 * Math.sin(i * 4.71 + phase * 1.7)));
    const dx = p.x - cx;
    const dy = p.y - cy;
    const d = Math.hypot(dx, dy) || 1;
    return { x: p.x + (dx / d) * bump, y: p.y + (dy / d) * bump };
  });
}

/** Andrew's monotone chain hull. Samples are tiny, so a plain sort is sufficient. */
function convexHull(points: Point[]): Point[] {
  if (points.length <= 3) return points;
  points.sort((a, b) => a.x - b.x || a.y - b.y);

  const lower: Point[] = [];
  for (const p of points) {
    while (lower.length >= 2 && cross(lower.at(-2)!, lower.at(-1)!, p) <= 0) lower.pop();
    lower.push(p);
  }

  const upper: Point[] = [];
  for (let i = points.length - 1; i >= 0; i--) {
    const p = points[i]!;
    while (upper.length >= 2 && cross(upper.at(-2)!, upper.at(-1)!, p) <= 0) upper.pop();
    upper.push(p);
  }

  lower.pop();
  upper.pop();
  return lower.concat(upper);
}

function cross(a: Point, b: Point, c: Point): number {
  return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

/**
 * Append one mass as a closed quadratic curve in screen space.
 *
 * `grow` is only used for the subtle lower shadow/high-contrast rim. Moving hull
 * points away from the shared centre preserves one silhouette instead of growing
 * the hidden circles separately.
 */
export function traceStoneMass(
  ctx: CanvasRenderingContext2D,
  mass: StoneMass,
  cameraY: number,
  grow: number,
  offsetY: number,
): void {
  const points = mass.points;
  const count = points.length / 2;

  const at = (index: number): Point => {
    const x = points[index * 2]!;
    const y = points[index * 2 + 1]!;
    const dx = x - mass.centreX;
    const dy = y - mass.centreY;
    const length = Math.hypot(dx, dy) || 1;
    return {
      x: x + (dx / length) * grow,
      y: y - cameraY + offsetY + (dy / length) * grow,
    };
  };

  let current = at(0);
  const last = at(count - 1);
  ctx.moveTo((last.x + current.x) * 0.5, (last.y + current.y) * 0.5);
  for (let i = 0; i < count; i++) {
    const next = at((i + 1) % count);
    ctx.quadraticCurveTo(
      current.x,
      current.y,
      (current.x + next.x) * 0.5,
      (current.y + next.y) * 0.5,
    );
    current = next;
  }
  ctx.closePath();
}

function stonePick(x: number, y: number): number {
  const h = Math.imul(Math.round(x) | 0, 0x27d4eb2d) ^ Math.imul(Math.round(y) | 0, 0x165667b1);
  return (h >>> 3) & 7;
}
