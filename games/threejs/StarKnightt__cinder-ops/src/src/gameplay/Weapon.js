import * as THREE from 'three';
import { mergeGeometries, mergeVertices } from 'three/addons/utils/BufferGeometryUtils.js';
import { WEAPONS, CAMERA } from '../core/Constants.js';
import { gameState } from '../core/GameState.js';
import { eventBus, Events } from '../core/EventBus.js';
import {
  recoilImpulse, currentSpread, stepViewmodel, impulseViewmodel,
  makeViewmodel, BURST_IDLE,
} from './Gunplay.js';

/* AK-47 viewmodel — CS2-style stamped rifle.
 * Camera looks down -Z. Gun local: +Z stock / -Z muzzle, +Y up, +X right.
 *
 * Magenta root cause (c7): SphereGeometry / raw boxes on glove+aoMap were
 * missing uv2 while customProgramCacheKey locked every mesh to the uv2
 * program compiled from the palm extrude. WebGL missing-attribute → error
 * magenta slab in ADS (lower grip/hand). Every geo now gets uv2; instanced
 * meshes get cloned materials; hulls are merged + smooth-shaded.
 */

const DUMMY = new THREE.Object3D();
const _v2 = [];
const _muzzleRight = new THREE.Vector3();
const _muzzleUp = new THREE.Vector3();
const _muzzleFwd = new THREE.Vector3();

function ensureUV2(geo) {
  if (!geo.attributes.uv) {
    const pos = geo.attributes.position;
    geo.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(pos.count * 2), 2));
    const uv = geo.attributes.uv;
    for (let i = 0; i < pos.count; i++) {
      uv.setXY(i, pos.getX(i) * 8 + 0.5, pos.getY(i) * 8 + 0.5);
    }
  }
  if (!geo.attributes.uv2) geo.setAttribute('uv2', geo.attributes.uv.clone());
  return geo;
}

function planarUV(geo, s = 8) {
  const pos = geo.attributes.position;
  if (!geo.attributes.uv) {
    geo.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(pos.count * 2), 2));
  }
  const uv = geo.attributes.uv;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), y = pos.getY(i), z = pos.getZ(i);
    const ax = Math.abs(x), ay = Math.abs(y), az = Math.abs(z);
    if (ay >= ax && ay >= az) uv.setXY(i, x * s + 0.5, z * s + 0.5);
    else if (ax >= az) uv.setXY(i, z * s + 0.5, y * s + 0.5);
    else uv.setXY(i, x * s + 0.5, y * s + 0.5);
  }
  uv.needsUpdate = true;
  geo.setAttribute('uv2', uv.clone());
  return geo;
}

function weldByAngle(geo, deg = 42) {
  let g = geo.index ? geo.toNonIndexed() : geo;
  try { g = mergeVertices(g, 1e-4); } catch { /* keep */ }
  if (g.index) {
    try { g = g.toNonIndexed(); } catch { /* keep */ }
  }
  const pos = g.attributes.position;
  const nrm = new Float32Array(pos.count * 3);
  const cosA = Math.cos(THREE.MathUtils.degToRad(deg));
  const faceN = [];
  const buckets = new Map();
  const keyOf = (x, y, z) => `${(x * 1800) | 0}_${(y * 1800) | 0}_${(z * 1800) | 0}`;
  for (let i = 0; i < pos.count; i += 3) {
    const ax = pos.getX(i), ay = pos.getY(i), az = pos.getZ(i);
    const bx = pos.getX(i + 1), by = pos.getY(i + 1), bz = pos.getZ(i + 1);
    const cx = pos.getX(i + 2), cy = pos.getY(i + 2), cz = pos.getZ(i + 2);
    const e1x = bx - ax, e1y = by - ay, e1z = bz - az;
    const e2x = cx - ax, e2y = cy - ay, e2z = cz - az;
    let nx = e1y * e2z - e1z * e2y;
    let ny = e1z * e2x - e1x * e2z;
    let nz = e1x * e2y - e1y * e2x;
    const len = Math.hypot(nx, ny, nz) || 1;
    nx /= len; ny /= len; nz /= len;
    faceN.push(nx, ny, nz);
    for (let k = 0; k < 3; k++) {
      const vi = i + k;
      const k0 = keyOf(pos.getX(vi), pos.getY(vi), pos.getZ(vi));
      let arr = buckets.get(k0);
      if (!arr) { arr = []; buckets.set(k0, arr); }
      arr.push(vi);
    }
  }
  for (let i = 0; i < pos.count; i++) {
    const fi = (i / 3) | 0;
    const fnx = faceN[fi * 3], fny = faceN[fi * 3 + 1], fnz = faceN[fi * 3 + 2];
    const nbr = buckets.get(keyOf(pos.getX(i), pos.getY(i), pos.getZ(i))) || [i];
    let sx = 0, sy = 0, sz = 0;
    for (const vi of nbr) {
      const fj = (vi / 3) | 0;
      const dx = faceN[fj * 3], dy = faceN[fj * 3 + 1], dz = faceN[fj * 3 + 2];
      if (fnx * dx + fny * dy + fnz * dz >= cosA) {
        sx += dx; sy += dy; sz += dz;
      }
    }
    const len = Math.hypot(sx, sy, sz) || 1;
    nrm[i * 3] = sx / len;
    nrm[i * 3 + 1] = sy / len;
    nrm[i * 3 + 2] = sz / len;
  }
  g.setAttribute('normal', new THREE.BufferAttribute(nrm, 3));
  return g;
}

function smooth(geo, planar = false, s = 10) {
  if (planar) planarUV(geo, s);
  else ensureUV2(geo);
  const g = weldByAngle(geo, planar ? 26 : 44);
  if (planar) planarUV(g, s);
  else ensureUV2(g);
  return g;
}

/* Stamped planes: UVs + hard normals. Do not weld — pass 5 disc was over-smooth. */
function crisp(geo, s = 10) {
  planarUV(geo, s);
  geo.computeVertexNormals();
  return geo;
}

function boxCrisp(sx, sy, sz, mat, name, uv = 8) {
  return mesh(crisp(new THREE.BoxGeometry(sx, sy, sz), uv), mat, name);
}

function mesh(geo, mat, name) {
  const m = new THREE.Mesh(ensureUV2(geo), mat);
  m.castShadow = false;
  m.receiveShadow = false;
  m.frustumCulled = false;
  if (name) m.name = name;
  return m;
}

function put(obj, x, y, z, rx = 0, ry = 0, rz = 0) {
  obj.position.set(x, y, z);
  if (rx || ry || rz) obj.rotation.set(rx, ry, rz);
  return obj;
}

function cyl(rt, rb, h, mat, seg = 24, name) {
  const geo = smooth(new THREE.CylinderGeometry(rt, rb, h, seg), false);
  return mesh(geo, mat, name);
}

function roundedRect(w, h, r) {
  const s = new THREE.Shape();
  const x = -w * 0.5;
  const y = -h * 0.5;
  const k = Math.min(r, w * 0.45, h * 0.45);
  s.moveTo(x + k, y);
  s.lineTo(x + w - k, y);
  s.quadraticCurveTo(x + w, y, x + w, y + k);
  s.lineTo(x + w, y + h - k);
  s.quadraticCurveTo(x + w, y + h, x + w - k, y + h);
  s.lineTo(x + k, y + h);
  s.quadraticCurveTo(x, y + h, x, y + h - k);
  s.lineTo(x, y + k);
  s.quadraticCurveTo(x, y, x + k, y);
  return s;
}

function extrudeRaw(shape, depth, bevel = 0.0022, segs = 5) {
  return new THREE.ExtrudeGeometry(shape, {
    depth,
    bevelEnabled: bevel > 0,
    bevelThickness: bevel,
    bevelSize: bevel,
    bevelSegments: segs,
    curveSegments: 16,
  });
}

function extrude(shape, depth, mat, name, bevel = 0.0022) {
  return mesh(smooth(extrudeRaw(shape, depth, bevel), true, 12), mat, name);
}

function extrudeCrisp(shape, depth, mat, name, bevel = 0.0010) {
  return mesh(crisp(extrudeRaw(shape, depth, bevel), 10), mat, name);
}

/** Side profile: shape.x → gun +Z, shape.y → gun +Y, depth → width on X. */
function extrudeZY(shape, width, mat, name, bevel = 0.0014) {
  const geo = smooth(extrudeRaw(shape, width, bevel), true, 12);
  geo.translate(0, 0, -width * 0.5);
  geo.rotateY(-Math.PI / 2);
  return mesh(geo, mat, name);
}

function extrudeZYCrisp(shape, width, mat, name, bevel = 0.0010) {
  const geo = crisp(extrudeRaw(shape, width, bevel, 6), 10);
  geo.translate(0, 0, -width * 0.5);
  geo.rotateY(-Math.PI / 2);
  return mesh(geo, mat, name);
}

function extrudeZYSoft(shape, width, mat, name, bevel = 0.0026) {
  /* Chamfer-to-smooth: 8-seg bevel + 38° weld so long edges read as
   * rolled sheet, not a CAD N-gon. Stamp creases stay (angle > 38). */
  let geo = extrudeRaw(shape, width, bevel, 8);
  geo = weldByAngle(geo, 38);
  planarUV(geo, 12);
  geo.translate(0, 0, -width * 0.5);
  geo.rotateY(-Math.PI / 2);
  return mesh(geo, mat, name);
}

/* Split giant planar caps so a highlight cannot smear across one face.
 * Intermediate bevel loops + a shallow crown / crease on axis-aligned flats.
 * Re-weld after displace — computeVertexNormals() was re-hardening the
 * chamfer-to-smooth transition into CAD facets. */
function stampFlats(geo, amp = 0.0011, mode = 'panel') {
  const p = geo.attributes.position;
  if (!geo.attributes.normal) geo.computeVertexNormals();
  const n = geo.attributes.normal;
  const crownOnly = mode === 'crown';
  for (let i = 0; i < p.count; i++) {
    const x = p.getX(i), y = p.getY(i), z = p.getZ(i);
    const nx = n.getX(i), ny = n.getY(i), nz = n.getZ(i);
    const m = Math.max(Math.abs(nx), Math.abs(ny), Math.abs(nz));
    if (m < 0.90) continue;
    /* Panel/crease sines were the dust-cover "quilted duct-tape" read. */
    const panel = crownOnly ? 0 : Math.abs(Math.sin(y * 36 + z * 22)) * Math.abs(Math.sin(z * 18 + x * 14));
    const crease = crownOnly ? 0 : (Math.abs(Math.sin(y * 26 + 0.4)) < 0.16 ? 1 : 0);
    const crown = 0.35 * (1 - Math.min(1, Math.abs(y - 0.024) / 0.040));
    const d = amp * (panel * 0.40 + crease * 0.55 + crown * 0.35);
    p.setX(i, x + nx * d);
    p.setY(i, y + ny * d * 0.45);
    p.setZ(i, z + nz * d * 0.45);
  }
  p.needsUpdate = true;
  return weldByAngle(geo, 36);
}

/* Neutral gunmetal VC. Bevels go near-black-rough so chamfer glitter dies;
 * flats stay near 1.0 so the stamped normal can still catch light. */
function markGunmetalVC(geo, { flat = 0.78, bevel = 0.34, wearAmp = 0.06, mottAmp = 1 } = {}) {
  if (!geo.attributes.normal) geo.computeVertexNormals();
  const rp = geo.attributes.position;
  const rn = geo.attributes.normal;
  const rc = new Float32Array(rp.count * 3);
  for (let i = 0; i < rp.count; i++) {
    const x = rp.getX(i), y = rp.getY(i), z = rp.getZ(i);
    const m = Math.max(Math.abs(rn.getX(i)), Math.abs(rn.getY(i)), Math.abs(rn.getZ(i)));
    const mott = 0.5 + 0.5 * Math.sin(z * 86 + y * 64 + 0.7) * Math.sin(x * 130 + z * 41 + 1.4);
    const mott2 = 0.5 + 0.5 * Math.sin(z * 190 + y * 148 + x * 72);
    const wear = 0.5 + 0.5 * Math.sin(z * 210 + x * 90 + y * 140);
    const isBevel = m < 0.996;
    const up = Math.max(0, rn.getY(i));
    let v = isBevel
      ? bevel + wearAmp * wear
      : flat + mottAmp * (0.16 * mott + 0.06 * mott2);
    /* c28: sun-facing AND camera-flank flats were the ADS aluminum slab.
     * pow(up,0.40) still floors crown-tilted stipple (ny~0.3), not just +Y. */
    const side = Math.abs(rn.getX(i));
    v *= 1 - 0.70 * (up > 0 ? up ** 0.40 : 0) - 0.40 * side;
    v = Math.max(0.12, v);
    rc[i * 3] = v;
    rc[i * 3 + 1] = v * 0.995;
    rc[i * 3 + 2] = v * 0.990;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(rc, 3));
  return geo;
}

function markMatteSteel(geo, v = 0.24) {
  const p = geo.attributes.position;
  const c = new Float32Array(p.count * 3);
  for (let i = 0; i < p.count; i++) {
    c[i * 3] = v;
    c[i * 3 + 1] = v;
    c[i * 3 + 2] = v;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(c, 3));
  return geo;
}

function shadeLeather(geo) {
  /* c28: uniform tan/olive. The old hemi + high-freq fold sine painted
   * cream knuckles / chocolate gaps (striped taffy). Form is gap AO only.
   * c32: downward faces were the sage-green "pill" hanging under the gun
   * (weapon 847-880,710-760 = 174/172/142). Dim + desat undersides only —
   * finger tops that pass in ads stay the c31 vertex recipe. */
  if (!geo.attributes.normal) geo.computeVertexNormals();
  const n = geo.attributes.normal;
  const c = new Float32Array(n.count * 3);
  for (let i = 0; i < n.count; i++) {
    const ny = n.getY(i);
    const nx = n.getX(i);
    const ao = 1 - 0.07 * Math.max(0, -ny) - 0.03 * Math.max(0, 0.22 - Math.abs(nx));
    const v = THREE.MathUtils.clamp(ao, 0.90, 0.96);
    const under = THREE.MathUtils.clamp(-ny, 0, 1);
    const dim = 1 - 0.34 * under;
    c[i * 3] = v * dim;
    c[i * 3 + 1] = v * (0.97 - 0.14 * under) * dim;
    c[i * 3 + 2] = v * (0.84 - 0.06 * under) * dim;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(c, 3));
  return geo;
}

function shadeCloth(geo) {
  if (!geo.attributes.normal) geo.computeVertexNormals();
  const p = geo.attributes.position;
  const n = geo.attributes.normal;
  const c = new Float32Array(p.count * 3);
  for (let i = 0; i < p.count; i++) {
    const y = p.getY(i), z = p.getZ(i);
    /* Soft value drift only — high-freq rings + v=0.98 were the cream
     * Michelin rims. Folds are shading, not lit geometry. */
    const fold = 0.5 + 0.5 * Math.sin(y * 14 + z * 9 + 0.6) * Math.sin(z * 6 + 1.1);
    const hemi = 0.70 + 0.30 * (n.getY(i) * 0.28 + 0.72);
    /* c32: G>R + high floor was the sage cuff/sleeve pill (weapon ~140/136/101,
     * shotgun mittSleeve). Keep 0x2e3024 olive, drop the green lift. */
    const v = THREE.MathUtils.clamp(hemi * (0.70 + 0.12 * fold), 0.36, 0.50);
    c[i * 3] = v * 0.74;
    c[i * 3 + 1] = v * 0.70;
    c[i * 3 + 2] = v * 0.52;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(c, 3));
  return geo;
}

function lathe(pts, segs, mat, name) {
  _v2.length = 0;
  for (let i = 0; i < pts.length; i += 2) _v2.push(new THREE.Vector2(pts[i], pts[i + 1]));
  return mesh(smooth(new THREE.LatheGeometry(_v2, segs), false), mat, name);
}

/* Lathed wood part with the axis on Z and UVs remapped so uv.x runs ALONG
 * the part: the bake's grain streaks then run down the length instead of
 * wrapping into cross-cut laminate rings (fix 2). sx/sy squash the section
 * into an ellipse (handguards are wider than tall). */
function woodSpindle(prof, segs, mat, name, sx = 1, sy = 1) {
  _v2.length = 0;
  for (let i = 0; i < prof.length; i += 2) _v2.push(new THREE.Vector2(prof[i], prof[i + 1]));
  let geo = new THREE.LatheGeometry(_v2, segs);
  const uv = geo.attributes.uv;
  for (let i = 0; i < uv.count; i++) {
    const u = uv.getX(i);
    const v = uv.getY(i);
    uv.setXY(i, v * 1.35, u * 0.85);
  }
  uv.needsUpdate = true;
  geo.rotateX(-Math.PI / 2);
  geo.scale(sx, sy, 1);
  geo = weldByAngle(geo, 44);
  ensureUV2(geo);
  return mesh(geo, mat, name);
}

/* Wood grain vertex tint (c22 fix 6): laminate bands run ALONG the part
 * (its long axis is local Z for spindles and extrudeZY parts), so the
 * value varies ACROSS the section — y bands with a slow z wobble — the way
 * AK laminate reads. Multiplies the bake so pores survive. Blue dips
 * hardest: dark streaks go umber, never grey. */
