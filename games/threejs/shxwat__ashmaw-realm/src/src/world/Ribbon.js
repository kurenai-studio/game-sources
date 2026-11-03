/**
 * Ribbon builder — a strip of quads swept along a polyline and draped over the
 * terrain. Used for lava channels, the river, dirt roads and bridge decks.
 *
 * UVs are (u across, v along-in-metres/scale) so shaders can flow textures
 * *down* the channel regardless of how it curves.
 */
import * as THREE from 'three';
import { CatmullRomCurve3 } from 'three';
import { height } from './Heightfield.js';

export function buildRibbon(path, {
  width = 20,
  widthJitter = 0.25,
  segmentsPerUnit = 1 / 6,
  yOffset = 0.6,
  drape = true,
  flatY = null,
  uvScale = 0.02,
  taperEnds = true,
} = {}) {
  const pts = path.map(([x, z]) => new THREE.Vector3(x, 0, z));
  const curve = new CatmullRomCurve3(pts, false, 'catmullrom', 0.4);
  const total = curve.getLength();
  const steps = Math.max(24, Math.round(total * segmentsPerUnit));

  const position = [];
  const uv = [];
  const index = [];
  const along = [];
  const across = [];

  const p = new THREE.Vector3();
  const tan = new THREE.Vector3();
  const side = new THREE.Vector3();
  const up = new THREE.Vector3(0, 1, 0);

  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    curve.getPointAt(t, p);
    curve.getTangentAt(t, tan);
    side.copy(tan).cross(up).normalize();

    // Channels widen and narrow — pure constant width reads as a pipe.
    const wob = Math.sin(t * 27.3) * 0.5 + Math.sin(t * 11.1 + 2.1) * 0.5;
    let w = width * (1 + wob * widthJitter);
    if (taperEnds) w *= 0.35 + 0.65 * Math.sin(Math.min(1, t * 6) * Math.PI * 0.5) * Math.sin(Math.min(1, (1 - t) * 6) * Math.PI * 0.5 + 0.0001);

    for (let s = -1; s <= 1; s++) {
      const x = p.x + side.x * w * s;
      const z = p.z + side.z * w * s;
      const y = flatY != null ? flatY
              : drape ? height(x, z) + yOffset
              : p.y + yOffset;
      position.push(x, y, z);
      uv.push((s + 1) * 0.5, t * total * uvScale);
      along.push(t);
      across.push(Math.abs(s));
    }
  }

  for (let i = 0; i < steps; i++) {
    const a = i * 3, b = (i + 1) * 3;
    index.push(a, b, a + 1,  b, b + 1, a + 1);
    index.push(a + 1, b + 1, a + 2,  b + 1, b + 2, a + 2);
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(position, 3));
  geo.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
  geo.setAttribute('aAlong', new THREE.Float32BufferAttribute(along, 1));
  geo.setAttribute('aAcross', new THREE.Float32BufferAttribute(across, 1));
  geo.setIndex(index);
  geo.computeVertexNormals();
  geo.computeBoundingSphere();
  geo.userData = { curve, length: total };
  return geo;
}

/** Flat disc for lakes/pools, with a wobbled rim so it isn't obviously a circle. */
export function buildBasin(cx, cz, radius, y, { segments = 96, rings = 6, wobble = 0.12 } = {}) {
  const geo = new THREE.CircleGeometry(1, segments, 0, Math.PI * 2);
  const pos = geo.attributes.position;
  const across = new Float32Array(pos.count);
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), z = pos.getY(i);
    const r = Math.hypot(x, z);
    const a = Math.atan2(z, x);
    const wob = 1 + (Math.sin(a * 3.1) * 0.6 + Math.sin(a * 7.7 + 1.3) * 0.4) * wobble;
    pos.setXY(i, x * radius * wob, z * radius * wob);
    across[i] = r;
  }
  geo.setAttribute('aAcross', new THREE.BufferAttribute(across, 1));
  geo.setAttribute('aAlong', new THREE.BufferAttribute(new Float32Array(pos.count), 1));
  geo.rotateX(-Math.PI / 2);
  geo.translate(cx, y, cz);
  geo.computeVertexNormals();
  geo.computeBoundingSphere();
  return geo;
}
