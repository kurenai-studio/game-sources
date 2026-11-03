/**
 * The village meshes (the plan is villageplan.ts): cottages with pitched tiled roofs, eaves, gable
 * overhangs and chimneys (windows and doors painted in the shader), back extensions, sheds and barns,
 * hedges and low stone walls round every plot, the churchyard's graves and lychgate, the market cross
 * and pump, the church with its tower and spire, the windmill on its hill (sails turn) and the stone
 * arch bridge.
 *
 * Static buildings are merged: one mesh per LOD (detailed near, simple far). The church and the
 * windmill are their own meshes: they swell a little with distance (a gentle scale bias) so the two
 * landmarks still read from 500 m up and a few kilometres off.
 */
import * as THREE from "three";
import { ID, M, boxM, cyl, merge, prep, setMat, xf } from "./geo";
import { uber } from "../render/materials";
import { LAYER_REFLECT, LAYER_SHADOW, onLayers } from "../render/lightpasses";
import { BRIDGE, CHURCH, LAKE, ROAD_PATHS, VILLAGE, WINDMILL, lakeShore } from "./layout";
import { groundHeight, riverAt } from "./heightfield";
import { rot, type Bound, type HouseSpec, type Prop, type VillagePlan } from "./villageplan";
import { mulberry32, range } from "../core/rng";

export { planVillage } from "./villageplan";
export type { HouseSpec, VillagePlan } from "./villageplan";

// ------------------------------------------------------------------ geometry

type Geo = THREE.BufferGeometry;

