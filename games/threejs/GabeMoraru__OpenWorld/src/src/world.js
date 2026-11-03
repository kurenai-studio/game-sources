import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { fbm, noise, hash2, rng, smoothstep } from './noise.js';
import { NODES, LINKS, ROADS } from './data.js';

export const HALF = 640;
const STEP = 5, N = (HALF * 2) / STEP + 1;
const gauss = (x, z, cx, cz, s) => Math.exp(-((x - cx) ** 2 + (z - cz) ** 2) / (2 * s * s));
const cheb = (x, z) => Math.max(Math.abs(x), Math.abs(z));
const near80 = (v) => Math.abs(v - Math.round(v / 80) * 80);
const CITY = 252;

export const U = {
  uNodes: { value: NODES.map(() => new THREE.Vector4()) },
  uTime: { value: 0 },
  uDawn: { value: 0 },
  uHeight: { value: null },
};

export function litAt(x, z) {
  let l = 0;
  for (const n of U.uNodes.value) {
    l = Math.max(l, n.w * (1 - smoothstep(n.z * 0.7, n.z, Math.hypot(x - n.x, z - n.y))));
  }
  return l;
}

/* ---------- shader patch: every world material reacts to the grid ---------- */

const PATCH_HEAD = `
uniform vec4 uNodes[${NODES.length}];
uniform float uTime;
uniform float uDawn;
uniform sampler2D uHeight;
varying vec3 vWP;
varying vec3 vWN;
varying vec2 vRUV;
float litAt(vec2 p) {
  float l = 0.;
  for (int i = 0; i < ${NODES.length}; i++) {
    vec4 n = uNodes[i];
    l = max(l, n.w * (1. - smoothstep(n.z * .7, n.z, distance(p, n.xy))));
  }
  return l;
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
`;

const PATCH_BODY = `
float L = litAt(vWP.xz);
vec3 col = outgoingLight;
#if defined(LAMP)
  col = mix(vec3(.05, .05, .08), vec3(2.6, 1.7, .8), L);
#elif defined(POOL)
  col = vec3(1., .6, .28) * L * .22 * (1. - smoothstep(.0, 1., length(vRUV - .5) * 2.)) * (1. - uDawn * .7);
#elif defined(WATERS)
  vec2 tuv = (vWP.xz + ${HALF}.) / ${HALF * 2}.;
  float th = texture2D(uHeight, tuv).r * 140. - 40.;
  float depth = max(0., -th);
  vec3 wc = mix(vec3(.04, .2, .27), vec3(.01, .035, .10), smoothstep(0., 12., depth));
  float rip = sin(vWP.x * .35 + uTime * 1.1 + sin(vWP.z * .25 + uTime * .7) * 2.) * sin(vWP.z * .31 - uTime * .9);
  float foam = smoothstep(1.3, 0., depth + rip * .4);
  wc += foam * vec3(.45, .5, .6) * .7;
  wc += pow(max(0., rip), 16.) * mix(vec3(.4, .45, .8), vec3(1.5, .9, .45), L);
  wc *= mix(vec3(.75, .8, 1.15), vec3(1.25, 1., .85), L);
  col = mix(wc, wc * 1.6 + vec3(.06, .1, .14), uDawn);
#else
  col *= mix(mix(vec3(.55, .6, 1.), vec3(1.06, .97, .86), L), vec3(1.1), uDawn);
  #ifdef ROAD
    float ax = abs(vRUV.x - .5);
    float dash = step(ax, .018) * step(.5, fract(vRUV.y / 9.));
    float edge = step(.43, ax) * step(ax, .45);
    col = mix(col, vec3(.95, .7, .3) * (.25 + 1.4 * L), dash);
    col = mix(col, vec3(.55, .55, .65) * (.25 + .8 * L), edge);
  #endif
  #ifdef WINDOWS
  if (abs(vWN.y) < .5) {
    vec2 t = normalize(vec2(-vWN.z, vWN.x));
    vec2 c = vec2(dot(vWP.xz, t) / WX, (vWP.y - 2.) / WY);
    vec2 f = fract(c), id = floor(c);
    float win = step(.3, f.x) * step(f.x, .7) * step(.35, f.y) * step(f.y, .75) * step(0., c.y);
    float h = hash(id + floor(vWP.xz / 23.) * 3.7 + vWN.xz * 11.);
    float on = step(.42, h) * L;
    col = mix(col, col * .5 + vec3(.04, .05, .09), win);
    col += win * on * mix(vec3(1.25, .72, .3), vec3(.7, .85, 1.1), step(.9, h)) * (.45 + .6 * h) * (1. - uDawn * .6);
  }
  #endif
#endif
outgoingLight = col;
`;

export function patch(mat, defines = {}) {
  mat.defines = { ...mat.defines, ...defines };
  mat.onBeforeCompile = (s) => {
    Object.assign(s.uniforms, U);
    s.vertexShader = 'varying vec3 vWP;\nvarying vec3 vWN;\nvarying vec2 vRUV;\n' + s.vertexShader.replace(
      '#include <project_vertex>',
      `#include <project_vertex>
      vec4 wp_ = vec4(transformed, 1.0);
      vec3 wn_ = normal;
      #ifdef USE_INSTANCING
        wp_ = instanceMatrix * wp_;
        wn_ = mat3(instanceMatrix) * wn_;
      #endif
      vWP = (modelMatrix * wp_).xyz;
      vWN = normalize(mat3(modelMatrix) * wn_);
      vRUV = uv;`
    );
    s.fragmentShader = PATCH_HEAD + s.fragmentShader.replace('#include <opaque_fragment>', PATCH_BODY + '#include <opaque_fragment>');
  };
  return mat;
}

const lambert = (defines) => patch(new THREE.MeshLambertMaterial({ vertexColors: true, flatShading: true }), defines);

/* ---------- geometry helpers ---------- */

const tmpColor = new THREE.Color();
function paint(geo, hex) {
  geo = geo.index ? geo.toNonIndexed() : geo;
  tmpColor.set(hex);
  const n = geo.attributes.position.count, c = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) c.set([tmpColor.r, tmpColor.g, tmpColor.b], i * 3);
  geo.setAttribute('color', new THREE.BufferAttribute(c, 3));
  return geo;
}
const part = (geo, hex, x = 0, y = 0, z = 0) => paint(geo.translate(x, y, z), hex);
const merge = (...parts) => mergeGeometries(parts);

const dummy = new THREE.Object3D();
function instanced(scene, geo, mat, list) {
  const m = new THREE.InstancedMesh(geo, mat, Math.max(1, list.length));
  list.forEach((o, i) => {
    dummy.position.set(o.x, o.y, o.z);
    dummy.rotation.set(0, o.ry || 0, 0);
    dummy.scale.set(o.sx ?? 1, o.sy ?? o.sx ?? 1, o.sz ?? o.sx ?? 1);
    dummy.updateMatrix();
    m.setMatrixAt(i, dummy.matrix);
    m.setColorAt(i, tmpColor.set(o.c ?? 0xffffff));
  });
  m.count = list.length;
  scene.add(m);
  return m;
}

