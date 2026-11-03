export const TAU = Math.PI * 2;

export function clamp(v: number, min: number, max: number): number {
  return v < min ? min : v > max ? max : v;
}

export function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

/** Smooth 0..1 ramp, used for falloffs where a hard edge would read as a bug. */
export function smoothstep(edge0: number, edge1: number, x: number): number {
  const t = clamp((x - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3 - 2 * t);
}

export function length(x: number, y: number): number {
  return Math.hypot(x, y);
}

/**
 * Slowblue: clamps a vector's magnitude in place-free style. Returns a scale factor
 * so callers can avoid allocating temporary vectors in the hot loop.
 */
export function limitScale(x: number, y: number, max: number): number {
  const m2 = x * x + y * y;
  if (m2 <= max * max || m2 === 0) return 1;
  return max / Math.sqrt(m2);
}
