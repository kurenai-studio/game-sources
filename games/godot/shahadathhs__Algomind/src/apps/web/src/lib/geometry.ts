/** Rounds to two decimals so generated SVG paths stay short and stable. */
export function round2(value: number): number {
  return Math.round(value * 100) / 100;
}

/** A rectangle with the top-right corner cut at 45 degrees (the Algomind tile). */
export function chamferPath(x: number, y: number, w: number, h: number, c: number): string {
  const cut = round2(Math.max(0, Math.min(c, w, h)));
  const [x0, y0, x1, y1] = [round2(x), round2(y), round2(x + w), round2(y + h)];
  return `M${x0} ${y0}H${round2(x1 - cut)}L${x1} ${round2(y0 + cut)}V${y1}H${x0}Z`;
}

/**
 * Chamfer size of a shape inset by `t` on every side, so that the cut line stays parallel to the
 * outer one and an outline keeps an even thickness.
 */
export function insetChamfer(c: number, t: number): number {
  return Math.max(0, round2(c - t * (2 - Math.SQRT2)));
}

/** Outer and inner paths of an outlined tile with an outline of thickness `t`. */
export function chamferOutline(
  x: number,
  y: number,
  w: number,
  h: number,
  c: number,
  t: number,
): { outer: string; inner: string } {
  return {
    outer: chamferPath(x, y, w, h, c),
    inner: chamferPath(x + t, y + t, w - 2 * t, h - 2 * t, insetChamfer(c, t)),
  };
}
