/**
 * The terrain heightfield: gentle rolling country (deterministic value-noise fbm), a broad
 * floodplain along the river, the village levelled, a hill under the windmill, a hollow for the
 * lake, and the river channel and lake basin carved below the water level. Everything dry stays
 * well above WATER_Y, so one flat water surface at y = 0 shows exactly where the land dips under it.
 *
 * Sampled once on a regular grid (GRID_HALF, STEP); `groundHeight` is a bilinear read of that grid
 * (the analytic base outside it), so terrain meshes, props and the balloon agree.
 */
import { GRID_HALF, LAKE, RIVER_PATH, VILLAGE, VILLAGE_Y, WATER_Y, WINDMILL, lakeDist, riverHalfWidth, riverIndex } from "./layout";
import { fbm, smooth } from "./noise";

/** Grid spacing (m) and vertices per side. */
export const STEP = 6.25;
export const N = Math.round((GRID_HALF * 2) / STEP) + 1;

let SEED = 1;

/** Rolling base land, no water or village (also the far ring's height). */
export function baseHeight(x: number, z: number): number {
  const s = SEED * 7919;
  const broad = (fbm(x / 1500, z / 1500, s + 11, 4) - 0.5) * 2;
  const mid = (fbm(x / 420, z / 420, s + 23, 3) - 0.5) * 2;
  const fine = (fbm(x / 110, z / 110, s + 37, 2) - 0.5) * 2;
  // Rounded ridges (folded noise) give the downs their shoulders.
  const ridge = 1 - Math.abs((fbm(x / 900, z / 900, s + 51, 3) - 0.5) * 2);
  // (Value-noise fbm sits mostly within +-0.3 of its mean, so the gains are large.)
  return 34 + broad * 80 + mid * 36 + ridge * ridge * 26 + fine * 3;
}

// ------------------------------------------------------------------ coarse river distance (chamfer)

const CS = 20;
const CN = Math.round((GRID_HALF * 2) / CS) + 1;
let coarse: Float32Array | null = null;

function buildCoarseRiver(): Float32Array {
  const d = new Float32Array(CN * CN).fill(1e9);
  // Exact distances to path samples near the path, then two chamfer sweeps.
  for (const [px, pz] of RIVER_PATH) {
    const cx = Math.round((px + GRID_HALF) / CS), cz = Math.round((pz + GRID_HALF) / CS);
    for (let j = cz - 3; j <= cz + 3; j++) for (let i = cx - 3; i <= cx + 3; i++) {
      if (i < 0 || j < 0 || i >= CN || j >= CN) continue;
      const x = i * CS - GRID_HALF, z = j * CS - GRID_HALF;
      const v = Math.hypot(x - px, z - pz);
      if (v < d[j * CN + i]) d[j * CN + i] = v;
    }
  }
  const a = CS, b = CS * Math.SQRT2;
  for (let j = 0; j < CN; j++) for (let i = 0; i < CN; i++) {
    let v = d[j * CN + i];
    if (i > 0) v = Math.min(v, d[j * CN + i - 1] + a);
    if (j > 0) {
      v = Math.min(v, d[(j - 1) * CN + i] + a);
      if (i > 0) v = Math.min(v, d[(j - 1) * CN + i - 1] + b);
      if (i < CN - 1) v = Math.min(v, d[(j - 1) * CN + i + 1] + b);
    }
    d[j * CN + i] = v;
  }
  for (let j = CN - 1; j >= 0; j--) for (let i = CN - 1; i >= 0; i--) {
    let v = d[j * CN + i];
    if (i < CN - 1) v = Math.min(v, d[j * CN + i + 1] + a);
    if (j < CN - 1) {
      v = Math.min(v, d[(j + 1) * CN + i] + a);
      if (i < CN - 1) v = Math.min(v, d[(j + 1) * CN + i + 1] + b);
      if (i > 0) v = Math.min(v, d[(j + 1) * CN + i - 1] + b);
    }
    d[j * CN + i] = v;
  }
  return d;
}

/** Approximate distance to the river centreline (m), smooth over hundreds of metres. */
export function riverDistCoarse(x: number, z: number): number {
  const c = coarse!;
  const fx = Math.min(CN - 1.001, Math.max(0, (x + GRID_HALF) / CS)), fz = Math.min(CN - 1.001, Math.max(0, (z + GRID_HALF) / CS));
  const i = Math.floor(fx), j = Math.floor(fz), u = fx - i, v = fz - j;
  const o = j * CN + i;
  return (c[o] * (1 - u) + c[o + 1] * u) * (1 - v) + (c[o + CN] * (1 - u) + c[o + CN + 1] * u) * v;
}

/** River centreline distance and local half-width; exact near the river. */
export function riverAt(x: number, z: number): { d: number; hw: number } {
  const dc = riverDistCoarse(x, z);
  if (dc > 90) return { d: dc, hw: 11 };
  const q = riverIndex.near(x, z, 120);
  return q.i < 0 ? { d: dc, hw: 11 } : { d: q.d, hw: q.v };
}

