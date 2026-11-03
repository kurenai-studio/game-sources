/**
 * The village plan (pure data, no meshes): a dense English village laid out on a 2 m occupancy grid.
 *
 *  - A paved market square on the crossroads with a market cross and a pump.
 *  - Joined terraces right on the street in the heart, semis and detached cottages with front
 *    gardens further out, every one with a long back garden plot behind it (burgage strips): lawn,
 *    veg rows, a path, a shed, a small tree, bounded by hedges or low stone walls. Back extensions.
 *  - The green (a mown ellipse with a footpath ring) with cottages facing it.
 *  - The church in a walled churchyard with yews, graves and a lychgate path to the street.
 *  - The land behind the streets filled with orchards, paddocks, allotments, barns with yards and
 *    copses, each hedged; never bare lawn.
 *  - Farmsteads out in the country.
 *
 * Everything placed is stamped into the grid first, so nothing overlaps a road, the river, the
 * square or another plot. The painter (villagemap.ts) and the mesh builder (village.ts) read this.
 */
import * as THREE from "three";
import { mulberry32, pick, range } from "../core/rng";
import { BRIDGE, CHURCH, FARMS, GREEN, ROAD_PATHS, SQUARE, VILLAGE, roadIndex, type P2 } from "./layout";
import { groundHeight, riverAt } from "./heightfield";
import type { PaintShape } from "./groundmap";
import { fbm } from "./noise";

export interface HouseSpec {
  x: number;
  z: number;
  yaw: number;
  w: number;
  d: number;
  h: number;
  pitch: number;
  wall: string;
  roof: string;
  chimney: number;
  annex: boolean;
  /** Plinth height (ground level under the house). */
  y: number;
  kind: "cottage" | "farmhouse" | "barn" | "shed" | "ext";
}

/** Rectangle in a local frame: world = (cx, cz) + rot(local, yaw). */
export interface Rect {
  cx: number;
  cz: number;
  yaw: number;
  x0: number;
  x1: number;
  z0: number;
  z1: number;
}

export type PaintKind = "garden" | "front" | "orchard" | "paddock" | "allot" | "yard" | "copse" | "meadow" | "square" | "green" | "churchyard" | "path";
export interface PaintOp {
  kind: PaintKind;
  R: Rect;
  seed: number;
  /** Garden: fraction of the plot (from the far end) in veg rows; 0 = all lawn. */
  veg?: number;
  /** Garden: path offset across the plot (local x), NaN for none. */
  path?: number;
}

export interface Bound {
  a: [number, number];
  b: [number, number];
  kind: "hedge" | "wall";
}

export interface Prop {
  x: number;
  z: number;
  yaw: number;
  kind: "grave" | "cross" | "pump" | "lychgate" | "greenhouse" | "stall";
  /** Stall awning colour. */
  color?: string;
}

export interface VillagePlan {
  houses: HouseSpec[];
  /** Coarse shapes for the 2 m field map (farm yards; the village itself is in `paint`). */
  shapes: PaintShape[];
  /** Fine paint ops for the village detail map. */
  paint: PaintOp[];
  /** Hedges and low stone walls round plots. */
  bounds: Bound[];
  props: Prop[];
  /** Chimney tops (world), for smoke. */
  chimneys: THREE.Vector3[];
  /** Tree spots the village asks for. */
  trees: { x: number; z: number; kind: "round" | "hero" | "tall" | "conifer" | "poplar" | "bush"; s: number; tint?: number }[];
  /** Polygons where the countryside road mask is suppressed (the square is paved over). */
  noRoad: [number, number][][];
  /** Footpath ring round the green (world polyline), painted in the detail map. */
  greenPath: [number, number][];
}

// Limewash, cream, warm stone and the odd brick front.
const WALLS = ["#f4ecd8", "#f6f1e6", "#efe0bc", "#f0dcae", "#ead2bc", "#e6dccb", "#e2c8a2", "#f3e6c6", "#c98a6c", "#d8c49a"];
// Warm clay tiles mostly (they read from altitude), some slate and the odd golden thatch tone.
const CLAY = ["#c8603c", "#d2703f", "#bb5538", "#d98a4e", "#b04a34", "#cf6a46", "#c4783e"];
const SLATE = ["#58637a", "#4e5868", "#626a78"];
const roofColor = (r: () => number) => (r() < 0.8 ? pick(r, CLAY) : r() < 0.7 ? pick(r, SLATE) : "#b89656");

