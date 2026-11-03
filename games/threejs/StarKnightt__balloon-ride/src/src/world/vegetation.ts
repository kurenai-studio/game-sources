/**
 * Trees and hedgerows across the countryside, all instanced.
 *
 * Every tree is one instance of a prototype per form (broadleaf, poplar, conifer, bush) at one of
 * three LODs: the reused painted card trees (flora/trees.ts, the Bay Ride crowns) close to the
 * camera, a lumpy blob crown on a trunk (toon foliage, ~250 tris) in the middle distance, and a
 * single faceted lump far off. Hedgerows are bushy strips along the parcel edges (two LODs; past
 * that the painted hedge line in the field map carries them). Instances live in 400 m tiles; each
 * refill (when the camera has moved or turned) culls tiles against the frustum, picks their LOD
 * and copies their matrices into one InstancedMesh per prototype and LOD, so the whole flora is
 * about 14 draw calls.
 */
import { TIER } from "../core/tier";
import * as THREE from "three";
import { mulberry32, range, type Rng } from "../core/rng";
import { ID, M, blob, merge, prep, spherize, xf, cyl } from "./geo";
import { uber } from "../render/materials";
import { LAYER_REFLECT, LAYER_SHADOW, onLayers } from "../render/lightpasses";
import { buildTrees, type TreeKind } from "../flora/trees";
import { foliageMaterial } from "../flora/glsl";
import { GRID_HALF, MAP_HALF, RIVER_PATH, WINDMILL, lakeDist, lakeShore, roadIndex } from "./layout";
import { groundHeight, riverAt } from "./heightfield";
import type { Edge, Parcel } from "./parcels";
import type { VillagePlan } from "./village";
import { hash2 } from "./noise";

type Form = 0 | 1 | 2 | 3; // broadleaf, poplar, conifer, bush
const FORMS = 4;

interface Spot {
  x: number;
  z: number;
  form: Form;
  s: number;
  yaw: number;
  tint: THREE.Color;
}

const TILE = 400;
const TN = Math.ceil((GRID_HALF * 2) / TILE);

/** LOD distance limits (m): card trees, blob trees, lumps. */
// The phone tier draws fewer trees: every distance and the card cap shrink with TIER.flora.
const TREE_LOD = [210, 950, 4600].map((v) => v * TIER.flora);
const HEDGE_LOD = [420, 1900].map((v) => v * Math.sqrt(TIER.flora));
const CARD_CAP = Math.round(520 * TIER.flora);

// ------------------------------------------------------------------ geometry helpers

export function pointInPoly(x: number, z: number, p: [number, number][]): boolean {
  let inside = false;
  for (let i = 0, j = p.length - 1; i < p.length; j = i++) {
    const [xi, zi] = p[i], [xj, zj] = p[j];
    if (zi > z !== zj > z && x < ((xj - xi) * (z - zi)) / (zj - zi) + xi) inside = !inside;
  }
  return inside;
}

export function edgeDist(x: number, z: number, p: [number, number][]): number {
  let d = Infinity;
  for (let i = 0; i < p.length; i++) {
    const [ax, az] = p[i], [bx, bz] = p[(i + 1) % p.length];
    const dx = bx - ax, dz = bz - az;
    const t = Math.max(0, Math.min(1, ((x - ax) * dx + (z - az) * dz) / (dx * dx + dz * dz || 1)));
    d = Math.min(d, Math.hypot(ax + dx * t - x, az + dz * t - z));
  }
  return d;
}

const GREENS = ["#3f7d3a", "#468a3c", "#3a7444", "#4f8a3a", "#437f40", "#2f6e4c", "#5b9a3e"];

