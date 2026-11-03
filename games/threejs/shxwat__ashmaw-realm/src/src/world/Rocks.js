/**
 * Rock: boulder fields, cliff spires, arches and the scree that ties structures
 * into the ground. All instanced — five deformed icosahedron variants and one
 * shard, placed by slope so boulders collect in gullies and shards cling to the
 * cliff faces.
 *
 * Placing scree at the feet of every wall and statue is the cheapest possible
 * trick for making procedural props stop looking pasted onto the terrain.
 */
import * as THREE from 'three';
import * as BGU from 'three/addons/utils/BufferGeometryUtils.js';
import { makeRng } from '../utils/Noise.js';
import { scatterPoints, TAU, clamp } from '../utils/MathX.js';
import { height, slopeAt, isOnWater, isOnLava, WORLD, normalAt } from './Heightfield.js';

function deform(geo, rng, amount = 0.42, stretch = [1, 1, 1]) {
  const p = geo.attributes.position;
  const seen = new Map();
  for (let i = 0; i < p.count; i++) {
    const key = `${p.getX(i).toFixed(3)},${p.getY(i).toFixed(3)},${p.getZ(i).toFixed(3)}`;
    let s = seen.get(key);
    if (s === undefined) { s = 1 + (rng() - 0.5) * amount * 2; seen.set(key, s); }
    p.setXYZ(i, p.getX(i) * s * stretch[0], p.getY(i) * s * stretch[1], p.getZ(i) * s * stretch[2]);
  }
  geo.computeVertexNormals();
  return geo;
}

function boulder(rng, detail = 1) {
  const g = new THREE.IcosahedronGeometry(1, detail);
  return deform(g, rng, 0.34, [1 + rng() * 0.5, 0.6 + rng() * 0.5, 1 + rng() * 0.4]);
}

function shard(rng) {
  const g = new THREE.ConeGeometry(1, 3.2, 5, 2);
  g.translate(0, 1.6, 0);
  return deform(g, rng, 0.3, [1, 1 + rng() * 0.8, 1]);
}

export class Rocks {
  constructor(materials, settings) {
    this.group = new THREE.Group();
    this.group.name = 'Rocks';
    const rng = makeRng(8181);

    const variants = [boulder(rng, 1), boulder(rng, 1), boulder(rng, 0), boulder(rng, 1), boulder(rng, 0)];
    const shardGeo = shard(rng);

    const rockMat = materials.get('rock');
    const basaltMat = materials.get('basalt');

    // ── boulder field ───────────────────────────────────────────────
    const total = settings.rockCount;
    const pts = scatterPoints({
      count: total, radius: WORLD.half * 0.92, center: [0, 0], minDist: 12, rng,
      reject: (x, z) => {
        const h = height(x, z);
        if (h < 2 || h > 340) return true;
        if (isOnWater(x, z) || isOnLava(x, z)) return true;
        const s = slopeAt(x, z, 6);
        return s < 0.06 && rng() > 0.35;   // favour slopes, allow some on flats
      },
    });

    const buckets = variants.map(() => []);
    for (const p of pts) buckets[Math.floor(rng() * variants.length)].push(p);

    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const pos = new THREE.Vector3();
    const scl = new THREE.Vector3();
    const up = new THREE.Vector3(0, 1, 0);
    const nrm = new THREE.Vector3();

    variants.forEach((geo, vi) => {
      const list = buckets[vi];
      if (!list.length) return;
      const hot = vi % 2 === 0;
      const inst = new THREE.InstancedMesh(geo, hot ? basaltMat : rockMat, list.length);
      inst.castShadow = true;
      inst.receiveShadow = true;
      inst.name = `Boulders${vi}`;
      for (let i = 0; i < list.length; i++) {
        const [x, z] = list[i];
        const y = height(x, z);
        const s = 1.6 + Math.pow(rng(), 2.4) * 13;
        const [nx, ny, nz] = normalAt(x, z, 5);
        nrm.set(nx, ny, nz);
        q.setFromUnitVectors(up, nrm.lerp(up, 0.35).normalize())
          .multiply(new THREE.Quaternion().setFromAxisAngle(up, rng() * TAU));
        pos.set(x, y - s * 0.32, z);
        scl.set(s, s * (0.7 + rng() * 0.5), s);
        m.compose(pos, q, scl);
        inst.setMatrixAt(i, m);
      }
      this.group.add(inst);
    });

    // ── cliff shards on steep faces ─────────────────────────────────
    const shardPts = scatterPoints({
      count: Math.round(total * 0.55), radius: WORLD.half * 0.9, center: [80, -80], minDist: 16, rng,
      // Keep them off high ridgelines and crater rims, where a field of
      // upright cones reads as a row of teeth rather than as scree.
      reject: (x, z) => {
        const h = height(x, z);
        return slopeAt(x, z, 8) < 0.42 || h < 40 || h > 250;
      },
    });
    if (shardPts.length) {
      const inst = new THREE.InstancedMesh(shardGeo, basaltMat, shardPts.length);
      inst.castShadow = true;
      inst.name = 'CliffShards';
      for (let i = 0; i < shardPts.length; i++) {
        const [x, z] = shardPts[i];
        const s = 2.0 + Math.pow(rng(), 2.4) * 7.5;
        const [nx, ny, nz] = normalAt(x, z, 6);
        nrm.set(nx, ny, nz);
        q.setFromUnitVectors(up, nrm.lerp(up, 0.2).normalize())
          .multiply(new THREE.Quaternion().setFromAxisAngle(up, rng() * TAU));
        pos.set(x, height(x, z) - s * 0.2, z);
        scl.set(s * (0.6 + rng() * 0.5), s * (0.85 + rng() * 0.5), s * (0.6 + rng() * 0.5));
        m.compose(pos, q, scl);
        inst.setMatrixAt(i, m);
      }
      this.group.add(inst);
    }

    // ── hero geology: an arch, monoliths and volcano crater spires ────
    this.group.add(this._buildArch(materials, rng, 470, 40, 62));
    this.group.add(this._buildMonoliths(materials, rng));
    this.group.add(this._buildCraterSpires(materials, rng));
  }

