/**
 * Village props — the layer that makes walking around feel like a place.
 *
 * Nothing here is clever. It's barrels, crates, carts, firewood, troughs,
 * hanging signs, laundry lines and cobbles. But eye-level detail density is
 * *the* difference between "procedural boxes on a heightfield" and a village:
 * at 1.7 m the eye needs something within 3 m to read scale against, and it
 * needs the ground to change material where people walk.
 *
 * All instanced and merged per material, so the whole clutter layer is ~8 draw
 * calls for several hundred objects.
 */
import * as THREE from 'three';
import * as BGU from 'three/addons/utils/BufferGeometryUtils.js';
import { makeRng, noise } from '../utils/Noise.js';
import { TAU, clamp, smoothstep } from '../utils/MathX.js';
import { WORLD, height, canBuild, isOnLava, isOnWater, normalAt } from '../world/Heightfield.js';
import { box, roofPrism, mergeSafe, meshFrom } from './Blocks.js';

/* ── individual props ─────────────────────────────────────────────────── */

function barrel(rng) {
  const parts = [];
  const h = 1.05 + rng() * 0.25;
  const r = 0.36 + rng() * 0.07;
  // Bulged staves: a straight cylinder reads as a bin, not a barrel.
  const body = new THREE.CylinderGeometry(r * 0.86, r * 0.86, h, 12, 4);
  const p = body.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const y = p.getY(i);
    const bulge = 1 + Math.cos((y / h) * Math.PI) * -0.0 + Math.sin(((y / h) + 0.5) * Math.PI) * 0.16;
    p.setX(i, p.getX(i) * bulge);
    p.setZ(i, p.getZ(i) * bulge);
  }
  body.computeVertexNormals();
  body.translate(0, h / 2, 0);
  parts.push(body);
  return mergeSafe(parts);
}

function barrelHoops(rng) {
  const parts = [];
  const h = 1.05;
  for (const t of [0.18, 0.5, 0.82]) {
    const ring = new THREE.TorusGeometry(0.42, 0.028, 4, 14);
    ring.rotateX(Math.PI / 2);
    ring.translate(0, h * t, 0);
    parts.push(ring);
  }
  return mergeSafe(parts);
}

function crate(rng) {
  const s = 0.6 + rng() * 0.35;
  const parts = [box(s, s * 0.92, s * (0.85 + rng() * 0.3), 0, s * 0.46, 0)];
  // Corner battens — the silhouette cue that says "crate" not "cube".
  const t = 0.06;
  for (const sx of [-1, 1]) for (const sz of [-1, 1]) {
    parts.push(box(t * 1.6, s * 0.94, t * 1.6, sx * s * 0.5, s * 0.46, sz * s * 0.5));
  }
  parts.push(box(s * 1.02, t, s * 1.02, 0, s * 0.9, 0));
  return mergeSafe(parts);
}

function firewood(rng) {
  const parts = [];
  const rows = 3 + Math.floor(rng() * 2);
  for (let r = 0; r < rows; r++) {
    const n = 5 - Math.floor(r * 0.7);
    for (let i = 0; i < n; i++) {
      const log = new THREE.CylinderGeometry(0.08 + rng() * 0.03, 0.09, 1.3 + rng() * 0.3, 6);
      log.rotateZ(Math.PI / 2);
      log.rotateY((rng() - 0.5) * 0.12);
      log.translate((i - (n - 1) / 2) * 0.2 + (rng() - 0.5) * 0.05, 0.1 + r * 0.19, (rng() - 0.5) * 0.1);
      parts.push(log);
    }
  }
  return mergeSafe(parts);
}

function trough(rng) {
  const parts = [];
  const w = 1.9, d = 0.62, h = 0.5;
  for (const sx of [-1, 1]) parts.push(box(0.09, h, d, sx * w / 2, h / 2, 0));
  for (const sz of [-1, 1]) parts.push(box(w, h, 0.09, 0, h / 2, sz * d / 2));
  parts.push(box(w, 0.09, d, 0, 0.05, 0));
  // Stubby legs.
  for (const sx of [-1, 1]) parts.push(box(0.14, 0.22, 0.14, sx * w * 0.38, 0.11, 0));
  return mergeSafe(parts);
}

