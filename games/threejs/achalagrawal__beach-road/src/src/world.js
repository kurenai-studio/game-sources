// Endless world built from chunks that stream in ahead of the car and drop off behind.
// Placement depends only on the chunk index, so every look shows the same place.
import * as THREE from 'three';
import { rng, vnoise, hash2, smoothstep } from './noise.js';
import { roadX, roadXd, zInfo, heightAt, terrainHeight, sideAngle, ROAD_HALF, EDGE, CHUNK_LEN } from './road.js';
import { BIOMES, BIOME_IDS } from './biomes.js';

const AHEAD = 10, BEHIND = 2;
const ROWS = CHUNK_LEN / 4 + 1;
const ROAD_ROWS = CHUNK_LEN / 2 + 1;

// Lateral sample positions: dense near the road, coarse far away.
const D_SAMPLES = (() => {
  const out = [];
  let d = -600;
  while (d < -320) { out.push(d); d += 40; }
  while (d < -60) { out.push(d); d += 16; }
  while (d < -14) { out.push(d); d += 5; }
  while (d < 14) { out.push(d); d += 2; }
  while (d < 40) { out.push(d); d += 3; }
  while (d <= 140) { out.push(d); d += 6; }
  return out;
})();

function buildPalettes(style) {
  const out = {};
  for (const id of BIOME_IDS) {
    const tint = BIOMES[id].tint, p = {};
    for (const [k, v] of Object.entries(style.terrain)) {
      const c = new THREE.Color(v);
      if (tint[k] && style.material !== 'neon') c.offsetHSL(...tint[k]);
      p[k] = c;
    }
    out[id] = p;
  }
  return out;
}

function terrainColor(d, h, slope, x, z, I, P, out) {
  if (d > EDGE) {
    const s0 = EDGE + I.m.shape.shoulder;
    if (d < s0 + 0.5) out.copy(P.shoulder);
    else if (h < -0.5) out.copy(P.seabed);
    else if (h < 0.3) out.copy(P.wetSand);
    else if (h > 3 && slope > 0.8) out.copy(P.grass).lerp(P.grass2, 0.4);
    else out.copy(P.sand);
    if (h > 0.6 && slope < 0.8) out.copy(P.rock);
  } else if (d > -EDGE) {
    out.copy(P.shoulder);
  } else {
    const n = vnoise(x * 0.02, z * 0.02);
    out.copy(P.grass).lerp(P.grass2, smoothstep(0.3, 0.7, n));
    out.lerp(P.rock, Math.max(smoothstep(24, 40, h - I.ry + n * 12), smoothstep(0.78, 0.6, slope)));
  }
  return out.multiplyScalar(0.95 + 0.1 * hash2(Math.round(x * 2), Math.round(z * 2)));
}

