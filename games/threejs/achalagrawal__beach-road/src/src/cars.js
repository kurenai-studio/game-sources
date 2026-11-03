// Car catalog and a procedural builder. Nine generic archetypes share one parts kit:
// extruded side profiles for the body, boxes and cylinders for the details.
import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { col, xf, outlineGeometry } from './assets.js';

const PI = Math.PI;

export const CAR_MODELS = [
  {
    id: 'hatch', name: 'Breeze EV', blurb: 'A small electric hatchback. Quick off the line, silent, easy to park by the beach.',
    stats: { topSpeed: 160, accel: 3.6, brake: 8.5, steer: 0.62, grip: 0.8 },
    engine: { cylinders: 0, idle: 0, redline: 12000, gears: 1, character: 'electric', volume: 0.45 },
    dims: { length: 3.95, width: 1.74, height: 1.52, wheelbase: 2.5, wheelRadius: 0.32, rideHeight: 0.2 },
    paints: ['#7fc8c0', '#f2f0ea', '#ffb347', '#5a7fd6', '#e85d75', '#3d3f46', '#b7e06b'],
  },
  {
    id: 'sedan', name: 'Coastline Sedan', blurb: 'The dependable family saloon. Smooth four-cylinder, comfortable on long drives.',
    stats: { topSpeed: 190, accel: 2.9, brake: 8.0, steer: 0.55, grip: 0.75 },
    engine: { cylinders: 4, idle: 800, redline: 6500, gears: 5, character: 'smooth', volume: 0.6 },
    dims: { length: 4.6, width: 1.8, height: 1.53, wheelbase: 2.78, wheelRadius: 0.36, rideHeight: 0.25 },
    paints: ['#ff7a6a', '#1d3557', '#c9c2b8', '#7a1f1f', '#2e2e33', '#7ec8f0', '#f4efe6'],
  },
  {
    id: 'wagon', name: 'Driftwood Estate', blurb: 'Long roof, roof rails and room for the surfboards. Unhurried and steady.',
    stats: { topSpeed: 180, accel: 2.6, brake: 7.8, steer: 0.52, grip: 0.72 },
    engine: { cylinders: 5, idle: 750, redline: 6200, gears: 6, character: 'smooth', volume: 0.6 },
    dims: { length: 4.75, width: 1.82, height: 1.6, wheelbase: 2.85, wheelRadius: 0.36, rideHeight: 0.26 },
    paints: ['#4f7c6b', '#c8b28a', '#2e4a6b', '#d9d4ca', '#7a2e3a', '#5d6a75', '#8a5a3c'],
  },
  {
    id: 'roadster', name: 'Sea Breeze Roadster', blurb: 'An open two-seater. Light, eager and sharp to steer. Hair-in-the-wind driving.',
    stats: { topSpeed: 210, accel: 3.8, brake: 9.0, steer: 0.68, grip: 0.88 },
    engine: { cylinders: 4, idle: 900, redline: 7800, gears: 6, character: 'buzzy', volume: 0.7 },
    dims: { length: 4.0, width: 1.76, height: 1.3, wheelbase: 2.48, wheelRadius: 0.33, rideHeight: 0.18 },
    paints: ['#d62828', '#f6f1e7', '#1f6f8b', '#2a9d8f', '#f4a261', '#14213d', '#e9c46a'],
  },
  {
    id: 'coupe', name: 'Sunset GT', blurb: 'A low grand-tourer coupe with a big V8. The fastest car on the coast road.',
    stats: { topSpeed: 240, accel: 4.6, brake: 9.5, steer: 0.55, grip: 0.92 },
    engine: { cylinders: 8, idle: 850, redline: 7200, gears: 6, character: 'rumble', volume: 0.85 },
    dims: { length: 4.45, width: 1.88, height: 1.25, wheelbase: 2.62, wheelRadius: 0.34, rideHeight: 0.14 },
    paints: ['#ffd23f', '#ff5a1f', '#101820', '#c0c5cc', '#3a86ff', '#8338ec', '#2b9348'],
  },
  {
    id: 'suv', name: 'Dune Ranger 4x4', blurb: 'A boxy off-roader with a roof rack and a spare on the tailgate. Heavy but unstoppable.',
    stats: { topSpeed: 170, accel: 2.4, brake: 7.0, steer: 0.5, grip: 0.65 },
    engine: { cylinders: 6, idle: 700, redline: 5800, gears: 5, character: 'rumble', volume: 0.75 },
    dims: { length: 4.6, width: 1.92, height: 1.92, wheelbase: 2.7, wheelRadius: 0.42, rideHeight: 0.34 },
    paints: ['#5b6b4e', '#d9cbb0', '#2f3e46', '#a44a3f', '#f2f2f2', '#3a5a7a', '#8a6f4e'],
  },
  {
    id: 'pickup', name: 'Harbour Hauler', blurb: 'A long pickup with an open bed. Lazy V8 torque, wide turning circle.',
    stats: { topSpeed: 175, accel: 2.7, brake: 7.2, steer: 0.48, grip: 0.62 },
    engine: { cylinders: 8, idle: 650, redline: 5500, gears: 4, character: 'rumble', volume: 0.8 },
    dims: { length: 5.3, width: 1.95, height: 1.78, wheelbase: 3.3, wheelRadius: 0.42, rideHeight: 0.34 },
    paints: ['#c1272d', '#2b4162', '#e0d6c2', '#3f4a3c', '#f5b700', '#6b705c', '#1c1c1c'],
  },
  {
    id: 'camper', name: 'Weekender Camper', blurb: 'A rounded two-tone camper van. Slow, soft and happiest at 90.',
    stats: { topSpeed: 125, accel: 1.6, brake: 6.0, steer: 0.5, grip: 0.55 },
    engine: { cylinders: 4, idle: 850, redline: 4800, gears: 4, character: 'buzzy', volume: 0.65 },
    dims: { length: 4.4, width: 1.82, height: 2.0, wheelbase: 2.4, wheelRadius: 0.34, rideHeight: 0.26 },
    paints: ['#7fb7be', '#e76f51', '#f4a261', '#6a994e', '#5b8fd1', '#e9c46a', '#d4778a'],
  },
  {
    id: 'classic', name: 'Promenade Classic', blurb: 'A round-fendered vintage cruiser with chrome and whitewalls. Made for Sunday drives.',
    stats: { topSpeed: 150, accel: 2.0, brake: 6.0, steer: 0.5, grip: 0.6 },
    engine: { cylinders: 6, idle: 600, redline: 4800, gears: 3, character: 'rumble', volume: 0.7 },
    dims: { length: 4.5, width: 1.86, height: 1.56, wheelbase: 2.75, wheelRadius: 0.37, rideHeight: 0.26 },
    paints: ['#9bd1c8', '#c94c4c', '#f2e3c6', '#2c4a6e', '#e8b04b', '#3e3a39', '#e7a1b0'],
  },
];

