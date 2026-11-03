/**
 * Modular building blocks.
 *
 * Every structure in the realm is assembled from these, then merged per-material
 * so a whole castle costs ~4 draw calls. Each helper returns a plain
 * BufferGeometry already positioned in the structure's local space.
 *
 * The `damage` parameter runs through most of them: it randomly deletes blocks,
 * slumps courses and knocks the tops off things. That single knob is what turns
 * a tidy procedural fort into a ruin.
 */
import * as THREE from 'three';
import * as BGU from 'three/addons/utils/BufferGeometryUtils.js';
import { TAU, clamp } from '../utils/MathX.js';

export const box = (w, h, d, x = 0, y = 0, z = 0, ry = 0) => {
  const g = new THREE.BoxGeometry(w, h, d);
  if (ry) g.rotateY(ry);
  g.translate(x, y, z);
  return g;
};

/** A course of individually-jittered blocks — reads as masonry, not a slab. */
export function blockWall(length, wHeight, thickness, {
  blockW = 3.2, blockH = 1.6, rng = Math.random, damage = 0, jitter = 0.12, taper = 0,
} = {}) {
  const parts = [];
  const courses = Math.max(1, Math.round(wHeight / blockH));
  for (let c = 0; c < courses; c++) {
    const y = c * blockH + blockH / 2;
    const t = c / courses;
    // Ruins lose their upper courses first, and unevenly along the run.
    const survive = 1 - damage * clamp((t - 0.35) / 0.65, 0, 1) * 1.35;
    const off = (c % 2) * blockW * 0.5;
    const n = Math.ceil(length / blockW) + 1;
    for (let i = 0; i < n; i++) {
      const x = -length / 2 + off + i * blockW;
      if (x < -length / 2 - blockW * 0.4 || x > length / 2 + blockW * 0.4) continue;
      const edgeBias = 1 - Math.abs(x) / (length / 2) * 0.35;
      if (rng() > survive * edgeBias) continue;
      const w = Math.min(blockW, length / 2 - x + blockW) * (0.92 + rng() * 0.1);
      const th = thickness * (1 - taper * t);
      const g = new THREE.BoxGeometry(Math.max(0.4, w), blockH * (0.95 + rng() * 0.08), th);
      g.translate(
        clamp(x, -length / 2 + w / 2, length / 2 - w / 2) + (rng() - 0.5) * jitter,
        y + (rng() - 0.5) * jitter * 0.6,
        (rng() - 0.5) * jitter * 2,
      );
      if (damage > 0.01) g.rotateZ((rng() - 0.5) * damage * 0.06);
      parts.push(g);
    }
  }
  return parts;
}

export function crenellations(length, thickness, y, { merlon = 1.9, gap = 1.5, rng = Math.random, damage = 0 } = {}) {
  const parts = [];
  const step = merlon + gap;
  const n = Math.floor(length / step);
  for (let i = 0; i <= n; i++) {
    if (rng() < damage * 0.8) continue;
    const x = -length / 2 + i * step + merlon / 2;
    parts.push(box(merlon, 1.7 + rng() * 0.3, thickness * 0.85, x, y + 0.85, 0));
  }
  return parts;
}

/** Round tower: tapered drum, string course, machicolation ring, conical roof. */
export function tower(radius, h, {
  segments = 12, rng = Math.random, damage = 0, roof = true, crenel = true, taper = 0.86,
} = {}) {
  const parts = [];
  const drumH = h * (1 - damage * 0.35 * rng());
  const drum = new THREE.CylinderGeometry(radius * taper, radius, drumH, segments, Math.max(2, Math.round(drumH / 4)));
  drum.translate(0, drumH / 2, 0);
  parts.push(drum);

  const ring = new THREE.CylinderGeometry(radius * taper * 1.14, radius * taper * 1.06, 1.1, segments, 1);
  ring.translate(0, drumH - 0.6, 0);
  parts.push(ring);

  if (crenel) {
    const n = Math.max(6, Math.round(segments * 1.4));
    for (let i = 0; i < n; i++) {
      if (rng() < damage) continue;
      const a = (i / n) * TAU;
      const r = radius * taper * 1.05;
      const m = box(1.5, 1.8, 1.0, Math.cos(a) * r, drumH + 0.9, Math.sin(a) * r, -a);
      parts.push(m);
    }
  }

  if (roof && damage < 0.5) {
    const rh = radius * 2.1;
    const cone = new THREE.ConeGeometry(radius * 1.24, rh, segments, 2);
    cone.translate(0, drumH + 1.8 + rh / 2, 0);
    parts.push(cone);
    const finial = new THREE.CylinderGeometry(0.12, 0.12, 3, 5);
    finial.translate(0, drumH + 1.8 + rh + 1.4, 0);
    parts.push(finial);
  }
  return { parts, height: drumH };
}