function addGrain(geo, kAcross = 90, amp = 0.55, across = 'y', range = [0.70, 1.22]) {
  const pos = geo.attributes.position;
  const col = new Float32Array(pos.count * 3);
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i);
    const y = pos.getY(i);
    const z = pos.getZ(i);
    const a = across === 'x' ? x : across === 'z' ? z : y;
    const along = across === 'x' ? z : across === 'z' ? x : z;
    const s1 = Math.sin(a * kAcross + Math.sin(along * 23 + 1.1) * 1.9 + (across === 'x' ? y : x) * 34);
    const s2 = Math.sin(a * kAcross * 2.6 + along * 55 + 0.7);
    const s3 = Math.sin(a * kAcross * 0.45 + along * 9.0 + 0.3);
    const band = 0.55 * s1 + 0.25 * s2 + 0.20 * s3;
    /* Milder than c23: the bake now carries grain. High amp + Y-displace
     * on spindles painted tiger-stripe rings (Y is circumferential after
     * woodSpindle's rotateX). */
    const v = THREE.MathUtils.clamp(1 + amp * band, range[0], range[1]);
    col[i * 3] = v;
    col[i * 3 + 1] = v * 0.96;
    col[i * 3 + 2] = v * 0.88;
    const d = band * 0.00035;
    if (across === 'x') pos.setX(i, x + d);
    else if (across === 'z') pos.setZ(i, z + d);
    else pos.setY(i, y + d);
  }
  pos.needsUpdate = true;
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  if (geo.attributes.normal) geo.computeVertexNormals();
  return geo;
}

function tube(curve, tubular, radius, radial, mat, name, closed = false) {
  return mesh(smooth(new THREE.TubeGeometry(curve, tubular, radius, radial, closed), false), mat, name);
}

function hookLumCap(shader, cap, opts = {}) {
  const sat = opts.sat == null ? 1 : opts.sat;
  const cool = opts.cool ? 1 : 0;
  const inj = `float _capLum = dot(outgoingLight, vec3(0.2126, 0.7152, 0.0722));
	outgoingLight *= min(1.0, ${cap.toFixed(3)} / max(_capLum, 1e-4));
	float _capLum2 = dot(outgoingLight, vec3(0.2126, 0.7152, 0.0722));
	outgoingLight = mix(vec3(_capLum2), outgoingLight, ${sat.toFixed(3)});
	${cool ? 'outgoingLight *= vec3(0.86, 0.90, 1.00);' : ''}
	`;
  if (shader.fragmentShader.includes('_capLum2')) return;
  if (shader.fragmentShader.includes('#include <opaque_fragment>')) {
    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <opaque_fragment>',
      `${inj}#include <opaque_fragment>`,
    );
  } else if (shader.fragmentShader.includes('gl_FragColor = vec4( outgoingLight')) {
    shader.fragmentShader = shader.fragmentShader.replace(
      'gl_FragColor = vec4( outgoingLight, diffuseColor.a );',
      `${inj}gl_FragColor = vec4( outgoingLight, diffuseColor.a );`,
    );
  } else {
    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <output_fragment>',
      `${inj}#include <output_fragment>`,
    );
  }
}

function hookSteelVC(mat, key, roughK = 2.15, cap = 0.115, capOpts = {}) {
  const baseObc = mat.onBeforeCompile;
  mat.onBeforeCompile = (shader) => {
    if (baseObc) baseObc(shader);
    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <roughnessmap_fragment>',
      `#include <roughnessmap_fragment>
	roughnessFactor = max(roughnessFactor, 0.90);
	roughnessFactor = min(1.0, roughnessFactor + (1.0 - vColor.r) * ${roughK.toFixed(2)});`,
    );
    shader.fragmentShader = shader.fragmentShader.replace(
      'mapN.xy *= normalScale;',
      'mapN.xy *= normalScale * mix(0.06, 0.42, smoothstep(0.28, 0.80, vColor.r));',
    );
    /* c28: ACES+exposure 2.26 still blew sun-flats to 250 after roughness
     * 1.0. Cap linear luminance so gun-owned ADS flats stay <= ~150. */
    hookLumCap(shader, cap, capOpts);
  };
  mat.customProgramCacheKey = () => key;
  return mat;
}

function hookMatteCap(mat, key, cap = 0.145, opts = {}) {
  const baseObc = mat.onBeforeCompile;
  mat.onBeforeCompile = (shader) => {
    if (baseObc) baseObc(shader);
    hookLumCap(shader, cap, opts);
  };
  mat.customProgramCacheKey = () => key;
  return mat;
}

function cloneHooked(mat, suffix = 'inst') {
  /* Material.clone() drops onBeforeCompile / customProgramCacheKey.
   * steelvc roughness+normalScale and vm depth-squash MUST come back. */
  const m2 = mat.clone();
  m2.onBeforeCompile = mat.onBeforeCompile;
  if (mat.customProgramCacheKey) {
    const key = mat.customProgramCacheKey();
    m2.customProgramCacheKey = () => `${key}-${suffix}`;
  }
  return m2;
}

function instanced(geo, mat, poses, name) {
  ensureUV2(geo);
  /* Material.clone() does NOT carry onBeforeCompile/customProgramCacheKey,
   * so instanced clones lost the vm depth squash and were depth-culled
   * behind the squashed receiver — THIS is why the c19 "16 rivets" never
   * survived a zoom: they were never on screen. Re-attach both. */
  const m2 = cloneHooked(mat, 'inst');
  const im = new THREE.InstancedMesh(geo, m2, poses.length);
  im.name = name;
  im.castShadow = false;
  im.frustumCulled = false;
  for (let i = 0; i < poses.length; i++) {
    const p = poses[i];
    DUMMY.position.set(p[0], p[1], p[2]);
    DUMMY.rotation.set(p[3] || 0, p[4] || 0, p[5] || 0);
    DUMMY.scale.set(p[6] ?? 1, p[7] ?? 1, p[8] ?? 1);
    DUMMY.updateMatrix();
    im.setMatrixAt(i, DUMMY.matrix);
  }
  im.instanceMatrix.needsUpdate = true;
  return im;
}

function vmDepthSquash(shader) {
  shader.vertexShader = shader.vertexShader.replace(
    '#include <project_vertex>',
    `#include <project_vertex>
	gl_Position.z = gl_Position.z * 0.12 - 0.88 * gl_Position.w;
`,
  );
}

function pbr(maps, color, metal, rough, extras = {}) {
  const tagged = extras.tag || 'pbr';
  const Ctor = extras.coat ? THREE.MeshPhysicalMaterial : THREE.MeshStandardMaterial;
  const mat = new Ctor({
    color,
    metalness: metal,
    roughness: maps?.ormMap ? 1 : rough,
    envMapIntensity: extras.env ?? 0.85,
    fog: false,
    ...(extras.coat ? { clearcoat: extras.coat, clearcoatRoughness: extras.coatR ?? 0.22 } : {}),
  });
  if (extras.vc) mat.vertexColors = true;
  if (maps) {
    if (maps.map) mat.map = maps.map;
    if (maps.normalMap) {
      mat.normalMap = maps.normalMap;
      mat.normalScale = new THREE.Vector2(extras.nrm ?? 0.95, extras.nrm ?? 0.95);
    }
    if (maps.ormMap) {
      mat.aoMap = maps.ormMap;
      mat.roughnessMap = maps.ormMap;
      mat.aoMapIntensity = extras.aoInt ?? 1.0;
      /* Roughness floor: the bake's glossy dips (0.44-0.52) are what spike
       * point-light speculars into 200+ streaks; a >1 multiplier lifts the
       * whole curve without flattening its variation. */
      mat.roughness = extras.roughMul ?? 1;
    }
  }
  mat.onBeforeCompile = (shader) => { vmDepthSquash(shader); };
  const key = `ak-vm-${tagged}-${maps?.map ? 'm' : 'x'}`;
  mat.customProgramCacheKey = () => key;
  mat.needsUpdate = true;
  return mat;
}

function vmMats(mats) {
  const maps = mats._maps || {};
  const woodMap = maps.akwood || maps.wood;
  const gunMap = maps.gunmetal || maps.metal;
  /* Amber laminate. Clearcoat cut to zero (fix 2, c20): coat 0.30 + the 2.3
   * warm fill turned the whole lower handguard into the "polished brass
   * tube" — the brightest speculars on the gun (223/212/186) were the coat
   * lobe, not the barrel steel. Matte oiled wood instead. */
  const wood = pbr(woodMap, 0x8d6f52, 0.02, 0.62, { env: 0.28, tag: 'wood', nrm: 1.45, aoInt: 0.22, roughMul: 1.50 });
  /* Low coat/env on the stock: sky bounce over the warm wood was tinting
   * the whole buttstock purple-grey in c15w1. Darker matte amber (fix 3,
   * c18): the 0x6e5834 tint under the top dir light hit ~#816235 metallic
   * gold on the stock comb; darker + rougher stays end-grain wood. */
  const woodDark = pbr(woodMap, 0x64502c, 0.02, 0.70, { env: 0.05, tag: 'woodD', coat: 0.0, coatR: 0.30, nrm: 0.85, aoInt: 0.24, roughMul: 1.3 });
  /* Matte end-grain wood for the stock socket wedge and upper handguard.
   * Green channel raised toward neutral (fix 10): the old red-lead tint
   * read as a faint magenta sheen at the barrel junction. */
  const woodEnd = pbr(woodMap, 0x6e5738, 0.02, 0.78, { env: 0.12, tag: 'wend', nrm: 0.8, aoInt: 0.30, roughMul: 1.4 });
  /* c22 grained wood set (fix 5/6): vertex-color streaks (addGrain) run
   * along each part, so stock/handguards stop reading as flat brown slabs.
   * The upper handguard gets its own DULL variant — its smooth spindle
   * caught the key light in a 220-RGB streak (the c22 "chrome bevel"
   * measurement landed on THIS part, not the receiver): much rougher, near
   * zero env, so the wood tops out as lit timber, not polish. */
  const woodGrain = pbr(woodMap, 0x7a6550, 0.02, 0.72, { env: 0.08, tag: 'wgrain', nrm: 1.70, aoInt: 0.24, roughMul: 1.75, vc: true });
  const woodGrainD = pbr(woodMap, 0x5a4830, 0.02, 0.78, { env: 0.04, tag: 'wgrainD', nrm: 1.20, aoInt: 0.26, roughMul: 1.50, vc: true });
  /* c32: wood-map * 0x6a5434 * warm vm fill was the flesh-pink wrap lump
   * at the hand/barrel junction (ads 830-865,552-590 peak 211/197/180 on
   * handguardUpper). Map-free dark leather, same recipe as the c31 pump. */
  const woodUpper = pbr(null, 0x463728, 0.00, 0.97, { env: 0.0, tag: 'wup', vc: true });
  hookMatteCap(woodUpper, 'ak-vm-wup-cap1', 0.078, { sat: 0.40 });
  const bakelite = pbr(maps.polymer, 0x2a1e14, 0.04, 0.62, { env: 0.14, tag: 'bake' });
  const grip = pbr(maps.polymer, 0x16100a, 0.03, 0.66, { env: 0.08, tag: 'grip' });

  /* GUNMETAL, c20. The c15-c19 oscillation (black -> slate -> khaki) had
   * one root cause: metals were lit as DIELECTRICS. High metalness + the
   * old black-cube envMap rendered black (metal only shows its reflected
   * environment); dropping metalness to 0.2 handed the tone to the warm vm
   * lights, whose 2.3-intensity 0xe8d4b0 fill x a warm 0xd4c6b2 tint =
   * khaki (measured 102/74/41 on the c19 flats). Fix is BOTH halves:
   * a dim NEUTRAL-GREY gradient PMREM (mats._vmEnv) as the reflection
   * source, metalness back to 0.7-0.85, near-neutral dark grey tints, and
   * neutralized vm light colors so the residual diffuse can't tint. */
  /* Metal F0 lives in the BAKE (0.155-0.33 linear): tints must stay near
   * white or the product renders as soot — real steel reflectance is ~0.5
   * linear, so a 0.24-linear tint x the bake gave 0.05 F0 = black (the
   * exact c20a failure). Bright neutral tints, darkness from the bake. */
  const darkMetal = pbr(gunMap, 0xd4d2ce, 0.80, 0.52, { env: 0.85, tag: 'steel', roughMul: 1.32, nrm: 0.70 });
  /* Same steel with vertex colors on: the receiver marks its bevel/chamfer
   * verts (c22 fix 2) — flats stay at 1.0 so the calibrated 51/49/44 base
   * gunmetal is untouched. Albedo darkening alone CANNOT clamp the bevel
   * streak: at metalness 0.80 a fifth of the lobe is dielectric F0 that
   * ignores color, and its HDR peak clips white through ACES (a full-mesh
   * vc=0.2 debug still measured 216). So the vertex color also DRIVES
   * ROUGHNESS in the shader — bevels go near-matte and the lobe spreads
   * instead of clipping. c27: nrm 3.60→0.90 (~4x cut) — the c26 1.75x
   * stamp read as granite-bark on the lower receiver. */
  const darkMetalVC = pbr(gunMap, 0xd4d2ce, 0.62, 0.58, { env: 0.06, tag: 'steelvc', roughMul: 2.05, vc: true, nrm: 0.18 });
  hookSteelVC(darkMetalVC, 'ak-vm-steelvc-rn4', 2.80);
  const worn = pbr(gunMap, 0xc2c4c6, 0.74, 0.50, { env: 0.85, tag: 'worn' });
  const edge = pbr(gunMap, 0x9a9894, 0.55, 0.72, { env: 0.28, tag: 'edge', nrm: 0.6 });
  /* Rivet heads (c22 fix 2): `edge` domes clipped at 217 — the brightest
   * px in the receiver rect after the bevel fix. Dimmer tint + rougher
   * lobe keeps the lit-cap-over-shaded-underside read below the 150 bar. */
  const rivet = pbr(gunMap, 0x7a7874, 0.32, 0.84, { env: 0.10, tag: 'rivet', roughMul: 1.65, nrm: 0.35 });
  const cavity = pbr(maps.metal, 0x0c0c0c, 0.30, 0.80, { env: 0.10, tag: 'cav' });
  /* c32: shotgun-only cavity. Shared 0x0c0c0c crushed the receiver insets
   * to ~23/19/13. Cool desat gunmetal in the c31 tube family (lum ~50-75). */
  const sgCavity = pbr(null, 0x2c2e32, 0.10, 0.96, { env: 0.0, tag: 'sgcav' });
  hookMatteCap(sgCavity, 'ak-vm-sgcav-cap1', 0.058, { sat: 0.20, cool: true });
  /* Dust cover: same family as the receiver, a half-step darker. */
  const blueSteel = pbr(gunMap, 0xb6b4b0, 0.78, 0.55, { env: 0.70, tag: 'blue', roughMul: 1.25 });
  /* Barrel/gas tube (fix 2): matte parkerized steel. No ormMap so the
   * roughness FLOOR is authored here (0.62) — the bake's 0.44 glossy dips
   * were the long specular streak on the c19 barrel cylinder. */
  const barrelMaps = gunMap ? { map: gunMap.map, normalMap: gunMap.normalMap } : null;
  /* c20 final: rough 0.66->0.75, env 0.30->0.22 — the 0.66 tube still peaked
   * at RGB 188 under the key light (limit 150). */
  /* c30: bake albedo + 0x3a3c40 was the pale ~150 barrel/front-sight.
   * Map-free dark steel like the shotgun barrel, tighter lum cap. */
  const barrelPark = pbr(null, 0x24262a, 0.08, 0.97, { env: 0.0, tag: 'bpark' });
  hookMatteCap(barrelPark, 'ak-vm-bpark-cap5', 0.070, { sat: 0.08, cool: true });
  const tubePark = pbr(null, 0x26282c, 0.10, 0.97, { env: 0.0, tag: 'tpark' });
  hookMatteCap(tubePark, 'ak-vm-tpark-cap2', 0.080, { sat: 0.28, cool: true });
  /* AKM bakelite mag (fix 4): muted brown bakelite with a slight resin
   * sheen. c22: the c21 flank measured 133/80/32 — still traffic-cone.
   * Ramp retuned toward ~120/85/55 (see buildAK) and roughness dropped a
   * step so the resin catches a soft sheen instead of staying dead flat. */
  const magBake = pbr(maps.bakelite || maps.polymer, 0xffffff, 0.02, 0.78, {
    env: 0.04, tag: 'bmag', vc: true, nrm: 0.55, aoInt: 0.38, roughMul: 1.55,
  });
  /* Mild cap: keep the amber gradient, clip the cream toe (240 → ~200). */
  hookMatteCap(magBake, 'ak-vm-bmag-cap', 0.200);
  /* Rib ridges a step LIGHTER than the flank so the raised geometry catches
   * light (c22 fix 3): the old 0x9a6236 blended into the body and only the
   * black shadow grooves showed — "painted dashes". */
  const magRib = pbr(maps.bakelite || maps.polymer, 0x6a4e28, 0.00, 0.96, {
    env: 0.0, tag: 'brib', nrm: 0.06, aoInt: 0.40, roughMul: 2.10, vc: true,
  });
  hookMatteCap(magRib, 'ak-vm-brib-cap', 0.095);
  /* c31: the amber side-saddle loops (0x8a6238 + polymer map, NO cap) were
   * the "copper mag tube with blown 246 streak" in every shotgun frame —
   * ID-render pinned the critic rect to sgShells, not the (already fixed)
   * sgTube. Same cool dark gunmetal recipe as the c30 hook. */
  const shellAmber = pbr(null, 0x26282c, 0.12, 0.96, { env: 0.0, tag: 'shell' });
  hookMatteCap(shellAmber, 'ak-vm-shell-cap1', 0.070, { sat: 0.08, cool: true });
  const magDark = pbr(gunMap, 0xb2b0ae, 0.62, 0.60, { env: 0.60, tag: 'magD' });
  /* Muzzle group: matte parkerized grey, same no-orm floor as the barrel. */
  /* c20 final: the rear-sight base front facet glinted at RGB 222 — same
   * fix as the barrel, higher floor + less env. */
  const park = pbr(barrelMaps, 0x5a5c60, 0.70, 0.74, { env: 0.24, tag: 'park', nrm: 0.8 });

  /* c28: one matte tan/olive — no map albedo/nrm (those swapped segments)
   * and no second pad tint. Roughness authored, not orm-dipped. */
  const glove = pbr(null, 0x454238, 0.00, 0.96, { env: 0.0, tag: 'glove', vc: true });
  hookMatteCap(glove, 'ak-vm-glove-cap2', 0.128);
  const glovePad = glove;
  const plate = pbr(maps.polymer, 0x3a3c38, 0.16, 0.58, { env: 0.20, tag: 'plate' });
  /* Sleeve: matte olive cloth, vertex folds only. Fabric twill/normal was
   * the diamond-weave basket on the forearm (c26 ads-hand). */
  const cloth = pbr(null, 0x2e3024, 0.00, 0.97, { env: 0.0, tag: 'cloth', vc: true });
  hookMatteCap(cloth, 'ak-vm-cloth-cap1', 0.068, { sat: 0.32 });
  /* Shotgun pump: matte walnut ~98/75/41. No wood-map albedo (that + warm
   * vm fill read as glossy orange plastic). Grain is vertex-only. */
  /* Cooler walnut — 0x7a4e1c + warm vm fill read blaze-orange / copper. */
  const woodMatte = pbr(null, 0x4a3018, 0.00, 0.99, { env: 0.0, tag: 'wmatte', vc: true });
  hookMatteCap(woodMatte, 'ak-vm-wmatte-cap5', 0.070, { sat: 0.38 });
  /* Shotgun barrel: dark gunmetal. Warm vm fill was painting it blaze-orange
   * (probe (810,590) = sgBarrel 144/70/22) — desaturate + cool after cap. */
  const sgBarrel = pbr(null, 0x24262a, 0.08, 0.98, { env: 0.0, tag: 'sgbar' });
  hookMatteCap(sgBarrel, 'ak-vm-sgbar-cap3', 0.070, { sat: 0.08, cool: true });
  /* Shotgun receiver: lifted out of soot, roughness floor, almost no nrm
   * so the stamped bake cannot sparkle as a white starfield. */
  const sgSteel = pbr(gunMap, 0xc8c6c2, 0.18, 0.94, { env: 0.0, tag: 'sgsteel', roughMul: 2.40, vc: true, nrm: 0.08 });
  /* c31: the cap alone let the warm key tint the receiver flats (top plane
   * read 82/67/47, r-b ≈ 30 — residue of the c30 "copper" family). Same
   * cool desaturate the barrel/tube already use. */
  hookSteelVC(sgSteel, 'ak-vm-sgsteel-rn6', 3.10, 0.092, { sat: 0.22, cool: true });
  /* Scope glass: near-black, low-rough, high env — same read as the enemy
   * visor. Only new material the expansion adds to the vm set. */
  const lens = pbr(null, 0x0a0e14, 0.40, 0.22, { env: 1.30, tag: 'lens' });

  const out = {
    wood, woodDark, woodEnd, woodGrain, woodGrainD, woodUpper, woodMatte, bakelite, grip,
    darkMetal, darkMetalVC, worn, edge, rivet, cavity, sgCavity, blueSteel, barrelPark, tubePark, sgBarrel, sgSteel, magBake, magRib, magDark, park, shellAmber,
    glove, glovePad, plate, cloth, lens,
  };
  /* Explicit per-material envMap (neutral grey studio PMREM baked in
   * materials.js). Without it, three r183 drives envMapIntensity from
   * scene.environmentIntensity only and the warm sky env leaks onto every
   * vm top face at grazing Fresnel. With it, each env value above is real
   * and the reflection source is guaranteed neutral. */
  if (mats._vmEnv) {
    for (const m of Object.values(out)) {
      m.envMap = mats._vmEnv;
      m.needsUpdate = true;
    }
  }
  return out;
}

