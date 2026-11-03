// Procedural scenery props. Each builder returns { base, glow }: merged vertex-coloured geometry,
// with the parts that light up at night (windows, lamps) split out into `glow` (or null).
import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { col, shade, xf, part } from './assets.js';

const PI = Math.PI;
const C = (p, k, fb) => col(p?.[k] ?? fb);
const merge = (parts) => (parts.length ? mergeGeometries(parts) : null);
const out = (base, glow = []) => ({ base: merge(base), glow: merge(glow) });

function rand(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Faceted normals on a non-indexed part.
function facet(g) {
  g.computeVertexNormals();
  return g;
}

// Position-hashed sideways noise, so coincident vertices stay welded.
function wobble(g, amt, seed = 1, yAmt = 0) {
  const p = g.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const x = p.getX(i), y = p.getY(i), z = p.getZ(i);
    const h = (k) => (Math.abs(Math.sin(x * 12.99 + y * 78.23 + z * 37.72 + seed * k) * 43758.55) % 1) - 0.5;
    p.setXYZ(i, x + h(1) * amt, y + h(2) * yAmt, z + h(3) * amt);
  }
  return g;
}

const mul = (a, b) => a.clone().multiply(b);
const box = (w, h, d) => new THREE.BoxGeometry(w, h, d);

function prism(pts, depth) {
  const g = new THREE.ExtrudeGeometry(new THREE.Shape(pts.map(([x, y]) => new THREE.Vector2(x, y))), { depth, bevelEnabled: false });
  g.translate(0, 0, -depth / 2);
  return g;
}

// Gable roof over a wall block, ridge along z (or along x). Gable ends take the wall colour.
function gable(parts, { x = 0, z = 0, y, span, len, rise, ov = 0.35, t = 0.16, wall, roof, alongX = false }) {
  const base = xf([x, y, z], [0, alongX ? PI / 2 : 0, 0]);
  parts.push(part(prism([[-span / 2, 0], [span / 2, 0], [0, rise]], len), wall, base));
  const a = Math.atan2(rise, span / 2), sl = Math.hypot(span / 2, rise) + ov;
  for (const s of [-1, 1]) {
    const cx = s * (span / 4 + Math.cos(a) * ov / 2 + Math.sin(a) * t / 2);
    const cy = rise / 2 - Math.sin(a) * ov / 2 + Math.cos(a) * t / 2;
    parts.push(part(box(sl, t, len + 2 * ov), roof, mul(base, xf([cx, cy, 0], [0, 0, -s * a]))));
  }
  parts.push(part(box(0.22, 0.12, len + 2 * ov), shade(roof, 0.8), mul(base, xf([0, rise + t * 0.8, 0]))));
}

const FACE = { 'x+': 0, 'x-': PI, 'z+': -PI / 2, 'z-': PI / 2 };

// Window with a frame on a wall face; the glass goes to `glow`.
function win(base, glow, p, pos, face, w = 0.9, h = 1.1, frame) {
  const m = xf(pos, [0, FACE[face], 0]);
  base.push(part(box(0.08, h + 0.18, w + 0.18), frame ?? C(p, 'white', '#f7f4ee'), mul(m, xf([0.03, 0, 0]))));
  base.push(part(box(0.05, 0.07, w + 0.3), frame ?? C(p, 'white', '#f7f4ee'), mul(m, xf([0.09, -h / 2 - 0.1, 0]))));
  glow.push(part(box(0.04, h, w), C(p, 'window', '#ffd98a'), mul(m, xf([0.075, 0, 0]))));
}

function door(base, p, pos, face, color, w = 1.0, h = 2.1) {
  const m = xf(pos, [0, FACE[face], 0]);
  base.push(part(box(0.08, h + 0.12, w + 0.16), C(p, 'white', '#f7f4ee'), mul(m, xf([0.03, h / 2 + 0.03, 0]))));
  base.push(part(box(0.06, h, w), color, mul(m, xf([0.06, h / 2, 0]))));
  base.push(part(box(0.12, 0.08, w + 0.4), shade(C(p, 'rock', '#bfb0a3'), 1.1), mul(m, xf([0.25, 0.04, 0]))));
}

// ---------------------------------------------------------------- vegetation

