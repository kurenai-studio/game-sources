/**
 * Wind layers by altitude (docs/research.md §a tuning table). World axes: x east, z south, y up.
 *
 *   low  (< 150 m)   2.5 m/s toward the east
 *   mid  (150-400 m) 4.0 m/s toward the north-east
 *   high (> 400 m)   6.0 m/s toward the north
 *
 * The layers blend with a smoothstep over +-40 m round 150 and 400 m (heading and speed blended
 * separately, so the wind veers with height instead of dying in between). Gusts: +-10 % speed and
 * +-8 degrees of heading on slow 20-40 s noise. Near the map edge the wind turns gently back toward
 * the centre (invisible: the balloon simply drifts round), so the countryside never runs out.
 */
import * as THREE from "three";

const DEG = Math.PI / 180;

/** Heading (radians; 0 = east, -90 deg = north since z points south) and speed (m/s) per layer. */
export const WIND_LAYERS = {
  low: { heading: 0, speed: 2.5, top: 150 },
  mid: { heading: -45 * DEG, speed: 4.0, top: 400 },
  high: { heading: -90 * DEG, speed: 6.0, top: Infinity },
} as const;

/** Blend half-width round each layer boundary (m). */
export const WIND_BLEND = 40;
/** Radius (m from the map centre) where the wind starts turning back, and where it points straight home. */
export const WIND_EDGE = [2200, 3000] as const;

const smooth = (a: number, b: number, x: number) => {
  const t = Math.min(1, Math.max(0, (x - a) / (b - a)));
  return t * t * (3 - 2 * t);
};

/** Smooth 1D value noise in -1..1 (deterministic). */
function noise1(x: number, seed: number): number {
  const i = Math.floor(x), f = x - i;
  const h = (n: number) => {
    const s = Math.sin((n + seed * 17.31) * 127.1) * 43758.5453;
    return (s - Math.floor(s)) * 2 - 1;
  };
  const u = f * f * (3 - 2 * f);
  return h(i) * (1 - u) + h(i + 1) * u;
}

/** Heading and speed of the undisturbed layer wind at altitude y (no gusts, no edge bend). */
export function layerWind(y: number): { heading: number; speed: number } {
  const L = WIND_LAYERS;
  const b1 = smooth(L.low.top - WIND_BLEND, L.low.top + WIND_BLEND, y);
  const b2 = smooth(L.mid.top - WIND_BLEND, L.mid.top + WIND_BLEND, y);
  const heading = L.low.heading + (L.mid.heading - L.low.heading) * b1 + (L.high.heading - L.mid.heading) * b2;
  const speed = L.low.speed + (L.mid.speed - L.low.speed) * b1 + (L.high.speed - L.mid.speed) * b2;
  return { heading, speed };
}

/**
 * The wind at (x, y, z) and time t, written to `out` as (vx, vz) in m/s: layer wind + gusts, bent
 * toward the map centre near the edge.
 */
export function windAt(x: number, y: number, z: number, t: number, out = new THREE.Vector2()): THREE.Vector2 {
  const w = layerWind(y);
  // Gusts: slow, uncorrelated noise on speed and heading (periods ~20-40 s), a little faster aloft.
  const g1 = noise1(t / 27 + y * 0.002, 1) * 0.7 + noise1(t / 11, 2) * 0.3;
  const g2 = noise1(t / 33 + y * 0.003, 3);
  let heading = w.heading + g2 * 8 * DEG;
  const speed = w.speed * (1 + 0.1 * g1);
  // Edge: turn the heading toward the centre along the shorter arc.
  const r = Math.hypot(x, z);
  const k = smooth(WIND_EDGE[0], WIND_EDGE[1], r);
  if (k > 0) {
    const home = Math.atan2(-z, -x);
    let d = home - heading;
    d = Math.atan2(Math.sin(d), Math.cos(d));
    heading += d * k;
  }
  return out.set(Math.cos(heading) * speed, Math.sin(heading) * speed);
}

/** The layer's mean drift (no gusts or edge bend) for cloud motion: (vx, vz) m/s. */
export function layerDrift(y: number, out = new THREE.Vector2()): THREE.Vector2 {
  const w = layerWind(y);
  return out.set(Math.cos(w.heading) * w.speed, Math.sin(w.heading) * w.speed);
}
