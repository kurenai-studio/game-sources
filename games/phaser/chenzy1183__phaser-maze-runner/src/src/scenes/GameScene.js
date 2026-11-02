// 游戏主场景：迷宫、玩家移动、金币、迷雾、提示、结算
const DIRS = [
  [1, 0],
  [-1, 0],
  [0, 1],
  [0, -1],
];

class GameScene extends Phaser.Scene {
  constructor() {
    super('Game');
  }

  init(data) {
    this.diffKey = DIFFICULTIES[data.difficulty] ? data.difficulty : 'normal';
    this.diff = DIFFICULTIES[this.diffKey];
    this.level = data.level || 1;
    this.score = data.score || 0;
    this.levelStartScore = this.score;
  }

  create() {
    this.cameras.main.setBackgroundColor(COLORS.bg);
    this.cameras.main.fadeIn(250, 15, 23, 42);

    this.finished = false;
    this.paused = false;
    this.moving = false;
    this.bumpLock = false;
    this.steps = 0;
    this.elapsed = 0;
    this.hintsLeft = this.diff.hints;
    this.moveDuration = 70;
    this.overlay = [];
    this.queuedDir = null;
    this.autoDir = null;
    this.swipeStart = null;

    this.buildLevel();
    this.createHud();
    this.setupInput();
    this.showBanner(`第 ${this.level} 关`);
  }

  // ---------- 关卡构建 ----------

  buildLevel() {
    const d = this.diff;
    const cols = Math.min(d.maxCols, d.baseCols + (this.level - 1) * d.growth);
    const rows = Math.min(d.maxRows, d.baseRows + Math.floor(((this.level - 1) * d.growth * 3) / 4));
    const { grid, width, height } = Maze.generate(cols, rows, d.braid);
    this.grid = grid;
    this.W = width;
    this.H = height;

    const areaW = GAME_WIDTH - 32;
    const areaH = GAME_HEIGHT - HUD_HEIGHT - 32;
    this.tile = Math.max(8, Math.floor(Math.min(areaW / width, areaH / height)));
    this.offsetX = Math.floor((GAME_WIDTH - this.tile * width) / 2);
    this.offsetY = HUD_HEIGHT + Math.floor((GAME_HEIGHT - HUD_HEIGHT - this.tile * height) / 2);

    this.drawMaze();

    // 起点固定在左上角，出口放在离起点最远的格子
    this.start = { x: 1, y: 1 };
    const dist = Maze.distances(grid, this.start);
    let exit = this.start;
    let far = 0;
    for (let y = 1; y < height; y += 2) {
      for (let x = 1; x < width; x += 2) {
        if (dist[y][x] > far) {
          far = dist[y][x];
          exit = { x, y };
        }
      }
    }
    this.exitPos = exit;
    this.optimal = far;

    const t = this.tile;
    const sp = this.toWorld(this.start.x, this.start.y);
    this.add.circle(sp.x, sp.y, t * 0.32, COLORS.accent, 0.18).setDepth(1);

    const ep = this.toWorld(exit.x, exit.y);
    this.exitSprite = this.add
      .image(ep.x, ep.y, 'exit')
      .setDisplaySize(t * 0.9, t * 0.9)
      .setDepth(d.exitVisible ? 9 : 2);
    this.tweens.add({
      targets: this.exitSprite,
      scale: this.exitSprite.scale * 1.12,
      duration: 700,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
    });

    // 金币
    const candidates = [];
    for (let y = 1; y < height; y += 2) {
      for (let x = 1; x < width; x += 2) {
        if (dist[y][x] > 3 && !(x === exit.x && y === exit.y)) candidates.push({ x, y });
      }
    }
    Phaser.Utils.Array.Shuffle(candidates);
    const count = Math.min(candidates.length, 3 + this.level, 12);
    this.coins = new Map();
    this.totalCoins = count;
    this.coinsCollected = 0;
    candidates.slice(0, count).forEach((c) => {
      const p = this.toWorld(c.x, c.y);
      const img = this.add.image(p.x, p.y, 'coin').setDisplaySize(t * 0.6, t * 0.6).setDepth(4);
      this.tweens.add({
        targets: img,
        y: p.y - t * 0.08,
        duration: 600 + Math.random() * 300,
        yoyo: true,
        repeat: -1,
        ease: 'Sine.easeInOut',
      });
      this.coins.set(`${c.x},${c.y}`, img);
    });

    // 玩家
    this.pos = { ...this.start };
    this.player = this.add.image(sp.x, sp.y, 'player').setDisplaySize(t * 0.82, t * 0.82).setDepth(6);

    this.hintGfx = this.add.graphics().setDepth(9.5);

    // 迷雾
    this.fog = null;
    if (d.fog) {
      this.explored = Array.from({ length: height }, () => new Array(width).fill(false));
      this.fog = this.add.graphics().setDepth(8);
      this.updateFog();
    }
  }