export function cypress(p) {
  const fol = C(p, 'cypress', p?.pine ?? '#3c6e4f');
  const g = new THREE.LatheGeometry([
    [0, 0], [0.5, 0.25], [0.82, 1.4], [0.9, 3.0], [0.78, 5.0], [0.5, 6.8], [0.2, 8.2], [0, 8.9],
  ].map(([r, y]) => new THREE.Vector2(r, y)), 7);
  wobble(g, 0.22, 3, 0.15);
  const inner = new THREE.LatheGeometry([[0, 0], [0.55, 0.4], [0.7, 2.5], [0.45, 5.0], [0, 6.2]].map(([r, y]) => new THREE.Vector2(r, y)), 5);
  wobble(inner, 0.18, 9, 0.1);
  return out([
    part(new THREE.CylinderGeometry(0.12, 0.17, 1.0, 5), C(p, 'trunk', '#8b6a4f'), xf([0, 0.5, 0])),
    facet(part(g, fol, xf([0, 0.7, 0], [0, 0.3, 0]))),
    facet(part(inner, shade(fol, 1.14), xf([0.25, 1.6, 0.18], [0, 1.1, 0]))),
  ]);
}

export function bush(p) {
  const r = rand(11), a = C(p, 'leaf', '#86d47a'), b = C(p, 'leaf2', '#55b56e');
  const parts = [];
  for (const [x, y, z, s, c] of [[0, 0.55, 0, 0.72, a], [0.5, 0.42, 0.25, 0.5, b], [-0.45, 0.4, -0.2, 0.52, b], [0.05, 0.4, -0.5, 0.45, a], [-0.1, 0.85, 0.2, 0.42, shade(a, 1.1)]]) {
    const g = wobble(new THREE.IcosahedronGeometry(s, 0), s * 0.25, r() * 10);
    parts.push(facet(part(g, c, xf([x, y, z], [r(), r(), r()], [1, 0.85, 1]))));
  }
  return out(parts);
}

export function grassTuft(p) {
  const r = rand(23), g0 = col(p?.grass ?? '#b9c46e').lerp(col(p?.sand ?? '#f4d8a4'), 0.25);
  const parts = [];
  for (let i = 0; i < 16; i++) {
    const h = 0.45 + r() * 0.45, a = r() * PI * 2, tilt = 0.15 + r() * 0.45, d = r() * 0.15;
    const g = new THREE.ConeGeometry(0.035, h, 3, 1, true);
    g.translate(0, h / 2, 0);
    const c = shade(g0, 0.8 + r() * 0.35);
    parts.push(facet(part(g, c, xf([Math.cos(a) * d, 0, Math.sin(a) * d], [Math.sin(a) * tilt, 0, -Math.cos(a) * tilt]))));
  }
  return out(parts);
}

export function flowers(p) {
  const r = rand(37), stem = shade(C(p, 'leaf2', '#55b56e'), 0.85);
  const cols = [C(p, 'flowerA', '#ff8fa3'), C(p, 'flowerB', '#ffd166'), C(p, 'flowerC', '#ffffff')];
  const parts = [];
  for (let i = 0; i < 5; i++) {
    const a = r() * PI * 2, d = r() * 0.5;
    parts.push(facet(part(new THREE.ConeGeometry(0.18, 0.35, 4), shade(C(p, 'leaf', '#86d47a'), 0.9 + r() * 0.2),
      xf([Math.cos(a) * d, 0.15, Math.sin(a) * d], [0, r() * 3, 0], [1, 1, 0.5]))));
  }
  for (let i = 0; i < 12; i++) {
    const a = r() * PI * 2, d = Math.sqrt(r()) * 0.7, h = 0.25 + r() * 0.3, x = Math.cos(a) * d, z = Math.sin(a) * d;
    parts.push(part(new THREE.CylinderGeometry(0.012, 0.015, h, 3), stem, xf([x, h / 2, z])));
    parts.push(facet(part(new THREE.IcosahedronGeometry(0.07 + r() * 0.03, 0), cols[i % 3], xf([x, h + 0.03, z], [r(), r(), 0], [1, 0.7, 1]))));
  }
  return out(parts);
}