/* ---------- collision: static circles and boxes in a spatial hash ---------- */

const CELL = 16, cells = new Map();
const key = (cx, cz) => (cx + 200) * 1000 + cz + 200;
let queryId = 0;

function addCollider(o) {
  const [x0, z0, x1, z1] = o.r !== undefined ? [o.x - o.r, o.z - o.r, o.x + o.r, o.z + o.r] : [o.x0, o.z0, o.x1, o.z1];
  for (let cx = Math.floor(x0 / CELL); cx <= Math.floor(x1 / CELL); cx++)
    for (let cz = Math.floor(z0 / CELL); cz <= Math.floor(z1 / CELL); cz++) {
      const k = key(cx, cz);
      if (!cells.has(k)) cells.set(k, []);
      cells.get(k).push(o);
    }
}
const addBox = (x, z, w, d) => addCollider({ x0: x - w / 2, z0: z - d / 2, x1: x + w / 2, z1: z + d / 2 });
const addCircle = (x, z, r) => addCollider({ x, z, r });

export function collide(x, z, r, boxesOnly = false) {
  let nx = 0, nz = 0, hit = false;
  queryId++;
  for (let cx = Math.floor((x - r) / CELL); cx <= Math.floor((x + r) / CELL); cx++)
    for (let cz = Math.floor((z - r) / CELL); cz <= Math.floor((z + r) / CELL); cz++) {
      const list = cells.get(key(cx, cz));
      if (!list) continue;
      for (const o of list) {
        if (o.q === queryId || (boxesOnly && o.r !== undefined)) continue;
        o.q = queryId;
        let dx, dz, m;
        if (o.r !== undefined) {
          dx = x - o.x; dz = z - o.z; m = r + o.r;
        } else {
          dx = x - Math.min(Math.max(x, o.x0), o.x1); dz = z - Math.min(Math.max(z, o.z0), o.z1); m = r;
          if (dx === 0 && dz === 0) {
            const pen = [x - o.x0, o.x1 - x, z - o.z0, o.z1 - z], k = pen.indexOf(Math.min(...pen));
            const ex = [-1, 1, 0, 0][k], ez = [0, 0, -1, 1][k];
            x += ex * (pen[k] + r); z += ez * (pen[k] + r);
            nx += ex; nz += ez; hit = true;
            continue;
          }
        }
        const d = Math.hypot(dx, dz);
        if (d < m && d > 1e-6) {
          x += (dx / d) * (m - d); z += (dz / d) * (m - d);
          nx += dx / d; nz += dz / d; hit = true;
        }
      }
    }
  const nl = Math.hypot(nx, nz) || 1;
  return { x, z, hit, nx: nx / nl, nz: nz / nl };
}

/* ---------- terrain ---------- */

function rawHeight(x, z) {
  const open = smoothstep(CITY, 330, cheb(x, z));
  const sub = gauss(x, z, -360, -60, 170);
  let h = 2 + (fbm(x / 170, z / 170) * 2 - 1) * 15 * open * (1 - 0.75 * sub);
  h += 90 * gauss(x, z, 20, -450, 115) * (0.75 + 0.5 * fbm(x / 50 + 9, z / 50));
  h += 22 * gauss(x, z, 410, -160, 70);
  h -= 15 * gauss(x, z, 190, -300, 55);
  h -= 18 * gauss(x, z, 400, 70, 60);
  const r = Math.hypot(x, z) + (fbm(x / 120 + 3, z / 120) - 0.5) * 90;
  return h - 40 * smoothstep(470, 590, r);
}

const H = new Float32Array(N * N), RD = new Float32Array(N * N).fill(999), RH = new Float32Array(N * N);

function stamp(x, z, h, R, inner = 0) {
  const i0 = Math.max(0, Math.floor((x - R + HALF) / STEP)), i1 = Math.min(N - 1, Math.ceil((x + R + HALF) / STEP));
  const j0 = Math.max(0, Math.floor((z - R + HALF) / STEP)), j1 = Math.min(N - 1, Math.ceil((z + R + HALF) / STEP));
  for (let j = j0; j <= j1; j++)
    for (let i = i0; i <= i1; i++) {
      const d = Math.max(0, Math.hypot(i * STEP - HALF - x, j * STEP - HALF - z) - inner), k = j * N + i;
      if (d < RD[k]) { RD[k] = d; RH[k] = h; }
    }
}

export function heightAt(x, z) {
  const fx = (x + HALF) / STEP, fz = (z + HALF) / STEP;
  const i = Math.min(N - 2, Math.max(0, Math.floor(fx))), j = Math.min(N - 2, Math.max(0, Math.floor(fz)));
  const u = Math.min(1, Math.max(0, fx - i)), v = Math.min(1, Math.max(0, fz - j));
  const a = H[j * N + i], b = H[j * N + i + 1], c = H[(j + 1) * N + i], d = H[(j + 1) * N + i + 1];
  return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
}

export function roadDistAt(x, z) {
  const i = Math.round((x + HALF) / STEP), j = Math.round((z + HALF) / STEP);
  return i < 0 || j < 0 || i >= N || j >= N ? 999 : RD[j * N + i];
}

/* ---------- road sampling ---------- */

const ROAD_WIDTH = { city: 12, suburb: 9, rural: 9, mountain: 8 };
const sampledRoads = ROADS.map((road) => {
  let pts;
  if (road.pts.length === 2) {
    const [[ax, az], [bx, bz]] = road.pts, n = Math.ceil(Math.hypot(bx - ax, bz - az) / 2);
    pts = Array.from({ length: n + 1 }, (_, i) => [ax + ((bx - ax) * i) / n, az + ((bz - az) * i) / n]);
  } else {
    const curve = new THREE.CatmullRomCurve3(road.pts.map(([x, z]) => new THREE.Vector3(x, 0, z)), false, 'centripetal');
    pts = curve.getSpacedPoints(Math.ceil(curve.getLength() / 2)).map((p) => [p.x, p.z]);
  }
  return { ...road, width: ROAD_WIDTH[road.kind], pts };
});

/* ---------- districts (decided before terrain colouring) ---------- */

