/**
 * Vegetation: the ash-forest and the grass.
 *
 * LOD & culling strategy — the forest is diced into a 3×3 grid of tiles. Each
 * tile owns two InstancedMeshes (detailed / reduced) and swaps between them on
 * camera distance, then hides entirely past the far plane. Three's own frustum
 * culling then works *per tile* instead of all-or-nothing on one giant mesh, so
 * standing in the village doesn't pay for the trees behind the volcano.
 *
 * Every trunk, frond and blade carries an `aFlex` attribute (0 at the root, 1
 * at the tip) which the shared wind shader uses — one gust field, thousands of
 * plants, all in phase.
 */
import * as THREE from 'three';
import * as BGU from 'three/addons/utils/BufferGeometryUtils.js';
import { makeRng, noise } from '../utils/Noise.js';
import { scatterPoints, TAU, clamp, smoothstep } from '../utils/MathX.js';
import { height, canPlant, lavaProximity, WORLD, normalAt } from './Heightfield.js';

/* ── geometry factories ───────────────────────────────────────────────── */

/** Add an aFlex attribute: 0 at `base` height, 1 at `tip`. */
function flex(geo, base, tip, power = 1.35) {
  const p = geo.attributes.position;
  const f = new Float32Array(p.count);
  for (let i = 0; i < p.count; i++) {
    const t = clamp((p.getY(i) - base) / (tip - base || 1), 0, 1);
    f[i] = Math.pow(t, power);
  }
  geo.setAttribute('aFlex', new THREE.BufferAttribute(f, 1));
  return geo;
}

function tint(geo, color, variance = 0.12, rng = Math.random) {
  const p = geo.attributes.position;
  const c = new Float32Array(p.count * 3);
  const base = new THREE.Color(color);
  const tmp = new THREE.Color();
  for (let i = 0; i < p.count; i++) {
    const v = 1 + (rng() - 0.5) * variance * 2;
    // Darken toward the interior of the canopy.
    const shade = 0.72 + clamp(p.getY(i) / 24, 0, 1) * 0.5;
    tmp.copy(base).multiplyScalar(v * shade);
    c[i * 3] = tmp.r; c[i * 3 + 1] = tmp.g; c[i * 3 + 2] = tmp.b;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(c, 3));
  return geo;
}

/** Intersecting foliage cards retain twig-sized gaps at a fraction of the
 * old closed-canopy triangle count. UV halves select the shared species atlas. */
function canopyCards(h, width, species, detail, rng) {
  const parts = [];
  const count = detail ? 3 : 2;
  for (let i = 0; i < count; i++) {
    const g = new THREE.PlaneGeometry(width, h, 1, 4);
    const uv = g.attributes.uv;
    for (let v = 0; v < uv.count; v++) uv.setX(v, (uv.getX(v) + species) * 0.5);
    g.translate(0, h * 0.5, 0);
    g.rotateY(i * Math.PI / count);
    parts.push(g);
  }
  const geo = BGU.mergeGeometries(parts);
  parts.forEach(g => g.dispose());
  return tint(flex(geo, 0, h), 0xffffff, 0.06, rng);
}