export function olive(p) {
  const r = rand(41), bark = shade(C(p, 'trunk', '#8b6a4f'), 0.85);
  const leaf = col(p?.leaf2 ?? '#6f9a4c').lerp(col('#c9d1bf'), 0.4);
  const parts = [];
  let x = 0, y = 0;
  for (let i = 0; i < 3; i++) {
    const lean = [0.25, -0.35, 0.3][i], h = [0.9, 0.8, 0.7][i], r0 = 0.3 - i * 0.06;
    const g = wobble(new THREE.CylinderGeometry(r0 - 0.05, r0, h, 6), 0.06, i + 2);
    parts.push(facet(part(g, bark, xf([x + Math.sin(lean) * h / 2, y + Math.cos(lean) * h / 2, 0], [0, 0, -lean]))));
    x += Math.sin(lean) * h;
    y += Math.cos(lean) * h;
  }
  for (const [a, l, e] of [[0.4, 1.3, 0.8], [2.4, 1.2, 0.7], [4.3, 1.1, 0.9]]) {
    const g = new THREE.CylinderGeometry(0.07, 0.12, l, 5);
    g.translate(0, l / 2, 0);
    parts.push(facet(part(g, bark, xf([x, y - 0.1, 0], [0, a, e]))));
  }
  for (const [cx, cy, cz, s, k] of [[0, 1.0, 0, 1.05, 1], [1.2, 0.5, 0.4, 0.8, 0.92], [-1.1, 0.6, -0.3, 0.85, 1.06], [0.3, 0.45, -1.1, 0.75, 0.95],
    [-0.4, 0.4, 1.1, 0.75, 1.1], [0.9, 1.0, -0.6, 0.65, 1.04], [-0.8, 1.1, 0.6, 0.6, 0.9]]) {
    const g = wobble(new THREE.IcosahedronGeometry(s, 0), s * 0.35, r() * 20);
    parts.push(facet(part(g, shade(leaf, k), xf([x + cx, y + cy, cz], [0, r() * 6, 0], [1.25, 0.62, 1.15]))));
  }
  return out(parts);
}

export function cactus(p) {
  const g0 = col(p?.pine ?? '#3f9473').lerp(col('#9db06a'), 0.35);
  const parts = [];
  const limb = (x, y, z, r, h) => {
    parts.push(facet(part(new THREE.CylinderGeometry(r, r, h, 8), g0, xf([x, y + h / 2, z]))));
    parts.push(facet(part(new THREE.SphereGeometry(r, 8, 3, 0, PI * 2, 0, PI / 2), shade(g0, 1.08), xf([x, y + h, z]))));
  };
  limb(0, 0, 0, 0.3, 3.9);
  for (const [s, y0, h, len] of [[1, 1.5, 1.3, 0.7], [-1, 2.1, 1.0, 0.6]]) {
    parts.push(facet(part(new THREE.CylinderGeometry(0.19, 0.19, len, 8).rotateZ(PI / 2), g0, xf([s * len / 2, y0, 0]))));
    parts.push(facet(part(new THREE.SphereGeometry(0.19, 8, 4), g0, xf([s * len, y0, 0]))));
    limb(s * len, y0, 0, 0.19, h);
  }
  return out(parts);
}

// ---------------------------------------------------------------- beach

export function beachHut(p, variant = 0) {
  const v = ((variant % 4) + 4) % 4;
  const wall = [C(p, 'accentA', '#5ab0d6'), C(p, 'wallB', '#cfe3e8'), C(p, 'accentB', '#f2a65a'), C(p, 'wallC', '#f3c9a8')][v];
  const trim = C(p, 'white', '#f7f4ee'), wood = C(p, 'wood', '#9b7653');
  const roof = [C(p, 'white', '#f7f4ee'), C(p, 'accentA', '#5ab0d6'), C(p, 'roofA', '#c8644a'), C(p, 'roofB', '#5a6e7f')][v];
  const base = [];
  base.push(part(box(3.0, 0.2, 2.8), wood, xf([0.2, 0.3, 0])));
  for (const [x, z] of [[-1.1, -1.2], [-1.1, 1.2], [1.5, -1.2], [1.5, 1.2]]) base.push(part(box(0.16, 0.4, 0.16), shade(wood, 0.8), xf([x, 0.2, z])));
  base.push(part(box(2.2, 2.2, 2.4), wall, xf([-0.2, 1.5, 0])));
  for (let i = 0; i < 4; i++) base.push(part(box(0.04, 2.2, 0.22), i % 2 ? trim : shade(wall, 0.9), xf([0.92, 1.5, -1.0 + i * 0.65 + (i > 1 ? 0.03 : 0)])));
  for (const z of [-1.2, 1.2]) for (const x of [-1.3, 0.9]) base.push(part(box(0.1, 2.2, 0.1), trim, xf([x, 1.5, z])));
  gable(base, { x: -0.2, y: 2.6, span: 2.4, len: 2.2, rise: 0.8, ov: 0.25, t: 0.1, wall, roof, alongX: true });
  door(base, p, [0.92, 0.4, 0], 'x+', [trim, wall, trim, C(p, 'accentA', '#5ab0d6')][v], 0.8, 1.75);
  base.push(part(box(0.12, 0.4, 0.4), trim, xf([0.96, 2.5, 0])));
  return out(base);
}

