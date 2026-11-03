/**
 * The canonical landscape.
 *
 * Everything spatial in the realm derives from `height(x,z)` — the terrain
 * mesh, prop placement, the walk controller's feet, lava channel depth, water
 * level, camera collision. One analytic function, no baked texture, so it can
 * be sampled at any resolution and always agrees with itself.
 *
 * Layout (top-down, +x east, +z south):
 *
 *          N
 *      ▲ Ashmaw (main volcano)          ▲ Cinderhorn
 *            ╲ lava
 *   ▓ Castle   ╲                    ▉ cliff wall
 *   ruins       ● lava lake            ⌐ waterfall
 *        ══ bridge ══     ⌂⌂⌂ village    ~ river
 *              ▲▲ forest ▲▲    ⛩ temple ruins
 *          S
 */
import { noise } from '../utils/Noise.js';
import { clamp, smoothstep, lerp } from '../utils/MathX.js';

export const WORLD = {
  size: 2400,
  half: 1200,

  volcano:  { x: -300, z: -470, radius: 470, height: 392, craterR: 84, craterDepth: 54, rim: 26 },
  volcano2: { x:  580, z: -700, radius: 300, height: 236, craterR: 48, craterDepth: 30, rim: 16 },

  village:  { x:  180, z:  330, radius: 150, y: 36 },
  castle:   { x: -350, z:  240, radius: 135, y: 116 },
  temple:   { x: -140, z:  540, radius:  80, y: 26 },
  lavaLake: { x:  -70, z:  160, radius:  98, y: 14 },
  pool:     { x:  480, z:  150, radius:  72, y: 18 },
  falls:    { x:  556, z:  108, top: 196 },
  plaza:    { x:  180, z:  330 },
};

/** Molten channel: crater → lake → southern overflow. Shared with LavaRivers. */
export const LAVA_PATH = [
  [-300, -470], [-286, -382], [-262, -300], [-232, -214], [-190, -128],
  [-152,  -44], [-124,   36], [ -96,  104], [ -70,  160],
  [ -52,  228], [ -22,  296], [  14,  366], [  44,  452], [  40,  566], [  16,  700],
];

/** Meltwater river: falls pool → south, past the village's east flank. */
export const RIVER_PATH = [
  [480, 150], [452, 224], [416, 300], [382, 378], [352, 462], [336, 556], [344, 660], [330, 780],
];

export const LAVA_WIDTH  = 26;
export const RIVER_WIDTH = 22;

/* ── polyline helpers ─────────────────────────────────────────────────── */

/** Squared distance from (x,z) to a polyline, plus the parametric position along it. */
export function distToPath(path, x, z) {
  let best = Infinity, bestT = 0, acc = 0, total = 0, bestAcc = 0;
  for (let i = 0; i < path.length - 1; i++) {
    const [ax, az] = path[i], [bx, bz] = path[i + 1];
    total += Math.hypot(bx - ax, bz - az);
  }
  for (let i = 0; i < path.length - 1; i++) {
    const [ax, az] = path[i], [bx, bz] = path[i + 1];
    const dx = bx - ax, dz = bz - az;
    const len2 = dx * dx + dz * dz;
    const t = clamp(((x - ax) * dx + (z - az) * dz) / (len2 || 1), 0, 1);
    const px = ax + dx * t, pz = az + dz * t;
    const d = Math.hypot(x - px, z - pz);
    if (d < best) { best = d; bestT = t; bestAcc = acc + Math.sqrt(len2) * t; }
    acc += Math.sqrt(len2);
  }
  return { dist: best, along: bestAcc / (total || 1), t: bestT, total };
}

export function pathPoint(path, u) {
  const segs = [];
  let total = 0;
  for (let i = 0; i < path.length - 1; i++) {
    const l = Math.hypot(path[i + 1][0] - path[i][0], path[i + 1][1] - path[i][1]);
    segs.push(l); total += l;
  }
  let target = clamp(u, 0, 1) * total, acc = 0;
  for (let i = 0; i < segs.length; i++) {
    if (acc + segs[i] >= target || i === segs.length - 1) {
      const t = (target - acc) / (segs[i] || 1);
      return [
        lerp(path[i][0], path[i + 1][0], t),
        lerp(path[i][1], path[i + 1][1], t),
        Math.atan2(path[i + 1][0] - path[i][0], path[i + 1][1] - path[i][1]),
      ];
    }
    acc += segs[i];
  }
  return [path[0][0], path[0][1], 0];
}