/** Walls with gable ends: front (+z, with the door), back, and two pentagon sides. */
function walls(w: number, d: number, h: number, rise: number, color: string, front: boolean): Geo {
  const pos: number[] = [], uv: number[] = [];
  const quad = (p: number[][], u: number[][]) => {
    for (const k of [0, 1, 2, 0, 2, 3]) {
      pos.push(...p[k]);
      uv.push(...u[k]);
    }
  };
  const code = (L: number, fr: boolean) => 200 * (Math.max(1, Math.round(L)) + (fr ? 50 : 0));
  const y0 = -1.2, hw = w / 2, hd = d / 2;
  // Front (+z) and back (-z): u across the wall, centred.
  const cf = code(w, front), cb = code(w, false);
  quad([[-hw, y0, hd], [hw, y0, hd], [hw, h, hd], [-hw, h, hd]], [[-hw + cf, y0], [hw + cf, y0], [hw + cf, h], [-hw + cf, h]]);
  quad([[hw, y0, -hd], [-hw, y0, -hd], [-hw, h, -hd], [hw, h, -hd]], [[-hw + cb, y0], [hw + cb, y0], [hw + cb, h], [-hw + cb, h]]);
  // Sides (pentagons): no windows in the gable triangle (k = 0 there would read as no wall), so side code.
  const cs = code(d, false);
  for (const sx of [-1, 1]) {
    const x = sx * hw;
    const zA = sx > 0 ? hd : -hd, zB = -zA;
    const uA = sx > 0 ? -hd : -hd, uB = hd;
    quad([[x, y0, zA], [x, y0, zB], [x, h, zB], [x, h, zA]], [[uA + cs, y0], [uB + cs, y0], [uB + cs, h], [uA + cs, h]]);
    pos.push(x, h, zA, x, h, zB, x, h + rise, 0);
    // Gable triangle: windows-free (high v is above both storeys only on tall gables).
    uv.push(uA + cs, 7.5, uB + cs, 7.5, cs, 7.5);
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
  g.computeVertexNormals();
  return prep(g, color, M.wall);
}

/** Two roof slabs with eaves and gable overhang (tile uv in metres). */
function roof(w: number, d: number, h: number, pitch: number, color: string): Geo[] {
  const oh = 0.55, og = 0.4, t = 0.22;
  const sl = (d / 2 + oh) / Math.cos(pitch);
  const rise = (d / 2) * Math.tan(pitch);
  const out: Geo[] = [];
  for (const side of [1, -1]) {
    const g = boxM(w + og * 2, t, sl, color, M.tile);
    const th = side * pitch;
    // Ridge point, then half the slab down the slope and half its thickness out.
    const sy = -Math.sin(pitch), sz = side * Math.cos(pitch);
    const ny = Math.cos(pitch), nz = side * Math.sin(pitch);
    const cy = h + rise + 0.06 + sy * (sl / 2 - 0.08) + ny * (t / 2);
    const cz = sz * (sl / 2 - 0.08) + nz * (t / 2);
    xf(g, 0, cy, cz, th, 0, 0);
    out.push(g);
  }
  // Ridge cap.
  out.push(xf(boxM(w + og * 2 + 0.05, 0.22, 0.34, color, M.tile), 0, h + rise + 0.2, 0));
  return out;
}

function houseGeo(hs: HouseSpec, detail: boolean): Geo[] {
  const rise = (hs.d / 2) * Math.tan(hs.pitch);
  const parts: Geo[] = [];
  const add = (w: number, d: number, h: number, ox: number, oz: number, front: boolean) => {
    const r2 = (d / 2) * Math.tan(hs.pitch);
    parts.push(xf(walls(w, d, h, r2, hs.wall, front), ox, 0, oz));
    if (detail) for (const g of roof(w, d, h, hs.pitch, hs.roof)) parts.push(xf(g, ox, 0, oz));
    else {
      // Far: a simple prism roof without overhang slabs.
      const g = new THREE.CylinderGeometry(0.01, 1, 1, 3, 1);
      g.rotateZ(Math.PI / 2);
      g.rotateY(Math.PI / 2);
      const pg = prep(g, hs.roof, M.tile);
      pg.scale(w + 0.8, r2 * 2 + 0.3, d + 1.1);
      parts.push(xf(pg, ox, h + r2 * 0.33, oz, 0, Math.PI / 2, 0));
    }
  };
  add(hs.w, hs.d, hs.h, 0, 0, hs.kind === "cottage" || hs.kind === "farmhouse");
  if (hs.annex) {
    const aw = hs.w * 0.55, ad = hs.d * 0.8, ah = hs.h * 0.7;
    add(aw, ad, ah, (hs.w / 2 + aw / 2 - 0.3) * (hs.chimney >= 0 ? -1 : 1), -hs.d * 0.12, false);
  }
  if (hs.chimney && detail) {
    const cx = hs.chimney * (hs.w / 2 - 0.9);
    const top = hs.h + rise + 1.0;
    parts.push(xf(boxM(0.8, top - hs.h, 0.8, "#9a5a44", M.stone), cx, hs.h + (top - hs.h) / 2, 0.5));
    parts.push(xf(boxM(0.98, 0.16, 0.98, "#6a4a3c", M.stone), cx, top, 0.5));
  }
  for (const g of parts) xf(g, hs.x, hs.y, hs.z, 0, hs.yaw, 0);
  return parts;
}

/** The church in its own frame (west tower at -x): nave, chancel, porch, tower, stone spire. */
function church(): Geo[] {
  const parts: Geo[] = [];
  const stone = "#d8cba6", slate = "#4e5a6c";
  const nave: HouseSpec = { x: 0, z: 0, yaw: 0, w: 26, d: 11, h: 9, pitch: 0.82, wall: stone, roof: slate, chimney: 0, annex: false, y: 0, kind: "barn" };
  parts.push(...houseGeo(nave, true));
  // Chancel: lower, narrower, at the east end; a south porch.
  parts.push(...houseGeo({ ...nave, w: 8, d: 7.5, h: 6.4, x: 15.5 }, true));
  parts.push(...houseGeo({ ...nave, w: 3.6, d: 4, h: 3.6, x: -4, z: 7.2, yaw: 0, pitch: 0.7 }, true));
  // Tower at the west end: buttressed, with a parapet and a tall pale stone spire that catches the sun.
  const T = 24;
  parts.push(xf(boxM(6.6, T, 6.6, "#e2d6b4", M.stone), -15, T / 2 - 1, 0));
  for (const [bx, bz] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) parts.push(xf(boxM(1.2, T * 0.55, 1.2, "#d0c29c", M.stone), -15 + bx * 3.3, T * 0.27 - 1, bz * 3.3));
  parts.push(xf(boxM(7.4, 0.9, 7.4, "#cbbd98", M.stone), -15, T - 0.6, 0));
  // Belfry openings: dark slots on each face.
  for (const [ox, oz, w, d] of [[0, 3.32, 1.4, 0.05], [0, -3.32, 1.4, 0.05], [3.32, 0, 0.05, 1.4], [-3.32, 0, 0.05, 1.4]]) {
    parts.push(xf(boxM(w, 2.6, d, "#2a2622", M.plain), -15 + ox, T - 4.5, oz));
  }
  const SP = 22;
  const sp = prep(new THREE.ConeGeometry(3.7, SP, 8, 1), "#e8dcc0", M.stone);
  parts.push(xf(sp, -15, T + SP / 2 - 0.4, 0, 0, Math.PI / 8, 0));
  parts.push(xf(cyl(0.08, 0.08, 2.6, "#d8b040", M.metal, 4), -15, T + SP + 0.8, 0));
  return parts;
}

/** Windmill tower and cap (static, its own frame); the sails are their own mesh so they can turn. */
function windmill(yaw: number): { body: Geo[]; sails: Geo; hub: THREE.Vector3 } {
  const body: Geo[] = [];
  body.push(xf(cyl(2.9, 4.5, 16, "#f6f1e6", M.plaster, 10), 0, 8, 0));
  body.push(xf(cyl(5.0, 5.0, 0.4, "#6a5440", M.planks, 10), 0, 5.6, 0)); // reefing stage
  const cap = prep(new THREE.SphereGeometry(3.5, 12, 6, 0, Math.PI * 2, 0, Math.PI / 2), "#4a3a30", M.tile);
  cap.scale(1, 0.95, 1.3);
  body.push(xf(cap, 0, 16, 0));
  body.push(xf(boxM(2.4, 2.4, 1.0, "#4a3a30", M.planks), 0, 17.3, 3.2));
  const door = boxM(1.3, 2.2, 0.1, "#3a2c22", M.planks);
  body.push(xf(door, 0, 1.1, 4.4, -0.1, 0, 0));
  for (const g of body) xf(g, 0, 0, 0, 0, yaw, 0);
  // Sails: four stocks with lattice sail cloth, built around the hub, turning about local z.
  const s: Geo[] = [];
  s.push(prep(new THREE.CylinderGeometry(0.5, 0.5, 1.0, 8).rotateX(Math.PI / 2), "#3a2c22", M.planks));
  for (let k = 0; k < 4; k++) {
    const a = (k * Math.PI) / 2;
    const stock = boxM(0.32, 13.5, 0.32, "#4a3a2c", M.planks);
    xf(stock, 0, 6.9, 0.1);
    const cloth = boxM(2.5, 10.2, 0.08, "#fbf3dc", M.cloth);
    xf(cloth, 1.4, 7.9, 0.1);
    const bars: Geo[] = [stock, cloth];
    for (let b = 0; b < 7; b++) bars.push(xf(boxM(2.6, 0.09, 0.12, "#5a4634", M.planks), 1.4, 3.2 + b * 1.6, 0.16));
    for (const g of bars) {
      g.rotateZ(a);
      s.push(g);
    }
  }
  const [a, b] = rot(0, 3.9, yaw);
  return { body, sails: merge(s), hub: new THREE.Vector3(a, 17.3, b) };
}

/** Road direction (yaw of local +z) where the south road crosses the river at the bridge. */
function bridgeYaw(): number {
  const P = ROAD_PATHS.find((p) => p.name === "south")!.path;
  let best = Infinity, yaw: number = BRIDGE.yaw;
  for (let i = 0; i < P.length - 1; i++) {
    const d = Math.hypot(P[i][0] - BRIDGE.x, P[i][1] - BRIDGE.z);
    if (d < best) {
      best = d;
      const j = Math.min(P.length - 1, i + 2), k = Math.max(0, i - 2);
      yaw = Math.atan2(P[j][0] - P[k][0], P[j][1] - P[k][1]);
    }
  }
  return yaw;
}

/** Stone arch bridge along local z (road direction), deck rising over one broad arch. */
function bridge(): Geo[] {
  const hw0 = riverAt(BRIDGE.x, BRIDGE.z).hw;
  const L = Math.max(BRIDGE.len, hw0 * 2 + 22), Wd = BRIDGE.width;
  const yaw = bridgeYaw();
  const c = Math.cos(yaw), s = Math.sin(yaw);
  const at = (lz: number) => groundHeight(BRIDGE.x + s * lz, BRIDGE.z + c * lz);
  const yA = at(-L / 2), yB = at(L / 2);
  const deck = (z: number) => {
    const t = (z + L / 2) / L;
    return yA + (yB - yA) * t + 2.6 * Math.sin(Math.PI * t) + 0.15;
  };
  const span = Math.max(22, hw0 * 2 + 2), rise = 5.2, spring = -0.6;
  const R = (span * span / 4 + rise * rise) / (2 * rise);
  const arch = (z: number) => (Math.abs(z) < span / 2 ? spring + Math.sqrt(R * R - z * z) - (R - rise) : -3);
  const stoneP: number[] = [], deckP: number[] = [], capP: number[] = [];
  const quad = (out: number[], a: number[], b: number[], cc: number[], d: number[]) => out.push(...a, ...b, ...cc, ...a, ...cc, ...d);
  const n = 52;
  const zs = Array.from({ length: n + 1 }, (_, i) => -L / 2 + (L * i) / n);
  const hw = Wd / 2, pw = 0.5, ph = 1.05;
  for (let i = 0; i < n; i++) {
    const z0 = zs[i], z1 = zs[i + 1];
    const t0 = deck(z0), t1 = deck(z1), b0 = arch(z0), b1 = arch(z1);
    // Road deck between the parapets, spandrel walls (outer faces run up to the parapet top), soffit.
    quad(deckP, [-hw + pw, t0, z0], [-hw + pw, t1, z1], [hw - pw, t1, z1], [hw - pw, t0, z0]);
    quad(stoneP, [hw, b0, z0], [hw, t0 + ph, z0], [hw, t1 + ph, z1], [hw, b1, z1]);
    quad(stoneP, [-hw, b1, z1], [-hw, t1 + ph, z1], [-hw, t0 + ph, z0], [-hw, b0, z0]);
    quad(stoneP, [-hw, b0, z0], [hw, b0, z0], [hw, b1, z1], [-hw, b1, z1]);
    // Parapet inner faces and pale coping on top (reads from above as two bright lines).
    quad(stoneP, [hw - pw, t1, z1], [hw - pw, t1 + ph, z1], [hw - pw, t0 + ph, z0], [hw - pw, t0, z0]);
    quad(stoneP, [-hw + pw, t0, z0], [-hw + pw, t0 + ph, z0], [-hw + pw, t1 + ph, z1], [-hw + pw, t1, z1]);
    for (const px of [-hw, hw - pw]) quad(capP, [px, t0 + ph, z0], [px + pw, t0 + ph, z0], [px + pw, t1 + ph, z1], [px, t1 + ph, z1]);
  }
  const mk = (p: number[], col: string, mat: number) => {
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.Float32BufferAttribute(p, 3));
    g.computeVertexNormals();
    const pg = prep(g, col, mat);
    return xf(pg, BRIDGE.x, 0, BRIDGE.z, 0, yaw, 0);
  };
  return [mk(stoneP, "#bba584", M.stone), mk(deckP, "#b9a27c", M.plain), mk(capP, "#e6dabd", M.stone)];
}

