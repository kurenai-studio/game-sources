/**
 * WaveDifficultyManager.js
 * 獨立波次難度與虎頭蜂 AI 行為管理器
 *
 * 職責：
 * 1. 計算各波次難度曲線（敵機速度、敵彈速度、射擊率、血量倍率）
 * 2. 控制虎頭蜂「越位急停回馬槍 (Turn-around Backstab)」解鎖與觸發機率
 * 3. 生成波次編隊結構與兵種配置
 */

import { getDifficulty } from '../logic/difficulty.js';

export class WaveDifficultyManager {
  constructor(scene) {
    this.scene = scene;
  }

  /**
   * 根據波次 wave 取得當前難度配置參數
   * @param {number} wave 當前波次 (從 1 開始)
   * @returns {Object} 難度數值包
   */
  getDifficulty(wave) {
    return getDifficulty(wave);
  }

  /**
   * 取得特定波次的編隊陣型配置
   * @param {number} wave 
   * @returns {Array<{type: 'HORNET'|'ARMORED', x: number, y: number}>}
   */
  getWaveFormation(wave) {
    const diff = this.getDifficulty(wave);
    const formation = [];
    const count = diff.enemyCount;

    for (let i = 0; i < count; i++) {
      const col = i % 6;
      const row = Math.floor(i / 6);
      const x = 70 + col * 68;
      const y = 80 + row * 55;

      // 第 2 波之後交錯配置裝甲蜂
      let type = 'HORNET';
      if (wave >= 2 && i % 3 === 0) {
        type = 'ARMORED';
      }

      formation.push({ type, x, y });
    }

    return formation;
  }
}
