/**
 * Ruins: the drowned temple, two stone bridges, and the wyrm-guardian statues
 * that line the old processional road.
 *
 * The bridges are load-bearing narratively as well as structurally — one spans
 * the lava channel between village and castle (so the fire-breath shot has
 * something dramatic to silhouette), the other crosses the meltwater river on
 * the village's east lane.
 */
import * as THREE from 'three';
import { makeRng } from '../utils/Noise.js';
import { TAU, clamp } from '../utils/MathX.js';
import {
  WORLD, height, LAVA_PATH, RIVER_PATH, pathPoint,
} from '../world/Heightfield.js';
import { Rocks } from '../world/Rocks.js';
import { box, blockWall, column, arch, crenellations, meshFrom, mergeSafe } from './Blocks.js';

/* ── guardian statue ──────────────────────────────────────────────────── */

/**
 * A seated wyrm on a plinth. Built from primitives, but the proportions matter:
 * heavy plinth, coiled body, long neck, head tilted down at whoever walks past.
 */
function buildGuardian(rng) {
  const parts = [];
  // Plinth.
  parts.push(box(7, 1.2, 7, 0, 0.6, 0));
  parts.push(box(6, 3.6, 6, 0, 2.9, 0));
  parts.push(box(6.8, 0.7, 6.8, 0, 5.0, 0));

  // Coiled body.
  const body = new THREE.SphereGeometry(2.3, 14, 10);
  body.scale(1.35, 0.85, 1.15);
  body.translate(0, 6.2, 0);
  parts.push(body);

  // Haunches & forelegs.
  for (const s of [-1, 1]) {
    const h = new THREE.SphereGeometry(1.1, 10, 8);
    h.scale(1, 0.9, 1.3);
    h.translate(s * 1.9, 6.0, -0.9);
    parts.push(h);
    const leg = new THREE.CylinderGeometry(0.42, 0.6, 3.0, 7);
    leg.translate(s * 1.5, 6.0, 2.1);
    parts.push(leg);
    const paw = new THREE.SphereGeometry(0.7, 8, 6);
    paw.scale(1.2, 0.6, 1.5);
    paw.translate(s * 1.5, 4.7, 2.7);
    parts.push(paw);
  }

  // Neck: a tapering stack, curving up and forward.
  let ny = 7.6, nz = 1.0, nr = 1.15;
  for (let i = 0; i < 7; i++) {
    const seg = new THREE.CylinderGeometry(nr * 0.88, nr, 1.15, 8);
    seg.rotateX(-0.34 - i * 0.05);
    seg.translate(0, ny, nz);
    parts.push(seg);
    ny += 0.95; nz += 0.42; nr *= 0.9;
  }

  // Head.
  const head = new THREE.ConeGeometry(1.05, 3.0, 8);
  head.rotateX(Math.PI * 0.62);
  head.translate(0, ny + 0.3, nz + 1.0);
  parts.push(head);
  const jaw = new THREE.BoxGeometry(1.1, 0.5, 2.0);
  jaw.rotateX(0.2);
  jaw.translate(0, ny - 0.35, nz + 1.2);
  parts.push(jaw);
  // Horns.
  for (const s of [-1, 1]) {
    const horn = new THREE.ConeGeometry(0.28, 2.1, 6);
    horn.rotateZ(s * 0.5);
    horn.rotateX(-0.7);
    horn.translate(s * 0.55, ny + 1.4, nz + 0.1);
    parts.push(horn);
  }

  // Folded wings — two swept blades.
  for (const s of [-1, 1]) {
    const w = new THREE.BoxGeometry(0.4, 5.4, 2.2);
    w.rotateZ(s * 0.28);
    w.rotateX(0.3);
    w.translate(s * 2.2, 8.0, -1.4);
    parts.push(w);
    const w2 = new THREE.BoxGeometry(0.35, 3.4, 1.4);
    w2.rotateZ(s * 0.6);
    w2.translate(s * 3.0, 9.6, -2.2);
    parts.push(w2);
  }

  // Tail curling around the plinth.
  let tx = 0, tz = -2.4, tr = 0.85;
  for (let i = 0; i < 9; i++) {
    const a = i * 0.55;
    const seg = new THREE.SphereGeometry(tr, 8, 6);
    seg.translate(tx, 5.6 - i * 0.08, tz);
    parts.push(seg);
    tx += Math.cos(a + 1.6) * 0.95;
    tz -= Math.sin(a + 0.4) * 0.55;
    tr *= 0.88;
  }

  // Erosion: knock the geometry about a little.
  const geo = mergeSafe(parts);
  const p = geo.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const j = 0.055;
    p.setXYZ(i, p.getX(i) + (rng() - 0.5) * j, p.getY(i) + (rng() - 0.5) * j, p.getZ(i) + (rng() - 0.5) * j);
  }
  geo.computeVertexNormals();
  return geo;
}