function receiverHull() {
  const s = new THREE.Shape();
  /* Stamped sheet: extra loops + a shallow crown so the long top is not
   * a CAD-straight N-gon. Rear wedge stays a real chamfer. */
  s.moveTo(-0.122, 0.000);
  s.lineTo(-0.122, 0.016);
  s.lineTo(-0.122, 0.032);
  s.lineTo(-0.121, 0.044);
  s.quadraticCurveTo(-0.118, 0.051, -0.108, 0.053);
  s.lineTo(-0.052, 0.0542);
  s.lineTo(0.012, 0.0546);
  s.lineTo(0.072, 0.0538);
  s.quadraticCurveTo(0.086, 0.052, 0.089, 0.046);
  s.lineTo(0.090, 0.026);
  s.lineTo(0.090, 0.008);
  s.quadraticCurveTo(0.088, 0.001, 0.078, -0.001);
  s.lineTo(0.058, -0.002);
  s.lineTo(0.042, -0.002);
  s.quadraticCurveTo(0.036, -0.010, 0.032, -0.014);
  s.lineTo(0.010, -0.014);
  s.lineTo(-0.012, -0.014);
  s.quadraticCurveTo(-0.018, -0.008, -0.020, 0.000);
  s.lineTo(-0.070, 0.000);
  s.lineTo(-0.122, 0.000);
  s.closePath();
  return s;
}

function dustCoverHull() {
  const s = new THREE.Shape();
  /* Rolled rear lip + slight top crown — breaks the ruler-straight cover. */
  s.moveTo(-0.098, 0.050);
  s.quadraticCurveTo(-0.100, 0.058, -0.094, 0.065);
  s.lineTo(-0.040, 0.0662);
  s.lineTo(0.020, 0.0666);
  s.lineTo(0.052, 0.0658);
  s.quadraticCurveTo(0.074, 0.064, 0.082, 0.056);
  s.quadraticCurveTo(0.080, 0.050, 0.070, 0.0495);
  s.closePath();
  return s;
}

function coverRibShape() {
  const s = new THREE.Shape();
  s.moveTo(-0.0058, 0.0615);
  s.quadraticCurveTo(-0.0058, 0.0674, 0.000, 0.0676);
  s.quadraticCurveTo(0.0058, 0.0674, 0.0058, 0.0615);
  s.closePath();
  return s;
}

function stockHull() {
  /* Comb dips behind the socket then rises to a small heel at the buttplate;
   * toe drops slightly — an AK stock profile, not a plank (fix 9). */
  const s = new THREE.Shape();
  s.moveTo(0.086, 0.002);
  s.lineTo(0.086, 0.042);
  s.quadraticCurveTo(0.130, 0.028, 0.176, 0.030);
  s.lineTo(0.196, 0.024);
  s.lineTo(0.198, -0.010);
  s.lineTo(0.188, -0.018);
  s.lineTo(0.086, -0.002);
  s.closePath();
  return s;
}

function gripHull() {
  const s = new THREE.Shape();
  s.moveTo(0.046, -0.002);
  s.lineTo(0.074, -0.002);
  s.lineTo(0.108, -0.078);
  s.quadraticCurveTo(0.104, -0.118, 0.074, -0.114);
  s.quadraticCurveTo(0.046, -0.098, 0.038, -0.056);
  s.quadraticCurveTo(0.036, -0.018, 0.046, -0.002);
  return s;
}

/* Banana magazine in the (z, y) side plane: both long edges sweep FORWARD
 * (-z) as they drop so the silhouette is a curved crescent (fix 2, c18).
 * Shorter and tucked INTO the receiver at the top: the c17 hull hung so
 * deep that in ADS two giant flank sheets filled the lower third, and the
 * proud magRidge crescent read as a second hollow shell. One closed solid
 * now; the top edge (+0.012) hides inside the mag well. */
function magHull() {
  const s = new THREE.Shape();
  s.moveTo(-0.024, 0.012);
  s.lineTo(0.030, 0.012);
  // Rear (convex) edge: bows back before diving forward.
  s.bezierCurveTo(0.042, -0.048, 0.012, -0.104, -0.036, -0.142);
  // Floorplate.
  s.lineTo(-0.070, -0.112);
  // Front (concave) edge back up to the mag well.
  s.bezierCurveTo(-0.050, -0.078, -0.036, -0.036, -0.024, 0.012);
  s.closePath();
  return s;
}

function triggerHull() {
  const s = new THREE.Shape();
  s.moveTo(-0.002, 0.008);
  s.lineTo(0.003, 0.008);
  s.lineTo(0.004, -0.004);
  s.quadraticCurveTo(0.008, -0.014, 0.002, -0.018);
  s.lineTo(-0.003, -0.010);
  s.quadraticCurveTo(0.0, -0.006, -0.002, 0.000);
  s.closePath();
  return s;
}

/* AKM slant brake: a plain cylinder whose front face is cut at ~55 deg so
 * the top edge reaches further forward than the bottom (fix 7). Replaces
 * the c15 bulged lathe that welded into a polished brass ball. Cut is
 * applied AFTER rotating the axis onto Z, in final gun coordinates. */
function slantBrakeGeo(r = 0.0122, len = 0.044, slope = 1.25) {
  const g = new THREE.CylinderGeometry(r, r * 1.08, len, 20, 5, false);
  g.rotateX(Math.PI / 2);
  const pos = g.attributes.position;
  const zFront = -len * 0.5;
  for (let i = 0; i < pos.count; i++) {
    const y = pos.getY(i);
    const zCut = zFront + (r - y) * slope * 0.5;
    if (pos.getZ(i) < zCut) pos.setZ(i, zCut);
  }
  pos.needsUpdate = true;
  return crisp(g, 12);
}

function mittGeo(side) {
  const parts = [];
  const palm = new THREE.SphereGeometry(0.013, 12, 10);
  palm.scale(1.05, 0.62, 1.35);
  palm.translate(0.001 * side, 0.001, -0.004);
  parts.push(palm);

  const mound = new THREE.SphereGeometry(0.0085, 10, 8);
  mound.scale(1.10, 0.52, 0.88);
  mound.translate(0.002 * side, 0.006, -0.010);
  parts.push(mound);

  /* Four gapped capsule fingers — 2 bones + knuckle + tip each. */
  for (let i = 0; i < 4; i++) {
    const z = -0.010 - i * 0.0084;
    const r = 0.0044 - i * 0.00026;
    const bone = new THREE.CylinderGeometry(r, r * 0.90, 0.013, 10);
    bone.rotateX(Math.PI / 2 + 0.42);
    bone.translate(0.001 * side, 0.003, z);
    parts.push(bone);
    const kn = new THREE.SphereGeometry(r * 1.16, 8, 6);
    kn.translate(0.001 * side, 0.007, z - 0.005);
    parts.push(kn);
    const bone2 = new THREE.CylinderGeometry(r * 0.90, r * 0.78, 0.010, 10);
    bone2.rotateX(Math.PI / 2 + 0.72);
    bone2.translate(0.001 * side, 0.008, z - 0.011);
    parts.push(bone2);
    const cap = new THREE.SphereGeometry(r * 0.95, 8, 6);
    cap.translate(0.001 * side, 0.011, z - 0.016);
    parts.push(cap);
  }

  const thumb = new THREE.CylinderGeometry(0.0046, 0.0040, 0.016, 10);
  thumb.rotateY(0.72 * side);
  thumb.rotateX(0.55);
  thumb.translate(-0.012 * side, 0.004, -0.002);
  parts.push(thumb);
  const thTip = new THREE.SphereGeometry(0.0044, 8, 6);
  thTip.translate(-0.016 * side, 0.008, -0.008);
  parts.push(thTip);

  const wrist = new THREE.SphereGeometry(0.0078, 10, 8);
  wrist.scale(0.90, 0.56, 1.00);
  wrist.translate(0.001 * side, -0.002, 0.014);
  parts.push(wrist);

  const merged = mergeGeometries(parts, false);
  for (const g of parts) g.dispose();
  let g = merged;
  try { g = mergeVertices(merged, 0.0016); } catch { /* keep */ }
  g.computeVertexNormals();
  shadeLeather(g);
  return ensureUV2(g);
}

function buildMitt(vm, side) {
  const g = new THREE.Group();
  g.name = side > 0 ? 'rightHand' : 'leftHand';
  g.add(mesh(mittGeo(side), vm.glove, 'mitt'));
  /* Short olive cuff so the mitt never ends as a cream wedge. */
  const cuffGeo = smooth(new THREE.CylinderGeometry(0.0108, 0.0136, 0.036, 18), false);
  shadeCloth(cuffGeo);
  const cuff = mesh(cuffGeo, vm.cloth, 'mittSleeve');
  put(cuff, 0.001 * side, -0.003, 0.026, 0.62, 0, 0.08 * side);
  g.add(cuff);
  return g;
}

/* Left support hand (fix 1, c18). The c17 build was separate meshes —
 * palm/cuff/fingers — hovering below-left of the guard with background
 * showing between every part. This one is a SINGLE merged geometry whose
 * palm slab penetrates the handguard underside, fingers are tori around
 * the actual guard axis wrapping over the top, and a thick forearm runs
 * from the palm back toward the player so the wrist never ends in air. */
/* Ellipse around the lower handguard section: guard is ~0.021 half-wide x
 * ~0.015 half-tall centered on (0, 0.022). Fingers ride just outside it. */
const HAND_CX = 0;
const HAND_CY = 0.022;
const HAND_A = 0.0268;
const HAND_B = 0.0212;
function guardPoint(theta, z, out) {
  out.set(HAND_CX + HAND_A * Math.cos(theta), HAND_CY + HAND_B * Math.sin(theta), z);
  return out;
}

/* c27 REBUILD: TubeGeometry wrapping 246° read as two banana-peel strips
 * and the 0.128 sleeve was a pale-green basket. Four SEPARATE 3-bone
 * capsule chains wrap the top/side of the guard with visible gaps; palm
 * sits under the handguard; thumb on the camera-near flank. */
const FINGER_Z = [-0.126, -0.150, -0.174, -0.198];
function guardOn(theta, z, out, pad) {
  out.set(
    HAND_CX + (HAND_A + pad) * Math.cos(theta),
    HAND_CY + (HAND_B + pad) * Math.sin(theta),
    z,
  );
  return out;
}
function supportHandGeo() {
  const parts = [];
  const p0 = new THREE.Vector3();
  const p1 = new THREE.Vector3();
  const p2 = new THREE.Vector3();
  const mid = new THREE.Vector3();
  const dir = new THREE.Vector3();
  const up = new THREE.Vector3(0, 1, 0);
  const q = new THREE.Quaternion();
  const mtx = new THREE.Matrix4();
  const one = new THREE.Vector3(1, 1, 1);
  const seg = (a, b, r0, r1 = r0, radial = 12) => {
    dir.copy(b).sub(a);
    const len = dir.length();
    if (len < 1e-6) return;
    /* Open-ended — cylinder caps were the glassy wedge at the grip. */
    const g = new THREE.CylinderGeometry(r0, r1, len, radial, 1, true);
    q.setFromUnitVectors(up, dir.multiplyScalar(1 / len));
    mid.copy(a).add(b).multiplyScalar(0.5);
    mtx.compose(mid, q, one);
    g.applyMatrix4(mtx);
    parts.push(g);
  };
  const knot = (a, r, w = 12, h = 10) => {
    const s = new THREE.SphereGeometry(r, w, h);
    s.translate(a.x, a.y, a.z);
    parts.push(s);
  };

  /* Palm mass UNDER + camera-near side of the guard. Less slab squash. */
  const palm = new THREE.SphereGeometry(0.0145, 14, 12);
  palm.scale(1.18, 0.80, 1.38);
  palm.translate(-0.012, 0.002, -0.156);
  parts.push(palm);
  const heel = new THREE.SphereGeometry(0.0110, 12, 10);
  heel.scale(1.08, 0.82, 1.06);
  heel.translate(-0.018, 0.002, -0.136);
  parts.push(heel);
  const back = new THREE.SphereGeometry(0.0105, 12, 10);
  back.scale(0.88, 0.80, 1.28);
  back.translate(-0.022, 0.010, -0.156);
  parts.push(back);
  const wrist = new THREE.SphereGeometry(0.0090, 12, 10);
  wrist.scale(1.02, 0.86, 1.14);
  wrist.translate(-0.010, -0.006, -0.118);
  parts.push(wrist);

  /* Four fat fingers on the CAMERA (-X) flank so a 3x crop reads sausages
   * with gaps, not top-side banana peels. 3 bones + knuckle balls. */
  for (let i = 0; i < FINGER_Z.length; i++) {
    const z = FINGER_Z[i];
    const r = 0.0074 - i * 0.00038;
    const pad = r + 0.0012;
    const root = new THREE.Vector3(-0.014, 0.000, z + 0.002);
    guardOn(2.95, z, p0, pad);
    guardOn(2.15, z, p1, pad);
    guardOn(1.35, z, p2, pad * 0.90);
    knot(root, r * 1.04, 12, 10);
    seg(root, p0, r, r * 0.96, 12);
    knot(p0, r * 1.12, 12, 10);
    seg(p0, p1, r * 0.96, r * 0.90, 12);
    knot(p1, r * 1.08, 12, 10);
    seg(p1, p2, r * 0.90, r * 0.78, 12);
    knot(p2, r * 0.92, 12, 10);
  }

  /* Thumb on the camera-near (-X) flank, two bones + pad. */
  p0.set(-0.018, 0.002, -0.144);
  p1.set(-0.028, 0.014, -0.166);
  p2.set(-0.030, 0.026, -0.184);
  seg(p0, p1, 0.0064, 0.0058, 12);
  knot(p1, 0.0066, 12, 10);
  seg(p1, p2, 0.0058, 0.0050, 12);
  knot(p2, 0.0052, 12, 10);

  const merged = mergeGeometries(parts, false);
  for (const p of parts) p.dispose();
  let g = merged;
  try { g = mergeVertices(merged, 0.0026); } catch { /* keep */ }
  g = weldByAngle(g, 54);
  shadeLeather(g);
  return ensureUV2(g);
}