const BY_ID = Object.fromEntries(CAR_MODELS.map((m) => [m.id, m]));

function carSurface(style, hex, o, ramp) {
  const color = col(hex);
  switch (style.material) {
    case 'toon': return new THREE.MeshToonMaterial({ color, gradientMap: ramp });
    case 'soft': return new THREE.MeshLambertMaterial({ color });
    case 'flat': return new THREE.MeshStandardMaterial({ color, flatShading: true, roughness: Math.max(o.rough ?? 0.8, 0.5), metalness: 0 });
    default: return new THREE.MeshStandardMaterial({ color, roughness: o.rough ?? 0.8, metalness: o.metal ?? 0 });
  }
}

let blobTexture = null;
function getBlobTexture() {
  if (blobTexture) return blobTexture;
  const cv = document.createElement('canvas');
  cv.width = cv.height = 128;
  const g = cv.getContext('2d');
  const grad = g.createRadialGradient(64, 64, 8, 64, 64, 64);
  grad.addColorStop(0, 'rgba(0,0,0,0.75)');
  grad.addColorStop(1, 'rgba(0,0,0,0)');
  g.fillStyle = grad;
  g.fillRect(0, 0, 128, 128);
  blobTexture = new THREE.CanvasTexture(cv);
  return blobTexture;
}

// Side profile (x = forward, y = up) extruded across the car. `width` is the total width including bevels.
function profile(pts, width, bevel) {
  const shape = new THREE.Shape(pts.map(([x, y]) => new THREE.Vector2(x, y)));
  const depth = width - 2 * bevel;
  const g = new THREE.ExtrudeGeometry(shape, {
    depth, bevelEnabled: bevel > 0, bevelThickness: bevel, bevelSize: bevel, bevelSegments: 2, curveSegments: 1,
  });
  g.translate(0, 0, -depth / 2);
  g.rotateY(PI / 2); // profile x (forward) -> world -z
  return g;
}

function arc(cx, cy, r, a0, a1, n, sx = 1) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = a0 + (a1 - a0) * (i / n);
    out.push([cx + Math.cos(t) * r * sx, cy + Math.sin(t) * r]);
  }
  return out;
}