function cart(rng) {
  const parts = [];
  const bedW = 1.5, bedL = 2.5;
  parts.push(box(bedW, 0.12, bedL, 0, 0.72, 0));
  for (const sx of [-1, 1]) parts.push(box(0.09, 0.42, bedL, sx * bedW / 2, 0.96, 0));
  parts.push(box(bedW, 0.42, 0.09, 0, 0.96, -bedL / 2));
  // Shafts angled to the ground.
  for (const sx of [-1, 1]) {
    const shaft = box(0.09, 0.09, 1.9, sx * bedW * 0.33, 0.62, bedL / 2 + 0.85);
    shaft.rotateX(-0.12);
    parts.push(shaft);
  }
  parts.push(box(0.16, 0.16, bedW * 1.15, 0, 0.62, 0, Math.PI / 2)); // axle
  return mergeSafe(parts);
}

function cartWheels(rng) {
  const parts = [];
  for (const sx of [-1, 1]) {
    const rim = new THREE.TorusGeometry(0.46, 0.055, 5, 16);
    rim.rotateY(Math.PI / 2);
    rim.translate(sx * 0.86, 0.48, 0);
    parts.push(rim);
    for (let s = 0; s < 6; s++) {
      const a = (s / 6) * Math.PI;
      const spoke = new THREE.BoxGeometry(0.045, 0.88, 0.045);
      spoke.rotateX(a);
      spoke.rotateZ(Math.PI / 2);
      spoke.translate(sx * 0.86, 0.48, 0);
      parts.push(spoke);
    }
    const hub = new THREE.CylinderGeometry(0.1, 0.1, 0.22, 8);
    hub.rotateZ(Math.PI / 2);
    hub.translate(sx * 0.86, 0.48, 0);
    parts.push(hub);
  }
  return mergeSafe(parts);
}

/** A hanging shop sign on a wrought bracket. */
function signBracket() {
  const parts = [];
  parts.push(box(0.07, 0.07, 1.0, 0, 2.5, 0.5));
  parts.push(box(0.05, 0.5, 0.05, 0, 2.28, 0.92));
  const brace = box(0.05, 0.05, 0.62, 0, 2.22, 0.32);
  brace.rotateX(-0.72);
  parts.push(brace);
  return mergeSafe(parts);
}

function signBoard(rng) {
  const parts = [box(0.72, 0.5, 0.055, 0, 1.95, 0.92)];
  return mergeSafe(parts);
}

/* ── the layer ────────────────────────────────────────────────────────── */

export class Props {
  constructor(materials, settings, village) {
    this.group = new THREE.Group();
    this.group.name = 'Props';
    const rng = makeRng(2718);
    const V = WORLD.village;

    this.materials = materials;
    this._sway = [];

    // ── where clutter can live: near a house, off the lanes ──────────
    const anchors = [];
    for (const plot of village.plots) {
      const n = 1 + Math.floor(rng() * 3);
      for (let i = 0; i < n; i++) {
        const a = rng() * TAU;
        const r = 4.5 + rng() * 5.5;
        const x = plot.x + Math.cos(a) * r;
        const z = plot.z + Math.sin(a) * r;
        if (!canBuild(x, z)) continue;
        anchors.push({ x, z, ry: rng() * TAU, near: plot });
      }
    }
    // Plaza gets a denser market cluster.
    for (let i = 0; i < 26; i++) {
      const a = rng() * TAU;
      const r = 8 + rng() * 16;
      const x = V.x + Math.cos(a) * r, z = V.z + Math.sin(a) * r;
      if (canBuild(x, z)) anchors.push({ x, z, ry: rng() * TAU, plaza: true });
    }

    this._place(anchors, rng, {
      barrel:  { geo: barrel(rng),      mat: 'wood',     w: 0.26, cast: true },
      hoops:   { geo: barrelHoops(rng), mat: 'iron',     w: 0.00, follows: 'barrel' },
      crate:   { geo: crate(rng),       mat: 'woodDark', w: 0.24, cast: true },
      wood:    { geo: firewood(rng),    mat: 'woodDark', w: 0.14, cast: true },
      trough:  { geo: trough(rng),      mat: 'wood',     w: 0.10, cast: true },
    });

    // ── carts: fewer, bigger, always beside a lane ───────────────────
    this._placeCarts(rng, materials);

    // ── hanging signs on the plaza-facing houses ─────────────────────
    this._placeSigns(rng, materials, village);

    // ── laundry lines strung between cottages ────────────────────────
    this._placeLaundry(rng, materials, village);

    // ── cobbled plaza + worn paths ───────────────────────────────────
    this.group.add(this._buildCobbles(materials, rng));
  }