function buildSupportGlove(vm) {
  const g = new THREE.Group();
  g.name = 'leftHand';
  g.add(mesh(supportHandGeo(), vm.glove, 'supportHand'));
  /* c28: knucklePads + backPad were the grey faceted knuckle blob
   * (wrong pad tint / 8-seg spheres z-fighting the finger knots). */
  /* Short matte olive cuff — a hand is ~10% of hip-frame height, not a
   * forearm-sized tube. No fabric maps (cloth is vertex-fold only). */
  const strapGeo = smooth(new THREE.TorusGeometry(0.0136, 0.0014, 6, 12), false);
  strapGeo.rotateX(Math.PI / 2);
  shadeCloth(strapGeo);
  const strap = mesh(strapGeo, vm.cloth, 'cuffStrap');
  put(strap, -0.014, -0.018, -0.104, 1.72, 0, 0.26);
  g.add(strap);
  const sleeveGeo = smooth(new THREE.CylinderGeometry(0.0128, 0.0154, 0.046, 14), false);
  shadeCloth(sleeveGeo);
  const sleeve = mesh(sleeveGeo, vm.cloth, 'sleeve');
  put(sleeve, -0.016, -0.030, -0.092, 1.72, 0, 0.26);
  g.add(sleeve);
  const cuffRoll = smooth(new THREE.TorusGeometry(0.0142, 0.0015, 6, 12), false);
  cuffRoll.rotateX(Math.PI / 2);
  shadeCloth(cuffRoll);
  const cuff = mesh(cuffRoll, vm.cloth, 'sleeveCuff');
  put(cuff, -0.015, -0.022, -0.100, 1.72, 0, 0.26);
  g.add(cuff);
  return g;
}

/* Shared muzzle flash sprite: sphere + cone in additive warm, scaled per
 * weapon (WEAPONS[id].flash) at build time. One program cache key for all
 * four rigs. */
function makeFlash(scale, x, y, z) {
  const flashMat = new THREE.MeshBasicMaterial({
    color: 0xffc070,
    transparent: true,
    opacity: 0,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
  });
  flashMat.onBeforeCompile = (shader) => { vmDepthSquash(shader); };
  flashMat.customProgramCacheKey = () => 'ak-cs2-flash';
  const flash = mesh(smooth(new THREE.SphereGeometry(0.016, 10, 8), false), flashMat, 'muzzleFlash');
  put(flash, x, y, z);
  const cone = mesh(smooth(new THREE.ConeGeometry(0.022, 0.044, 8), false), flashMat);
  put(cone, 0, 0, -0.016, -Math.PI / 2, 0, 0);
  flash.add(cone);
  flash.scale.setScalar(scale);
  /* Light lives on the viewmodel root (always visible). Parenting it to
   * the gun made NUM_POINT_LIGHTS drop when the sniper hid the viewmodel
   * — a mid-combat shader recompile on every scope-in. */
  return { flash };
}

