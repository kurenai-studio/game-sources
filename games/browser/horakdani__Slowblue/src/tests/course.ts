import { ACT_WATER, type Act } from '../src/config/levels';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { ObstacleSystem } from '../src/sim/ObstacleSystem';
import { W } from './helpers';

/**
 * Slowblue: the corridor sweep, shared by every act's safety net.
 *
 * "No obstacle that cannot be flown" is a claim, and a claim about geometry can
 * be checked instead of believed. The sweep carries a set of reachable x
 * positions down the whole course, dilating it by how far a body can actually
 * move sideways in the time it takes to cover the vertical distance, and
 * intersecting it with the space that is actually open. If that set ever
 * empties, some wall cannot be reached around; if a required ring never
 * intersects it, that ring is behind a wall and the run is unwinnable at it.
 *
 * The numbers are deliberately pessimistic - a shoal cruises at 118 px/s and a
 * laid current moves it sideways faster than 45 px/s - so a course that passes
 * here has margin, not a solution. The design memo's own requirement is that
 * this holds in any medium (DESIGN-ASCENT §10): lateral authority in air is
 * weaker per stroke but there is no forced drift shrinking the time budget, so
 * the same pessimistic ratio stays honest there.
 *
 * ## What it could not see, and now can
 *
 * The set it carries is a flat bitmap, and for six acts that was enough, because
 * every archetype in the game was a row laid *across* the course: whatever the
 * geometry, the reachable set was essentially one run of cells, so "is this ring
 * reachable" and "is this ring reachable by the body that took the last one"
 * were the same question. They stop being the same question as soon as a course
 * has two ways round something for longer than the dilation takes to re-merge -
 * and act I's reachable set is already in more than one piece on about a tenth
 * of its slices today. Two required rings, one in each piece, both read as
 * reachable, and no single body can hold both.
 *
 * So there are two checks here now rather than one:
 *
 *   - `blockedAt` / `ringsReachable`, as before: is there *any* line.
 *   - `chainBreaks`: seeded at each required ring in turn and carried forward,
 *     is the *next* required ring still reachable from it. That is the question
 *     the player actually asks, and it is the one a branching course can fail
 *     while the flat check stays green.
 *
 * It also reports `minWidestRun` - the narrowest the widest reachable run ever
 * gets, in px. The sweep samples points and a shoal is about 150 px across, so a
 * corridor the bitmap approves can still be one no body fits down. That number
 * is deliberately not asserted tightly anywhere; it is *printed*, so a change
 * that halves it shows up in a test log rather than a year later in a phone.
 */
const FORWARD = 100;
const LATERAL = 45;
/** Sampling steps for the sweep. Fine enough to catch a one-blob-wide slot. */
const SLICE = 20;
const CELL = 4;

export function buildCourse(act: Act = ACT_WATER): ObstacleSystem {
  const o = new ObstacleSystem(W, 1, true, act);
  // "Ahead" is a signed direction, not a smaller number: three acts fall, and a
  // build line hardcoded to -1e6 silently builds nothing at all for them.
  o.ensureAhead(act.direction * 1e6);
  return o;
}

export interface Sweep {
  /** Reachable x cells at each required ring, keyed by pod y. */
  ringsReachable: { level: number; section: number; x: number; ok: boolean }[];
  /** Y where the corridor closed completely, if it ever did. */
  blockedAt: number | null;
  /**
   * Required rings that cannot be reached from the previous required ring by a
   * single body. Empty on a course nobody has broken.
   */
  chainBreaks: { level: number; section: number; from: number; to: number }[];
  /** The narrowest the widest reachable run ever gets, in px. Reported, not asserted. */
  minWidestRun: number;
  /** How many separate pieces the reachable set is ever in at once. */
  maxComponents: number;
}

interface Ring {
  y: number;
  x: number;
  r: number;
  level: number;
  section: number;
}

/** Anywhere within the lateral budget of a reachable cell is reachable. */
function dilate(reach: Uint8Array, budget: number, cols: number): Uint8Array {
  const grown = new Uint8Array(cols);
  for (let i = 0; i < cols; i++) {
    if (reach[i] === 0) continue;
    for (let j = Math.max(0, i - budget); j <= Math.min(cols - 1, i + budget); j++) grown[j] = 1;
  }
  return grown;
}

/** Widest contiguous run of set cells, in cells. */
function widestRun(row: Uint8Array, cols: number): number {
  let best = 0;
  let run = 0;
  for (let i = 0; i < cols; i++) {
    run = row[i] === 1 ? run + 1 : 0;
    if (run > best) best = run;
  }
  return best;
}

/** How many separate runs of set cells the row is in. */
function componentCount(row: Uint8Array, cols: number): number {
  let n = 0;
  for (let i = 0; i < cols; i++) if (row[i] === 1 && (i === 0 || row[i - 1] === 0)) n++;
  return n;
}

/** Carries `reach` one slice forward: dilate, then intersect with what is open. */
function advance(reach: Uint8Array, row: Uint8Array, budget: number, cols: number): number {
  const grown = dilate(reach, budget, cols);
  let any = 0;
  for (let i = 0; i < cols; i++) {
    reach[i] = grown[i] === 1 && row[i] === 1 ? 1 : 0;
    any += reach[i]!;
  }
  return any;
}

/** The cell range a ring covers, as `[lo, hi]` inclusive. */
function ringCells(ring: Ring, cols: number): [number, number] {
  return [
    Math.max(0, Math.floor((ring.x - ring.r * 0.6) / CELL)),
    Math.min(cols - 1, Math.ceil((ring.x + ring.r * 0.6) / CELL)),
  ];
}