const R = rng(1971);
const parks = [], blocks = [];
for (let bi = -3; bi < 3; bi++)
  for (let bj = -3; bj < 3; bj++) {
    const b = { x0: bi * 80 + 9, x1: (bi + 1) * 80 - 9, z0: bj * 80 + 9, z1: (bj + 1) * 80 - 9 };
    b.cx = (b.x0 + b.x1) / 2; b.cz = (b.z0 + b.z1) / 2;
    b.tower = Math.max(gauss(b.cx, b.cz, 0, 0, 110), 1.1 * gauss(b.cx, b.cz, -80, -160, 80));
    b.docks = b.cx > 150;
    const isPark = !b.docks && R() < (b.tower < 0.25 ? 0.22 : 0.08);
    (isPark ? parks : blocks).push(b);
  }
const inPark = (x, z) => parks.some((p) => x > p.x0 - 4 && x < p.x1 + 4 && z > p.z0 - 4 && z < p.z1 + 4);

const FARMS = [[-200, 360, 170], [300, 290, 190]];
function fieldAt(x, z) {
  if (!FARMS.some(([fx, fz, r]) => Math.hypot(x - fx, z - fz) < r)) return -1;
  if (Math.hypot(x + 215, z - 410) < 55) return -1;
  const cx = Math.floor(x / 45), cz = Math.floor(z / 45), h = hash2(cx * 7 + 1, cz * 13 + 5);
  return h < 0.72 ? Math.floor(h * 4.2) : -1;
}
const nearNode = (x, z, r) => NODES.some((n) => Math.hypot(x - n.pos[0], z - n.pos[1]) < r);

const C = {
  seabed: '#14303c', sand: '#b39c76', plaza: '#33354a', sidewalk: '#55576f', grass: '#2d5e4f', grass2: '#467a50',
  rock: '#5b5674', snow: '#dfe2ef', wheat: '#c7a456', wheat2: '#9a7c3a', lavender: '#7d69ad', lavender2: '#5a4c86',
  crop: '#55803f', crop2: '#3c6332', parkGrass: '#2f6a4c',
};
const cA = new THREE.Color(), cB = new THREE.Color();

function groundColor(x, z, h, rd) {
  if (h < 0.5) return cA.set(h < -2 ? C.seabed : C.sand);
  const inCity = cheb(x, z) < CITY;
  if (!inCity && h < 1.4) return cA.set(C.sand);
  if (inCity) return cA.set(inPark(x, z) && rd > 7 ? C.parkGrass : rd < 10 ? C.sidewalk : C.plaza);
  if (h > 62 + noise(x / 20, z / 20) * 10) return cA.set(C.snow);
  if (h > 28) return cA.set(C.rock).lerp(cB.set(C.grass), smoothstep(40, 28, h) * noise(x / 15, z / 15));
  const f = fieldAt(x, z);
  if (f >= 0 && rd > 8) {
    const rows = hash2(Math.floor(x / 45), Math.floor(z / 45) + 99) > 0.5 ? x : z;
    const stripe = Math.round(rows / STEP) % 2 === 0;
    const pair = [[C.wheat, C.wheat2], [C.lavender, C.lavender2], [C.crop, C.crop2], [C.wheat, C.crop]][f];
    return cA.set(pair[stripe ? 0 : 1]);
  }
  return cA.set(C.grass).lerp(cB.set(C.grass2), noise(x / 40, z / 40) * 0.9);
}

/* ---------- build ---------- */

