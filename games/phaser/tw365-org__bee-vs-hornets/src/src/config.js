/**
 * 遊戲全域設定與平衡參數
 */
export const GAME_CONFIG = {
  WIDTH: 480,
  HEIGHT: 640,
  PARENT: 'game-container',
  
  // 玩家參數
  PLAYER: {
    SPEED: 320,
    MAX_HP: 100,
    START_BOMBS: 2,
    MAX_BOMBS: 3,
    INVULNERABLE_DURATION: 1500, // 毫秒
  },

  // 重武器升級門檻與特性
  WEAPONS: {
    LV0: {
      id: 0,
      name: '雙連發蜂針',
      scoreRequired: 0,
      fireRate: 150, // 射擊間隔 ms
      damage: 15,
      speed: 620,
      color: 0x00ffcc,
    },
    LV1: {
      id: 1,
      name: '花蜜散彈針',
      scoreRequired: 1000,
      fireRate: 200,
      damage: 18,
      speed: 580,
      spreadAngles: [-24, -12, 0, 12, 24],
      color: 0xffdd00,
    },
    LV2: {
      id: 2,
      name: '蜂王追蹤微導彈',
      scoreRequired: 2500,
      fireRate: 250,
      damage: 32,
      speed: 460,
      turnRate: 0.12,
      color: 0x33ff55,
    },
    LV3: {
      id: 3,
      name: '重型等離子轟爆砲',
      scoreRequired: 5000,
      fireRate: 380,
      damage: 90,
      speed: 420,
      piercing: true,
      color: 0xff00ff,
    }
  },

  // 敵機參數
  ENEMIES: {
    HORNET: {
      hp: 20,
      score: 100,
      speed: 160,
    },
    ARMORED: {
      hp: 75,
      score: 300,
      speed: 110,
    },
    QUEEN: {
      hp: 850,
      score: 2500,
      speed: 80,
    }
  },

  // 花粉天譴核爆參數
  POLLEN: {
    MINION_DAMAGE: 120,  // 對工蜂與裝甲蜂造成全屏肅清傷害
    BOSS_DAMAGE: 200,    // 對女王 Boss 造成核爆重創傷害
  },

  // 大自然食物鏈彩蛋：東方蜂鷹天敵援助參數
  EASTER: {
    BOSS_DAMAGE: 250,    // 蜂鷹掠過對女王 Boss 造成的重創傷害
    MINION_DAMAGE: 150,  // 蜂鷹掠過對普通工蜂/裝甲蜂造成的秒殺傷害
    RANGE: 95,           // 蜂鷹掠食判定範圍半徑 (像素)
    COOLDOWN: 45000,     // 援助觸發冷卻時間 (毫秒)
  }
};
