// The road is an endless curve x = roadX(z) at height roadY(z). The default direction of travel is
// -z; the ocean is on the +x side, hills on the -x side. Lateral positions are measured by
// "d" = offset from the road centre. Region shapes (biomes.js) set elevation, shoreline and hills.
import { vnoise, fbm, smoothstep } from './noise.js';
import { biomeMix } from './biomes.js';

export const ROAD_BASE = 2.0;   // road height on a flat beach
export const ROAD_HALF = 5.2;   // half width of the asphalt
export const EDGE = 6.5;        // shoulder edge; terrain shaping starts here
export const LANE = 2.4;        // lane centre offset
export const CHUNK_LEN = 80;    // world is generated in 80 m slices

export function roadX(z) {
  return 38 * Math.sin(z * 0.0032) + 16 * Math.sin(z * 0.0081 + 1.3) + 6 * Math.sin(z * 0.019 + 0.5);
}

export function roadXd(z) {
  return 38 * 0.0032 * Math.cos(z * 0.0032) + 16 * 0.0081 * Math.cos(z * 0.0081 + 1.3) + 6 * 0.019 * Math.cos(z * 0.019 + 0.5);
}

function roadXdd(z) {
  return -38 * 0.0032 ** 2 * Math.sin(z * 0.0032) - 16 * 0.0081 ** 2 * Math.sin(z * 0.0081 + 1.3) - 6 * 0.019 ** 2 * Math.sin(z * 0.019 + 0.5);
}

export function curvature(z) {
  const d1 = roadXd(z);
  return Math.abs(roadXdd(z)) / Math.pow(1 + d1 * d1, 1.5);
}

// Everything that depends only on z, computed once per terrain row.
export function zInfo(z, out = {}) {
  out.m = biomeMix(z, out.m);
  const S = out.m.shape;
  out.rx = roadX(z);
  out.ry = ROAD_BASE + S.rise + Math.sin(z * 0.0047) * (0.4 + S.hills * 0.7);
  out.sd = EDGE + S.shoulder + S.drop + 3 * Math.sin(z * 0.031 + 2.0) + 2 * Math.sin(z * 0.013);
  return out;
}

const tmp = {};
export function roadY(z) { return zInfo(z, tmp).ry; }
export function shoreD(z) { return zInfo(z, tmp).sd; }

export function heightAt(d, x, z, I) {
  const S = I.m.shape, ry = I.ry;
  if (d > EDGE) {
    const s0 = EDGE + S.shoulder;
    if (d < s0) return ry - 0.08;
    const t = (d - s0) / (I.sd - s0);
    let h = t < 1 ? ry * Math.pow(1 - t, S.steep) : Math.max(-(d - I.sd) * 0.09 * (1 + S.steep * 0.4), -9);
    h += (vnoise(x * 0.12, z * 0.12) - 0.5) * 0.35 * smoothstep(s0, s0 + 4, d);
    if (h > 0.5) h += (vnoise(x * 0.35 + 5, z * 0.35) - 0.5) * S.rough * 2 * Math.min(1, h * 0.5);
    return h;
  }
  if (d > -EDGE) return ry;
  const a = -d, flatEnd = EDGE + S.terrace;
  const big = fbm(x * 0.0055 + 31.7, z * 0.0055);
  const small = vnoise(x * 0.04, z * 0.04);
  const hills = (4 + 55 * big * big + 6 * small) * S.hills;
  return ry + smoothstep(flatEnd, flatEnd + 45, a) * hills + smoothstep(EDGE, EDGE + 6, a) * small * (S.terrace > 5 ? 0.3 : 1.2);
}

export function terrainHeight(x, z) {
  const I = zInfo(z, tmp);
  return heightAt(x - I.rx, x, z, I);
}

// Yaw for an object whose local forward is -z, travelling along the road.
// dir = -1 drives toward -z, +1 toward +z.
export function heading(z, dir) {
  return Math.atan2(-roadXd(z) * dir, -dir);
}

// Angle that turns local +x toward the road's +x side (for buildings facing the road).
export function sideAngle(z) {
  return Math.atan(roadXd(z));
}

export const ROAD_GLSL = /* glsl */ `
float roadX(float z) { return 38.0 * sin(z * 0.0032) + 16.0 * sin(z * 0.0081 + 1.3) + 6.0 * sin(z * 0.019 + 0.5); }
uniform sampler2D shoreTex; uniform float shoreZ0; uniform float shoreSpan;
vec2 shoreInfo(float z) { return texture2D(shoreTex, vec2((z - shoreZ0) / shoreSpan, 0.5)).rg; }
`;
