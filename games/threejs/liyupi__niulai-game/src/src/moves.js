/**
 * 招式数据表 —— 帧数据驱动（启动/判定/收招），参考拳皇·街霸设计方法论：
 * - 普通技可取消衔接必杀技（轻→重→必杀 是标准连招路线）
 * - 命中硬直 > 招式收招时间差 = 可形成连段
 * - 连招伤害递减，重招击退大但硬直长（风险回报）
 *
 * 姿态关节: torso/head/armL/foreL/armR/foreR/legL/shinL/legR/shinR → [x,y,z]
 */

const P = (o) => o;   // 姿态简写

export const MOVES = {
  // ---- 轻拳：直拳（Jab）。启动快、命中硬直长于收招 → 可自连成轻-轻连段
  lp: {
    name: '轻拳', startup: 0.08, active: 0.08, recovery: 0.17,
    damage: 32, hitstun: 0.38, blockstun: 0.2, knockback: 1.6, launch: 0,
    range: 1.55, hitH: 1.7, hitR: 0.62, limb: 'handR',
    meterGain: 7, whiffMeter: 2, canCancel: ['lp', 'hp', 'lk', 'hk', 'special'],
    sfx: 'whoosh',
    poseWindup: P({ torso: [0.04, 0.22, 0], armR: [0.3, 0, -0.5], foreR: [-1.7, 0, 0] }),
    poseStrike: P({ torso: [0.08, -0.5, 0], armR: [-1.62, 0, -0.08], foreR: [-0.08, 0, 0], head: [0, -0.15, 0], legR: [-0.15, 0, -0.06] }),
  },
  // ---- 重拳：抡臂重击。启动慢伤害高，命中时对手大击退；防御者掉血（chip）
  hp: {
    name: '重拳', startup: 0.17, active: 0.1, recovery: 0.3,
    damage: 72, hitstun: 0.5, blockstun: 0.26, knockback: 5.2, launch: 0,
    range: 1.75, hitH: 1.7, hitR: 0.72, limb: 'handR', heavy: true,
    meterGain: 12, whiffMeter: 4, canCancel: ['special'],
    sfx: 'whooshHeavy',
    poseWindup: P({ torso: [-0.1, 0.55, 0], armR: [0.6, 0, -0.9], foreR: [-2.0, 0, 0], armL: [-0.4, 0, 0.6] }),
    poseStrike: P({ torso: [0.22, -0.85, 0], armR: [-1.5, 0, -0.35], foreR: [-0.05, 0, 0], armL: [0.3, 0, 0.8], head: [0.05, -0.2, 0], legR: [-0.3, 0, -0.1], legL: [0.15, 0, 0.1] }),
  },
  // ---- 轻踢：前踢。距离比拳远
  lk: {
    name: '轻踢', startup: 0.09, active: 0.09, recovery: 0.2,
    damage: 38, hitstun: 0.4, blockstun: 0.2, knockback: 2.2, launch: 0,
    range: 1.85, hitH: 1.0, hitR: 0.64, limb: 'footR',
    meterGain: 8, whiffMeter: 2, canCancel: ['hk', 'special'],
    sfx: 'whoosh',
    poseWindup: P({ torso: [-0.08, 0, 0], legR: [-0.8, 0, -0.06], shinR: [-1.5, 0, 0], armL: [-0.3, 0, 0.5] }),
    poseStrike: P({ torso: [-0.22, 0, 0], legR: [-1.35, 0, -0.06], shinR: [-0.12, 0, 0], legL: [0.12, 0, 0.08], armL: [-0.5, 0, 0.7], armR: [0.25, 0, -0.5], head: [-0.08, 0, 0] }),
  },
  // ---- 重踢：扫堂重踢。可击倒
  hk: {
    name: '重踢', startup: 0.19, active: 0.11, recovery: 0.34,
    damage: 66, hitstun: 0.55, blockstun: 0.28, knockback: 5.8, launch: 2.2, knockdown: true,
    range: 2.0, hitH: 1.1, hitR: 0.74, limb: 'footR', heavy: true,
    meterGain: 12, whiffMeter: 4, canCancel: ['special'],
    sfx: 'whooshHeavy',
    poseWindup: P({ torso: [-0.05, 0.5, 0], legR: [0.3, 0, -0.5], shinR: [-1.2, 0, 0], armL: [-0.8, 0, 0.9] }),
    poseStrike: P({ torso: [-0.38, -0.55, 0], legR: [-1.6, 0, -0.55], shinR: [-0.15, 0, 0], legL: [-0.2, 0, 0.05], armL: [-1.1, 0, 1.1], armR: [0.4, 0, -0.7], head: [-0.15, 0.1, 0] }),
  },
  // ---- 空中轻拳/轻踢
  air_lp: {
    name: '空拳', startup: 0.07, active: 0.14, recovery: 0.12,
    damage: 30, hitstun: 0.36, blockstun: 0.18, knockback: 1.8, launch: 0,
    range: 1.5, hitH: 1.5, hitR: 0.6, limb: 'handR', air: true,
    meterGain: 6, whiffMeter: 2, canCancel: [], sfx: 'whoosh',
    poseWindup: P({ armR: [0.2, 0, -0.4], foreR: [-1.6, 0, 0] }),
    poseStrike: P({ torso: [0.3, -0.4, 0], armR: [-1.9, 0, -0.1], foreR: [-0.05, 0, 0], legL: [-0.6, 0, 0.1], legR: [-0.4, 0, -0.1] }),
  },
  air_hk: {
    name: '空踢', startup: 0.1, active: 0.18, recovery: 0.14,
    damage: 52, hitstun: 0.45, blockstun: 0.24, knockback: 3.2, launch: 1.2,
    range: 1.8, hitH: 1.2, hitR: 0.68, limb: 'footR', air: true,
    meterGain: 9, whiffMeter: 3, canCancel: [], sfx: 'whooshHeavy',
    poseWindup: P({ legR: [-0.6, 0, -0.3], shinR: [-1.4, 0, 0] }),
    poseStrike: P({ torso: [0.25, 0, 0], legR: [-1.5, 0, -0.2], shinR: [-0.1, 0, 0], legL: [-0.7, 0, 0.1], armL: [-0.9, 0, 0.8] }),
  },
};

