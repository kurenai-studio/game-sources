// Collision Manager - Optimized collision detection system
import { checkCollision } from './collision.js';
import { getDistanceSq } from './mathHelpers.js';

export class CollisionManager {
  constructor() {
    this.collisionCache = new Map();
    this.cacheTimeout = 16; // Cache for 16ms
    this.lastCacheTime = 0;
  }

  /**
   * Check collision between two rectangles (cached)
   */
  checkRectCollision(rect1, rect2, time) {
    const cacheKey = `${rect1.x},${rect1.y},${rect1.width},${rect1.height}-${rect2.x},${rect2.y},${rect2.width},${rect2.height}`;
    
    // Clear cache if too old
    if (time - this.lastCacheTime > this.cacheTimeout) {
      this.collisionCache.clear();
      this.lastCacheTime = time;
    }
    
    // Check cache
    if (this.collisionCache.has(cacheKey)) {
      return this.collisionCache.get(cacheKey);
    }
    
    const result = checkCollision(rect1, rect2);
    this.collisionCache.set(cacheKey, result);
    return result;
  }

  /**
   * Check if point is within circle (using squared distance)
   */
  isPointInCircle(px, py, cx, cy, radius) {
    const radiusSq = radius * radius;
    return getDistanceSq(px, py, cx, cy) <= radiusSq;
  }

  /**
   * Check if two circles intersect (using squared distance)
   */
  doCirclesIntersect(x1, y1, r1, x2, y2, r2) {
    const distanceSq = getDistanceSq(x1, y1, x2, y2);
    const radiusSumSq = (r1 + r2) * (r1 + r2);
    return distanceSq <= radiusSumSq;
  }

  /**
   * Get collision rectangle for game object
   */
  getCollisionRect(obj, size) {
    return {
      x: obj.x - size / 2,
      y: obj.y - size / 2,
      width: size,
      height: size
    };
  }

  /**
   * Clear collision cache
   */
  clearCache() {
    this.collisionCache.clear();
  }
}