export function sweepCourse(o: ObstacleSystem): Sweep {
  const cols = Math.ceil(W / CELL) + 1;
  // The sweep walks the course the way the swarm does, so on a descending act it
  // runs from the smallest Y to the largest. One sign, applied to the start, the
  // end and the step - exactly the pattern `World.u` establishes for the sim.
  const dir = o.act.direction;
  const first = o.sections[0]!;
  const last = o.sections[o.sections.length - 1]!;
  const startY = dir < 0 ? first.maxY + 600 : first.minY - 600;
  const endY = dir < 0 ? last.minY - 200 : last.maxY + 200;
  const budget = Math.max(1, Math.round(((LATERAL * (SLICE / FORWARD)) / CELL) * 1));

  // The open rows are the expensive part - `hit` is a linear scan over every blob
  // of a course that is never pruned - so they are built once here and the
  // per-ring chain pass below reads them back instead of re-deriving them.
  const ys: number[] = [];
  const open: Uint8Array[] = [];
  for (let y = startY; (endY - y) * dir > 0; y += SLICE * dir) {
    const row = new Uint8Array(cols);
    // `hitSwept`, not `hit`: a section that drifts is authored in the middle of
    // its travel, so the live circles are only one of the places it is. See
    // `Section.envelope` - the sweep asks whether a line exists past everywhere
    // the thing ever gets to, which is the only version of the question that is
    // still true whenever the player happens to arrive.
    for (let i = 0; i < cols; i++) row[i] = o.hitSwept(i * CELL, y, 1) === null ? 1 : 0;
    ys.push(y);
    open.push(row);
  }

  const rings: Ring[] = o.sections.flatMap((s) =>
    s.podHints
      .filter((p) => p.required === true)
      .map((p) => ({
        y: p.y,
        x: p.x,
        r: DEFAULT_TUNING.rescueRadius * (p.scale ?? 1),
        level: s.level,
        section: s.id,
      })),
  );

  // The shoal starts as a body in the middle, but assume nothing: start from the
  // whole open width, so the sweep answers "is there any line", not "is there one
  // from where I happened to put the fish".
  const reach = Uint8Array.from(open[0] ?? new Uint8Array(cols));
  const ringsReachable: Sweep['ringsReachable'] = [];
  const seen = new Set<Ring>();
  /** Slice index each ring was resolved at, so the chain pass can start there. */
  const ringSlice = new Map<Ring, number>();
  let minWidestRun = Infinity;
  let maxComponents = 0;
  let blockedAt: number | null = null;

  for (let k = 0; k < ys.length; k++) {
    if (advance(reach, open[k]!, budget, cols) === 0) {
      blockedAt = ys[k]!;
      break;
    }
    minWidestRun = Math.min(minWidestRun, widestRun(reach, cols) * CELL);
    maxComponents = Math.max(maxComponents, componentCount(reach, cols));

    for (const ring of rings) {
      if (seen.has(ring)) continue;
      if (Math.abs(ring.y - ys[k]!) > SLICE * 0.5) continue;
      seen.add(ring);
      ringSlice.set(ring, k);
      // The ring only has to be *touchable*: the shoal has to get its body inside
      // the ring, so a reachable cell within the ring radius is the honest test.
      const [lo, hi] = ringCells(ring, cols);
      let ok = false;
      for (let i = lo; i <= hi; i++) if (reach[i] === 1) ok = true;
      ringsReachable.push({ level: ring.level, section: ring.section, x: ring.x, ok });
    }
  }

  return {
    ringsReachable,
    blockedAt,
    chainBreaks: blockedAt === null ? chainRings(rings, ringSlice, open, cols, budget) : [],
    minWidestRun: Number.isFinite(minWidestRun) ? minWidestRun : 0,
    maxComponents,
  };
}

/**
 * Slowblue: can one body take them all, in order?
 *
 * The flat sweep answers "is this ring reachable", starting from the whole open
 * width. That is the right question for the *first* ring and the wrong one for
 * every ring after it, because the body that has to hold ring N+1 is the body
 * that just held ring N - it is not free to have been somewhere else while it
 * was doing so.
 *
 * So this seeds the reachable set at each ring in turn, at the cells actually
 * inside it, and carries it forward under the same dilation as far as the next
 * one. A course whose rings are strung along a single corridor passes for free,
 * which is why nothing in the campaign needed it until the campaign had a course
 * with two ways through something.
 */
function chainRings(
  rings: Ring[],
  ringSlice: Map<Ring, number>,
  open: Uint8Array[],
  cols: number,
  budget: number,
): Sweep['chainBreaks'] {
  const out: Sweep['chainBreaks'] = [];
  for (let n = 0; n + 1 < rings.length; n++) {
    const from = rings[n]!;
    const to = rings[n + 1]!;
    const k0 = ringSlice.get(from);
    const k1 = ringSlice.get(to);
    // A ring the sweep never visited is already reported by the count check in
    // each act's own suite; there is nothing to chain from or to.
    if (k0 === undefined || k1 === undefined || k1 <= k0) continue;
    const reach = new Uint8Array(cols);
    const [lo, hi] = ringCells(from, cols);
    for (let i = lo; i <= hi; i++) if (open[k0]![i] === 1) reach[i] = 1;
    for (let k = k0 + 1; k <= k1; k++) {
      if (advance(reach, open[k]!, budget, cols) === 0) break;
    }
    const [tlo, thi] = ringCells(to, cols);
    let ok = false;
    for (let i = tlo; i <= thi; i++) if (reach[i] === 1) ok = true;
    if (!ok) out.push({ level: to.level, section: to.section, from: from.x, to: to.x });
  }
  return out;
}