export const rot = (x: number, z: number, yaw: number): [number, number] => {
  const c = Math.cos(yaw), s = Math.sin(yaw);
  // Local +z is the house's front; local +x along the ridge. Ry(yaw).
  return [x * c + z * s, -x * s + z * c];
};
const unrot = (a: number, b: number, yaw: number): [number, number] => {
  const c = Math.cos(yaw), s = Math.sin(yaw);
  return [a * c - b * s, a * s + b * c];
};

export function rectPoly(R: Rect): [number, number][] {
  return [[R.x0, R.z0], [R.x1, R.z0], [R.x1, R.z1], [R.x0, R.z1]].map(([x, z]) => {
    const [a, b] = rot(x, z, R.yaw);
    return [R.cx + a, R.cz + b] as [number, number];
  });
}
const W = (R: Rect, lx: number, lz: number): [number, number] => {
  const [a, b] = rot(lx, lz, R.yaw);
  return [R.cx + a, R.cz + b];
};

/** Rough minimum ground under a footprint. */
function footY(x: number, z: number, yaw: number, w: number, d: number): number {
  let lo = Infinity;
  for (const [a, b] of [[-w / 2, -d / 2], [w / 2, -d / 2], [w / 2, d / 2], [-w / 2, d / 2], [0, 0]]) {
    const [p, q] = rot(a, b, yaw);
    lo = Math.min(lo, groundHeight(x + p, z + q));
  }
  return lo;
}

// ------------------------------------------------------------------ occupancy grid

const OG_HALF = 400, OG_CELL = 2, OG_N = (OG_HALF * 2) / OG_CELL;
const enum Cell { free = 0, road = 1, house = 2, plot = 3, water = 4, keep = 5 }

class Occ {
  readonly a = new Uint8Array(OG_N * OG_N);
  at(x: number, z: number): number {
    const i = Math.floor((x + OG_HALF) / OG_CELL), j = Math.floor((z + OG_HALF) / OG_CELL);
    if (i < 0 || j < 0 || i >= OG_N || j >= OG_N) return -1;
    return j * OG_N + i;
  }
  /** Visit every cell whose centre lies in the rect grown by `pad` (negative shrinks). */
  each(R: Rect, pad: number, fn: (k: number) => boolean | void): boolean {
    const P = rectPoly({ ...R, x0: R.x0 - pad, x1: R.x1 + pad, z0: R.z0 - pad, z1: R.z1 + pad });
    let xa = Infinity, xb = -Infinity, za = Infinity, zb = -Infinity;
    for (const [x, z] of P) {
      xa = Math.min(xa, x); xb = Math.max(xb, x); za = Math.min(za, z); zb = Math.max(zb, z);
    }
    const i0 = Math.floor((xa + OG_HALF) / OG_CELL), i1 = Math.floor((xb + OG_HALF) / OG_CELL);
    const j0 = Math.floor((za + OG_HALF) / OG_CELL), j1 = Math.floor((zb + OG_HALF) / OG_CELL);
    for (let j = j0; j <= j1; j++) for (let i = i0; i <= i1; i++) {
      const x = (i + 0.5) * OG_CELL - OG_HALF, z = (j + 0.5) * OG_CELL - OG_HALF;
      const [lx, lz] = unrot(x - R.cx, z - R.cz, R.yaw);
      if (lx < R.x0 - pad || lx > R.x1 + pad || lz < R.z0 - pad || lz > R.z1 + pad) continue;
      if (i < 0 || j < 0 || i >= OG_N || j >= OG_N) {
        if (fn(-1) === false) return false;
        continue;
      }
      if (fn(j * OG_N + i) === false) return false;
    }
    return true;
  }
  free(R: Rect, pad = 0): boolean {
    return this.each(R, pad, (k) => k < 0 || this.a[k] === Cell.free);
  }
  mark(R: Rect, v: number, pad = 0): void {
    this.each(R, pad, (k) => {
      if (k >= 0 && (this.a[k] === Cell.free || v === Cell.house)) this.a[k] = v;
    });
  }
}

// ------------------------------------------------------------------ the plan

