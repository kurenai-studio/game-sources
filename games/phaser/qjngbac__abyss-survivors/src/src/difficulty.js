// 难度配置表（唯一数据源）：
// - GameScene 用它做实际数值结算
// - MenuScene 用它生成难度说明（避免文案与实际数值各写一份、越改越不一致）
// 1: 普通 / 2: 困难 / 3: 噩梦
export default {
  1: {
    player: { hp: 1.0, dmg: 1.0, speed: 1.0 },
    enemy:  { hp: 1.0, dmg: 1.0, speed: 1.0, interval: 1.0 },
    goldMul: 1.0, xpMul: 1.0,
    badge: '普通'
  },
  2: {
    player: { hp: 0.90, dmg: 0.90, speed: 0.95 },
    enemy:  { hp: 1.30, dmg: 1.25, speed: 1.08, interval: 0.90 },
    goldMul: 1.25, xpMul: 1.25,
    badge: '困难'
  },
  3: {
    player: { hp: 0.75, dmg: 0.80, speed: 0.90 },
    enemy:  { hp: 1.65, dmg: 1.45, speed: 1.15, interval: 0.80 },
    goldMul: 1.50, xpMul: 1.50,
    badge: '噩梦'
  }
};