function buildAK(vm) {
  const metal = vm.darkMetal;
  const worn = vm.worn;
  const edge = vm.edge;
  const hole = vm.cavity;
  const gun = new THREE.Group();
  gun.name = 'ak47';

  /* Soft stamped receiver: chamfer-to-smooth long edges, not a crisp N-gon. */
  const recv = extrudeZYSoft(receiverHull(), 0.034, vm.darkMetalVC, 'receiver', 0.0026);
  recv.geometry = stampFlats(recv.geometry, 0.00012, 'crown');
  markGunmetalVC(recv.geometry, { flat: 0.58, bevel: 0.20, mottAmp: 0.10 });
  gun.add(recv);

  /* Dust cover: ONE smooth stamped panel — crown only, no quilt sines. */
  const cover = extrudeZYSoft(dustCoverHull(), 0.026, vm.darkMetalVC, 'dustCover', 0.0022);
  cover.geometry = stampFlats(cover.geometry, 0.00010, 'crown');
  markGunmetalVC(cover.geometry, { flat: 0.48, bevel: 0.16, mottAmp: 0.06 });
  gun.add(cover);
  /* Inset matte spine — park crown was the white-bead chain. */
  const coverCrown = boxCrisp(0.0236, 0.0018, 0.176, vm.cavity, 'coverCrown');
  put(coverCrown, 0, 0.0676, -0.014);
  gun.add(coverCrown);
  /* AKM mag-well dimple (ARES ref: long concave stiffener above the mag
   * well on the stamped Type-4 receiver): dark inset + thin lower lip. */
  for (const sx of [1, -1]) {
    const dimple = boxCrisp(0.0030, 0.013, 0.058, hole, `magDimple${sx}`);
    put(dimple, sx * 0.0168, 0.010, -0.014);
    gun.add(dimple);
    const dimLip = boxCrisp(0.0018, 0.0022, 0.058, vm.park, `magDimpleLip${sx}`);
    put(dimLip, sx * 0.0172, 0.0028, -0.014);
    gun.add(dimLip);
  }
  /* c27: the three proud cover ribs + stamp panels read as quilted
   * duct-tape squares. One smooth stamped panel; seam groove stays. */
  /* Receiver/cover horizontal seam line where the stamped shell meets the
   * cover — a thin darker groove, not a gold strip. */
  const seam = boxCrisp(0.0346, 0.0018, 0.170, hole, 'recvSeam');
  put(seam, 0, 0.0505, -0.014);
  gun.add(seam);
  /* c19: the long bright edge-wear strips are GONE. They were the repeat
   * "gold band / beige tape" offender — two parallel bright lines riding
   * the receiver top corners straight through the stock-junction rect.
   * Edge definition now comes from the receiver bevel + rivets alone. */

  /* Ejection port rebuilt as RECESSED geometry (fix 3, c20). The c19 port
   * was a painted-black rectangle flush with the flank. Now: the cavity
   * floor sits 4.5 mm INSIDE the receiver, the bolt-carrier face is
   * visible inside it, and a lit inner lip on the lower sill catches the
   * key light so the recess reads as depth, not paint. */
  /* The receiver is a solid extrude spanning x=+-0.017, so the recess is
   * built as LAYERED proud plates: bezel frame outermost (-0.0192), dark
   * cavity floor a millimetre behind it (-0.0179), lit sill and bolt face
   * between. The x-offsets give true parallax and the sill's tilted top
   * face holds a real highlight inside the dark slot. */
  const portCavity = boxCrisp(0.0018, 0.0140, 0.044, hole, 'ejectionPort');
  put(portCavity, -0.0170, 0.033, -0.010);
  gun.add(portCavity);
  /* Bolt-carrier face inside the recess, rear half: brighter steel. */
  const boltFace = boxCrisp(0.0022, 0.0104, 0.020, worn, 'boltFace');
  put(boltFace, -0.0172, 0.0325, 0.001, 0, 0, -0.10);
  gun.add(boltFace);
  /* Lit inner sill along the bottom inside edge, tilted up-camera. */
  const lipIn = boxCrisp(0.0026, 0.0016, 0.040, vm.park, 'portLipInner');
  put(lipIn, -0.0176, 0.0272, -0.010, 0, 0, 0.55);
  gun.add(lipIn);
  /* Proud bezel frame around the opening. */
  const lipT = boxCrisp(0.0022, 0.0026, 0.048, vm.park, 'portLipT');
  put(lipT, -0.0181, 0.0410, -0.010);
  gun.add(lipT);
  const lipB = boxCrisp(0.0022, 0.0026, 0.048, vm.park, 'portLipB');
  put(lipB, -0.0181, 0.0250, -0.010);
  gun.add(lipB);
  const lipR = boxCrisp(0.0022, 0.0142, 0.0028, vm.park, 'portLipR');
  put(lipR, -0.0181, 0.033, 0.0128);
  gun.add(lipR);
  const lipF = boxCrisp(0.0022, 0.0142, 0.0028, vm.park, 'portLipF');
  put(lipF, -0.0181, 0.033, -0.0328);
  gun.add(lipF);
  /* Bolt-carrier channel running REAR from the port (fix 9): recessed dark
   * groove with the carrier rail floating inside it, so the charging
   * handle has a track to live on instead of floating on the flank. */
  const chChannel = boxCrisp(0.0012, 0.0090, 0.054, hole, 'carrierChannel');
  put(chChannel, -0.0174, 0.033, 0.039);
  gun.add(chChannel);
  const chRail = boxCrisp(0.0012, 0.0040, 0.052, worn, 'carrierRail');
  put(chRail, -0.0178, 0.0335, 0.039);
  gun.add(chRail);
  /* Charging handle (fix 9): the c19 cylinder knob read as a cartoon pill.
   * Now a small hooked tab: short shank off the rail + down-swept hook. */
  const chShank = boxCrisp(0.0030, 0.0034, 0.0075, vm.park, 'chargingShank');
  put(chShank, -0.0194, 0.0335, 0.020);
  gun.add(chShank);
  const chHook = boxCrisp(0.0024, 0.0072, 0.0030, vm.park, 'chargingHook');
  put(chHook, -0.0202, 0.0308, 0.0205, 0.18, 0, 0.12);
  gun.add(chHook);
  /* Selector lever slimmed ~40% (fix 9): the giant pivot disc + fat lever
   * was the "3x oversized pill" in the 920-1015 rect. */
  const selPivot = cyl(0.0036, 0.0036, 0.0020, worn, 12, 'selPivot');
  put(selPivot, -0.0180, 0.030, 0.052, 0, 0, Math.PI / 2);
  gun.add(selPivot);
  const selector = boxCrisp(0.0018, 0.0034, 0.042, vm.park, 'selector');
  put(selector, -0.0181, 0.020, 0.034, -0.42, 0, 0);
  gun.add(selector);
  const selPlate = boxCrisp(0.0010, 0.013, 0.034, worn, 'selPlate');
  put(selPlate, -0.0174, 0.029, 0.046);
  gun.add(selPlate);
  /* Visible mag-well collar under the receiver's front half. Dark cavity
   * tone (fix 2): the bright worn collar showed between mag and receiver
   * as an "open notch with a flat inner shell face". */
  const magWell = boxCrisp(0.037, 0.011, 0.052, hole, 'magWell');
  put(magWell, 0, -0.013, 0.008);
  gun.add(magWell);

  const trunnion = lathe([0.012, 0, 0.017, 0.005, 0.017, 0.014, 0.012, 0.020], 24, metal, 'trunnion');
  put(trunnion, 0, 0.026, -0.108, -Math.PI / 2, 0, 0);
  gun.add(trunnion);

  /* Rear-sight block sits where the handguard meets the receiver (fix 9). */
  /* c22 fix 2 (round 5): probe-pick pinned the 216-RGB "chrome streak" to
   * THIS collar's front corner — park's dielectric lobe clips white on the
   * sharp box edge under the key light. Switch to steelvc and mark every
   * vert ~0.66: the shader turns that into a near-1.0 roughness, so the
   * collar reads dark forged steel with no clipped edge highlight. */
  /* c31: this collar WAS the "glassy translucent sliver" over the support-
   * hand fingertips (weapon/ads) — ID-render pinned the pale striped blob
   * at the fingertips to trunnionCollar: the 0xd4d2ce steelvc tint under
   * the warm hand/under fills read as translucent grey-pink, and its sine
   * wear-stripe vertex colors were the "bandage stripes". True dark
   * forged steel now — same map-free cool tubePark as the barrel family
   * (metal 0.10, rough 0.97, env 0, lum cap 0.080 cool-desat). Taller
   * (0.054 → 0.064) so it also occludes the receiver's crowned front-top
   * corner (y≈0.0546): that 3 mm strip hit the steelvc lum cap and was
   * the flat ~185 white rim riding the fingertips. */
  const collar = boxCrisp(0.048, 0.064, 0.024, vm.tubePark, 'trunnionCollar');
  put(collar, 0, 0.024, -0.113);
  gun.add(collar);
  /* Sight group in dark parkerized steel (fix 2, c20): the `worn` posts
   * rendered as two WHITE pillars at the trunnion — brightest px on the
   * gun after the barrel streak. */
  const sightBase = boxCrisp(0.026, 0.018, 0.030, vm.darkMetalVC, 'rearSightBase');
  markMatteSteel(sightBase.geometry, 0.18);
  put(sightBase, 0, 0.056, -0.108);
  gun.add(sightBase);
  const sightCap = boxCrisp(0.024, 0.0016, 0.028, vm.cavity, 'sightCap');
  put(sightCap, 0, 0.0656, -0.108);
  gun.add(sightCap);
  /* Rear sight rebuilt (c22 fix 4): the old rearNotch extrude stood two
   * 28 mm posts over the base — the "twin antennas" in every weapon crop.
   * Real AK read: a low ramped LEAF over the sight block with a sliding
   * catch mid-way and a shallow notch plate at its rear. Nothing rises
   * more than ~10 mm above the base top. */
  const sightLeaf = boxCrisp(0.0138, 0.0032, 0.052, vm.darkMetalVC, 'sightLeaf');
  markMatteSteel(sightLeaf.geometry, 0.20);
  put(sightLeaf, 0, 0.0665, -0.086, -0.14, 0, 0);
  gun.add(sightLeaf);
  const sightSlider = boxCrisp(0.0148, 0.0040, 0.0085, vm.darkMetalVC, 'sightSlider');
  markMatteSteel(sightSlider.geometry, 0.20);
  put(sightSlider, 0, 0.0682, -0.090, -0.14, 0, 0);
  gun.add(sightSlider);
  const sightNotch = boxCrisp(0.0150, 0.0052, 0.0036, vm.darkMetalVC, 'sightNotch');
  markMatteSteel(sightNotch.geometry, 0.20);
  put(sightNotch, 0, 0.0700, -0.0655);
  gun.add(sightNotch);
  /* Notch ears: two LOW nubs flanking the aiming groove. */
  for (const sx of [1, -1]) {
    const ear = boxCrisp(0.0052, 0.0026, 0.0036, vm.darkMetalVC, `sightEar${sx}`);
    markMatteSteel(ear.geometry, 0.20);
    put(ear, sx * 0.0049, 0.0736, -0.0655);
    gun.add(ear);
  }
  const coverLip = boxCrisp(0.028, 0.008, 0.008, vm.darkMetalVC, 'coverFrontLip');
  markMatteSteel(coverLip.geometry, 0.22);
  put(coverLip, 0, 0.060, -0.096);
  gun.add(coverLip);

  /* Contoured lower handguard: lathed spindle with a PRONOUNCED mid palm
   * swell (c22 fix 6), squashed into a wider-than-tall ellipse, laminate
   * grain bands via vertex color. */
  const hgLower = woodSpindle([
    0.0001, 0,
    0.0128, 0.005,
    0.0150, 0.022,
    0.0176, 0.048,
    0.0150, 0.076,
    0.0126, 0.092,
    0.0001, 0.096,
  ], 22, vm.woodGrain, 'handguard', 1.28, 0.92);
  addGrain(hgLower.geometry, 48, 0.22, 'x');
  put(hgLower, 0, 0.022, -0.118);
  gun.add(hgLower);
  /* Upper handguard rebuilt (c22 fix 5): the smooth ovoid spindle held the
   * brightest specular on the gun (220 RGB streak measured at 863,599 on
   * THIS part). Now a fluted profile — mid dip between two swells kills
   * the single long highlight — in dull grained wood matching the stock,
   * clamped by steel ferrules at both ends like a real AKM upper. */
  const hgUpper = woodSpindle([
    0.0001, 0,
    0.0094, 0.004,
    0.0107, 0.014,
    0.0096, 0.032,
    0.0106, 0.050,
    0.0090, 0.066,
    0.0001, 0.071,
  ], 18, vm.woodUpper, 'handguardUpper', 1.10, 1.0);
  addGrain(hgUpper.geometry, 56, 0.18, 'x');
  put(hgUpper, 0, 0.048, -0.126);
  gun.add(hgUpper);
  /* c31: `park` (metal 0.70, rough 0.74, env 0.24) glinted a pale grey
   * crescent (161/153/141) on the front ferrule right at the support-hand
   * fingertips — the critic's "glassy sliver". Capped cool tubePark now. */
  const ferR = cyl(0.0104, 0.0104, 0.0075, vm.tubePark, 14, 'hgUpFerruleR');
  put(ferR, 0, 0.048, -0.1305, Math.PI / 2, 0, 0);
  gun.add(ferR);
  const ferF = cyl(0.0098, 0.0098, 0.0075, vm.tubePark, 14, 'hgUpFerruleF');
  put(ferF, 0, 0.048, -0.1925, Math.PI / 2, 0, 0);
  gun.add(ferF);
  /* Steel retainer rings capping both handguard ends. */
  const hgRingR = cyl(0.0158, 0.0158, 0.010, vm.park, 18, 'hgRingR');
  put(hgRingR, 0, 0.024, -0.121, Math.PI / 2, 0, 0);
  hgRingR.scale.set(1.22, 1, 0.90);
  gun.add(hgRingR);
  const hgRingF = cyl(0.0146, 0.0146, 0.010, vm.park, 18, 'hgRingF');
  put(hgRingF, 0, 0.024, -0.210, Math.PI / 2, 0, 0);
  hgRingF.scale.set(1.18, 1, 0.88);
  gun.add(hgRingF);

  const barrel = lathe([
    0.0110, 0,
    0.0116, 0.04,
    0.0112, 0.12,
    0.0106, 0.20,
    0.0100, 0.255,
  ], 28, vm.barrelPark, 'barrel');
  put(barrel, 0, 0.026, -0.210, -Math.PI / 2, 0, 0);
  gun.add(barrel);

  const gasBlock = lathe([
    0.010, 0,
    0.016, 0.004,
    0.017, 0.014,
    0.015, 0.020,
    0.011, 0.024,
  ], 24, vm.barrelPark, 'gasBlock');
  put(gasBlock, 0, 0.026, -0.348, -Math.PI / 2, 0, 0);
  gun.add(gasBlock);

  const gasTube = lathe([0.0074, 0, 0.0078, 0.04, 0.0076, 0.14, 0.0072, 0.150], 22, vm.barrelPark, 'gasTube');
  put(gasTube, 0, 0.048, -0.198, -Math.PI / 2, 0, 0);
  gun.add(gasTube);

  /* Front sight assembly at the muzzle: lathed base, HOODED RING with a
   * center post inside it — replaces the c16 splayed flat ears that read
   * as a garden fork. Everything matte parkerized grey (fix 3). */
  const fsBase = lathe([
    0.0104, 0,
    0.0148, 0.004,
    0.0152, 0.017,
    0.0112, 0.023,
  ], 20, vm.barrelPark, 'frontSightBase');
  put(fsBase, 0, 0.026, -0.428, -Math.PI / 2, 0, 0);
  gun.add(fsBase);
  /* Hood: full ring standing above the base, plane facing the muzzle axis. */
  const hood = mesh(smooth(new THREE.TorusGeometry(0.0092, 0.0026, 10, 22), false), vm.barrelPark, 'sightHood');
  put(hood, 0, 0.049, -0.433);
  gun.add(hood);
  /* Hood legs joining ring to base. */
  const legL = boxCrisp(0.0022, 0.010, 0.0044, vm.barrelPark, 'hoodLegL');
  put(legL, -0.0078, 0.041, -0.433);
  gun.add(legL);
  const legR = boxCrisp(0.0022, 0.010, 0.0044, vm.barrelPark, 'hoodLegR');
  put(legR, 0.0078, 0.041, -0.433);
  gun.add(legR);
  const post = cyl(0.0016, 0.0020, 0.014, worn, 10, 'frontPost');
  put(post, 0, 0.046, -0.433);
  gun.add(post);

  /* AKM slanted muzzle brake: plain cylinder, ONE oblique front cut, matte
   * parkerized — no brass ring (fix 3). */
  const brake = mesh(slantBrakeGeo(), vm.barrelPark, 'muzzleBrake');
  put(brake, 0, 0.026, -0.472);
  gun.add(brake);
  const bore = cyl(0.0052, 0.0052, 0.010, hole, 14, 'brakeBore');
  put(bore, 0, 0.0285, -0.488, Math.PI / 2 - 0.55, 0, 0);
  gun.add(bore);

  const magGrp = new THREE.Group();
  magGrp.name = 'magazine';
  magGrp.rotation.x = 0.38;
  magGrp.position.set(0, 0.002, 0.006);
  /* Bakelite body with a painted amber-brown gradient (fix 4): dark resin
   * at the feed end blending to lit amber toward the floorplate, with a
   * faint swirl driven by position so the flank is never one flat tone. */
  const magBody = extrudeZYCrisp(magHull(), 0.030, vm.magBake, 'magBody', 0.0016);
  {
    const mp = magBody.geometry.attributes.position;
    const mc = new Float32Array(mp.count * 3);
    const uv = magBody.geometry.attributes.uv;
    /* Bake carries amber. UV.y runs along the banana so the gradient is on
     * the ads-facing flank, not a random extrude patch. Mild VC only — the
     * c23 1.55-2.25 ramp was lighting-state theatre and died in the ads well. */
    for (let i = 0; i < mp.count; i++) {
      const t = THREE.MathUtils.clamp((0.012 - mp.getY(i)) / 0.150, 0, 1);
      const swirl = 0.5 + 0.5 * Math.sin(mp.getY(i) * 140 + mp.getZ(i) * 180);
      if (uv) uv.setXY(i, mp.getZ(i) * 2.1 + 0.5, t);
      /* Mild VC — bake carries the amber. Feed end (t~0) darkens toward
       * worn steel so the lips read, toe stays in-family (no 1.08 lift). */
      const feed = THREE.MathUtils.clamp((mp.getY(i) + 0.004) / 0.020, 0, 1);
      const k = (0.64 + 0.05 * t + 0.02 * swirl) * (0.58 + 0.42 * feed);
      mc[i * 3] = k;
      mc[i * 3 + 1] = k * 0.94;
      mc[i * 3 + 2] = k * 0.86;
    }
    if (uv) {
      uv.needsUpdate = true;
      magBody.geometry.setAttribute('uv2', uv.clone());
    }
    magBody.geometry.setAttribute('color', new THREE.BufferAttribute(mc, 3));
  }
  magGrp.add(magBody);
  /* Horizontal stiffening ribs proud of BOTH flanks so the ADS crop shows
   * geometry steps, not a flat slab: five stations riding the curve. */
  const magRibs = [
    [0.004, -0.020, 0.18],
    [-0.006, -0.048, 0.38],
    [-0.017, -0.076, 0.58],
    [-0.030, -0.100, 0.76],
    [-0.044, -0.120, 0.92],
  ];
  for (let i = 0; i < magRibs.length; i++) {
    const [rz, ry, ra] = magRibs[i];
    /* Geometric rib ridges (c22 fix 3): the painted-black grooves are GONE
     * — they were the "two dark dashes". Each station is now a single
     * PROUD ridge in the lighter rib bakelite; its crisp top facet catches
     * the key light and its underside self-shades, so the step reads as
     * geometry at 4x without any painted shadow. */
    const rib = boxCrisp(0.0390, 0.0050, 0.0080, vm.magRib, `magRib${i}`);
    markMatteSteel(rib.geometry, 0.42);
    {
      const rn = rib.geometry.attributes.normal;
      const rc = rib.geometry.attributes.color;
      if (rn && rc) {
        for (let k = 0; k < rn.count; k++) {
          const up = Math.max(0, rn.getY(k));
          const v = 0.42 * (1 - 0.55 * up);
          rc.setXYZ(k, v, v * 0.92, v * 0.78);
        }
        rc.needsUpdate = true;
      }
    }
    put(rib, 0, ry, rz, ra, 0, 0);
    magGrp.add(rib);
  }
  /* Feed-lip wear: darker worn steel collar, slightly proud so ADS reads it. */
  const feedLip = boxCrisp(0.0342, 0.0092, 0.044, vm.magDark, 'magFeedLip');
  put(feedLip, 0, 0.010, 0.004, 0.12, 0, 0);
  magGrp.add(feedLip);
  const feedWear = boxCrisp(0.0310, 0.0036, 0.036, vm.park, 'magFeedWear');
  put(feedWear, 0, 0.0152, 0.002, 0.10, 0, 0);
  magGrp.add(feedWear);
  /* Floorplate with a proud lip step at the toe (fix 4). */
  const floorplate = boxCrisp(0.0350, 0.0070, 0.048, vm.magDark, 'magFloorplate');
  put(floorplate, 0, -0.129, -0.051, 0.66, 0, 0);
  magGrp.add(floorplate);
  const plateLip = boxCrisp(0.0362, 0.0042, 0.014, vm.magRib, 'magPlateLip');
  put(plateLip, 0, -0.122, -0.070, 0.66, 0, 0);
  magGrp.add(plateLip);
  magGrp.scale.set(0.98, 0.96, 1.0);
  gun.add(magGrp);

  gun.add(extrudeZYCrisp(gripHull(), 0.026, vm.grip, 'pistolGrip', 0.0012));
  const gripCap = lathe([0.010, 0, 0.013, 0.003, 0.012, 0.008], 14, vm.bakelite, 'gripCap');
  put(gripCap, 0, -0.110, 0.088, 0, 0, 0);
  gun.add(gripCap);

  const trigger = extrudeZY(triggerHull(), 0.005, vm.park, 'trigger', 0.0003);
  put(trigger, 0, -0.014, 0.050);
  gun.add(trigger);
  gun.add(tube(
    new THREE.CubicBezierCurve3(
      new THREE.Vector3(0, -0.002, 0.026),
      new THREE.Vector3(0, -0.038, 0.030),
      new THREE.Vector3(0, -0.042, 0.074),
      new THREE.Vector3(0, -0.004, 0.082),
    ),
    18, 0.0034, 8, metal, 'triggerGuard',
  ));

  const stock = extrudeZY(stockHull(), 0.025, vm.woodGrainD, 'stock', 0.0030);
  {
    /* Shape the buttstock: width tapers 34% toward the pad, the comb drops
     * and the whole rear thins slightly, so it reads as a lathed AK stock
     * with a big soft bevel — not a raw plank (fix 2). */
    const sp = stock.geometry.attributes.position;
    for (let i = 0; i < sp.count; i++) {
      const z = sp.getZ(i);
      const t = THREE.MathUtils.clamp((z - 0.086) / 0.112, 0, 1);
      const swell = 1 + 0.10 * Math.sin(Math.PI * t);
      sp.setX(i, sp.getX(i) * (1 - 0.34 * t) * swell);
      const y = sp.getY(i);
      sp.setY(i, 0.014 + (y - 0.014) * (1 - 0.16 * t) - 0.009 * t);
    }
    sp.needsUpdate = true;
    stock.geometry.computeVertexNormals();
    /* Extrude UVs sample a ~0.1uv patch of the bake, which magnifies into a
     * featureless sheen. Re-project box-planar: uv.x runs ALONG the stock
     * (grain axis), uv.y across the section, per dominant normal axis. */
    const sn = stock.geometry.attributes.normal;
    const suv = stock.geometry.attributes.uv;
    for (let i = 0; i < sp.count; i++) {
      const u = (sp.getZ(i) - 0.086) * 6.5 + 0.30;
      const cross = Math.abs(sn.getY(i)) > 0.55 ? sp.getX(i) : sp.getY(i);
      /* cross scale 14 -> 4.5 (fix 3): the 14x squeeze pushed the bake's
       * fine pore rows into bright metallic-looking ribs on the comb. */
      suv.setXY(i, u, cross * 4.5 + 0.5);
    }
    suv.needsUpdate = true;
    stock.geometry.setAttribute('uv2', suv.clone());
    /* Laminate grain bands across the shaped section (c22 fix 6): applied
     * AFTER the taper so the streaks follow the final surface. */
    addGrain(stock.geometry, 64, 0.26);
  }
  gun.add(stock);
  for (let i = 0; i < 5; i++) {
    const slat = boxCrisp(0.0022, 0.034, 0.088, vm.woodGrain, `stockSlat${i}`);
    addGrain(slat.geometry, 44, 0.16);
    put(slat, (i - 2) * 0.0048, 0.016, 0.142, 0.04, 0, 0);
    gun.add(slat);
  }
  /* Rear socket wedge in matte end-grain wood — the metallic version lit up
   * as a polished gold ribbed wedge in the c16 crop (fix 6). A thin dark
   * steel tang line above is all the metal that remains. */
  const socket = boxCrisp(0.030, 0.050, 0.016, vm.woodEnd, 'stockSocket');
  put(socket, 0, 0.020, 0.094);
  gun.add(socket);
  /* Tang dropped to cavity-black (fix 2, c19): probe-pick showed THIS box
   * was the last beige strip in the junction rect — its top face collects
   * every vm light at once and out-shone the receiver top (0.64 vs 0.42).
   * As a shadow-dark seam it reads like the gap every real AK shows where
   * the wood meets the rear trunnion. */
  /* Tang as dark textured steel (c20): the c19 cavity-black box read as a
   * void slab hovering over the stock comb in the crop. blueSteel keeps it
   * a full stop under the receiver top without going to paint-black. */
  const socketTang = boxCrisp(0.022, 0.0038, 0.024, vm.blueSteel, 'stockTang');
  put(socketTang, 0, 0.0448, 0.098, 0.08, 0, 0);
  gun.add(socketTang);
  const buttplate = boxCrisp(0.0245, 0.050, 0.013, vm.bakelite, 'buttplate');
  put(buttplate, 0, 0.005, 0.1965, -0.10, 0, 0);
  gun.add(buttplate);
  const pad = lathe([0.015, 0, 0.021, 0.004, 0.021, 0.010, 0.016, 0.012], 16, vm.bakelite, 'buttpad');
  put(pad, 0, 0.005, 0.203, 0, 0, Math.PI / 2);
  gun.add(pad);

  /* AKM rivet pattern (fix 3, c20): DOMED heads — squashed spheres whose
   * top curvature catches the vm key/dir light as a bright cap over a
   * shaded underside, the shading that makes a rivet read at 2x zoom. Head
   * diameter 8.4 mm (~12 px at the weapon stop) vs the c19 6 mm cylinders
   * whose flat end-caps lit like the flank and vanished. */
  /* c25: flush low-profile bumps (~65% smaller, flattened on X). The c24
   * proud domes + bright rivet lobe were the polka-dot tell. */
  const rivetGeo = new THREE.SphereGeometry(0.00188, 10, 8);
  rivetGeo.scale(0.30, 1, 1);
  const rivets = [];
  for (const sx of [1, -1]) {
    rivets.push(
      [sx * 0.0178, 0.038, 0.084],
      [sx * 0.0178, 0.012, 0.076],
      [sx * 0.0178, 0.026, 0.056],
      [sx * 0.0178, 0.008, 0.038],
      [sx * 0.0178, 0.026, -0.056],
      [sx * 0.0178, 0.040, -0.090],
      [sx * 0.0178, 0.012, -0.096],
      [sx * 0.0178, 0.026, -0.096],
    );
  }
  gun.add(instanced(rivetGeo, vm.rivet, rivets, 'rivets'));

  const { flash } = makeFlash(WEAPONS.rifle.flash, 0, 0.026, -0.512);
  gun.add(flash);

  const right = buildMitt(vm, 1);
  right.scale.setScalar(0.56);
  put(right, 0.018, -0.058, 0.078, 1.05, 0.18, 0.42);
  gun.add(right);

  const left = buildSupportGlove(vm);
  gun.add(left);

  return {
    gun, flash,
    /* c21 pose handoff: gun lowered/centered so it stops blocking the
     * crosshair (was hip 0.062,-0.112,-0.268 / aim 0.028,-0.086,-0.268). */
    hip: new THREE.Vector3(0.085, -0.150, -0.300),
    aim: new THREE.Vector3(0.070, -0.135, -0.310),
  };
}

/* ── "Longshot" bolt sniper ─────────────────────────────────────────────
 * AWP-like silhouette: long heavy barrel, boxy receiver, big top scope,
 * bolt handle on the right flank, polymer skeleton stock. ~1/3 the AK's
 * part count — it is hidden entirely while scoped. */
function sniperReceiverHull() {
  const s = new THREE.Shape();
  s.moveTo(-0.150, 0.000);
  s.lineTo(-0.150, 0.038);
  s.lineTo(-0.128, 0.046);
  s.lineTo(0.088, 0.046);
  s.lineTo(0.098, 0.036);
  s.lineTo(0.098, 0.004);
  s.lineTo(0.052, -0.006);
  s.lineTo(0.034, -0.014);
  s.lineTo(-0.014, -0.014);
  s.lineTo(-0.030, -0.002);
  s.closePath();
  return s;
}

function sniperStockHull() {
  const s = new THREE.Shape();
  s.moveTo(0.092, 0.000);
  s.lineTo(0.092, 0.042);
  s.quadraticCurveTo(0.150, 0.040, 0.210, 0.034);
  s.lineTo(0.238, 0.026);
  s.lineTo(0.242, -0.036);
  s.lineTo(0.216, -0.044);
  s.lineTo(0.150, -0.020);
  s.quadraticCurveTo(0.110, -0.008, 0.092, 0.000);
  s.closePath();
  return s;
}

