/**
 * 每次俯衝單次命中判定器
 */
export function createOnceHitTracker() {
  const hitSet = new Set();
  return {
    tryHit(target) {
      if (hitSet.has(target)) return false;
      hitSet.add(target);
      return true;
    },
    has(target) {
      return hitSet.has(target);
    },
    reset() {
      hitSet.clear();
    }
  };
}