/* ── bridge ───────────────────────────────────────────────────────────── */

function buildBridge(rng, { span, deckY, gorge, piers = 2, damage = 0.15 }) {
  const parts = [];
  const rise = span * 0.17;

  // Deck: a shallow arc of slabs.
  const n = Math.round(span / 2.6);
  for (let i = 0; i <= n; i++) {
    const t = i / n;
    const x = (t - 0.5) * span;
    const y = deckY + Math.sin(t * Math.PI) * rise;
    if (rng() < damage * 0.35 && t > 0.25 && t < 0.75) continue;   // a hole in the deck
    parts.push(box(2.9, 0.8, 9, x, y, 0));
    // Parapets.
    for (const s of [-1, 1]) {
      if (rng() < damage * 0.9) continue;
      parts.push(box(2.7, 1.5, 0.8, x, y + 1.1, s * 4.1));
    }
  }

  // Arches down to the gorge floor.
  for (let a = 0; a < piers; a++) {
    const t = (a + 0.5) / piers;
    const x = (t - 0.5) * span;
    const y = deckY + Math.sin(t * Math.PI) * rise;
    const archSpan = span / piers * 0.82;
    const av = arch(archSpan, archSpan * 0.55, 1.5, { blocks: 15, depth: 8.6, rng });
    for (const g of av) { g.translate(x, y - archSpan * 0.55 - 0.5, 0); parts.push(g); }
    // Pier down to the floor.
    const pierH = Math.max(2, y - archSpan * 0.55 - gorge);
    if (a < piers - 1) {
      const px = x + archSpan * 0.5 + 1.2;
      parts.push(box(3.4, pierH, 9, px, gorge + pierH / 2, 0));
      parts.push(box(4.6, 1.2, 10, px, gorge + pierH, 0));
    }
  }
  // Abutments.
  for (const s of [-1, 1]) {
    parts.push(box(6, Math.max(3, deckY - gorge + 2), 11, s * (span / 2 + 2), (deckY + gorge) / 2, 0));
  }

  return mergeSafe(parts);
}

/* ── the assembly ─────────────────────────────────────────────────────── */

export class Ruins {
  constructor(materials, settings) {
    this.group = new THREE.Group();
    this.group.name = 'Ruins';
    const rng = makeRng(60613);

    this.group.add(this._buildTemple(materials, rng));
    this.group.add(this._buildStatues(materials, rng));
    this.group.add(this._buildBridges(materials, rng));
  }

  _buildTemple(materials, rng) {
    const g = new THREE.Group();
    g.name = 'Temple';
    const T = WORLD.temple;
    const y = height(T.x, T.z);
    const parts = [];

    // Stylobate.
    for (let s = 0; s < 3; s++) {
      parts.push(box(46 - s * 3, 1.1, 30 - s * 3, 0, 0.55 + s * 1.1, 0));
    }
    const floorY = 3.4;

    // Peristyle — 8 × 5 columns, progressively more ruined toward the back.
    for (let i = 0; i < 8; i++) {
      for (let j = 0; j < 5; j++) {
        const edge = i === 0 || i === 7 || j === 0 || j === 4;
        if (!edge) continue;
        const ruin = clamp((i / 7) * 0.7 + rng() * 0.45, 0, 0.95);
        const broken = ruin > 0.55 ? 0.25 + rng() * 0.6 : rng() * 0.15;
        const col = column(1.35, 13, { flutes: 14, rng, broken });
        for (const c of col) { c.translate(-19 + i * 5.4, floorY, -12 + j * 6); parts.push(c); }
      }
    }

    // Architrave fragments over the intact (front) end.
    for (let i = 0; i < 3; i++) {
      parts.push(box(11, 1.6, 3.2, -14 + i * 5.4, floorY + 14.4, -12));
      parts.push(box(11, 1.6, 3.2, -14 + i * 5.4, floorY + 14.4, 12));
    }
    // Pediment shards.
    const ped = box(15, 5.5, 3.0, -14, floorY + 17.6, -12);
    ped.rotateZ(0.06);
    parts.push(ped);

    // Cella walls, collapsed at the rear.
    for (const [len, x, z, ry, dmg] of [
      [30, 0, -8, 0, 0.35], [30, 0, 8, 0, 0.5], [16, -15, 0, Math.PI / 2, 0.25], [16, 15, 0, Math.PI / 2, 0.8],
    ]) {
      const w = blockWall(len, 9, 1.6, { rng, damage: dmg, blockW: 2.6, blockH: 1.3 });
      for (const b of w) { b.rotateY(ry); b.translate(x, floorY, z); parts.push(b); }
    }

    // Altar, cracked.
    parts.push(box(5, 2.2, 3.2, 0, floorY + 1.1, 0));
    const slab = box(6.2, 0.6, 4.2, 0.3, floorY + 2.5, 0);
    slab.rotateZ(0.09);
    parts.push(slab);

    // Fallen drums scattered across the floor.
    for (let i = 0; i < 22; i++) {
      const d = new THREE.CylinderGeometry(1.25, 1.3, 1.8 + rng() * 2.4, 12);
      d.rotateZ(Math.PI / 2 + (rng() - 0.5) * 0.5);
      d.rotateY(rng() * TAU);
      d.translate((rng() - 0.5) * 40, floorY + 0.9, (rng() - 0.5) * 24);
      parts.push(d);
    }

    const mesh = meshFrom(parts, materials.get('stone'), { name: 'TempleStone' });
    if (mesh) g.add(mesh);
    g.add(Rocks.scree(materials, rng, 0, 0, 26, 26));
    g.position.set(T.x, y, T.z);
    g.rotation.y = 0.42;
    return g;
  }

