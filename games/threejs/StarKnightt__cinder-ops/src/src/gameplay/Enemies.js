import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';
import { ENEMY_CONFIG, ENEMY_LOADOUTS, WORLD } from '../core/Constants.js';
import { eventBus, Events } from '../core/EventBus.js';
import { gameState } from '../core/GameState.js';

const _to = new THREE.Vector3();
const _down = new THREE.Vector3(0, -1, 0);
const _aim = new THREE.Vector3();
const _inv = new THREE.Quaternion();
const _local = new THREE.Vector3();
const _eBreath = new THREE.Euler();
const _qBreath = new THREE.Quaternion();
const _eye = new THREE.Vector3();
const _muzzle = new THREE.Vector3();
const _edir = new THREE.Vector3();
const _impact = new THREE.Vector3();
const _body = new THREE.Vector3();
const _off = new THREE.Vector3();
const _cands = [];

const AXES = ['x', 'y', 'z'];

// Segment a→b versus AABB slab test. Used for enemy muzzle → player eye
// line-of-sight, so walls and tall cover actually stop bullets.
function segHitsAabb(a, b, box) {
  let t0 = 0;
  let t1 = 1;
  for (const k of AXES) {
    const d = b[k] - a[k];
    if (Math.abs(d) < 1e-9) {
      if (a[k] < box.min[k] || a[k] > box.max[k]) return false;
    } else {
      let u0 = (box.min[k] - a[k]) / d;
      let u1 = (box.max[k] - a[k]) / d;
      if (u0 > u1) { const t = u0; u0 = u1; u1 = t; }
      if (u0 > t0) t0 = u0;
      if (u1 < t1) t1 = u1;
      if (t0 > t1) return false;
    }
  }
  return true;
}

// Nearest entry distance of ray origin+dir·t into an AABB, or Infinity.
function rayAabbT(origin, dir, box, maxDist) {
  let t0 = 0;
  let t1 = maxDist;
  for (const k of AXES) {
    const d = dir[k];
    if (Math.abs(d) < 1e-9) {
      if (origin[k] < box.min[k] || origin[k] > box.max[k]) return Infinity;
    } else {
      let u0 = (box.min[k] - origin[k]) / d;
      let u1 = (box.max[k] - origin[k]) / d;
      if (u0 > u1) { const t = u0; u0 = u1; u1 = t; }
      if (u0 > t0) t0 = u0;
      if (u1 < t1) t1 = u1;
      if (t0 > t1) return Infinity;
    }
  }
  return t0;
}

/* c23: ~12% taller than the c22 5-head stump; helmet shrink in dressHead
 * is what pushes the silhouette toward a CS2 7.5-head read. */
const BODY_SCALE = 1.18;

/* Player hit zones, world metres. Derived from the c33/c34 visual meshes
 * (hips.scale = BODY_SCALE) — NOT the c21 plan's 0.17 / 0.38 / 0.55, which
 * predated the +70% skull and left a gap at the trapezius / outer deltoid.
 *
 *   skull half-width  0.062×1.18 = 0.073
 *   helm+rim envelope ≈ 0.10 from skull origin
 *   trap/yoke         ≈ 0.19 from skull (reads as head at range)
 *   outer deltoid     ≈ 0.27 from skull, ≈ 0.46 from a body center 0.62 down
 *
 * rayHit uses sphere *entry* t (not the closest-point t). Closest-point
 * recorded the hit at the center, so a wall whose AABB ended in the
 * (dist − r … dist) window — typical when peeking a head over cover —
 * rejected a visually-true sniper shot. */
export const HIT_ZONES = {
  headR: 0.22,
  bodyR: 0.46,
  bodyDown: 0.62,
};

/** First positive intersection of ray origin+dir·t with a sphere, or Infinity. */
export function raySphereT(ox, oy, oz, dx, dy, dz, cx, cy, cz, r, maxT) {
  const ocx = ox - cx;
  const ocy = oy - cy;
  const ocz = oz - cz;
  const b = ocx * dx + ocy * dy + ocz * dz;
  const c = ocx * ocx + ocy * ocy + ocz * ocz - r * r;
  const disc = b * b - c;
  if (disc < 0) return Infinity;
  const s = Math.sqrt(disc);
  const t0 = -b - s;
  if (t0 > 1e-4 && t0 <= maxT) return t0;
  const t1 = -b + s;
  if (t1 > 1e-4 && t1 <= maxT) return t1;
  return Infinity;
}

function std(color, roughness, metalness, mapSet, extras = {}) {
  const mat = new THREE.MeshStandardMaterial({
    color,
    roughness,
    metalness,
    envMapIntensity: extras.env ?? 0.28,
    emissive: extras.em || 0x000000,
    emissiveIntensity: extras.emI || 0,
    /* Cloth parts multiply a per-vertex mottle (see addMottle): one flat
     * albedo per part was the "plastic toy" read — real fatigues shade
     * across a single panel. Every shared geo carries the attribute, so
     * enabling it per-material is safe. */
    vertexColors: !!(extras.mottle || extras.vc),
  });
  if (mapSet) {
    if (mapSet.map && extras.albedo) mat.map = mapSet.map;
    if (mapSet.normalMap) {
      mat.normalMap = mapSet.normalMap;
      mat.normalScale = new THREE.Vector2(0.55, 0.55);
    }
    if (mapSet.ormMap) {
      mat.aoMap = mapSet.ormMap;
      mat.roughnessMap = mapSet.ormMap;
      mat.aoMapIntensity = 0.7;
    }
  }
  return mat;
}

