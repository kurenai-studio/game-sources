// Procedural low-poly models (palms, trees, rocks, boats, clouds, cars) and per-style materials.
// Everything is generated in code, so there are no model files to download.
import * as THREE from 'three';
import { mergeGeometries, mergeVertices } from 'three/addons/utils/BufferGeometryUtils.js';
import { rng } from './noise.js';
import * as P from './props.js';

export const col = (hex) => new THREE.Color(hex);
export const shade = (hex, k) => col(hex).multiplyScalar(k);

export function xf(pos = [0, 0, 0], rot = [0, 0, 0], scale = [1, 1, 1]) {
  return new THREE.Matrix4().compose(
    new THREE.Vector3(...pos),
    new THREE.Quaternion().setFromEuler(new THREE.Euler(...rot)),
    new THREE.Vector3(...scale),
  );
}

// Bake a solid vertex colour into a geometry so many parts can merge into one mesh.
export function part(geom, color, matrix) {
  const g = geom.index ? geom.toNonIndexed() : geom;
  if (matrix) g.applyMatrix4(matrix);
  for (const k of Object.keys(g.attributes)) if (k !== 'position' && k !== 'normal') g.deleteAttribute(k);
  const c = color instanceof THREE.Color ? color : col(color);
  const n = g.attributes.position.count, arr = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { arr[i * 3] = c.r; arr[i * 3 + 1] = c.g; arr[i * 3 + 2] = c.b; }
  g.setAttribute('color', new THREE.BufferAttribute(arr, 3));
  return g;
}

export function jitter(g, amount, seed = 1) {
  const p = g.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const x = p.getX(i), y = p.getY(i), z = p.getZ(i);
    const h = Math.abs(Math.sin(x * 12.9898 + y * 78.233 + z * 37.719 + seed) * 43758.5453) % 1;
    const k = 1 - amount + 2 * amount * h;
    p.setXYZ(i, x * k, y * k, z * k);
  }
  g.computeVertexNormals();
  return g;
}

function palmGeometry(f) {
  const parts = [];
  let x = 0, y = 0;
  for (let i = 0; i < 6; i++) {
    const r0 = 0.26 - i * 0.025, h = 1.08, lean = 0.05 + i * 0.045;
    const g = new THREE.CylinderGeometry(r0 - 0.025, r0, h, 6);
    parts.push(part(g, i % 2 ? col(f.palmTrunk) : shade(f.palmTrunk, 0.86),
      xf([x + Math.sin(lean) * h / 2, y + Math.cos(lean) * h / 2, 0], [0, 0, -lean])));
    x += Math.sin(lean) * h;
    y += Math.cos(lean) * h;
  }
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * Math.PI * 2 + (i % 2) * 0.2, e = -0.25 - (i % 3) * 0.12;
    const g = new THREE.ConeGeometry(0.55, 3.4, 4, 1);
    g.translate(0, 1.7, 0);
    g.scale(0.16, 1, 1);
    g.rotateZ(-(Math.PI / 2 - e));
    g.rotateY(a);
    g.translate(x, y, 0);
    parts.push(part(g, i % 2 ? col(f.palmLeaf) : shade(f.palmLeaf, 0.84)));
  }
  parts.push(part(new THREE.IcosahedronGeometry(0.22, 0), f.trunk, xf([x + 0.15, y - 0.25, 0.1])));
  parts.push(part(new THREE.IcosahedronGeometry(0.2, 0), f.trunk, xf([x - 0.1, y - 0.25, -0.15])));
  return mergeGeometries(parts);
}

function roundTreeGeometry(f, detail) {
  return mergeGeometries([
    part(new THREE.CylinderGeometry(0.22, 0.32, 2.4, 6), f.trunk, xf([0, 1.2, 0])),
    part(new THREE.IcosahedronGeometry(1.9, detail), f.leaf, xf([0, 3.6, 0], [0.3, 0.5, 0], [1, 0.9, 1])),
    part(new THREE.IcosahedronGeometry(1.25, detail), f.leaf2, xf([1.0, 3.0, 0.5], [0.8, 0.2, 0])),
    part(new THREE.IcosahedronGeometry(1.1, detail), shade(f.leaf, 0.92), xf([-0.8, 4.4, -0.4])),
  ]);
}