export function umbrella(p, variant = 0) {
  const v = ((variant % 4) + 4) % 4;
  const A = [C(p, 'accentA', '#5ab0d6'), C(p, 'flowerA', '#ff8fa3'), C(p, 'accentB', '#f2a65a'), C(p, 'roofB', '#5a6e7f')][v];
  const B = [C(p, 'white', '#f7f4ee'), C(p, 'white', '#f7f4ee'), C(p, 'flowerB', '#ffd166'), C(p, 'white', '#f7f4ee')][v];
  const base = [], tilt = 0.12, top = 2.45;
  const m = xf([0, 0, 0], [0, 0, tilt]);
  base.push(part(new THREE.CylinderGeometry(0.03, 0.035, top, 5), C(p, 'white', '#f7f4ee'), mul(m, xf([0, top / 2, 0]))));
  for (let i = 0; i < 8; i++) {
    const g = new THREE.ConeGeometry(1.25, 0.5, 2, 1, false, (i / 8) * PI * 2, PI / 4);
    base.push(facet(part(g, i % 2 ? A : B, mul(m, xf([0, top - 0.15, 0])))));
  }
  base.push(part(new THREE.SphereGeometry(0.06, 5, 3), A, mul(m, xf([0, top + 0.12, 0]))));
  const towel = [C(p, 'flowerB', '#ffd166'), C(p, 'accentA', '#5ab0d6'), C(p, 'flowerA', '#ff8fa3'), C(p, 'accentB', '#f2a65a')][v];
  if (v % 2 === 0) {
    const frame = C(p, 'wood', '#9b7653');
    for (const z of [-0.3, 0.3]) {
      base.push(part(box(1.5, 0.06, 0.05), frame, xf([0.95, 0.32, z])));
      for (const x of [0.3, 1.6]) base.push(part(box(0.05, 0.32, 0.05), frame, xf([x, 0.16, z])));
      base.push(part(box(0.62, 0.05, 0.05), frame, xf([0.12, 0.55, z], [0, 0, -0.75])));
    }
    base.push(part(box(1.3, 0.06, 0.58), towel, xf([1.05, 0.37, 0])));
    base.push(part(box(0.62, 0.06, 0.58), shade(towel, 0.92), xf([0.15, 0.6, 0], [0, 0, -0.75])));
  } else {
    const tm = xf([1.0, 0.01, 0.2], [0, 0.25, 0]);
    base.push(part(box(1.7, 0.02, 0.85), towel, tm));
    for (let i = 0; i < 3; i++) base.push(part(box(0.16, 0.02, 0.85), B, mul(tm, xf([-0.5 + i * 0.5, 0.004, 0]))));
  }
  return out(base);
}

// ---------------------------------------------------------------- buildings