const smax = (a: number, b: number, k: number) => {
  const h = Math.max(k - Math.abs(a - b), 0) / k;
  return Math.max(a, b) + h * h * k * 0.25;
};

/** The full analytic height (used to fill the grid). */
function heightAt(x: number, z: number): number {
  let h = baseHeight(x, z);
  const r = riverAt(x, z);
  // Floodplain: the land eases down to ~3.5 m over the last few hundred metres to the river.
  const plain = 3.2 + 1.2 * fbm(x / 260, z / 260, SEED * 31 + 5, 2);
  h = plain + (h - plain) * smooth(30, 340, r.d) ** 1.1;
  // The village sits on a gently levelled shelf.
  const dv = Math.hypot(x - VILLAGE.x, z - VILLAGE.z);
  const vk = smooth(VILLAGE.r * 0.55, VILLAGE.r * 1.7, dv);
  const shelf = VILLAGE_Y + 1.2 * (fbm(x / 90, z / 90, SEED * 41 + 3, 2) - 0.5) - 1.5 * smooth(160, 40, r.d);
  h = shelf + (h - shelf) * vk;
  // Windmill hill.
  const dm = Math.hypot(x - WINDMILL.x, z - WINDMILL.z) / WINDMILL.hillR;
  h += WINDMILL.hill * Math.exp(-dm * dm * 2.2);
  // Lake hollow: the land settles toward a low shore around it.
  const ld = lakeDist(x, z);
  const shore = 3.4;
  h = shore + (h - shore) * smooth(5, 320, ld);
  // Dry land never drops near the water level (keeps one flat water plane honest, and far depth precise).
  h = smax(h, 2.6, 1.5);
  // River channel and lake basin, carved below the water.
  const ck = smooth(r.hw - 5, r.hw + 8, r.d);
  h = -2.4 + (h + 2.4) * ck;
  const lk = smooth(-16, 9, ld);
  h = -3.2 + (h + 3.2) * lk;
  return h;
}

/** Height for the far ring outside the grid: the base land with the river's floodplain. */
export function farHeight(x: number, z: number): number {
  let d = Infinity;
  for (let i = 0; i < RIVER_PATH.length; i += 6) {
    const p = RIVER_PATH[i];
    const e = (p[0] - x) ** 2 + (p[1] - z) ** 2;
    if (e < d) d = e;
  }
  d = Math.sqrt(d);
  const h = baseHeight(x, z), plain = 3.6;
  return plain + (h - plain) * smooth(30, 520, d) ** 1.2;
}

// ------------------------------------------------------------------ the grid

export let heights: Float32Array = new Float32Array(0);

/** Build the heightfield (call once at boot). */
export function buildHeightfield(seed = 1): void {
  SEED = seed;
  coarse = buildCoarseRiver();
  heights = new Float32Array(N * N);
  for (let j = 0; j < N; j++) {
    const z = j * STEP - GRID_HALF;
    for (let i = 0; i < N; i++) heights[j * N + i] = heightAt(i * STEP - GRID_HALF, z);
  }
}

/** Grid height at integer vertex (i, j), clamped to the grid. */
export function hAt(i: number, j: number): number {
  i = i < 0 ? 0 : i >= N ? N - 1 : i;
  j = j < 0 ? 0 : j >= N ? N - 1 : j;
  return heights[j * N + i];
}

/** Ground height at (x, z), matching the terrain mesh's triangles (bilinear within a cell). */
export function groundHeight(x: number, z: number): number {
  const fx = (x + GRID_HALF) / STEP, fz = (z + GRID_HALF) / STEP;
  if (fx < 0 || fz < 0 || fx > N - 1 || fz > N - 1) return baseHeight(x, z);
  const i = Math.min(N - 2, Math.floor(fx)), j = Math.min(N - 2, Math.floor(fz));
  const u = fx - i, v = fz - j;
  const o = j * N + i, h = heights;
  // Same split as the terrain mesh (diagonal from (i+1, j) to (i, j+1)).
  if (u + v <= 1) return h[o] + (h[o + 1] - h[o]) * u + (h[o + N] - h[o]) * v;
  return h[o + N + 1] + (h[o + N] - h[o + N + 1]) * (1 - u) + (h[o + 1] - h[o + N + 1]) * (1 - v);
}

/** Ground slope (rise over run) at (x, z). */
export function groundSlope(x: number, z: number): number {
  const e = STEP;
  const dx = groundHeight(x + e, z) - groundHeight(x - e, z);
  const dz = groundHeight(x, z + e) - groundHeight(x, z - e);
  return Math.hypot(dx, dz) / (2 * e);
}

/** True where the ground is under water (or right at its edge). */
export const isWet = (x: number, z: number, margin = 0.8) => groundHeight(x, z) < WATER_Y + margin;

export { LAKE };