function kitFrom(mats) {
  const maps = mats?._maps || {};
  const fabric = maps.fabric || maps.glove;
  const wood = maps.akwood || maps.wood || maps.polymer;
  const gun = maps.gunmetal || maps.metal;
  /* c7 mint-green: cloth 0x7a8468 + sun 3.85 + env 1.18 + ACES 1.48
   * washed the green channel to ~150,210,160. Skin/shemagh blew to a
   * white "hat". These are the real enemy meshes — kit was too light. */
  /* c22 re-skin toward ak-inferno.jpg agents: the c20 kit was still a
   * SATURATED-GREEN plastic toy (torso green channel led red by 8+). CS2
   * cloth is desaturated warm olive/brown-grey — red >= green everywhere
   * except a hint on the jacket — with tan webbing clearly LIGHTER and
   * warmer than the jacket, and trousers a neutral dark grey-brown.
   * Cloth-family materials multiply the shared vertex mottle (mottle:
   * true) so no panel is one flat tone. */
  return {
    cloth: std(0x53503b, 0.94, 0.02, fabric, { env: 0.08, mottle: true }),
    pants: std(0x35322b, 0.94, 0.02, fabric, { env: 0.07, mottle: true }),
    vest: std(0x7d6b48, 0.88, 0.02, fabric, { env: 0.10, mottle: true }),
    plate: std(0x564e3c, 0.78, 0.05, maps.polymer, { env: 0.12, mottle: true }),
    pouch: std(0x776547, 0.90, 0.02, fabric, { env: 0.10, mottle: true }),
    skin: std(0x6a4c38, 0.80, 0.02, null, { env: 0.10 }),
    /* c31: c30's 0xb08a62 blew to 215/171/83 in scope sun — a bulb under
     * the helmet. Sunlit skin must cap ~150/115/80, so the base drops to
     * a darker tan, fully matte (rough 0.97, env 0), and paintSkullFace
     * bakes a helmet-brim shadow into the upper face. */
    /* Blue is held high in the base: the warm sun + ACES crushes B ~2.5x
     * harder than R, so an already-warm base renders pure orange. */
    faceSkin: std(0x736050, 0.97, 0.00, null, { env: 0.0, vc: true }),
    skull: std(0x2a261c, 0.94, 0.00, null, { env: 0.02 }),
    /* Neck matches the shadowed-skin family — 0x8a6a4c was a second
     * glowing amber ball under the chin at scope range. */
    neck: std(0x4e4136, 0.96, 0.00, null, { env: 0.02 }),
    brow: std(0x5a4030, 0.94, 0.00, null, { env: 0.02 }),
    belt: std(0x1e1a14, 0.86, 0.03, maps.glove, { env: 0.06, mottle: true }),
    rifle: std(0x1a1c1a, 0.62, 0.42, gun, { env: 0.18, albedo: true }),
    /* c31 value breaks on the carried gun: dark receiver vs warm wood
     * furniture vs grey steel barrel vs dark-grey mag — the c30 gun was
     * one flat black L-slab. */
    furniture: std(0x5e4728, 0.80, 0.03, wood, { env: 0.10, albedo: true }),
    steel: std(0x3a3d40, 0.70, 0.35, gun, { env: 0.14 }),
    mag: std(0x2c2925, 0.78, 0.22, gun, { env: 0.10 }),
    helm: std(0x3e3a30, 0.94, 0.00, maps.polymer, { env: 0.0, mottle: true }),
    brim: std(0x302c24, 0.96, 0.00, null, { env: 0.0, mottle: true }),
    /* Sleeves a half-step lighter than the torso: the old 0x4e5442 green
     * made the deltoids pop off as separate pods (fix 1). */
    sleeve: std(0x4c4835, 0.92, 0.02, fabric, { env: 0.08, mottle: true }),
    visor: std(0x0c0a08, 0.22, 0.08, null, { env: 0.18 }),
    shemagh: std(0x3a3226, 0.96, 0.00, null, { env: 0.0, mottle: true }),
    /* c23 wrap: dark cloth over the whole skull — never a skin/orange card.
     * c27: no fabric maps / no env — the sphere + orm glossy dips was the
     * bowling-ball hotspot in scope. */
    balaclava: std(0x262218, 0.96, 0.00, null, { env: 0.0, mottle: true }),
    /* Eye slit only: near-black recess, a step below the wrap. The c22
     * 0x453930 + skin chin still read as a minifig orange bar in scope. */
    eye: std(0x1a1612, 0.92, 0.02, null, { env: 0.04 }),
    /* Desaturated skin-tan slit — c24 0x6a4c38 read as a glowing orange bar. */
    eyeTan: std(0x3c342c, 0.90, 0.02, null, { env: 0.05 }),
    /* Gloves MUST read against the black rifle — c22 0x2c2820 vanished
     * into kit.rifle 0x2a2c28, which is why the critic saw no hands.
     * c31: but 0x4a3c2c rendered as saturated RUST ovals under the warm
     * grade (79/46/19 measured) — the critic's "painted camo ovals".
     * Darker, desaturated leather keeps the hand read without the blob. */
    glove: std(0x352f27, 0.92, 0.02, maps.glove, { env: 0.06, mottle: true }),
    knuckle: std(0x3e372d, 0.90, 0.02, maps.glove, { env: 0.06, mottle: true }),
    cap: std(0x242218, 0.88, 0.02, fabric, { env: 0.06, mottle: true }),
    boot: std(0x181410, 0.92, 0.02, maps.glove, { env: 0.05, mottle: true }),
    strap: std(0x1c1a16, 0.86, 0.03, maps.glove, { env: 0.06, mottle: true }),
    contact: mats?.contact || null,
    bootAO: new THREE.MeshBasicMaterial({
      color: 0x0c0a08, transparent: true, opacity: 0.40,
      depthWrite: false, fog: false,
    }),
  };
}

function mesh(geo, mat, x, y, z, sx, sy, sz) {
  const m = new THREE.Mesh(geo, mat);
  m.position.set(x, y, z);
  m.scale.set(sx, sy, sz);
  m.castShadow = true;
  m.receiveShadow = true;
  m.frustumCulled = false;
  m.matrixAutoUpdate = true;
  if (m.geometry.attributes.uv && !m.geometry.attributes.uv2) {
    m.geometry.setAttribute('uv2', m.geometry.attributes.uv);
  }
  return m;
}

function orientDown(node, from, to) {
  _aim.copy(to).sub(from);
  const len = _aim.length();
  if (len < 1e-5) return 0;
  node.quaternion.setFromUnitVectors(_down, _aim.multiplyScalar(1 / len));
  return len;
}

/* Per-vertex cloth mottle: a value ramp (darker low + positional noise)
 * baked into every shared geo once. Materials opt in via vertexColors, so
 * a single olive panel picks up the soft tonal drift real fatigues have.
 * Slightly warm-biased so the variation never reads as green sheen. */
function addMottle(geo) {
  const pos = geo.attributes.position;
  const col = new Float32Array(pos.count * 3);
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i);
    const y = pos.getY(i);
    const z = pos.getZ(i);
    const n1 = Math.sin(x * 21.7 + z * 15.3 + 1.7) * Math.sin(y * 17.9 + x * 9.1);
    const n2 = Math.sin((x + y) * 39.3 + 0.6) * Math.sin((z - y) * 29.7);
    const v = THREE.MathUtils.clamp(1 + 0.075 * n1 + 0.045 * n2 + 0.03 * y, 0.86, 1.10);
    col[i * 3] = v;
    col[i * 3 + 1] = v * 0.985;
    col[i * 3 + 2] = v * 0.96;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
}

function makeGeos() {
  /* c22 fix 1: segment counts raised so nothing shows hex facets at 10 m
   * (sph 14x12 put visible flats on every shoulder/elbow cap). ~+2.5k tris
   * per enemy, ~+20k across the 8-man squad — inside the 30k budget. */
  const geos = {
    cyl: new THREE.CylinderGeometry(1, 1, 1, 16),
    tap: new THREE.CylinderGeometry(0.68, 1, 1, 16),
    inv: new THREE.CylinderGeometry(1, 0.66, 1, 16),
    sph: new THREE.SphereGeometry(1, 20, 14),
    hemi: new THREE.SphereGeometry(1, 20, 12, 0, Math.PI * 2, 0, Math.PI * 0.58),
    /* Shallow helmet cap — stays above the equator so it cannot mushroom. */
    helmCap: new THREE.SphereGeometry(1, 18, 10, 0, Math.PI * 2, 0, Math.PI * 0.38),
    rbox: new RoundedBoxGeometry(1, 1, 1, 3, 0.12),
    /* Cloth volumes (torso/pelvis/satchel) use a much rounder box so the
     * chest reads as a stuffed jacket, not a crate (fix 1). */
    soft: new RoundedBoxGeometry(1, 1, 1, 3, 0.24),
    plate: new RoundedBoxGeometry(1, 1, 1, 2, 0.08),
    disc: new THREE.CircleGeometry(1, 22),
    /* Cheap knuckle/palm cap — the shared 20×14 sph is 560 tris; 8×6 is ~80. */
    knob: new THREE.SphereGeometry(1, 8, 6),
  };
  for (const g of Object.values(geos)) addMottle(g);
  /* c34: 20×14 left brow/sockets between rings — paint interpolated
   * to a flat dome. 32×24 is enough verts for a 35px face. No mottle. */
  geos.skull = new THREE.SphereGeometry(1, 32, 24);
  geos.cylFold = foldShade(geos.cyl);
  geos.tapFold = foldShade(geos.tap);
  /* c30: calves thicken toward thigh width (was 0.78→0.52 stovepipe).
   * c33: close-range still read as stilts — raise the ankle taper so the
   * shin keeps thigh mass instead of collapsing to a pipe. */
  const thighSrc = new THREE.CylinderGeometry(1, 0.80, 1, 16);
  const calfSrc = new THREE.CylinderGeometry(0.96, 0.78, 1, 16);
  addMottle(thighSrc);
  addMottle(calfSrc);
  geos.thigh = foldShade(thighSrc);
  geos.calf = foldShade(calfSrc);
  /* Face card AFTER addMottle — cloth mottle would paint the skin green. */
  geos.faceCard = paintFaceCard(new THREE.CircleGeometry(0.5, 20));
  return geos;
}