// ---- 必杀技（能量条满释放，每人独有演出）----
export const SPECIALS = {
  rush: {
    name: '蛮牛冲撞', kind: 'rush',
    startup: 0.28, active: 0.62, recovery: 0.42,
    damage: 46, hits: 3, hitInterval: 0.18, hitstun: 0.34, blockstun: 0.2,
    knockback: 2.0, finalKnockback: 7.5, launch: 0, finalKnockdown: true,
    range: 1.35, hitH: 1.6, hitR: 0.95, limb: 'body', heavy: true,
    dashSpeed: 10.5, meterCost: 100, invuln: false, armor: true,   // 冲撞中霸体
    sfx: 'rush',
  },
  fly: {
    name: '飞天小牛弹', kind: 'fly',
    startup: 0.24, active: 0.5, recovery: 0.5,
    damage: 105, hits: 1, hitstun: 0.7, blockstun: 0.3,
    knockback: 4, launch: 5.5, knockdown: true,
    range: 1.15, hitH: 1.2, hitR: 0.92, limb: 'body', heavy: true,
    riseVel: 7.5, flySpeed: 13, meterCost: 100,
    sfx: 'fly',
  },
  flurry: {
    name: '豹影连踢', kind: 'flurry',
    startup: 0.22, active: 1.15, recovery: 0.4,
    damage: 26, hits: 7, hitInterval: 0.15, hitstun: 0.3, blockstun: 0.16,
    knockback: 0.7, finalKnockback: 6.5, launch: 0, finalKnockdown: true,
    range: 1.9, hitH: 1.5, hitR: 1.1, limb: 'body', heavy: true,
    suck: 2.2,     // 命中时把对手往自己吸（乱舞演出）
    meterCost: 100,
    sfx: 'flurry',
  },
  upper: {
    name: '怒火上勾拳', kind: 'upper',
    startup: 0.2, active: 0.14, recovery: 0.55,
    damage: 95, hits: 1, hitstun: 0.8, blockstun: 0.3,
    knockback: 2.5, launch: 9.5, knockdown: true,
    range: 1.6, hitH: 2.4, hitR: 0.78, limb: 'handR', heavy: true,
    stepSpeed: 6.5, selfRise: 6.5, meterCost: 100,
    sfx: 'upper',
  },
  // ---- 新角色专属必杀（全新机制）----
  coil: {
    name: '绳影缠绕', kind: 'coil',
    startup: 0.22, active: 1.3, recovery: 0.5,
    damage: 26, hits: 5, hitInterval: 0.24, hitstun: 0.5, blockstun: 0.22,
    knockback: 0.4, finalKnockback: 7.2, launch: 4.6, finalKnockdown: true,
    range: 1.6, hitH: 1.5, hitR: 0.95, limb: 'body', heavy: true,
    lungeSpeed: 9.5, meterCost: 100,
    sfx: 'flurry',
  },
  storm: {
    name: '羽毛风暴', kind: 'storm',
    startup: 0.3, active: 1.35, recovery: 0.45,
    damage: 24, hits: 8, hitInterval: 0.15, hitstun: 0.32, blockstun: 0.14,
    knockback: 0.7, finalKnockback: 6.0, launch: 4.0, finalKnockdown: true,
    range: 1.2, hitH: 3.2, hitR: 1.15, limb: 'body', heavy: true,
    riseVel: 8.8, hoverY: 3.2, meterCost: 100,
    sfx: 'fly',
  },
  pack: {
    name: '狼群围猎', kind: 'pack',
    startup: 0.4, active: 1.3, recovery: 0.5,
    damage: 42, hits: 4, hitInterval: 0.32, hitstun: 0.36, blockstun: 0.2,
    knockback: 1.0, finalKnockback: 7.5, launch: 3.2, finalKnockdown: true,
    range: 1.8, hitH: 1.6, hitR: 1.6, limb: 'body', heavy: true,
    meterCost: 100,
    sfx: 'rush',
  },
};