  _place(anchors, rng, kinds) {
    const buckets = {};
    for (const k of Object.keys(kinds)) buckets[k] = [];

    for (const a of anchors) {
      // Pick a kind by weight.
      let roll = rng();
      for (const [k, cfg] of Object.entries(kinds)) {
        if (cfg.follows) continue;
        roll -= cfg.w;
        if (roll <= 0) { buckets[k].push(a); break; }
      }
    }
    // Hoops ride on barrels.
    for (const [k, cfg] of Object.entries(kinds)) {
      if (cfg.follows) buckets[k] = buckets[cfg.follows];
    }

    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const p = new THREE.Vector3();
    const s = new THREE.Vector3();
    const up = new THREE.Vector3(0, 1, 0);
    const nrm = new THREE.Vector3();

    for (const [k, cfg] of Object.entries(kinds)) {
      const list = buckets[k];
      if (!list?.length || !cfg.geo) continue;
      const inst = new THREE.InstancedMesh(cfg.geo, this.materials.get(cfg.mat), list.length);
      inst.castShadow = !!cfg.cast;
      inst.receiveShadow = true;
      inst.name = `Prop_${k}`;
      for (let i = 0; i < list.length; i++) {
        const a = list[i];
        const sc = 0.9 + rng() * 0.3;
        // Sit on the slope, not through it.
        const [nx, ny, nz] = normalAt(a.x, a.z, 2);
        nrm.set(nx, ny, nz);
        q.setFromUnitVectors(up, nrm.lerp(up, 0.5).normalize())
          .multiply(new THREE.Quaternion().setFromAxisAngle(up, a.ry));
        p.set(a.x, height(a.x, a.z) - 0.04, a.z);
        s.setScalar(sc);
        m.compose(p, q, s);
        inst.setMatrixAt(i, m);
      }
      this.group.add(inst);
    }
  }

  _placeCarts(rng, materials) {
    const V = WORLD.village;
    const spots = [];
    for (let i = 0; i < 7; i++) {
      const a = rng() * TAU;
      const r = 14 + rng() * 80;
      const x = V.x + Math.cos(a) * r, z = V.z + Math.sin(a) * r;
      if (canBuild(x, z)) spots.push([x, z, rng() * TAU]);
    }
    if (!spots.length) return;

    const bodyGeo = cart(rng);
    const wheelGeo = cartWheels(rng);
    const body = new THREE.InstancedMesh(bodyGeo, materials.get('woodDark'), spots.length);
    const wheels = new THREE.InstancedMesh(wheelGeo, materials.get('wood'), spots.length);
    body.castShadow = wheels.castShadow = true;
    body.receiveShadow = true;

    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const p = new THREE.Vector3();
    const s = new THREE.Vector3(1, 1, 1);
    const up = new THREE.Vector3(0, 1, 0);
    for (let i = 0; i < spots.length; i++) {
      const [x, z, ry] = spots[i];
      p.set(x, height(x, z) - 0.05, z);
      q.setFromAxisAngle(up, ry);
      m.compose(p, q, s);
      body.setMatrixAt(i, m);
      wheels.setMatrixAt(i, m);
    }
    this.group.add(body, wheels);
  }

  _placeSigns(rng, materials, village) {
    const plots = village.plots.slice(0, 22).filter(() => rng() > 0.45);
    if (!plots.length) return;
    const bracketGeo = signBracket();
    const boardGeo = signBoard(rng);
    const brackets = new THREE.InstancedMesh(bracketGeo, materials.get('iron'), plots.length);
    brackets.castShadow = true;

    this.signBoards = [];
    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const p = new THREE.Vector3();
    const s = new THREE.Vector3(1, 1, 1);
    const up = new THREE.Vector3(0, 1, 0);

    for (let i = 0; i < plots.length; i++) {
      const plot = plots[i];
      const ry = plot.ry;
      // Mount on the wall face, pushed out along the plot's facing.
      const off = 3.4;
      const x = plot.x + Math.cos(ry + Math.PI / 2) * off;
      const z = plot.z + Math.sin(ry + Math.PI / 2) * off;
      p.set(x, height(x, z), z);
      q.setFromAxisAngle(up, ry + Math.PI / 2);
      m.compose(p, q, s);
      brackets.setMatrixAt(i, m);

      // Boards swing, so they are individual meshes with a pivot.
      const pivot = new THREE.Group();
      pivot.position.set(x, height(x, z), z);
      pivot.rotation.y = ry + Math.PI / 2;
      const board = new THREE.Mesh(boardGeo, materials.get('wood'));
      board.castShadow = true;
      // Re-origin so it swings from the bracket arm, not its own centre.
      board.geometry = boardGeo;
      board.position.set(0, 0, 0);
      pivot.add(board);
      this.group.add(pivot);
      this.signBoards.push({ pivot, phase: rng() * TAU });
    }
    this.group.add(brackets);
  }

