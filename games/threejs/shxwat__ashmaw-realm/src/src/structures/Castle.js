/**
 * Kaer Ashmaw — the ruined seat of the old kingdom, on its mesa west of the lake.
 *
 * Composition notes (this is a *shot*, not just a model): the great tower is
 * placed so that from the village it silhouettes against the volcano, and its
 * roof is flat and wide because the dragon lands on it. The curtain wall is
 * broken on the volcano side — the story is that Ashmaw came from there.
 *
 * Everything merges down to one mesh per material. Banners are separate because
 * they need the wind shader; braziers are separate because they emit.
 */
import * as THREE from 'three';
import { makeRng } from '../utils/Noise.js';
import { TAU } from '../utils/MathX.js';
import { WORLD, height } from '../world/Heightfield.js';
import { Rocks } from '../world/Rocks.js';
import {
  box, blockWall, crenellations, tower, arch, column, stairs, meshFrom, mergeSafe,
} from './Blocks.js';

export class Castle {
  constructor(materials, settings) {
    this.group = new THREE.Group();
    this.group.name = 'Castle';
    const rng = makeRng(5150);
    const C = WORLD.castle;
    const baseY = height(C.x, C.z);

    this.origin = new THREE.Vector3(C.x, baseY, C.z);
    /** Where the dragon perches. */
    this.perch = new THREE.Vector3();

    const stoneParts = [];
    const woodParts = [];
    const ironParts = [];

    // ── curtain wall: an irregular pentagon, broken toward the volcano ──
    const R = 82;
    const corners = [];
    const sides = 6;
    for (let i = 0; i < sides; i++) {
      const a = (i / sides) * TAU + 0.35;
      const rr = R * (0.86 + rng() * 0.28);
      corners.push([Math.cos(a) * rr, Math.sin(a) * rr, a]);
    }

    for (let i = 0; i < sides; i++) {
      const [x1, z1] = corners[i];
      const [x2, z2] = corners[(i + 1) % sides];
      const mx = (x1 + x2) / 2, mz = (z1 + z2) / 2;
      const len = Math.hypot(x2 - x1, z2 - z1);
      const ang = Math.atan2(x2 - x1, z2 - z1);

      // The two segments facing the volcano (north-west) are the most ruined.
      const facing = Math.atan2(mx, mz);
      const towardVolcano = Math.cos(facing - Math.atan2(WORLD.volcano.x - C.x, WORLD.volcano.z - C.z));
      const damage = 0.16 + Math.max(0, towardVolcano) * 0.72;

      const wallH = 15 - damage * 5;
      const wall = blockWall(len, wallH, 5.5, { rng, damage, blockW: 3.6, blockH: 1.7, taper: 0.12 });
      const crown = crenellations(len, 5.5, wallH, { rng, damage: damage * 1.2 });
      const walkway = damage < 0.5 ? [box(len, 0.6, 6.6, 0, wallH - 0.3, 0)] : [];

      for (const g of [...wall, ...crown, ...walkway]) {
        g.rotateY(-ang + Math.PI / 2);
        g.translate(mx, 0, mz);
        stoneParts.push(g);
      }

      // Corner tower at each vertex.
      const t = tower(9 - damage * 2, 26 - damage * 12, {
        segments: 14, rng, damage, roof: damage < 0.42, crenel: true,
      });
      for (const g of t.parts) { g.translate(x1, 0, z1); stoneParts.push(g); }
    }

    // ── gatehouse (south-east, facing the bridge to the village) ────────
    const gateA = 0.9;
    const gx = Math.cos(gateA) * R * 0.95, gz = Math.sin(gateA) * R * 0.95;
    {
      const parts = [];
      parts.push(...blockWall(26, 21, 8, { rng, damage: 0.1, blockW: 3.4 }));
      parts.push(...crenellations(26, 8, 21, { rng, damage: 0.2 }));
      // Gate void framed by a voussoir arch (we build the arch, and simply omit
      // wall blocks behind it by placing the arch in front of a recess).
      parts.push(...arch(11, 7.5, 1.6, { blocks: 15, depth: 9, rng }));
      parts.push(box(13, 1.4, 9.6, 0, 15.4, 0));
      // Machicolation corbels.
      for (let i = -5; i <= 5; i++) parts.push(box(1.1, 1.6, 2.4, i * 2.2, 17.2, 4.4));
      // Flanking turrets.
      for (const s of [-1, 1]) {
        const t = tower(5.4, 27, { segments: 10, rng, damage: 0.12, roof: true });
        for (const g of t.parts) { g.translate(s * 14.5, 0, 0); parts.push(g); }
      }
      for (const g of parts) {
        g.rotateY(-gateA + Math.PI / 2);
        g.translate(gx, 0, gz);
        stoneParts.push(g);
      }
      // Portcullis.
      const bars = [];
      for (let i = -4; i <= 4; i++) bars.push(box(0.35, 12, 0.35, i * 1.25, 6, 0));
      for (let j = 0; j < 5; j++) bars.push(box(11, 0.3, 0.3, 0, 1.6 + j * 2.4, 0));
      for (const g of bars) {
        g.rotateY(-gateA + Math.PI / 2);
        g.translate(gx, 0, gz);
        ironParts.push(g);
      }
      this._gateLocal = new THREE.Vector3(gx, 0, gz);
    }

    // ── the keep ───────────────────────────────────────────────────────
    {
      const kw = 34, kd = 27, kh = 44;
      const parts = [];
      // Four faces built as block walls so the silhouette is broken.
      const faces = [
        [kw, 0, -kd / 2, 0],
        [kw, 0, kd / 2, 0],
        [kd, -kw / 2, 0, Math.PI / 2],
        [kd, kw / 2, 0, Math.PI / 2],
      ];
      for (const [len, x, z, ry] of faces) {
        const w = blockWall(len, kh, 4.5, { rng, damage: 0.34, blockW: 3.8, blockH: 1.8, taper: 0.08 });
        for (const g of w) { g.rotateY(ry); g.translate(x, 0, z); parts.push(g); }
      }
      // Collapsed floor slabs hanging inside.
      parts.push(box(kw - 8, 0.9, kd - 8, 2, 16, -1));
      parts.push(box(kw - 14, 0.8, kd - 12, -4, 29, 3, 0.14));
      // Gothic window voids implied by framing stones.
      for (let f = 0; f < 3; f++) {
        const y = 12 + f * 11;
        for (const s of [-1, 1]) {
          parts.push(box(1.4, 7, 1.6, s * 7, y + 3.5, -kd / 2 - 0.6));
          parts.push(...arch(5.4, 3.2, 1.2, { blocks: 7, depth: 1.8, rng })
            .map((g) => { g.translate(s * 7 + 0, y + 7, -kd / 2 - 0.6); return g; }));
        }
      }
      for (const g of parts) { g.translate(-26, 0, -14); stoneParts.push(g); }
    }

    // ── the great tower (dragon perch) ─────────────────────────────────
    {
      const tx = 30, tz = 26, r = 15, h = 78;
      const t = tower(r, h, { segments: 18, rng, damage: 0.1, roof: false, crenel: true, taper: 0.8 });
      for (const g of t.parts) { g.translate(tx, 0, tz); stoneParts.push(g); }
      // Flat crown to land on, plus a ring of merlons already added by tower().
      const cap = new THREE.CylinderGeometry(r * 0.84, r * 0.84, 1.4, 18);
      cap.translate(tx, t.height + 0.7, tz);
      stoneParts.push(cap);
      // Buttresses.
      for (let i = 0; i < 5; i++) {
        const a = (i / 5) * TAU;
        const b = box(3.2, h * 0.55, 7, tx + Math.cos(a) * (r + 2), h * 0.275, tz + Math.sin(a) * (r + 2), -a);
        stoneParts.push(b);
      }
      this._perchLocal = new THREE.Vector3(tx, t.height + 2.2, tz);
      this.perchRadius = r * 0.84;
    }

    // ── courtyard, stairs, chapel shell ────────────────────────────────
    stoneParts.push(box(150, 1.2, 150, 0, -0.4, 0));
    {
      const st = stairs(14, 1.1, 1.5, 12, { rng });
      for (const g of st) { g.translate(gx * 0.55, 0, gz * 0.55); stoneParts.push(g); }
    }
    {
      // Chapel: two rows of broken columns and a fallen lintel.
      for (let i = 0; i < 5; i++) {
        for (const s of [-1, 1]) {
          const broken = i > 2 ? 0.3 + rng() * 0.5 : rng() * 0.2;
          const col = column(1.5, 15, { flutes: 12, rng, broken });
          for (const g of col) { g.translate(28 + i * 7.5, 0, -34 + s * 7); stoneParts.push(g); }
        }
      }
      const lintel = box(16, 1.8, 3, 40, 1.2, -34, 0.3);
      lintel.rotateZ(0.12);
      stoneParts.push(lintel);
    }

    // ── timber: hoardings, a ruined hall roof, gate doors ──────────────
    {
      for (let i = 0; i < 7; i++) {
        const a = rng() * TAU;
        const rr = R * (0.55 + rng() * 0.3);
        const beam = box(0.7, 0.7, 9 + rng() * 7, Math.cos(a) * rr, 1.2 + rng() * 9, Math.sin(a) * rr, rng() * TAU);
        beam.rotateZ((rng() - 0.5) * 0.7);
        woodParts.push(beam);
      }
      for (const s of [-1, 1]) {
        const door = box(5.4, 11, 0.7, 0, 5.5, 0);
        door.rotateY(s * 0.55);
        door.translate(gx + s * 2.6, 0, gz);
        woodParts.push(door);
      }
    }

    // ── assemble ───────────────────────────────────────────────────────
    const stone = meshFrom(stoneParts, materials.get('stone'), { name: 'CastleStone' });
    const wood = meshFrom(woodParts, materials.get('woodDark'), { name: 'CastleTimber' });
    const iron = meshFrom(ironParts, materials.get('iron'), { name: 'CastleIron' });
    for (const m of [stone, wood, iron]) if (m) this.group.add(m);

    this.group.add(Rocks.scree(materials, rng, 0, 0, 96, 40));
    this.group.position.set(C.x, baseY, C.z);
    this.group.rotation.y = -0.3;

    // Landmarks must be resolved *after* the group transform, or the dragon
    // lands next to the tower instead of on it.
    this.group.updateMatrixWorld(true);
    this.perch.copy(this._perchLocal).applyMatrix4(this.group.matrixWorld);
    this.gate = this._gateLocal.clone().applyMatrix4(this.group.matrixWorld);

    // ── banners (wind-driven cloth) ─────────────────────────────────────
    this.banners = this._buildBanners(materials, rng, corners, R);
    this.group.add(this.banners);

    // ── braziers ────────────────────────────────────────────────────────
    this.braziers = [];
    const brazierSpots = [[gx * 0.8, gz * 0.8], [gx * 0.62 + 8, gz * 0.62 - 8], [-20, 40], [34, -6], [18, 46]];
    for (const [x, z] of brazierSpots) {
      const b = this._buildBrazier(materials, x, z);
      this.group.add(b.group);
      this.braziers.push(b);
    }
  }