/* ── the height function ──────────────────────────────────────────────── */

function volcanoCone(v, x, z) {
  const d = Math.hypot(x - v.x, z - v.z);
  if (d > v.radius * 1.45) return 0;

  // Concave (logarithmic) flank profile: steep dramatic upper cone, wide apron at the base.
  const k = clamp(1 - d / v.radius, 0, 1);
  let h = v.height * Math.pow(k, 1.65);

  const ang = Math.atan2(z - v.z, x - v.x);

  /**
   * Barrancas — the radial erosion gullies that are *the* signature of a
   * stratovolcano.
   *
   * The shape of these matters more than their depth. Water leaving a summit
   * runs straight down the fall line, so the channels are (a) strictly radial,
   * (b) V-shaped rather than sinusoidal, and (c) deepest at mid-flank, dying
   * out near the rim (no catchment yet) and near the base (the apron buries
   * them). The previous version used `max(0, simplex(...))` which zeroed
   * roughly half the circumference and left broad soft swells where the other
   * half should have been sharp channels — the mountain read as a sand dune.
   *
   * `1 - |cos|` gives a periodic V with cusps at the channel floors. Sampling
   * the *count* jitter from angle-space noise stops them being evenly spaced.
   */
  const chanJitter = noise.simplex2(Math.cos(ang * 3.0) * 2.2, Math.sin(ang * 3.0) * 2.2);
  const chanPhase = ang * 7.0 + chanJitter * 0.65;
  const vee = 1.0 - Math.abs(Math.cos(chanPhase));          // 0 at ridge, 1 in channel
  // Exponent kept just below 1. A sharper cusp (0.55 was tried) has an
  // effectively infinite derivative at the channel floor, and the terrain mesh
  // samples at ~9 m — so the cusp lands at a different sub-quad position on
  // every radial line and the surface breaks into hard visible triangles.
  // This profile is still V-ish but band-limited enough for the grid to hold.
  const veeSharp = smoothstep(0.0, 1.0, vee);

  // Depth envelope: nothing at the rim, maximum at mid-flank, buried at the base.
  const flank = smoothstep(0.05, 0.42, k) * smoothstep(0.95, 0.62, k);
  // Long-wavelength variation so not every channel is the same depth.
  const chanVary = 0.55 + 0.45 * (noise.fbm2(x * 0.0035, z * 0.0035, 3) * 0.5 + 0.5);
  h -= veeSharp * 27 * flank * chanVary;

  // The interfluves (ridges between channels) stand proud — same signal
  // inverted, weaker, and biased to the upper cone where they are freshest.
  const ridge = Math.pow(1.0 - vee, 1.8);
  h += ridge * 9 * smoothstep(0.10, 0.70, k) * chanVary;

  // Fine radial corrugation, one octave up, keeps the flanks from reading as
  // smooth ruled surfaces between the big channels.
  //
  // Angular frequency has to stay low enough that the *arc length* of one
  // period is comfortably wider than a terrain quad even on the upper cone,
  // where the radius — and therefore the arc length — is small. At ang*27 the
  // period shrank to ~23 m near the summit against a 9 m grid, which aliased
  // into jagged creases rather than corrugation.
  const fine = 1.0 - Math.abs(Math.cos(ang * 17.0 + chanJitter * 3.0));
  h -= fine * 2.5 * smoothstep(0.08, 0.42, k) * smoothstep(0.82, 0.5, k);

  // Terraced basalt strata: stepped ledges from successive flow units.
  const stepH = 16.0;
  const stepVal = Math.sin(h / stepH * Math.PI * 2.0);
  const terrace = smoothstep(-0.2, 0.6, stepVal) * 1.2 * smoothstep(0.2, 0.9, k);
  h += terrace;

  // 4. Parasitic Flank Vent (Cinder Cone on shoulder)
  if (v === WORLD.volcano) {
    const pd = Math.hypot(x - (v.x + 140), z - (v.z - 110));
    if (pd < 110) {
      const pk = clamp(1 - pd / 110, 0, 1);
      let ph = 65 * Math.pow(pk, 1.5);
      if (pd < 22) ph -= 28 * smoothstep(22, 5, pd);
      h += ph * 0.85;
    }
  }

  // 5. Summit crater: asymmetric rim, breached on one side, magmatic throat.
  if (d < v.craterR * 2.5) {
    /**
     * A real summit crater is never an even ring. One sector is always lower —
     * blown out by a lateral blast or collapsed and then drained by a lava
     * flow — and that breach is what makes a volcano read as a volcano rather
     * than as a hill with a dimple. The old rim was a uniform ridge plus
     * high-frequency `ridged2` spikes, which is why the summit looked like a
     * crown of loose black teeth stuck onto a cone.
     *
     * BREACH_DIR points the notch south-east, down toward the lava channel
     * that LAVA_PATH already runs from the crater, so the geology agrees with
     * the molten river leaving it.
     */
    const BREACH_DIR = -0.9;
    let dA = ang - BREACH_DIR;
    dA = Math.atan2(Math.sin(dA), Math.cos(dA));            // wrap to [-π, π]
    const breach = Math.exp(-Math.pow(dA / 0.62, 2));       // 1 inside the notch

    // Rim height: broad asymmetry from low-frequency angular noise, not spikes.
    const rimWave = noise.simplex2(Math.cos(ang * 2.0) * 1.8, Math.sin(ang * 2.0) * 1.8);
    const rimHeight = (v.rim + rimWave * 15) * (1 - breach * 0.92);
    const rimWeight = Math.exp(-Math.pow((d - v.craterR) / (v.craterR * 0.44), 2));
    h += rimHeight * rimWeight;

    // Stepped inner bowl dropping into the vent throat.
    if (d < v.craterR * 1.15) {
      const craterDepthRatio = smoothstep(v.craterR * 1.15, v.craterR * 0.1, d);
      const innerTerrace = Math.floor((1 - d / v.craterR) * 4.0) * 6.0;
      h -= (v.craterDepth + innerTerrace) * craterDepthRatio;

      // Central magmatic vent drop.
      if (d < v.craterR * 0.35) {
        h -= 35 * smoothstep(v.craterR * 0.35, 0, d);
      }
    }

    // Carry the breach downslope as a spillway, so the notch drains somewhere
    // instead of stopping dead at the rim.
    h -= breach * 26 * smoothstep(v.craterR * 0.9, v.craterR * 2.4, d)
                     * smoothstep(v.craterR * 3.2, v.craterR * 1.6, d);
  }

  return h;
}

