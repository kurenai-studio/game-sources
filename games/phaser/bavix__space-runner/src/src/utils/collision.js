// Collision detection utilities

/**
 * Check collision between two rectangles
 * Optimized with early exit
 */
export function checkCollision(rect1, rect2) {
  // Optimize: early exit for non-overlapping cases
  if (rect1.x + rect1.width < rect2.x || rect1.x > rect2.x + rect2.width) {
    return false;
  }
  if (rect1.y + rect1.height < rect2.y || rect1.y > rect2.y + rect2.height) {
    return false;
  }
  return true;
}






