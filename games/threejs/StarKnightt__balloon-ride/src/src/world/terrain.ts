/**
 * Terrain meshes. The heightfield goes to the GPU as a float texture; the land is drawn as square
 * chunks of one shared grid patch per LOD (fine near the camera, coarse far), each LOD a single
 * InstancedMesh whose instances are the visible chunks at that LOD (CPU frustum test per chunk),
 * so the whole heightfield costs four draw calls. Skirts hide the cracks where LODs meet.
 * A coarse far ring carries the land on past the grid to the haze, and the water is one flat
 * surface over every grid cell that dips below the water level.
 */
import * as THREE from "three";
import { GRID_HALF, OUTER_HALF, WATER_Y } from "./layout";
import { N, STEP, farHeight, groundHeight, heights } from "./heightfield";
import { LAND, terrainMaterial, waterMaterial } from "../render/landMaterials";

/** Cells per chunk side, and the LOD steps (cells per patch quad). */
const CHUNK = 128;
const LODS = [1, 2, 4, 8];
/** Camera distance (m) to a chunk's nearest point at which each LOD ends. */
const LOD_DIST = [520, 1300, 2800, Infinity];

function patch(step: number): THREE.BufferGeometry {
  const n = CHUNK / step + 1;
  const pos: number[] = [];
  for (let j = 0; j < n; j++) for (let i = 0; i < n; i++) pos.push(i * step, 0, j * step);
  const idx: number[] = [];
  for (let j = 0; j < n - 1; j++) for (let i = 0; i < n - 1; i++) {
    const a = j * n + i, b = a + 1, c = a + n, d = c + 1;
    // Diagonal from (i+1, j) to (i, j+1), as groundHeight assumes.
    idx.push(a, c, b, b, c, d);
  }
  // Skirt: a second ring along the border hanging down (y = 1 flags a skirt vertex).
  const ring: number[] = [];
  for (let i = 0; i < n - 1; i++) ring.push(i);
  for (let j = 0; j < n - 1; j++) ring.push(j * n + n - 1);
  for (let i = n - 1; i > 0; i--) ring.push((n - 1) * n + i);
  for (let j = n - 1; j > 0; j--) ring.push(j * n);
  const s0 = pos.length / 3;
  for (const v of ring) pos.push(pos[v * 3], 1, pos[v * 3 + 2]);
  for (let k = 0; k < ring.length; k++) {
    const a = ring[k], b = ring[(k + 1) % ring.length];
    const sa = s0 + k, sb = s0 + ((k + 1) % ring.length);
    idx.push(a, sa, b, b, sa, sb, a, b, sa, b, sb, sa);
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setIndex(idx);
  g.boundingSphere = new THREE.Sphere(new THREE.Vector3(), 1e7);
  return g;
}

interface Chunk {
  ci: number;
  cj: number;
  box: THREE.Box3;
}

export class Terrain {
  readonly group = new THREE.Group();
  private readonly lod: THREE.InstancedMesh[] = [];
  private readonly chunks: Chunk[] = [];
  private readonly frustum = new THREE.Frustum();
  private readonly pv = new THREE.Matrix4();
  private readonly m = new THREE.Matrix4();
  readonly water: THREE.Mesh;
  /** Chunks drawn per LOD last frame. */
  readonly counts = [0, 0, 0, 0];

  constructor() {
    const tex = new THREE.DataTexture(heights, N, N, THREE.RedFormat, THREE.FloatType);
    tex.minFilter = tex.magFilter = THREE.NearestFilter;
    tex.generateMipmaps = false;
    tex.needsUpdate = true;
    LAND.uHeight.value = tex;
    LAND.uGridStep.value = STEP;
    LAND.uGridHalf.value = GRID_HALF;
    LAND.uGridN.value = N;

    const nc = (N - 1) / CHUNK;
    for (let cj = 0; cj < nc; cj++) for (let ci = 0; ci < nc; ci++) {
      let lo = Infinity, hi = -Infinity;
      for (let j = cj * CHUNK; j <= (cj + 1) * CHUNK; j += 2) for (let i = ci * CHUNK; i <= (ci + 1) * CHUNK; i += 2) {
        const h = heights[j * N + i];
        if (h < lo) lo = h;
        if (h > hi) hi = h;
      }
      const x0 = ci * CHUNK * STEP - GRID_HALF, z0 = cj * CHUNK * STEP - GRID_HALF;
      this.chunks.push({ ci, cj, box: new THREE.Box3(new THREE.Vector3(x0, lo - 30, z0), new THREE.Vector3(x0 + CHUNK * STEP, hi + 2, z0 + CHUNK * STEP)) });
    }
    const mat = terrainMaterial(false);
    LODS.forEach((s, k) => {
      const im = new THREE.InstancedMesh(patch(s), mat, this.chunks.length);
      im.name = `terrain lod${k}`;
      im.frustumCulled = false;
      im.count = 0;
      im.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
      this.lod.push(im);
      this.group.add(im);
    });
    this.group.add(this.farRing());
    this.water = this.waterMesh();
    this.group.add(this.water);
  }

  /** Pick each chunk's LOD and cull it against the camera frustum. */
  update(camera: THREE.Camera): void {
    camera.updateMatrixWorld();
    this.frustum.setFromProjectionMatrix(this.pv.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse));
    const cam = camera.position;
    const counts = this.counts;
    counts.fill(0);
    for (const c of this.chunks) {
      if (!this.frustum.intersectsBox(c.box)) continue;
      const d = c.box.distanceToPoint(cam);
      let k = 0;
      while (d > LOD_DIST[k]) k++;
      const s = LODS[k];
      // Instance matrix: translation = chunk origin in cells, x scale = the LOD step.
      this.m.set(s, 0, 0, c.ci * CHUNK, 0, 1, 0, 0, 0, 0, 1, c.cj * CHUNK, 0, 0, 0, 1);
      this.lod[k].setMatrixAt(counts[k]++, this.m);
    }
    this.lod.forEach((im, k) => {
      im.count = counts[k];
      im.instanceMatrix.needsUpdate = true;
    });
  }

  /** Coarse land from the grid edge out to OUTER_HALF (the base rolling height, no features). */
  private farRing(): THREE.Mesh {
    const cell = 125;
    const n = Math.round((OUTER_HALF * 2) / cell);
    const pos: number[] = [], nrm: number[] = [], idx: number[] = [];
    const id = new Int32Array((n + 1) * (n + 1)).fill(-1);
    const inner = GRID_HALF - cell * 1.5;
    const vert = (i: number, j: number) => {
      const k = j * (n + 1) + i;
      if (id[k] >= 0) return id[k];
      const x = i * cell - OUTER_HALF, z = j * cell - OUTER_HALF;
      // Sink a little toward the far edge so it tucks under the painted ridges.
      const r = Math.max(Math.abs(x), Math.abs(z));
      const inGrid = r <= GRID_HALF + 1;
      const hf = (px: number, pz: number) => (inGrid ? groundHeight(px, pz) - 6 : farHeight(px, pz));
      const y = hf(x, z) - Math.max(0, r - 6000) * 0.012;
      const e = 20;
      const hx = hf(x + e, z) - hf(x - e, z), hz = hf(x, z + e) - hf(x, z - e);
      const l = Math.hypot(hx, 2 * e, hz);
      pos.push(x, y, z);
      nrm.push(-hx / l, (2 * e) / l, -hz / l);
      return (id[k] = pos.length / 3 - 1);
    };
    for (let j = 0; j < n; j++) for (let i = 0; i < n; i++) {
      const x0 = i * cell - OUTER_HALF, z0 = j * cell - OUTER_HALF;
      if (x0 >= -inner && x0 + cell <= inner && z0 >= -inner && z0 + cell <= inner) continue;
      const a = vert(i, j), b = vert(i + 1, j), c = vert(i, j + 1), d = vert(i + 1, j + 1);
      idx.push(a, c, b, b, c, d);
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
    g.setAttribute("normal", new THREE.Float32BufferAttribute(nrm, 3));
    g.setIndex(idx);
    g.computeBoundingSphere();
    const m = new THREE.Mesh(g, terrainMaterial(true));
    m.name = "terrain far ring";
    m.matrixAutoUpdate = false;
    m.frustumCulled = false;
    return m;
  }

  /** One flat quad per grid cell that dips under the water, merged along rows. */
  private waterMesh(): THREE.Mesh {
    const pos: number[] = [], idx: number[] = [];
    const wet = (i: number, j: number) => heights[j * N + i] < WATER_Y + 0.4;
    for (let j = 0; j < N - 1; j++) {
      let i = 0;
      while (i < N - 1) {
        const cellWet = (k: number) => wet(k, j) || wet(k + 1, j) || wet(k, j + 1) || wet(k + 1, j + 1);
        if (!cellWet(i)) {
          i++;
          continue;
        }
        let e = i;
        while (e < N - 1 && cellWet(e)) e++;
        const x0 = i * STEP - GRID_HALF, x1 = e * STEP - GRID_HALF, z0 = j * STEP - GRID_HALF, z1 = z0 + STEP;
        const b = pos.length / 3;
        pos.push(x0, WATER_Y, z0, x1, WATER_Y, z0, x0, WATER_Y, z1, x1, WATER_Y, z1);
        idx.push(b, b + 2, b + 1, b + 1, b + 2, b + 3);
        i = e;
      }
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
    g.setIndex(idx);
    g.computeBoundingSphere();
    const m = new THREE.Mesh(g, waterMaterial());
    m.name = "water";
    m.matrixAutoUpdate = false;
    // Drawn after the land, so the hidden parts under the banks fail the depth test early.
    m.renderOrder = 1;
    return m;
  }
}