/** Middle LOD: a lumpy crown of a few blobs on a short trunk, sized to the card tree's bounds. */
function blobTree(form: Form, box: THREE.Box3, seed: number): THREE.BufferGeometry {
  const r = mulberry32(seed);
  const W = Math.max(box.max.x - box.min.x, box.max.z - box.min.z), H = box.max.y;
  const parts: THREE.BufferGeometry[] = [];
  const trunkH = form === 3 ? 0.3 : form === 2 ? H * 0.18 : H * 0.42;
  parts.push(xf(cyl(0.18, 0.3, trunkH + 0.4, "#5b4634", M.bark, 5), 0, trunkH / 2 - 0.2, 0));
  const c = new THREE.Vector3(0, form === 3 ? H * 0.45 : H * 0.62, 0);
  const crown: THREE.BufferGeometry[] = [];
  if (form === 2) {
    // Conifer: stacked cones.
    for (let i = 0; i < 3; i++) {
      const g = prep(new THREE.ConeGeometry(W * 0.42 * (1 - i * 0.22), H * 0.42, 7, 1), "#2f5a45", M.foliage);
      crown.push(xf(g, 0, H * (0.32 + i * 0.22), 0));
    }
  } else {
    const n = form === 1 ? 3 : form === 3 ? 2 : 4;
    for (let i = 0; i < n; i++) {
      const rad = form === 1 ? W * 0.32 : W * range(r, 0.26, 0.34);
      const g = prep(blob(rad, 1, 0.2, r() * 40), GREENS[i % GREENS.length], M.foliage);
      const a = (i / n) * Math.PI * 2 + r();
      const off = form === 1 ? 0 : W * 0.2;
      const yy = form === 1 ? H * (0.4 + (i / (n - 1)) * 0.45) : c.y + range(r, -0.15, 0.25) * H * 0.4;
      if (form === 1) g.scale(1, 1.5, 1);
      crown.push(xf(g, Math.cos(a) * off, yy, Math.sin(a) * off));
    }
  }
  const cg = merge(crown);
  spherize(cg, c, 0.6, form === 1 ? 0.5 : 1);
  parts.push(cg);
  return merge(parts);
}

/** Far LOD: one faceted lump (or cone), no trunk. */
function lumpTree(form: Form, box: THREE.Box3): THREE.BufferGeometry {
  const W = Math.max(box.max.x - box.min.x, box.max.z - box.min.z), H = box.max.y;
  if (form === 2 || form === 1) {
    const g = prep(new THREE.ConeGeometry(W * (form === 1 ? 0.4 : 0.46), H * 0.92, 5, 1), form === 1 ? "#468a3c" : "#2f5a45", M.foliage);
    return xf(g, 0, H * 0.5, 0);
  }
  const g = prep(new THREE.IcosahedronGeometry(1, 0), "#437f40", M.foliage);
  g.scale(W * 0.52, H * 0.4, W * 0.52);
  return xf(g, 0, H * 0.58, 0);
}

/** Hedge strip, 7 m long (local x), ~2 m wide and ~2.3 m tall. */
function hedgeGeo(detail: boolean): THREE.BufferGeometry {
  if (!detail) {
    const g = prep(new THREE.IcosahedronGeometry(1, 0), "#3f7a3a", M.foliage);
    g.scale(3.9, 1.25, 1.15);
    return xf(g, 0, 1.0, 0);
  }
  const parts: THREE.BufferGeometry[] = [];
  const r = mulberry32(91);
  for (let i = 0; i < 3; i++) {
    const g = prep(blob(1.35, 1, 0.22, r() * 30), GREENS[(i * 3) % GREENS.length], M.foliage);
    g.scale(1.25, 0.95, 0.85);
    parts.push(xf(g, -2.4 + i * 2.4, 1.15 + range(r, -0.1, 0.2), range(r, -0.2, 0.2)));
  }
  const m = merge(parts);
  spherize(m, new THREE.Vector3(0, 0.4, 0), 0.45, 0.8);
  return m;
}

// ------------------------------------------------------------------ placement

interface Tile {
  box: THREE.Box3;
  /** Per form: instance matrices (16 floats each) and colours (3 each). */
  m: number[][];
  c: number[][];
  hm: number[];
  hc: number[];
}

export interface Vegetation {
  group: THREE.Group;
  /** Hedge runs as placed (gaps at roads and gates), for painting the field map. */
  hedgeLines: [number, number][][];
  update(camera: THREE.PerspectiveCamera): void;
  info(): Record<string, number>;
}

