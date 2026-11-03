/**
 * Patchwork fields: a Voronoi tessellation of a jittered seed grid (exact cells by half-plane
 * clipping), with some cells split into long strips, each parcel given a crop (pasture, mown hay,
 * wheat, barley, rapeseed, lavender, plough, stubble, young crop), a row direction along its
 * longest side, and a role (field, woods, orchard, village). Edges remember the two parcels they
 * separate so hedgerows can be drawn once per shared edge.
 */
import { mulberry32, type Rng } from "../core/rng";
import { GRID_HALF, VILLAGE, WINDMILL, lakeDist } from "./layout";
import { fbm, hash2 } from "./noise";
import { riverAt } from "./heightfield";

export type Crop = "pasture" | "mown" | "wheat" | "barley" | "rape" | "lavender" | "plough" | "stubble" | "young" | "woods" | "orchard" | "village";

export interface Parcel {
  id: number;
  poly: [number, number][];
  cx: number;
  cz: number;
  area: number;
  crop: Crop;
  /** Base colour (sRGB hex). */
  color: string;
  /** Broad mown stripes 0..1, fine furrows / rows 0..1. */
  mown: number;
  furrow: number;
  /** Row direction (radians, 0..PI). */
  angle: number;
  /** Grazing animals: none, sheep or cows. */
  stock: "none" | "sheep" | "cows";
}

export interface Edge {
  a: [number, number];
  b: [number, number];
  /** The parcels on either side (-1 = none). */
  p: number;
  q: number;
  hedge: boolean;
}

const SPACING = 560;

/** Jittered seed of grid cell (i, j), with gentle regional stretching so fields aren't all alike. */
function seedAt(i: number, j: number, seed: number): [number, number] {
  const jx = hash2(i, j, seed * 3 + 1) - 0.5, jz = hash2(i, j, seed * 3 + 2) - 0.5;
  return [(i + 0.5 + jx * 0.9) * SPACING - GRID_HALF, (j + 0.5 + jz * 0.9) * SPACING - GRID_HALF];
}

type Poly = { pts: [number, number][] };

/** Clip a convex polygon by the half-plane n·p <= c (Sutherland-Hodgman). */
function clip(poly: Poly, nx: number, nz: number, c: number): Poly {
  const out: [number, number][] = [];
  const P = poly.pts, n = P.length;
  for (let i = 0; i < n; i++) {
    const A = P[i], B = P[(i + 1) % n];
    const da = A[0] * nx + A[1] * nz - c, db = B[0] * nx + B[1] * nz - c;
    if (da <= 0) out.push(A);
    if ((da <= 0) !== (db <= 0)) {
      const t = da / (da - db);
      out.push([A[0] + (B[0] - A[0]) * t, A[1] + (B[1] - A[1]) * t]);
    }
  }
  return { pts: out };
}

function area(p: [number, number][]): number {
  let s = 0;
  for (let i = 0; i < p.length; i++) {
    const a = p[i], b = p[(i + 1) % p.length];
    s += a[0] * b[1] - b[0] * a[1];
  }
  return s / 2;
}

function centroid(p: [number, number][]): [number, number] {
  let x = 0, z = 0, A = 0;
  for (let i = 0; i < p.length; i++) {
    const a = p[i], b = p[(i + 1) % p.length];
    const k = a[0] * b[1] - b[0] * a[1];
    A += k;
    x += (a[0] + b[0]) * k;
    z += (a[1] + b[1]) * k;
  }
  return A === 0 ? p[0] : [x / (3 * A), z / (3 * A)];
}

/** Split a convex polygon by the line through `c` with normal (nx, nz). */
function split(p: Poly, cx: number, cz: number, nx: number, nz: number): [Poly, Poly] {
  const c = cx * nx + cz * nz;
  return [clip(p, nx, nz, c), clip(p, -nx, -nz, -c)];
}

/** Woods mask: high, broken ground, plus a few belts; 0..1. */
export function woodsMask(x: number, z: number, seed: number): number {
  return fbm(x / 620, z / 620, seed * 13 + 77, 3);
}