/** Conifer: tapered trunk + stacked skirts. `detail` drives segment counts. */
function buildConifer(rng, detail = 1) {
  const h = 16 + rng() * 16;
  const radial = detail ? 8 : 5;
  const trunkR = 0.5 + h * 0.022;

  const trunkParts = [];
  const trunk = new THREE.CylinderGeometry(trunkR * 0.45, trunkR, h, radial, detail ? 3 : 1);
  trunk.translate(0, h / 2, 0);
  // Lean the whole tree slightly — perfectly vertical forests look CG.
  const lean = (rng() - 0.5) * 0.16;
  trunk.rotateZ(lean);
  trunkParts.push(trunk);

  if (detail) {
    const branches = 3 + Math.floor(rng() * 3);
    for (let i = 0; i < branches; i++) {
      const t = 0.35 + rng() * 0.5;
      const bl = 2.5 + rng() * 3.5;
      const b = new THREE.CylinderGeometry(0.10, 0.22, bl, 4, 1);
      b.translate(0, bl / 2, 0);
      b.rotateZ(Math.PI * (0.28 + rng() * 0.16) * (rng() > 0.5 ? 1 : -1));
      b.rotateY(rng() * TAU);
      b.translate(0, h * t, 0);
      trunkParts.push(b);
    }
  }

  const trunkGeo = flex(BGU.mergeGeometries(trunkParts), 0, h, 2.2);
  const leafGeo = canopyCards(h * 1.07, h * 0.67, 0, detail, rng);
  trunkParts.forEach(g => g.dispose());
  return { trunkGeo, leafGeo, height: h };
}

/** Charred snag — no canopy, for the scorched ground near the lava. */
function buildSnag(rng) {
  const h = 9 + rng() * 12;
  const parts = [];
  const t = new THREE.CylinderGeometry(0.12, 0.75, h, 6, 2);
  t.translate(0, h / 2, 0);
  t.rotateZ((rng() - 0.5) * 0.5);
  parts.push(t);
  const n = 2 + Math.floor(rng() * 3);
  for (let i = 0; i < n; i++) {
    const bl = 2 + rng() * 5;
    const b = new THREE.CylinderGeometry(0.05, 0.2, bl, 4, 1);
    b.translate(0, bl / 2, 0);
    b.rotateZ(Math.PI * (0.3 + rng() * 0.2) * (rng() > 0.5 ? 1 : -1));
    b.rotateY(rng() * TAU);
    b.translate(0, h * (0.4 + rng() * 0.5), 0);
    parts.push(b);
  }
  const geo = flex(BGU.mergeGeometries(parts), 0, h, 2.0);
  parts.forEach((g) => g.dispose());
  return geo;
}

/** Broadleaf: a gnarled trunk with blobby foliage clusters. */
function buildBroadleaf(rng, detail = 1) {
  const h = 12 + rng() * 12;
  const radial = detail ? 7 : 5;
  const parts = [];
  const trunk = new THREE.CylinderGeometry(0.34, 0.9, h * 0.62, radial, detail ? 3 : 1);
  trunk.translate(0, h * 0.31, 0);
  parts.push(trunk);

  const trunkGeo = flex(BGU.mergeGeometries(parts), 0, h, 2.4);
  const leafGeo = canopyCards(h, h * 0.88, 1, detail, rng);
  parts.forEach(g => g.dispose());
  return { trunkGeo, leafGeo, height: h };
}

/* ── forest ───────────────────────────────────────────────────────────── */

const TILE_DIV = 3;