/** 必杀技姿态（model.update 中程序化驱动大部分，这里给关键帧） */
export const SPECIAL_POSES = {
  flyStrike: { torso: [1.35, 0, 0], armL: [-1.55, 0, 0.12], armR: [-1.55, 0, -0.12], foreL: [-0.08, 0, 0], foreR: [-0.08, 0, 0], legL: [0.25, 0, 0.08], legR: [0.3, 0, -0.08], head: [-1.1, 0, 0] },
  upperWindup: { torso: [0.5, 0.3, 0], armR: [0.8, 0, -0.4], foreR: [-2.2, 0, 0], legR: [0.4, 0, -0.1], shinR: [0.8, 0, 0] },
  upperStrike: { torso: [-0.35, -0.2, 0], armR: [-2.95, 0, -0.1], foreR: [-0.15, 0, 0], armL: [0.5, 0, 0.6], legL: [-0.6, 0, 0.1], legR: [-0.4, 0, -0.1] },
  coilWindup: { torso: [0.6, 0, 0], head: [-0.3, 0, 0], armL: [1.2, 0, 0.9], armR: [1.2, 0, -0.9], foreL: [-2.2, 0, 0], foreR: [-2.2, 0, 0] },
  stormRise: { torso: [-0.15, 0, 0], head: [0.2, 0, 0], armL: [-0.4, 0, 2.6], armR: [-0.4, 0, -2.6], foreL: [-0.15, 0, 0], foreR: [-0.15, 0, 0], legL: [0.3, 0, 0.1], legR: [0.3, 0, -0.1] },
  packHowl: { torso: [-0.4, 0, 0], head: [-0.7, 0, 0], armL: [-0.3, 0, 0.5], armR: [-0.3, 0, -0.5], foreL: [-0.6, 0, 0], foreR: [-0.6, 0, 0] },
};
