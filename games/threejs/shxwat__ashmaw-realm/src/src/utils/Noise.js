/**
 * Deterministic noise toolkit (CPU side).
 *
 * Simplex 2D/3D after Gustavson's reference implementation, wrapped in a
 * seedable permutation table so the whole world regenerates identically on
 * every load — important, because terrain height is sampled independently by
 * a dozen systems (placement, walk collision, water level, LOD tiles) and they
 * must all agree to the millimetre.
 */

const F2 = 0.5 * (Math.sqrt(3) - 1);
const G2 = (3 - Math.sqrt(3)) / 6;
const F3 = 1 / 3;
const G3 = 1 / 6;

const GRAD3 = [
  [1,1,0],[-1,1,0],[1,-1,0],[-1,-1,0],
  [1,0,1],[-1,0,1],[1,0,-1],[-1,0,-1],
  [0,1,1],[0,-1,1],[0,1,-1],[0,-1,-1],
];

/** xorshift32 — small, fast, good enough for table shuffling. */
export function makeRng(seed = 1337) {
  let s = seed >>> 0 || 1;
  return function rng() {
    s ^= s << 13; s >>>= 0;
    s ^= s >>> 17;
    s ^= s << 5;  s >>>= 0;
    return s / 4294967296;
  };
}

export class Noise {
  constructor(seed = 1337) {
    const rng = makeRng(seed);
    const p = new Uint8Array(256);
    for (let i = 0; i < 256; i++) p[i] = i;
    for (let i = 255; i > 0; i--) {
      const j = (rng() * (i + 1)) | 0;
      const t = p[i]; p[i] = p[j]; p[j] = t;
    }
    this.perm = new Uint8Array(512);
    this.permMod12 = new Uint8Array(512);
    for (let i = 0; i < 512; i++) {
      this.perm[i] = p[i & 255];
      this.permMod12[i] = this.perm[i] % 12;
    }
  }

  simplex2(xin, yin) {
    const { perm, permMod12 } = this;
    const s = (xin + yin) * F2;
    let i = Math.floor(xin + s), j = Math.floor(yin + s);
    const t = (i + j) * G2;
    const x0 = xin - (i - t), y0 = yin - (j - t);
    const i1 = x0 > y0 ? 1 : 0, j1 = x0 > y0 ? 0 : 1;
    const x1 = x0 - i1 + G2, y1 = y0 - j1 + G2;
    const x2 = x0 - 1 + 2 * G2, y2 = y0 - 1 + 2 * G2;
    i &= 255; j &= 255;

    let n = 0;
    let t0 = 0.5 - x0 * x0 - y0 * y0;
    if (t0 > 0) {
      const g = GRAD3[permMod12[i + perm[j]]];
      t0 *= t0; n += t0 * t0 * (g[0] * x0 + g[1] * y0);
    }
    let t1 = 0.5 - x1 * x1 - y1 * y1;
    if (t1 > 0) {
      const g = GRAD3[permMod12[i + i1 + perm[j + j1]]];
      t1 *= t1; n += t1 * t1 * (g[0] * x1 + g[1] * y1);
    }
    let t2 = 0.5 - x2 * x2 - y2 * y2;
    if (t2 > 0) {
      const g = GRAD3[permMod12[i + 1 + perm[j + 1]]];
      t2 *= t2; n += t2 * t2 * (g[0] * x2 + g[1] * y2);
    }
    return 70 * n;
  }

  simplex3(xin, yin, zin) {
    const { perm, permMod12 } = this;
    const s = (xin + yin + zin) * F3;
    let i = Math.floor(xin + s), j = Math.floor(yin + s), k = Math.floor(zin + s);
    const t = (i + j + k) * G3;
    const x0 = xin - (i - t), y0 = yin - (j - t), z0 = zin - (k - t);

    let i1, j1, k1, i2, j2, k2;
    if (x0 >= y0) {
      if (y0 >= z0)      { i1=1;j1=0;k1=0; i2=1;j2=1;k2=0; }
      else if (x0 >= z0) { i1=1;j1=0;k1=0; i2=1;j2=0;k2=1; }
      else               { i1=0;j1=0;k1=1; i2=1;j2=0;k2=1; }
    } else {
      if (y0 < z0)       { i1=0;j1=0;k1=1; i2=0;j2=1;k2=1; }
      else if (x0 < z0)  { i1=0;j1=1;k1=0; i2=0;j2=1;k2=1; }
      else               { i1=0;j1=1;k1=0; i2=1;j2=1;k2=0; }
    }

    const x1 = x0 - i1 + G3,       y1 = y0 - j1 + G3,       z1 = z0 - k1 + G3;
    const x2 = x0 - i2 + 2 * G3,   y2 = y0 - j2 + 2 * G3,   z2 = z0 - k2 + 2 * G3;
    const x3 = x0 - 1 + 3 * G3,    y3 = y0 - 1 + 3 * G3,    z3 = z0 - 1 + 3 * G3;
    i &= 255; j &= 255; k &= 255;

    let n = 0;
    let t0 = 0.6 - x0*x0 - y0*y0 - z0*z0;
    if (t0 > 0) { const g = GRAD3[permMod12[i + perm[j + perm[k]]]];
      t0 *= t0; n += t0*t0*(g[0]*x0 + g[1]*y0 + g[2]*z0); }
    let t1 = 0.6 - x1*x1 - y1*y1 - z1*z1;
    if (t1 > 0) { const g = GRAD3[permMod12[i+i1 + perm[j+j1 + perm[k+k1]]]];
      t1 *= t1; n += t1*t1*(g[0]*x1 + g[1]*y1 + g[2]*z1); }
    let t2 = 0.6 - x2*x2 - y2*y2 - z2*z2;
    if (t2 > 0) { const g = GRAD3[permMod12[i+i2 + perm[j+j2 + perm[k+k2]]]];
      t2 *= t2; n += t2*t2*(g[0]*x2 + g[1]*y2 + g[2]*z2); }
    let t3 = 0.6 - x3*x3 - y3*y3 - z3*z3;
    if (t3 > 0) { const g = GRAD3[permMod12[i+1 + perm[j+1 + perm[k+1]]]];
      t3 *= t3; n += t3*t3*(g[0]*x3 + g[1]*y3 + g[2]*z3); }
    return 32 * n;
  }

  /** Fractal brownian motion, 2D. Returns roughly [-1,1]. */
  fbm2(x, y, octaves = 5, lacunarity = 2.02, gain = 0.5) {
    let amp = 1, freq = 1, sum = 0, norm = 0;
    for (let o = 0; o < octaves; o++) {
      sum  += amp * this.simplex2(x * freq, y * freq);
      norm += amp;
      amp  *= gain;
      freq *= lacunarity;
    }
    return sum / norm;
  }

  /** Ridged multifractal — the workhorse for mountain silhouettes. */
  ridged2(x, y, octaves = 5, lacunarity = 2.07, gain = 0.5) {
    let amp = 1, freq = 1, sum = 0, norm = 0;
    for (let o = 0; o < octaves; o++) {
      const n = 1 - Math.abs(this.simplex2(x * freq, y * freq));
      sum  += amp * n * n;
      norm += amp;
      amp  *= gain;
      freq *= lacunarity;
    }
    return sum / norm;
  }

  /** Cheap 2-lobe warp — kills the "noise grid" look on large features. */
  warp2(x, y, strength = 0.6) {
    const wx = this.simplex2(x + 5.2, y + 1.3);
    const wy = this.simplex2(x - 3.7, y + 9.1);
    return this.fbm2(x + strength * wx, y + strength * wy, 5);
  }
}

export const noise = new Noise(20260731);