export class Forest {
  constructor(materials, settings) {
    this.group = new THREE.Group();
    this.group.name = 'Forest';
    this.settings = settings;
    this.tiles = [];

    const rng = makeRng(4242);
    const trunkMat = materials.get('trunk');
    const leafMat = materials.get('foliage');
    const barkMat = materials.get('woodDark');
    const canopyDepth = new THREE.MeshDepthMaterial({
      map: leafMat.map, alphaTest: leafMat.alphaTest,
      side: THREE.DoubleSide, depthPacking: THREE.RGBADepthPacking,
    });

    // Build a small library of species/variants, then instance them.
    const VARIANTS = 5;
    const lib = [];
    for (let i = 0; i < VARIANTS; i++) {
      const broad = i >= 3;
      lib.push({
        hi: broad ? buildBroadleaf(rng, 1) : buildConifer(rng, 1),
        lo: broad ? buildBroadleaf(makeRng(9000 + i), 0) : buildConifer(makeRng(9000 + i), 0),
      });
    }
    const snagGeo = buildSnag(makeRng(777));

    // ── scatter ─────────────────────────────────────────────────────
    const total = settings.treeCount;
    const points = [];
    // Two clusters: the southern forest basin and a thinner belt west of the castle.
    const zones = [
      { c: [40, 620], r: 620, share: 0.62 },
      { c: [-520, 300], r: 380, share: 0.20 },
      { c: [420, 480], r: 320, share: 0.18 },
    ];
    for (const z of zones) {
      const pts = scatterPoints({
        count: Math.round(total * z.share),
        radius: z.r, center: z.c, minDist: 7.5, rng,
        reject: (x, zz) => !canPlant(x, zz),
      });
      points.push(...pts);
    }

    // Charred snags live where nothing else can.
    const snagPts = scatterPoints({
      count: Math.round(total * 0.11),
      radius: 520, center: [-90, 40], minDist: 11, rng,
      reject: (x, z) => {
        const lp = lavaProximity(x, z);
        return lp < 0.28 || lp > 0.92 || height(x, z) < 4;
      },
    });

    // ── bucket into tiles ───────────────────────────────────────────
    const buckets = Array.from({ length: TILE_DIV * TILE_DIV }, () => []);
    const snagBuckets = Array.from({ length: TILE_DIV * TILE_DIV }, () => []);
    const tileOf = (x, z) => {
      const ix = clamp(Math.floor(((x + WORLD.half) / WORLD.size) * TILE_DIV), 0, TILE_DIV - 1);
      const iz = clamp(Math.floor(((z + WORLD.half) / WORLD.size) * TILE_DIV), 0, TILE_DIV - 1);
      return iz * TILE_DIV + ix;
    };
    for (const p of points) buckets[tileOf(p[0], p[1])].push(p);
    for (const p of snagPts) snagBuckets[tileOf(p[0], p[1])].push(p);

    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const pos = new THREE.Vector3();
    const scl = new THREE.Vector3();
    const up = new THREE.Vector3(0, 1, 0);
    const nrm = new THREE.Vector3();

    for (let ti = 0; ti < buckets.length; ti++) {
      const list = buckets[ti];
      const snagList = snagBuckets[ti];
      if (!list.length && !snagList.length) continue;

      const tile = new THREE.Group();
      tile.name = `ForestTile${ti}`;
      const hiGroup = new THREE.Group();
      const loGroup = new THREE.Group();
      tile.add(hiGroup, loGroup);

      // Split this tile's trees across the variant library.
      const perVariant = Array.from({ length: VARIANTS }, () => []);
      for (const p of list) perVariant[Math.floor(rng() * VARIANTS)].push(p);

      const center = new THREE.Vector3();
      let n = 0;

      for (let v = 0; v < VARIANTS; v++) {
        const pts = perVariant[v];
        if (!pts.length) continue;
        const { hi, lo } = lib[v];

        const hiTrunk = new THREE.InstancedMesh(hi.trunkGeo, trunkMat, pts.length);
        const hiLeaf  = new THREE.InstancedMesh(hi.leafGeo, leafMat, pts.length);
        const loTrunk = new THREE.InstancedMesh(lo.trunkGeo, trunkMat, pts.length);
        const loLeaf  = new THREE.InstancedMesh(lo.leafGeo, leafMat, pts.length);
        hiTrunk.castShadow = hiLeaf.castShadow = true;
        loTrunk.castShadow = loLeaf.castShadow = false;
        hiLeaf.receiveShadow = true;
        hiLeaf.customDepthMaterial = loLeaf.customDepthMaterial = canopyDepth;

        for (let i = 0; i < pts.length; i++) {
          const [x, z] = pts[i];
          const y = height(x, z);
          const s = 0.55 + Math.pow(rng(), 0.65) * 1.05;
          // Slight tilt away from the slope normal keeps hillside trees natural.
          const [nx, ny, nz] = normalAt(x, z, 8);
          nrm.set(nx, ny, nz);
          q.setFromUnitVectors(up, nrm.lerp(up, 0.72).normalize());
          const spin = new THREE.Quaternion().setFromAxisAngle(up, rng() * TAU);
          q.multiply(spin);
          pos.set(x, y - 0.6, z);
          scl.set(s, s * (0.86 + rng() * 0.3), s);
          m.compose(pos, q, scl);
          hiTrunk.setMatrixAt(i, m); hiLeaf.setMatrixAt(i, m);
          loTrunk.setMatrixAt(i, m); loLeaf.setMatrixAt(i, m);
          center.add(pos); n++;
        }
        hiGroup.add(hiTrunk, hiLeaf);
        loGroup.add(loTrunk, loLeaf);
      }

      if (snagList.length) {
        const snags = new THREE.InstancedMesh(snagGeo, barkMat, snagList.length);
        snags.castShadow = true;
        for (let i = 0; i < snagList.length; i++) {
          const [x, z] = snagList[i];
          const s = 0.8 + rng() * 0.8;
          pos.set(x, height(x, z) - 0.5, z);
          q.setFromAxisAngle(up, rng() * TAU);
          scl.set(s, s * (0.8 + rng() * 0.5), s);
          m.compose(pos, q, scl);
          snags.setMatrixAt(i, m);
          center.add(pos); n++;
        }
        hiGroup.add(snags);
        loGroup.add(snags.clone());
      }

      if (n) center.divideScalar(n);
      loGroup.visible = false;
      this.tiles.push({ node: tile, hi: hiGroup, lo: loGroup, center, radius: WORLD.size / TILE_DIV });
      this.group.add(tile);
    }

    this._treeCount = points.length + snagPts.length;
  }

