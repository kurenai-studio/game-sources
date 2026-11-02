// Optimized drawing helpers - avoid Math.sqrt in loops
/**
 * Check if point is within circle using squared distance (faster)
 */
export function isInCircleSq(dx, dy, radiusSq) {
  return (dx * dx + dy * dy) <= radiusSq;
}

/**
 * Check if point is within ring using squared distance (faster)
 */
export function isInRingSq(dx, dy, innerRadiusSq, outerRadiusSq) {
  const distSq = dx * dx + dy * dy;
  return distSq <= outerRadiusSq && distSq > innerRadiusSq;
}

/**
 * Pre-calculate squared radii for common sizes
 */
export function getRadiusSq(radius) {
  return radius * radius;
}





