/**
 * 難度曲線純函式
 * @param {number} wave 
 * @returns {Object}
 */
export function getDifficulty(wave) {
  const isBossWave = wave % 3 === 0;
  const speedMultiplier = 1.0 + Math.max(0, wave - 1) * 0.06;
  const bulletSpeedMultiplier = 1.0 + Math.max(0, wave - 1) * 0.08;
  const shootChance = Math.min(0.85, 0.4 + (wave - 1) * 0.08);

  let turnAroundChance = 0;
  if (wave >= 3) {
    turnAroundChance = Math.min(0.75, 0.3 + (wave - 3) * 0.15);
  }

  const hpBonus = wave >= 4 ? Math.floor((wave - 3) / 2) : 0;
  const enemyCount = Math.min(14, 5 + wave * 2);

  return {
    wave,
    isBossWave,
    speedMultiplier,
    bulletSpeedMultiplier,
    shootChance,
    turnAroundChance,
    hpBonus,
    enemyCount,
  };
}