/** Eastern escarpment — the cliff wall the waterfall pours off. */
function escarpment(x, z) {
  const edge = 560 + noise.simplex2(z * 0.0035, 11.7) * 70 + noise.simplex2(z * 0.011, 4.2) * 22;
  const t = smoothstep(edge - 46, edge + 90, x);
  const top = 210 + noise.fbm2(x * 0.004, z * 0.004, 4) * 70;
  // Notch where the river cuts through, so the falls have a spout.
  const notch = Math.exp(-Math.pow((z - WORLD.falls.z) / 62, 2)) * smoothstep(edge + 120, edge - 40, x);
  return t * top * (1 - notch * 0.72);
}

/** North-west massif: jagged ridges, keeps the horizon interesting. */
function massif(x, z) {
  const t = smoothstep(-260, -820, z) * smoothstep(240, -520, x);
  if (t <= 0) return 0;
  const r = noise.ridged2(x * 0.0026 + 3.3, z * 0.0026 - 1.1, 6);
  return t * (75 + r * 215);
}

/** A steep-sided mesa for the ruined castle. */
function castleSpur(x, z) {
  const c = WORLD.castle;
  const d = Math.hypot(x - c.x, z - c.z);
  const wob = noise.simplex2(x * 0.01, z * 0.01) * 16;
  const t = smoothstep(c.radius * 2.15 + wob, c.radius * 0.72, d);
  return t * c.y * 0.92;
}

function flattenTo(h, x, z, spot, inner = 0.55, outer = 1.25, targetY = spot.y) {
  const d = Math.hypot(x - spot.x, z - spot.z);
  const w = smoothstep(spot.radius * outer, spot.radius * inner, d);
  return lerp(h, targetY, w);
}

/** Carve a channel: returns the (negative) depth to add and the bank shoulder. */
function carve(path, width, x, z, depth, bank) {
  const { dist } = distToPath(path, x, z);
  if (dist > width * 4.5) return 0;
  const cut = smoothstep(width * 2.4, width * 0.35, dist) * depth;
  const shoulder = Math.exp(-Math.pow((dist - width * 1.9) / (width * 1.1), 2)) * bank;
  return shoulder - cut;
}