export async function buildVegetation(parcels: Parcel[], edges: Edge[], plan: VillagePlan, seed: number, pause: () => Promise<void>): Promise<Vegetation> {
  const r: Rng = mulberry32(seed * 4241 + 9);
  const spots: Spot[] = [];
  const hedges: { x: number; z: number; yaw: number; len: number }[] = [];

  // Houses and yards keep their ground clear.
  const houseHash = new Map<number, { x: number; z: number; r: number }[]>();
  const hk = (x: number, z: number) => Math.floor(x / 40) * 10007 + Math.floor(z / 40);
  for (const h of plan.houses) {
    const e = { x: h.x, z: h.z, r: Math.hypot(h.w, h.d) * 0.5 + (h.kind === "barn" ? 6 : 2.5) };
    for (let dx = -1; dx <= 1; dx++) for (let dz = -1; dz <= 1; dz++) {
      const k = hk(h.x + dx * 40, h.z + dz * 40);
      const l = houseHash.get(k) ?? [];
      l.push(e);
      houseHash.set(k, l);
    }
  }
  const clear = (x: number, z: number, pad = 2.5): boolean => {
    if (Math.abs(x) > GRID_HALF - 20 || Math.abs(z) > GRID_HALF - 20) return false;
    if (groundHeight(x, z) < 1.4) return false;
    // The windmill stands on a bald hilltop.
    if (Math.hypot(x - WINDMILL.x, z - WINDMILL.z) < 165) return false;
    const rd = roadIndex.near(x, z, 10);
    if (rd.d < rd.v + pad) return false;
    for (const e of houseHash.get(hk(x, z)) ?? []) if (Math.hypot(e.x - x, e.z - z) < e.r) return false;
    return true;
  };
  const tintOf = (k: number) => {
    const c = new THREE.Color();
    const u = r();
    // A spread round the authored greens: many deep dark crowns, some ochre-tinged (oak, ash
    // turning), a few blue-grey (willow, alder), the odd bright lime.
    if (u < 0.3) c.setRGB(range(r, 0.62, 0.78), range(r, 0.7, 0.84), range(r, 0.72, 0.9));
    else if (u < 0.44) c.setRGB(range(r, 1.18, 1.36), range(r, 1.0, 1.1), range(r, 0.6, 0.75));
    else if (u < 0.52) c.setRGB(range(r, 0.78, 0.9), range(r, 0.9, 1.0), range(r, 1.05, 1.2));
    else if (u < 0.56) c.setRGB(range(r, 1.1, 1.2), range(r, 1.12, 1.22), 0.8);
    else c.setRGB(range(r, 0.84, 1.04), range(r, 0.86, 1.02), range(r, 0.82, 1.02));
    return c.multiplyScalar(k);
  };
  const add = (x: number, z: number, form: Form, s: number, pad = 2.5, tk = 1) => {
    if (!clear(x, z, pad)) return;
    spots.push({ x, z, form, s, yaw: r() * Math.PI * 2, tint: tintOf(tk) });
  };

  for (const p of parcels) {
    const far = Math.max(Math.abs(p.cx), Math.abs(p.cz)) > MAP_HALF + 400;
    if (p.crop === "woods") {
      // Dense broadleaf woods with some conifers, ragged at the edge.
      let x0 = Infinity, x1 = -Infinity, z0 = Infinity, z1 = -Infinity;
      for (const [x, z] of p.poly) {
        x0 = Math.min(x0, x); x1 = Math.max(x1, x); z0 = Math.min(z0, z); z1 = Math.max(z1, z);
      }
      const sp = far ? 15 : 10.5;
      for (let z = z0; z < z1; z += sp) for (let x = x0; x < x1; x += sp) {
        const px = x + (r() - 0.5) * sp * 0.8, pz = z + (r() - 0.5) * sp * 0.8;
        if (!pointInPoly(px, pz, p.poly)) continue;
        const ed = edgeDist(px, pz, p.poly);
        if (ed < 2 + 6 * hash2(Math.round(px / 9), Math.round(pz / 9), 3)) continue;
        const con = groundHeight(px, pz) > 40 && r() < 0.45 ? 2 : r() < 0.12 ? 2 : 0;
        add(px, pz, con as Form, range(r, 1.2, 1.75) * (far ? 1.3 : 1), 1.5, range(r, 0.82, 1.02));
      }
      // Undergrowth bushes along the wood edge.
      if (!far) for (let i = 0; i < p.poly.length; i++) {
        const [ax, az] = p.poly[i], [bx, bz] = p.poly[(i + 1) % p.poly.length];
        const len = Math.hypot(bx - ax, bz - az);
        for (let t = 0; t < len; t += range(r, 9, 18)) {
          const k = t / len;
          add(ax + (bx - ax) * k, az + (bz - az) * k, 3, range(r, 1.4, 2.2));
        }
      }
    } else if (p.crop === "orchard") {
      // Rows of small round trees along the parcel's grain.
      const ca = Math.cos(p.angle), sa = Math.sin(p.angle);
      let u0 = Infinity, u1 = -Infinity, v0 = Infinity, v1 = -Infinity;
      for (const [x, z] of p.poly) {
        const u = x * ca + z * sa, v = -x * sa + z * ca;
        u0 = Math.min(u0, u); u1 = Math.max(u1, u); v0 = Math.min(v0, v); v1 = Math.max(v1, v);
      }
      for (let v = v0 + 4; v < v1; v += 8) for (let u = u0 + 4; u < u1; u += 7) {
        const x = u * ca - v * sa, z = u * sa + v * ca;
        if (!pointInPoly(x, z, p.poly) || edgeDist(x, z, p.poly) < 6) continue;
        if (!clear(x, z)) continue;
        spots.push({ x, z, form: 0, s: range(r, 0.5, 0.62), yaw: r() * 6.28, tint: new THREE.Color(range(r, 1.05, 1.2), range(r, 1.05, 1.15), 0.8) });
      }
    } else if (p.crop === "pasture" && !far && r() < 0.3) {
      // A lone tree or two standing out in the field.
      for (let i = 0, n = 1 + Math.floor(r() * 2); i < n; i++) {
        const x = p.cx + (r() - 0.5) * 60, z = p.cz + (r() - 0.5) * 60;
        if (pointInPoly(x, z, p.poly) && edgeDist(x, z, p.poly) > 12) add(x, z, 0, range(r, 1.1, 1.5));
      }
    }
  }
  await pause();

  // Hedgerows (with the odd tree standing in them) along hedged parcel edges.
  const seen = new Set<number>();
  const hedgeLines: [number, number][][] = [];
  for (const e of edges) {
    if (!e.hedge) continue;
    const [ax, az] = e.a, [bx, bz] = e.b;
    const len = Math.hypot(bx - ax, bz - az);
    const far = Math.max(Math.abs(ax), Math.abs(az)) > MAP_HALF + 600;
    const yaw = Math.atan2(-(bz - az), bx - ax);
    let run: [number, number][] = [];
    const flush = () => {
      if (run.length > 1) hedgeLines.push(run);
      run = [];
    };
    for (let t = 3.5; t < len - 2; t += 6.4) {
      const k = t / len;
      const x = ax + (bx - ax) * k, z = az + (bz - az) * k;
      const key = Math.round(x / 4) * 100003 + Math.round(z / 4);
      if (seen.has(key) || !clear(x, z, 2.2)) {
        flush();
        continue;
      }
      seen.add(key);
      // Field gates and gappy stretches at irregular spacing.
      if (hash2(Math.round(x / 6), Math.round(z / 6), 31) < 0.07) {
        flush();
        continue;
      }
      run.push([x, z]);
      if (!far) hedges.push({ x, z, yaw, len: 1 });
      if (hash2(Math.round(x), Math.round(z), 77) < 0.075) add(x + (r() - 0.5) * 2, z + (r() - 0.5) * 2, r() < 0.15 ? 1 : 0, range(r, 1.0, 1.45), 1);
    }
    flush();
  }

  // Willows and alders lining the river banks, following every bend, in groups with gaps; on the
  // inside of the bends a gravel bar (painted) and fewer trees.
  for (let i = 0; i < RIVER_PATH.length - 1; i++) {
    const [ax, az] = RIVER_PATH[i], [bx, bz] = RIVER_PATH[i + 1];
    if (Math.max(Math.abs(ax), Math.abs(az)) > GRID_HALF - 50) continue;
    const g = hash2(Math.floor(i / 6), 0, 51);
    if (g < 0.18) continue;
    const dx = bx - ax, dz = bz - az, l = Math.hypot(dx, dz) || 1;
    for (const side of [-1, 1]) {
      if (r() < 0.35) continue;
      const hw = riverAt(ax, az).hw;
      const o = hw + range(r, 4, 9);
      const x = ax - (dz / l) * o * side, z = az + (dx / l) * o * side;
      if (riverAt(x, z).d < hw + 3) continue;
      const willow = r() < 0.45;
      if (!clear(x, z, 1.5)) continue;
      spots.push({
        x, z, form: willow ? 0 : r() < 0.3 ? 1 : 0, s: willow ? range(r, 0.9, 1.25) : range(r, 1.0, 1.4), yaw: r() * 6.28,
        tint: willow ? new THREE.Color(range(r, 0.92, 1.02), range(r, 1.02, 1.1), range(r, 0.9, 1.0)) : tintOf(0.85),
      });
    }
  }
  // Lake shore: alder and willow clumps with gaps, reed beds (small yellow-green bushes) at the
  // water's edge.
  const shore = lakeShore(260);
  for (let i = 0; i < shore.length; i++) {
    const [x, z] = shore[i];
    const [nx0, nz0] = shore[(i + 1) % shore.length];
    const tx = nx0 - x, tz = nz0 - z, tl = Math.hypot(tx, tz) || 1;
    // Outward normal (the shore runs counter-clockwise round the lake).
    let ox = tz / tl, oz = -tx / tl;
    if (lakeDist(x + ox * 5, z + oz * 5) < lakeDist(x, z)) [ox, oz] = [-ox, -oz];
    if (hash2(Math.floor(i / 9), 3, 9) > 0.35) {
      for (let k = 0; k < 2; k++) {
        const o = range(r, 6, 22);
        const px = x + ox * o + range(r, -3, 3), pz = z + oz * o + range(r, -3, 3);
        if (lakeDist(px, pz) > 4) add(px, pz, r() < 0.2 ? 1 : 0, range(r, 0.9, 1.35), 2.5, 0.9);
      }
    }
    if (hash2(Math.floor(i / 6), 5, 13) > 0.3) {
      // Balloon Ride: denser, taller reed beds that read from 150 m up.
      for (let k = 0; k < 14; k++) {
        const o = range(r, -3, 5);
        const px = x + ox * o + range(r, -1.5, 1.5), pz = z + oz * o + range(r, -1.5, 1.5);
        if (groundHeight(px, pz) < -1.2 || groundHeight(px, pz) > 6) continue;
        spots.push({ x: px, z: pz, form: 3, s: range(r, 1.5, 2.3), yaw: r() * 6.28, tint: new THREE.Color(range(r, 1.3, 1.5), range(r, 1.15, 1.3), 0.5) });
      }
    }
  }
  // The village's own trees.
  const formOf: Record<string, Form> = { round: 0, hero: 0, tall: 0, poplar: 1, conifer: 2, bush: 3 };
  for (const t of plan.trees) {
    if (groundHeight(t.x, t.z) < 1.4) continue;
    spots.push({ x: t.x, z: t.z, form: formOf[t.kind] ?? 0, s: t.s * (t.kind === "hero" ? 1.4 : 1), yaw: r() * 6.28, tint: tintOf(t.tint ?? 1) });
  }
  await pause();

  // ---------------------------------------------------------------- prototypes
  const kinds: TreeKind[] = ["round", "poplar", "conifer", "bush"];
  const cards: THREE.BufferGeometry[] = [];
  for (const k of kinds) {
    const { group } = await buildTrees([{ name: k, spots: [{ x: 0, z: 0, kind: k, scale: 1, seed: 1234 + k.length }] }], () => 0);
    const g = (group.children[0] as THREE.Mesh).geometry;
    g.computeBoundingBox();
    cards.push(g);
  }
  const boxes = cards.map((g) => g.boundingBox!);
  const mids = kinds.map((_, f) => blobTree(f as Form, boxes[f], 77 + f));
  const lumps = kinds.map((_, f) => lumpTree(f as Form, boxes[f]));

  // ---------------------------------------------------------------- tiles
  const tiles: Tile[] = [];
  for (let j = 0; j < TN; j++) for (let i = 0; i < TN; i++) {
    const x0 = i * TILE - GRID_HALF, z0 = j * TILE - GRID_HALF;
    tiles.push({ box: new THREE.Box3(new THREE.Vector3(x0, Infinity, z0), new THREE.Vector3(x0 + TILE, -Infinity, z0 + TILE)), m: [[], [], [], []], c: [[], [], [], []], hm: [], hc: [] });
  }
  const tileOf = (x: number, z: number) => {
    const i = Math.min(TN - 1, Math.max(0, Math.floor((x + GRID_HALF) / TILE)));
    const j = Math.min(TN - 1, Math.max(0, Math.floor((z + GRID_HALF) / TILE)));
    return tiles[j * TN + i];
  };
  const mtx = new THREE.Matrix4(), q = new THREE.Quaternion(), up = new THREE.Vector3(0, 1, 0), v = new THREE.Vector3(), sc = new THREE.Vector3();
  for (const s of spots) {
    const y = groundHeight(s.x, s.z) - 0.25;
    const t = tileOf(s.x, s.z);
    mtx.compose(v.set(s.x, y, s.z), q.setFromAxisAngle(up, s.yaw), sc.set(s.s, s.s * range(r, 0.92, 1.1), s.s));
    t.m[s.form].push(...mtx.elements);
    t.c[s.form].push(s.tint.r, s.tint.g, s.tint.b);
    t.box.min.y = Math.min(t.box.min.y, y);
    t.box.max.y = Math.max(t.box.max.y, y + 14 * s.s);
  }
  for (const h of hedges) {
    const y = groundHeight(h.x, h.z) - 0.2;
    const t = tileOf(h.x, h.z);
    mtx.compose(v.set(h.x, y, h.z), q.setFromAxisAngle(up, h.yaw), sc.set(range(r, 0.92, 1.05), range(r, 0.8, 1.15), range(r, 0.85, 1.1)));
    t.hm.push(...mtx.elements);
    const tk = range(r, 0.85, 1.1);
    t.hc.push(tk * range(r, 0.92, 1.05), tk, tk * range(r, 0.85, 1.05));
    t.box.min.y = Math.min(t.box.min.y, y);
    t.box.max.y = Math.max(t.box.max.y, y + 4);
  }
  const tilesUsed = tiles.filter((t) => t.box.max.y > -Infinity);

  // ---------------------------------------------------------------- instanced meshes
  const group = new THREE.Group();
  group.name = "vegetation";
  const total = (f: number) => tilesUsed.reduce((s, t) => s + t.m[f].length / 16, 0);
  const totalH = tilesUsed.reduce((s, t) => s + t.hm.length / 16, 0);
  const foliage = foliageMaterial();
  // Card trees and blob crowns share the reused painted-foliage material (one palette near to mid);
  // the far lumps and the hedgerows take the inked uber foliage, darker, so woods and hedge lines
  // still read as dark masses and lines from altitude.
  const blobMat = foliage;
  const farMat = uber(ID.tree, 0.7);
  const mk = (g: THREE.BufferGeometry, mat: THREE.Material, n: number, name: string, shadow: boolean, refl: boolean) => {
    const im = new THREE.InstancedMesh(g, mat, Math.max(1, n));
    im.instanceColor = new THREE.InstancedBufferAttribute(new Float32Array(Math.max(1, n) * 3).fill(1), 3);
    im.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    im.instanceColor.setUsage(THREE.DynamicDrawUsage);
    im.count = 0;
    im.frustumCulled = false;
    im.name = name;
    if (shadow) onLayers(im, LAYER_SHADOW);
    if (refl) onLayers(im, LAYER_REFLECT);
    group.add(im);
    return im;
  };
  const L0 = kinds.map((k, f) => mk(cards[f], foliage, Math.min(CARD_CAP, total(f)), `trees ${k} cards`, true, false));
  const L1 = kinds.map((k, f) => mk(mids[f], blobMat, total(f), `trees ${k} blob`, true, true));
  const L2 = kinds.map((k, f) => mk(lumps[f], farMat, total(f), `trees ${k} lump`, false, false));
  const H0 = mk(hedgeGeo(true), farMat, totalH, "hedges near", true, false);
  const H1 = mk(hedgeGeo(false), farMat, totalH, "hedges far", false, false);

  const frustum = new THREE.Frustum(), pv = new THREE.Matrix4();
  const lastPos = new THREE.Vector3(1e9, 0, 0), lastQ = new THREE.Quaternion();
  const counts = { cards: 0, blobs: 0, lumps: 0, hedgeNear: 0, hedgeFar: 0 };
  const put = (im: THREE.InstancedMesh, src: number[], col: number[], from: number, n: number) => {
    const at = im.count;
    (im.instanceMatrix.array as Float32Array).set(src.slice(from * 16, (from + n) * 16), at * 16);
    (im.instanceColor!.array as Float32Array).set(col.slice(from * 3, (from + n) * 3), at * 3);
    im.count = at + n;
  };
  const putAll = (im: THREE.InstancedMesh, src: number[], col: number[]) => {
    const n = src.length / 16, at = im.count;
    (im.instanceMatrix.array as Float32Array).set(src, at * 16);
    (im.instanceColor!.array as Float32Array).set(col, at * 3);
    im.count = at + n;
  };

  return {
    group,
    hedgeLines,
    update(camera) {
      // Refill only when the view has changed noticeably.
      if (camera.position.distanceTo(lastPos) < 4 && camera.quaternion.angleTo(lastQ) < 0.02) return;
      lastPos.copy(camera.position);
      lastQ.copy(camera.quaternion);
      camera.updateMatrixWorld();
      frustum.setFromProjectionMatrix(pv.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse));
      for (const im of [...L0, ...L1, ...L2, H0, H1]) im.count = 0;
      const cam = camera.position;
      for (const t of tilesUsed) {
        if (!frustum.intersectsBox(t.box)) continue;
        const d = t.box.distanceToPoint(cam);
        if (d > TREE_LOD[2]) continue;
        for (let f = 0; f < FORMS; f++) {
          const src = t.m[f], n = src.length / 16;
          if (!n) continue;
          if (d < TREE_LOD[0]) {
            // Near tile: per-tree choice between card tree and blob.
            for (let k = 0; k < n; k++) {
              const o = k * 16;
              const dx = src[o + 12] - cam.x, dy = src[o + 13] - cam.y, dz = src[o + 14] - cam.z;
              const dd = Math.sqrt(dx * dx + dy * dy + dz * dz);
              put(dd < TREE_LOD[0] && L0[f].count < CARD_CAP ? L0[f] : L1[f], src, t.c[f], k, 1);
            }
          } else putAll(d < TREE_LOD[1] ? L1[f] : L2[f], src, t.c[f]);
        }
        if (t.hm.length && d < HEDGE_LOD[1]) {
          if (d < HEDGE_LOD[0]) {
            const n = t.hm.length / 16;
            for (let k = 0; k < n; k++) {
              const o = k * 16;
              const dd = Math.hypot(t.hm[o + 12] - cam.x, t.hm[o + 13] - cam.y, t.hm[o + 14] - cam.z);
              put(dd < HEDGE_LOD[0] ? H0 : H1, t.hm, t.hc, k, 1);
            }
          } else putAll(H1, t.hm, t.hc);
        }
      }
      for (const im of [...L0, ...L1, ...L2, H0, H1]) {
        im.instanceMatrix.needsUpdate = true;
        im.instanceColor!.needsUpdate = true;
      }
      counts.cards = L0.reduce((s, m) => s + m.count, 0);
      counts.blobs = L1.reduce((s, m) => s + m.count, 0);
      counts.lumps = L2.reduce((s, m) => s + m.count, 0);
      counts.hedgeNear = H0.count;
      counts.hedgeFar = H1.count;
    },
    info: () => ({ trees: spots.length, hedges: hedges.length, ...counts }),
  };
}

export { hedgeGeo };