  drawMaze() {
    const g = this.add.graphics().setDepth(0);
    const t = this.tile;
    const ox = this.offsetX;
    const oy = this.offsetY;
    const edge = Math.max(2, Math.round(t * 0.18));

    g.fillStyle(COLORS.floor, 1);
    g.fillRect(ox, oy, t * this.W, t * this.H);

    for (let y = 0; y < this.H; y++) {
      for (let x = 0; x < this.W; x++) {
        if (this.grid[y][x] !== 1) continue;
        const px = ox + x * t;
        const py = oy + y * t;
        g.fillStyle(COLORS.wall, 1);
        g.fillRect(px, py, t, t);
        if (y === 0 || this.grid[y - 1][x] === 0) {
          g.fillStyle(COLORS.wallTop, 1);
          g.fillRect(px, py, t, edge);
        }
        if (y < this.H - 1 && this.grid[y + 1][x] === 0) {
          g.fillStyle(COLORS.wallShadow, 0.45);
          g.fillRect(px, py + t, t, edge);
        }
      }
    }
  }

  toWorld(x, y) {
    return {
      x: this.offsetX + x * this.tile + this.tile / 2,
      y: this.offsetY + y * this.tile + this.tile / 2,
    };
  }

  isOpen(x, y) {
    return !!this.grid[y] && this.grid[y][x] === 0;
  }

  // ---------- HUD ----------

  createHud() {
    const g = this.add.graphics().setDepth(20);
    g.fillStyle(COLORS.hud, 0.95);
    g.fillRect(0, 0, GAME_WIDTH, HUD_HEIGHT);
    g.lineStyle(1, 0x1e293b, 1);
    g.lineBetween(0, HUD_HEIGHT, GAME_WIDTH, HUD_HEIGHT);

    const y = HUD_HEIGHT / 2;
    this.hudLevel = this.add
      .text(16, y, `第 ${this.level} 关 · ${this.diff.label}`, {
        fontFamily: FONT,
        fontSize: '18px',
        fontStyle: 'bold',
        color: '#7dd3fc',
      })
      .setOrigin(0, 0.5)
      .setDepth(21);
    this.hudStats = this.add
      .text(170, y, '', { fontFamily: FONT, fontSize: '16px', color: '#e2e8f0' })
      .setOrigin(0, 0.5)
      .setDepth(21);

    this.btnHint = UI.button(this, 745, y, 60, 34, '提示', () => this.showHint(), { fontSize: 15, depth: 21 });
    this.btnPause = UI.button(this, 813, y, 60, 34, '暂停', () => this.togglePause(), { fontSize: 15, depth: 21 });
    this.btnMute = UI.button(this, 896, y, 90, 34, Sfx.isMuted() ? '声音:关' : '声音:开', () => this.toggleMute(), {
      fontSize: 15,
      depth: 21,
    });

    this.updateHud();
  }

  updateHud() {
    this.hudStats.setText(
      `时间 ${this.formatTime(this.elapsed / 1000)}   步数 ${this.steps}   金币 ${this.coinsCollected}/${this.totalCoins}   提示 ${this.hintsLeft}   分数 ${this.score}`
    );
  }

  formatTime(secs) {
    const s = Math.floor(secs);
    return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
  }

  // ---------- 输入 ----------

  setupInput() {
    const kb = this.input.keyboard;
    this.cursors = kb.createCursorKeys();
    this.wasd = kb.addKeys('W,A,S,D');

    kb.on('keydown-H', () => this.showHint());
    kb.on('keydown-P', () => {
      if (!this.finished) this.togglePause();
    });
    kb.on('keydown-ESC', () => {
      if (this.finished) this.goMenu();
      else this.togglePause();
    });
    kb.on('keydown-R', () => {
      if (!this.finished) this.restartLevel();
    });
    kb.on('keydown-M', () => this.toggleMute());
    kb.on('keydown-ENTER', () => {
      if (this.finished) this.nextLevel();
    });
    kb.on('keydown-SPACE', () => {
      if (this.finished) this.nextLevel();
    });

    // 触屏滑动：沿通道自动前进，直到岔路/死胡同
    this.input.on('pointerdown', (p) => {
      Sfx.unlock();
      if (p.y < HUD_HEIGHT || this.finished || this.paused) return;
      this.swipeStart = { x: p.x, y: p.y };
    });
    this.input.on('pointermove', (p) => {
      if (!p.isDown || !this.swipeStart) return;
      const dx = p.x - this.swipeStart.x;
      const dy = p.y - this.swipeStart.y;
      if (Math.hypot(dx, dy) < 24) return;
      const dir = Math.abs(dx) > Math.abs(dy) ? { x: Math.sign(dx), y: 0 } : { x: 0, y: Math.sign(dy) };
      this.queuedDir = dir;
      this.autoDir = dir;
      this.swipeStart = { x: p.x, y: p.y };
    });
    const end = () => (this.swipeStart = null);
    this.input.on('pointerup', end);
    this.input.on('pointerupoutside', end);
  }