/** Hedges (bushy green boxes) and low drystone walls round the plots; graves. */
function boundsGeo(bounds: Bound[], props: Prop[]): Geo {
  const parts: Geo[] = [];
  const r = mulberry32(5);
  const HEDGE = ["#3f6e35", "#466f38", "#3a6630", "#4a7a3c", "#41703a"];
  const STONE = ["#bfa985", "#b49e7c", "#c8b28e", "#ad9878"];
  for (const b of bounds) {
    const [ax, az] = b.a, [bx, bz] = b.b;
    const len = Math.hypot(bx - ax, bz - az);
    if (len < 0.6) continue;
    const yaw = Math.atan2(bx - ax, bz - az);
    // Long runs split so they follow the ground.
    const n = Math.max(1, Math.ceil(len / 12));
    for (let k = 0; k < n; k++) {
      const t = (k + 0.5) / n, l = len / n;
      const x = ax + (bx - ax) * t, z = az + (bz - az) * t;
      const y = groundHeight(x, z);
      if (b.kind === "hedge") {
        const h = range(r, 1.2, 1.6);
        parts.push(xf(boxM(1.0, h + 0.3, l + 0.5, HEDGE[Math.floor(r() * HEDGE.length)], M.foliage), x, y + h / 2 - 0.15, z, 0, yaw, 0));
      } else {
        parts.push(xf(boxM(0.5, 1.0, l + 0.25, STONE[Math.floor(r() * STONE.length)], M.stone), x, y + 0.3, z, 0, yaw, 0));
        parts.push(xf(boxM(0.58, 0.12, l + 0.3, "#cbb994", M.stone), x, y + 0.84, z, 0, yaw, 0));
      }
    }
  }
  for (const p of props) {
    if (p.kind !== "grave") continue;
    const y = groundHeight(p.x, p.z);
    parts.push(xf(boxM(0.6, 0.85, 0.16, r() < 0.5 ? "#c8c2b4" : "#a8a49a", M.stone), p.x, y + 0.3, p.z, 0, p.yaw, 0));
  }
  return merge(parts);
}

