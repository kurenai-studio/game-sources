/**
 * config.js — 全局配置常量
 * 所有游戏参数集中管理，便于调整平衡性
 */

// ==================== 画布与渲染 ====================
/** 游戏设计分辨率（世界单位，非像素） */
export const GAME_WIDTH = 960;
export const GAME_HEIGHT = 540;

/** 像素缩放倍数（用于像素风格纹理清晰度） */
export const PIXEL_SCALE = 3;

// ==================== 物理参数 ====================
/** 重力加速度 (像素/秒²) */
export const GRAVITY = 1800;

/** 玩家移动速度 */
export const PLAYER_SPEED = 280;

/** 玩家跳跃初速度 (负值=向上) */
export const PLAYER_JUMP_FORCE = -620;

/** 地面摩擦力 (0~1, 越大减速越快) */
export const PLAYER_FRICTION = 0.82;

/** 空中水平控制系数 */
export const PLAYER_AIR_CONTROL = 0.65;

/** 最大下落速度 */
export const MAX_FALL_SPEED = 900;

// ==================== 战斗参数 ====================
/** 玩家最大生命值 */
export const PLAYER_MAX_HP = 100;

/** 近战第一段伤害 */
export const ATTACK1_DAMAGE = 15;

/** 近战第二段伤害 */
export const ATTACK2_DAMAGE = 22;

/** 攻击范围（前方矩形宽度） */
export const ATTACK_RANGE_X = 45;

/** 攻击范围（矩形高度） */
export const ATTACK_RANGE_Y = 50;

/** 连击窗口时间（秒），在此时间内再次按攻击触发连击 */
export const COMBO_WINDOW = 0.45;

/** 攻击1持续时间（秒） */
export const ATTACK1_DURATION = 0.25;

/** 攻击2持续时间（秒） */
export const ATTACK2_DURATION = 0.35;

/** 受伤无敌时间（秒） */
export const INVINCIBILITY_TIME = 0.8;

/** 受伤击退力度 */
export const KNOCKBACK_FORCE = 350;

// ==================== 敌人参数 ====================
/** 近战敌人巡逻速度 */
export const MELEE_PATROL_SPEED = 60;

/** 近战敌人追击速度 */
export const MELEE_CHASE_SPEED = 160;

/** 近战敌人攻击冷却（秒） */
export const MELEE_ATTACK_COOLDOWN = 1.2;

/** 近战敌人攻击伤害 */
export const MELEE_ATTACK_DAMAGE = 12;

/** 远程敌人巡逻速度 */
export const RANGED_PATROL_SPEED = 40;

/** 远程敌人追击速度 */
export const RANGED_CHASE_SPEED = 100;

/** 远程敌人攻击冷却 */
export const RANGED_ATTACK_COOLDOWN = 2.0;

/** 远程弹幕速度 */
export const PROJECTILE_SPEED = 300;

/** 远程弹幕伤害 */
export const PROJECTILE_DAMAGE = 10;

/** 敌人发现玩家的视野范围 */
export const ENEMY_SIGHT_RANGE = 350;

/** 敌人最大生命值 */
export const MELEE_HP = 40;
export const RANGED_HP = 30;

// ==================== 物品参数 ====================
/** 血瓶恢复量 */
export const HEALTH_POTION_HEAL = 30;

/** 金币分值 */
export const COIN_SCORE = 50;

// ==================== 连击计分 ====================
/** 连击衰减时间（秒），超过此时间未命中则连击归零 */
export const COMBO_DECAY_TIME = 2.0;

/** 连击倍率计算：基础分 * (1 + combo * COMBO_MULTIPLIER) */
export const COMBO_MULTIPLIER = 0.15;

// ==================== 色彩调色板（暗黑奇幻风格） ====================
export const COLORS = {
    // 背景
    bgDark: '#0d0d1a',
    bgMid: '#1a1a3e',
    bgLight: '#2a2a5a',

    // 平台
    stone: '#4a4a5a',
    stoneLight: '#5a5a6a',
    stoneDark: '#3a3a4a',
    moss: '#4a6a4a',

    // 玩家
    playerArmor: '#4a90d9',
    playerArmorLight: '#6ab0f0',
    playerSkin: '#e8c8a0',
    playerHair: '#3a2a1a',

    // 敌人
    meleeEnemy: '#8b3a3a',
    meleeEnemyLight: '#aa4a4a',
    rangedEnemy: '#6a3a8b',
    rangedEnemyLight: '#8a4aaa',

    // 特效
    slash: '#ffdd44',
    slashGlow: '#ffaa00',
    hitSpark: '#ffcc00',
    damageNumber: '#ff4444',
    healNumber: '#44ff44',
    coinGlow: '#ffcc00',

    // 物品
    healthPotion: '#ff4444',
    coin: '#ffcc00',
};

// ==================== 特效时间 ====================
/** 伤害数字持续时间（秒） */
export const DAMAGE_NUMBER_DURATION = 0.8;

/** 粒子生命周期（秒） */
export const PARTICLE_LIFETIME = 0.4;

/** 敌人消散动画时间（秒） */
export const DISSOLVE_DURATION = 0.6;

/** 屏幕震动持续时间（秒） */
export const SCREEN_SHAKE_DURATION = 0.15;

/** 屏幕震动强度 */
export const SCREEN_SHAKE_INTENSITY = 6;