function buildSniper(vm) {
  const gun = new THREE.Group();
  gun.name = 'longshot';

  const recv = extrudeZYCrisp(sniperReceiverHull(), 0.036, vm.darkMetal, 'snReceiver', 0.0014);
  gun.add(recv);
  /* Polymer forend under the barrel root — gives the support glove a real
   * thing to hold (its wrap ellipse matches the AK guard height). */
  const forend = boxCrisp(0.034, 0.024, 0.150, vm.plate, 'snForend');
  put(forend, 0, 0.010, -0.190);
  gun.add(forend);

  const barrel = lathe([
    0.0138, 0,
    0.0142, 0.05,
    0.0128, 0.20,
    0.0118, 0.38,
    0.0110, 0.52,
  ], 24, vm.barrelPark, 'snBarrel');
  put(barrel, 0, 0.024, -0.148, -Math.PI / 2, 0, 0);
  gun.add(barrel);
  const brake = cyl(0.0165, 0.0155, 0.052, vm.park, 18, 'snBrake');
  put(brake, 0, 0.024, -0.690, Math.PI / 2, 0, 0);
  gun.add(brake);
  const bore = cyl(0.0058, 0.0058, 0.008, vm.cavity, 12, 'snBore');
  put(bore, 0, 0.024, -0.714, Math.PI / 2, 0, 0);
  gun.add(bore);

  /* Scope: main tube + two lathe bell ends + dark lens discs + mounts. */
  const tube = cyl(0.019, 0.019, 0.140, vm.darkMetal, 24, 'scopeTube');
  put(tube, 0, 0.094, -0.028, Math.PI / 2, 0, 0);
  gun.add(tube);
  const bellF = lathe([0.019, 0, 0.026, 0.016, 0.0275, 0.042], 24, vm.darkMetal, 'scopeBellF');
  put(bellF, 0, 0.094, -0.095, -Math.PI / 2, 0, 0);
  gun.add(bellF);
  const bellR = lathe([0.019, 0, 0.023, 0.012, 0.024, 0.034], 24, vm.darkMetal, 'scopeBellR');
  put(bellR, 0, 0.094, 0.040, Math.PI / 2, 0, 0);
  gun.add(bellR);
  const lensF = cyl(0.0245, 0.0245, 0.004, vm.lens, 20, 'scopeLensF');
  put(lensF, 0, 0.094, -0.136, Math.PI / 2, 0, 0);
  gun.add(lensF);
  const lensR = cyl(0.0215, 0.0215, 0.004, vm.lens, 20, 'scopeLensR');
  put(lensR, 0, 0.094, 0.073, Math.PI / 2, 0, 0);
  gun.add(lensR);
  const turret = cyl(0.0085, 0.0085, 0.016, vm.park, 14, 'scopeTurret');
  put(turret, 0, 0.120, -0.028);
  gun.add(turret);
  const mountF = boxCrisp(0.014, 0.030, 0.018, vm.park, 'scopeMountF');
  put(mountF, 0, 0.062, -0.052);
  gun.add(mountF);
  const mountR = boxCrisp(0.014, 0.030, 0.018, vm.park, 'scopeMountR');
  put(mountR, 0, 0.062, 0.016);
  gun.add(mountR);

  /* Bolt handle: shank + ball knob on the right flank. */
  const boltShank = cyl(0.0042, 0.0042, 0.034, vm.edge, 12, 'snBoltShank');
  put(boltShank, 0.026, 0.028, 0.056, 0, 0, -1.05);
  gun.add(boltShank);
  const boltKnob = mesh(smooth(new THREE.SphereGeometry(0.0088, 12, 9), false), vm.edge, 'snBoltKnob');
  put(boltKnob, 0.040, 0.020, 0.056);
  gun.add(boltKnob);

  const stock = extrudeZY(sniperStockHull(), 0.030, vm.plate, 'snStock', 0.0022);
  gun.add(stock);
  const cheek = boxCrisp(0.026, 0.016, 0.070, vm.bakelite, 'snCheek');
  put(cheek, 0, 0.050, 0.152);
  gun.add(cheek);
  const buttpad = boxCrisp(0.030, 0.062, 0.014, vm.bakelite, 'snButtpad');
  put(buttpad, 0, -0.004, 0.246, -0.08, 0, 0);
  gun.add(buttpad);

  const magBox = boxCrisp(0.032, 0.030, 0.070, vm.magDark, 'snMag');
  put(magBox, 0, -0.026, 0.004);
  gun.add(magBox);

  gun.add(extrudeZYCrisp(gripHull(), 0.026, vm.grip, 'snGrip', 0.0012));
  const trigger = extrudeZY(triggerHull(), 0.005, vm.edge, 'snTrigger', 0.0003);
  put(trigger, 0, -0.014, 0.050);
  gun.add(trigger);
  gun.add(tubeGuard(vm.darkMetal));

  const { flash } = makeFlash(WEAPONS.sniper.flash, 0, 0.024, -0.730);
  gun.add(flash);

  const right = buildMitt(vm, 1);
  right.scale.setScalar(0.56);
  put(right, 0.018, -0.058, 0.078, 1.05, 0.18, 0.42);
  gun.add(right);
  const left = buildSupportGlove(vm);
  left.position.set(0, -0.012, -0.030);
  gun.add(left);

  return {
    gun, flash,
    hip: new THREE.Vector3(0.095, -0.150, -0.320),
    // Aim pose is irrelevant — the viewmodel is hidden while scoped.
    aim: new THREE.Vector3(0.095, -0.150, -0.320),
  };
}

/* ── "Rampart" pump shotgun ─────────────────────────────────────────────
 * Signature silhouette: barrel over a parallel under-tube magazine, wood
 * pump sleeve riding the tube (slides during the 0.9 s pump), amber shell
 * loops on the receiver flank. */
function shotgunReceiverHull() {
  const s = new THREE.Shape();
  /* c28: boxier pump receiver — shorter, square corners, flat top/bottom.
   * The c27 kayak hull (deep belly + big crown radius) was the silhouette. */
  s.moveTo(-0.100, -0.004);
  s.lineTo(-0.100, 0.012);
  s.lineTo(-0.100, 0.036);
  s.lineTo(-0.098, 0.044);
  s.lineTo(-0.090, 0.0460);
  s.lineTo(-0.040, 0.0464);
  s.lineTo(0.016, 0.0466);
  s.lineTo(0.054, 0.0462);
  s.lineTo(0.064, 0.042);
  s.lineTo(0.066, 0.018);
  s.lineTo(0.066, 0.002);
  s.lineTo(0.058, -0.004);
  s.lineTo(0.016, -0.005);
  s.lineTo(-0.040, -0.005);
  s.lineTo(-0.086, -0.004);
  s.lineTo(-0.100, -0.004);
  s.closePath();
  return s;
}

function buildShotgun(vm) {
  const gun = new THREE.Group();
  gun.name = 'rampart';

  const recv = extrudeZYSoft(shotgunReceiverHull(), 0.038, vm.sgSteel, 'sgReceiver', 0.0014);
  recv.geometry = stampFlats(recv.geometry, 0.00008, 'crown');
  markGunmetalVC(recv.geometry, { flat: 0.52, bevel: 0.14, mottAmp: 0.06 });
  gun.add(recv);
  /* Stamped flank detail so the camera-near side is not a featureless slab. */
  const sgGroove = boxCrisp(0.014, 0.0020, 0.148, vm.sgCavity, 'sgTopGroove');
  put(sgGroove, 0, 0.0468, -0.012);
  gun.add(sgGroove);
  const sgGrooveLipL = boxCrisp(0.0152, 0.0007, 0.150, vm.tubePark, 'sgGrooveLipL');
  put(sgGrooveLipL, 0, 0.0476, -0.012);
  gun.add(sgGrooveLipL);
  const sgGrooveLipR = boxCrisp(0.0152, 0.0007, 0.150, vm.tubePark, 'sgGrooveLipR');
  put(sgGrooveLipR, 0, 0.0460, -0.012);
  gun.add(sgGrooveLipR);
  for (const sx of [1, -1]) {
    const stamp = boxCrisp(0.0024, 0.016, 0.048, vm.sgCavity, `sgStamp${sx}`);
    put(stamp, sx * 0.0194, 0.026, 0.016);
    gun.add(stamp);
    const stampLip = boxCrisp(0.0007, 0.0172, 0.050, vm.tubePark, `sgStampLip${sx}`);
    put(stampLip, sx * 0.0208, 0.026, 0.016);
    gun.add(stampLip);
    const pinA = cyl(0.0016, 0.0016, 0.0024, vm.park, 8, `sgPinA${sx}`);
    put(pinA, sx * 0.0188, 0.036, 0.028, 0, 0, Math.PI / 2);
    gun.add(pinA);
    const pinB = cyl(0.0014, 0.0014, 0.0024, vm.park, 8, `sgPinB${sx}`);
    put(pinB, sx * 0.0188, 0.016, 0.040, 0, 0, Math.PI / 2);
    gun.add(pinB);
  }
  /* Ejection port as layered recess (c23): cavity + bolt face + lips so
   * the slab flank reads as a cut, not a painted card. park/cavity/worn
   * only — no new low-rough metal. */
  const portCavity = boxCrisp(0.0048, 0.0200, 0.058, vm.sgCavity, 'sgPort');
  put(portCavity, -0.0210, 0.030, -0.024);
  gun.add(portCavity);
  const sgBolt = boxCrisp(0.0032, 0.0130, 0.024, vm.worn, 'sgBoltFace');
  put(sgBolt, -0.0218, 0.0295, -0.010, 0, 0, -0.08);
  gun.add(sgBolt);
  const sgLipT = boxCrisp(0.0030, 0.0032, 0.062, vm.park, 'sgPortT');
  put(sgLipT, -0.0226, 0.0412, -0.024);
  gun.add(sgLipT);
  const sgLipB = boxCrisp(0.0030, 0.0032, 0.062, vm.park, 'sgPortB');
  put(sgLipB, -0.0226, 0.0190, -0.024);
  gun.add(sgLipB);
  const sgLipF = boxCrisp(0.0030, 0.0200, 0.0034, vm.park, 'sgPortF');
  put(sgLipF, -0.0226, 0.030, -0.0540);
  gun.add(sgLipF);
  const sgLipR = boxCrisp(0.0030, 0.0200, 0.0034, vm.park, 'sgPortR');
  put(sgLipR, -0.0226, 0.030, 0.0060);
  gun.add(sgLipR);
  /* Loading gate inset on the receiver underside. */
  const gate = boxCrisp(0.018, 0.0024, 0.038, vm.sgCavity, 'sgGate');
  put(gate, 0, -0.0054, 0.010);
  gun.add(gate);
  const gateLip = boxCrisp(0.020, 0.0016, 0.040, vm.park, 'sgGateLip');
  put(gateLip, 0, -0.0038, 0.010);
  gun.add(gateLip);
  const gatePin = boxCrisp(0.0036, 0.0024, 0.005, vm.park, 'sgGatePin');
  put(gatePin, -0.008, -0.0042, 0.026);
  gun.add(gatePin);
  /* Trigger group plate + pin so the guard isn't a floating hoop. */
  const tg = boxCrisp(0.024, 0.016, 0.044, vm.park, 'sgTrigGroup');
  put(tg, 0, -0.006, 0.048);
  gun.add(tg);
  const tgPin = cyl(0.0024, 0.0024, 0.026, vm.worn, 10, 'sgTrigPin');
  put(tgPin, 0, -0.004, 0.038, 0, 0, Math.PI / 2);
  gun.add(tgPin);

  const barrel = lathe([
    0.0122, 0,
    0.0126, 0.06,
    0.0118, 0.28,
    0.0112, 0.40,
  ], 24, vm.sgBarrel, 'sgBarrel');
  put(barrel, 0, 0.040, -0.100, -Math.PI / 2, 0, 0);
  gun.add(barrel);

  const tubeMag = cyl(0.0095, 0.0095, 0.360, vm.tubePark, 18, 'sgTube');
  put(tubeMag, 0, 0.008, -0.270, Math.PI / 2, 0, 0);
  gun.add(tubeMag);
  const tubeCap = lathe([0.0001, 0, 0.0092, 0.005, 0.0098, 0.016], 16, vm.tubePark, 'sgTubeCap');
  put(tubeCap, 0, 0.008, -0.436, -Math.PI / 2, 0, 0);
  gun.add(tubeCap);
  const clampF = boxCrisp(0.026, 0.048, 0.012, vm.park, 'sgClamp');
  put(clampF, 0, 0.024, -0.428);
  gun.add(clampF);

  /* Pump sleeve (named — Weapon.update slides it +z during the pump). The
   * left mitt is parented here so the hand rides the pump. */
  const pump = woodSpindle([
    0.0148, 0.002,
    0.0162, 0.010,
    0.0178, 0.030,
    0.0190, 0.052,
    0.0172, 0.070,
    0.0190, 0.090,
    0.0178, 0.110,
    0.0162, 0.130,
    0.0148, 0.138,
  ], 36, vm.woodMatte, 'pumpWood', 1.16, 0.88);
  addGrain(pump.geometry, 72, 0.42, 'x', [0.48, 0.78]);
  const pumpGrp = new THREE.Group();
  pumpGrp.name = 'pump';
  pumpGrp.position.set(0, 0.010, -0.250);
  pumpGrp.add(pump);
  const pumpCapGeo = smooth(new THREE.SphereGeometry(0.0154, 16, 12), false);
  addGrain(pumpCapGeo, 64, 0.36, 'x', [0.48, 0.78]);
  const pumpCapF = mesh(pumpCapGeo, vm.woodMatte, 'pumpCapF');
  pumpCapF.scale.set(1.16, 0.88, 0.58);
  put(pumpCapF, 0, 0, -0.002);
  pumpGrp.add(pumpCapF);
  /* Muzzle-end cap was the blaze-orange band — gunmetal ferrule. */
  const pumpCapR = mesh(pumpCapGeo, vm.sgBarrel, 'pumpCapR');
  pumpCapR.scale.set(1.16, 0.88, 0.58);
  put(pumpCapR, 0, 0, -0.138);
  pumpGrp.add(pumpCapR);
  const pumpFerrule = cyl(0.0162, 0.0162, 0.012, vm.sgBarrel, 18, 'sgPumpFerrule');
  put(pumpFerrule, 0, 0.002, -0.134, Math.PI / 2, 0, 0);
  pumpFerrule.scale.set(1.18, 1, 1.02);
  pumpGrp.add(pumpFerrule);
  const pumpRing = cyl(0.0168, 0.0168, 0.008, vm.tubePark, 18, 'sgPumpRing');
  put(pumpRing, 0, 0.002, -0.070, Math.PI / 2, 0, 0);
  pumpRing.scale.set(1.18, 1, 1.02);
  pumpGrp.add(pumpRing);
  const leftMitt = buildMitt(vm, -1);
  leftMitt.scale.setScalar(0.62);
  put(leftMitt, -0.004, -0.022, -0.072, 1.02, -0.20, -0.38);
  pumpGrp.add(leftMitt);
  gun.add(pumpGrp);

  const bead = mesh(smooth(new THREE.SphereGeometry(0.0036, 10, 8), false), vm.park, 'sgBead');
  put(bead, 0, 0.048, -0.494);
  gun.add(bead);

  /* Shell loops on the camera flank of the receiver. c31: 0.050-long
   * cylinders at 0.030 spacing OVERLAPPED into one continuous tube — the
   * critic's "copper magazine tube". Shorter shells leave 2 mm breaks so
   * four separate loops read; dark matte kills the specular streak. */
  const shellGeo = new THREE.CylinderGeometry(0.0088, 0.0088, 0.028, 10);
  shellGeo.rotateX(Math.PI / 2);
  const shellPoses = [];
  for (let i = 0; i < 4; i++) {
    shellPoses.push([-0.0252, 0.024, -0.062 + i * 0.030, 0, 0, 0, 1, 1, 1]);
  }
  gun.add(instanced(shellGeo, vm.shellAmber, shellPoses, 'sgShells'));
  /* Rail behind the loops: `plate` (rough 0.58, env 0.20) caught its own
   * warm specular — same tubePark gunmetal as the mag tube it borders. */
  const shellRail = boxCrisp(0.0032, 0.030, 0.126, vm.tubePark, 'sgShellRail');
  put(shellRail, -0.0212, 0.024, -0.017);
  gun.add(shellRail);

  const stock = extrudeZY(stockHull(), 0.026, vm.woodGrainD, 'sgStock', 0.0030);
  {
    const sp = stock.geometry.attributes.position;
    for (let i = 0; i < sp.count; i++) {
      const z = sp.getZ(i);
      const t = THREE.MathUtils.clamp((z - 0.086) / 0.112, 0, 1);
      const swell = 1 + 0.10 * Math.sin(Math.PI * t);
      /* Wrist narrows at the socket, comb drops, butt swells — same
       * recipe as the AK stock so it stops reading as a brown box. */
      const wrist = z < 0.110 ? 0.78 + 0.22 * ((z - 0.086) / 0.024) : 1;
      sp.setX(i, sp.getX(i) * (1 - 0.34 * t) * swell * Math.min(1, wrist));
      const y = sp.getY(i);
      sp.setY(i, 0.014 + (y - 0.014) * (1 - 0.18 * t) - 0.010 * t);
    }
    sp.needsUpdate = true;
    stock.geometry.computeVertexNormals();
    const sn = stock.geometry.attributes.normal;
    const suv = stock.geometry.attributes.uv;
    for (let i = 0; i < sp.count; i++) {
      const u = (sp.getZ(i) - 0.086) * 6.5 + 0.30;
      const cross = Math.abs(sn.getY(i)) > 0.55 ? sp.getX(i) : sp.getY(i);
      suv.setXY(i, u, cross * 4.5 + 0.5);
    }
    suv.needsUpdate = true;
    stock.geometry.setAttribute('uv2', suv.clone());
    addGrain(stock.geometry, 64, 0.24);
  }
  gun.add(stock);
  const comb = boxCrisp(0.018, 0.010, 0.070, vm.woodGrainD, 'sgComb');
  addGrain(comb.geometry, 52, 0.18);
  put(comb, 0, 0.040, 0.150, -0.08, 0, 0);
  gun.add(comb);
  for (let i = 0; i < 4; i++) {
    const slat = boxCrisp(0.0020, 0.032, 0.084, vm.woodGrain, `sgStockSlat${i}`);
    addGrain(slat.geometry, 40, 0.14);
    put(slat, (i - 1.5) * 0.0050, 0.014, 0.140, 0.04, 0, 0);
    gun.add(slat);
  }
  const buttplate = boxCrisp(0.0245, 0.050, 0.013, vm.bakelite, 'sgButtplate');
  put(buttplate, 0, 0.005, 0.1965, -0.10, 0, 0);
  gun.add(buttplate);
  const sgPad = lathe([0.015, 0, 0.021, 0.004, 0.021, 0.010, 0.016, 0.012], 16, vm.bakelite, 'sgButtpad');
  put(sgPad, 0, 0.005, 0.203, 0, 0, Math.PI / 2);
  gun.add(sgPad);
  gun.add(extrudeZYCrisp(gripHull(), 0.026, vm.grip, 'sgGrip', 0.0012));
  const trigger = extrudeZY(triggerHull(), 0.005, vm.park, 'sgTrigger', 0.0003);
  put(trigger, 0, -0.014, 0.050);
  gun.add(trigger);
  gun.add(tubeGuard(vm.blueSteel));

  const { flash } = makeFlash(WEAPONS.shotgun.flash, 0, 0.040, -0.520);
  gun.add(flash);

  const right = buildMitt(vm, 1);
  right.scale.setScalar(0.56);
  put(right, 0.018, -0.058, 0.078, 1.05, 0.18, 0.42);
  gun.add(right);

  return {
    gun, flash, pump: pumpGrp,
    hip: new THREE.Vector3(0.085, -0.150, -0.300),
    aim: new THREE.Vector3(0.020, -0.070, -0.240),
  };
}

