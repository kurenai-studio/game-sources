// 主菜单：选择难度、查看最高纪录、开始游戏
class MenuScene extends Phaser.Scene {
  constructor() {
    super('Menu');
  }

  create() {
    this.starting = false;
    this.cameras.main.setBackgroundColor(COLORS.bg);
    this.cameras.main.fadeIn(250, 15, 23, 42);
    this.drawBackdrop();

    const cx = GAME_WIDTH / 2;

    const panel = this.add.graphics();
    panel.fillStyle(0x0f172a, 0.9);
    panel.fillRoundedRect(cx - 330, 80, 660, 580, 24);
    panel.lineStyle(2, 0x1e3a5f, 1);
    panel.strokeRoundedRect(cx - 330, 80, 660, 580, 24);

    const hero = this.add.image(cx, 145, 'player').setDisplaySize(64, 64);
    this.tweens.add({ targets: hero, y: 135, duration: 900, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });

    this.add
      .text(cx, 215, 'MAZE RUNNER', { fontFamily: FONT, fontSize: '58px', fontStyle: 'bold', color: '#f8fafc' })
      .setOrigin(0.5);
    this.add
      .text(cx, 268, '迷宫逃脱 · 收集金币 · 找到出口', { fontFamily: FONT, fontSize: '20px', color: '#94a3b8' })
      .setOrigin(0.5);

    this.add.text(cx, 322, '选择难度', { fontFamily: FONT, fontSize: '16px', color: '#64748b' }).setOrigin(0.5);

    const keys = Object.keys(DIFFICULTIES);
    this.diffButtons = keys.map((k, i) => {
      const btn = UI.button(this, cx + (i - 1) * 190, 368, 170, 52, DIFFICULTIES[k].label, () => this.select(k));
      btn.key = k;
      return btn;
    });

    this.descText = this.add
      .text(cx, 422, '', { fontFamily: FONT, fontSize: '16px', color: '#94a3b8' })
      .setOrigin(0.5);
    this.bestText = this.add
      .text(cx, 452, '', { fontFamily: FONT, fontSize: '15px', color: '#fbbf24' })
      .setOrigin(0.5);

    UI.button(this, cx, 525, 260, 64, '开始游戏', () => this.startGame(), { primary: true });

    this.add
      .text(
        cx,
        604,
        '方向键 / WASD 移动   H 提示路线   P / Esc 暂停   R 重开   M 静音\n手机：滑动屏幕，角色会沿通道前进，遇到岔路自动停下',
        { fontFamily: FONT, fontSize: '14px', color: '#64748b', align: 'center', lineSpacing: 8 }
      )
      .setOrigin(0.5);

    this.add
      .text(cx, GAME_HEIGHT - 28, 'Made with Phaser 3', { fontFamily: FONT, fontSize: '12px', color: '#475569' })
      .setOrigin(0.5);

    const kb = this.input.keyboard;
    kb.on('keydown-ONE', () => this.select('easy'));
    kb.on('keydown-TWO', () => this.select('normal'));
    kb.on('keydown-THREE', () => this.select('hard'));
    kb.on('keydown-LEFT', () => this.cycle(-1));
    kb.on('keydown-RIGHT', () => this.cycle(1));
    kb.on('keydown-ENTER', () => this.startGame());
    kb.on('keydown-SPACE', () => this.startGame());

    const saved = Store.get('difficulty', 'normal');
    this.select(DIFFICULTIES[saved] ? saved : 'normal');
  }

  drawBackdrop() {
    const tile = 24;
    const cols = Math.floor((GAME_WIDTH / tile - 1) / 2);
    const rows = Math.floor((GAME_HEIGHT / tile - 1) / 2);
    const { grid, width, height } = Maze.generate(cols, rows, 0.1);
    const ox = (GAME_WIDTH - width * tile) / 2;
    const oy = (GAME_HEIGHT - height * tile) / 2;
    const g = this.add.graphics();
    g.fillStyle(COLORS.wall, 0.35);
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        if (grid[y][x] === 1) g.fillRect(ox + x * tile, oy + y * tile, tile, tile);
      }
    }
  }

  cycle(delta) {
    const keys = Object.keys(DIFFICULTIES);
    const i = keys.indexOf(this.selected);
    this.select(keys[(i + delta + keys.length) % keys.length]);
    Sfx.click();
  }

  select(key) {
    this.selected = key;
    Store.set('difficulty', key);
    this.diffButtons.forEach((b) => b.setSelected(b.key === key));
    this.descText.setText(DIFFICULTIES[key].desc);
    const best = Store.get('best_' + key, null);
    this.bestText.setText(
      best && best.score > 0 ? `最高纪录：第 ${best.level} 关 · ${best.score} 分` : '最高纪录：暂无'
    );
  }

  startGame() {
    if (this.starting) return;
    this.starting = true;
    Sfx.unlock();
    this.cameras.main.fadeOut(250, 15, 23, 42);
    this.cameras.main.once('camerafadeoutcomplete', () => {
      this.scene.start('Game', { difficulty: this.selected, level: 1, score: 0 });
    });
  }
}