  /** Laundry: two poles and a sagging line of cloth. Uses the wind material. */
  _placeLaundry(rng, materials, village) {
    const cloth = materials.get('cloth');
    const g = new THREE.Group();
    g.name = 'Laundry';
    let made = 0;
    for (const plot of village.plots) {
      if (made >= 7) break;
      if (rng() > 0.3) continue;
      const a = plot.ry + Math.PI / 2;
      const x0 = plot.x + Math.cos(a) * 5.5, z0 = plot.z + Math.sin(a) * 5.5;
      const x1 = x0 + Math.cos(a + 1.4) * 7, z1 = z0 + Math.sin(a + 1.4) * 7;
      if (!canBuild(x0, z0) || !canBuild(x1, z1)) continue;
      const y0 = height(x0, z0), y1 = height(x1, z1);

      const poles = [];
      poles.push(box(0.11, 3.0, 0.11, 0, 1.5, 0));
      const poleA = meshFrom(poles, materials.get('woodDark'), { name: 'LaundryPole' });
      poleA.position.set(x0, y0, z0);
      const poleB = poleA.clone();
      poleB.position.set(x1, y1, z1);
      g.add(poleA, poleB);

      // Three garments hanging from the line.
      for (let k = 0; k < 3; k++) {
        const t = 0.22 + k * 0.28;
        const gx = x0 + (x1 - x0) * t, gz = z0 + (z1 - z0) * t;
        const gy = (y0 + (y1 - y0) * t) + 2.75 - Math.sin(t * Math.PI) * 0.22;
        const w = 0.75 + rng() * 0.5, h = 0.9 + rng() * 0.6;
        const geo = new THREE.PlaneGeometry(w, h, 5, 6);
        // Pin the top edge: the wind material flexes on uv.x, so rotate the
        // plane's UVs into place by building it "sideways" then turning it.
        geo.translate(0, -h / 2, 0);
        geo.rotateZ(Math.PI / 2);
        geo.rotateY(a);
        const mesh = new THREE.Mesh(geo, cloth);
        mesh.position.set(gx, gy, gz);
        mesh.castShadow = true;
        g.add(mesh);
      }
      made++;
    }
    this.group.add(g);
  }

  /**
   * Cobbles. A worn stone apron over the plaza and the first stretch of each
   * lane — the single strongest cue that people live here, because bare
   * heightfield ground always reads as terrain rather than as a street.
   */
  _buildCobbles(materials, rng) {
    const V = WORLD.village;
    const g = new THREE.Group();
    g.name = 'Cobbles';

    // Cobbles, not dinner plates: 0.5 m stones read as stepping stones.
    const stone = new THREE.CylinderGeometry(0.26, 0.21, 0.16, 6);
    const spots = [];
    // Radial rings around the plaza, thinning out.
    for (let ring = 0; ring < 16; ring++) {
      const r = 1.2 + ring * 0.92;
      const n = Math.max(8, Math.round(r * 7.0));
      for (let i = 0; i < n; i++) {
        const a = (i / n) * TAU + ring * 0.31;
        const jx = (rng() - 0.5) * 0.26, jz = (rng() - 0.5) * 0.26;
        const x = V.x + Math.cos(a) * r + jx;
        const z = V.z + Math.sin(a) * r + jz;
        // Thin out with distance so the apron has a soft edge.
        if (rng() > 1.05 - ring / 18) continue;
        if (isOnLava(x, z) || isOnWater(x, z)) continue;
        spots.push([x, z]);
      }
    }
    if (!spots.length) return g;

    const inst = new THREE.InstancedMesh(stone, materials.get('stone'), spots.length);
    inst.receiveShadow = true;
    inst.castShadow = false;
    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const p = new THREE.Vector3();
    const s = new THREE.Vector3();
    const up = new THREE.Vector3(0, 1, 0);
    for (let i = 0; i < spots.length; i++) {
      const [x, z] = spots[i];
      const sc = 0.85 + rng() * 0.5;
      p.set(x, height(x, z) - 0.015, z);
      q.setFromAxisAngle(up, rng() * TAU);
      s.set(sc, 0.5 + rng() * 0.5, sc * (0.9 + rng() * 0.25));
      m.compose(p, q, s);
      inst.setMatrixAt(i, m);
    }
    g.add(inst);
    this.cobbleCount = spots.length;
    return g;
  }

  update(dt, elapsed) {
    // Signs creak in the wind.
    for (const s of this.signBoards ?? []) {
      s.pivot.rotation.z = Math.sin(elapsed * 0.9 + s.phase) * 0.06
                         + Math.sin(elapsed * 2.3 + s.phase) * 0.015;
    }
  }

  dispose() { this.group.traverse((o) => o.geometry?.dispose()); }
}
