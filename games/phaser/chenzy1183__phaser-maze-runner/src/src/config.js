// 全局配置
const GAME_WIDTH = 960;
const GAME_HEIGHT = 720;
const HUD_HEIGHT = 56;

const FONT = '"PingFang SC", "Microsoft YaHei", "Noto Sans SC", "Helvetica Neue", Arial, sans-serif';

const COLORS = {
  bg: 0x0f172a,
  hud: 0x020617,
  floor: 0x1e293b,
  wall: 0x334155,
  wallTop: 0x64748b,
  wallShadow: 0x0b1120,
  player: 0x38bdf8,
  exit: 0x22c55e,
  coin: 0xfacc15,
  hint: 0xf472b6,
  fog: 0x020617,
  accent: 0x38bdf8,
};

// 难度配置
// baseCols/baseRows: 第一关的迷宫格子数；growth: 每关增长；braid: 额外打通的墙比例（越大岔路/环路越多）
const DIFFICULTIES = {
  easy: {
    label: '简单',
    desc: '迷宫较小 · 无迷雾 · 5 次提示',
    baseCols: 7,
    baseRows: 5,
    growth: 1,
    maxCols: 19,
    maxRows: 14,
    braid: 0.15,
    fog: false,
    fogRadius: 0,
    exitVisible: true,
    hints: 5,
  },
  normal: {
    label: '普通',
    desc: '中等迷宫 · 迷雾视野 · 出口可见 · 3 次提示',
    baseCols: 9,
    baseRows: 7,
    growth: 2,
    maxCols: 25,
    maxRows: 18,
    braid: 0.08,
    fog: true,
    fogRadius: 7,
    exitVisible: true,
    hints: 3,
  },
  hard: {
    label: '困难',
    desc: '大型迷宫 · 狭窄视野 · 出口隐藏 · 1 次提示',
    baseCols: 13,
    baseRows: 9,
    growth: 2,
    maxCols: 31,
    maxRows: 22,
    braid: 0.03,
    fog: true,
    fogRadius: 4.5,
    exitVisible: false,
    hints: 1,
  },
};

// 本地存储（最高纪录、设置）
const Store = {
  get(key, fallback) {
    try {
      const v = localStorage.getItem('maze_runner_' + key);
      return v === null ? fallback : JSON.parse(v);
    } catch (e) {
      return fallback;
    }
  },
  set(key, value) {
    try {
      localStorage.setItem('maze_runner_' + key, JSON.stringify(value));
    } catch (e) {
      /* ignore */
    }
  },
};