// Shared parts kit. Positions are [x (right), y (up), f (forward)]; world z = -f.
function makeKit(style, assets, model, spec, paint) {
  const d = model.dims, car = style.car ?? {};
  const glowK = style.post?.bloom ? 3 : 1;
  const mk = (hex, o = {}) => carSurface(style, hex, o, assets?.ramp);
  const paintO = { metal: car.metal ?? 0, rough: car.rough ?? 0.7 };
  const mats = {
    paint: mk(paint, paintO),
    accent: mk(spec.accent ?? paint, paintO),
    trim: mk(car.trim ?? '#2a2a30', { rough: 0.7 }),
    glass: mk(car.glass ?? '#2c3b48', { metal: 0.2, rough: 0.12 }),
    chrome: mk('#dfe2e7', { metal: 0.7, rough: 0.25 }),
    hub: mk('#cfd0d6', { metal: 0.5, rough: 0.35 }),
    tire: mk('#1e1e22', { rough: 0.95 }),
    dark: mk('#141418', { rough: 0.95 }),
    white: mk('#f1eee6', { rough: 0.8 }),
    seat: mk('#5a4034', { rough: 0.9 }),
    head: new THREE.MeshBasicMaterial({ color: col('#fff4d6').multiplyScalar(glowK) }),
    tail: new THREE.MeshBasicMaterial({ color: col('#ff2a3a').multiplyScalar(glowK) }),
    blob: new THREE.MeshBasicMaterial({
      map: getBlobTexture(), transparent: true, depthWrite: false, polygonOffset: true, polygonOffsetFactor: -4,
    }),
  };
  if (car.neon) mats.neon = new THREE.MeshBasicMaterial({ color: col(car.neon).multiplyScalar(2.5) });

  const group = new THREE.Group(), body = new THREE.Group();
  group.add(body);
  const bins = new Map();

  const put = (geom, mat, m, { parent = body, outline = true } = {}) => {
    const g = geom.index ? geom.toNonIndexed() : geom.clone();
    geom.dispose();
    for (const k of Object.keys(g.attributes)) if (k !== 'position' && k !== 'normal') g.deleteAttribute(k);
    g.clearGroups();
    g.computeBoundingBox();
    const s = g.boundingBox.getSize(new THREE.Vector3());
    const ol = outline && Math.min(s.x, s.y, s.z) >= 0.09; // thin bits would drown in ink
    if (m) g.applyMatrix4(m);
    const key = `${parent.id}:${mat.id}:${ol}`;
    let bin = bins.get(key);
    if (!bin) bins.set(key, bin = { parent, mat, ol, list: [] });
    bin.list.push(g);
  };
  const at = ([x, y, f], rot = [0, 0, 0], scale = [1, 1, 1]) => xf([x, y, -f], rot, scale);
  const box = (mat, [w, h, l], pos, rot, o) => put(new THREE.BoxGeometry(w, h, l), mat, at(pos, rot ?? undefined), o);
  const cylG = (r, len, axis, seg, r2 = r) => {
    const g = new THREE.CylinderGeometry(r2, r, len, seg);
    if (axis === 'x') g.rotateZ(PI / 2);
    else if (axis === 'z') g.rotateX(PI / 2);
    return g;
  };
  const cyl = (mat, r, len, axis, pos, seg = 12, o) => put(cylG(r, len, axis, seg), mat, at(pos), o);
  const prof = (pts, width, mat, bevel = 0.05, x = 0, o) => put(profile(pts, width, bevel), mat, x ? xf([x, 0, 0]) : null, o);
  // Box laid along a profile segment p0 -> p1 (front faces bottom-to-top, rear faces top-to-bottom), lifted `off` off the surface.
  const slab = (mat, p0, p1, w, t, off = 0, x = 0, o) => {
    const dx = p1[0] - p0[0], dy = p1[1] - p0[1], len = Math.hypot(dx, dy);
    const nx = dy / len, ny = -dx / len, k = t / 2 + off;
    const cx = (p0[0] + p1[0]) / 2 + nx * k, cy = (p0[1] + p1[1]) / 2 + ny * k;
    box(mat, [w, len, t], [x, cy, cx], [Math.atan2(-dx, dy), 0, 0], o);
  };
  const both = (fn) => { fn(-1); fn(1); };
  const light = (kind, size, pos, rot) => box(kind === 'head' ? mats.head : mats.tail, size, pos, rot);
  const roundLight = (kind, r, pos, rim = true) => {
    if (rim) cyl(mats.chrome, r + 0.03, 0.06, 'z', [pos[0], pos[1], pos[2] - 0.02], 14);
    cyl(kind === 'head' ? mats.head : mats.tail, r, 0.04, 'z', [pos[0], pos[1], pos[2] + 0.01], 14);
  };
  const mirrors = (f, y, half, mat = mats.paint) => both((s) => {
    box(mat, [0.16, 0.11, 0.07], [s * (half + 0.1), y, f]);
    box(mats.dark, [0.1, 0.03, 0.04], [s * (half + 0.03), y - 0.03, f + 0.01]);
  });
  // Lower body with wheel-arch notches cut into the bottom edge, plus dark liners inside them.
  const lowerBody = (top, { width = d.width, bevel = 0.05, mat = mats.paint } = {}) => {
    const R = d.wheelRadius, B = top[0][1], ra = R + 0.06 + bevel, pts = top.slice();
    for (const xa of [...spec.axles].sort((a, b) => b - a)) {
      const a0 = Math.asin(Math.max(-1, Math.min(1, (B - R) / ra)));
      pts.push(...arc(xa, R, ra, a0, PI - a0, 9));
    }
    prof(pts, width, mat, bevel);
    for (const xa of spec.axles) {
      const r = ra - bevel - 0.015;
      put(new THREE.CylinderGeometry(r, r, width - 0.1, 12, 1, false, -0.3, PI + 0.6).rotateZ(PI / 2), mats.dark, at([0, R, xa]));
    }
  };
  // Thick arc band around a wheel: fender flares and vintage fenders.
  const fenderBand = (xa, r0, r1, sx, width, mat, x, bevel = 0.04, a0 = 0, a1 = PI) => {
    const R = d.wheelRadius;
    const pts = [...arc(xa, R, r1, a0, a1, 10, sx), ...arc(xa, R, r0, a1, a0, 10, sx)];
    prof(pts, width, mat, bevel, x);
  };
  return { d, mats, group, body, bins, put, at, box, cyl, cylG, prof, slab, both, light, roundLight, mirrors, lowerBody, fenderBand };
}