/* ── "Vektor" semi-auto pistol ──────────────────────────────────────────
 * Compact: boxy slide with ejection notch + rear serrations, polymer frame
 * and raked grip, short exposed muzzle, two half-scale mitts. */
function pistolFrameHull() {
  const s = new THREE.Shape();
  s.moveTo(-0.098, 0.006);
  s.lineTo(-0.098, 0.020);
  s.lineTo(0.052, 0.020);
  s.lineTo(0.058, 0.012);
  s.lineTo(0.070, -0.058);
  s.lineTo(0.058, -0.092);
  s.quadraticCurveTo(0.052, -0.098, 0.040, -0.094);
  s.lineTo(0.016, -0.088);
  s.lineTo(0.006, -0.020);
  s.lineTo(-0.020, -0.008);
  s.closePath();
  return s;
}

function buildPistol(vm) {
  const gun = new THREE.Group();
  gun.name = 'vektor';

  const slide = boxCrisp(0.0285, 0.0295, 0.185, vm.darkMetal, 'pSlide', 10);
  put(slide, 0, 0.0335, -0.010);
  gun.add(slide);
  const topStrip = boxCrisp(0.016, 0.006, 0.185, vm.blueSteel, 'pTopStrip');
  put(topStrip, 0, 0.0492, -0.010);
  gun.add(topStrip);
  const notch = boxCrisp(0.0035, 0.011, 0.034, vm.cavity, 'pEject');
  put(notch, -0.0138, 0.040, -0.034);
  gun.add(notch);
  const serrPoses = [];
  for (let i = 0; i < 6; i++) {
    serrPoses.push([-0.0148, 0.0335, 0.048 + i * 0.0062, 0, 0, 0, 1, 1, 1]);
  }
  gun.add(instanced(new THREE.BoxGeometry(0.0018, 0.022, 0.0028), vm.cavity, serrPoses, 'pSerrations'));
  /* c22 fix 7 (pistol polish): the rear grooves alone read as paint — a
   * lit ridge now stands proud between each pair so the bank reads as
   * machined relief, plus a matching front bank near the muzzle. */
  const ridgePoses = [];
  for (let i = 0; i < 5; i++) {
    ridgePoses.push([-0.0151, 0.0335, 0.0511 + i * 0.0062, 0, 0, 0, 1, 1, 1]);
  }
  gun.add(instanced(new THREE.BoxGeometry(0.0016, 0.0195, 0.0026), vm.edge, ridgePoses, 'pSerrRidges'));
  const frontSerr = [];
  for (let i = 0; i < 4; i++) {
    frontSerr.push([-0.0148, 0.0335, -0.088 + i * 0.0058, 0, 0, 0, 1, 1, 1]);
  }
  gun.add(instanced(new THREE.BoxGeometry(0.0018, 0.018, 0.0028), vm.cavity, frontSerr, 'pSerrFront'));
  /* Ejection port depth: lit lower sill tilted up-camera + bolt-face hint
   * inside the dark slot (same recipe as the AK port). */
  const pSill = boxCrisp(0.0022, 0.0014, 0.032, vm.edge, 'pPortSill');
  put(pSill, -0.0147, 0.0347, -0.034, 0, 0, 0.55);
  gun.add(pSill);
  const pBolt = boxCrisp(0.0018, 0.0082, 0.014, vm.worn, 'pBoltFace');
  put(pBolt, -0.0139, 0.040, -0.026, 0, 0, -0.08);
  gun.add(pBolt);

  const frame = extrudeZYCrisp(pistolFrameHull(), 0.0255, vm.grip, 'pFrame', 0.0012);
  gun.add(frame);
  for (const sx of [1, -1]) {
    const panel = boxCrisp(0.0044, 0.055, 0.028, vm.bakelite, `pPanel${sx}`);
    put(panel, sx * 0.0142, -0.052, 0.042, 0.30, 0, 0);
    gun.add(panel);
  }
  /* Grip crosshatch on the camera-side panel (c22 fix 7): shallow groove
   * grid proud of the bakelite so the grip reads textured, not molded
   * smooth. Grouped so the grid inherits the panel's rake. */
  const gripTex = new THREE.Group();
  gripTex.name = 'pGripTex';
  gripTex.position.set(-0.0167, -0.052, 0.042);
  gripTex.rotation.x = 0.30;
  for (let i = 0; i < 3; i++) {
    const gh = boxCrisp(0.0008, 0.0020, 0.0250, vm.cavity, `pGripH${i}`);
    put(gh, 0, -0.0115 + i * 0.0115, 0);
    gripTex.add(gh);
  }
  for (let i = 0; i < 2; i++) {
    const gv = boxCrisp(0.0008, 0.0480, 0.0020, vm.cavity, `pGripV${i}`);
    put(gv, 0, 0, -0.0065 + i * 0.0130);
    gripTex.add(gv);
  }
  gun.add(gripTex);

  const brl = cyl(0.0068, 0.0068, 0.018, vm.park, 14, 'pBarrel');
  put(brl, 0, 0.0335, -0.108, Math.PI / 2, 0, 0);
  gun.add(brl);
  const bore = cyl(0.0032, 0.0032, 0.006, vm.cavity, 10, 'pBore');
  put(bore, 0, 0.0335, -0.114, Math.PI / 2, 0, 0);
  gun.add(bore);

  const fSight = boxCrisp(0.0032, 0.0068, 0.006, vm.park, 'pFrontSight');
  put(fSight, 0, 0.0546, -0.096);
  gun.add(fSight);
  const rSight = boxCrisp(0.0140, 0.0068, 0.006, vm.park, 'pRearSight');
  put(rSight, 0, 0.0546, 0.074);
  gun.add(rSight);
  const hammer = boxCrisp(0.0078, 0.010, 0.008, vm.park, 'pHammer');
  put(hammer, 0, 0.030, 0.084, 0.25, 0, 0);
  gun.add(hammer);

  const trigger = extrudeZY(triggerHull(), 0.005, vm.edge, 'pTrigger', 0.0003);
  put(trigger, 0, -0.012, 0.014);
  gun.add(trigger);
  gun.add(tube(
    new THREE.CubicBezierCurve3(
      new THREE.Vector3(0, -0.004, -0.016),
      new THREE.Vector3(0, -0.040, -0.014),
      new THREE.Vector3(0, -0.042, 0.022),
      new THREE.Vector3(0, -0.008, 0.026),
    ),
    16, 0.0030, 8, vm.grip, 'pGuard',
  ));

  const { flash } = makeFlash(WEAPONS.pistol.flash, 0, 0.0335, -0.130);
  gun.add(flash);

  const right = buildMitt(vm, 1);
  right.scale.setScalar(0.50);
  put(right, 0.011, -0.050, 0.050, 1.05, 0.18, 0.42);
  gun.add(right);
  const left = buildMitt(vm, -1);
  left.scale.setScalar(0.50);
  put(left, -0.013, -0.056, 0.044, 1.02, -0.22, -0.50);
  gun.add(left);

  return {
    gun, flash,
    hip: new THREE.Vector3(0.060, -0.130, -0.250),
    aim: new THREE.Vector3(0.024, -0.108, -0.235),
  };
}

/* AK-style trigger guard loop shared by the new builders. */
function tubeGuard(mat) {
  return tube(
    new THREE.CubicBezierCurve3(
      new THREE.Vector3(0, -0.002, 0.026),
      new THREE.Vector3(0, -0.038, 0.030),
      new THREE.Vector3(0, -0.042, 0.074),
      new THREE.Vector3(0, -0.004, 0.082),
    ),
    18, 0.0034, 8, mat, 'triggerGuard',
  );
}

export class Weapon {
  constructor(camera, mats) {
    this.camera = camera;
    this.root = new THREE.Group();
    this.root.name = 'viewmodel';
    camera.add(this.root);
    this._vm = makeViewmodel();
    this._sway = new THREE.Vector2();
    this._clock = 0;
    this._clickBuf = 0;
    this._dryClick = false;
    this._ads = 0;
    this._holdAds = false;
    this._cool = 0;
    this._cool0 = 1;
    this._flash = 0;
    this._muzzleWorld = new THREE.Vector3();
    /* Multi-rig: all four viewmodels built once at load, visibility-toggled
     * on switch (zero draw calls while hidden — no scene add/remove churn).
     * vmMats() runs ONCE and is shared so program cache keys stay stable. */
    const vm = vmMats(mats);
    this.rigs = {
      rifle: buildAK(vm),
      sniper: buildSniper(vm),
      shotgun: buildShotgun(vm),
      pistol: buildPistol(vm),
    };
    this.camera.layers.enable(1);
    for (const rig of Object.values(this.rigs)) {
      rig.gun.scale.setScalar(1.02);
      let hooked = false;
      rig.gun.traverse((o) => {
        o.frustumCulled = false;
        o.layers.set(1);
        if (o.renderOrder < 10) o.renderOrder = 10;
        if (o.isMesh) {
          ensureUV2(o.geometry);
          if (!hooked) {
            hooked = true;
            o.onBeforeRender = () => { this._syncFovZ(); };
          }
        }
      });
      rig.gun.visible = false;
      this.root.add(rig.gun);
    }
    this.id = 'rifle';
    this.gun = this.rigs.rifle.gun;
    this.muzzle = this.rigs.rifle.flash;
    this.hip = this.rigs.rifle.hip;
    this.aim = this.rigs.rifle.aim;
    this.gun.visible = true;
    /* One muzzle PointLight on the always-visible root. Intensity 0 when
     * idle (or while the viewmodel is hidden) so NUM_POINT_LIGHTS never
     * changes mid-combat. */
    this._muzzleLight = new THREE.PointLight(0xffc070, 0, 4, 2);
    this.root.add(this._muzzleLight);
    this.muzzleLight = this._muzzleLight;
    this._muzzleLocal = new THREE.Vector3();
    /* Switch state machine: lower current (0.3 s, drops + pitches down) →
     * swap visibility → raise next over WEAPONS[id].raise. */
    this._switch = null;
    this._reload = null;
    this._scopeStage = 0;
    this._rescope = 0;
    this._burst = 0;
    this._lastShot = -10;
    this.root.frustumCulled = false;
    this.root.renderOrder = 10;
    /* c19 fix 1+2 exposure redistribution: overall ~+0.5 stop, but moved
     * OFF the top-down dir (whose grazing hits made wood/cover top faces
     * the brightest px on the gun) and INTO the front-left fill + ambient
     * terms that light the camera-facing receiver flank. Dir also swung
     * forward so rear-facing chamfers at the stock junction fall off. */
    /* c20: light COLORS neutralized (fix 1). The 0xe8d4b0 fill at 2.30 was
     * the khaki multiplier — warm light x any grey albedo lands ochre. The
     * gunmetal is now real metal fed by a neutral-grey envMap, so the rig
     * only needs to carry the dielectrics (wood/glove/bakelite), which get
     * their warmth from their own albedo tints. */
    const wrap = new THREE.HemisphereLight(0xe6e4e0, 0x8a8478, 1.55);
    wrap.layers.set(1);
    const amb = new THREE.AmbientLight(0xd6d4d2, 0.95);
    amb.layers.set(1);
    const key = new THREE.PointLight(0xefece6, 1.30, 1.7, 1.4);
    key.position.set(0.12, 0.48, 0.04);
    key.layers.set(1);
    const dir = new THREE.DirectionalLight(0xeceae6, 0.46);
    dir.position.set(0.10, 1.15, -0.30);
    dir.layers.set(1);
    const fill = new THREE.PointLight(0xe2dfda, 2.05, 1.55, 1.45);
    fill.position.set(-0.26, 0.14, -0.34);
    fill.layers.set(1);
    /* Under-fill: the mag lives in the viewmodel's shadow well. A short
     * warm point below the receiver lifts bakelite without hitting the
     * receiver top (dir/key stay the same or slightly softer). */
    const under = new THREE.PointLight(0xf0d8b0, 2.20, 1.25, 1.35);
    under.position.set(0.02, -0.14, -0.02);
    under.layers.set(1);
    /* Support-hand fill: fingers sit in the guard's shadow well and were
     * missing a local lift (layer 1 is already on every vm mesh). */
    const hand = new THREE.PointLight(0xf4eee4, 2.55, 0.78, 1.45);
    hand.position.set(-0.06, 0.05, -0.15);
    hand.layers.set(1);
    this.root.add(wrap, amb, key, dir, fill, under, hand);
    this._wrap = wrap;
    this._amb = amb;
    this._key = key;
    this._dir = dir;
    this._fill = fill;
    this._under = under;
    this._hand = hand;
    this._placedFov = CAMERA.FOV;
    /* Kick/sway are LOCAL to this camera-parented root so the rig inherits
     * camera pitch/yaw. YXZ matches the camera so a pitch kick stays a
     * pitch kick after look-up/look-down (XYZ was composing a world-tilt
     * that read as "gun stays vertical"). */
    this.root.rotation.order = 'YXZ';
    this._applyPose(0);
    eventBus.on(Events.PLAYER_DIE, () => this._forceUnscope());
    eventBus.on(Events.GAME_OVER, () => this._forceUnscope());
  }

  get cfg() { return WEAPONS[this.id]; }

  /** Muzzle tip in WORLD space. The viewmodel is camera-parented (FOV-local);
   * getWorldPosition walks the camera→root→gun→flash chain so Combat never
   * treats a camera-space offset as a world point. */
  muzzleWorld(out) {
    const v = out || this._muzzleWorld;
    if (this.root.parent !== this.camera) this.camera.add(this.root);
    this.camera.updateMatrixWorld(true);
    this.root.updateMatrixWorld(true);
    this.muzzle.updateWorldMatrix(true, false);
    this.muzzle.getWorldPosition(v);
    /* Stale matrixWorld used to return the flash's local pos as world
     * (near the origin). A tracer from there to the wall reads as a
     * vertical/diagonal streak. Fall back to a camera-local offset. */
    if (v.distanceToSquared(this.camera.position) > 64) {
      _muzzleRight.setFromMatrixColumn(this.camera.matrixWorld, 0);
      _muzzleUp.setFromMatrixColumn(this.camera.matrixWorld, 1);
      this.camera.getWorldDirection(_muzzleFwd);
      v.copy(this.camera.position)
        .addScaledVector(_muzzleRight, 0.12)
        .addScaledVector(_muzzleUp, -0.08)
        .addScaledVector(_muzzleFwd, 0.45);
    }
    return v;
  }

  _fovK() {
    const ref = CAMERA.FOV;
    const fov = THREE.MathUtils.clamp(this.camera.fov || ref, 24, 110);
    return Math.tan(THREE.MathUtils.degToRad(ref * 0.5))
      / Math.tan(THREE.MathUtils.degToRad(fov * 0.5));
  }