export function house(p, variant = 0) {
  const v = ((variant % 6) + 6) % 6;
  const wall = [C(p, 'wallA', '#f2e6d0'), C(p, 'wallB', '#cfe3e8'), C(p, 'white', '#f7f4ee'), C(p, 'wallC', '#f3c9a8'), C(p, 'wallA', '#f2e6d0'), C(p, 'wallC', '#f3c9a8')][v];
  const roof = [C(p, 'roofA', '#c8644a'), C(p, 'roofB', '#5a6e7f'), C(p, 'white', '#f7f4ee'), C(p, 'roofB', '#5a6e7f'), C(p, 'roofA', '#c8644a'), C(p, 'roofB', '#5a6e7f')][v];
  const accent = [C(p, 'accentA', '#2f7fb5'), C(p, 'accentB', '#e0a43a'), C(p, 'accentA', '#2f7fb5'), C(p, 'accentB', '#e0a43a'), C(p, 'accentB', '#e0a43a'), C(p, 'accentA', '#2f7fb5')][v];
  const white = C(p, 'white', '#f7f4ee'), stone = C(p, 'rock', '#bfb0a3');
  const base = [], glow = [];
  const block = (x, z, w, d, y0, h, c = wall) => base.push(part(box(w, h, d), c, xf([x, y0 + h / 2, z])));
  const plinth = (x, z, w, d) => base.push(part(box(w + 0.2, 0.3, d + 0.2), shade(stone, 0.95), xf([x, 0.15, z])));
  const chimney = (x, y, z, h = 1.6) => {
    base.push(part(box(0.6, h, 0.6), shade(wall, 0.9), xf([x, y + h / 2, z])));
    base.push(part(box(0.72, 0.15, 0.72), shade(stone, 0.8), xf([x, y + h, z])));
  };
  const rail = (x, y, z, len, alongZ = true) => {
    const n = Math.max(2, Math.round(len / 0.35));
    for (let i = 0; i <= n; i++) {
      const t = -len / 2 + (i / n) * len;
      base.push(part(box(0.05, 0.9, 0.05), white, xf(alongZ ? [x, y + 0.45, z + t] : [x + t, y + 0.45, z])));
    }
    base.push(part(box(alongZ ? 0.1 : len + 0.1, 0.08, alongZ ? len + 0.1 : 0.1), white, xf([x, y + 0.92, z])));
  };
  const flat = (x, z, w, d, y, c = white) => {
    base.push(part(box(w + 0.3, 0.25, d + 0.3), c, xf([x, y + 0.12, z])));
    for (const s of [-1, 1]) {
      base.push(part(box(0.2, 0.45, d + 0.3), c, xf([x + s * (w / 2 + 0.05), y + 0.45, z])));
      base.push(part(box(w + 0.3, 0.45, 0.2), c, xf([x, y + 0.45, z + s * (d / 2 + 0.05)])));
    }
  };

  if (v === 0) { // one-storey gabled cottage, ridge parallel to the road
    plinth(0, 0, 6, 8);
    block(0, 0, 6, 8, 0.3, 2.8);
    gable(base, { y: 3.1, span: 6, len: 8, rise: 2.0, wall, roof });
    door(base, p, [3, 0.3, 0], 'x+', accent);
    for (const z of [-2.5, 2.5]) win(base, glow, p, [3, 1.9, z], 'x+', 1.1, 1.1);
    for (const z of [-4, 4]) win(base, glow, p, [0, 1.9, z], z > 0 ? 'z+' : 'z-', 1.0, 1.0);
    win(base, glow, p, [-3, 1.9, 1.5], 'x-');
    chimney(-1.2, 3.8, 2.6);
  } else if (v === 1) { // two-storey, gable facing the road, front balcony
    plinth(0, 0, 7, 7);
    block(0, 0, 7, 7, 0.3, 5.4);
    gable(base, { y: 5.7, span: 7, len: 7, rise: 2.4, wall, roof, alongX: true });
    door(base, p, [3.5, 0.3, -1.6], 'x+', accent);
    win(base, glow, p, [3.5, 1.9, 1.5], 'x+', 1.4, 1.2);
    door(base, p, [3.5, 3.1, 0], 'x+', accent, 1.1, 2.0);
    glow.push(part(box(0.04, 1.2, 0.7), C(p, 'window', '#ffd98a'), xf([3.62, 4.4, 0])));
    for (const z of [-2.2, 2.2]) win(base, glow, p, [3.5, 4.1, z], 'x+', 0.9, 1.1);
    base.push(part(box(1.6, 0.2, 3.4), white, xf([4.3, 3.0, 0])));
    rail(5.05, 3.1, 0, 3.4);
    rail(4.3, 3.1, -1.65, 1.5, false);
    rail(4.3, 3.1, 1.65, 1.5, false);
    for (const z of [-3.5, 3.5]) for (const y of [1.9, 4.1]) win(base, glow, p, [0.8, y, z], z > 0 ? 'z+' : 'z-');
  } else if (v === 2) { // white flat-roof cubes, blue door
    plinth(0, 0, 7, 7);
    block(0, 0, 7, 7, 0.3, 5.6);
    flat(0, 0, 7, 7, 5.9, wall);
    block(-0.5, 5.2, 5, 3.4, 0.3, 3.0);
    flat(-0.5, 5.2, 5, 3.4, 3.3, wall);
    door(base, p, [3.5, 0.3, 1.5], 'x+', accent);
    for (const z of [-1.8]) win(base, glow, p, [3.5, 1.8, z], 'x+', 1.0, 1.2);
    for (const z of [-1.8, 1.5]) win(base, glow, p, [3.5, 4.3, z], 'x+', 1.0, 1.2);
    win(base, glow, p, [2.0, 1.9, 5.2], 'x+', 1.0, 1.0);
    for (const s of [-1, 1]) base.push(part(box(0.06, 1.3, 0.45), accent, xf([3.56, 4.3, -1.8 + s * 0.78])));
    win(base, glow, p, [0, 4.3, -3.5], 'z-', 1.0, 1.2);
    base.push(part(box(2.4, 0.12, 1.4), shade(C(p, 'wood', '#9b7653'), 1), xf([-0.5, 3.8, 5.2])));
  } else if (v === 3) { // bungalow with a shaded veranda
    plinth(0, 0, 6, 9);
    block(0, 0, 6, 9, 0.3, 3.0);
    base.push(part(box(8.4, 0.28, 9.8), roof, xf([1.0, 3.44, 0])));
    base.push(part(box(8.5, 0.14, 9.9), white, xf([1.0, 3.3, 0])));
    base.push(part(box(2.2, 0.2, 9), shade(C(p, 'wood', '#9b7653'), 1.05), xf([4.1, 0.2, 0])));
    for (const z of [-4.3, -1.45, 1.45, 4.3]) base.push(part(box(0.18, 3.0, 0.18), white, xf([4.95, 1.8, z])));
    door(base, p, [3, 0.3, 0], 'x+', accent);
    for (const z of [-2.8, 2.8]) win(base, glow, p, [3, 1.8, z], 'x+', 1.4, 1.2);
    for (const z of [-4.5, 4.5]) win(base, glow, p, [0, 1.8, z], z > 0 ? 'z+' : 'z-', 1.2, 1.0);
  } else if (v === 4) { // L-shaped: two-storey block plus a low wing
    plinth(0, -1, 6, 6);
    block(0, -1, 6, 6, 0.3, 5.2);
    gable(base, { y: 5.5, z: -1, span: 6, len: 6, rise: 2.0, wall, roof });
    plinth(0.5, 4, 5, 4);
    block(0.5, 4, 5, 4, 0.3, 2.8, shade(wall, 0.96));
    gable(base, { x: 0.5, y: 3.1, z: 4, span: 4, len: 5, rise: 1.5, wall: shade(wall, 0.96), roof, alongX: true });
    door(base, p, [3.0, 0.3, 4], 'x+', accent);
    for (const z of [-2.6, 0.6]) {
      win(base, glow, p, [3, 1.9, z], 'x+', 1.1, 1.2);
      win(base, glow, p, [3, 4.0, z], 'x+', 1.1, 1.1);
    }
    win(base, glow, p, [0.5, 1.8, 6], 'z+', 1.2, 1.0);
    win(base, glow, p, [0, 4.0, -4], 'z-');
    chimney(-1.6, 6.3, -2.6, 1.8);
  } else { // tall narrow townhouse with steep gable
    plinth(0, 0, 6, 5);
    block(0, 0, 6, 5, 0.3, 7.6);
    base.push(part(box(6.1, 0.18, 5.1), white, xf([0, 3.0, 0])));
    base.push(part(box(6.1, 0.18, 5.1), white, xf([0, 5.5, 0])));
    gable(base, { y: 7.9, span: 5, len: 6, rise: 3.0, wall, roof, alongX: true });
    door(base, p, [3, 0.3, -1.2], 'x+', accent);
    win(base, glow, p, [3, 1.8, 1.0], 'x+', 1.2, 1.2);
    for (const z of [-1.2, 1.2]) {
      win(base, glow, p, [3, 4.2, z], 'x+', 0.9, 1.4);
      win(base, glow, p, [3, 6.6, z], 'x+', 0.9, 1.3);
    }
    win(base, glow, p, [3, 8.9, 0], 'x+', 0.8, 0.9);
    base.push(part(box(1.1, 0.16, 4.0), white, xf([3.55, 3.5, 0])));
    rail(4.05, 3.55, 0, 4.0);
    for (const z of [-2.5, 2.5]) win(base, glow, p, [0, 4.2, z], z > 0 ? 'z+' : 'z-', 0.9, 1.2);
    chimney(-1.5, 8.6, 1.4, 1.4);
  }
  return out(base, glow);
}