/** Market cross, pump, lychgate, greenhouses. */
function propsGeo(props: Prop[]): Geo[] {
  const parts: Geo[] = [];
  for (const p of props) {
    const y = groundHeight(p.x, p.z);
    const local: Geo[] = [];
    if (p.kind === "cross") {
      local.push(xf(boxM(4.2, 0.5, 4.2, "#c8b896", M.stone), 0, 0.15, 0));
      local.push(xf(boxM(3.0, 0.5, 3.0, "#d0c09e", M.stone), 0, 0.65, 0));
      local.push(xf(boxM(1.8, 0.5, 1.8, "#d8c8a6", M.stone), 0, 1.15, 0));
      local.push(xf(cyl(0.28, 0.38, 4.4, "#ddd0b0", M.stone, 8), 0, 3.6, 0));
      local.push(xf(boxM(1.2, 0.26, 0.26, "#ddd0b0", M.stone), 0, 5.3, 0));
    } else if (p.kind === "pump") {
      local.push(xf(cyl(1.3, 1.4, 0.7, "#bfae8c", M.stone, 10), 0, 0.2, 0));
      local.push(xf(boxM(0.35, 1.8, 0.35, "#3a4a3c", M.metal), 0, 1.4, 0));
      local.push(xf(boxM(0.9, 0.12, 0.12, "#3a4a3c", M.metal), 0.4, 2.1, 0));
    } else if (p.kind === "lychgate") {
      for (const sx of [-1.6, 1.6]) for (const sz of [-1.1, 1.1]) local.push(xf(boxM(0.25, 2.4, 0.25, "#5a4232", M.planks), sx, 1.2, sz));
      for (const g of roof(4.0, 3.0, 2.4, 0.8, "#4e5a6c")) local.push(g);
    } else if (p.kind === "stall") {
      for (const sx of [-1.6, 1.6]) for (const sz of [-1.1, 1.1]) local.push(xf(boxM(0.12, 2.3, 0.12, "#5a4232", M.planks), sx, 1.15, sz));
      local.push(xf(boxM(3.0, 0.8, 1.8, "#c8a878", M.planks), 0, 0.4, 0.1));
      for (const g of roof(3.6, 2.8, 2.2, 0.3, p.color ?? "#c8483a")) local.push(setMat(g, M.plain));
    } else if (p.kind === "greenhouse") {
      local.push(xf(boxM(2.4, 1.0, 3.4, "#e8e2d6", M.plaster), 0, 0.5, 0));
      for (const g of roof(2.4, 3.4, 1.0, 0.55, "#cfe2e0")) local.push(g);
    } else continue;
    for (const g of local) parts.push(xf(g, p.x, y, p.z, 0, p.yaw, 0));
  }
  return parts;
}