/* Paint a CS2-style face onto a UNIT sphere. Front is local -Z (rifle
 * side). Scalp/sides stay dark so they merge with the helmet. */
function paintSkullFace(geo) {
  const pos = geo.attributes.position;
  const col = new Float32Array(pos.count * 3);
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i);
    const y = pos.getY(i);
    const z = pos.getZ(i);
    const front = THREE.MathUtils.smoothstep(0.05, -0.42, z);
    /* Raised so the forehead is actually face (c30's 0.28 left brow in
     * the scalp fade — features blended into one darker dome). */
    const lower = THREE.MathUtils.smoothstep(0.42, -0.10, y);
    const faceM = front * lower;
    /* c34: projection-aligned. Equator (y=0) is the first visible tan
     * row under the brim (~screen 360); lock (490,372) is y≈-0.49.
     * Brow on the equator, sockets on ±0.38, mouth on the chin ring. */
    const brow = Math.max(0, 1 - Math.abs(y + 0.02) / 0.10)
      * THREE.MathUtils.smoothstep(0.52, 0.14, Math.abs(x)) * front;
    const eyeL = Math.hypot((x + 0.38) / 0.22, (y + 0.04) / 0.14);
    const eyeR = Math.hypot((x - 0.38) / 0.22, (y + 0.04) / 0.14);
    const socket = Math.max(0, 1 - Math.min(eyeL, eyeR)) * faceM;
    const pupil = Math.max(0, 1 - Math.min(
      Math.hypot((x + 0.38) / 0.055, (y + 0.04) / 0.042),
      Math.hypot((x - 0.38) / 0.055, (y + 0.04) / 0.042),
    )) * faceM;
    const mouth = Math.max(0, 1 - Math.abs(y + 0.68) / 0.08)
      * THREE.MathUtils.smoothstep(0.40, 0.10, Math.abs(x)) * faceM;
    const jaw = THREE.MathUtils.smoothstep(-0.74, -0.96, y) * faceM;
    /* Helmet-brim shadow: a face under a brim is darkest at the hairline
     * and opens up toward the jaw — without it the whole sphere catches
     * full sun and reads emissive (c30 scope tell). */
    const brim = 1.0 - 0.46 * THREE.MathUtils.smoothstep(-0.06, 0.32, y);
    const skin = (1.0 - 0.42 * brow - 0.28 * socket - 0.72 * pupil - 0.36 * mouth - 0.16 * jaw) * brim;
    const scalp = 0.22;
    const r = THREE.MathUtils.lerp(scalp, skin, faceM);
    const gch = THREE.MathUtils.lerp(scalp, skin * 0.99, faceM);
    /* Blue held AT red so warm sun doesn't push the face amber. */
    const b = THREE.MathUtils.lerp(scalp * 0.90, skin, faceM);
    col[i * 3] = r;
    col[i * 3 + 1] = gch;
    col[i * 3 + 2] = b;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  geo.computeVertexNormals();
  return geo;
}

/* Darken the hemi cut so the rim reads as a hard shell, not a soft cap.
 * Multiplies the shared cloth mottle. Sits on the bowl — does not grow
 * downward over the face. */