export function lighthouse(p) {
  const red = C(p, 'accentB', '#d64541'), white = C(p, 'white', '#f7f4ee'), metal = C(p, 'metal', '#3c4248');
  const stone = C(p, 'rock', '#bfb0a3'), base = [], glow = [];
  base.push(facet(part(new THREE.CylinderGeometry(3.0, 3.3, 0.8, 8), stone, xf([0, 0.4, 0]))));
  const H = 15.6, bands = 6, r0 = 2.2, r1 = 1.35;
  for (let i = 0; i < bands; i++) {
    const a = i / bands, b = (i + 1) / bands;
    base.push(part(new THREE.CylinderGeometry(r0 + (r1 - r0) * b, r0 + (r1 - r0) * a, H / bands, 12), i % 2 ? red : white,
      xf([0, 0.8 + (a + b) / 2 * H, 0])));
  }
  door(base, p, [r0 - 0.05, 0.8, 0], 'x+', metal, 0.9, 1.9);
  for (const [y, a] of [[6, 0.6], [10.5, 3.6]]) {
    const r = r0 + (r1 - r0) * ((y - 0.8) / H) - 0.02;
    base.push(part(box(0.1, 0.9, 0.5), metal, xf([Math.cos(a) * r, y, -Math.sin(a) * r], [0, a, 0])));
  }
  const top = 0.8 + H;
  base.push(part(new THREE.CylinderGeometry(2.1, 1.5, 0.35, 12), metal, xf([0, top + 0.17, 0])));
  for (let i = 0; i < 16; i++) {
    const a = (i / 16) * PI * 2;
    base.push(part(box(0.06, 0.9, 0.06), metal, xf([Math.cos(a) * 1.95, top + 0.8, Math.sin(a) * 1.95])));
  }
  base.push(part(new THREE.TorusGeometry(1.95, 0.05, 4, 16).rotateX(PI / 2), metal, xf([0, top + 1.25, 0])));
  base.push(part(new THREE.CylinderGeometry(1.15, 1.15, 0.5, 10), red, xf([0, top + 0.6, 0])));
  glow.push(part(new THREE.CylinderGeometry(0.95, 0.95, 1.5, 10), C(p, 'lamp', '#fff1c4'), xf([0, top + 1.6, 0])));
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * PI * 2;
    base.push(part(box(0.08, 1.5, 0.08), metal, xf([Math.cos(a) * 0.98, top + 1.6, Math.sin(a) * 0.98])));
  }
  base.push(facet(part(new THREE.ConeGeometry(1.3, 1.2, 10), red, xf([0, top + 2.95, 0]))));
  base.push(part(new THREE.SphereGeometry(0.2, 6, 4), metal, xf([0, top + 3.65, 0])));
  base.push(part(new THREE.CylinderGeometry(0.02, 0.04, 0.7, 4), metal, xf([0, top + 4.0, 0])));
  // keeper's hut
  const hx = 4.2, hz = 3.2;
  base.push(part(box(3.6, 2.6, 4.2), white, xf([hx, 1.3, hz])));
  gable(base, { x: hx, z: hz, y: 2.6, span: 3.6, len: 4.2, rise: 1.3, ov: 0.25, wall: white, roof: red });
  door(base, p, [hx + 1.8, 0, hz - 0.9], 'x+', metal, 0.9, 1.9);
  win(base, glow, p, [hx + 1.8, 1.5, hz + 1.0], 'x+', 0.8, 0.8);
  win(base, glow, p, [hx, 1.5, hz + 2.1], 'z+', 0.9, 0.8);
  return { ...out(base, glow), lanternHeight: top + 1.6 };
}