  get treeCount() { return this._treeCount; }

  /** Distance-based LOD swap + far cull. */
  update(dt, camera) {
    const cp = camera.position;
    for (const t of this.tiles) {
      const d = Math.hypot(cp.x - t.center.x, cp.z - t.center.z) - t.radius * 0.5;
      const near = d < 420;
      const visible = d < 1750;
      t.node.visible = visible;
      if (!visible) continue;
      if (t.hi.visible !== near) { t.hi.visible = near; t.lo.visible = !near; }
    }
  }

  dispose() {
    this.group.traverse((o) => { if (o.isInstancedMesh) o.geometry.dispose(); });
  }
}

/* ── grass ────────────────────────────────────────────────────────────── */

export class Grass {
  constructor(materials, settings) {
    this.group = new THREE.Group();
    this.group.name = 'Grass';
    if (!settings.grassCount) return;

    // A crossed pair of quads (two blade strips 90° apart), not one flat quad.
    //
    // A single quad has a random yaw per instance and no billboarding, so from
    // most camera angles it's seen close to edge-on — a plane viewed near its
    // own edge degenerates to a hairline, so every field of this grass reads
    // as thin bright vertical streaks (only the rim gets a specular kick,
    // there's no width left to shade). Crossing two quads at 90° guarantees
    // at least one of them always presents real width to the camera, which is
    // the standard fix for flat-card vegetation (same trick as Minecraft's
    // cross-plane grass/saplings).
    const blade = (() => {
      const h = 1.0, w = 0.075;
      const pos = [], idx = [], f = [], col = [];
      const rungs = 4;
      const buildStrip = (angle, vertBase) => {
        const cx = Math.cos(angle), cz = Math.sin(angle);
        for (let i = 0; i <= rungs; i++) {
          const t = i / rungs;
          const y = t * h;
          const taper = (1 - t * 0.85);
          const hw = w * taper;
          pos.push(-hw * cx, y, -hw * cz,  hw * cx, y, hw * cz);
          f.push(t, t);
        }
        for (let i = 0; i < rungs; i++) {
          const a = vertBase + i * 2, b = vertBase + (i + 1) * 2;
          idx.push(a, b, a + 1, b, b + 1, a + 1);   // material is DoubleSide, one winding is enough
        }
      };
      buildStrip(0, 0);
      buildStrip(Math.PI / 2, (rungs + 1) * 2);
      // The shared foliage material declares vertexColors, so the blade needs a
      // white base colour for instanceColor to modulate.
      for (let i = 0; i < pos.length / 3; i++) col.push(1, 1, 1);
      const g = new THREE.BufferGeometry();
      g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
      g.setAttribute('aFlex', new THREE.Float32BufferAttribute(f, 1));
      g.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
      g.setIndex(idx);
      g.computeVertexNormals();
      return g;
    })();

    const count = settings.grassCount;
    const rng = makeRng(31337);
    const mat = materials.get('grass');

    // Vertex colours per instance aren't possible on a shared geometry, so we
    // vary scale/rotation instead and let the terrain colour show through.
    const mesh = new THREE.InstancedMesh(blade, mat, count);
    mesh.castShadow = false;
    mesh.receiveShadow = false;
    mesh.name = 'GrassField';

    const colors = new Float32Array(count * 3);
    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const p = new THREE.Vector3();
    const s = new THREE.Vector3();
    const up = new THREE.Vector3(0, 1, 0);
    const c = new THREE.Color();

    // Grass hugs the village, the temple approach and the river banks.
    const zones = [
      { c: [WORLD.village.x, WORLD.village.z], r: 300, share: 0.45 },
      { c: [WORLD.temple.x, WORLD.temple.z], r: 240, share: 0.25 },
      { c: [360, 470], r: 280, share: 0.30 },
    ];
    let i = 0;
    for (const z of zones) {
      const n = Math.round(count * z.share);
      const pts = scatterPoints({
        count: n, radius: z.r, center: z.c, rng,
        reject: (x, zz) => {
          if (lavaProximity(x, zz) > 0.25 || height(x, zz) < 4) return true;
          // Nothing grows through a cobbled square.
          const dp = Math.hypot(x - WORLD.village.x, zz - WORLD.village.z);
          return dp < 19;
        },
      });
      for (const [x, zz] of pts) {
        if (i >= count) break;
        const y = height(x, zz);
        // noise*0.5+0.5 remaps [-1,1] to [0,1] — the extra "+ 0.5" here duplicated
        // that offset, so lush actually ranged 0.5..1.5 instead of 0..1. That let
        // blade height (below) run up past 1.4 m and pushed instance colour well
        // past white, which is what was aliasing into bright streaks at range.
        const lush = smoothstep(0.35, 0.0, lavaProximity(x, zz)) * (0.5 + noise.fbm2(x * 0.01, zz * 0.01, 3) * 0.5);
        // Ankle-to-knee. At 1.6 m these read as orange traffic cones from
        // inside walk mode, which is exactly what they looked like.
        const sc = (0.30 + rng() * 0.55) * (0.6 + lush * 0.7);
        p.set(x, y - 0.08, zz);
        q.setFromAxisAngle(up, rng() * TAU);
        s.set(sc * (0.7 + rng() * 0.6), sc, 1);
        m.compose(p, q, s);
        mesh.setMatrixAt(i, m);
        c.setRGB(0.16 + lush * 0.14, 0.21 + lush * 0.28, 0.08 + lush * 0.09);
        const dry = 1 - lush;
        c.r += dry * 0.22; c.g += dry * 0.14;
        colors[i * 3] = c.r; colors[i * 3 + 1] = c.g; colors[i * 3 + 2] = c.b;
        i++;
      }
    }
    mesh.count = i;
    mesh.instanceColor = new THREE.InstancedBufferAttribute(colors, 3);
    mesh.instanceColor.needsUpdate = true;
    this.mesh = mesh;
    this.group.add(mesh);
  }

  update() { /* wind is in-shader */ }

  dispose() { this.mesh?.geometry.dispose(); }
}