export function height(x, z) {
  // Rolling base with domain warp so the low ground never looks like fbm.
  let h = 22 + noise.warp2(x * 0.00085, z * 0.00085, 0.9) * 46;
  h += noise.fbm2(x * 0.0042, z * 0.0042, 4) * 13;
  h += noise.fbm2(x * 0.019, z * 0.019, 3) * 3.2;

  h += volcanoCone(WORLD.volcano, x, z);
  h += volcanoCone(WORLD.volcano2, x, z);
  h += escarpment(x, z);
  h += massif(x, z);
  h += castleSpur(x, z);

  // Southern forest basin sits low and wet.
  h -= smoothstep(300, 760, z) * 16;

  // Coastline. The previous raised rim closed the horizon, but it also made
  // the entire realm read as a square island floating in empty space. Sink the
  // terrain beneath sea level on an irregular, radial shore instead. The
  // ocean surface covers the submerged part of the grid, so the land now has
  // a believable coast with a continuous horizon rather than a hard world edge.
  const radial = Math.hypot(x, z);
  const shoreNoise = noise.fbm2(x * 0.0021 + 17.3, z * 0.0021 - 9.7, 4) * 58
    + noise.simplex2(x * 0.006, z * 0.006) * 24;
  const shore = 1010 + shoreNoise;
  const coast = smoothstep(shore - 150, shore + 190, radial);
  h = lerp(h, -18, coast);

  // Channels.
  h += carve(LAVA_PATH,  LAVA_WIDTH,  x, z, 20, 7);
  h += carve(RIVER_PATH, RIVER_WIDTH, x, z, 16, 5);

  // Basins & platforms.
  h = flattenTo(h, x, z, WORLD.lavaLake, 0.5, 1.35, WORLD.lavaLake.y - 7);
  h = flattenTo(h, x, z, WORLD.pool,     0.5, 1.3,  WORLD.pool.y - 9);
  h = flattenTo(h, x, z, WORLD.village,  0.52, 1.4);
  h = flattenTo(h, x, z, WORLD.temple,   0.5, 1.5);
  h = flattenTo(h, x, z, WORLD.castle,   0.34, 0.85, WORLD.castle.y);

  return h;
}

/* ── derived queries ─────────────────────────────────────────────────── */

export function normalAt(x, z, e = 2.5) {
  const hL = height(x - e, z), hR = height(x + e, z);
  const hD = height(x, z - e), hU = height(x, z + e);
  const nx = hL - hR, nz = hD - hU, ny = 2 * e;
  const l = Math.hypot(nx, ny, nz) || 1;
  return [nx / l, ny / l, nz / l];
}

/** 0 = flat, 1 = vertical. */
export function slopeAt(x, z, e = 3) {
  return 1 - normalAt(x, z, e)[1];
}

export const lavaProximity = (x, z) => {
  const d = distToPath(LAVA_PATH, x, z).dist;
  const lake = Math.hypot(x - WORLD.lavaLake.x, z - WORLD.lavaLake.z) - WORLD.lavaLake.radius;
  return Math.max(
    smoothstep(LAVA_WIDTH * 3.2, LAVA_WIDTH * 0.8, d),
    smoothstep(180, 0, lake),
  );
};

export const isOnLava = (x, z) =>
  distToPath(LAVA_PATH, x, z).dist < LAVA_WIDTH * 1.1 ||
  Math.hypot(x - WORLD.lavaLake.x, z - WORLD.lavaLake.z) < WORLD.lavaLake.radius;

export const isOnWater = (x, z) =>
  distToPath(RIVER_PATH, x, z).dist < RIVER_WIDTH * 1.15 ||
  Math.hypot(x - WORLD.pool.x, z - WORLD.pool.z) < WORLD.pool.radius;

export const inVillage = (x, z, pad = 0) =>
  Math.hypot(x - WORLD.village.x, z - WORLD.village.z) < WORLD.village.radius + pad;

/** Where trees are allowed: not molten, not paved, not vertical, not too high. */
export function canPlant(x, z) {
  const h = height(x, z);
  if (h < 6 || h > 210) return false;
  if (slopeAt(x, z, 6) > 0.42) return false;
  if (lavaProximity(x, z) > 0.35) return false;
  if (isOnWater(x, z)) return false;
  if (inVillage(x, z, 16)) return false;
  return true;
}

/** Where a building can sit: flat-ish and dry. */
export function canBuild(x, z) {
  if (slopeAt(x, z, 8) > 0.2) return false;
  if (isOnLava(x, z) || isOnWater(x, z)) return false;
  return true;
}
