// 波次导演：
// - 普通关卡：波次表来自关卡配置（levels.json），由 GameScene 传入。
//   interval 波持续刷怪；count 波刷指定数量后结束（精英/Boss 用）。
// - 无尽模式（levelConfig.endless）：波次每 45 秒解锁一档、逐档加密永不停止；
//   精英怪周期登场；Boss 每 150 秒轮换出现且血量逐次递增（小怪成长由 GameScene 的 hp/dmg 缩放负责）。
const ENDLESS_TIERS = [
  { enemy: 'bat',      'interval': 1.0 },
  { enemy: 'zombie',   'interval': 1.8 },
  { enemy: 'bat',      'interval': 0.6 },
  { enemy: 'skeleton', 'interval': 2.4 },
  { enemy: 'zombie',   'interval': 1.2 },
  { enemy: 'ghost',    'interval': 2.8 },
  { enemy: 'bat',      'interval': 0.4 },
  { enemy: 'skeleton', 'interval': 1.6 },
  { enemy: 'ghost',    'interval': 2.0 },
  { enemy: 'boar',     'interval': 5.0 },
  { enemy: 'zombie',   'interval': 0.9 },
  { enemy: 'bat',      'interval': 0.3 },
  { enemy: 'ghost',    'interval': 1.5 },
  { enemy: 'boar',     'interval': 3.5 },
  { enemy: 'skeleton', 'interval': 1.2 }
];
const ENDLESS_BOSS_ORDER = ['trollKing', 'reaper', 'boarKing', 'reaperTrue'];

export default class SpawnDirector {
  constructor(scene) {
    this.scene = scene;
    this.endless = !!scene.levelConfig.endless;
    this.waves = scene.levelConfig.waves;
    this.intervalMul = scene.intervalMul || 1;
    this.timers = {};
    this.started = {};
    this.done = {};
    // 无尽模式状态
    this.eliteT = 75;   // 首个精英 75 秒后登场，之后每 90 秒一只
    this.bossT = 240;   // 首个 Boss 4 分钟后登场，之后每 150 秒轮换
    this.bossCount = 0;
  }

  update(dt) {
    if (this.scene.gameOver) return;
    if (this.scene.isBrotato) return this.updateBrotato(dt);
    if (this.endless) return this.updateEndless(dt);
    // 关底 Boss 战独立：Boss 存活期间停止增援小波，让战斗成为 DPS 检验而非清怪竞赛
    const eList = this.scene.enemies.getChildren();
    for (let i = 0; i < eList.length; i++) {
      const e = eList[i];
      if (e.active && e.cfg && e.cfg.behavior === 'boss') return;
    }
    const t = this.scene.elapsed;
    for (const w of this.waves) {
      if (t < w.at) continue;
      const key = `${w.enemy}@${w.at}`;
      if (this.done[key]) continue;
      if (w.count) { // 一次性波（精英 / Boss）
        for (let i = 0; i < w.count; i++) this.scene.spawnEnemy(w.enemy);
        this.done[key] = true;
        continue;
      }
      if (!this.started[key]) {
        this.started[key] = true;
        this.timers[key] = 0; // 到点立刻出第一只
      }
      this.timers[key] -= dt;
      if (this.timers[key] <= 0) {
        this.timers[key] += w.interval * this.intervalMul;
        this.scene.spawnEnemy(w.enemy);
      }
    }
  }

  updateEndless(dt) {
    const t = this.scene.elapsed;
    const len = ENDLESS_TIERS.length;
    // 波次阶梯：每 45 秒解锁新的一档；全部档位解锁后按轮次继续加密
    const tierIdx = Math.min(len - 1, Math.floor(t / 45));
    const loop = Math.floor(t / (45 * len));
    const density = 1 + loop * 0.3;
    for (let i = 0; i <= tierIdx; i++) {
      const key = `tier${i}`;
      if (!this.started[key]) { this.started[key] = true; this.timers[key] = i === tierIdx ? 0 : 0.4; }
      this.timers[key] -= dt;
      if (this.timers[key] <= 0) {
        this.timers[key] += ENDLESS_TIERS[i].interval / density;
        this.scene.spawnEnemy(ENDLESS_TIERS[i].enemy);
      }
    }
    // 精英巨魔周期登场（大怪物逐渐增多）
    this.eliteT -= dt;
    if (this.eliteT <= 0) {
      this.eliteT = Math.max(45, 90 - loop * 15);
      this.scene.spawnEnemy('troll');
    }
    // Boss 轮番登场，血量一次比一次厚
    this.bossT -= dt;
    if (this.bossT <= 0) {
      this.bossT = 210;
      const type = ENDLESS_BOSS_ORDER[this.bossCount % ENDLESS_BOSS_ORDER.length];
      this.bossCount++;
      this.scene.spawnEnemy(type, undefined, undefined, 1 + this.bossCount * 0.35);
    }
  }

  // 进化模式（土豆兄弟）：前两波温和过渡，后续波次递进强化
  updateBrotato(dt) {
    if (!this.scene.brotoWaveActive) return;
    const wave = this.scene.brotoWave || 1;
    this._brotoTimer = (this._brotoTimer || 0) - dt;
    if (this._brotoTimer <= 0) {
      let baseInterval;
      let count;
      let pool = ['bat'];

      if (wave === 1) {
        // 第 1 波：温和热身，单只蝙蝠平缓刷新，让初始单武器玩家从容走位
        baseInterval = 0.88;
        count = 1;
        pool = ['bat'];
      } else if (wave === 2) {
        // 第 2 波：微增压，偶尔刷 2 只，混入少量僵尸
        baseInterval = 0.72;
        count = Math.random() < 0.7 ? 1 : 2;
        pool = ['bat', 'bat', 'zombie'];
      } else {
        // 第 3 波起：逐渐加压提速
        baseInterval = Math.max(0.24, 0.58 - (wave - 2) * 0.022);
        if (wave <= 4) {
          count = Math.random() < 0.6 ? 1 : 2;
        } else if (wave <= 8) {
          count = Math.random() < 0.6 ? 2 : 3;
        } else {
          count = Math.random() < 0.5 ? 3 : 4;
        }

        pool.push('zombie');
        if (wave >= 4) pool.push('skeleton');
        if (wave >= 6) pool.push('ghost');
        if (wave >= 8) pool.push('boar');
      }

      const diffMul = (this.scene.diffConfig && this.scene.diffConfig.enemy) ? this.scene.diffConfig.enemy.interval : 1;
      this._brotoTimer = baseInterval * diffMul;

      for (let i = 0; i < count; i++) {
        this.scene.spawnEnemy(Phaser.Utils.Array.GetRandom(pool));
      }

      // 伴随野猪突击与精英巨魔
      if (wave >= 5 && Math.random() < 0.12) {
        this.scene.spawnEnemy('boar');
      }
      if (wave >= 8 && Math.random() < 0.06) {
        this.scene.spawnEnemy('troll');
      }
    }
  }
}