export function pierSegment(p) {
  const wood = C(p, 'wood', '#9b7653'), dark = shade(wood, 0.72), base = [];
  for (let i = 0; i < 20; i++) base.push(part(box(0.36, 0.1, 3.0), shade(wood, 0.92 + ((i * 7) % 5) * 0.035), xf([0.2 + i * 0.4, 0.95, 0])));
  for (const z of [-1.2, 1.2]) base.push(part(box(8.0, 0.25, 0.2), dark, xf([4, 0.78, z])));
  for (const x of [0.25, 4.25]) {
    base.push(part(box(0.2, 0.2, 3.1), dark, xf([x, 0.6, 0])));
    for (const z of [-1.4, 1.4]) base.push(part(new THREE.CylinderGeometry(0.15, 0.17, 4.0, 6), dark, xf([x, -1.0, z])));
    base.push(part(box(0.1, 0.12, 3.6), dark, xf([x, -0.8, 0], [Math.atan2(2.2, 2.8), 0, 0])));
  }
  for (const z of [-1.42, 1.42]) {
    for (const x of [0.1, 2.1, 4.1, 6.1]) base.push(part(box(0.12, 1.05, 0.12), wood, xf([x, 1.5, z])));
    base.push(part(box(8.0, 0.1, 0.12), shade(wood, 1.05), xf([4, 2.0, z])));
    base.push(part(box(8.0, 0.08, 0.06), wood, xf([4, 1.5, z])));
  }
  return out(base);
}