function pineGeometry(f) {
  return mergeGeometries([
    part(new THREE.CylinderGeometry(0.18, 0.26, 1.6, 5), f.trunk, xf([0, 0.8, 0])),
    part(new THREE.ConeGeometry(1.9, 2.8, 7), f.pine, xf([0, 2.6, 0])),
    part(new THREE.ConeGeometry(1.45, 2.4, 7), shade(f.pine, 1.08), xf([0, 3.8, 0])),
    part(new THREE.ConeGeometry(0.95, 2.0, 7), shade(f.pine, 1.16), xf([0, 4.9, 0])),
  ]);
}

function rockGeometry(f) {
  const g = jitter(new THREE.DodecahedronGeometry(1, 0), 0.25, 3);
  return part(g, f.rock, xf([0, 0.3, 0], [0, 0, 0], [1.3, 0.75, 1.1]));
}

function islandGeometry(f) {
  const g = jitter(new THREE.ConeGeometry(1, 1, 10, 4), 0.18, 7);
  g.translate(0, 0.5, 0);
  const out = part(g, f.island);
  const p = out.attributes.position, c = out.attributes.color, sand = col(f.sand ?? '#e8d3a4');
  for (let i = 0; i < p.count; i += 3) {
    const yAvg = (p.getY(i) + p.getY(i + 1) + p.getY(i + 2)) / 3;
    if (yAvg < 0.12) for (let j = 0; j < 3; j++) c.setXYZ(i + j, sand.r, sand.g, sand.b);
  }
  return out;
}

function boatGeometry(f) {
  const hull = part(new THREE.BoxGeometry(1.3, 0.6, 4, 1, 1, 2), f.hull);
  const p = hull.attributes.position;
  for (let i = 0; i < p.count; i++) {
    let x = p.getX(i);
    if (p.getY(i) < 0) x *= 0.45;
    if (p.getZ(i) < -1.2) x *= 0.25;
    p.setX(i, x);
  }
  hull.computeVertexNormals();
  const sail = new THREE.ShapeGeometry(new THREE.Shape([
    new THREE.Vector2(0, 0.5), new THREE.Vector2(0, 4.0), new THREE.Vector2(-2.0, 0.6),
  ]));
  sail.rotateY(Math.PI / 2);
  sail.translate(0, 0, 0.2);
  return mergeGeometries([
    hull,
    part(new THREE.CylinderGeometry(0.05, 0.06, 4.2, 5), f.trunk, xf([0, 2.3, 0.2])),
    part(sail, f.sail),
  ]);
}

function cloudGeometry(f, detail) {
  const r = rng(77), parts = [];
  for (let k = 0; k < 7; k++) {
    const rad = 4 + r() * 5;
    parts.push(part(new THREE.IcosahedronGeometry(rad, detail), f.cloud,
      xf([(r() - 0.5) * 24, r() * 4, (r() - 0.5) * 8], [r(), r(), r()], [1, 0.75, 1])));
  }
  const g = mergeGeometries(parts);
  const p = g.attributes.position;
  for (let i = 0; i < p.count; i++) if (p.getY(i) < -1) p.setY(i, -1);
  g.computeVertexNormals();
  return g;
}

function postGeometry(f) {
  return part(new THREE.BoxGeometry(0.18, 0.9, 0.18), f.post, xf([0, 0.45, 0]));
}

// Smooth-normal copy used for the inverted-hull outlines in the toon style.
export function outlineGeometry(g) {
  const p = new THREE.BufferGeometry();
  p.setAttribute('position', g.getAttribute('position').clone());
  if (g.index) p.setIndex(g.index.clone());
  const m = mergeVertices(p, 1e-3);
  m.computeVertexNormals();
  return m;
}