  readDirection() {
    const c = this.cursors;
    const w = this.wasd;
    let dir = null;
    if (c.left.isDown || w.A.isDown) dir = { x: -1, y: 0 };
    else if (c.right.isDown || w.D.isDown) dir = { x: 1, y: 0 };
    else if (c.up.isDown || w.W.isDown) dir = { x: 0, y: -1 };
    else if (c.down.isDown || w.S.isDown) dir = { x: 0, y: 1 };

    if (dir) {
      this.autoDir = null;
      this.queuedDir = null;
      return dir;
    }
    if (this.queuedDir) {
      const q = this.queuedDir;
      this.queuedDir = null;
      return q;
    }
    return null;
  }

  update(time, delta) {
    if (this.finished || this.paused) return;
    this.elapsed += delta;
    this.updateHud();
    if (this.moving) return;
    const dir = this.readDirection();
    if (dir) this.tryMove(dir.x, dir.y);
  }

  // ---------- 移动 ----------

  tryMove(dx, dy) {
    const nx = this.pos.x + dx;
    const ny = this.pos.y + dy;
    if (!this.isOpen(nx, ny)) {
      this.autoDir = null;
      if (!this.bumpLock) {
        this.bumpLock = true;
        Sfx.bump();
        this.cameras.main.shake(70, 0.002);
        this.time.delayedCall(220, () => (this.bumpLock = false));
      }
      return;
    }

    this.moving = true;
    this.pos = { x: nx, y: ny };
    this.steps++;
    if (dx !== 0) this.player.setFlipX(dx < 0);
    if (this.steps % 2 === 1) Sfx.step();
    if (this.fog) this.updateFog();

    const p = this.toWorld(nx, ny);
    this.tweens.add({
      targets: this.player,
      x: p.x,
      y: p.y,
      duration: this.moveDuration,
      onComplete: () => {
        this.moving = false;
        this.onArrive();
      },
    });
  }

  onArrive() {
    const key = `${this.pos.x},${this.pos.y}`;
    const coin = this.coins.get(key);
    if (coin) this.collectCoin(key, coin);

    if (this.pos.x === this.exitPos.x && this.pos.y === this.exitPos.y) {
      this.completeLevel();
      return;
    }
    if (this.autoDir) this.continueAutoRun();
  }

  // 自动沿通道前进：只有 2 个出口（直道或拐角）时继续，遇到岔路或死胡同停下
  continueAutoRun() {
    const back = { x: -this.autoDir.x, y: -this.autoDir.y };
    const open = DIRS.filter(([dx, dy]) => this.isOpen(this.pos.x + dx, this.pos.y + dy));
    if (open.length !== 2) {
      this.autoDir = null;
      return;
    }
    const next = open.find(([dx, dy]) => !(dx === back.x && dy === back.y));
    if (!next) {
      this.autoDir = null;
      return;
    }
    this.autoDir = { x: next[0], y: next[1] };
    this.tryMove(next[0], next[1]);
  }

  // ---------- 迷雾 ----------

  updateFog() {
    const r = this.diff.fogRadius;
    const { x: px, y: py } = this.pos;
    const t = this.tile;
    const R = Math.ceil(r);

    for (let y = Math.max(0, py - R); y <= Math.min(this.H - 1, py + R); y++) {
      for (let x = Math.max(0, px - R); x <= Math.min(this.W - 1, px + R); x++) {
        if (Math.hypot(x - px, y - py) <= r) this.explored[y][x] = true;
      }
    }

    const g = this.fog;
    g.clear();
    const soft = 1.5;
    for (let y = 0; y < this.H; y++) {
      for (let x = 0; x < this.W; x++) {
        const d = Math.hypot(x - px, y - py);
        let a;
        if (d <= r - soft) a = 0;
        else if (d <= r) a = ((d - (r - soft)) / soft) * 0.55;
        else a = this.explored[y][x] ? 0.55 : 0.97;
        if (a > 0.01) {
          g.fillStyle(COLORS.fog, a);
          g.fillRect(this.offsetX + x * t, this.offsetY + y * t, t, t);
        }
      }
    }
  }