export function createWorld(scene) {
  for (let j = 0; j < N; j++)
    for (let i = 0; i < N; i++) H[j * N + i] = rawHeight(i * STEP - HALF, j * STEP - HALF);
  for (const road of sampledRoads) for (const [x, z] of road.pts) stamp(x, z, rawHeight(x, z), 28);
  for (const n of NODES) stamp(n.pos[0], n.pos[1], rawHeight(n.pos[0], n.pos[1]), 46, 16);
  for (let k = 0; k < N * N; k++) H[k] += (RH[k] - H[k]) * (1 - smoothstep(6, 22, RD[k])) * (RD[k] < 999);

  // terrain mesh + minimap image from the same grid
  const pos = new Float32Array(N * N * 3), colors = new Float32Array(N * N * 3), idx = [];
  const mapCanvas = document.createElement('canvas');
  mapCanvas.width = mapCanvas.height = N;
  const mctx = mapCanvas.getContext('2d'), img = mctx.createImageData(N, N);
  const heightBytes = new Uint8Array(N * N);
  for (let j = 0; j < N; j++)
    for (let i = 0; i < N; i++) {
      const k = j * N + i, x = i * STEP - HALF, z = j * STEP - HALF, h = H[k];
      pos.set([x, h, z], k * 3);
      const c = groundColor(x, z, h, RD[k]);
      colors.set([c.r, c.g, c.b], k * 3);
      const shade = Math.min(1.25, Math.max(0.55, 0.85 + 0.08 * (H[k] - H[Math.max(0, k - N - 1)])));
      const water = h < 0;
      img.data.set(water ? [16, 30, 52, 255] : [c.r * 255 * shade, c.g * 255 * shade, c.b * 255 * shade, 255], k * 4);
      heightBytes[k] = Math.max(0, Math.min(255, ((h + 40) / 140) * 255));
      if (i < N - 1 && j < N - 1) idx.push(k, k + N, k + 1, k + 1, k + N, k + N + 1);
    }
  mctx.putImageData(img, 0, 0);
  const tgeo = new THREE.BufferGeometry();
  tgeo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  tgeo.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  tgeo.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(N * N * 2), 2));
  tgeo.setIndex(idx);
  tgeo.computeVertexNormals();
  scene.add(new THREE.Mesh(tgeo, lambert()));

  const heightTex = new THREE.DataTexture(heightBytes, N, N, THREE.RedFormat);
  heightTex.magFilter = heightTex.minFilter = THREE.LinearFilter;
  heightTex.needsUpdate = true;
  U.uHeight.value = heightTex;

  // roads
  const roadGeos = sampledRoads.map(({ pts, width }) => {
    const p = [], uv = [], ind = [];
    let dist = 0;
    pts.forEach(([x, z], k) => {
      const [ax, az] = pts[Math.max(0, k - 1)], [bx, bz] = pts[Math.min(pts.length - 1, k + 1)];
      const tl = Math.hypot(bx - ax, bz - az), nx = -(bz - az) / tl, nz = (bx - ax) / tl;
      if (k) dist += Math.hypot(x - pts[k - 1][0], z - pts[k - 1][1]);
      for (const s of [-1, 1]) {
        const vx = x + (nx * s * width) / 2, vz = z + (nz * s * width) / 2;
        p.push(vx, heightAt(vx, vz) + 0.14, vz);
        uv.push((s + 1) / 2, dist);
      }
      if (k) ind.push(2 * k - 2, 2 * k - 1, 2 * k, 2 * k - 1, 2 * k + 1, 2 * k);
    });
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.Float32BufferAttribute(p, 3));
    g.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
    g.setIndex(ind);
    g.computeVertexNormals();
    return paint(g, '#202232');
  });
  const roadMat = lambert({ ROAD: '' });
  roadMat.flatShading = false;
  roadMat.polygonOffset = true;
  roadMat.polygonOffsetFactor = -2;
  scene.add(new THREE.Mesh(merge(...roadGeos), roadMat));

  mctx.strokeStyle = 'rgba(205,190,170,0.75)';
  mctx.lineCap = 'round';
  for (const { pts, width } of sampledRoads) {
    mctx.lineWidth = width / STEP * 0.6;
    mctx.beginPath();
    pts.forEach(([x, z], k) => mctx[k ? 'lineTo' : 'moveTo']((x + HALF) / STEP, (z + HALF) / STEP));
    mctx.stroke();
  }

  // water
  const water = new THREE.Mesh(new THREE.PlaneGeometry(4000, 4000).rotateX(-Math.PI / 2), patch(new THREE.MeshBasicMaterial(), { WATERS: '' }));
  water.position.y = -0.05;
  scene.add(water);

  const lists = { building: [], antenna: [], house: [], tree: [], pine: [], blossom: [], car: [], lamp: [], pool: [],
    barn: [], silo: [], bale: [], container: [], rock: [], pylon: [] };
  const palette = ['#3b3f63', '#4a4470', '#5d5378', '#6b6a8a', '#2f4a5e', '#7a6a7f', '#4c5a78', '#835f6f'];
  const pick = (arr) => arr[Math.floor(R() * arr.length)];
  const carColors = ['#e9d8b4', '#d0644f', '#3f8c8a', '#e0a64a', '#5a5f8f', '#c9c3d6', '#8a3f4f'];
  const groundY = (x, z) => heightAt(x, z);

  function building(x, z, w, d, h, c, y = groundY(x, z) - 0.5) {
    lists.building.push({ x, y, z, sx: w, sy: h, sz: d, c });
    addBox(x, z, w, d);
    return y + h;
  }

  // city blocks
  for (const b of blocks) {
    const n = b.docks ? 2 : R() < 0.5 ? 2 : 3, lot = (b.x1 - b.x0) / n;
    for (let a = 0; a < n; a++)
      for (let c = 0; c < n; c++) {
        const w = lot - 3 - R() * 5, d = lot - 3 - R() * 5;
        const x = b.x0 + lot * (a + 0.5), z = b.z0 + lot * (c + 0.5);
        const h = b.docks ? 7 + R() * 7 : 9 + R() * 16 + b.tower * R() * 95;
        const color = b.docks ? pick(['#5b4a5e', '#4b5866', '#6d5a52']) : pick(palette);
        let top = building(x, z, w, d, h, color);
        if (!b.docks && h > 34 && R() < 0.6) top = building(x, z, w * 0.66, d * 0.66, h * 0.28, color, top);
        if (h > 40) lists.antenna.push({ x, y: top, z, sy: 4 + R() * 8 });
      }
  }
  for (const p of parks)
    for (let k = 0; k < 14; k++) {
      const x = p.x0 + 4 + R() * (p.x1 - p.x0 - 8), z = p.z0 + 4 + R() * (p.z1 - p.z0 - 8);
      lists.tree.push({ x, y: groundY(x, z), z, sx: 0.8 + R() * 0.5, ry: R() * 6, c: pick(['#3b7d4d', '#2f6a4a', '#c56b5a']) });
      addCircle(x, z, 0.7);
    }

  // parked cars along city curbs
  for (let i = -3; i <= 3; i++)
    for (let s = -235; s < 235; s += 9) {
      if (Math.abs(((s % 80) + 80) % 80 - 40) > 26 || R() < 0.55) continue;
      for (const side of [-1, 1]) {
        if (R() < 0.5) continue;
        const along = R() < 0.5;
        const [x, z] = along ? [i * 80 + side * 4.6, s] : [s, i * 80 + side * 4.6];
        if (Math.abs(x) > 240 || Math.abs(z) > 240 || collide(x, z, 2.4).hit) continue;
        lists.car.push({ x, y: groundY(x, z), z, ry: along ? 0 : Math.PI / 2, c: pick(carColors) });
        addBox(x, z, along ? 2.1 : 4.4, along ? 4.4 : 2.1);
      }
    }

  // docks: container yard
  for (let z = -60; z < 210; z += 15)
    for (let x = 252; x < 300; x += 3.4) {
      if (heightAt(x, z) < 1.3 || heightAt(x, z + 7) < 1.3 || heightAt(x, z - 7) < 1.3 || R() < 0.25) continue;
      const stack = 1 + Math.floor(R() * 3), y0 = groundY(x, z);
      for (let k = 0; k < stack; k++) lists.container.push({ x, y: y0 + k * 2.7, z, c: pick(['#c4573f', '#2f7f86', '#d39a3e', '#4d4f86', '#8b3f52']) });
      addBox(x, z, 2.7, 12.4);
    }

  // suburbs: houses along curving streets, facing the road
  for (const road of sampledRoads.filter((r) => r.kind === 'suburb')) {
    for (let k = 6; k < road.pts.length - 6; k += 12)
      for (const side of [-1, 1]) {
        const [x, z] = road.pts[k], [bx, bz] = road.pts[k + 1];
        const tl = Math.hypot(bx - x, bz - z), nx = (-(bz - z) / tl) * side, nz = ((bx - x) / tl) * side;
        const hx = x + nx * 15, hz = z + nz * 15;
        if (heightAt(hx, hz) < 1.6 || roadDistAt(hx, hz) < 10 || cheb(hx, hz) < CITY + 6 || nearNode(hx, hz, 22) || collide(hx, hz, 7.5).hit) continue;
        const ry = Math.atan2(-nx, -nz), w = 9 + R() * 3, d = 8 + R() * 3;
        lists.house.push({ x: hx, y: groundY(hx, hz) - 0.3, z: hz, ry, sx: w, sy: 4.2 + R() * 1.6, sz: d, c: pick(['#e7dcc8', '#c9d3d8', '#e3c7a8', '#b8c4b0', '#d8b8c0']), roof: pick(['#6b3b45', '#3c4766', '#5a4b3c', '#7a4a3a']) });
        addCircle(hx, hz, 6.2);
        if (R() < 0.45) {
          const cx = hx - nx * 3 + nz * (w / 2 + 2.5), cz = hz - nz * 3 - nx * (w / 2 + 2.5);
          if (!collide(cx, cz, 2.2).hit) { lists.car.push({ x: cx, y: groundY(cx, cz), z: cz, ry, c: pick(carColors) }); addCircle(cx, cz, 2.2); }
        }
        const tx = hx + nx * 8 + nz * (R() - 0.5) * 10, tz = hz + nz * 8 - nx * (R() - 0.5) * 10;
        if (R() < 0.7 && !collide(tx, tz, 1.5).hit) {
          lists.tree.push({ x: tx, y: groundY(tx, tz), z: tz, sx: 0.8 + R() * 0.5, ry: R() * 6, c: pick(['#3b7d4d', '#c56b5a', '#d89a4c', '#2f6a4a']) });
          addCircle(tx, tz, 0.7);
        }
      }
  }

  // farmsteads along rural lanes
  for (const road of sampledRoads.filter((r) => r.kind === 'rural')) {
    for (let k = 10; k < road.pts.length - 10; k += 28) {
      if (R() < 0.35) continue;
      const side = R() < 0.5 ? -1 : 1, [x, z] = road.pts[k], [bx, bz] = road.pts[k + 1];
      const tl = Math.hypot(bx - x, bz - z), nx = (-(bz - z) / tl) * side, nz = ((bx - x) / tl) * side;
      const fx = x + nx * 26, fz = z + nz * 26;
      if (heightAt(fx, fz) < 1.8 || roadDistAt(fx, fz) < 16 || cheb(fx, fz) < CITY + 20 || nearNode(fx, fz, 30) || collide(fx, fz, 14).hit) continue;
      const ry = Math.atan2(-nx, -nz);
      lists.barn.push({ x: fx, y: groundY(fx, fz) - 0.3, z: fz, ry, sx: 10, sy: 7, sz: 14, c: pick(['#9c4a45', '#8a5a4a', '#a8574f']) });
      addCircle(fx, fz, 8);
      const sx = fx + nz * 10, sz = fz - nx * 10;
      lists.silo.push({ x: sx, y: groundY(sx, sz) - 0.3, z: sz, sy: 0.8 + R() * 0.5 });
      addCircle(sx, sz, 2.8);
      for (let b = 0; b < 8; b++) {
        const ax = fx + nx * (14 + R() * 30) + nz * (R() - 0.5) * 40, az = fz + nz * (14 + R() * 30) - nx * (R() - 0.5) * 40;
        if (roadDistAt(ax, az) < 6 || collide(ax, az, 1.6).hit) continue;
        lists.bale.push({ x: ax, y: groundY(ax, az) + 0.9, z: az, ry: R() * 3 });
        addCircle(ax, az, 1.2);
      }
    }
  }

  // orchard rows
  for (let x = -270; x < -150; x += 8)
    for (let z = 370; z < 455; z += 8) {
      const jx = x + (R() - 0.5) * 1.5, jz = z + (R() - 0.5) * 1.5;
      if (roadDistAt(jx, jz) < 8 || heightAt(jx, jz) < 1.6 || nearNode(jx, jz, 20)) continue;
      lists.blossom.push({ x: jx, y: groundY(jx, jz), z: jz, sx: 0.7 + R() * 0.2, ry: R() * 6, c: pick(['#e8a0a8', '#f0c0c8', '#d98a94', '#f2e0e4']) });
      addCircle(jx, jz, 0.6);
    }

  // power plant
  const works = { x: 0, z: 300 };
  const towers = [[-48, 332], [-20, 352]];
  const steam = [];
  const coolingProfile = [[13, 0], [10.5, 8], [8.5, 18], [9.5, 26]].map(([r, y]) => new THREE.Vector2(r, y));
  const coolingGeo = part(new THREE.LatheGeometry(coolingProfile, 20), '#b9b6c9');
  const plantParts = [];
  for (const [x, z] of towers) {
    const y = groundY(x, z) - 0.5;
    plantParts.push(coolingGeo.clone().translate(x, y, z));
    addCircle(x, z, 12.5);
    steam.push([x, y + 26, z]);
  }
  plantParts.push(part(new THREE.BoxGeometry(34, 12, 18), '#4e4c66', 42, groundY(42, 318) + 5.5, 318));
  plantParts.push(part(new THREE.BoxGeometry(18, 7, 12), '#5d5675', 36, groundY(36, 340) + 3, 340));
  addBox(42, 318, 34, 18); addBox(36, 340, 18, 12);
  for (const x of [56, 64]) {
    plantParts.push(part(new THREE.CylinderGeometry(1.3, 1.8, 34, 10), '#6b6680', x, groundY(x, 330) + 17, 330));
    addCircle(x, 330, 1.8);
    lists.antenna.push({ x, y: groundY(x, 330) + 34, z: 330, sy: 0.2 });
  }
  scene.add(new THREE.Mesh(merge(...plantParts), lambert({ WINDOWS: '', WX: '3.0', WY: '3.5' })));

  // wind turbines and windmills on the ridge
  const spinners = [];
  const turbineTower = merge(
    part(new THREE.CylinderGeometry(0.5, 0.9, 36, 8), '#d9d8e6', 0, 18, 0),
    part(new THREE.BoxGeometry(1.6, 1.6, 4), '#d9d8e6', 0, 36, -0.6)
  );
  const bladeParts = [0, 1, 2].map((k) => part(new THREE.BoxGeometry(0.5, 15, 0.15), '#e8e7f2', 0, 7.5, 0).rotateZ((k * Math.PI * 2) / 3));
  const turbineRotor = merge(...bladeParts);
  const turbineList = [];
  const tr = rng(77);
  for (let k = 0; k < 120 && turbineList.length < 11; k++) {
    const a = tr() * Math.PI * 2, rr = 55 + tr() * 110, x = 410 + Math.cos(a) * rr, z = -150 + Math.sin(a) * rr;
    if (heightAt(x, z) < 6 || roadDistAt(x, z) < 14 || nearNode(x, z, 22) || turbineList.some((t) => Math.hypot(t.x - x, t.z - z) < 30) || collide(x, z, 3).hit) continue;
    turbineList.push({ x, y: groundY(x, z) - 0.5, z, ry: 0.6 });
    addCircle(x, z, 1);
  }
  instanced(scene, turbineTower, lambert(), turbineList);
  const rotorMesh = instanced(scene, turbineRotor, lambert(), turbineList);
  spinners.push({ mesh: rotorMesh, list: turbineList, yOff: 36, zOff: 1.5, speed: 1.1 });

  const millTower = merge(
    part(new THREE.CylinderGeometry(2.2, 3.4, 12, 8), '#e2d6c0', 0, 6, 0),
    part(new THREE.ConeGeometry(2.8, 3.5, 8), '#6b3b45', 0, 13.7, 0)
  );
  const millRotor = merge(...[0, 1, 2, 3].map((k) => part(new THREE.BoxGeometry(1.6, 9, 0.12), '#c9b89a', 0, 5, 0).rotateZ((k * Math.PI) / 2)));
  const millList = [];
  for (const [x, z] of [[340, -175], [395, -110], [330, -95], [420, -205]]) {
    if (heightAt(x, z) < 2 || roadDistAt(x, z) < 8 || collide(x, z, 4).hit) continue;
    millList.push({ x, y: groundY(x, z) - 0.3, z, ry: Math.atan2(370 - x, -140 - z) });
    addCircle(x, z, 3.4);
  }
  instanced(scene, millTower, lambert(), millList);
  spinners.push({ mesh: instanced(scene, millRotor, lambert(), millList), list: millList, yOff: 11, zOff: 3, speed: 0.6 });

  // power pylons and cables between linked substations (outside the city)
  const nodeById = Object.fromEntries(NODES.map((n, i) => [n.id, { ...n, i }]));
  const cables = [];
  for (const [a, b] of LINKS) {
    const A = nodeById[a].pos, B = nodeById[b].pos, len = Math.hypot(B[0] - A[0], B[1] - A[1]);
    const ux = (B[0] - A[0]) / len, uz = (B[1] - A[1]) / len, ry = Math.atan2(ux, uz);
    const towersOnLink = [];
    for (let s = 26; s < len - 26; s += 48) {
      let x = A[0] + ux * s, z = A[1] + uz * s;
      if (roadDistAt(x, z) < 7) { x += uz * 12; z -= ux * 12; }
      if (cheb(x, z) < CITY + 8 || heightAt(x, z) < 1 || roadDistAt(x, z) < 7 || collide(x, z, 2.5).hit) continue;
      const p = { x, y: groundY(x, z) - 0.3, z, ry };
      lists.pylon.push(p);
      towersOnLink.push(p);
      addCircle(x, z, 1.5);
    }
    const pts = [];
    for (let k = 0; k < towersOnLink.length - 1; k++) {
      const p = towersOnLink[k], q = towersOnLink[k + 1];
      if (Math.hypot(q.x - p.x, q.z - p.z) > 110) continue;
      for (const off of [-3.4, 3.4]) {
        const ox = uz * off, oz = -ux * off;
        for (let t = 0; t < 8; t++) {
          const f0 = t / 8, f1 = (t + 1) / 8;
          const at = (f) => [p.x + ox + (q.x - p.x) * f, p.y + 17.6 + (q.y - p.y) * f - Math.sin(f * Math.PI) * 3, p.z + oz + (q.z - p.z) * f];
          pts.push(...at(f0), ...at(f1));
        }
      }
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.Float32BufferAttribute(pts, 3));
    const mat = new THREE.LineBasicMaterial({ color: '#2a2740' });
    scene.add(new THREE.LineSegments(g, mat));
    cables.push({ a: nodeById[a].i, b: nodeById[b].i, mat });
  }

  // street lamps with pools of light
  for (const road of sampledRoads) {
    const spacing = road.kind === 'city' ? 14 : 18;
    road.pts.forEach(([x, z], k) => {
      if (k % spacing || k === 0 || k === road.pts.length - 1) return;
      const [bx, bz] = road.pts[k + 1], tl = Math.hypot(bx - x, bz - z);
      for (const side of road.kind === 'city' ? [-1, 1] : [(k / spacing) % 2 ? 1 : -1]) {
        const nx = (-(bz - z) / tl) * side, nz = ((bx - x) / tl) * side;
        const lx = x + nx * (road.width / 2 + 1.2), lz = z + nz * (road.width / 2 + 1.2);
        if (road.kind === 'city' && near80(lx) < 10 && near80(lz) < 10) continue;
        if (heightAt(lx, lz) < 0.8 || collide(lx, lz, 0.6).hit) continue;
        const y = groundY(lx, lz), ry = Math.atan2(-nx, -nz);
        lists.lamp.push({ x: lx, y, z: lz, ry });
        lists.pool.push({ x: lx - nx * 2.2, y: groundY(lx - nx * 2.2, lz - nz * 2.2) + 0.3, z: lz - nz * 2.2, sx: 13 });
        addCircle(lx, lz, 0.35);
      }
    });
  }

  // forests, singles and mountain rocks
  for (let z = -HALF; z < HALF; z += 8)
    for (let x = -HALF; x < HALF; x += 8) {
      const jx = x + (hash2(x, z) - 0.5) * 7, jz = z + (hash2(z + 5, x) - 0.5) * 7;
      if (cheb(jx, jz) < CITY + 4) continue;
      const h = heightAt(jx, jz);
      if (h < 1.7 || roadDistAt(jx, jz) < 10.5 || nearNode(jx, jz, 18) || fieldAt(jx, jz) >= 0) continue;
      const forest = fbm(jx / 130 + 20, jz / 130) + (jz < -230 ? 0.12 : 0) - gauss(jx, jz, -360, -60, 150) * 0.25;
      const roll = hash2(x * 3 + 1, z * 7 + 2);
      if (h > 30 && roll < 0.05) {
        lists.rock.push({ x: jx, y: h - 0.4, z: jz, sx: 1.5 + roll * 50, ry: roll * 99 });
        addCircle(jx, jz, 1.2 + roll * 30);
        continue;
      }
      if (h > 66 || (forest < 0.56 && roll > 0.035)) continue;
      if (collide(jx, jz, 1.2).hit) continue;
      const pine = h > 16 || jz < -240 || forest > 0.66;
      const s = 0.75 + hash2(x + 9, z - 3) * 0.7;
      if (pine) lists.pine.push({ x: jx, y: h - 0.2, z: jz, sx: s, ry: roll * 30, c: h > 40 ? '#2c4f55' : pick(['#1f4a45', '#245247', '#2b5a4c']) });
      else lists.tree.push({ x: jx, y: h - 0.2, z: jz, sx: s, ry: roll * 30, c: pick(['#3b7d4d', '#2f6a4a', '#4a8552', '#c56b5a', '#d89a4c']) });
      addCircle(jx, jz, 0.7);
    }

  /* ---------- instanced meshes ---------- */
  const unitBox = paint(new THREE.BoxGeometry(1, 1, 1).translate(0, 0.5, 0), '#ffffff');
  instanced(scene, unitBox, lambert({ WINDOWS: '', WX: '3.0', WY: '3.6' }), lists.building);
  const antennaMat = new THREE.MeshBasicMaterial({ color: new THREE.Color(4, 0.4, 0.5) });
  instanced(scene, merge(part(new THREE.CylinderGeometry(0.15, 0.25, 1, 5), '#444455', 0, 0.5, 0)), lambert(), lists.antenna);
  const beacons = instanced(scene, new THREE.SphereGeometry(0.45, 8, 6), antennaMat, lists.antenna.map((a) => ({ ...a, y: a.y + a.sy, sy: 1 })));

  instanced(scene, unitBox, lambert({ WINDOWS: '', WX: '3.4', WY: '2.6' }), lists.house);
  const roofGeo = paint(new THREE.CylinderGeometry(1, 1, 1, 3).rotateX(-Math.PI / 2).translate(0, 0.5, 0).scale(0.66, 0.42, 1.1).translate(0, 1, 0), '#ffffff');
  instanced(scene, roofGeo, lambert(), lists.house.map((h) => ({ ...h, c: h.roof })));

  const roundTree = merge(
    part(new THREE.CylinderGeometry(0.28, 0.4, 2.4, 5), '#5a4038', 0, 1.2, 0),
    part(new THREE.IcosahedronGeometry(2.4, 0), '#ffffff', 0, 4.1, 0),
    part(new THREE.IcosahedronGeometry(1.6, 0), '#ffffff', 0.9, 5.4, 0.5)
  );
  instanced(scene, roundTree, lambert(), [...lists.tree, ...lists.blossom]);
  const pineTree = merge(
    part(new THREE.CylinderGeometry(0.3, 0.42, 2, 5), '#4a3530', 0, 1, 0),
    part(new THREE.ConeGeometry(2.6, 5, 7), '#ffffff', 0, 4.2, 0),
    part(new THREE.ConeGeometry(1.9, 4, 7), '#ffffff', 0, 6.6, 0),
    part(new THREE.ConeGeometry(1.1, 2.6, 7), '#ffffff', 0, 8.6, 0)
  );
  instanced(scene, pineTree, lambert(), lists.pine);
  instanced(scene, part(new THREE.DodecahedronGeometry(1, 0).scale(1, 0.7, 1.2), '#6a6582'), lambert(), lists.rock);

  const parkedCar = merge(
    part(new THREE.BoxGeometry(2, 0.9, 4.3), '#ffffff', 0, 0.75, 0),
    part(new THREE.BoxGeometry(1.8, 0.75, 2.2), '#22283a', 0, 1.55, -0.3),
    ...[[-1, 1.4], [1, 1.4], [-1, -1.4], [1, -1.4]].map(([x, z]) => part(new THREE.CylinderGeometry(0.42, 0.42, 0.3, 8).rotateZ(Math.PI / 2), '#151520', x * 0.95, 0.42, z))
  );
  instanced(scene, parkedCar, lambert(), lists.car);
  instanced(scene, paint(new THREE.BoxGeometry(2.6, 2.6, 12).translate(0, 1.3, 0), '#ffffff'), lambert(), lists.container);

  const barn = merge(part(new THREE.BoxGeometry(1, 1, 1), '#ffffff', 0, 0.5, 0), part(new THREE.CylinderGeometry(1, 1, 1, 3).rotateX(-Math.PI / 2).translate(0, 0.5, 0).scale(0.7, 0.55, 1.05).translate(0, 1, 0), '#5a3a3a'));
  instanced(scene, barn, lambert(), lists.barn);
  const silo = merge(part(new THREE.CylinderGeometry(2.5, 2.5, 12, 12), '#9aa2b8', 0, 6, 0), part(new THREE.SphereGeometry(2.5, 12, 6, 0, Math.PI * 2, 0, Math.PI / 2), '#7a8098', 0, 12, 0));
  instanced(scene, silo, lambert(), lists.silo);
  instanced(scene, part(new THREE.CylinderGeometry(0.9, 0.9, 1.6, 10).rotateZ(Math.PI / 2), '#c9a85c'), lambert(), lists.bale);

  const pylon = merge(
    part(new THREE.CylinderGeometry(0.35, 1.6, 19, 4), '#3a3850', 0, 9.5, 0),
    part(new THREE.BoxGeometry(8, 0.35, 0.35), '#3a3850', 0, 17.8, 0),
    part(new THREE.BoxGeometry(5, 0.3, 0.3), '#3a3850', 0, 14.5, 0)
  );
  instanced(scene, pylon, lambert(), lists.pylon);

  const lampPole = merge(
    part(new THREE.CylinderGeometry(0.1, 0.16, 6, 5), '#2c2c3a', 0, 3, 0),
    part(new THREE.BoxGeometry(0.12, 0.12, 2.2), '#2c2c3a', 0, 6, 1.0)
  );
  instanced(scene, lampPole, lambert(), lists.lamp);
  instanced(scene, paint(new THREE.BoxGeometry(0.7, 0.2, 0.9).translate(0, 5.9, 2.1), '#ffffff'), patch(new THREE.MeshBasicMaterial(), { LAMP: '' }), lists.lamp);
  const poolMat = patch(new THREE.MeshBasicMaterial({ transparent: true, blending: THREE.AdditiveBlending, depthWrite: false }), { POOL: '' });
  instanced(scene, new THREE.PlaneGeometry(1, 1).rotateX(-Math.PI / 2), poolMat, lists.pool);

  /* ---------- sky ---------- */
  const sun = new THREE.Vector3(-0.5, 0.35, -0.8).normalize();
  const sky = new THREE.Mesh(
    new THREE.SphereGeometry(1800, 32, 16),
    new THREE.ShaderMaterial({
      side: THREE.BackSide, depthWrite: false, fog: false,
      uniforms: { uTime: U.uTime, uDawn: U.uDawn, uSun: { value: sun } },
      vertexShader: 'varying vec3 vDir; void main(){ vDir = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.); }',
      fragmentShader: `
        uniform float uTime, uDawn; uniform vec3 uSun; varying vec3 vDir;
        float h21(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
        void main(){
          vec3 d = normalize(vDir); float y = d.y;
          vec3 top = mix(vec3(.006, .007, .03), vec3(.12, .25, .55), uDawn);
          vec3 hor = mix(vec3(.10, .035, .11), vec3(1., .5, .28), uDawn);
          vec3 c = mix(hor, top, pow(clamp(y, 0., 1.), .5));
          if (y < 0.) c = hor * .6;
          vec2 sp = vec2(atan(d.z, d.x) * 140., asin(clamp(y, -1., 1.)) * 140.);
          float s = h21(floor(sp));
          c += step(.986, s) * smoothstep(.45, .0, length(fract(sp) - .5)) * (.6 + .4 * sin(uTime * 2. + s * 50.)) * (1. - uDawn) * smoothstep(0., .2, y) * 1.4;
          float a = sin(d.x * 5. + uTime * .12 + sin(d.z * 3.5 + uTime * .09) * 2.2) * .5 + .5;
          a *= smoothstep(.12, .4, y) * smoothstep(.85, .4, y);
          c += pow(a, 5.) * (.6 + .4 * sin(d.z * 22. + uTime * .4)) * mix(vec3(.05, .8, .55), vec3(.6, .15, .85), smoothstep(.2, .7, y)) * .35 * (1. - uDawn);
          float md = dot(d, normalize(uSun));
          c += smoothstep(.9986, .9991, md) * mix(vec3(2.4, 2.3, 2.1), vec3(4., 2.6, 1.3), uDawn);
          c += pow(max(md, 0.), 80.) * mix(vec3(.18, .16, .3), vec3(1.2, .6, .3), uDawn);
          gl_FragColor = vec4(c, 1.);
        }`,
    })
  );
  sky.renderOrder = -1;
  scene.add(sky);

  // drifting clouds
  const cloudList = [];
  const cr = rng(5);
  for (let k = 0; k < 60; k++) {
    const x = (cr() - 0.5) * 1600, z = (cr() - 0.5) * 1600, y = 150 + cr() * 60;
    for (let p = 0; p < 4; p++) cloudList.push({ x: x + (cr() - 0.5) * 50, y: y + cr() * 8, z: z + (cr() - 0.5) * 25, sx: 14 + cr() * 18, sy: 6 + cr() * 5, sz: 12 + cr() * 14, ry: cr() * 3 });
  }
  const cloudMat = new THREE.MeshBasicMaterial({ color: '#221f3d', transparent: true, opacity: 0.75, fog: false });
  const clouds = instanced(scene, new THREE.IcosahedronGeometry(1, 1), cloudMat, cloudList);
  clouds.frustumCulled = false;

  // fireflies that hover over the terrain around the camera
  const ffCount = 900, ffPos = new Float32Array(ffCount * 3);
  for (let k = 0; k < ffCount; k++) ffPos.set([cr() * 160, cr(), cr() * 160], k * 3);
  const ffGeo = new THREE.BufferGeometry();
  ffGeo.setAttribute('position', new THREE.BufferAttribute(ffPos, 3));
  const ffUniforms = { uCam: { value: new THREE.Vector3() }, uTime: U.uTime, uHeight: U.uHeight, uDawn: U.uDawn };
  const fireflies = new THREE.Points(ffGeo, new THREE.ShaderMaterial({
    uniforms: ffUniforms, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
    vertexShader: `
      uniform vec3 uCam; uniform float uTime; uniform sampler2D uHeight; varying float vA; varying float vHue;
      void main(){
        vec3 p = position;
        p.xz = mod(p.xz - uCam.xz + 80., 160.) - 80. + uCam.xz;
        p.x += sin(uTime * .4 + position.z) * 2.; p.z += cos(uTime * .3 + position.x) * 2.;
        float th = texture2D(uHeight, (p.xz + ${HALF}.) / ${HALF * 2}.).r * 140. - 40.;
        p.y = max(th, 0.) + 1. + position.y * 7. + sin(uTime + position.x) * .6;
        vec4 mv = modelViewMatrix * vec4(p, 1.);
        vA = (.5 + .5 * sin(uTime * 2.5 + position.x * 7.)) * smoothstep(80., 40., length(p.xz - uCam.xz));
        vHue = fract(position.z * 3.1);
        gl_PointSize = 90. / -mv.z;
        gl_Position = projectionMatrix * mv;
      }`,
    fragmentShader: `
      uniform float uDawn; varying float vA; varying float vHue;
      void main(){
        float d = length(gl_PointCoord - .5);
        float a = smoothstep(.5, .0, d) * vA * (1. - uDawn);
        gl_FragColor = vec4(mix(vec3(2., 1.3, .5), vec3(.5, 1.8, 1.4), step(.7, vHue)) * a, a);
      }`,
  }));
  fireflies.frustumCulled = false;
  scene.add(fireflies);

  /* ---------- substations ---------- */
  const nodeVis = NODES.map((n) => {
    const [x, z] = n.pos, y = groundY(x, z);
    const g = new THREE.Group();
    g.position.set(x, y, z);
    const metal = lambert();
    const base = new THREE.Mesh(merge(
      part(new THREE.CylinderGeometry(10, 11, 0.5, 24), '#2b2a3d', 0, 0.05, 0),
      part(new THREE.CylinderGeometry(2.6, 3.2, 2, 8), '#3a3852', 0, 1.4, 0)
    ), metal);
    const glow = new THREE.MeshBasicMaterial({ color: '#000' });
    const pillar = new THREE.Mesh(new THREE.CylinderGeometry(0.9, 1.3, 14, 8).translate(0, 9, 0), glow);
    const rings = [4.5, 8.5, 12.5].map((h, k) => {
      const ring = new THREE.Mesh(new THREE.TorusGeometry(3.4 - k * 0.6, 0.18, 6, 32), glow);
      ring.position.y = h;
      ring.rotation.x = Math.PI / 2;
      g.add(ring);
      return ring;
    });
    const padMat = new THREE.MeshBasicMaterial({ color: '#000', transparent: true, blending: THREE.AdditiveBlending, depthWrite: false });
    const pad = new THREE.Mesh(new THREE.RingGeometry(9.2, 10.4, 48).rotateX(-Math.PI / 2), padMat);
    pad.position.y = 0.7;
    const beamMat = new THREE.ShaderMaterial({
      uniforms: { uColor: { value: new THREE.Color() }, uTime: U.uTime },
      transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide,
      vertexShader: 'varying vec2 vUv; void main(){ vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.); }',
      fragmentShader: 'uniform vec3 uColor; uniform float uTime; varying vec2 vUv; void main(){ float a = pow(1. - vUv.y, 2.2) * (.6 + .4 * sin(vUv.y * 90. - uTime * 4.)); gl_FragColor = vec4(uColor * a, a); }',
    });
    const beam = new THREE.Mesh(new THREE.CylinderGeometry(1.4, 1.4, 320, 12, 1, true).translate(0, 160, 0), beamMat);
    const orb = new THREE.Mesh(new THREE.IcosahedronGeometry(1, 1), new THREE.MeshBasicMaterial({ color: new THREE.Color(4, 2.2, 0.8) }));
    orb.position.y = 18;
    g.add(base, pillar, pad, beam, orb);
    scene.add(g);
    addCircle(x, z, 3.2);
    return { group: g, glow, padMat, beamMat, rings, orb, y };
  });

  return {
    mapCanvas, nodeVis, cables, steam, roads: sampledRoads,
    update(t, dt, cam) {
      U.uTime.value = t;
      ffUniforms.uCam.value.copy(cam);
      for (const s of spinners) {
        s.list.forEach((o, i) => {
          dummy.position.set(o.x + Math.sin(o.ry) * s.zOff, o.y + s.yOff, o.z + Math.cos(o.ry) * s.zOff);
          dummy.rotation.set(0, o.ry, t * s.speed + i);
          dummy.scale.set(1, 1, 1);
          dummy.updateMatrix();
          s.mesh.setMatrixAt(i, dummy.matrix);
        });
        s.mesh.instanceMatrix.needsUpdate = true;
      }
      antennaMat.color.setScalar(0).setRGB(4 * (0.5 + 0.5 * Math.sin(t * 2.2)) + 0.3, 0.3, 0.4);
      clouds.position.x = ((t * 3) % 400) - 200;
      const d = U.uDawn.value;
      cloudMat.color.setRGB(0.13 + d * 0.9, 0.12 + d * 0.65, 0.24 + d * 0.5);
      beacons.visible = d < 0.9;
    },
  };
}