// Per-model geometry. Each returns the headlight height and the driver's eye position [x, y, f].
const SPECS = {
  hatch: {
    axles: [1.24, -1.26], tyre: 0.22, wheel: { rimK: 0.66 },
    build(k) {
      const { mats, box, prof, light, both } = k, B = 0.25;
      k.lowerBody([[-1.9, B], [-1.95, 0.45], [-1.93, 0.96], [-1.8, 1.0], [0.55, 0.98], [1.72, 0.82], [1.93, 0.6], [1.9, B]]);
      prof([[0.55, 0.96], [-0.18, 1.42], [-1.52, 1.44], [-1.84, 0.98]], 1.48, mats.glass, 0.03);
      prof([[-0.14, 1.4], [-1.52, 1.42], [-1.58, 1.49], [-0.16, 1.48]], 1.46, mats.paint, 0.03);
      box(mats.paint, [1.52, 0.44, 0.1], [0, 1.2, -0.62]);
      box(mats.paint, [1.52, 0.44, 0.26], [0, 1.2, -1.48]);
      box(mats.paint, [1.3, 0.05, 0.24], [0, 1.52, -1.6], [-0.12, 0, 0]);
      box(mats.trim, [1.76, 0.14, 0.13], [0, 0.36, 1.95]);
      box(mats.trim, [1.76, 0.14, 0.13], [0, 0.36, -1.95]);
      box(mats.dark, [0.9, 0.12, 0.06], [0, 0.46, 1.96]);
      light('head', [1.2, 0.04, 0.05], [0, 0.8, 1.81]);
      both((s) => {
        light('head', [0.3, 0.1, 0.08], [s * 0.58, 0.74, 1.84]);
        light('tail', [0.26, 0.14, 0.06], [s * 0.62, 0.88, -1.98]);
      });
      light('tail', [1.0, 0.04, 0.05], [0, 0.9, -1.99]);
      box(mats.white, [0.44, 0.11, 0.03], [0, 0.56, -2.0], null, { outline: false });
      k.mirrors(0.45, 1.03, 0.72);
      return { head: 0.76, eye: [-0.36, 1.2, -0.45] };
    },
  },
  sedan: {
    axles: [1.38, -1.4], tyre: 0.24, wheel: {},
    build(k) {
      const { mats, box, prof, light, both } = k, B = 0.3;
      k.lowerBody([[-2.2, B], [-2.27, 0.5], [-2.24, 0.92], [-1.66, 1.0], [0.85, 0.95], [2.05, 0.82], [2.25, 0.6], [2.2, B]]);
      prof([[0.84, 0.93], [0.1, 1.42], [-1.08, 1.44], [-1.72, 0.98]], 1.54, mats.glass, 0.03);
      prof([[0.14, 1.4], [-1.06, 1.42], [-1.1, 1.49], [0.1, 1.48]], 1.5, mats.paint, 0.03);
      box(mats.paint, [1.58, 0.46, 0.1], [0, 1.18, -0.45]);
      box(mats.trim, [1.86, 0.16, 0.14], [0, 0.4, 2.27]);
      box(mats.trim, [1.86, 0.16, 0.14], [0, 0.4, -2.29]);
      box(mats.dark, [0.8, 0.16, 0.06], [0, 0.56, 2.29]);
      both((s) => {
        light('head', [0.4, 0.13, 0.08], [s * 0.6, 0.72, 2.2]);
        light('tail', [0.42, 0.13, 0.08], [s * 0.62, 0.8, -2.28]);
      });
      box(mats.white, [0.48, 0.12, 0.03], [0, 0.58, -2.33], null, { outline: false });
      k.mirrors(0.7, 1.0, 0.76);
      return { head: 0.72, eye: [-0.38, 1.2, -0.35] };
    },
  },
  wagon: {
    axles: [1.42, -1.43], tyre: 0.24, wheel: {},
    build(k) {
      const { mats, box, prof, light, both } = k, B = 0.31;
      k.lowerBody([[-2.3, B], [-2.36, 0.5], [-2.34, 0.96], [-2.24, 1.0], [0.95, 0.95], [2.12, 0.82], [2.33, 0.6], [2.28, B]]);
      prof([[0.94, 0.93], [0.18, 1.42], [-2.12, 1.44], [-2.28, 0.98]], 1.56, mats.glass, 0.03);
      prof([[0.22, 1.4], [-2.13, 1.42], [-2.17, 1.49], [0.2, 1.48]], 1.52, mats.paint, 0.03);
      box(mats.paint, [1.6, 0.46, 0.1], [0, 1.18, -0.4]);
      box(mats.paint, [1.6, 0.46, 0.1], [0, 1.18, -1.3]);
      box(mats.paint, [1.6, 0.46, 0.16], [0, 1.18, -2.1]);
      both((s) => {
        box(mats.trim, [0.05, 0.05, 2.2], [s * 0.62, 1.57, -0.95]);
        for (const f of [0.1, -2.0]) box(mats.trim, [0.06, 0.08, 0.1], [s * 0.62, 1.52, f]);
        light('head', [0.42, 0.13, 0.08], [s * 0.6, 0.72, 2.26]);
        light('tail', [0.16, 0.3, 0.07], [s * 0.74, 0.82, -2.37]);
      });
      box(mats.trim, [1.88, 0.16, 0.14], [0, 0.4, 2.35]);
      box(mats.trim, [1.88, 0.16, 0.14], [0, 0.4, -2.39]);
      box(mats.dark, [0.8, 0.16, 0.06], [0, 0.56, 2.36]);
      box(mats.white, [0.48, 0.12, 0.03], [0, 0.6, -2.41], null, { outline: false });
      k.mirrors(0.8, 1.0, 0.77);
      return { head: 0.72, eye: [-0.38, 1.2, -0.3] };
    },
  },
  roadster: {
    axles: [1.2, -1.28], tyre: 0.24, wheel: { rimK: 0.64 },
    build(k) {
      const { mats, box, prof, slab, light, both, put, at } = k, B = 0.23;
      k.lowerBody([[-1.92, B], [-1.97, 0.45], [-1.95, 0.76], [-1.72, 0.86], [-0.8, 0.86], [-0.78, 0.55],
        [0.26, 0.55], [0.3, 0.84], [0.45, 0.86], [1.62, 0.76], [1.95, 0.58], [1.93, B]]);
      both((s) => {
        prof([[-0.84, 0.5], [0.34, 0.5], [0.34, 0.86], [-0.84, 0.86]], 0.1, mats.paint, 0.02, s * 0.83);
        box(mats.seat, [0.5, 0.12, 0.48], [s * 0.38, 0.64, -0.3]);
        box(mats.seat, [0.48, 0.55, 0.12], [s * 0.38, 0.92, -0.62], [0.22, 0, 0]);
        box(mats.seat, [0.28, 0.18, 0.1], [s * 0.38, 1.27, -0.72], [0.22, 0, 0]);
        put(new THREE.SphereGeometry(1, 8, 5, 0, PI * 2, 0, PI / 2), mats.paint, at([s * 0.38, 0.88, -1.22], [0, 0, 0], [0.24, 0.2, 0.5]));
        slab(mats.chrome, [0.32, 0.86], [0.08, 1.21], 0.05, 0.04, 0, s * 0.71, { outline: false });
        light('head', [0.36, 0.1, 0.1], [s * 0.58, 0.66, 1.9]);
        light('tail', [0.34, 0.1, 0.06], [s * 0.6, 0.72, -1.99]);
      });
      box(mats.dark, [1.5, 0.03, 1.06], [0, 0.6, -0.24], null, { outline: false });
      box(mats.dark, [1.5, 0.3, 0.04], [0, 0.72, 0.28], null, { outline: false });
      box(mats.dark, [1.5, 0.3, 0.04], [0, 0.72, -0.8], null, { outline: false });
      slab(mats.glass, [0.32, 0.86], [0.08, 1.2], 1.38, 0.03);
      box(mats.chrome, [1.46, 0.04, 0.05], [0, 1.215, 0.08], null, { outline: false });
      put(new THREE.TorusGeometry(0.17, 0.025, 4, 12), mats.dark, at([-0.38, 0.95, 0.08], [-0.45, 0, 0]), { outline: false });
      box(mats.dark, [0.6, 0.14, 0.06], [0, 0.46, 1.96]);
      box(mats.trim, [1.6, 0.1, 0.12], [0, 0.32, 1.97]);
      box(mats.trim, [1.6, 0.1, 0.12], [0, 0.32, -1.98]);
      k.mirrors(0.25, 0.93, 0.8);
      return { head: 0.66, eye: [-0.38, 1.1, -0.35] };
    },
  },
  coupe: {
    axles: [1.3, -1.32], tyre: 0.27, wheel: { rimK: 0.7, rim: 'dark' },
    build(k) {
      const { mats, box, prof, slab, light, both, cyl } = k, B = 0.19;
      k.lowerBody([[-2.12, B], [-2.2, 0.42], [-2.18, 0.84], [-2.06, 0.92], [-1.5, 0.9], [0.5, 0.88], [1.9, 0.77], [2.2, 0.5], [2.16, B]], { width: 1.88 });
      prof([[0.5, 0.86], [-0.3, 1.16], [-0.95, 1.18], [-1.98, 0.9]], 1.48, mats.glass, 0.03);
      prof([[-0.26, 1.14], [-0.95, 1.16], [-1.02, 1.22], [-0.28, 1.21]], 1.44, mats.paint, 0.03);
      box(mats.paint, [1.6, 0.04, 0.28], [0, 1.03, -2.0]);
      both((s) => {
        box(mats.dark, [0.04, 0.12, 0.08], [s * 0.5, 0.96, -2.0]);
        box(mats.dark, [0.06, 0.08, 1.5], [s * 0.93, 0.25, -0.01]);
        cyl(mats.chrome, 0.05, 0.16, 'z', [s * 0.5, 0.3, -2.22], 8);
        slab(mats.head, [2.15, 0.58], [1.97, 0.74], 0.4, 0.03, 0.05, s * 0.6);
      });
      light('tail', [1.5, 0.07, 0.06], [0, 0.8, -2.25]);
      box(mats.dark, [1.7, 0.05, 0.22], [0, 0.22, 2.1]);
      box(mats.dark, [0.9, 0.1, 0.06], [0, 0.36, 2.22]);
      box(mats.white, [0.44, 0.11, 0.03], [0, 0.55, -2.26], null, { outline: false });
      k.mirrors(0.35, 0.96, 0.74);
      return { head: 0.66, eye: [-0.38, 1.0, -0.5] };
    },
  },
  suv: {
    axles: [1.38, -1.32], tyre: 0.3, wheel: { rimK: 0.58, rim: 'trim' },
    build(k) {
      const { mats, box, prof, light, both, cyl, d } = k, B = 0.39;
      k.lowerBody([[-2.2, B], [-2.3, 0.58], [-2.3, 1.1], [-2.22, 1.18], [0.9, 1.16], [2.16, 1.06], [2.28, 0.86], [2.26, B]], { width: 1.92 });
      prof([[0.88, 1.14], [0.36, 1.66], [-2.16, 1.68], [-2.24, 1.16]], 1.68, mats.glass, 0.03);
      prof([[0.38, 1.64], [-2.16, 1.66], [-2.2, 1.76], [0.34, 1.75]], 1.7, mats.paint, 0.03);
      for (const [f, l] of [[-0.42, 0.12], [-1.38, 0.12], [-2.12, 0.18]]) box(mats.paint, [1.72, 0.52, l], [0, 1.42, f]);
      const ra = d.wheelRadius + 0.11;
      both((s) => {
        for (const xa of k.d.axlesF) k.fenderBand(xa, ra - 0.05, ra + 0.08, 1, 0.12, mats.trim, s * 0.95, 0.03, -0.1, PI + 0.1);
        box(mats.trim, [0.06, 0.06, 2.3], [s * 0.72, 1.88, -0.92]);
        for (const f of [0.2, -2.0]) box(mats.trim, [0.06, 0.1, 0.06], [s * 0.72, 1.82, f]);
        box(mats.trim, [0.18, 0.05, 1.5], [s * 0.98, 0.42, 0.03]);
        light('head', [0.3, 0.2, 0.06], [s * 0.66, 0.94, 2.29]);
        light('tail', [0.14, 0.4, 0.06], [s * 0.86, 0.95, -2.35]);
      });
      for (const f of [0.15, -0.6, -1.35, -2.0]) box(mats.trim, [1.5, 0.05, 0.05], [0, 1.9, f]);
      box(mats.dark, [1.0, 0.3, 0.05], [0, 0.92, 2.3]);
      box(mats.trim, [1.94, 0.2, 0.16], [0, 0.48, 2.33]);
      box(mats.trim, [1.94, 0.2, 0.16], [0, 0.48, -2.33]);
      box(mats.dark, [1.2, 0.1, 0.3], [0, 0.4, 2.25]);
      cyl(mats.tire, d.wheelRadius * 0.95, 0.26, 'z', [0, 1.0, -2.49], 16);
      cyl(mats.trim, d.wheelRadius * 0.55, 0.29, 'z', [0, 1.0, -2.49], 10);
      cyl(mats.chrome, 0.08, 0.32, 'z', [0, 1.0, -2.49], 8);
      k.mirrors(0.75, 1.24, 0.84);
      return { head: 0.94, eye: [-0.4, 1.5, -0.25] };
    },
  },
  pickup: {
    axles: [1.72, -1.58], tyre: 0.3, wheel: { rimK: 0.6, rim: 'chrome' },
    build(k) {
      const { mats, box, prof, light, both } = k, B = 0.39;
      k.lowerBody([[-2.6, B], [-2.66, 0.58], [-2.66, 1.0], [-0.62, 1.0], [-0.62, 1.18], [1.1, 1.16], [2.48, 1.06], [2.64, 0.86], [2.62, B]], { width: 1.95 });
      prof([[1.08, 1.14], [0.56, 1.64], [-0.5, 1.66], [-0.58, 1.16]], 1.7, mats.glass, 0.03);
      prof([[0.58, 1.62], [-0.5, 1.64], [-0.53, 1.74], [0.56, 1.73]], 1.72, mats.paint, 0.03);
      box(mats.paint, [1.74, 0.48, 0.14], [0, 1.42, -0.44]);
      both((s) => {
        box(mats.paint, [0.1, 0.38, 2.06], [s * 0.925, 1.2, -1.66]);
        box(mats.dark, [0.12, 0.03, 2.08], [s * 0.925, 1.4, -1.66], null, { outline: false });
        light('tail', [0.1, 0.26, 0.04], [s * 0.925, 1.18, -2.72]);
        light('head', [0.28, 0.18, 0.06], [s * 0.78, 0.9, 2.69]);
        box(mats.chrome, [0.16, 0.05, 2.1], [s * 0.99, 0.44, 0.07], null, { outline: false });
      });
      box(mats.paint, [1.95, 0.4, 0.1], [0, 1.2, -0.67]);
      box(mats.paint, [1.95, 0.38, 0.1], [0, 1.19, -2.66]);
      box(mats.dark, [1.74, 0.02, 1.95], [0, 1.06, -1.66], null, { outline: false });
      box(mats.chrome, [1.3, 0.34, 0.06], [0, 0.86, 2.7]);
      for (const y of [0.8, 0.92]) box(mats.dark, [1.2, 0.04, 0.02], [0, y, 2.735], null, { outline: false });
      box(mats.chrome, [1.98, 0.2, 0.16], [0, 0.48, 2.68]);
      box(mats.chrome, [1.98, 0.2, 0.16], [0, 0.48, -2.68]);
      k.mirrors(0.9, 1.24, 0.86, mats.chrome);
      return { head: 0.9, eye: [-0.42, 1.5, 0.0] };
    },
  },
  camper: {
    axles: [1.3, -1.1], tyre: 0.22, accent: '#f6f1e6', wheel: { rimK: 0.72, rim: 'accent', spokes: false, cap: 0.32 },
    build(k) {
      const { mats, box, prof, slab, light, both, roundLight } = k, B = 0.31;
      k.lowerBody([[-2.12, B], [-2.18, 0.5], [-2.18, 1.04], [2.1, 1.04], [2.17, 0.85], [2.16, 0.5], [2.1, B]]);
      prof([[-2.18, 1.1], [2.1, 1.1], [2.04, 1.3], [1.9, 1.78], [1.66, 1.95], [-1.82, 1.95], [-2.08, 1.84], [-2.18, 1.6]], 1.82, mats.accent);
      both((s) => {
        slab(mats.glass, [2.035, 1.33], [1.91, 1.75], 0.74, 0.03, 0.05, s * 0.4);
        for (const [f, l] of [[1.45, 0.6], [0.6, 0.78], [-0.3, 0.78], [-1.2, 0.78]]) box(mats.glass, [0.03, 0.46, l], [s * 0.915, 1.5, f]);
        roundLight('head', 0.12, [s * 0.62, 0.86, 2.22]);
        light('tail', [0.12, 0.22, 0.04], [s * 0.75, 0.85, -2.245]);
      });
      box(mats.glass, [1.1, 0.34, 0.03], [0, 1.45, -2.24]);
      for (const y of [0.66, 0.73, 0.8]) box(mats.dark, [0.6, 0.035, 0.02], [0, y, -2.235], null, { outline: false });
      box(mats.chrome, [1.86, 0.1, 0.12], [0, 0.42, 2.22]);
      box(mats.chrome, [1.86, 0.1, 0.12], [0, 0.42, -2.22]);
      k.mirrors(1.95, 1.28, 0.88, mats.chrome);
      return { head: 0.86, eye: [-0.42, 1.62, 1.5] };
    },
  },
  classic: {
    axles: [1.38, -1.37], tyre: 0.2, track: 0.76, accent: '#f3ead8', wheel: { rimK: 0.55, rim: 'chrome', whitewall: true, spokes: false, cap: 0.3 },
    build(k) {
      const { mats, box, prof, light, both, cyl, roundLight } = k, B = 0.36;
      k.lowerBody([[-2.1, B], [-2.2, 0.55], [-2.12, 0.82], [-1.9, 0.95], [-1.4, 1.0], [1.1, 0.98], [1.95, 0.92], [2.16, 0.72], [2.14, B]], { width: 1.38 });
      prof([[1.0, 0.96], [0.5, 1.4], [-0.9, 1.44], [-1.42, 0.98]], 1.22, mats.glass, 0.03);
      prof([[0.52, 1.37], [0.3, 1.49], [-0.6, 1.53], [-0.92, 1.46], [-0.94, 1.4]], 1.26, mats.accent, 0.03);
      box(mats.accent, [1.26, 0.46, 0.1], [0, 1.2, -0.2]);
      const [fa, ra] = k.d.axlesF;
      both((s) => {
        k.fenderBand(fa, 0.45, 0.53, 1.3, 0.34, mats.paint, s * 0.76);
        k.fenderBand(ra, 0.45, 0.52, 1.22, 0.34, mats.paint, s * 0.76);
        box(mats.trim, [0.3, 0.06, (fa - 0.62) - (ra + 0.6)], [s * 0.76, 0.42, (fa - 0.62 + ra + 0.6) / 2]);
        cyl(mats.chrome, 0.15, 0.22, 'z', [s * 0.6, 0.84, 2.1], 12);
        roundLight('head', 0.12, [s * 0.6, 0.84, 2.21], false);
        roundLight('tail', 0.07, [s * 0.55, 0.78, -2.2], false);
      });
      box(mats.chrome, [0.42, 0.46, 0.08], [0, 0.66, 2.18]);
      for (const x of [-0.12, 0, 0.12]) box(mats.dark, [0.04, 0.38, 0.02], [x, 0.66, 2.225], null, { outline: false });
      cyl(mats.chrome, 0.07, 1.84, 'x', [0, 0.42, 2.24], 8);
      cyl(mats.chrome, 0.07, 1.84, 'x', [0, 0.42, -2.24], 8);
      box(mats.chrome, [0.04, 0.06, 0.2], [0, 1.0, 1.85], null, { outline: false });
      k.mirrors(0.95, 1.02, 0.62, mats.chrome);
      return { head: 0.84, eye: [-0.32, 1.25, -0.4] };
    },
  },
};