export function lampPost(p) {
  const metal = C(p, 'metal', '#4a5258'), base = [], glow = [];
  base.push(part(new THREE.CylinderGeometry(0.2, 0.26, 0.6, 8), metal, xf([0, 0.3, 0])));
  base.push(part(new THREE.CylinderGeometry(0.07, 0.1, 5.6, 6), metal, xf([0, 3.4, 0])));
  base.push(part(new THREE.SphereGeometry(0.11, 6, 4), metal, xf([0, 6.2, 0])));
  base.push(part(new THREE.CylinderGeometry(0.045, 0.045, 0.75, 5).rotateZ(PI / 2), metal, xf([0.38, 6.15, 0], [0, 0, 0.18])));
  base.push(part(new THREE.CylinderGeometry(0.045, 0.045, 0.6, 5).rotateZ(PI / 2), metal, xf([1.02, 6.25, 0], [0, 0, -0.08])));
  base.push(part(box(0.7, 0.14, 0.34), metal, xf([1.3, 6.24, 0])));
  base.push(part(box(0.06, 0.06, 0.06), metal, xf([1.3, 6.34, 0])));
  glow.push(part(box(0.56, 0.08, 0.26), C(p, 'lamp', '#fff1c4'), xf([1.3, 6.13, 0])));
  return { ...out(base, glow), lampOffset: new THREE.Vector3(1.3, 6.08, 0) };
}

export function windTurbine(p) {
  const white = C(p, 'white', '#f4f4f2'), base = [];
  const hubHeight = 40.8, hubOffset = new THREE.Vector3(0, hubHeight, 2.7);
  base.push(part(new THREE.CylinderGeometry(2.6, 2.8, 0.6, 12), shade(C(p, 'rock', '#bfb0a3'), 1.05), xf([0, 0.3, 0])));
  base.push(part(new THREE.CylinderGeometry(0.95, 1.6, 40, 12), white, xf([0, 20.4, 0])));
  base.push(part(box(0.06, 2.0, 0.9), shade(white, 0.6), xf([1.6, 1.6, 0])));
  base.push(part(box(1.9, 1.9, 5.0), white, xf([0, hubHeight, 0.4])));
  base.push(part(box(1.9, 0.3, 5.0), shade(white, 0.88), xf([0, hubHeight - 0.8, 0.4])));
  const rotor = [];
  rotor.push(part(new THREE.ConeGeometry(0.9, 1.8, 10).rotateX(PI / 2), white, xf([0, 0, 0.9])));
  rotor.push(part(new THREE.CylinderGeometry(0.9, 0.9, 0.6, 10).rotateX(PI / 2), shade(white, 0.92), xf([0, 0, -0.2])));
  for (let i = 0; i < 3; i++) {
    const g = new THREE.BoxGeometry(1.2, 14.5, 0.22);
    const pos = g.attributes.position;
    for (let j = 0; j < pos.count; j++) {
      if (pos.getY(j) > 0) pos.setX(j, pos.getX(j) * 0.28 + 0.25);
    }
    g.translate(0, 7.25 + 0.7, 0);
    g.computeVertexNormals();
    rotor.push(facet(part(g, white, xf([0, 0, 0], [0, 0, (i / 3) * PI * 2], [1, 1, 1]).multiply(xf([0, 0, 0], [0, 0.18, 0])))));
  }
  return { base: merge(base), glow: null, rotor: merge(rotor), hubHeight, hubOffset };
}

export function fence(p) {
  const wood = col(p?.wood ?? '#a8865f').lerp(col('#c9c0b0'), 0.25), r = rand(5), base = [];
  for (const z of [-1.95, 0, 1.95]) {
    base.push(facet(part(box(0.12, 1.15, 0.12), shade(wood, 0.85), xf([0, 0.5, z], [(r() - 0.5) * 0.08, 0, (r() - 0.5) * 0.08]))));
  }
  for (const [y, k] of [[0.45, 0.95], [0.85, 1.05]]) {
    base.push(part(box(0.05, 0.12, 4.0), shade(wood, k), xf([0.08, y, 0], [(r() - 0.5) * 0.03, 0, 0])));
  }
  return out(base);
}

export function sign(p) {
  const board = C(p, 'accentA', '#2f7d5b'), white = C(p, 'white', '#f7f4ee'), metal = C(p, 'metal', '#8a9096'), base = [];
  base.push(part(new THREE.CylinderGeometry(0.05, 0.05, 2.4, 6), metal, xf([-0.06, 1.2, 0])));
  base.push(part(box(0.06, 0.92, 1.42), white, xf([0, 1.95, 0])));
  base.push(part(box(0.04, 0.8, 1.3), board, xf([0.04, 1.95, 0])));
  return out(base);
}