  _buildStatues(materials, rng) {
    const g = new THREE.Group();
    g.name = 'Guardians';
    const geo = buildGuardian(rng);

    // Line the road from the village toward the castle bridge, plus a pair
    // flanking the temple steps and one lone sentinel above the lava lake.
    const spots = [];
    for (let i = 0; i < 8; i++) {
      const t = i / 7;
      const x = 150 + (-40 - 150) * t + Math.sin(t * 6) * 12;
      const z = 330 + (300 - 330) * t + Math.cos(t * 5) * 8;
      const side = i % 2 ? 1 : -1;
      spots.push([x + side * 11, z + side * 6, Math.atan2(-side, 0.4)]);
    }
    spots.push([WORLD.temple.x + 26, WORLD.temple.z - 16, 2.1]);
    spots.push([WORLD.temple.x + 22, WORLD.temple.z + 18, 2.5]);
    spots.push([WORLD.lavaLake.x + 118, WORLD.lavaLake.z - 34, -1.2]);
    spots.push([WORLD.village.x - 96, WORLD.village.z - 78, 0.7]);

    const inst = new THREE.InstancedMesh(geo, materials.get('statue'), spots.length);
    inst.castShadow = inst.receiveShadow = true;
    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const p = new THREE.Vector3();
    const s = new THREE.Vector3();
    const up = new THREE.Vector3(0, 1, 0);
    for (let i = 0; i < spots.length; i++) {
      const [x, z, ry] = spots[i];
      const sc = 1.5 + rng() * 0.9;
      p.set(x, height(x, z) - 0.4, z);
      q.setFromAxisAngle(up, ry + (rng() - 0.5) * 0.2);
      s.setScalar(sc);
      m.compose(p, q, s);
      inst.setMatrixAt(i, m);
      g.add(Rocks.scree(materials, rng, x, z, 6 * sc, 5));
    }
    g.add(inst);
    return g;
  }

  _buildBridges(materials, rng) {
    const g = new THREE.Group();
    g.name = 'Bridges';

    // ── over the lava channel, on the castle road ───────────────────
    {
      const [x, z, ang] = pathPoint(LAVA_PATH, 0.72);
      const deckY = height(x, z) + 22;
      const geo = buildBridge(rng, { span: 96, deckY: 0, gorge: -24, piers: 3, damage: 0.2 });
      const mesh = new THREE.Mesh(geo, materials.get('stone'));
      mesh.castShadow = mesh.receiveShadow = true;
      mesh.name = 'LavaBridge';
      mesh.position.set(x, deckY, z);
      mesh.rotation.y = ang;
      g.add(mesh);
      this.lavaBridge = mesh;
      // A guard tower at the near end.
      const t = meshFrom(
        [
          ...blockWall(12, 14, 4, { rng, damage: 0.3, blockW: 2.8 }),
          ...crenellations(12, 4, 14, { rng, damage: 0.4 }),
        ],
        materials.get('stone'), { name: 'BridgeTower' },
      );
      if (t) {
        const tx = x + Math.cos(ang) * 56, tz = z + Math.sin(ang) * 56;
        t.position.set(tx, height(tx, tz), tz);
        t.rotation.y = ang;
        g.add(t);
      }
    }

    // ── over the meltwater river, east of the village ────────────────
    {
      const [x, z, ang] = pathPoint(RIVER_PATH, 0.34);
      const deckY = height(x, z) + 12;
      const geo = buildBridge(rng, { span: 52, deckY: 0, gorge: -14, piers: 2, damage: 0.06 });
      const mesh = new THREE.Mesh(geo, materials.get('stone'));
      mesh.castShadow = mesh.receiveShadow = true;
      mesh.name = 'RiverBridge';
      mesh.position.set(x, deckY, z);
      mesh.rotation.y = ang;
      g.add(mesh);
    }

    return g;
  }

  update() {}
  dispose() { this.group.traverse((o) => o.geometry?.dispose()); }
}