export function buildCarModel(modelId, { paint, style, assets } = {}) {
  const model = BY_ID[modelId] ?? BY_ID.sedan, spec = SPECS[model.id];
  const k = makeKit(style, assets, model, spec, paint ?? style.car?.body ?? model.paints[0]);
  const { mats, group, body, put, cylG, bins } = k;
  const d = { ...model.dims };
  k.d = { ...d, axlesF: spec.axles };
  const R = d.wheelRadius, tw = spec.tyre;

  const info = spec.build(k);

  const headAnchor = new THREE.Object3D();
  headAnchor.position.set(0, info.head, -d.length / 2 - 0.05);
  body.add(headAnchor);

  if (mats.neon) {
    const [fa, ra] = spec.axles, gap = R + 0.12, len = fa - ra - 2 * gap;
    k.both((s) => k.box(mats.neon, [0.04, 0.05, len], [s * (d.width / 2 + 0.02), d.rideHeight + 0.08, (fa + ra) / 2]));
    k.box(mats.neon, [d.width * 0.8, 0.04, 0.04], [0, d.rideHeight + 0.06, d.length / 2]);
    k.box(mats.neon, [d.width * 0.8, 0.04, 0.04], [0, d.rideHeight + 0.06, -d.length / 2]);
  }

  // Wheels: [front-left, front-right, rear-left, rear-right]. Front ones sit inside steering pivots.
  const wo = spec.wheel ?? {}, rimK = wo.rimK ?? 0.62;
  const rimMat = { dark: mats.trim, trim: mats.trim, chrome: mats.chrome, accent: mats.accent }[wo.rim] ?? mats.hub;
  const xw = spec.track ?? d.width / 2 - tw / 2 + 0.02;
  const wheels = [], steer = [];
  spec.axles.forEach((xa, i) => k.both((s) => {
    const w = new THREE.Group(), o = { parent: w };
    put(cylG(R, tw, 'x', 18), mats.tire, null, o);
    if (wo.whitewall) put(cylG(R * 0.8, tw + 0.012, 'x', 18), mats.white, null, o);
    put(cylG(R * rimK, tw + 0.024, 'x', 12), rimMat, null, o);
    put(cylG(R * (wo.cap ?? 0.2), tw + 0.06, 'x', 8), mats.chrome, null, o);
    if (wo.spokes !== false) {
      for (let j = 0; j < 3; j++) put(new THREE.BoxGeometry(tw + 0.04, R * rimK * 1.75, R * 0.1), mats.dark, xf([0, 0, 0], [j * PI / 3, 0, 0]), { parent: w, outline: false });
    }
    if (i === 0) {
      const st = new THREE.Group();
      st.position.set(s * xw, R, -xa);
      st.add(w);
      group.add(st);
      steer.push(st);
    } else {
      w.position.set(s * xw, R, -xa);
      group.add(w);
    }
    wheels.push(w);
  }));
  // both() runs left then right, so the order is FL, FR, RL, RR.

  const geoms = new Set(), outlines = [];
  const noOutline = new Set([mats.head, mats.tail, mats.neon]);
  for (const { parent, mat, ol, list } of bins.values()) {
    const g = list.length > 1 ? mergeGeometries(list) : list[0];
    if (list.length > 1) for (const x of list) x.dispose();
    const mesh = new THREE.Mesh(g, mat);
    mesh.castShadow = !noOutline.has(mat);
    parent.add(mesh);
    geoms.add(g);
    if (ol && assets?.mats?.outline && !noOutline.has(mat)) {
      const og = outlineGeometry(g);
      const o = new THREE.Mesh(og, assets.mats.outline);
      mesh.add(o);
      geoms.add(og);
      outlines.push(o);
    }
  }

  const blobG = new THREE.PlaneGeometry(d.width * 1.55, d.length * 1.22).rotateX(-PI / 2);
  const blob = new THREE.Mesh(blobG, mats.blob);
  blob.position.y = 0.03;
  blob.renderOrder = 1;
  group.add(blob);
  geoms.add(blobG);

  const [ex, ey, ef] = info.eye;
  return {
    id: model.id, group, body, wheels, steer, outlines, blob,
    lights: { head: mats.head, tail: mats.tail },
    headAnchor,
    cockpit: new THREE.Vector3(ex, ey, -ef),
    dims: d,
    dispose() {
      for (const g of geoms) g.dispose();
      for (const m of Object.values(mats)) m.dispose();
    },
  };
}