interface CropDef { crop: Crop; w: number; colors: string[]; mown: number; furrow: number }
const CROPS: CropDef[] = [
  { crop: "pasture", w: 36, colors: ["#5f9a3c", "#6aa443", "#4f8c3a", "#78a848", "#86b452", "#4a8a3e", "#5c9447"], mown: 0, furrow: 0 },
  { crop: "mown", w: 11, colors: ["#9fbb5c", "#b0c268", "#93b456"], mown: 1, furrow: 0 },
  { crop: "wheat", w: 14, colors: ["#d9b25a", "#e0bd68", "#cfa64c", "#d6b864"], mown: 0, furrow: 0.35 },
  { crop: "barley", w: 6, colors: ["#e2cf8c", "#d8c27a"], mown: 0, furrow: 0.3 },
  { crop: "rape", w: 5, colors: ["#e6cc2c", "#edd640"], mown: 0, furrow: 0.15 },
  { crop: "lavender", w: 3, colors: ["#8a68d0", "#9a74d4", "#7e62c4"], mown: 0, furrow: 1 },
  { crop: "plough", w: 10, colors: ["#8a6040", "#7c5538", "#946a46"], mown: 0, furrow: 1 },
  { crop: "stubble", w: 6, colors: ["#cdb27a", "#c4a86c"], mown: 0.55, furrow: 0.25 },
  { crop: "young", w: 5, colors: ["#86b04e", "#7aa64a"], mown: 0, furrow: 0.8 },
];
const CROP_W = CROPS.reduce((s, c) => s + c.w, 0);

function pickCrop(r: Rng): CropDef {
  let u = r() * CROP_W;
  for (const c of CROPS) if ((u -= c.w) <= 0) return c;
  return CROPS[0];
}

/** Direction (0..PI) of the polygon's longest edge. */
function longestDir(p: [number, number][]): number {
  let best = 0, ang = 0;
  for (let i = 0; i < p.length; i++) {
    const a = p[i], b = p[(i + 1) % p.length];
    const l = Math.hypot(b[0] - a[0], b[1] - a[1]);
    if (l > best) {
      best = l;
      ang = Math.atan2(b[1] - a[1], b[0] - a[0]);
    }
  }
  return ((ang % Math.PI) + Math.PI) % Math.PI;
}

export interface ParcelSet {
  parcels: Parcel[];
  edges: Edge[];
}