/** A timber jetty on the lake's south-west shore (the side facing the village). */
function jetty(): Geo[] {
  const sh = lakeShore(360);
  let best = sh[0], bd = Infinity;
  for (const p of sh) {
    const d = Math.hypot(p[0] - VILLAGE.x - 200, p[1] - VILLAGE.z + 200);
    if (d < bd) { bd = d; best = p; }
  }
  const yaw = Math.atan2(LAKE.x - best[0], LAKE.z - best[1]);
  const parts: Geo[] = [];
  const L = 22;
  parts.push(xf(boxM(2.2, 0.18, L, "#8a6a4a", M.deck), 0, 1.0, L / 2 - 4));
  for (let z = -3; z <= L - 4; z += 3.2) for (const x of [-1.0, 1.0]) parts.push(xf(cyl(0.12, 0.12, 4.2, "#5a4232", M.planks, 5), x, -0.9, z));
  parts.push(xf(boxM(4.4, 0.18, 3.0, "#8a6a4a", M.deck), 0, 1.0, L - 4));
  const y = Math.max(0, groundHeight(best[0], best[1]) - 1.2);
  for (const g of parts) xf(g, best[0], y, best[1], 0, yaw, 0);
  return parts;
}

export interface Village {
  group: THREE.Group;
  sails: THREE.Mesh;
  near: THREE.Mesh;
  far: THREE.Mesh;
  update(t: number, camera: THREE.Camera): void;
}

