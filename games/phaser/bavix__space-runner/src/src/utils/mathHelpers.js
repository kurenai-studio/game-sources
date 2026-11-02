// Optimized math utilities for game performance

/**
 * Calculate squared distance between two points (faster than distance)
 * Use this when you only need to compare distances, not the actual value
 */
export function getDistanceSq(x1, y1, x2, y2) {
  const dx = x2 - x1;
  const dy = y2 - y1;
  return dx * dx + dy * dy;
}

/**
 * Calculate distance between two points
 * Use getDistanceSq when possible for better performance
 */
export function getDistance(x1, y1, x2, y2) {
  return Math.sqrt(getDistanceSq(x1, y1, x2, y2));
}

/**
 * Normalize a vector (dx, dy) using pre-calculated distance
 * Optimized version that avoids recalculating distance
 */
export function normalizeVector(dx, dy, distance) {
  if (distance > 0) {
    const invDistance = 1 / distance;
    return { x: dx * invDistance, y: dy * invDistance };
  }
  return { x: 0, y: 0 };
}

/**
 * Normalize a vector using squared distance (avoids sqrt)
 * Returns normalized vector and actual distance
 */
export function normalizeVectorFromSq(dx, dy, distanceSq) {
  if (distanceSq > 0) {
    const invDistance = 1 / Math.sqrt(distanceSq);
    return { 
      x: dx * invDistance, 
      y: dy * invDistance,
      distance: Math.sqrt(distanceSq)
    };
  }
  return { x: 0, y: 0, distance: 0 };
}

/**
 * Fast check if point is within circle (using squared distance)
 */
export function isPointInCircleSq(px, py, cx, cy, radiusSq) {
  return getDistanceSq(px, py, cx, cy) <= radiusSq;
}

/**
 * Clamp a value between min and max
 */
export function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

/**
 * Linear interpolation
 */
export function lerp(start, end, t) {
  return start + (end - start) * t;
}

/**
 * Smooth step interpolation
 */
export function smoothStep(t) {
  return t * t * (3 - 2 * t);
}