  _applyPose(t) {
    const k = this._fovK();
    this.root.position.x = THREE.MathUtils.lerp(this.hip.x, this.aim.x, t);
    this.root.position.y = THREE.MathUtils.lerp(this.hip.y, this.aim.y, t);
    this.root.position.z = THREE.MathUtils.lerp(this.hip.z, this.aim.z, t) * k;
    /* c21 handoff: flatter yaw/pitch so the muzzle stops climbing into the
     * crosshair (0.12/0.36 → 0.05/0.30 hip; 0.08/0.24 → 0.03/0.22 ads). */
    this.gun.rotation.z = THREE.MathUtils.lerp(-0.04, -0.02, t);
    this.gun.rotation.x = THREE.MathUtils.lerp(0.05, 0.03, t);
    this.gun.rotation.y = THREE.MathUtils.lerp(0.30, 0.22, t);
    this._placedFov = THREE.MathUtils.clamp(this.camera.fov || CAMERA.FOV, 24, 110);
  }

  _syncFovZ() {
    const fov = THREE.MathUtils.clamp(this.camera.fov || CAMERA.FOV, 24, 110);
    if (Math.abs(fov - this._placedFov) < 0.04) return;
    const ref = CAMERA.FOV;
    const kNew = Math.tan(THREE.MathUtils.degToRad(ref * 0.5))
      / Math.tan(THREE.MathUtils.degToRad(fov * 0.5));
    const kOld = Math.tan(THREE.MathUtils.degToRad(ref * 0.5))
      / Math.tan(THREE.MathUtils.degToRad(this._placedFov * 0.5));
    this.root.position.z *= kNew / kOld;
    this._placedFov = fov;
  }

  _syncLights(t) {
    /* ADS targets scaled with the c19 hip raise so the bakelite mag keeps
     * its gradient in the ads crop instead of dropping to ambient grey. */
    this._wrap.intensity = THREE.MathUtils.lerp(1.55, 1.18, t);
    this._amb.intensity = THREE.MathUtils.lerp(0.95, 0.62, t);
    this._key.intensity = THREE.MathUtils.lerp(1.30, 0.92, t);
    this._dir.intensity = THREE.MathUtils.lerp(0.46, 0.34, t);
    this._fill.intensity = THREE.MathUtils.lerp(2.05, 1.30, t);
    this._under.intensity = THREE.MathUtils.lerp(1.85, 2.25, t);
    this._hand.intensity = THREE.MathUtils.lerp(0.62, 0.48, t);
  }

  /* Debug/tools compat: Game.setAds(true) = hold-ADS stage 0 of the active
   * weapon (rifle by default — preserves the `ads` stop's framing). */
  setAds(on) {
    this._holdAds = !!on;
    this._ads = on ? 1 : 0;
    gameState.player.ads = !!on;
    gameState.player.adsEase = on ? 1 : 0;
    gameState.player.fovTarget = on ? this.cfg.zoom.stages[0] : 0;
    this._applyPose(this._ads);
    this._syncLights(this._ads);
  }

  /** Drive sniper scope stages directly (tools/pickup-free debugging). */
  setScope(stage) {
    const n = THREE.MathUtils.clamp(stage | 0, 0, this.cfg.zoom.stages.length);
    this._setStage(n);
  }

  _setStage(n) {
    this._scopeStage = n;
    gameState.player.scopeStage = n;
    gameState.player.scoped = n > 0;
    if (this.cfg.zoom.stages.length > 1) {
      gameState.player.ads = n > 0;
      gameState.player.adsEase = n > 0 ? 1 : 0;
      gameState.player.fovTarget = n > 0 ? this.cfg.zoom.stages[n - 1] : 0;
    }
    if (this.cfg.zoom.hideViewmodel) {
      this.gun.visible = !(n > 0);
    }
  }

  /** Death / sprint / jump / switch: overlay, FOV and viewmodel must not stick. */
  _forceUnscope() {
    this._rescope = 0;
    this._holdAds = false;
    this._ads = 0;
    this._setStage(0);
    gameState.player.ads = false;
    gameState.player.adsEase = 0;
    gameState.player.fovTarget = 0;
    gameState.player.scoped = false;
    gameState.player.scopeStage = 0;
    if (this.gun) this.gun.visible = true;
  }

  /** Instant equip — pickups, restart and the g.equip() debug API. */
  equip(id, instant = true) {
    if (!WEAPONS[id]) return;
    if (!instant) { this.requestSwitch(id); return; }
    this._cancelReload();
    this._switch = null;
    this._setStage(0);
    this._holdAds = false;
    this._ads = 0;
    this._burst = 0;
    this._lastShot = -10;
    this._clickBuf = 0;
    gameState.player.bloom = 0;
    if (id !== gameState.activeWeapon) gameState.lastWeapon = gameState.activeWeapon;
    this.id = id;
    gameState.activeWeapon = id;
    this._bindRig();
    gameState.player.ads = false;
    gameState.player.fovTarget = 0;
    this._applyPose(0);
    this._syncLights(0);
    eventBus.emit(Events.WEAPON_SWITCH, { id });
  }

  _bindRig() {
    for (const [rid, rig] of Object.entries(this.rigs)) rig.gun.visible = rid === this.id;
    const rig = this.rigs[this.id];
    this.gun = rig.gun;
    this.muzzle = rig.flash;
    this.muzzleLight = this._muzzleLight;
    this.hip = rig.hip;
    this.aim = rig.aim;
    this._pump = rig.pump || null;
    this.muzzle.material.opacity = 0;
    this.muzzleLight.intensity = 0;
  }

  /** Slot 2 cycles the two heavies. From a non-heavy, restore the last
   * heavy or default to the Longshot. */
  _nextHeavy() {
    const w = gameState.weapons;
    if (this.id === 'sniper' && w.shotgun?.owned) return 'shotgun';
    if (this.id === 'shotgun' && w.sniper?.owned) return 'sniper';
    if (gameState.lastWeapon === 'shotgun' && w.shotgun?.owned) return 'shotgun';
    if (w.sniper?.owned) return 'sniper';
    if (w.shotgun?.owned) return 'shotgun';
    return null;
  }

  requestSwitch(id) {
    if (!WEAPONS[id] || id === this.id) return;
    if (!gameState.weapons[id]?.owned) return;
    if (this._switch && this._switch.next === id) return;
    this._cancelReload();          // switching cancels a reload (CS2)
    this._forceUnscope();
    this._switch = { phase: 'lower', t: 0, dur: 0.3, next: id };
  }

  _switchUpdate(dt) {
    const s = this._switch;
    if (!s) return 0;
    s.t += dt;
    if (s.phase === 'lower') {
      if (s.t >= s.dur) {
        gameState.lastWeapon = this.id;
        this.id = s.next;
        gameState.activeWeapon = s.next;
        this._burst = 0;
        this._lastShot = -10;
        gameState.player.bloom = 0;
        this._bindRig();
        s.phase = 'raise';
        s.dur = this.cfg.raise;
        s.t = 0;
        eventBus.emit(Events.WEAPON_SWITCH, { id: this.id });
        return 1;
      }
      return Math.min(1, s.t / s.dur);
    }
    if (s.t >= s.dur) {
      this._switch = null;
      return 0;
    }
    return 1 - Math.min(1, s.t / s.dur);
  }

  update(dt, input, moving) {
    const cfg = this.cfg;
    const w = gameState.weapon;

    // ── switching ──
    if (input.slot1) this.requestSwitch('rifle');
    if (input.slot2) {
      const next = this._nextHeavy();
      if (next) this.requestSwitch(next);
    }
    if (input.slot3) this.requestSwitch('pistol');
    if (input.swap && gameState.weapons[gameState.lastWeapon]?.owned) {
      this.requestSwitch(gameState.lastWeapon);
    }
    const lowerK = this._switchUpdate(dt);
    const switching = !!this._switch;

    // ── zoom: click-to-cycle scope stages (sniper) vs hold-ADS ──
    const stages = cfg.zoom.stages;
    if (this._scopeStage > 0) {
      const wantSprint = input.sprint && input.moveZ > 0 && !input.crouch;
      if (wantSprint || input.jump || !gameState.player.alive) {
        this._forceUnscope();
      }
    }
    if (stages.length > 1) {
      if (input.adsDown && !switching && !w.reloading && gameState.player.alive) {
        this._setStage((this._scopeStage + 1) % (stages.length + 1));
        this._rescope = 0;
      }
      gameState.player.fovTarget = this._scopeStage > 0 ? stages[this._scopeStage - 1] : 0;
      gameState.player.ads = this._scopeStage > 0;
    } else {
      const wantAds = (input.ads || this._holdAds) && !switching && gameState.player.alive;
      /* c21 handoff: ADS blend response 14 → 18 (snappier settle). */
      this._ads += ((wantAds ? 1 : 0) - this._ads) * (1 - Math.exp(-18 * dt));
      gameState.player.ads = this._ads > 0.55;
      gameState.player.fovTarget = wantAds ? stages[0] : 0;
      if (this._scopeStage) this._setStage(0);
    }

    // ── reload timers (dt-driven so switching can cancel cleanly) ──
    if (this._reload) {
      this._reload.t -= dt;
      if (this._reload.t <= 0) this._reloadStep();
    }

    // ── cooldown / vfx decay ──
    this._clock += dt;
    this._cool = Math.max(0, this._cool - dt);
    const rec = cfg.spread.recover || 0;
    if (rec > 0 && gameState.player.bloom > 0) {
      gameState.player.bloom = Math.max(0, gameState.player.bloom - rec * dt);
    }
    const adsEase = stages.length > 1 ? (this._scopeStage > 0 ? 1 : 0) : this._ads;
    gameState.player.adsEase = adsEase;
    gameState.player.spread = currentSpread(cfg, gameState.player.bloom, gameState.player);
    stepViewmodel(this._vm, dt);
    this._flash = Math.max(0, this._flash - dt * 18);
    this.muzzle.material.opacity = this._flash;
    /* Hidden viewmodel (sniper scope) must not drop the light from the
     * graph — keep it at intensity 0 so the world program stays compiled. */
    this.muzzleLight.intensity = this.gun.visible
      ? this._flash * 18 * (this.id === 'shotgun' ? 1.5 : 1)
      : 0;
    this.muzzle.getWorldPosition(this._muzzleLocal);
    this.root.worldToLocal(this._muzzleLocal);
    this.muzzleLight.position.copy(this._muzzleLocal);

    // Sniper re-scope after the bolt cycle (CS2 rescope).
    if (this._rescope && this._cool <= 0 && !switching && !w.reloading) {
      this._setStage(this._rescope);
      this._rescope = 0;
    }

    /* dt-correct look sway (autopsy fix 9): the old `* 0.12` per-frame lerp
     * grew ~25% at 48 fps vs 60. lookX is per-frame pixels, so normalize to
     * a 60 Hz-equivalent delta (mouse *velocity*) — amplitude and response
     * are now identical at 60 and 165 Hz. Rate 7.5 == the old 0.12@60fps. */
    const swayK = 1 - Math.exp(-7.5 * dt);
    const swayN = dt > 0 ? 1 / (60 * dt) : 1;
    this._sway.x += (input.lookX * swayN * 0.0004 - this._sway.x) * swayK;
    this._sway.y += (-input.lookY * swayN * 0.0004 - this._sway.y) * swayK;

    const t = stages.length > 1 ? 0 : this._ads;
    this._syncLights(t);
    this._applyPose(t);
    /* 5-DOF viewmodel kick is additive on the posed root — hip/aim vectors
     * stay put and the spring returns here exactly when pz/py/rx settle. */
    const vm = this._vm;
    this.root.position.y += vm.py * 0.5;
    this.root.position.z += vm.pz;
    const now = performance.now();
    const idle = Math.sin(now * 0.0015) * 0.0018 * (1 - t * 0.7);
    this.root.position.y += idle;
    this.root.position.x += Math.cos(now * 0.0011) * 0.0012 * (1 - t * 0.7);
    /* Local kick only — parent camera already carries look pitch. Clamp so
     * a shotgun impulse can't leave the barrel parked at the sky. */
    this.root.rotation.set(
      THREE.MathUtils.clamp(vm.rx * 0.6 + this._sway.y, -0.28, 0.28),
      THREE.MathUtils.clamp(vm.ry + this._sway.x, -0.22, 0.22),
      THREE.MathUtils.clamp(vm.rz, -0.22, 0.22),
    );
    if (moving) {
      const bob = Math.sin(now * 0.012) * 0.006 * (1 - t);
      this.root.position.y += bob;
      this.root.position.x += Math.cos(now * 0.01) * 0.004 * (1 - t);
    }
    // Switch lower/raise: root drops 0.14 and pitches down ~20°.
    if (lowerK > 0) {
      this.root.position.y -= 0.14 * lowerK;
      this.root.rotation.x -= 0.35 * lowerK;
    }
    // Shotgun pump: sleeve (with the support mitt) slides +z and back.
    if (this._pump && this._cool > 0 && this._cool0 > 0.2) {
      const k = 1 - this._cool / this._cool0;
      const s = Math.sin(Math.PI * THREE.MathUtils.clamp((k - 0.18) / 0.60, 0, 1));
      this._pump.position.z = -0.250 + 0.060 * s;
    } else if (this._pump) {
      this._pump.position.z = -0.250;
    }

    if (input.reload && !switching) this.reload();
    // Shell-by-shell reload is interruptible by firing (plan §1).
    if (input.fireDown && this._reload?.style === 'shell' && w.mag > 0) {
      this._cancelReload();
    }
    if (!input.fire) this._dryClick = false;
    if (input.fireDown && (this._cool > 0 || w.reloading || switching)) {
      // Sniper bolt is 1.2 s; a 0.2 s buffer died mid-cycle and the click
      // vanished. Hold the buffer through the remaining cool so the shot
      // leaves after rescope — still a real camera ray, never a dry fire.
      this._clickBuf = this.id === 'sniper'
        ? Math.max(this._cool + 0.05, 0.2)
        : 0.2;
    }
    if (!switching) {
      const wantFire = cfg.auto ? input.fire : input.fireDown;
      if (wantFire || this._clickBuf > 0) {
        if (this.tryFire()) this._clickBuf = 0;
      }
    }
    if (this._clickBuf > 0) this._clickBuf = Math.max(0, this._clickBuf - dt);
  }

  tryFire() {
    const cfg = this.cfg;
    const w = gameState.weapon;
    if (this._switch || w.reloading || this._cool > 0) return false;
    if (w.mag <= 0) {
      if (!this._dryClick) {
        eventBus.emit(Events.WEAPON_EMPTY);
        this._dryClick = true;
      }
      if (w.reserve > 0) this.reload();
      return false;
    }
    w.mag -= 1;
    this._cool0 = 60 / cfg.rpm;
    this._cool = this._cool0;
    this._flash = 1;
    this._burst = (this._clock - this._lastShot) < BURST_IDLE ? this._burst + 1 : 1;
    this._lastShot = this._clock;
    impulseViewmodel(this._vm, cfg.vmKick ?? 0.035, cfg.vmRot ?? 0.055);
    const rec = recoilImpulse(cfg, this._burst);
    const scopedShot = this._scopeStage > 0 || gameState.player.scoped || gameState.player.ads;
    this.muzzleWorld(this._muzzleWorld);
    eventBus.emit(Events.WEAPON_FIRE, {
      id: this.id,
      ads: scopedShot,
      recoilVy: rec.vy,
      recoilVx: rec.vx,
      recoilY: rec.vy,
      recoilX: rec.vx,
      fovKick: cfg.fovKick || 0,
      burst: this._burst,
      muzzle: this._muzzleWorld,
    });
    // Unscope AFTER the shot so Combat still uses the scoped cone.
    if (cfg.recoil.unscopeOnFire && this._scopeStage > 0) {
      this._rescope = this._scopeStage;
      this._setStage(0);
    }
    // Bloom grows after the shot so first-shot accuracy stays at base hip/ADS.
    const add = cfg.spread.perShot || 0;
    if (add) {
      const cap = cfg.spread.max ?? add;
      gameState.player.bloom = Math.min(cap, (gameState.player.bloom || 0) + add);
    }
    return true;
  }

  reload() {
    const cfg = this.cfg;
    const w = gameState.weapon;
    if (this._switch || w.reloading || w.mag >= cfg.mag || w.reserve <= 0) return;
    w.reloading = true;
    if (this._scopeStage) this._setStage(0);
    this._rescope = 0;
    this._reload = { t: cfg.reload, style: cfg.reloadStyle, id: this.id };
    eventBus.emit(Events.WEAPON_RELOAD);
  }

  _reloadStep() {
    const cfg = WEAPONS[this._reload.id];
    const w = gameState.weapons[this._reload.id];
    if (this._reload.style === 'shell') {
      w.mag += 1;
      w.reserve -= 1;
      if (w.mag < cfg.mag && w.reserve > 0) {
        this._reload.t = cfg.reload;      // next shell
        eventBus.emit(Events.WEAPON_RELOAD);
        return;
      }
    } else {
      const take = Math.min(cfg.mag - w.mag, w.reserve);
      w.mag += take;
      w.reserve -= take;
    }
    w.reloading = false;
    this._reload = null;
    gameState.player.bloom = 0;
  }

  _cancelReload() {
    if (!this._reload) return;
    gameState.weapons[this._reload.id].reloading = false;
    this._reload = null;
  }
}