  _buildArch(materials, rng, cx, cz, span) {
    const parts = [];
    const steps = 14;
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const a = Math.PI * t;
      const r = span * 0.5;
      const x = -Math.cos(a) * r;
      const y = Math.sin(a) * r * 1.25;
      const thick = 7 + Math.sin(t * Math.PI) * 5;
      const b = new THREE.IcosahedronGeometry(thick, 0);
      deform(b, rng, 0.3, [1.4, 1, 1.2]);
      b.translate(x, y, Math.sin(t * 5) * 3);
      parts.push(b);
    }
    const geo = BGU.mergeGeometries(parts);
    parts.forEach((g) => g.dispose());
    const mesh = new THREE.Mesh(geo, materials.get('rock'));
    mesh.position.set(cx, height(cx, cz) - 3, cz);
    mesh.rotation.y = 0.6;
    mesh.castShadow = mesh.receiveShadow = true;
    mesh.name = 'StoneArch';
    return mesh;
  }

  _buildMonoliths(materials, rng) {
    const g = new THREE.Group();
    g.name = 'Monoliths';
    const spots = [[300, -150], [340, -110], [268, -128], [-560, 460], [-600, 500]];
    for (const [x, z] of spots) {
      const h = 22 + rng() * 34;
      const geo = new THREE.BoxGeometry(6 + rng() * 6, h, 4 + rng() * 5);
      deform(geo, rng, 0.14);
      const m = new THREE.Mesh(geo, materials.get('basalt'));
      m.position.set(x, height(x, z) + h * 0.42, z);
      m.rotation.set((rng() - 0.5) * 0.2, rng() * TAU, (rng() - 0.5) * 0.2);
      m.castShadow = m.receiveShadow = true;
      g.add(m);
    }
    return g;
  }

  /**
   * Eroded basalt buttresses on Ashmaw's crater rim.
   *
   * This used to place 28 cones at `(i / 28) * TAU` with ±0.075 rad of jitter
   * — a near-perfect ring of evenly spaced spikes up to 56 units tall. Regular
   * spacing is the giveaway: nothing in geology is evenly spaced, so the
   * summit read as a crown of black teeth bolted onto a cone rather than as
   * rock. They also fought the crater's own silhouette instead of reinforcing
   * it.
   *
   * Now: far fewer, clustered into a couple of irregular groups, squatter and
   * wedge-shaped rather than needle-like, and absent from the breached sector
   * (which by definition is where the rim collapsed and blew out).
   */
  _buildCraterSpires(materials, rng) {
    const g = new THREE.Group();
    g.name = 'CraterSpires';
    const V = WORLD.volcano;
    const basaltMat = materials.get('basalt');
    const BREACH_DIR = -0.9;    // must match volcanoCone() in Heightfield.js

    // A few clusters at arbitrary bearings, each with a handful of blocks.
    const clusters = [0.7, 1.9, 3.05, 4.4, 5.3];
    for (const base of clusters) {
      const n = 2 + Math.floor(rng() * 3);
      for (let i = 0; i < n; i++) {
        const angle = base + (rng() - 0.5) * 0.55;

        // Skip the breach: the rim is gone there.
        let dA = angle - BREACH_DIR;
        dA = Math.atan2(Math.sin(dA), Math.cos(dA));
        if (Math.abs(dA) < 0.75) continue;

        const r = V.craterR * (0.82 + rng() * 0.40);
        const x = V.x + Math.cos(angle) * r;
        const z = V.z + Math.sin(angle) * r;
        const h = 11 + rng() * 17;
        const radiusBottom = 6 + rng() * 7;

        // Wide base, blunt top: a weathered buttress, not a spike.
        const geo = new THREE.CylinderGeometry(radiusBottom * 0.45, radiusBottom, h, 6);
        deform(geo, rng, 0.42, [1 + rng() * 0.5, 1, 1 + rng() * 0.5]);

        const mesh = new THREE.Mesh(geo, basaltMat);
        mesh.position.set(x, height(x, z) + h * 0.30, z);
        mesh.rotation.set((rng() - 0.5) * 0.22, rng() * TAU, (rng() - 0.5) * 0.22);
        mesh.castShadow = mesh.receiveShadow = true;
        g.add(mesh);
      }
    }
    return g;
  }

  /** Scatter small rubble around a point — call it after placing any structure. */
  static scree(materials, rng, cx, cz, radius, count = 14) {
    const geo = boulder(rng, 0);
    const inst = new THREE.InstancedMesh(geo, materials.get('rock'), count);
    inst.castShadow = true;
    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const p = new THREE.Vector3();
    const s = new THREE.Vector3();
    for (let i = 0; i < count; i++) {
      const a = rng() * TAU;
      const r = radius * (0.6 + rng() * 0.6);
      const x = cx + Math.cos(a) * r, z = cz + Math.sin(a) * r;
      const sc = 0.5 + rng() * 2.4;
      p.set(x, height(x, z) - sc * 0.3, z);
      q.setFromEuler(new THREE.Euler(rng() * TAU, rng() * TAU, rng() * TAU));
      s.set(sc, sc * 0.7, sc);
      m.compose(p, q, s);
      inst.setMatrixAt(i, m);
    }
    return inst;
  }

  update() {}
  dispose() { this.group.traverse((o) => o.geometry?.dispose()); }
}