function paintHelmRim(geo) {
  const pos = geo.attributes.position;
  const src = geo.attributes.color;
  const col = new Float32Array(pos.count * 3);
  for (let i = 0; i < pos.count; i++) {
    const y = pos.getY(i);
    const rim = THREE.MathUtils.smoothstep(0.22, -0.22, y);
    const v = 1.0 - 0.58 * rim;
    const r = src ? src.getX(i) : 1;
    const gch = src ? src.getY(i) : 1;
    const b = src ? src.getZ(i) : 1;
    col[i * 3] = r * v;
    col[i * 3 + 1] = gch * v;
    col[i * 3 + 2] = b * v * 0.94;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

/* Vertex-shaded operator face: brow shadow, eye sockets, pupils, mouth.
 * One plane — not a stack of boxes. */
function paintFaceCard(geo) {
  const pos = geo.attributes.position;
  const col = new Float32Array(pos.count * 3);
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i);
    const y = pos.getY(i);
    const brow = THREE.MathUtils.smoothstep(0.16, 0.36, y)
      * THREE.MathUtils.smoothstep(0.50, 0.26, Math.abs(x));
    const eyeL = Math.hypot((x + 0.15) / 0.10, (y - 0.08) / 0.055);
    const eyeR = Math.hypot((x - 0.15) / 0.10, (y - 0.08) / 0.055);
    const socket = Math.max(0, 1 - Math.min(eyeL, eyeR));
    const pupil = Math.max(0, 1 - Math.min(
      Math.hypot((x + 0.15) / 0.028, (y - 0.08) / 0.022),
      Math.hypot((x - 0.15) / 0.028, (y - 0.08) / 0.022),
    ));
    const nose = THREE.MathUtils.smoothstep(0.10, 0.02, Math.hypot(x * 2.2, y + 0.04));
    const mouth = THREE.MathUtils.smoothstep(0.12, 0.04, Math.hypot(x * 1.8, y + 0.26));
    const cheek = THREE.MathUtils.smoothstep(0.22, 0.08, Math.hypot(Math.abs(x) - 0.18, y + 0.06));
    const v = THREE.MathUtils.clamp(
      1.0 - 0.32 * brow - 0.24 * socket - 0.72 * pupil - 0.18 * mouth + 0.08 * nose + 0.04 * cheek,
      0.22, 1.02,
    );
    col[i * 3] = v;
    col[i * 3 + 1] = v * 0.96;
    col[i * 3 + 2] = v * 0.88;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  geo.computeVertexNormals();
  return geo;
}

/* Cheap trouser crease: modulate the shared mottle so legs aren't pipes. */
function foldShade(src) {
  const geo = src.clone();
  const p = geo.attributes.position;
  const srcC = geo.attributes.color;
  const c = new Float32Array(p.count * 3);
  for (let i = 0; i < p.count; i++) {
    const y = p.getY(i);
    const x = p.getX(i);
    const z = p.getZ(i);
    const crease = Math.abs(Math.sin(y * Math.PI * 2.6 + 0.25));
    const side = 0.55 + 0.45 * Math.sin(x * 5.5 + z * 3.8);
    const fold = 0.70 + 0.30 * crease * side;
    const b = srcC ? srcC.getX(i) : 1;
    c[i * 3] = b * fold;
    c[i * 3 + 1] = b * fold * 0.99;
    c[i * 3 + 2] = b * fold * 0.96;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(c, 3));
  return geo;
}

function buildLimb(parent, from, to, tip, kit, g, upperMat, lowerMat, upperR, lowerR, role) {
  const sh = new THREE.Group();
  sh.position.copy(from);
  const upperLen = orientDown(sh, from, to);
  const uLen = role === 'arm' ? upperLen * 0.86 : upperLen;
  const upperGeo = role === 'leg' && g.thigh ? g.thigh : (role === 'leg' && g.cylFold ? g.cylFold : g.cyl);
  sh.add(mesh(upperGeo, upperMat, 0, -uLen * 0.5, 0, upperR * (role === 'arm' ? 1.02 : 1), uLen * 0.92, upperR * (role === 'arm' ? 0.98 : 1)));
  if (role === 'arm') {
    /* c31: the c30 deltoid stack (drape 1.78x + cap 1.52x on upperR
     * 0.086) rendered shoulder balls 3-4x head width. Whole mass shrunk
     * so the widest shoulder point is ~1.4x helmet width, and the cap is
     * now a thin rolled-sleeve seam ring — a sleeve, not a ball joint. */
    /* c32: mass hangs DOWN the sleeve. The c31 tap sat at +Y (toward the
     * ear) and the drape rbox still read as a raised pad slab once both
     * arms were assembled. Keep the slim radii; drop the apex below the
     * joint so the silhouette is neck → slope → arm, not head-in-a-well. */
    sh.add(mesh(g.sph, upperMat, 0, -0.012, 0, upperR * 0.84, upperR * 0.50, upperR * 0.82));
    sh.add(mesh(g.rbox, upperMat, 0, -0.030, 0.002, upperR * 1.12, upperR * 0.74, upperR * 1.06));
    sh.add(mesh(g.tap, upperMat, 0, -0.008, 0, upperR * 0.94, 0.018, upperR * 0.88));
  } else {
    /* Trouser hip — soft cloth volume, not a sun-catching sphere that
     * read as tan skin/shorts between jacket hem and thighs (c29 #6).
     * c33: larger hip cap so the thigh roots read as planted trousers. */
    sh.add(mesh(g.soft, upperMat, 0, -0.018, 0.004, upperR * 1.48, upperR * 1.52, upperR * 1.34));
  }

  const el = new THREE.Group();
  el.position.set(0, -uLen, 0);
  _inv.copy(sh.quaternion).invert();
  _local.copy(tip).sub(from).applyQuaternion(_inv);
  const lowerLen = orientDown(el, new THREE.Vector3(0, -uLen, 0), _local);
  const lowerGeo = role === 'leg' && g.calf ? g.calf : (role === 'leg' && g.tapFold ? g.tapFold : g.tap);
  el.add(mesh(lowerGeo, lowerMat, 0, -lowerLen * 0.5, 0, lowerR * (role === 'arm' ? 0.82 : 1), lowerLen * 0.94, lowerR * (role === 'arm' ? 0.78 : 1)));
  if (role === 'arm') {
    el.add(mesh(g.sph, lowerMat, 0, 0, 0, lowerR * 1.05, lowerR * 0.82, lowerR * 1.05));
    /* Sleeve cuff swallows the wrist so the forearm doesn't end as a stick
     * behind a floating rifle. Hands live on the gun. */
    el.add(mesh(g.cyl, upperMat, 0, -lowerLen + 0.028, 0, lowerR * 1.18, 0.055, lowerR * 1.10));
    el.add(mesh(g.cyl, kit.glove || kit.belt, 0, -lowerLen + 0.006, 0, lowerR * 0.92, 0.028, lowerR * 0.86));
  } else {
    /* Shaped boot: ankle cuff + heel + thin sole + rounded toe.
     * c33: grown with the thicker calf so the foot isn't a pin under a pipe. */
    el.add(mesh(g.cyl, kit.boot, 0, -lowerLen - 0.012, 0.016, 0.078, 0.036, 0.076));
    el.add(mesh(g.rbox, kit.boot, 0, -lowerLen - 0.066, -0.006, 0.082, 0.046, 0.066));
    el.add(mesh(g.rbox, kit.boot, 0, -lowerLen - 0.096, 0.036, 0.096, 0.018, 0.162));
    el.add(mesh(g.knob, kit.boot, 0, -lowerLen - 0.076, 0.092, 0.066, 0.036, 0.074));
    if (kit.bootAO) {
      const ao = mesh(g.disc, kit.bootAO, 0, -lowerLen - 0.104, 0.020, 0.136, 0.136, 0.136);
      ao.rotation.x = -Math.PI / 2;
      ao.castShadow = false;
      ao.receiveShadow = false;
      ao.renderOrder = 1;
      el.add(ao);
    }
  }
  sh.add(el);
  parent.add(sh);
  return sh;
}

/* c31 rebuild: the c30 carried gun was a featureless black L-slab (the
 * vertical stroke was a 0.20-long STRAIGHT box mag). Now: short dark
 * receiver, warm wood handguard/grip/stock (value break), grey steel
 * barrel protruding past the handguard w/ front sight, stock with a comb
 * step + butt pad, and a curved banana magazine chained from three
 * rearward-sweeping segments. */
function buildRifle(kit, g, loadout = 'rifle') {
  const gun = new THREE.Group();
  const shotgun = loadout === 'shotgun';
  const steel = kit.steel || kit.rifle;
  /* Receiver: short dark box + dust-cover step, not a full-length slab. */
  gun.add(mesh(g.rbox, kit.rifle, 0, 0.012, 0.045, 0.042, 0.052, 0.235));
  gun.add(mesh(g.rbox, kit.rifle, 0, 0.044, 0.020, 0.034, 0.020, 0.150));
  gun.add(mesh(g.rbox, steel, 0, 0.052, -0.040, 0.014, 0.016, 0.030));
  /* Wood handguard — clearly warmer than the receiver. */
  gun.add(mesh(g.rbox, kit.furniture, 0, 0.006, -0.155, 0.046, 0.042, 0.150));
  /* Barrel: distinct grey cylinder protruding well past the handguard. */
  const barrel = mesh(g.cyl, steel, 0, 0.016, -0.335, 0.0085, 0.23, 0.0085);
  barrel.rotation.x = Math.PI / 2;
  gun.add(barrel);
  const brake = mesh(g.cyl, kit.rifle, 0, 0.016, -0.465, 0.0125, 0.038, 0.0125);
  brake.rotation.x = Math.PI / 2;
  gun.add(brake);
  gun.add(mesh(g.rbox, kit.rifle, 0, 0.040, -0.415, 0.011, 0.042, 0.013));
  if (shotgun) {
    // Shotgunner read (plan §8): no gas tube, under-barrel tube magazine.
    const tubeMag = mesh(g.cyl, steel, 0, -0.006, -0.26, 0.0075, 0.20, 0.0075);
    tubeMag.rotation.x = Math.PI / 2;
    gun.add(tubeMag);
  } else {
    const gas = mesh(g.cyl, steel, 0, 0.034, -0.20, 0.005, 0.13, 0.005);
    gas.rotation.x = Math.PI / 2;
    gun.add(gas);
    /* Banana mag: three chained segments, bottom sweeping toward the
     * stock (negative rot.x = rearward), dark grey vs the receiver. */
    const magMat = kit.mag || kit.rifle;
    const segs = [
      [-0.078, 0.029, -0.26],
      [-0.140, 0.055, -0.55],
      [-0.191, 0.099, -0.88],
    ];
    for (const [y, z, rx] of segs) {
      const seg = mesh(g.rbox, magMat, 0, y, z, 0.030, 0.078, 0.052);
      seg.rotation.x = rx;
      gun.add(seg);
    }
    const plate = mesh(g.rbox, magMat, 0, -0.212, 0.124, 0.033, 0.016, 0.058);
    plate.rotation.x = -0.88;
    gun.add(plate);
  }
  /* Raked wood pistol grip. */
  const grip = mesh(g.rbox, kit.furniture, 0, -0.050, 0.112, 0.032, 0.085, 0.045);
  grip.rotation.x = -0.30;
  gun.add(grip);
  /* Stock: dropped slab + comb step + dark butt pad. */
  const stock = mesh(g.rbox, kit.furniture, 0, -0.010, 0.255, 0.036, 0.048, 0.185);
  stock.rotation.x = 0.10;
  gun.add(stock);
  gun.add(mesh(g.rbox, kit.furniture, 0, 0.026, 0.180, 0.032, 0.026, 0.085));
  const butt = mesh(g.rbox, kit.rifle, 0, -0.020, 0.348, 0.040, 0.070, 0.018);
  butt.rotation.x = 0.10;
  gun.add(butt);
  addGripHands(gun, kit, g, shotgun);
  return gun;
}

/* Readable gloved hands on the carried rifle/shotgun. Palms + wrapping
 * fingers + thumbs — c22's two dark rboxes matched the receiver and
 * vanished at 10 m. Leather is a step warmer than the rifle so the grip
 * reads in scope and street. */
function addGripHands(gun, kit, g, shotgun) {
  const glove = kit.glove || kit.belt;
  const pad = kit.knuckle || glove;
  const sleeve = kit.sleeve || kit.cloth;
  const zGuard = shotgun ? -0.14 : -0.165;
  const zGrip = shotgun ? 0.078 : 0.110;

  /* Support mitt + thumb — 15 m read is a mitten with a thumb, not four
   * merged finger sticks. c31: mitt shrunk ~15% — at gun scale 1.35 the
   * old pads read as brown ovals floating on the chest. */
  gun.add(mesh(g.knob, glove, 0.000, -0.024, zGuard, 0.026, 0.018, 0.031));
  gun.add(mesh(g.rbox, pad, 0.002, 0.004, zGuard, 0.031, 0.021, 0.036));
  const thL = mesh(g.cyl, glove, -0.040, 0.006, zGuard - 0.024, 0.014, 0.056, 0.014);
  thL.rotation.x = 1.05;
  thL.rotation.z = -0.55;
  gun.add(thL);
  gun.add(mesh(g.knob, glove, -0.048, 0.024, zGuard - 0.048, 0.015, 0.013, 0.015));
  const cuffL = mesh(g.cyl, sleeve, -0.032, -0.010, zGuard + 0.050, 0.022, 0.032, 0.020);
  cuffL.rotation.x = 0.55;
  gun.add(cuffL);

  /* Grip mitt + thumb on the pistol grip. */
  gun.add(mesh(g.knob, glove, 0.010, -0.040, zGrip, 0.024, 0.026, 0.020));
  gun.add(mesh(g.rbox, pad, 0.012, -0.026, zGrip + 0.002, 0.022, 0.028, 0.024));
  const thR = mesh(g.cyl, glove, 0.026, -0.022, zGrip - 0.026, 0.011, 0.038, 0.011);
  thR.rotation.x = 1.05;
  gun.add(thR);
  gun.add(mesh(g.knob, glove, 0.028, -0.006, zGrip - 0.042, 0.012, 0.011, 0.012));
  const cuffR = mesh(g.cyl, sleeve, 0.022, -0.018, zGrip + 0.034, 0.020, 0.030, 0.018);
  cuffR.rotation.x = 0.40;
  gun.add(cuffR);
}

function dressHead(variant, head, kit, g) {
  /* c30: ONE painted skull. Face lives in the vertex colors of that
   * sphere — no extra card/disc. Helmet hugs the same origin.
   * c33: c32 shrank the vest/pads and left this assembly untouched, so
   * the head that used to hide between giant pads now reads as a pin.
   * Grow ~70% so the tan FACE (not just the dark helm) reads at range.
   * Shoulders stay at the c32 roots — the assembled span lands ~2.3-2.5x
   * the new helm, which is the CS2 agent read; do not re-inflate pads.
   * Face material / brim shadow / hemisphere helm are unchanged. */
  const tilt = variant === 1 ? 0.05 : variant === 2 ? -0.04 : 0.0;
  const skullGeo = paintSkullFace((g.skull || g.sph).clone());
  const skull = mesh(skullGeo, kit.faceSkin, 0, 0.000, 0.002, 0.062, 0.054, 0.058);
  head.add(skull);

  /* c34: c33 sat the hemi too high — at 3m it read beret. Drop the rim
   * ~10% (crown stays on the skull top). Dark rim paint + a thin lip
   * that sits ON the cut (not hanging over the face) restore the shell. */
  const helm = mesh(paintHelmRim(g.hemi.clone()), kit.helm, 0, 0.021, 0.002, 0.069, 0.033, 0.065);
  helm.rotation.x = -0.11 + tilt;
  head.add(helm);
  const rim = mesh(g.tap, kit.brim, 0, 0.014, 0.002, 0.074, 0.008, 0.070);
  rim.rotation.x = -0.11 + tilt;
  head.add(rim);

  /* c32: longer neck column so the helmet crests a visible gap above the
   * dropped shoulder line. Same 0x4e4136 — do not brighten.
   * c33: thicker than c32 but still clearly narrower than the new jaw. */
  const neck = mesh(g.cyl, kit.neck, 0, -0.080, 0.002, 0.025, 0.046, 0.024);
  head.add(neck);
  return skull;
}

/* c30: break the mirrored A-pose. Shins ~20% shorter than the old 0.44
 * vertical pipes; knees come forward so feet still plant. */
function legStance(variant) {
  if (variant === 1) {
    return {
      lHip: new THREE.Vector3(-0.138, -0.05, 0.08),
      lKnee: new THREE.Vector3(-0.120, -0.50, 0.26),
      lAnkle: new THREE.Vector3(-0.085, -0.89, 0.18),
      rHip: new THREE.Vector3(0.175, -0.07, -0.02),
      rKnee: new THREE.Vector3(0.245, -0.56, 0.12),
      rAnkle: new THREE.Vector3(0.220, -0.92, -0.04),
    };
  }
  if (variant === 2) {
    return {
      lHip: new THREE.Vector3(-0.172, -0.04, 0.02),
      lKnee: new THREE.Vector3(-0.240, -0.52, 0.18),
      lAnkle: new THREE.Vector3(-0.190, -0.89, 0.04),
      rHip: new THREE.Vector3(0.172, -0.04, 0.04),
      rKnee: new THREE.Vector3(0.230, -0.54, 0.16),
      rAnkle: new THREE.Vector3(0.175, -0.89, 0.02),
    };
  }
  return {
    lHip: new THREE.Vector3(-0.168, -0.06, 0.04),
    lKnee: new THREE.Vector3(-0.255, -0.52, 0.18),
    lAnkle: new THREE.Vector3(-0.230, -0.90, 0.06),
    rHip: new THREE.Vector3(0.138, -0.06, 0.00),
    rKnee: new THREE.Vector3(0.110, -0.54, 0.16),
    rAnkle: new THREE.Vector3(0.095, -0.90, 0.02),
  };
}

function dressKit(variant, spine, hips, kit, g) {
  /* Vest carrier wrapping the ribcage: soft rounded wrap slightly proud of
   * the chest on all four sides, so the silhouette steps chest -> vest ->
   * plate instead of sweeping as one cone. */
  /* c32: vest was 0.325 wide (4.1x helmet) with its top at y=0.348 —
   * a flat slab at jaw height that made the assembled olive read 5x
   * even after the c31 deltoid shrink. Narrow to ~3.0x and drop the
   * yoke so the head sits clearly above the carrier. */
  spine.add(mesh(g.soft, kit.vest, 0, 0.186, 0.008, 0.238, 0.205, 0.178));
  /* Player-facing front is -z (rifle side): the c19 "front" plate and the
   * whole pouch row sat at +z — on the BACK, invisible for the entire
   * pass. Big plate + pouches now live on -z. */
  spine.add(mesh(g.plate, kit.plate, 0, 0.200, -0.108, 0.162, 0.168, 0.028));
  spine.add(mesh(g.plate, kit.plate, 0, 0.178, 0.104, 0.144, 0.148, 0.022));
  /* Straps follow the trapezius (high at collar, low at deltoid) instead
   * of sitting as ear-height tan bars on top of the pads. */
  for (const side of [-1, 1]) {
    const strap = mesh(g.rbox, kit.vest, side * 0.058, 0.278, 0.004, 0.032, 0.016, 0.092);
    strap.rotation.z = -side * 0.44;
    spine.add(strap);
  }
  /* 2-3 tan mag pouches on the FRONT plate, below the carried rifle. */
  const n = variant === 1 ? 2 : 3;
  for (let i = 0; i < n; i++) {
    const x = n === 2 ? -0.050 + i * 0.10 : -0.092 + i * 0.092;
    spine.add(mesh(g.rbox, kit.pouch, x, 0.068, -0.132, 0.054, 0.080, 0.044));
  }
  spine.add(mesh(g.rbox, kit.strap, 0, 0.255, -0.116, 0.168, 0.012, 0.014));
  /* Slung satchel (fix 6, asymmetry): cross-chest sling running shoulder
   * to hip plus a canvas bag riding the LEFT hip, breaking the mirrored
   * silhouette. */
  const sling = mesh(g.rbox, kit.strap, -0.02, 0.20, -0.128, 0.045, 0.40, 0.020);
  sling.rotation.z = 0.55;
  spine.add(sling);
  hips.add(mesh(g.rbox, kit.belt, 0, 0.04, 0.02, 0.24, 0.044, 0.14));
  const satchel = mesh(g.soft, kit.pouch, -0.152, -0.070, 0.018, 0.118, 0.110, 0.078);
  satchel.rotation.z = 0.08;
  satchel.rotation.y = 0.10;
  hips.add(satchel);
  const flap = mesh(g.rbox, kit.strap, -0.152, -0.022, 0.018, 0.122, 0.032, 0.082);
  flap.rotation.z = 0.08;
  flap.rotation.y = 0.10;
  hips.add(flap);
  /* Drop-leg holster on the RIGHT thigh — no floating strap ring (c28). */
  const holster = mesh(g.rbox, kit.belt, 0.158, -0.220, -0.040, 0.078, 0.150, 0.070);
  holster.rotation.z = -0.06;
  hips.add(holster);
  hips.add(mesh(g.rbox, kit.plate, 0.160, -0.140, -0.046, 0.044, 0.052, 0.038));
  hips.add(mesh(g.rbox, kit.pouch, 0.138, -0.018, -0.048, 0.056, 0.048, 0.038));
  const radio = mesh(g.rbox, kit.plate, 0.082, 0.248, -0.082, 0.036, 0.068, 0.028);
  spine.add(radio);
}

export class Enemy {
  constructor(spawn, mats, geos) {
    this.health = ENEMY_CONFIG.HEALTH;
    this.alive = true;
    this.yaw = spawn.yaw;
    this.mayFire = true;
    this.shotsFired = 0;
    this.root = new THREE.Group();
    this.root.name = 'enemy';
    // Authored elevated posts (balcony) keep their y; everything else is
    // re-planted on the asphalt with just sole clearance.
    const planted = spawn.elevated
      ? spawn.y
      : ((spawn.y > 0.35 || spawn.y === undefined || spawn.y === null) ? 0.12 : spawn.y);
    this.spawnY = planted;
    this.root.position.set(spawn.x, planted, spawn.z);
    this.root.rotation.y = spawn.yaw;
    this.root.frustumCulled = false;
    this.root.matrixAutoUpdate = true;
    this.root.renderOrder = 4;
    this.hitbox = { radius: HIT_ZONES.bodyR, height: 1.74 * BODY_SCALE, headR: HIT_ZONES.headR };
    this._idle = Math.random() * 10;
    this._chest = new THREE.Vector3();
    this._hitPayload = { dmg: 0, from: this.root.position };

    const g = geos;
    const kit = kitFrom(mats);
    const cloth = kit.cloth;
    const variant = Math.abs(spawn.seed | 0) % 3;
    this.variant = variant;
    /* Loadout (plan §8): ground-level Suq holders (E1, E6) are shotgunners
     * — dangerous to push, harmless past 14 m. Everyone else keeps the
     * rifle. Derived from position so the spawn table stays untouched;
     * spawn.loadout overrides if authored. Movement AI (close rush) is
     * deferred to a future pathing pass — the distance gate alone creates
     * the right player read. */
    this.loadout = spawn.loadout
      || ((!spawn.elevated && spawn.x > WORLD.SUQ_MIN_X) ? 'shotgun' : 'rifle');
    this.resetCombat();

    const hips = new THREE.Group();
    /* Hip height raised with the longer legs so soles stay planted. */
    hips.position.set(0, 1.20, 0);
    hips.scale.setScalar(BODY_SCALE);
    this.hips = hips;

    hips.add(mesh(g.soft, kit.pants, 0, -0.02, 0.01, 0.205, 0.092, 0.148));
    hips.add(mesh(g.rbox, kit.belt, 0, 0.04, 0.02, 0.265, 0.044, 0.162));

    const spine = new THREE.Group();
    spine.position.set(0, 0.08, 0);
    this.spine = spine;
    /* Torso volumes (c22 fix 1): broad ribcage over a narrower abdomen,
     * both on the SOFT rounded box so the jacket reads as stuffed cloth —
     * the sharp rbox pair was the "box torso" of the toy-soldier read. */
    /* c32: ribcage 0.295 was already 3.7x helmet — the vest sat on top
     * of that and the assembled olive read 5x. Narrow the jacket so the
     * shoulder span can actually hit ~3x. */
    spine.add(mesh(g.soft, cloth, 0, 0.208, 0.005, 0.214, 0.188, 0.148));
    spine.add(mesh(g.soft, cloth, 0, 0.012, 0.0, 0.188, 0.248, 0.138));

    const head = new THREE.Group();
    /* Raised 8 mm so the taller skull still crests the collar gap. */
    head.position.set(0, 0.438, 0.008);
    this.head = dressHead(variant, head, kit, g);
    spine.add(head);

    /* Collar ring — the neck column lands in this hole so the helmet
     * crests a readable gap instead of sitting in a vest valley. */
    spine.add(mesh(g.cyl, cloth, 0, 0.322, 0.004, 0.038, 0.024, 0.034));

    /* c32: the ±0.148 / y=0.350 rbox yokes WERE the raised ear-height
     * pads. Replace with a trapezius that slopes down from the collar
     * to a low sleeve cap at the joint. */
    const sleeveYoke = kit.sleeve || cloth;
    for (const side of [-1, 1]) {
      const trap = mesh(g.soft, sleeveYoke, side * 0.066, 0.292, 0.004, 0.078, 0.030, 0.068);
      trap.rotation.z = -side * 0.50;
      spine.add(trap);
      spine.add(mesh(g.soft, sleeveYoke, side * 0.098, 0.258, 0.006, 0.046, 0.032, 0.054));
    }

    const sleeve = kit.sleeve || cloth;
    const forearm = kit.sleeve || cloth;

    /* c32: roots 0.162→0.096 (~3.0x helmet once deltoid half-width is
     * added), dropped 0.345→0.270 so pad tops sit at jaw or below.
     * Elbows pulled in so the upper-arm silhouette doesn't re-widen
     * the shoulder line. Hands stay on the rifle. Arm r 0.056 kept. */
    this.lShoulder = buildLimb(
      spine,
      new THREE.Vector3(-0.096, 0.270, 0.01),
      new THREE.Vector3(-0.132, 0.138, -0.10),
      new THREE.Vector3(-0.02, 0.19, -0.40),
      kit, g, sleeve, forearm, 0.056, 0.046, 'arm',
    );
    this.rShoulder = buildLimb(
      spine,
      new THREE.Vector3(0.096, 0.256, 0.01),
      new THREE.Vector3(0.126, 0.128, -0.02),
      new THREE.Vector3(0.10, 0.15, -0.16),
      kit, g, sleeve, forearm, 0.056, 0.046, 'arm',
    );
    this._lShQ = this.lShoulder.quaternion.clone();
    this._rShQ = this.rShoulder.quaternion.clone();

    const weap = buildRifle(kit, g, this.loadout);
    weap.scale.setScalar(1.35);
    weap.position.set(0.06, 0.23, -0.28);
    weap.rotation.set(-0.10, 0.42, 0.08);
    this.weapon = weap;
    spine.add(weap);

    dressKit(variant, spine, hips, kit, g);
    hips.add(spine);

    /* Trouser waist fills jacket-hem → thigh so the hip-joint spheres
     * cannot read as tan shorts / exposed skin (c29 #6).
     * c33: wider hip block so close-range legs don't read as stilts
     * under a vest that is already the right width. */
    hips.add(mesh(g.soft, kit.pants, 0, -0.04, 0.012, 0.285, 0.172, 0.178));
    hips.add(mesh(g.soft, kit.pants, 0, -0.10, 0.015, 0.248, 0.138, 0.162));
    hips.add(mesh(g.rbox, kit.belt, 0, -0.18, 0.000, 0.034, 0.15, 0.11));
    const stance = legStance(variant);
    this.lHip = buildLimb(
      hips,
      stance.lHip, stance.lKnee, stance.lAnkle,
      kit, g, kit.pants, kit.pants, 0.118, 0.110, 'leg',
    );
    this.rHip = buildLimb(
      hips,
      stance.rHip, stance.rKnee, stance.rAnkle,
      kit, g, kit.pants, kit.pants, 0.118, 0.110, 'leg',
    );
    /* Knee plates deleted — they read as tan blocks on the A-pose. */

    this.root.add(hips);
    if (kit.contact) {
      const blob = new THREE.Mesh(g.disc, kit.contact);
      blob.rotation.x = -Math.PI / 2;
      blob.position.set(0, 0.018, 0.02);
      blob.scale.set(0.62, 0.62, 0.78);
      blob.castShadow = false;
      blob.receiveShadow = false;
      blob.renderOrder = 1;
      this.root.add(blob);
    }
    this.root.traverse((o) => {
      o.visible = true;
      o.frustumCulled = false;
      if (o.layers) o.layers.enable(0);
    });
    this.root.updateMatrixWorld(true);
  }

  resetCombat() {
    this.cool = 0.4 + Math.random() * 0.8;
    this.reactT = -1;
    this.burstLeft = 0;
    this.burstGap = 0;
    this.reloadT = 0;
    this.engageT = 0;
    this._lost = 0;
    this.shotsFired = 0;
    const lo = ENEMY_LOADOUTS[this.loadout] || ENEMY_LOADOUTS.rifle;
    this.ammo = lo.mag ?? 30;
    this.mayFire = true;
  }

  chest() {
    return this._chest.setFromMatrixPosition(this.head.matrixWorld);
  }

  update(dt, playerPos, canSee, squad) {
    if (!this.alive) return;
    this._idle += dt;
    const b = Math.sin(this._idle * 1.65);
    const s = Math.sin(this._idle * 0.82);
    this.spine.rotation.x = 0.035 + b * 0.028;
    this.spine.rotation.y = s * 0.022;
    this.hips.rotation.z = s * 0.01;
    _eBreath.set(b * 0.035, 0, 0);
    this.lShoulder.quaternion.copy(this._lShQ).multiply(_qBreath.setFromEuler(_eBreath));
    _eBreath.set(Math.sin(this._idle * 1.65 + 0.45) * 0.028, 0, 0);
    this.rShoulder.quaternion.copy(this._rShQ).multiply(_qBreath.setFromEuler(_eBreath));
    this.weapon.rotation.x = -0.10 + b * 0.008;
    this.weapon.rotation.y = 0.42 + s * 0.006;

    _to.copy(playerPos).sub(this.root.position);
    _to.y = 0;
    const dist = _to.length();
    if (dist > 0.001) {
      const want = Math.atan2(-_to.x, -_to.z);
      let d = want - this.yaw;
      while (d > Math.PI) d -= Math.PI * 2;
      while (d < -Math.PI) d += Math.PI * 2;
      this.yaw += d * Math.min(1, dt * 3.2);
      this.root.rotation.y = this.yaw;
    }
    this.cool -= dt;
    const inRange = canSee && dist < ENEMY_CONFIG.SIGHT;
    if (!inRange) {
      this._lost += dt;
      if (this._lost > 1.2) {
        this.reactT = -1;
        this.engageT = 0;
      }
      return;
    }
    this._lost = 0;
    // reactT < 0 = not yet acquired; > 0 = counting down; 0 = ready to fire.
    // Must latch at 0 when the delay expires — a leftover negative used to
    // re-roll 0.30–0.80 every frame (livelock: enemies never reached _fireAt).
    if (this.reactT < 0) this.reactT = 0.30 + Math.random() * 0.50;
    if (this.reactT > 0) {
      this.reactT -= dt;
      if (this.reactT > 0) return;
      this.reactT = 0;
    }
    if (this.reloadT > 0) {
      this.reloadT -= dt;
      return;
    }
    this.engageT += dt;
    if (!gameState.game.isPlaying || gameState.game.grace > 0 || !gameState.player.alive) return;
    if (this.mayFire === false) return;

    if (this.burstLeft <= 0) {
      if (this.burstGap > 0) {
        this.burstGap -= dt;
        return;
      }
      this._startBurst();
    }
    if (this.cool > 0) return;
    this._fireAt(playerPos, dist, squad);
  }

  _startBurst() {
    const lo = ENEMY_LOADOUTS[this.loadout] || ENEMY_LOADOUTS.rifle;
    const loMin = lo.burstMin ?? 3;
    const loMax = lo.burstMax ?? 5;
    this.burstLeft = loMin + (Math.random() * (loMax - loMin + 1) | 0);
  }

  _fireAt(playerPos, dist, squad) {
    const lo = ENEMY_LOADOUTS[this.loadout] || ENEMY_LOADOUTS.rifle;
    const dt0 = lo.burstDt || [0.11, 0.15];
    this.cool = dt0[0] + Math.random() * (dt0[1] - dt0[0]);
    this.burstLeft -= 1;
    this.ammo -= 1;
    if (this.burstLeft <= 0) {
      const g = lo.burstGap || [0.80, 1.50];
      this.burstGap = g[0] + Math.random() * (g[1] - g[0]);
    }
    if (this.ammo <= 0) {
      const r = lo.reload || [2.0, 2.9];
      this.reloadT = r[0] + Math.random() * (r[1] - r[0]);
      this.ammo = lo.mag ?? 30;
      this.burstLeft = 0;
    }

    _eye.copy(playerPos);
    _eye.y = playerPos.y + 1.5;
    _muzzle.copy(this.chest());
    _muzzle.x -= Math.sin(this.yaw) * 0.55;
    _muzzle.z -= Math.cos(this.yaw) * 0.55;
    _muzzle.y -= 0.12;

    if (squad && !squad.losClear(_muzzle, _eye)) return;

    this.shotsFired += 1;
    const warm = 1.55 + (0.80 - 1.55) * Math.min(1, this.engageT / 5.5);
    const spd = gameState.player.speed || 0;
    const err = 0.040 * warm * (1 + dist * 0.028) * (1 + spd * 0.075)
      * (gameState.player.crouching ? 1.15 : 1);
    _edir.copy(_eye).sub(_muzzle);
    const aimLen = _edir.length() || 1;
    _edir.multiplyScalar(1 / aimLen);
    _edir.x += (Math.random() - 0.5) * 2 * err;
    _edir.y += (Math.random() - 0.5) * 2 * err;
    _edir.normalize();

    _body.set(playerPos.x, playerPos.y + 0.90, playerPos.z);
    _off.copy(_body).sub(_muzzle);
    const tca = _off.dot(_edir);
    const d2 = _off.lengthSq() - tca * tca;
    const hit = tca > 0 && d2 < 0.42 * 0.42;

    const shotDist = hit ? tca : aimLen;
    _impact.copy(_muzzle).addScaledVector(_edir, shotDist);
    if (_impact.y < 0.02) _impact.y = 0.02;

    const vfx = squad?.vfx;
    vfx?.tracer(_muzzle, _edir, 'enemy', shotDist);
    vfx?.muzzleFlash(_muzzle);
    if (hit) {
      const dmg = this.loadout === 'shotgun'
        ? (dist <= lo.near ? lo.dmgNear : dist <= lo.far ? lo.dmgFar : 0)
        : (lo.damage ?? ENEMY_CONFIG.DAMAGE);
      if (dmg > 0) {
        this._hitPayload.dmg = dmg;
        this._hitPayload.from = this.root.position;
        eventBus.emit(Events.PLAYER_HIT, this._hitPayload);
      }
    } else {
      vfx?.dust(_impact, true);
    }
  }

  hit(dmg, headshot = false) {
    if (!this.alive) return false;
    if (this.reactT < 0) this.reactT = 0.14 + Math.random() * 0.16;
    else this.reactT = Math.min(this.reactT, 0.14 + Math.random() * 0.16);
    this.health -= dmg;
    const killed = this.health <= 0;
    if (killed) {
      this.alive = false;
      this.root.rotation.x = 1.25;
      this.root.position.y = this.spawnY + 0.03;
      gameState.game.kills += 1;
      gameState.game.remaining = Math.max(0, gameState.game.remaining - 1);
    }
    eventBus.emit(Events.ENEMY_HIT, { enemy: this, headshot, killed, dmg });
    if (killed) eventBus.emit(Events.ENEMY_DIE, { enemy: this });
    return killed;
  }
}

export class EnemySquad {
  constructor(scene, spawns, mats, colliders = [], vfx = null) {
    this.geos = makeGeos();
    // Only AABBs tall enough to be real cover occlude bullets; ground clutter
    // (curbs, low crates, sandbag-only stacks) stays shootable-over, which the
    // slab test handles in y anyway for anything that remains.
    this.blockers = colliders.filter((c) => c.max.y >= 0.9);
    this.vfx = vfx;
    this.list = spawns.map((s) => {
      const e = new Enemy(s, mats, this.geos);
      e.root.visible = true;
      e.root.frustumCulled = false;
      e.root.renderOrder = 4;
      scene.add(e.root);
      e.root.updateMatrixWorld(true);
      return e;
    });
  }

  losClear(a, b) {
    for (const c of this.blockers) {
      if (segHitsAabb(a, b, c)) return false;
    }
    return true;
  }

  update(dt, playerPos, hostile = true) {
    if (hostile) {
      _cands.length = 0;
      for (const e of this.list) {
        if (!e.alive) { e.mayFire = false; continue; }
        _to.copy(playerPos).sub(e.root.position);
        _to.y = 0;
        const dist = _to.length();
        e.mayFire = false;
        if (dist < ENEMY_CONFIG.SIGHT) _cands.push(e);
      }
      _cands.sort((a, b) => {
        const da = (a.root.position.x - playerPos.x) ** 2 + (a.root.position.z - playerPos.z) ** 2;
        const db = (b.root.position.x - playerPos.x) ** 2 + (b.root.position.z - playerPos.z) ** 2;
        return da - db;
      });
      for (let i = 0; i < _cands.length && i < 2; i++) _cands[i].mayFire = true;
    }
    for (const e of this.list) {
      e.update(dt, playerPos, hostile && e.alive, this);
    }
  }

  /* Snapshot head/body world positions + which blockers contain each
   * torso. Combat calls this once per trigger pull so an 8-pellet blast
   * does not re-walk matrixWorld / containment 9×. */
  prepHits() {
    this._hitsFresh = true;
    const cache = this._hitCache || (this._hitCache = []);
    const blockers = this.blockers;
    const nB = blockers.length;
    let n = 0;
    for (const e of this.list) {
      if (!e.alive) continue;
      const head = e.chest();
      const bx = head.x, by = head.y - HIT_ZONES.bodyDown, bz = head.z;
      let row = cache[n];
      if (!row || row.skip.length !== nB) {
        row = { e, hx: 0, hy: 0, hz: 0, bx: 0, by: 0, bz: 0, skip: new Uint8Array(nB) };
        cache[n] = row;
      }
      row.e = e;
      row.hx = head.x; row.hy = head.y; row.hz = head.z;
      row.bx = bx; row.by = by; row.bz = bz;
      const skip = row.skip;
      skip.fill(0);
      for (let i = 0; i < nB; i++) {
        const c = blockers[i];
        if (bx >= c.min.x && bx <= c.max.x
          && by >= c.min.y && by <= c.max.y
          && bz >= c.min.z && bz <= c.max.z) skip[i] = 1;
      }
      n++;
    }
    cache.length = n;
  }

  /* Player hitscan. Two zones on the same ray: head sphere at chest()
   * (skull world origin) and a body sphere bodyDown below it. Walls clip
   * first. Hit distance is the sphere *entry* (see HIT_ZONES). ALWAYS
   * returns { enemy, dist, headshot, wallT } so Combat can place miss
   * dust at origin + dir·wallT.
   *
   * A blocker that CONTAINS this enemy's torso does not occlude them —
   * they spawned inside cover (E4-in-dumpster) and the visible mesh is
   * still a legal target. The same box still stops shots at anyone
   * standing behind it. Miss-dust wallT stays global. */
  rayHit(origin, dir, maxDist) {
    let wallT = maxDist;
    for (const c of this.blockers) {
      const t = rayAabbT(origin, dir, c, wallT);
      if (t < wallT) wallT = t;
    }
    let best = null;
    let bestD = maxDist;
    let bestHead = false;
    const ox = origin.x, oy = origin.y, oz = origin.z;
    const dx = dir.x, dy = dir.y, dz = dir.z;
    const cache = this._hitCache;
    if (this._hitsFresh && cache && cache.length) {
      const blockers = this.blockers;
      for (let i = 0; i < cache.length; i++) {
        const h = cache[i];
        let eWall = maxDist;
        for (let b = 0; b < blockers.length; b++) {
          if (h.skip[b]) continue;
          const t = rayAabbT(origin, dir, blockers[b], eWall);
          if (t < eWall) eWall = t;
        }
        const clip = eWall < bestD ? eWall : bestD;
        const ht = raySphereT(ox, oy, oz, dx, dy, dz, h.hx, h.hy, h.hz, HIT_ZONES.headR, clip);
        if (ht < bestD) {
          bestD = ht;
          best = h.e;
          bestHead = true;
          continue;
        }
        const bt = raySphereT(ox, oy, oz, dx, dy, dz, h.bx, h.by, h.bz, HIT_ZONES.bodyR, clip);
        if (bt < bestD) {
          bestD = bt;
          best = h.e;
          bestHead = false;
        }
      }
      return { enemy: best, dist: best ? bestD : 0, headshot: bestHead, wallT };
    }
    for (const e of this.list) {
      if (!e.alive) continue;
      const head = e.chest();
      const bx = head.x, by = head.y - HIT_ZONES.bodyDown, bz = head.z;
      let eWall = maxDist;
      for (const c of this.blockers) {
        if (bx >= c.min.x && bx <= c.max.x
          && by >= c.min.y && by <= c.max.y
          && bz >= c.min.z && bz <= c.max.z) continue;
        const t = rayAabbT(origin, dir, c, eWall);
        if (t < eWall) eWall = t;
      }
      const clip = eWall < bestD ? eWall : bestD;
      const ht = raySphereT(ox, oy, oz, dx, dy, dz, head.x, head.y, head.z, HIT_ZONES.headR, clip);
      if (ht < bestD) {
        bestD = ht;
        best = e;
        bestHead = true;
        continue;
      }
      const bt = raySphereT(
        ox, oy, oz, dx, dy, dz,
        bx, by, bz,
        HIT_ZONES.bodyR, clip,
      );
      if (bt < bestD) {
        bestD = bt;
        best = e;
        bestHead = false;
      }
    }
    return { enemy: best, dist: best ? bestD : 0, headshot: bestHead, wallT };
  }
}
