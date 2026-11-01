/**
 * 快照範圍傷害純函式 (防止迭代中 splice 漏殺)
 * @param {Array} targets 目標陣列
 * @param {number|Function} damageFor 傷害數值或 (target) => number 計算函式
 * @param {Function} isEligible 是否具備受傷資格 (target) => boolean
 * @param {Function} applyDamage 實際造成傷害回調 (target, damage) => void
 * @returns {number} 實際受到傷害的目標數
 */
export function applyAreaDamage(targets, damageFor, isEligible, applyDamage) {
  let count = 0;
  // 透過 slice() 快照，安全避開迭代中 splice 造成索引位移漏殺
  targets.slice().forEach(target => {
    if (isEligible(target)) {
      const dmg = typeof damageFor === 'function' ? damageFor(target) : damageFor;
      applyDamage(target, dmg);
      count++;
    }
  });
  return count;
}