function outlineMaterial(hex, width) {
  const m = new THREE.MeshBasicMaterial({ color: col(hex), side: THREE.BackSide });
  m.onBeforeCompile = (sh) => {
    sh.vertexShader = sh.vertexShader.replace('#include <begin_vertex>',
      `#include <begin_vertex>\n transformed += normal * ${width.toFixed(3)};`);
  };
  m.customProgramCacheKey = () => 'outline' + width;
  return m;
}

function toonRamp() {
  const t = new THREE.DataTexture(new Uint8Array([90, 175, 255]), 3, 1, THREE.RedFormat);
  t.minFilter = t.magFilter = THREE.NearestFilter;
  t.needsUpdate = true;
  return t;
}

function makeSurface(style, ramp, p) {
  switch (style.material) {
    case 'flat': return new THREE.MeshStandardMaterial({ roughness: 0.92, metalness: 0, flatShading: true, ...p });
    case 'toon': return new THREE.MeshToonMaterial({ gradientMap: ramp, ...p });
    case 'soft': return new THREE.MeshLambertMaterial(p);
    case 'pbr': return new THREE.MeshStandardMaterial({ roughness: 0.88, metalness: 0, ...p });
    case 'neon': return new THREE.MeshBasicMaterial({ color: col(style.flora.silhouette), side: p.side ?? THREE.FrontSide });
  }
}

function roadTexture(r) {
  const cv = document.createElement('canvas');
  cv.width = 256; cv.height = 512;
  const g = cv.getContext('2d');
  g.fillStyle = r.asphalt;
  g.fillRect(0, 0, 256, 512);
  const rand = rng(5);
  for (let i = 0; i < 2600; i++) {
    g.fillStyle = rand() < 0.5 ? `rgba(255,255,255,${rand() * 0.05})` : `rgba(0,0,0,${rand() * 0.08})`;
    g.fillRect(rand() * 256, rand() * 512, 2, 2);
  }
  g.fillStyle = r.line;
  g.fillRect(14, 0, 8, 512);
  g.fillRect(234, 0, 8, 512);
  g.fillStyle = r.center;
  g.fillRect(124, 0, 8, 280);
  const tex = new THREE.CanvasTexture(cv);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.anisotropy = 8;
  return tex;
}

function roadMaterial(style, ramp) {
  const map = roadTexture(style.road);
  const shared = { map, polygonOffset: true, polygonOffsetFactor: -2, polygonOffsetUnits: -2 };
  switch (style.material) {
    case 'neon': return new THREE.MeshBasicMaterial({ ...shared, color: new THREE.Color(1.6, 1.6, 1.6) });
    case 'flat': return new THREE.MeshStandardMaterial({ ...shared, roughness: 0.9 });
    case 'toon': return new THREE.MeshToonMaterial({ ...shared, gradientMap: ramp });
    case 'soft': return new THREE.MeshLambertMaterial(shared);
    case 'pbr': return new THREE.MeshStandardMaterial({ ...shared, roughness: 0.75 });
  }
}

function cloudMaterial(style, ramp) {
  const c = col(style.flora.cloud), fog = style.clouds.fog;
  switch (style.material) {
    case 'toon': return new THREE.MeshToonMaterial({ color: c, gradientMap: ramp, fog });
    case 'flat': return new THREE.MeshStandardMaterial({ color: c, flatShading: true, roughness: 1, emissive: c.clone().multiplyScalar(0.35), fog });
    case 'soft': return new THREE.MeshLambertMaterial({ color: c, emissive: c.clone().multiplyScalar(0.45), fog });
    case 'pbr': return new THREE.MeshStandardMaterial({ color: c, roughness: 1, emissive: col(style.sky.horizon).multiplyScalar(0.35), fog });
    default: return new THREE.MeshBasicMaterial({ color: c, fog });
  }
}

// Two opposed light cones from the lighthouse lantern, spun around y at night.
function beamGeometry() {
  const one = new THREE.ConeGeometry(5, 70, 16, 1, true);
  one.translate(0, -35, 0);
  one.rotateZ(Math.PI / 2);
  const two = one.clone().rotateY(Math.PI);
  return mergeGeometries([one, two]);
}