export function buildParcels(seed = 1): ParcelSet {
  const r = mulberry32(seed * 977 + 3);
  const G = Math.ceil((GRID_HALF * 2) / SPACING);
  const cells: Poly[] = [];
  const B = GRID_HALF + 200;
  for (let j = 0; j < G; j++) for (let i = 0; i < G; i++) {
    const [sx, sz] = seedAt(i, j, seed);
    let poly: Poly = { pts: [[-B, -B], [B, -B], [B, B], [-B, B]] };
    for (let dj = -2; dj <= 2; dj++) for (let di = -2; di <= 2; di++) {
      if (!di && !dj) continue;
      const ni = i + di, nj = j + dj;
      if (ni < 0 || nj < 0 || ni >= G || nj >= G) continue;
      const [ox, oz] = seedAt(ni, nj, seed);
      const nx = ox - sx, nz = oz - sz;
      const c = (nx * (ox + sx) + nz * (oz + sz)) / 2;
      poly = clip(poly, nx, nz, c);
      if (poly.pts.length < 3) break;
    }
    if (poly.pts.length < 3) continue;
    cells.push(poly);
  }

  // Each macro cell is one farm's land: cut recursively into fields along the farm's own grain
  // (mostly straight cuts across the longer side, jittered), down to a size drawn per piece, so
  // the patchwork has big pastures, middling arable and narrow strips side by side.
  const polys: { poly: Poly }[] = [];
  const cut = (p: Poly, grain: number, depth: number) => {
    const A = Math.abs(area(p.pts));
    const [cx, cz] = centroid(p.pts);
    const dv = Math.hypot(cx - VILLAGE.x, cz - VILLAGE.z);
    const target = dv < VILLAGE.r * 1.1 ? 30000 : 6000 + r() * r() * 52000;
    if (A < target || depth > 7 || p.pts.length < 3) {
      polys.push({ poly: p });
      return;
    }
    // Extent along the grain and across it: cut across the longer one.
    const gx = Math.cos(grain), gz = Math.sin(grain);
    let a0 = Infinity, a1 = -Infinity, b0 = Infinity, b1 = -Infinity;
    for (const [x, z] of p.pts) {
      const u = x * gx + z * gz, v = -x * gz + z * gx;
      a0 = Math.min(a0, u); a1 = Math.max(a1, u); b0 = Math.min(b0, v); b1 = Math.max(b1, v);
    }
    const alongLonger = a1 - a0 > (b1 - b0) * (0.8 + r() * 0.5);
    const ang = (alongLonger ? grain : grain + Math.PI / 2) + (r() - 0.5) * 0.35;
    const nx = Math.cos(ang), nz = Math.sin(ang);
    const span = alongLonger ? a1 - a0 : b1 - b0;
    const off = (r() - 0.5) * span * 0.36;
    const [p1, p2] = split(p, cx + nx * off, cz + nz * off, nx, nz);
    for (const q of [p1, p2]) if (q.pts.length >= 3 && Math.abs(area(q.pts)) > 400) cut(q, grain, depth + 1);
  };
  for (const p of cells) {
    const [cx, cz] = centroid(p.pts);
    // The grain turns slowly across the country (farms near each other share it roughly).
    const grain = (fbm(cx / 1800, cz / 1800, seed * 5 + 9, 2) - 0.5) * 4.5 + (r() - 0.5) * 0.5;
    cut(p, grain, 0);
  }

  const parcels: Parcel[] = [];
  for (const { poly } of polys) {
    const [cx, cz] = centroid(poly.pts);
    const A = Math.abs(area(poly.pts));
    const dv = Math.hypot(cx - VILLAGE.x, cz - VILLAGE.z);
    const wm = woodsMask(cx, cz, seed);
    const dm = Math.hypot(cx - WINDMILL.x, cz - WINDMILL.z);
    const river = riverAt(cx, cz).d;
    let def = pickCrop(r);
    let crop: Crop = def.crop;
    let color = def.colors[Math.floor(r() * def.colors.length)];
    let mown = def.mown, furrow = def.furrow;
    if (dv < VILLAGE.r * 0.95) {
      crop = "village";
      color = "#78a64a";
      mown = 0;
      furrow = 0;
    } else if (wm > 0.62 && dm > 200 && lakeDist(cx, cz) > 60 && river > 60) {
      crop = "woods";
      color = "#2e5a2c";
      mown = furrow = 0;
    } else if (dv < 700 && r() < 0.12 && river > 50) {
      crop = "orchard";
      color = "#7aa84a";
      mown = 0.4;
      furrow = 0;
    } else if (river < 120 && r() < 0.6) {
      // Water meadows: lush pasture along the river.
      def = CROPS[0];
      crop = "pasture";
      color = ["#5a9a40", "#4f9240", "#66a446"][Math.floor(r() * 3)];
      mown = furrow = 0;
    }
    // Pale grass under the windmill on its hill.
    if (dm < 160 && crop !== "village") {
      crop = "pasture";
      color = dm < 110 ? "#a6c466" : "#8cb854";
      mown = furrow = 0;
    }
    const stock: Parcel["stock"] = crop === "pasture" && A > 6000 ? (r() < 0.45 ? "sheep" : r() < 0.25 ? "cows" : "none") : "none";
    parcels.push({ id: parcels.length, poly: poly.pts, cx, cz, area: A, crop, color, mown, furrow, angle: longestDir(poly.pts), stock });
  }

  // Edges: each polygon edge once (shared edges are found by matching midpoints).
  const edges: Edge[] = [];
  const seen = new Map<string, number>();
  const key = (x: number, z: number) => `${Math.round(x * 2)},${Math.round(z * 2)}`;
  for (const p of parcels) {
    const P = p.poly;
    for (let i = 0; i < P.length; i++) {
      const a = P[i], b = P[(i + 1) % P.length];
      if (Math.hypot(b[0] - a[0], b[1] - a[1]) < 2) continue;
      const k = key((a[0] + b[0]) / 2, (a[1] + b[1]) / 2);
      const e = seen.get(k);
      if (e !== undefined) {
        edges[e].q = p.id;
        continue;
      }
      seen.set(k, edges.length);
      edges.push({ a, b, p: p.id, q: -1, hedge: false });
    }
  }
  for (const e of edges) {
    const P = parcels[e.p], Q = e.q >= 0 ? parcels[e.q] : null;
    const wood = P.crop === "woods" && (!Q || Q.crop === "woods");
    const vill = P.crop === "village" && (!Q || Q.crop === "village");
    const mx = (e.a[0] + e.b[0]) / 2, mz = (e.a[1] + e.b[1]) / 2;
    // Most field boundaries are hedged; within the woods or the village there are none.
    e.hedge = !wood && !vill && hash2(Math.round(mx), Math.round(mz), seed + 5) < 0.72;
  }
  return { parcels, edges };
}

