// Coastal regions the road passes through. Each lasts about three kilometres and blends into the
// next over a few hundred metres. The order is a seeded shuffle, so a long drive visits all of
// them in varying order and never repeats a region back to back.
import { rng, hash2, smoothstep } from './noise.js';

// shape: rise = road height above the base level, shoulder = flat strip past the asphalt,
// drop = horizontal distance from the shoulder down to the waterline, steep = how quickly the
// ground falls away (1 = straight slope, 3 = cliff), hills = scale of the land-side hills,
// terrace = flat land beside the road for buildings, rough = rockiness of slopes and shore.
// scatter: [type, zone, expected count per 80 m chunk].
export const BIOMES = {
  tropical: {
    name: 'Palm Beach',
    shape: { rise: 0, shoulder: 1.5, drop: 17, steep: 1.0, hills: 0.9, terrace: 0, rough: 0.2 },
    tint: {},
    scatter: [
      ['palm', 'beach', 6], ['palm', 'roadside', 3], ['tree', 'hills', 22], ['pine', 'hills', 5], ['bush', 'hillsNear', 6],
      ['rock', 'shore', 4], ['umbrella', 'beach', 1.4], ['beachHut', 'beach', 0.5], ['boat', 'sea', 0.45],
      ['island', 'far', 0.14], ['post', 'rail', 1], ['pier', 'shore', 0.08], ['sign', 'roadside', 0.1],
    ],
  },
  cliffs: {
    name: 'Cypress Cliffs',
    shape: { rise: 16, shoulder: 2.5, drop: 13, steep: 3.2, hills: 1.2, terrace: 0, rough: 0.9 },
    tint: { grass: [0.02, -0.12, 0.0], rock: [0.0, -0.3, 0.12], sand: [0.0, -0.05, -0.03] },
    scatter: [
      ['cypress', 'roadside', 4], ['cypress', 'hills', 10], ['olive', 'hills', 10], ['bush', 'hillsNear', 8],
      ['rock', 'shore', 8], ['house', 'hillsNear', 1.0], ['post', 'rail', 2], ['boat', 'sea', 0.5],
      ['island', 'far', 0.2], ['lighthouse', 'shore', 0.05],
    ],
  },
  pines: {
    name: 'Pine Coast',
    shape: { rise: 6, shoulder: 2, drop: 9, steep: 2.0, hills: 1.9, terrace: 0, rough: 0.6 },
    tint: { sand: [0.0, -0.45, -0.1], grass: [0.04, -0.1, -0.08], rock: [0.0, -0.25, -0.02] },
    scatter: [
      ['pine', 'hills', 38], ['pine', 'roadside', 4], ['rock', 'shore', 10], ['rock', 'beach', 3], ['bush', 'hillsNear', 5],
      ['lighthouse', 'shore', 0.08], ['boat', 'sea', 0.3], ['island', 'far', 0.18], ['post', 'rail', 1], ['sign', 'roadside', 0.08],
    ],
  },
  village: {
    name: 'Harbour Village',
    shape: { rise: 1.5, shoulder: 2.5, drop: 12, steep: 1.3, hills: 0.8, terrace: 42, rough: 0.2 },
    tint: {},
    scatter: [
      ['house', 'terrace', 5], ['lamp', 'road', 1], ['palm', 'roadside', 1], ['tree', 'hills', 12], ['bush', 'terrace', 4],
      ['flowers', 'terrace', 3], ['boat', 'harbour', 1.3], ['pier', 'shore', 0.35], ['umbrella', 'beach', 1],
      ['beachHut', 'beach', 0.3], ['sign', 'roadside', 0.3], ['rock', 'shore', 2],
    ],
  },
  dunes: {
    name: 'Dune Flats',
    shape: { rise: 0.6, shoulder: 2, drop: 30, steep: 0.85, hills: 0.35, terrace: 0, rough: 0.5 },
    tint: { grass: [-0.03, -0.15, 0.06], sand: [0.01, 0.05, 0.05] },
    scatter: [
      ['grassTuft', 'beach', 24], ['grassTuft', 'hills', 40], ['fence', 'fence', 1], ['cactus', 'hills', 3], ['bush', 'hills', 6],
      ['palm', 'beach', 0.8], ['umbrella', 'beach', 0.6], ['rock', 'shore', 1], ['boat', 'sea', 0.25],
      ['island', 'far', 0.1], ['post', 'rail', 1],
    ],
  },
  meadow: {
    name: 'Turbine Meadows',
    shape: { rise: 4, shoulder: 2, drop: 11, steep: 2.0, hills: 0.75, terrace: 0, rough: 0.3 },
    tint: { grass: [0.02, 0.06, 0.03] },
    scatter: [
      ['flowers', 'hills', 18], ['flowers', 'hillsNear', 8], ['bush', 'hills', 8], ['tree', 'hills', 10],
      ['turbine', 'hillsMid', 0.8], ['fence', 'fence', 0.6], ['house', 'hillsNear', 0.3], ['rock', 'shore', 5],
      ['post', 'rail', 1], ['boat', 'sea', 0.3],
    ],
  },
};

