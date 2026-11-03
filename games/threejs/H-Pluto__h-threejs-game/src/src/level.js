/**
 * level.js — 关卡数据定义
 * 手工设计的平台布局（非随机生成）—— 包含高低差地形、敌人位置、物品位置
 */

/**
 * 获取关卡数据
 * @returns {Object} { platforms, enemies, items, startPos, endZone }
 */
export function getLevelData() {
    // ==================== 平台定义 ====================
    // 格式: { x, y, w, h, type }
    // x,y = 中心世界坐标, w,h = 宽高
    const platforms = [
        // ===== 地面层（连续地面） =====
        // 起始区域
        { x: 300, y: 480, w: 800, h: 80, type: 'ground' },

        // 中间地面
        { x: 1600, y: 480, w: 600, h: 80, type: 'ground' },

        // 终点区域
        { x: 2800, y: 480, w: 800, h: 80, type: 'ground' },

        // ===== 中间浮动平台（高低差） =====
        { x: 550, y: 350, w: 180, h: 24, type: 'platform' },
        { x: 850, y: 280, w: 160, h: 24, type: 'platform' },
        { x: 1100, y: 330, w: 200, h: 24, type: 'platform' },

        // 较高平台
        { x: 700, y: 200, w: 140, h: 24, type: 'platform' },
        { x: 950, y: 160, w: 120, h: 24, type: 'platform' },

        // 第二区域平台
        { x: 1400, y: 380, w: 200, h: 24, type: 'platform' },
        { x: 1700, y: 320, w: 160, h: 24, type: 'platform' },
        { x: 1900, y: 260, w: 140, h: 24, type: 'platform' },

        // 挑战跳跃段
        { x: 2100, y: 400, w: 100, h: 24, type: 'platform' },
        { x: 2250, y: 340, w: 100, h: 24, type: 'platform' },
        { x: 2400, y: 280, w: 120, h: 24, type: 'platform' },
        { x: 2550, y: 350, w: 140, h: 24, type: 'platform' },

        // 终点前的高台
        { x: 2800, y: 380, w: 150, h: 24, type: 'platform' },
        { x: 3000, y: 320, w: 150, h: 24, type: 'platform' },

        // ===== 墙壁（作为障碍物） =====
        { x: 1200, y: 430, w: 30, h: 120, type: 'wall' },
        { x: 2050, y: 450, w: 30, h: 100, type: 'wall' },
    ];

    // ==================== 敌人定义 ====================
    // 格式: { type, x, y, patrolMinX, patrolMaxX }
    const enemies = [
        // 第一区域 - 近战兵
        { type: 'melee', x: 450, y: 445, patrolMinX: 200, patrolMaxX: 650 },
        { type: 'melee', x: 600, y: 445, patrolMinX: 200, patrolMaxX: 650 },

        // 高台守卫 - 近战兵
        { type: 'melee', x: 700, y: 165, patrolMinX: 630, patrolMaxX: 770 },

        // 第二区域 - 远程兵
        { type: 'ranged', x: 1500, y: 445, patrolMinX: 1300, patrolMaxX: 1900 },
        { type: 'ranged', x: 1700, y: 285, patrolMinX: 1620, patrolMaxX: 1780 },

        // 混合敌人区域
        { type: 'melee', x: 1800, y: 445, patrolMinX: 1300, patrolMaxX: 1900 },
        { type: 'ranged', x: 2100, y: 365, patrolMinX: 2050, patrolMaxX: 2150 },

        // 终点区域守卫
        { type: 'melee', x: 2700, y: 445, patrolMinX: 2500, patrolMaxX: 2900 },
        { type: 'melee', x: 2850, y: 445, patrolMinX: 2500, patrolMaxX: 2900 },
        { type: 'ranged', x: 3000, y: 285, patrolMinX: 2925, patrolMaxX: 3075 },
    ];

    // ==================== 物品定义 ====================
    // 格式: { type, x, y }
    const items = [
        // 血瓶 - 放在挑战区域作为补给
        { type: 'health', x: 550, y: 320 },
        { type: 'health', x: 1400, y: 350 },
        { type: 'health', x: 2250, y: 310 },
        { type: 'health', x: 2800, y: 350 },

        // 金币 - 散落在各平台
        { type: 'coin', x: 350, y: 450 },
        { type: 'coin', x: 400, y: 450 },
        { type: 'coin', x: 700, y: 170 },
        { type: 'coin', x: 850, y: 250 },
        { type: 'coin', x: 950, y: 130 },
        { type: 'coin', x: 1100, y: 300 },
        { type: 'coin', x: 1700, y: 290 },
        { type: 'coin', x: 1900, y: 230 },
        { type: 'coin', x: 2100, y: 370 },
        { type: 'coin', x: 2400, y: 250 },
        { type: 'coin', x: 2550, y: 320 },
        { type: 'coin', x: 3000, y: 290 },
    ];

    // ==================== 玩家起点 ====================
    const startPos = { x: 100, y: 400 };

    // ==================== 终点区域 ====================
    const endZone = { x: 3100, y: 440, w: 60, h: 100 };

    return { platforms, enemies, items, startPos, endZone };
}
