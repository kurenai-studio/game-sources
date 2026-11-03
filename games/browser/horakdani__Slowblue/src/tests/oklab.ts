import type { Rgb } from '../src/render/Paint';

/**
 * Slowblue: the colour instrument, and why the suite needed one at all.
 *
 * Every measurement this project has ever pointed at a frame is a *luminance*
 * measurement. `frame()` in `e2e/acts.spec.ts` collapses each pixel to one
 * Rec.601 number before it does anything else, and the seam pass, the column-step
 * pass and the band pass are all built on that one number. That is the right
 * reduction for the six defects those passes were written for - every one of them
 * is an edge - and it is the wrong one for §14, which is the only part of the
 * brief that is *about hue*.
 *
 * It lives in `tests/` rather than in `src/`: nothing in the running game needs
 * to convert a colour space, and a renderer that shipped this would be carrying
 * three cube roots per pixel it never calls.
 */

export interface Lch {
  l: number;
  c: number;
  h: number;
}

/**
 * sRGB to OkLCh.
 *
 * OkLab rather than HSL, and the difference is the whole reason anything here can
 * assert. HSL's hue is a wheel drawn on the *gamma-encoded* cube: two colours a
 * nominal twenty degrees apart on it are indistinguishable in one sector and
 * obviously different in another, and its "lightness" calls #0000ff and #ffff00
 * the same brightness. Neither survives a question of the form "how far apart are
 * these two stations".
 */
export function toLch([r, g, b]: Rgb): Lch {
  const lin = (v: number): number => {
    const s = v / 255;
    return s <= 0.04045 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
  };
  const R = lin(r);
  const G = lin(g);
  const B = lin(b);
  const l = Math.cbrt(0.4122214708 * R + 0.5363325363 * G + 0.0514459929 * B);
  const m = Math.cbrt(0.2119034982 * R + 0.6806995451 * G + 0.1073969566 * B);
  const s = Math.cbrt(0.0883024619 * R + 0.2817188376 * G + 0.6299787005 * B);
  const L = 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s;
  const A = 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s;
  const Bb = 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s;
  const h = (Math.atan2(Bb, A) * 180) / Math.PI;
  return { l: L, c: Math.hypot(A, Bb), h: h < 0 ? h + 360 : h };
}

/** Straight-line distance in OkLab, which is the space's whole reason for being. */
export function labDistance(a: Lch, b: Lch): number {
  const rad = Math.PI / 180;
  return Math.hypot(
    a.l - b.l,
    a.c * Math.cos(a.h * rad) - b.c * Math.cos(b.h * rad),
    a.c * Math.sin(a.h * rad) - b.c * Math.sin(b.h * rad),
  );
}

/** Signed shortest way round the hue circle, in degrees. */
export function hueDelta(a: number, b: number): number {
  let d = b - a;
  while (d > 180) d -= 360;
  while (d < -180) d += 360;
  return d;
}

/**
 * The warm band, and why it is these degrees.
 *
 * Read off the campaign rather than chosen. The `pod` colour is the golden
 * life-spark §14 calls every act's visual link, and across the forty zone
 * palettes it lands between **42 and 97** degrees in OkLCh - from the trench
 * floor's orange to act VI's pale yellow. The band is opened to 0..110 so that
 * the plasma's fire clears one end and act VI's leaf green clears the other
 * without either touching it.
 */
export function isWarm(h: number): boolean {
  return h >= 0 && h <= 110;
}