export function planVillage(seed: number): VillagePlan {
  const r = mulberry32(seed * 313 + 17);
  const houses: HouseSpec[] = [];
  const shapes: PaintShape[] = [];
  const paint: PaintOp[] = [];
  const bounds: Bound[] = [];
  const props: Prop[] = [];
  const trees: VillagePlan["trees"] = [];
  const occ = new Occ();
  const sd = () => Math.floor(r() * 1e9);

  // Roads and the river (with its banks) are off limits.
  for (let j = 0; j < OG_N; j++) for (let i = 0; i < OG_N; i++) {
    const x = (i + 0.5) * OG_CELL - OG_HALF, z = (j + 0.5) * OG_CELL - OG_HALF;
    const rd = roadIndex.near(x, z, 12);
    if (rd.d < rd.v + 1.2) occ.a[j * OG_N + i] = Cell.road;
    else {
      const rv = riverAt(x, z);
      if (rv.d < rv.hw + 9) occ.a[j * OG_N + i] = Cell.water;
    }
  }
  occ.mark({ cx: BRIDGE.x, cz: BRIDGE.z, yaw: 0, x0: -16, x1: 16, z0: -40, z1: 40 }, Cell.keep);

  // ---------------------------------------------------------------- market square
  const SQ: Rect = { cx: SQUARE.x, cz: SQUARE.z, yaw: 0, x0: -SQUARE.hx, x1: SQUARE.hx, z0: -SQUARE.hz, z1: SQUARE.hz };
  occ.mark(SQ, Cell.keep, 0.5);
  // The roads' cells inside it become the square too.
  occ.each(SQ, 0, (k) => {
    if (k >= 0) occ.a[k] = Cell.keep;
  });
  paint.push({ kind: "square", R: SQ, seed: sd() });
  const sqPoly = rectPoly(SQ);
  props.push({ x: SQUARE.x + 13, z: SQUARE.z - 9, yaw: 0.3, kind: "cross" });
  props.push({ x: SQUARE.x - 15, z: SQUARE.z + 11, yaw: 0, kind: "pump" });
  trees.push({ x: SQUARE.x - 17, z: SQUARE.z - 11, kind: "hero", s: 1.0 });
  // Market stalls with striped awnings in two corners of the square.
  const AWN = ["#c8483a", "#2f7a5a", "#d8a83a", "#3e66a8", "#b8486a"];
  for (const [lx, lz, yaw] of [[8, 3, 0], [13.5, 3, 0], [19, 3, 0], [8, 9.5, Math.PI], [14, 9.5, Math.PI], [-22, -22, Math.PI / 2], [-22, -16.5, Math.PI / 2]] as const) {
    props.push({ x: SQUARE.x + lx, z: SQUARE.z + lz, yaw, kind: "stall", color: pick(r, AWN) });
  }

  // ---------------------------------------------------------------- the green
  const greenPath: [number, number][] = [];
  for (let i = 0; i <= 64; i++) {
    const a = (i / 64) * Math.PI * 2;
    greenPath.push([GREEN.x + Math.cos(a) * (GREEN.rx + 1.5), GREEN.z + Math.sin(a) * (GREEN.rz + 1.5)]);
  }
  const GR: Rect = { cx: GREEN.x, cz: GREEN.z, yaw: 0, x0: -GREEN.rx - 3, x1: GREEN.rx + 3, z0: -GREEN.rz - 3, z1: GREEN.rz + 3 };
  occ.each(GR, 0, (k) => {
    if (k < 0) return;
    const x = ((k % OG_N) + 0.5) * OG_CELL - OG_HALF, z = (Math.floor(k / OG_N) + 0.5) * OG_CELL - OG_HALF;
    if (Math.hypot((x - GREEN.x) / (GREEN.rx + 3.5), (z - GREEN.z) / (GREEN.rz + 3.5)) < 1 && occ.a[k] === Cell.free) occ.a[k] = Cell.keep;
  });
  paint.push({ kind: "green", R: GR, seed: sd() });
  trees.push({ x: GREEN.x - 10, z: GREEN.z + 3, kind: "hero", s: 1.3 });
  for (let i = 0; i < 5; i++) {
    const a = i * 1.25 + 0.5;
    trees.push({ x: GREEN.x + Math.cos(a) * (GREEN.rx - 7), z: GREEN.z + Math.sin(a) * (GREEN.rz - 6), kind: i % 2 ? "round" : "tall", s: range(r, 0.8, 1.05) });
  }

  // ---------------------------------------------------------------- church and churchyard
  const CY: Rect = { cx: CHURCH.x, cz: CHURCH.z, yaw: CHURCH.yaw, x0: -31, x1: 27, z0: -22, z1: 23 };
  occ.mark(CY, Cell.keep, 0.5);
  paint.push({ kind: "churchyard", R: CY, seed: sd() });
  {
    // Walls all round, the lychgate in the south wall; a path from it down to the east road.
    const P = rectPoly(CY);
    const gateA = W(CY, -3, CY.z1), gateB = W(CY, 3, CY.z1);
    bounds.push({ a: P[0], b: P[1], kind: "wall" }, { a: P[1], b: P[2], kind: "wall" }, { a: P[3], b: P[0], kind: "wall" });
    bounds.push({ a: P[2], b: gateB, kind: "wall" }, { a: gateA, b: P[3], kind: "wall" });
    const g = W(CY, 0, CY.z1);
    props.push({ x: g[0], z: g[1], yaw: CHURCH.yaw, kind: "lychgate" });
    // Path south to the street.
    let len = 4;
    while (len < 80) {
      const [px, pz] = W(CY, 0, CY.z1 + len);
      const rd = roadIndex.near(px, pz, 10);
      if (rd.d < rd.v) break;
      len += 1;
    }
    const PATH: Rect = { cx: CY.cx, cz: CY.cz, yaw: CY.yaw, x0: -1.3, x1: 1.3, z0: CY.z1, z1: CY.z1 + len };
    occ.mark(PATH, Cell.keep, 1.5);
    paint.push({ kind: "path", R: PATH, seed: sd() });
    // Yews along the walls and by the gate; the graves in rows south and east of the church.
    for (const [lx, lz, s] of [[-5.5, 19.5, 0.62], [5.5, 19.5, 0.6], [-27, -18, 0.75], [-27, 18, 0.7], [22, -18, 0.66], [13, -19, 0.58], [-14, 19, 0.55]] as const) {
      const [x, z] = W(CY, lx, lz);
      trees.push({ x, z, kind: "conifer", s, tint: 0.62 });
    }
    for (let row = 0; row < 3; row++) for (let k = 0; k < 9; k++) {
      if (r() < 0.2) continue;
      const lx = -24 + k * 2.6 + range(r, -0.3, 0.3), lz = 11 + row * 2.4;
      if (Math.abs(lx) < 3.5) continue;
      const [x, z] = W(CY, lx, lz);
      props.push({ x, z, yaw: CHURCH.yaw + range(r, -0.08, 0.08), kind: "grave" });
    }
    for (let row = 0; row < 4; row++) for (let k = 0; k < 4; k++) {
      if (r() < 0.25) continue;
      const [x, z] = W(CY, 17 + k * 2.2, -12 + row * 3.4);
      props.push({ x, z, yaw: CHURCH.yaw + range(r, -0.08, 0.08), kind: "grave" });
    }
  }

  // ---------------------------------------------------------------- frontage

  interface Run {
    left: number;
    core: boolean;
    d: number;
    h: number;
    pitch: number;
    setback: number;
    bound: Bound["kind"];
    gd: number;
    roof: string;
    detached: boolean;
  }

  const addHouse = (R: Rect, h: number, pitch: number, wall: string, roof: string, kind: HouseSpec["kind"], chimney = 0, annex = false) => {
    const w = R.x1 - R.x0, d = R.z1 - R.z0;
    const [cx, cz] = W(R, (R.x0 + R.x1) / 2, (R.z0 + R.z1) / 2);
    houses.push({ x: cx, z: cz, yaw: R.yaw, w, d, h, pitch, wall, roof, chimney, annex, y: footY(cx, cz, R.yaw, w, d), kind });
  };

  /** Bounds along three sides of a plot (left, back, right), with an optional gate gap in the back. */
  const hedgePlot = (R: Rect, kind: Bound["kind"], gate = false, front = false) => {
    const P = rectPoly(R); // 0:(x0,z0) 1:(x1,z0) 2:(x1,z1) 3:(x0,z1)
    bounds.push({ a: P[3], b: P[0], kind }, { a: P[1], b: P[2], kind });
    if (gate) {
      const m0 = W(R, (R.x0 + R.x1) / 2 - 1.6, R.z0), m1 = W(R, (R.x0 + R.x1) / 2 + 1.6, R.z0);
      bounds.push({ a: P[0], b: m0, kind }, { a: m1, b: P[1], kind });
    } else bounds.push({ a: P[0], b: P[1], kind });
    if (front) {
      const m0 = W(R, (R.x0 + R.x1) / 2 - 1.6, R.z1), m1 = W(R, (R.x0 + R.x1) / 2 + 1.6, R.z1);
      bounds.push({ a: P[3], b: m0, kind }, { a: m1, b: P[2], kind });
    }
  };

  const gardenTrees = (R: Rect, z0: number, z1: number, n: number) => {
    for (let k = 0; k < n; k++) {
      const [x, z] = W(R, range(r, R.x0 + 1.4, R.x1 - 1.4), range(r, z0, z1));
      trees.push({ x, z, kind: r() < 0.55 ? "round" : r() < 0.6 ? "bush" : "tall", s: range(r, 0.42, 0.72), tint: range(r, 0.85, 1.1) });
    }
  };

  const streets: { path: readonly P2[]; hw: number; loop?: [number, number] }[] = [];
  for (const p of ROAD_PATHS) streets.push({ path: p.path, hw: p.w / 2 });
  // The square's four sides (closed, outward only).
  streets.unshift({ path: [...sqPoly, sqPoly[0]], hw: 0, loop: [SQUARE.x, SQUARE.z] });
  streets.splice(1, 0, { path: greenPath, hw: 2.5, loop: [GREEN.x, GREEN.z] });

  for (const st of streets) {
    const P = st.path;
    const next: Record<number, number> = { [-1]: range(r, 0, 3), [1]: range(r, 0, 3) };
    const run: Record<number, Run | null> = { [-1]: null, [1]: null };
    let s = 0;
    for (let i = 0; i < P.length - 1; i++) {
      const [ax, az] = P[i], [bx, bz] = P[i + 1];
      const seg = Math.hypot(bx - ax, bz - az);
      if (seg < 1e-3) continue;
      const tx = (bx - ax) / seg, tz = (bz - az) / seg;
      for (let u = 0; u < seg; u += 0.5) {
        const sa = s + u;
        const x = ax + tx * u, z = az + tz * u;
        for (const side of st.loop ? [1] : [-1, 1]) {
          if (sa < next[side]) continue;
          let nx = -tz * side, nz = tx * side;
          if (st.loop && nx * (x - st.loop[0]) + nz * (z - st.loop[1]) < 0) [nx, nz] = [-nx, -nz];
          const dv = Math.hypot(x - VILLAGE.x, z - VILLAGE.z);
          if (dv > VILLAGE.r * 1.5) {
            next[side] = sa + 8;
            run[side] = null;
            continue;
          }
          let R0 = run[side];
          if (!R0 || R0.left <= 0) {
            const core = dv < 150;
            const detached = !core && r() < 0.55;
            R0 = run[side] = {
              left: core ? 2 + Math.floor(r() * 5) : detached ? 1 : 2,
              core,
              d: core ? range(r, 6.2, 7.8) : range(r, 6.6, 8.4),
              h: core ? range(r, 5.6, 7.0) : range(r, 4.6, 6.2),
              pitch: range(r, 0.66, 0.86),
              setback: core ? range(r, 0.4, 1.4) : range(r, 3.5, 7),
              bound: core ? (r() < 0.5 ? "wall" : "hedge") : r() < 0.7 ? "hedge" : "wall",
              gd: core ? range(r, 18, 32) : range(r, 20, 36),
              roof: roofColor(r),
              detached,
            };
          }
          const dens = dv < VILLAGE.r * 0.95 ? 0.97 : dv < VILLAGE.r * 1.15 ? 0.55 : 0.16;
          if (r() > dens) {
            next[side] = sa + range(r, 6, 16);
            R0.left = 0;
            continue;
          }
          const w = R0.core ? range(r, 5.6, 8.4) : range(r, 8, 11.5);
          const d = R0.d;
          // Detached houses sit in a wider plot with a side garden.
          const side0 = R0.detached ? range(r, 2.5, 5) : 0;
          const side1 = R0.detached ? range(r, 2.5, 5) : 0;
          const off = st.hw + 1.2 + R0.setback + d / 2;
          const yaw = Math.atan2(-nx, -nz);
          // Local +x runs along -side * tangent: the plot spans [sa, sa + width] along the street.
          const along = side0 + w / 2;
          const cx = x + nx * off + tx * along, cz = z + nz * off + tz * along;
          const sgn = -side; // local x = sgn * tangent
          const H: Rect = { cx, cz, yaw, x0: -w / 2, x1: w / 2, z0: -d / 2, z1: d / 2 };
          // Plot across the full frontage (side gardens included), mapped into local x.
          const px0 = sgn > 0 ? -w / 2 - side0 : -w / 2 - side1;
          const px1 = sgn > 0 ? w / 2 + side1 : w / 2 + side0;
          const tight = R0.core ? -0.3 : 0.6;
          if (!occ.free(H, tight) || (R0.setback > 2 && !occ.free({ ...H, x0: px0, x1: px1, z0: d / 2, z1: d / 2 + R0.setback - 0.5 }, -0.3))) {
            next[side] = sa + 1.5;
            R0.left = 0;
            continue;
          }
          occ.mark(H, Cell.house);
          const wall = R0.core && r() < 0.15 ? "#c98a6c" : pick(r, WALLS);
          const roof = r() < 0.75 ? R0.roof : roofColor(r);
          const chimney = r() < 0.85 ? (r() < 0.5 ? -1 : 1) : 0;
          addHouse(H, R0.h * range(r, 0.95, 1.05), R0.pitch, wall, roof, "cottage", chimney, !R0.core && r() < 0.3);
          // Front garden.
          if (R0.setback > 2) {
            const F: Rect = { ...H, x0: px0, x1: px1, z0: d / 2, z1: d / 2 + R0.setback - 0.4 };
            occ.mark(F, Cell.plot);
            paint.push({ kind: "front", R: F, seed: sd() });
            const P4 = rectPoly(F);
            const g0 = W(F, -1.0, F.z1), g1 = W(F, 1.0, F.z1);
            bounds.push({ a: P4[3], b: g0, kind: R0.bound }, { a: g1, b: P4[2], kind: R0.bound });
          }
          // Back garden: as deep as fits.
          for (const k of [1, 0.72, 0.5, 0.32]) {
            const gd = R0.gd * k;
            if (gd < 6) break;
            const Gd: Rect = { ...H, x0: px0, x1: px1, z0: -d / 2 - gd, z1: -d / 2 - 0.2 };
            if (!occ.free(Gd, -0.3)) continue;
            occ.mark(Gd, Cell.plot);
            const veg = r() < 0.62 ? range(r, 0.3, 0.55) : 0;
            paint.push({ kind: "garden", R: Gd, seed: sd(), veg, path: r() < 0.7 ? range(r, px0 + 1, px1 - 1) : NaN });
            hedgePlot(Gd, R0.bound, false);
            // Back extension: a lower wing with its ridge running back into the garden.
            if (r() < 0.5 && gd > 9) {
              const ew = Math.min(3.4, w * 0.45), ed = range(r, 2.8, 4.6);
              const ex = (r() < 0.5 ? -1 : 1) * (w / 2 - ew / 2 - 0.25);
              const [ecx, ecz] = W(H, ex, -d / 2 - ed / 2 + 0.3);
              addHouse({ cx: ecx, cz: ecz, yaw: yaw + Math.PI / 2, x0: -ed / 2, x1: ed / 2, z0: -ew / 2, z1: ew / 2 }, R0.h * 0.6, 0.62, wall, roof, "ext");
            }
            // Shed in a far corner, greenhouse now and then.
            if (gd > 10 && r() < 0.6) {
              const sx = (r() < 0.5 ? px0 + 1.6 : px1 - 1.6);
              const [scx, scz] = W(H, sx, -d / 2 - gd + 1.5);
              addHouse({ cx: scx, cz: scz, yaw, x0: -1.3, x1: 1.3, z0: -1.0, z1: 1.0 }, 2.0, 0.42, pick(r, ["#7a6248", "#6a5a44", "#8a7458", "#5e6a52"]), pick(r, ["#4a4440", "#5a4a3e", "#6a5040"]), "shed");
            } else if (gd > 12 && r() < 0.2) {
              const [gx, gz] = W(H, (px0 + px1) / 2 + range(r, -1, 1), -d / 2 - gd * 0.6);
              props.push({ x: gx, z: gz, yaw, kind: "greenhouse" });
            }
            gardenTrees(H, -d / 2 - gd * 0.92, -d / 2 - gd * 0.45, r() < 0.75 ? (r() < 0.4 ? 2 : 1) : 0);
            break;
          }
          next[side] = sa + side0 + w + side1 + (R0.core ? (R0.left > 1 ? -0.35 : range(r, 1.5, 5)) : R0.detached ? range(r, 2, 8) : R0.left > 1 ? 0 : range(r, 3, 8));
          R0.left--;
        }
      }
      s += seg;
    }
  }

  // ---------------------------------------------------------------- infill behind the streets

  const block = (x: number, z: number) => {
    const rd = roadIndex.near(x, z, 160);
    let yaw = r() * Math.PI;
    if (rd.i >= 0) {
      const sgs = roadIndex.seg, o = rd.i * 5;
      yaw = Math.atan2(sgs[o + 2] - sgs[o], sgs[o + 3] - sgs[o + 1]) + Math.PI / 2 + range(r, -0.08, 0.08);
    }
    const n = fbm(x / 90, z / 90, seed * 13 + 7, 2);
    const u = r();
    const kind: PaintKind = u < 0.2 ? "orchard" : u < 0.42 ? "paddock" : u < 0.58 ? "allot" : u < 0.72 ? "yard" : n > 0.55 || u < 0.86 ? "copse" : "meadow";
    const sizes: Record<string, [number, number]> = { orchard: [34, 28], paddock: [40, 32], allot: [34, 22], yard: [30, 26], copse: [24, 22], meadow: [36, 30] };
    const [w0, d0] = sizes[kind];
    for (const k of [1, 0.78, 0.6]) {
      const w = w0 * k * range(r, 0.85, 1.15), d = d0 * k * range(r, 0.85, 1.15);
      const R: Rect = { cx: x, cz: z, yaw, x0: -w / 2, x1: w / 2, z0: -d / 2, z1: d / 2 };
      if (!occ.free(R, 0.8)) continue;
      occ.mark(R, Cell.plot);
      paint.push({ kind, R, seed: sd() });
      const hedgeKind: Bound["kind"] = kind === "yard" || (kind === "allot" && r() < 0.5) ? "wall" : "hedge";
      if (kind !== "copse") hedgePlot(R, hedgeKind, true, true);
      if (kind === "orchard") {
        for (let lz = R.z0 + 3.5; lz < R.z1 - 2.5; lz += 6) for (let lx = R.x0 + 3.5; lx < R.x1 - 2.5; lx += 5.5) {
          if (r() < 0.1) continue;
          const [tx, tz] = W(R, lx + range(r, -0.4, 0.4), lz + range(r, -0.4, 0.4));
          trees.push({ x: tx, z: tz, kind: "round", s: range(r, 0.4, 0.52), tint: range(r, 1.02, 1.15) });
        }
      } else if (kind === "copse") {
        for (let t = 0, nt = 6 + Math.floor(r() * 7); t < nt; t++) {
          const [tx, tz] = W(R, range(r, R.x0 + 2, R.x1 - 2), range(r, R.z0 + 2, R.z1 - 2));
          trees.push({ x: tx, z: tz, kind: r() < 0.7 ? "round" : r() < 0.5 ? "tall" : "poplar", s: range(r, 0.8, 1.2), tint: range(r, 0.75, 1.0) });
        }
      } else if (kind === "yard") {
        // A barn along the back, a cart shed across one side.
        const bw = Math.min(w - 6, range(r, 16, 22)), bd = range(r, 8, 10);
        addHouse({ cx: x, cz: z, yaw, x0: -bw / 2, x1: bw / 2, z0: R.z0 + 1.5, z1: R.z0 + 1.5 + bd }, range(r, 5.5, 7), 0.68,
          pick(r, ["#8a4a34", "#6e4e36", "#a0583c", "#c8b896"]), pick(r, ["#5a5e66", "#6e5a4a", "#a84a34", "#7a6a5a"]), "barn");
        if (d > 24 && r() < 0.7) addHouse({ cx: x, cz: z, yaw: yaw + Math.PI / 2, x0: -R.z1 + 2, x1: -R.z1 + 2 + 10, z0: R.x1 - 6.5, z1: R.x1 - 1.5 }, 3.4, 0.45, "#7a6248", "#4e4a46", "shed");
      } else if (kind === "paddock") {
        if (r() < 0.6) addHouse({ cx: x, cz: z, yaw, x0: R.x1 - 9, x1: R.x1 - 1.5, z0: R.z0 + 1.5, z1: R.z0 + 5 }, 2.8, 0.4, "#6a5440", "#4a4440", "shed");
        if (r() < 0.6) {
          const [tx, tz] = W(R, range(r, R.x0 + 6, R.x1 - 6), range(r, R.z0 + 6, R.z1 - 6));
          trees.push({ x: tx, z: tz, kind: "round", s: range(r, 0.95, 1.3), tint: 0.9 });
        }
      } else if (kind === "allot") {
        for (let lx = R.x0 + 4; lx < R.x1 - 3; lx += 10) {
          if (r() < 0.55) addHouse({ cx: x, cz: z, yaw, x0: lx, x1: lx + 2.2, z0: R.z1 - 3.2, z1: R.z1 - 1.4 }, 1.9, 0.35, pick(r, ["#7a6248", "#5e6a52", "#8a7458", "#6a7a8a"]), "#4a4440", "shed");
        }
        if (r() < 0.5) {
          const [gx, gz] = W(R, range(r, R.x0 + 4, R.x1 - 4), R.z0 + 3);
          props.push({ x: gx, z: gz, yaw, kind: "greenhouse" });
        }
      } else if (kind === "meadow") {
        gardenTrees(R, R.z0 + 3, R.z1 - 3, 2);
      }
      return;
    }
  };
  {
    const STEP = 22;
    const cand: [number, number][] = [];
    for (let gz = -VILLAGE.r; gz <= VILLAGE.r; gz += STEP) for (let gx = -VILLAGE.r; gx <= VILLAGE.r; gx += STEP) {
      const x = VILLAGE.x + gx + range(r, -6, 6), z = VILLAGE.z + gz + range(r, -6, 6);
      if (Math.hypot(x - VILLAGE.x, z - VILLAGE.z) > VILLAGE.r * 1.02) continue;
      cand.push([x, z]);
    }
    // Inner candidates first, so the heart fills before the edge.
    cand.sort((a, b) => Math.hypot(a[0], a[1]) - Math.hypot(b[0], b[1]));
    for (const [x, z] of cand) {
      const k = occ.at(x, z);
      if (k >= 0 && occ.a[k] === Cell.free) block(x, z);
    }
    // A second, finer pass for the leftover gaps.
    for (let gz = -VILLAGE.r; gz <= VILLAGE.r; gz += 12) for (let gx = -VILLAGE.r; gx <= VILLAGE.r; gx += 12) {
      const x = VILLAGE.x + gx, z = VILLAGE.z + gz;
      if (Math.hypot(x, z) > VILLAGE.r * 0.98) continue;
      const k = occ.at(x, z);
      if (k >= 0 && occ.a[k] === Cell.free) block(x, z);
    }
    // Stray trees in what is still open (verges, corners), clumped.
    for (let gz = -VILLAGE.r; gz <= VILLAGE.r; gz += 9) for (let gx = -VILLAGE.r; gx <= VILLAGE.r; gx += 9) {
      const x = VILLAGE.x + gx + range(r, -3, 3), z = VILLAGE.z + gz + range(r, -3, 3);
      if (Math.hypot(x, z) > VILLAGE.r * 1.05) continue;
      const k = occ.at(x, z);
      if (k < 0 || occ.a[k] !== Cell.free) continue;
      const clump = fbm(x / 60, z / 60, seed * 3 + 41, 2);
      if (r() > (clump > 0.55 ? 0.5 : 0.12)) continue;
      trees.push({ x, z, kind: r() < 0.75 ? "round" : r() < 0.5 ? "tall" : "poplar", s: range(r, 0.7, 1.15) });
    }
  }

  // ---------------------------------------------------------------- farmsteads
  for (const f of FARMS) {
    const yard = rectPoly({ cx: f.x, cz: f.z, yaw: f.yaw, x0: -26, x1: 26, z0: -20, z1: 20 });
    shapes.push({ poly: yard, color: "#b8a47a", mown: 0, angle: f.yaw });
    const add = (lx: number, lz: number, yawOff: number, kind: HouseSpec["kind"], w: number, d: number, h: number) => {
      const [a, b] = rot(lx, lz, f.yaw);
      const x = f.x + a, z = f.z + b, yaw = f.yaw + yawOff;
      houses.push({
        x, z, yaw, w, d, h, pitch: kind === "barn" ? 0.7 : range(r, 0.62, 0.8),
        wall: kind === "barn" ? pick(r, ["#7a3a2c", "#6a4a32", "#8a4a34", "#5c4a3a"]) : kind === "shed" ? "#7a6248" : pick(r, WALLS),
        roof: kind === "barn" ? pick(r, ["#5a5e66", "#6e5a4a", "#a84a34"]) : roofColor(r),
        chimney: kind === "farmhouse" ? 1 : 0, annex: kind === "farmhouse" && r() < 0.5, y: footY(x, z, yaw, w, d), kind,
      });
    };
    add(-6, -13, 0, "farmhouse", range(r, 10, 12), 7.5, 6);
    add(10, 6, Math.PI / 2, "barn", range(r, 22, 28), 11, 7.5);
    add(-16, 10, Math.PI, "shed", 8, 5, 3.4);
    add(-22, -6, Math.PI / 2, "barn", range(r, 12, 16), 7, 5);
    for (let i = 0; i < 9; i++) {
      const [a, b] = rot(range(r, -40, 40), range(r, -42, -26), f.yaw);
      trees.push({ x: f.x + a, z: f.z + b, kind: r() < 0.8 ? "round" : "poplar", s: range(r, 0.85, 1.3) });
    }
  }

  const chimneys: THREE.Vector3[] = [];
  for (const h of houses) {
    if (!h.chimney) continue;
    const rise = (h.d / 2) * Math.tan(h.pitch);
    const [a, b] = rot(h.chimney * (h.w / 2 - 0.9), 0.5, h.yaw);
    chimneys.push(new THREE.Vector3(h.x + a, h.y + h.h + rise + 1.0, h.z + b));
  }
  return { houses, shapes, paint, bounds, props, chimneys, trees, noRoad: [sqPoly], greenPath };
}