/** Voussoir arch — real wedge blocks, so lighting reads correctly in the vault. */
export function arch(span, rise, thickness, { blocks = 13, depth = 3, rng = Math.random } = {}) {
  const parts = [];
  for (let i = 0; i < blocks; i++) {
    const t = (i + 0.5) / blocks;
    const a = Math.PI * t;
    const r = span / 2;
    const x = -Math.cos(a) * r;
    const y = Math.sin(a) * rise;
    const w = (Math.PI * r) / blocks * 1.12;
    const g = new THREE.BoxGeometry(w, thickness, depth);
    g.rotateZ(a - Math.PI / 2);
    g.translate(x, y, 0);
    parts.push(g);
  }
  return parts;
}

/** Fluted column with base and capital. */
export function column(radius, h, { flutes = 12, rng = Math.random, broken = 0 } = {}) {
  const parts = [];
  const use = h * (1 - broken);
  const shaft = new THREE.CylinderGeometry(radius * 0.86, radius, use, flutes, Math.max(2, Math.round(use / 3)));
  shaft.translate(0, use / 2, 0);
  parts.push(shaft);
  parts.push(box(radius * 2.6, 0.9, radius * 2.6, 0, 0.45, 0));
  if (broken < 0.05) {
    parts.push(box(radius * 2.4, 0.8, radius * 2.4, 0, use + 0.4, 0));
    parts.push(box(radius * 2.9, 0.5, radius * 2.9, 0, use + 1.05, 0));
  } else {
    // Fracture: a tilted stub sitting on the break.
    const stub = new THREE.CylinderGeometry(radius * 0.8, radius * 0.9, 1.6, flutes, 1);
    stub.rotateZ((rng() - 0.5) * 0.5);
    stub.translate((rng() - 0.5) * 0.6, use + 0.7, (rng() - 0.5) * 0.6);
    parts.push(stub);
  }
  return parts;
}

/** Gabled roof as a prism, optionally hipped. */
export function roofPrism(w, d, h, { overhang = 0.5, ridgeShift = 0 } = {}) {
  const W = w / 2 + overhang, D = d / 2 + overhang;
  const v = [
    -W, 0, -D,   W, 0, -D,   W, 0, D,   -W, 0, D,          // eaves
    -W + ridgeShift, h, 0,   W + ridgeShift, h, 0,          // ridge
  ];
  // Winding matters: with these reversed, back-face culling hid both slopes and
  // left the soffit facing the sky — every roof in the village rendered as a
  // flat white table with a dark cap.
  const idx = [
    0, 5, 1, 0, 4, 5,     // back slope   (normal +Y −Z)
    3, 5, 4, 3, 2, 5,     // front slope  (normal +Y +Z)
    0, 3, 4,              // left gable
    1, 5, 2,              // right gable
    0, 2, 3, 0, 1, 2,     // soffit       (normal −Y)
  ];
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(v, 3));
  g.setIndex(idx);
  g.computeVertexNormals();
  // Cheap planar UVs so the tile/thatch texture has something to sit on.
  const p = g.attributes.position;
  const uv = new Float32Array(p.count * 2);
  for (let i = 0; i < p.count; i++) {
    uv[i * 2] = (p.getX(i) + W) / (2 * W);
    uv[i * 2 + 1] = (p.getY(i) / h) * 0.8 + (p.getZ(i) + D) / (4 * D);
  }
  g.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
  return g;
}

export function stairs(width, rise, run, steps, { rng = Math.random } = {}) {
  const parts = [];
  for (let i = 0; i < steps; i++) {
    parts.push(box(width, rise, run, 0, rise * (i + 0.5), -run * i));
  }
  return parts;
}

/** Merge with a guard: mergeGeometries throws on an empty list. */
export function mergeSafe(parts) {
  const clean = parts.filter(Boolean);
  if (!clean.length) return null;
  const merged = BGU.mergeGeometries(clean, false);
  clean.forEach((g) => g.dispose());
  if (merged) { merged.computeBoundingSphere(); merged.computeBoundingBox(); }
  return merged;
}

/** Build a mesh from parts, or null. */
export function meshFrom(parts, material, { cast = true, receive = true, name = '' } = {}) {
  const geo = mergeSafe(parts);
  if (!geo) return null;
  const m = new THREE.Mesh(geo, material);
  m.castShadow = cast;
  m.receiveShadow = receive;
  if (name) m.name = name;
  return m;
}