function terrainGeometry(z0, palettes) {
  const cols = D_SAMPLES.length, n = ROWS * cols;
  const pos = new Float32Array(n * 3), nor = new Float32Array(n * 3), col = new Float32Array(n * 3);
  const c = new THREE.Color(), nv = new THREE.Vector3(), I = {};
  const P = {};
  for (let r = 0; r < ROWS; r++) {
    const z = z0 - r * 4;
    zInfo(z, I);
    const A = palettes[I.m.a], B = I.m.b ? palettes[I.m.b] : A;
    for (const k in A) (P[k] ??= new THREE.Color()).copy(A[k]).lerp(B[k], I.m.w);
    for (let k = 0; k < cols; k++) {
      const d = D_SAMPLES[k], x = I.rx + d, i = (r * cols + k) * 3;
      let h = heightAt(d, x, z, I);
      nv.set(
        terrainHeight(x - 1, z) - terrainHeight(x + 1, z), 2,
        terrainHeight(x, z - 1) - terrainHeight(x, z + 1),
      ).normalize();
      terrainColor(d, h, nv.y, x, z, I, P, c);
      if (Math.abs(d) < ROAD_HALF) h -= 0.25; // tuck under the asphalt, no z-fighting
      pos[i] = x; pos[i + 1] = h; pos[i + 2] = z;
      nor[i] = nv.x; nor[i + 1] = nv.y; nor[i + 2] = nv.z;
      col[i] = c.r; col[i + 1] = c.g; col[i + 2] = c.b;
    }
  }
  const idx = [];
  for (let r = 0; r < ROWS - 1; r++) {
    for (let k = 0; k < cols - 1; k++) {
      const a = r * cols + k, b = a + 1, cc = a + cols, dd = cc + 1;
      idx.push(a, b, cc, b, dd, cc);
    }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  g.setAttribute('normal', new THREE.BufferAttribute(nor, 3));
  g.setAttribute('color', new THREE.BufferAttribute(col, 3));
  g.setIndex(idx);
  g.computeBoundingSphere();
  return g;
}

function roadGeometry(z0) {
  const pos = [], uv = [], nor = [], idx = [], I = {};
  for (let r = 0; r < ROAD_ROWS; r++) {
    const z = z0 - r * 2, v = (r * 2) / 10;
    zInfo(z, I);
    pos.push(I.rx - ROAD_HALF, I.ry + 0.03, z, I.rx + ROAD_HALF, I.ry + 0.03, z);
    uv.push(0, v, 1, v);
    nor.push(0, 1, 0, 0, 1, 0);
    if (r < ROAD_ROWS - 1) {
      const a = r * 2;
      idx.push(a, a + 1, a + 2, a + 1, a + 3, a + 2);
    }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute('normal', new THREE.Float32BufferAttribute(nor, 3));
  g.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeBoundingSphere();
  return g;
}

const _q = new THREE.Quaternion(), _e = new THREE.Euler(), _p = new THREE.Vector3(), _s = new THREE.Vector3();
function T(x, y, z, sx, sy = sx, sz = sx, rx = 0, ry = 0, rz = 0) {
  return new THREE.Matrix4().compose(_p.set(x, y, z), _q.setFromEuler(_e.set(rx, ry, rz)), _s.set(sx, sy, sz));
}

// Ground is flat enough for a building when the corners of its footprint stay within `tol`.
function flatSpot(x, z, r, tol) {
  let lo = Infinity, hi = -Infinity;
  for (const [dx, dz] of [[-r, -r], [r, -r], [-r, r], [r, r], [0, 0]]) {
    const h = terrainHeight(x + dx, z + dz);
    lo = Math.min(lo, h);
    hi = Math.max(hi, h);
  }
  return hi - lo < tol ? lo : null;
}

export class World {
  constructor(scene, style, assets) {
    this.scene = scene;
    this.assets = assets;
    this.chunks = new Map();
    this.palettes = buildPalettes(style);
  }

  // dir: -1 when travelling toward -z, +1 toward +z (keeps the generated window ahead of the car).
  update(z, dir, time, dt, budget = 1) {
    const ci = Math.floor(-z / CHUNK_LEN);
    const lo = dir < 0 ? ci - BEHIND : ci - AHEAD, hi = dir < 0 ? ci + AHEAD : ci + BEHIND;
    for (const [i, ch] of this.chunks) {
      if (i < lo - 1 || i > hi + 1) { this.disposeChunk(ch); this.chunks.delete(i); }
    }
    let built = 0;
    for (let k = 0; k <= AHEAD && built < budget; k++) {
      for (const i of dir < 0 ? [ci + k, ci - k] : [ci - k, ci + k]) {
        if (i >= lo && i <= hi && !this.chunks.has(i) && built < budget) {
          this.chunks.set(i, this.buildChunk(i));
          built++;
        }
      }
    }
    for (const ch of this.chunks.values()) {
      for (const b of ch.boats) {
        b.mesh.position.y = Math.sin(time * 0.8 + b.phase) * 0.25 - 0.1;
        b.mesh.rotation.z = Math.sin(time * 0.6 + b.phase) * 0.06;
        b.mesh.rotation.x = Math.sin(time * 0.5 + b.phase * 1.3) * 0.04;
      }
      for (const r of ch.rotors) r.rotation.z += dt * r.userData.spin;
      for (const b of ch.beams) b.rotation.y += dt * 0.9;
    }
  }

  buildChunk(i) {
    const { geoms, mats, outlineGeoms } = this.assets;
    const group = new THREE.Group();
    const z0 = -i * CHUNK_LEN;

    const terrain = new THREE.Mesh(terrainGeometry(z0, this.palettes), mats.terrain);
    terrain.receiveShadow = true;
    const road = new THREE.Mesh(roadGeometry(z0), mats.road);
    road.receiveShadow = true;
    group.add(terrain, road);

    const r = rng(i * 7919 + 13);
    const lists = new Map(); // geometry key -> matrices
    const add = (key, m) => { if (!lists.has(key)) lists.set(key, []); lists.get(key).push(m); };
    const boats = [], rotors = [], beams = [];
    const I = {};

    const mixC = zInfo(z0 - CHUNK_LEN / 2, {}).m;
    const parts = [[mixC.a, 1 - mixC.w]];
    if (mixC.b) parts.push([mixC.b, mixC.w]);

    for (const [biome, weight] of parts) {
      for (const [type, zone, rate] of BIOMES[biome].scatter) {
        const want = rate * weight;
        let n = Math.floor(want) + (r() < want % 1 ? 1 : 0);
        if (type === 'post' || type === 'lamp' || type === 'fence') n = n > 0 ? 1 : 0;
        for (let k = 0; k < n; k++) this.place(type, zone, rate, z0, r, I, add, { group, boats, rotors, beams });
      }
    }

    const instanced = [];
    for (const [key, list] of lists) {
      const g = geoms[key];
      if (!g) continue;
      const base = g.base ?? g, glow = g.glow ?? null;
      const mat = key === 'post' ? mats.post : mats.flora;
      const m = new THREE.InstancedMesh(base, mat, list.length);
      list.forEach((t, j) => m.setMatrixAt(j, t));
      m.instanceMatrix.needsUpdate = true;
      m.castShadow = key !== 'island';
      m.receiveShadow = key.startsWith('house') || key === 'pier';
      m.computeBoundingSphere();
      group.add(m);
      instanced.push(m);
      if (glow) {
        const gm = new THREE.InstancedMesh(glow, mats.glow, list.length);
        gm.instanceMatrix = m.instanceMatrix;
        gm.computeBoundingSphere();
        group.add(gm);
        instanced.push(gm);
      }
      if (outlineGeoms && outlineGeoms[key]) {
        const o = new THREE.InstancedMesh(outlineGeoms[key], mats.outline, list.length);
        o.instanceMatrix = m.instanceMatrix;
        o.computeBoundingSphere();
        group.add(o);
        instanced.push(o);
      }
    }

    this.scene.add(group);
    return { group, terrain, road, instanced, boats, rotors, beams };
  }

  place(type, zone, rate, z0, r, I, add, out) {
    const { geoms, mats, outlineGeoms } = this.assets;
    const z = z0 - r() * CHUNK_LEN;
    zInfo(z, I);
    const S = I.m.shape, s0 = EDGE + S.shoulder;
    const rnd = [r(), r(), r(), r()]; // fixed draw count keeps placement stable across looks
    const yaw = rnd[1] * Math.PI * 2;

    let d;
    switch (zone) {
      case 'beach': d = s0 + 1.5 + rnd[0] * Math.max(I.sd - s0 - 4.5, 0); break;
      case 'roadside': d = -(EDGE + 1.5 + rnd[0] * 8); break;
      case 'hillsNear': d = -(EDGE + 6 + rnd[0] * 40); break;
      case 'hills': d = -(10 + S.terrace + rnd[0] * rnd[0] * 320); break;
      case 'hillsMid': d = -(45 + rnd[0] * 110); break;
      case 'terrace': d = -(EDGE + 6 + rnd[0] * Math.max(S.terrace - 12, 0)); break;
      case 'shore': d = I.sd - 4 + rnd[0] * 9; break;
      case 'sea': d = I.sd + 30 + rnd[0] * 230; break;
      case 'harbour': d = I.sd + 18 + rnd[0] * 90; break;
      case 'far': d = 380 + rnd[0] * 300; break;
      default: d = 0;
    }
    const x = I.rx + d;
    const h = () => heightAt(d, x, z, I);

    switch (type) {
      case 'palm': case 'tree': case 'pine': case 'cypress': case 'olive': case 'bush':
      case 'grassTuft': case 'flowers': case 'cactus': {
        const y = h();
        if (zone === 'beach' && (y < 0.4 || y < I.ry - 3)) return; // no trees on cliff faces
        if (zone === 'hills' && y - I.ry > 38 && type !== 'pine') return;
        const big = zone === 'hills' ? 1 + -d / 220 : 1;
        const s = (0.8 + rnd[2] * 0.7) * big;
        const ry = type === 'palm' ? (d > 0 ? (rnd[1] - 0.5) * 1.4 : Math.PI + (rnd[1] - 0.5) * 1.5) : yaw;
        add(type, T(x, y - 0.15, z, s, s, s, 0, ry));
        return;
      }
      case 'rock': {
        const s = (0.6 + rnd[2] * 1.5) * (1 + S.rough);
        add('rock', T(x, h() - 0.25, z, s, s, s, rnd[3] * 3, yaw, rnd[0] * 3));
        return;
      }
      case 'umbrella': case 'beachHut': {
        const y = h();
        if (y < 0.5 || y > I.ry - 0.8) return;
        const variants = type === 'umbrella' ? 3 : 4;
        add(`${type}${Math.floor(rnd[2] * variants)}`, T(x, y - 0.05, z, 1, 1, 1, 0, sideAngle(z) + Math.PI + (rnd[3] - 0.5) * 0.6));
        return;
      }
      case 'house': {
        const ground = flatSpot(x, z, 5, zone === 'terrace' ? 2.2 : 1.4);
        if (ground === null) return;
        add(`house${Math.floor(rnd[2] * 6)}`, T(x, ground - 0.3, z, 1, 1, 1, 0, sideAngle(z) + (rnd[3] - 0.5) * 0.25));
        return;
      }
      case 'sign':
        add('sign', T(x, h(), z, 1, 1, 1, 0, sideAngle(z)));
        return;
      case 'post':
        for (let k = 0; k < CHUNK_LEN / (10 / rate); k++) {
          const pz = z0 - 5 - k * (10 / rate);
          zInfo(pz, I);
          add('post', T(I.rx + 6.0, I.ry, pz, 1));
        }
        return;
      case 'lamp':
        for (let k = 0; k < CHUNK_LEN / 32; k++) {
          const pz = z0 - 8 - k * 32, side = k % 2 ? 1 : -1;
          zInfo(pz, I);
          add('lamp', T(I.rx + side * (EDGE + 0.4), I.ry, pz, 1, 1, 1, 0, sideAngle(pz) + (side > 0 ? Math.PI : 0)));
        }
        return;
      case 'fence':
        for (let k = 0; k < CHUNK_LEN / 4; k++) {
          const pz = z0 - 2 - k * 4;
          zInfo(pz, I);
          const fx = I.rx - (EDGE + 3);
          add('fence', T(fx, heightAt(-(EDGE + 3), fx, pz, I), pz, 1, 1, 1, 0, Math.atan(roadXd(pz))));
        }
        return;
      case 'island':
        add('island', T(x, -1.5, z, 60 + rnd[2] * 90, 18 + rnd[3] * 45, (60 + rnd[2] * 90) * 0.8, 0, yaw));
        return;
      case 'boat': {
        const mesh = new THREE.Mesh(geoms.boat, mats.floraDouble);
        mesh.position.set(x, 0, z);
        mesh.rotation.y = yaw;
        mesh.castShadow = true;
        if (outlineGeoms) mesh.add(new THREE.Mesh(outlineGeoms.boat, mats.outline));
        out.group.add(mesh);
        out.boats.push({ mesh, phase: rnd[2] * 10 });
        return;
      }
      case 'pier': {
        const start = I.sd - 3, segs = 4 + Math.floor(rnd[2] * 4);
        for (let k = 0; k < segs; k++) add('pier', T(I.rx + start + k * 8, 0, z, 1));
        return;
      }
      case 'lighthouse': {
        const lx = I.rx + I.sd + 7, lh = geoms.lighthouse;
        if (!lh) return;
        add('rock', T(lx, -0.8, z, 4.5, 2.2, 4.5, 0, yaw));
        add('lighthouse', T(lx, 0.9, z, 1, 1, 1, 0, yaw));
        const beam = new THREE.Mesh(this.assets.beamGeometry, mats.beam);
        beam.position.set(lx, 0.9 + (lh.lanternHeight ?? 18), z);
        out.group.add(beam);
        out.beams.push(beam);
        return;
      }
      case 'turbine': {
        const tb = geoms.turbine;
        if (!tb) return;
        const y = h(), face = 0.6;
        add('turbine', T(x, y - 0.5, z, 1, 1, 1, 0, face));
        const rotor = new THREE.Mesh(tb.rotor, mats.flora);
        const off = (tb.hubOffset ?? new THREE.Vector3(0, tb.hubHeight ?? 40, 0)).clone().applyAxisAngle(new THREE.Vector3(0, 1, 0), face);
        rotor.position.set(x + off.x, y - 0.5 + off.y, z + off.z);
        rotor.rotation.set(0, face, rnd[3] * 6);
        rotor.userData.spin = 0.5 + rnd[2] * 0.4;
        rotor.castShadow = true;
        out.group.add(rotor);
        out.rotors.push(rotor);
        return;
      }
    }
  }

  disposeChunk(ch) {
    this.scene.remove(ch.group);
    ch.terrain.geometry.dispose();
    ch.road.geometry.dispose();
    for (const m of ch.instanced) m.dispose();
  }

  dispose() {
    for (const ch of this.chunks.values()) this.disposeChunk(ch);
    this.chunks.clear();
  }
}