  // ---------- 道具 / 特效 ----------

  collectCoin(key, coin) {
    this.coins.delete(key);
    this.coinsCollected++;
    this.score += 100;
    Sfx.coin();
    this.tweens.killTweensOf(coin);
    this.tweens.add({
      targets: coin,
      scale: coin.scale * 1.8,
      alpha: 0,
      duration: 250,
      onComplete: () => coin.destroy(),
    });
    this.burst(coin.x, coin.y, COLORS.coin, 10);
    this.floatText(coin.x, coin.y, '+100', '#fde047');
  }

  burst(x, y, tint, count) {
    const emitter = this.add
      .particles(x, y, 'dot', {
        speed: { min: 50, max: 170 },
        lifespan: 450,
        scale: { start: 0.5, end: 0 },
        tint,
        emitting: false,
      })
      .setDepth(11);
    emitter.explode(count);
    this.time.delayedCall(700, () => emitter.destroy());
  }

  floatText(x, y, str, color) {
    const t = this.add
      .text(x, y, str, {
        fontFamily: FONT,
        fontSize: '18px',
        fontStyle: 'bold',
        color,
        stroke: '#0f172a',
        strokeThickness: 4,
      })
      .setOrigin(0.5)
      .setDepth(12);
    this.tweens.add({ targets: t, y: y - 36, alpha: 0, duration: 800, onComplete: () => t.destroy() });
  }

  showBanner(text) {
    const cy = (GAME_HEIGHT + HUD_HEIGHT) / 2;
    const t = this.add
      .text(GAME_WIDTH / 2, cy, text, {
        fontFamily: FONT,
        fontSize: '56px',
        fontStyle: 'bold',
        color: '#f8fafc',
        stroke: '#0f172a',
        strokeThickness: 8,
      })
      .setOrigin(0.5)
      .setDepth(25)
      .setAlpha(0)
      .setScale(0.8);
    this.tweens.add({
      targets: t,
      alpha: 1,
      scale: 1,
      duration: 300,
      ease: 'Back.easeOut',
      hold: 700,
      yoyo: true,
      onComplete: () => t.destroy(),
    });
  }

  // ---------- 提示 ----------

  showHint() {
    if (this.finished || this.paused) return;
    if (this.hintsLeft <= 0) {
      Sfx.bump();
      this.floatText(this.player.x, this.player.y - this.tile * 0.6, '提示已用完', '#fca5a5');
      return;
    }
    const path = Maze.shortestPath(this.grid, this.pos, this.exitPos);
    if (!path) return;

    this.hintsLeft--;
    this.score = Math.max(0, this.score - 50);
    Sfx.hint();
    this.floatText(this.player.x, this.player.y - this.tile * 0.6, '-50', '#f9a8d4');

    const g = this.hintGfx;
    this.tweens.killTweensOf(g);
    g.clear();
    g.setAlpha(1);
    const radius = Math.max(2, this.tile * 0.14);
    path.slice(1).forEach((p) => {
      const w = this.toWorld(p.x, p.y);
      g.fillStyle(COLORS.hint, 0.9);
      g.fillCircle(w.x, w.y, radius);
    });
    this.tweens.add({ targets: g, alpha: 0, delay: 2500, duration: 800 });
    this.updateHud();
  }

  // ---------- 面板 / 流程 ----------

  showPanel(title, lines, buttons) {
    this.clearPanel();
    const cx = GAME_WIDTH / 2;
    const cy = (GAME_HEIGHT + HUD_HEIGHT) / 2;
    const pw = 480;
    const ph = 130 + lines.length * 34 + 80;

    const dim = this.add
      .rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, 0x020617, 0.7)
      .setDepth(30)
      .setInteractive();
    const g = this.add.graphics().setDepth(31);
    g.fillStyle(0x0f172a, 1);
    g.fillRoundedRect(cx - pw / 2, cy - ph / 2, pw, ph, 18);
    g.lineStyle(2, 0x38bdf8, 0.8);
    g.strokeRoundedRect(cx - pw / 2, cy - ph / 2, pw, ph, 18);
    const titleText = this.add
      .text(cx, cy - ph / 2 + 46, title, { fontFamily: FONT, fontSize: '30px', fontStyle: 'bold', color: '#f8fafc' })
      .setOrigin(0.5)
      .setDepth(32);
    this.overlay.push(dim, g, titleText);