  _buildBanners(materials, rng, corners, R) {
    const g = new THREE.Group();
    g.name = 'Banners';
    const cloth = materials.get('cloth');
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * TAU + 0.2;
      const rr = R * 0.9;
      const w = 4.5, h = 13;
      const geo = new THREE.PlaneGeometry(w, h, 8, 14);
      // aFlex via uv.x is handled by the material (flexExpr: 'uv.x'), and we
      // pin the hoist edge by shifting the plane so x=0 is the pole.
      geo.translate(w / 2, -h / 2, 0);
      const m = new THREE.Mesh(geo, cloth);
      m.castShadow = true;
      m.position.set(Math.cos(a) * rr, 20 + rng() * 5, Math.sin(a) * rr);
      m.rotation.y = -a + Math.PI / 2 + (rng() - 0.5) * 0.4;
      g.add(m);

      const pole = new THREE.Mesh(
        new THREE.CylinderGeometry(0.22, 0.26, h + 6, 6),
        materials.get('woodDark'),
      );
      pole.position.set(m.position.x, m.position.y - h / 2 + 1, m.position.z);
      pole.castShadow = true;
      g.add(pole);
    }
    return g;
  }

  _buildBrazier(materials, x, z) {
    const g = new THREE.Group();
    const bowl = new THREE.Mesh(
      new THREE.CylinderGeometry(1.9, 1.1, 1.5, 10, 1, true),
      materials.get('iron'),
    );
    bowl.position.y = 3.2;
    const legs = new THREE.Mesh(
      new THREE.ConeGeometry(1.5, 3.0, 3, 1, true),
      materials.get('iron'),
    );
    legs.position.y = 1.5;
    legs.rotation.y = 0.4;
    const coals = new THREE.Mesh(
      new THREE.SphereGeometry(1.5, 10, 6, 0, TAU, 0, Math.PI / 2),
      materials.get('emberGlass'),
    );
    coals.position.y = 3.5;
    g.add(bowl, legs, coals);
    g.position.set(x, 0, z);
    const light = new THREE.PointLight(0xff8b3a, 30, 70, 2);
    light.position.set(x, 5, z);
    g.add(light);
    return { group: g, light, world: new THREE.Vector3() };
  }

  update(dt, elapsed) {
    for (let i = 0; i < this.braziers.length; i++) {
      const b = this.braziers[i];
      const f = 0.72 + 0.28 * Math.sin(elapsed * (5 + i) + i * 2.1) * Math.sin(elapsed * 2.3 + i);
      b.light.intensity = 30 * f;
    }
  }

  dispose() { this.group.traverse((o) => o.geometry?.dispose()); }
}
