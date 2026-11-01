/**
 * 護衛召喚條件判定
 * @param {number} activeMinionCount 目前活躍護衛數量
 * @param {number} cap 上限門檻（預設 4）
 * @returns {boolean} 是否允許召喚護衛
 */
export function shouldSummonMinions(activeMinionCount, cap = 4) {
  return activeMinionCount <= cap;
}
