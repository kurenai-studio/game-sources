/** Small helpers shared by the level art and the furniture. */

/** Deterministic pseudo-random number in [0, 1) for a grid position. */
export function hash(x: number, y: number, n = 0): number {
  let h = (Math.imul(x, 374761393) + Math.imul(y, 668265263) + Math.imul(n, 1274126177)) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  h ^= h >>> 16;
  return (h >>> 0) / 4294967296;
}

/** A colour lightened (f > 1) or darkened (f < 1). */
export function tone(color: number, f: number): number {
  const r = Math.min(255, Math.round(((color >> 16) & 0xff) * f));
  const gg = Math.min(255, Math.round(((color >> 8) & 0xff) * f));
  const b = Math.min(255, Math.round((color & 0xff) * f));
  return (r << 16) | (gg << 8) | b;
}
