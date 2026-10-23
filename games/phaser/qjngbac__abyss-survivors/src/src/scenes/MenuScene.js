const FONT = '"Microsoft YaHei", "PingFang SC", sans-serif';
import getData from '../data.js';
import meta from '../meta.js';
import audio from '../audio.js';
import DIFFICULTY_CONFIGS from '../difficulty.js';

export default class MenuScene extends Phaser.Scene {
  constructor() { super('MenuScene'); }

  create() {
    const W = this.scale.width, H = this.scale.height;
    const chars = getData(this, 'characters').list;
    const levelList = getData(this, 'levels').levels;
    const mainIds = levelList.filter(l => !l.fun && !l.endless).map(l => l.id);
    const mainProgress = (diff) => {
      const cleared = meta.getCleared(diff);
      const done = mainIds.filter(id => id <= cleared).length;
      return '主线进度 ' + done + '/' + mainIds.length + (done >= mainIds.length ? ' · 已全部通关' : ' · 下一关：第 ' + mainIds[done] + ' 关');
    };

    this.add.rectangle(W / 2, H / 2, W, H, 0x1a1c2c);

    // 经典顶端大 LOGO 与大标题
    this.add.image(W / 2, 110, 'ui-title-logo').setDisplaySize(300, 150);
    this.add.text(W / 2, 195, '深 渊 幸 存 者', {
      fontFamily: FONT, fontSize: '38px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(0.5);
    this.add.text(W / 2, 232, 'WASD / 方向键移动 · 手机按住屏幕左半边拖动 · X 切换瞄准 · 升级按 1/2/3 · P 暂停 · M 静音 · 音乐开关在暂停面板', {
      fontFamily: FONT, fontSize: '13px', color: '#94b0c2'
    }).setOrigin(0.5);

    // 出战角色入口
    const curChar = chars.find(c => c.id === meta.getCharacter()) || chars[0];
    const charBtn = this.add.text(W / 2, 266, '— 出战角色 · ' + curChar.name + '（点击切换） —', {
      fontFamily: FONT, fontSize: '16px', color: '#41a6f6'
    }).setOrigin(0.5).setInteractive({ useHandCursor: true });
    charBtn.on('pointerdown', () => {
      audio.unlock();
      audio.click();
      this.scene.start('CharacterScene');
    });

    // 关卡难度选择栏：难度 1（普通） / 难度 2（困难） / 难度 3（噩梦）
    let curDiff = meta.getDifficulty();
    // 难度说明：按「我方 / 敌方 / 收益」三行分组，数值来自唯一数据源 DIFFICULTY_CONFIGS，
    // 不再用"·"和空格把三件事堆成一句话（原来 12px 一行很难扫读，也容易与实际数值脱节）。
    const diffDescGroup = this.add.container(0, 0);
    const drawDiffDesc = () => {
      diffDescGroup.removeAll(true);
      const cfg = DIFFICULTY_CONFIGS[curDiff] || DIFFICULTY_CONFIGS[1];
      const pct = v => {
        const n = Math.round((v - 1) * 100);
        return n === 0 ? '±0%' : (n > 0 ? '+' : '') + n + '%';
      };
      const rows = [
        { tag: '我方', color: '#ff9a9a', bg: 0x3a1c22, border: 0xb13e53,
          text: `生命 ${pct(cfg.player.hp)}    伤害 ${pct(cfg.player.dmg)}    移速 ${pct(cfg.player.speed)}` },
        { tag: '敌方', color: '#ffbe7a', bg: 0x3a2a18, border: 0xffa040,
          text: `生命 ${pct(cfg.enemy.hp)}    伤害 ${pct(cfg.enemy.dmg)}    移速 ${pct(cfg.enemy.speed)}    密度 ${pct(1 / cfg.enemy.interval)}` },
        { tag: '收益', color: '#8ee08e', bg: 0x1c3a24, border: 0x38b764,
          text: `金币 ${pct(cfg.goldMul)}    经验 ${pct(cfg.xpMul)}` }
      ];
      const TAG_W = 54, GAP = 8;
      const nodes = rows.map((row, i) => {
        const y = 346 + i * 20;
        const tagBg = this.add.rectangle(0, y, TAG_W, 20, row.bg).setStrokeStyle(1, row.border);
        const tagT = this.add.text(0, y, row.tag, { fontFamily: FONT, fontSize: '11px', color: row.color, fontStyle: 'bold' }).setOrigin(0.5);
        const val = this.add.text(0, y, row.text, { fontFamily: FONT, fontSize: '12px', color: row.color }).setOrigin(0, 0.5);
        diffDescGroup.add([tagBg, tagT, val]);
        return { tagBg, tagT, val };
      });
      // 创建后按最宽一行整体居中，保证三行标签左对齐、看着不歪
      const maxW = Math.max(...nodes.map(n => TAG_W + GAP + n.val.width));
      const left = W / 2 - maxW / 2;
      nodes.forEach(n => {
        n.tagBg.setX(left + TAG_W / 2);
        n.tagT.setX(left + TAG_W / 2);
        n.val.setX(left + TAG_W + GAP);
      });
    };

    const diffButtons = [];
    const diffOpts = [
      { id: 1, label: '难度 1 · 普通', color: '#38b764', activeBorder: 0x38b764 },
      { id: 2, label: '难度 2 · 困难', color: '#ffcd75', activeBorder: 0xffcd75 },
      { id: 3, label: '难度 3 · 噩梦', color: '#ff6b6b', activeBorder: 0xff6b6b }
    ];

    const refreshDiffUI = () => {
      diffButtons.forEach(({ id, bg, text, opt }) => {
        const active = (id === curDiff);
        bg.setFillStyle(active ? 0x2b2e42 : 0x14151f);
        bg.setStrokeStyle(active ? 3 : 1, active ? opt.activeBorder : 0x3a3d52);
        text.setColor(active ? opt.color : '#6b7280');
        text.setFontStyle(active ? 'bold' : 'normal');
      });
      drawDiffDesc();
      if (this.classicCardD2) this.classicCardD2.setText(mainProgress(curDiff));
    };

    diffOpts.forEach((opt, idx) => {
      const bx = W / 2 + (idx - 1) * 165;
      const by = 312;
      const bg = this.add.rectangle(bx, by, 150, 34, 0x14151f).setStrokeStyle(1, 0x3a3d52);
      const text = this.add.text(bx, by, opt.label, {
        fontFamily: FONT, fontSize: '13px', color: '#6b7280'
      }).setOrigin(0.5);
      bg.setInteractive({ useHandCursor: true }).on('pointerdown', () => {
        curDiff = opt.id;
        meta.setDifficulty(opt.id);
        audio.unlock();
        audio.click();
        refreshDiffUI();
      });
      diffButtons.push({ id: opt.id, bg, text, opt });
    });

    // 模式分割提示
    this.add.text(W / 2, 412, '— 选 择 游 戏 模 式 —', {
      fontFamily: FONT, fontSize: '15px', color: '#94b0c2'
    }).setOrigin(0.5);

    // 主页仅放两个模式卡片：经典关卡模式 & 进化模式
    const card1 = this._makeModeCard(
      W / 2 - 200, 520, 370, 170,
      '📜 经典关卡模式 (' + mainIds.length + ' 主线 + 趣味 + 无尽)', '#ffcd75', 0xffcd75,
      '通关解锁下一关 · Boss 讨伐 · 每关独立地貌配色',
      mainProgress(curDiff),
      '【 点击进入关卡选择 】', '#41a6f6',
      () => {
        audio.unlock();
        audio.click();
        this.scene.stop('MenuScene');
        this.scene.start('LevelSelectScene');
      }
    );
    this.classicCardD2 = card1.d2Text;

    const evoBest = meta.getEvoBest ? meta.getEvoBest() : 0;
    const evoRecord = evoBest >= 20 ? '👑 已通关 20 波（进化登顶！）' : (evoBest > 0 ? ('🏆 最好纪录：第 ' + evoBest + ' 波 / 20 波') : '未挑战（准备迎战第 1 波）');
    this._makeModeCard(
      W / 2 + 200, 520, 370, 170,
      '⚡ 进化模式 (土豆兄弟玩法)', '#d46c99', 0xd46c99,
      '全屏角斗场 · 全怪掉金 · 局间军备加点',
      evoRecord,
      '【 点击开始挑战 】', '#d46c99',
      () => {
        audio.unlock();
        audio.click();
        this.scene.stop('MenuScene');
        this.scene.start('GameScene', { mode: 'brotato', wave: 1, difficulty: meta.getDifficulty() });
      }
    );

    refreshDiffUI();

    // 商店 / 成就入口 + 金币余额（右上角经典布局）
    this.add.text(W - 24, 24, '金 币　' + meta.getGold(), {
      fontFamily: FONT, fontSize: '21px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(1, 0);
    this.makeNavBtn(W - 110, 90, '🏪 商店', 'ShopScene', 0xffcd75);
    this.makeNavBtn(W - 110, 150, '🏆 成就', 'AchievementsScene', 0x38b764);

    // 重置存档（左下角经典布局）
    let resetArmed = false;
    const resetText = this.add.text(16, H - 24, '重置存档', {
      fontFamily: FONT, fontSize: '13px', color: '#565a73'
    }).setOrigin(0, 0.5).setInteractive({ useHandCursor: true });
    resetText.on('pointerdown', () => {
      audio.click();
      if (!resetArmed) {
        resetArmed = true;
        resetText.setText('⚠ 再点一次确认清空全部进度').setColor('#ff6b6b');
        this.time.delayedCall(3000, () => {
          resetArmed = false;
          resetText.setText('重置存档').setColor('#565a73');
        });
      } else {
        meta.wipe();
        this.scene.restart();
      }
    });
  }

  _makeModeCard(x, y, w, h, title, titleCol, borderCol, desc1, desc2, btnLabel, btnCol, cb) {
    const c = this.add.container(x, y);
    const bg = this.add.rectangle(0, 0, w, h, 0x20222f).setStrokeStyle(2.5, borderCol);

    const titleText = this.add.text(0, -50, title, {
      fontFamily: FONT, fontSize: '18px', color: titleCol, fontStyle: 'bold'
    }).setOrigin(0.5);

    const d1 = this.add.text(0, -16, desc1, {
      fontFamily: FONT, fontSize: '12px', color: '#94b0c2'
    }).setOrigin(0.5);

    const d2 = this.add.text(0, 12, desc2, {
      fontFamily: FONT, fontSize: '13px', color: '#f4f4f4', fontStyle: 'bold'
    }).setOrigin(0.5);

    const btnBg = this.add.rectangle(0, 48, w - 50, 34, 0x141620).setStrokeStyle(1.5, borderCol);
    const btnTxt = this.add.text(0, 48, btnLabel, {
      fontFamily: FONT, fontSize: '14px', color: btnCol, fontStyle: 'bold'
    }).setOrigin(0.5);

    c.add([bg, titleText, d1, d2, btnBg, btnTxt]);

    bg.setInteractive({ useHandCursor: true });
    bg.on('pointerover', () => {
      bg.setFillStyle(0x282c3f);
      btnBg.setFillStyle(0x1e2436);
    });
    bg.on('pointerout', () => {
      bg.setFillStyle(0x20222f);
      btnBg.setFillStyle(0x141620);
    });
    bg.on('pointerdown', cb);
    btnBg.setInteractive({ useHandCursor: true }).on('pointerdown', cb);

    return { container: c, d2Text: d2 };
  }

  makeNavBtn(x, y, label, sceneKey, color) {
    const c = this.add.container(x, y);
    const bg = this.add.rectangle(0, 0, 130, 46, 0x20222f).setStrokeStyle(2, color);
    const t = this.add.text(0, 0, label, { fontFamily: FONT, fontSize: '19px', color: color }).setOrigin(0.5);
    c.add([bg, t]);
    bg.setInteractive({ useHandCursor: true }).on('pointerdown', () => {
      audio.unlock();
      audio.click();
      this.scene.start(sceneKey);
    });
  }
}