function propPalette(style) {
  const f = style.flora, t = style.terrain;
  return {
    trunk: f.trunk, leaf: f.leaf, leaf2: f.leaf2, pine: f.pine, rock: f.rock, sand: t.sand, grass: t.grass,
    cypress: '#' + shade(f.pine, 0.9).getHexString(),
    ...style.props,
  };
}

export function buildAssets(style, terrainMaterial) {
  const f = style.flora, ramp = toonRamp(), p = propPalette(style);
  const geoms = {
    palm: palmGeometry(f),
    tree: roundTreeGeometry(f, style.detail),
    pine: pineGeometry(f),
    rock: rockGeometry(f),
    island: islandGeometry({ ...f, sand: style.terrain.sand }),
    boat: boatGeometry(f),
    cloud: cloudGeometry(f, style.detail),
    post: postGeometry(f),
    cypress: P.cypress(p), olive: P.olive(p), bush: P.bush(p), grassTuft: P.grassTuft(p), flowers: P.flowers(p),
    cactus: P.cactus(p), sign: P.sign(p), lamp: P.lampPost(p), fence: P.fence(p), pier: P.pierSegment(p),
    lighthouse: P.lighthouse(p), turbine: P.windTurbine(p),
  };
  for (let v = 0; v < 6; v++) geoms[`house${v}`] = P.house(p, v);
  for (let v = 0; v < 4; v++) geoms[`beachHut${v}`] = P.beachHut(p, v);
  for (let v = 0; v < 3; v++) geoms[`umbrella${v}`] = P.umbrella(p, v);

  const mats = {
    flora: makeSurface(style, ramp, { vertexColors: true }),
    floraDouble: makeSurface(style, ramp, { vertexColors: true, side: THREE.DoubleSide }),
    terrain: terrainMaterial ?? makeSurface(style, ramp, { vertexColors: true }),
    road: roadMaterial(style, ramp),
    cloud: cloudMaterial(style, ramp),
    post: style.material === 'neon'
      ? new THREE.MeshBasicMaterial({ color: col(style.road.line).multiplyScalar(2) })
      : makeSurface(style, ramp, { vertexColors: true }),
    // Windows, lamps and lanterns. main.js scales the colour with how dark it is.
    glow: new THREE.MeshBasicMaterial({ vertexColors: true }),
    beam: new THREE.MeshBasicMaterial({
      color: col(p.lamp ?? '#fff2c4'), transparent: true, opacity: 0, blending: THREE.AdditiveBlending,
      depthWrite: false, side: THREE.DoubleSide, fog: true,
    }),
  };
  let outlineGeoms = null;
  if (style.outline) {
    mats.outline = outlineMaterial(style.outline.color, style.outline.width);
    outlineGeoms = {};
    for (const k of ['palm', 'tree', 'pine', 'rock', 'boat', 'post']) outlineGeoms[k] = outlineGeometry(geoms[k]);
  }
  const beam = beamGeometry();
  return {
    geoms, mats, outlineGeoms, ramp, beamGeometry: beam,
    dispose() {
      for (const g of Object.values(geoms)) {
        if (g.isBufferGeometry) { g.dispose(); continue; }
        g.base?.dispose();
        g.glow?.dispose();
        g.rotor?.dispose();
      }
      beam.dispose();
      if (outlineGeoms) for (const g of Object.values(outlineGeoms)) g.dispose();
      for (const m of Object.values(mats)) { m.map?.dispose(); m.dispose(); }
      ramp.dispose();
    },
  };
}

export const MAX_CLOUDS = 40;

export function buildClouds(style, assets, around) {
  const g = new THREE.Group(), r = rng(4242);
  for (let k = 0; k < MAX_CLOUDS; k++) {
    const m = new THREE.Mesh(assets.geoms.cloud, assets.mats.cloud);
    m.position.set(around.x + (r() - 0.5) * 1400, 120 + r() * 110, around.z + 300 - r() * 1500);
    const s = 0.9 + r() * 1.5;
    m.scale.set(s * (1 + r() * 0.8), s * 0.8, s);
    m.rotation.y = r() * Math.PI;
    g.add(m);
  }
  return g;
}

