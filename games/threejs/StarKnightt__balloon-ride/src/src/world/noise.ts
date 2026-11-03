/**
 * Deterministic CPU noise for the world layout (heightfield, parcel jitter, placement masks).
 * Integer-hash value noise: identical on every machine, no Math.random anywhere.
 */

/** 32-bit integer hash of a lattice point and a seed, as 0..1. */
export function hash2(ix: number, iz: number, seed: number): number {
  let h = (ix * 374761393 + iz * 668265263 + seed * 2147483647) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  h ^= h >>> 16;
  return (h >>> 0) / 4294967296;
}

/** Smooth value noise, 0..1. */
export function vnoise(x: number, z: number, seed: number): number {
  const ix = Math.floor(x), iz = Math.floor(z);
  const fx = x - ix, fz = z - iz;
  const ux = fx * fx * (3 - 2 * fx), uz = fz * fz * (3 - 2 * fz);
  const a = hash2(ix, iz, seed), b = hash2(ix + 1, iz, seed);
  const c = hash2(ix, iz + 1, seed), d = hash2(ix + 1, iz + 1, seed);
  return a + (b - a) * ux + (c - a) * uz + (a - b - c + d) * ux * uz;
}

/** Fractal value noise, roughly 0..1 (mean 0.5). */
export function fbm(x: number, z: number, seed: number, oct = 4, lac = 2.03, gain = 0.5): number {
  let a = 0.5, s = 0, n = 0;
  for (let i = 0; i < oct; i++) {
    s += a * vnoise(x, z, seed + i * 131);
    n += a;
    // Rotate each octave a little so lattice rows never line up.
    const nx = x * 0.8 - z * 0.6, nz = x * 0.6 + z * 0.8;
    x = nx * lac + 17.1;
    z = nz * lac - 9.3;
    a *= gain;
  }
  return s / n;
}

export const smooth = (e0: number, e1: number, x: number) => {
  const t = Math.min(1, Math.max(0, (x - e0) / (e1 - e0)));
  return t * t * (3 - 2 * t);
};