    lines.forEach(([label, value], i) => {
      const y = cy - ph / 2 + 104 + i * 34;
      const isTotal = i === lines.length - 1 && label === '总分';
      const l = this.add
        .text(cx - pw / 2 + 50, y, label, { fontFamily: FONT, fontSize: '18px', color: '#94a3b8' })
        .setOrigin(0, 0.5)
        .setDepth(32);
      const v = this.add
        .text(cx + pw / 2 - 50, y, value, {
          fontFamily: FONT,
          fontSize: isTotal ? '22px' : '18px',
          fontStyle: 'bold',
          color: isTotal ? '#fde047' : '#f8fafc',
        })
        .setOrigin(1, 0.5)
        .setDepth(32);
      this.overlay.push(l, v);
    });

    const bw = buttons.length >= 3 ? 130 : 180;
    const gap = 14;
    const total = buttons.length * bw + (buttons.length - 1) * gap;
    const startX = cx - total / 2 + bw / 2;
    buttons.forEach((b, i) => {
      const btn = UI.button(this, startX + i * (bw + gap), cy + ph / 2 - 50, bw, 48, b.label, b.cb, {
        primary: b.primary,
        fontSize: 18,
        depth: 33,
      });
      this.overlay.push(btn);
    });
  }

  clearPanel() {
    this.overlay.forEach((o) => o.destroy());
    this.overlay = [];
  }

  togglePause() {
    if (this.finished) return;
    this.paused = !this.paused;
    if (this.paused) {
      this.tweens.pauseAll();
      this.showPanel(
        '已暂停',
        [
          ['当前关卡', `第 ${this.level} 关`],
          ['用时', this.formatTime(this.elapsed / 1000)],
          ['分数', `${this.score}`],
        ],
        [
          { label: '返回菜单', cb: () => this.goMenu() },
          { label: '重新开始', cb: () => this.restartLevel() },
          { label: '继续', cb: () => this.togglePause(), primary: true },
        ]
      );
      this.btnPause.setLabel('继续');
    } else {
      this.tweens.resumeAll();
      this.clearPanel();
      this.btnPause.setLabel('暂停');
    }
  }

  toggleMute() {
    const muted = Sfx.toggleMute();
    this.btnMute.setLabel(muted ? '声音:关' : '声音:开');
  }

  completeLevel() {
    this.finished = true;
    this.autoDir = null;
    Sfx.win();
    this.burst(this.exitSprite.x, this.exitSprite.y, COLORS.exit, 28);
    if (this.fog) this.fog.clear();

    const secs = this.elapsed / 1000;
    const par = this.optimal * 0.18 + 5;
    const timeBonus = Math.max(0, Math.round((par - secs) * 20));
    const efficiency = Math.min(1, this.optimal / Math.max(1, this.steps));
    const pathBonus = Math.round(efficiency * 300);
    const levelBonus = 200 + this.level * 50;
    const hintBonus = this.hintsLeft * 50;
    this.score += timeBonus + pathBonus + levelBonus + hintBonus;
    this.updateHud();

    const best = Store.get('best_' + this.diffKey, { level: 0, score: 0 });
    const newRecord = this.score > best.score;
    Store.set('best_' + this.diffKey, {
      level: Math.max(best.level, this.level),
      score: Math.max(best.score, this.score),
    });

    this.time.delayedCall(450, () => {
      this.showPanel(
        newRecord ? `第 ${this.level} 关完成 · 新纪录!` : `第 ${this.level} 关完成!`,
        [
          ['用时', this.formatTime(secs)],
          ['步数 / 最短路线', `${this.steps} / ${this.optimal}`],
          ['金币', `${this.coinsCollected} / ${this.totalCoins}`],
          ['通关奖励', `+${levelBonus}`],
          ['路线效率', `+${pathBonus}`],
          ['速度奖励', `+${timeBonus}`],
          ['剩余提示', `+${hintBonus}`],
          ['总分', `${this.score}`],
        ],
        [
          { label: '返回菜单', cb: () => this.goMenu() },
          { label: '下一关 ▶', cb: () => this.nextLevel(), primary: true },
        ]
      );
    });
  }

  nextLevel() {
    this.scene.restart({ difficulty: this.diffKey, level: this.level + 1, score: this.score });
  }

  restartLevel() {
    this.tweens.resumeAll();
    this.scene.restart({ difficulty: this.diffKey, level: this.level, score: this.levelStartScore });
  }

  goMenu() {
    this.tweens.resumeAll();
    this.scene.start('Menu');
  }
}