export const BIOME_IDS = Object.keys(BIOMES);
const SHAPE_KEYS = Object.keys(BIOMES.tropical.shape);

const SEG = 2800;   // average region length (m)
const BLEND = 450;  // crossfade length (m)
const S0 = 1000;    // offset so the drive starts well inside the first region

// Deterministic shuffle per cycle of six regions; cycle 0 always opens on the palm beach.
const orders = new Map();
function rawOrder(c) {
  const r = rng((c * 9176 + 7) >>> 0);
  const o = BIOME_IDS.slice();
  for (let i = o.length - 1; i > 0; i--) {
    const j = Math.floor(r() * (i + 1));
    [o[i], o[j]] = [o[j], o[i]];
  }
  if (c === 0) {
    const k = o.indexOf('tropical');
    [o[0], o[k]] = [o[k], o[0]];
  }
  return o;
}
function cycleOrder(c) {
  let o = orders.get(c);
  if (o) return o;
  o = rawOrder(c);
  // Never start a cycle with the region the previous one ended on.
  if (c !== 0 && o[0] === rawOrder(c - 1)[o.length - 1]) [o[0], o[1]] = [o[1], o[0]];
  orders.set(c, o);
  return o;
}

export function biomeOfSegment(k) {
  const n = BIOME_IDS.length, c = Math.floor(k / n);
  return cycleOrder(c)[k - c * n];
}

// Distance (s = -z + S0) where segment k starts.
function boundary(k) {
  return k * SEG + (k === 0 ? 0 : (hash2(k, 77) - 0.5) * 900);
}

function segmentAt(s) {
  let k = Math.floor(s / SEG);
  if (s < boundary(k)) k--;
  else if (s >= boundary(k + 1)) k++;
  return k;
}

// Blend of at most two regions at world z. Pass `out` to avoid allocating.
export function biomeMix(z, out = { a: null, b: null, w: 0, shape: {} }) {
  const s = -z + S0, k = segmentAt(s);
  const toStart = s - boundary(k), toEnd = boundary(k + 1) - s, half = BLEND / 2;
  out.a = biomeOfSegment(k);
  out.b = null;
  out.w = 0;
  if (toStart < half) { out.b = biomeOfSegment(k - 1); out.w = 0.5 * (1 - smoothstep(0, 1, toStart / half)); }
  else if (toEnd < half) { out.b = biomeOfSegment(k + 1); out.w = 0.5 * (1 - smoothstep(0, 1, toEnd / half)); }
  const A = BIOMES[out.a].shape, B = out.b ? BIOMES[out.b].shape : A;
  for (const key of SHAPE_KEYS) out.shape[key] = A[key] + (B[key] - A[key]) * out.w;
  return out;
}

export function dominantBiome(z) {
  const m = biomeMix(z);
  return m.w > 0.5 ? m.b : m.a;
}

// World z where the next stretch of `id` begins, searching in the travel direction (dir -1 = toward -z).
export function nextBiomeZ(z, id, dir = -1) {
  const s = -z + S0, k0 = segmentAt(s), step = dir < 0 ? 1 : -1;
  for (let i = 1; i < 60; i++) {
    const k = k0 + i * step;
    if (biomeOfSegment(k) === id) return -(step > 0 ? boundary(k) + BLEND : boundary(k + 1) - BLEND) + S0;
  }
  return z;
}
