import { applyAreaDamage } from './areaDamage.js';
import { createOnceHitTracker } from './onceHitTracker.js';

/**
 * 共通資格守門：判斷實體是否可受到核爆或蜂鷹傷害
 * D4 規範：進場中 (ENTERING) 的工蜂對所有傷害免疫
 */
export function isEnemyDamageEligible(target) {
  if (!target || !target.active) return false;
  if (target.state === 'ENTERING') return false;
  return true;
}

/**
 * 花粉天譴全屏核爆 (純邏輯)
 * @param {Array} targets 場上敵機列表
 * @param {Object} options 配置參數 { minionDamage, bossDamage, isBoss, onDamaged }
 * @returns {number} 實際受到核爆傷害的目標數
 */
export function detonatePollen(targets, options = {}) {
  const minionDamage = options.minionDamage ?? 120;
  const bossDamage = options.bossDamage ?? 200;
  const isBoss = options.isBoss || (t => t.isBoss);
  const onDamaged = options.onDamaged || ((t, dmg) => t.takeDamage?.(dmg));

  const damageFor = target => (isBoss(target) ? bossDamage : minionDamage);

  return applyAreaDamage(
    targets,
    damageFor,
    isEnemyDamageEligible,
    (target, dmg) => {
      onDamaged(target, dmg);
    }
  );
}

/**
 * 東方蜂鷹天降神援俯衝掠食 (純邏輯)
 * 透過 tracker 確保每個目標在同一次俯衝中只受一次傷害
 * @param {Array} targets 場上敵機列表
 * @param {Object} buzzardPos 蜂鷹當前座標 { x, y }
 * @param {Object} options 配置參數 { tracker, range, minionDamage, bossDamage, isBoss, onDamaged, distanceFn }
 * @returns {Array} 本次更新受到傷害的目標名單
 */
export function buzzardStrike(targets, buzzardPos, options = {}) {
  const tracker = options.tracker || createOnceHitTracker();
  const range = options.range ?? 95;
  const minionDamage = options.minionDamage ?? 150;
  const bossDamage = options.bossDamage ?? 250;
  const isBoss = options.isBoss || (t => t.isBoss);
  const onDamaged = options.onDamaged || ((t, dmg) => t.takeDamage?.(dmg));
  const distanceFn = options.distanceFn || ((x1, y1, x2, y2) => Math.hypot(x1 - x2, y1 - y2));

  const hitTargets = [];

  targets.slice().forEach(target => {
    if (!isEnemyDamageEligible(target)) return;

    const dist = distanceFn(buzzardPos.x, buzzardPos.y, target.x, target.y);
    if (dist <= range) {
      if (tracker.tryHit(target)) {
        const dmg = isBoss(target) ? bossDamage : minionDamage;
        onDamaged(target, dmg);
        hitTargets.push(target);
      }
    }
  });

  return hitTargets;
}
