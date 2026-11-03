/**
 * Interpolates from start to end using the given threshold.
 * @param start The start value.
 * @param end The end value.
 * @param threshold The interpolation value between the two floats.
 */
export function lerp(start: number, end: number, threshold: number): number {
  return start + (end - start) * threshold;
}