export function buildVillage(plan: VillagePlan): Village {
  const group = new THREE.Group();
  group.name = "village";
  const nearParts: Geo[] = [], farParts: Geo[] = [];
  for (const h of plan.houses) {
    nearParts.push(...houseGeo(h, true));
    if (h.kind !== "shed" && h.kind !== "ext") farParts.push(...houseGeo(h, false));
  }
  const br = [...bridge(), ...jetty()];
  const mat = uber(ID.house, 1);
  const near = new THREE.Mesh(merge([...nearParts, ...br.map((g) => g.clone()), ...propsGeo(plan.props)]), mat);
  near.name = "village near";
  const far = new THREE.Mesh(merge([...farParts, ...br]), mat);
  far.name = "village far";
  // Hedges, walls and graves: no ink of their own (they drew as black wire from altitude).
  const bnd = new THREE.Mesh(boundsGeo(plan.bounds, plan.props), uber(ID.fence, -1));
  bnd.name = "village bounds";
  for (const m of [near, far, bnd]) {
    m.matrixAutoUpdate = false;
    m.updateMatrix();
    group.add(m);
  }
  onLayers(near, LAYER_SHADOW, LAYER_REFLECT);
  onLayers(bnd, LAYER_SHADOW);
  onLayers(far, LAYER_REFLECT);
  far.visible = false;

  // Landmarks: church and windmill, each in its own frame so they can carry a distance scale bias.
  const churchMesh = new THREE.Mesh(merge(church()), mat);
  churchMesh.name = "church";
  churchMesh.position.set(CHURCH.x, groundHeight(CHURCH.x, CHURCH.z) - 0.4, CHURCH.z);
  churchMesh.rotation.y = CHURCH.yaw;
  const mill = new THREE.Group();
  mill.name = "windmill";
  mill.position.set(WINDMILL.x, groundHeight(WINDMILL.x, WINDMILL.z) - 0.3, WINDMILL.z);
  const wm = windmill(-0.75); // sails face south-west, toward the village and the usual views
  const body = new THREE.Mesh(merge(wm.body), mat);
  const sails = new THREE.Mesh(wm.sails, uber(ID.house, 1, THREE.DoubleSide));
  sails.name = "windmill sails";
  sails.position.copy(wm.hub);
  sails.rotation.set(0, -0.75, 0, "YXZ");
  mill.add(body, sails);
  group.add(churchMesh, mill);
  onLayers(churchMesh, LAYER_SHADOW, LAYER_REFLECT);
  onLayers(mill, LAYER_SHADOW, LAYER_REFLECT);
  const vc = new THREE.Vector3(VILLAGE.x, 0, VILLAGE.z);
  // Gentle scale bias with distance: 1 at 500 m, up to 1 + k from ~2.2 km on.
  const bias = (o: THREE.Object3D, camera: THREE.Camera, k: number) => {
    const d = camera.position.distanceTo(o.position);
    o.scale.setScalar(1 + k * Math.min(1, Math.max(0, (d - 500) / 1700)));
  };
  return {
    group,
    sails,
    near,
    far,
    update(t, camera) {
      sails.rotation.z = -t * 0.45;
      // Detailed village while it is within ~1.6 km, the simple one beyond.
      const d = camera.position.distanceTo(vc);
      near.visible = bnd.visible = d < 1600;
      far.visible = !near.visible;
      bias(churchMesh, camera, 0.45);
      bias(mill, camera, 0.6);
    },
  };
}
