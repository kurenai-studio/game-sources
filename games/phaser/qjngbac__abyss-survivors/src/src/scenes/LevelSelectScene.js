const FONT = '"Microsoft YaHei", "PingFang SC", sans-serif';
import getData from '../data.js';
import meta from '../meta.js';
import audio from '../audio.js';

export default class LevelSelectScene extends Phaser.Scene {
  constructor() { super('LevelSelectScene'); }

  create() {
    const W = this.scale.width, H = this.scale.height;
    this.levels = getData(this, 'levels').levels;
    // 主线关 id 序列（趣味关/无尽不占解锁链）
    this.mainIds = this.levels.filter(l => !l.fun && !l.endless).map(l => l.id);

    this.add.rectangle(W / 2, H / 2, W, H, 0x1a1c2c);

    // 标题与返回
    this.add.text(W / 2, 34, '经 典 关 卡 选 择', {
      fontFamily: FONT, fontSize: '30px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(0.5);

    const backBtn = this.add.text(45, 24, '← 返回主菜单', {
      fontFamily: FONT, fontSize: '18px', color: '#41a6f6', fontStyle: 'bold'
    }).setOrigin(0, 0).setInteractive({ useHandCursor: true });
    backBtn.on('pointerdown', () => {
      audio.unlock();
      audio.click();
      this.scene.start('MenuScene');
    });

    this.goldText = this.add.text(W - 40, 24, '💰 金币  ' + meta.getGold(), {
      fontFamily: FONT, fontSize: '20px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(1, 0);

    // 难度切换栏：难度 1 / 2 / 3 关卡独立，难度 2 和 3 需从第 1 关开始通关
    this.curDiff = meta.getDifficulty();
    this._diffButtons = [];
    const diffOpts = [
      { id: 1, label: '⚔ 难度 1 · 普通', color: '#38b764', activeBorder: 0x38b764 },
      { id: 2, label: '🔥 难度 2 · 困难', color: '#ffcd75', activeBorder: 0xffcd75 },
      { id: 3, label: '☠ 难度 3 · 噩梦', color: '#ff6b6b', activeBorder: 0xff6b6b }
    ];

    diffOpts.forEach((opt, idx) => {
      const bx = W / 2 + (idx - 1) * 165;
      const by = 74;
      const bg = this.add.rectangle(bx, by, 150, 32, 0x14151f).setStrokeStyle(1, 0x3a3d52);
      const text = this.add.text(bx, by, opt.label, {
        fontFamily: FONT, fontSize: '13px', color: '#6b7280'
      }).setOrigin(0.5);
      bg.setInteractive({ useHandCursor: true }).on('pointerdown', () => {
        if (this.curDiff === opt.id) return;
        this.curDiff = opt.id;
        meta.setDifficulty(opt.id);
        audio.unlock();
        audio.click();
        this._refreshDiffUI();
        this._drawLevelGrid();
      });
      this._diffButtons.push({ id: opt.id, bg, text, opt });
    });

    this.subTitle = this.add.text(W / 2, 110, '', {
      fontFamily: FONT, fontSize: '12px', color: '#94b0c2'
    }).setOrigin(0.5);

    this.gridContainer = this.add.container(0, 0);

    this._refreshDiffUI();
    this._drawLevelGrid();

    this.add.text(W / 2, H - 20, '每种难度进度独立 · 主线按序解锁，趣味关与无尽随时可玩 · 点击已解锁关卡直接出战', {
      fontFamily: FONT, fontSize: '12px', color: '#565a73'
    }).setOrigin(0.5);
  }

  _refreshDiffUI() {
    const diffNames = { 1: '普通', 2: '困难', 3: '噩梦' };
    this._diffButtons.forEach(({ id, bg, text, opt }) => {
      const active = (id === this.curDiff);
      bg.setFillStyle(active ? 0x2b2e42 : 0x14151f);
      bg.setStrokeStyle(active ? 3 : 1, active ? opt.activeBorder : 0x3a3d52);
      text.setColor(active ? opt.color : '#6b7280');
      text.setFontStyle(active ? 'bold' : 'normal');
    });

    const cleared = meta.getCleared(this.curDiff);
    const done = this.mainIds.filter(id => id <= cleared).length;
    const all = this.mainIds.length;
    const nextMain = this.mainIds[done];
    const unlockDesc = done >= all
      ? '主线全通关 · 无尽与趣味关随时可玩'
      : `主线进度 ${done}/${all} · 下一关：第 ${nextMain} 关`;
    this.subTitle.setText(
      `当前挑战：${diffNames[this.curDiff]}难度 · ${unlockDesc}`
    );
  }

  _drawLevelGrid() {
    this.gridContainer.removeAll(true);
    const W = this.scale.width;
    const cleared = meta.getCleared(this.curDiff);

    // 14 关卡网格：3 列 × 5 行
    const cols = 3, cardW = 380, cardH = 74, gapX = 20, gapY = 12;
    const totalW = cols * cardW + (cols - 1) * gapX;
    const startX = (W - totalW) / 2 + cardW / 2;
    const startY = 142;
    const rowH = cardH + gapY;

    const clearedIdx = this.mainIds.filter(id => id <= cleared).length;

    this.levels.forEach((lv, i) => {
      const col = i % cols, row = Math.floor(i / cols);
      const x = startX + col * (cardW + gapX);
      const y = startY + row * rowH;
      const isEndless = !!lv.endless;
      const isFun = !!lv.fun;
      // 趣味关与无尽随时可玩；主线关按主线序列逐关解锁（难度 1/2/3 进度独立）
      const unlocked = (isEndless || isFun) ? true : this.mainIds.indexOf(lv.id) <= clearedIdx;
      const accent = (isEndless || isFun) ? 0xd46c99 : 0xffcd75;

      const c = this.add.container(x, y);
      const borderCol = unlocked ? accent : 0x2e3244;
      const bg = this.add.rectangle(0, 0, cardW, cardH, unlocked ? 0x20222f : 0x14151f)
        .setStrokeStyle(1.8, borderCol);

      // 左侧序号徽章
      const badgeBgCol = unlocked ? ((isEndless || isFun) ? 0x3d1c30 : 0x2d2518) : 0x181922;
      const badgeBg = this.add.rectangle(-cardW / 2 + 30, 0, 42, 42, badgeBgCol).setStrokeStyle(1, borderCol);
      const mainNo = this.mainIds.indexOf(lv.id) + 1;
      const numStr = isEndless ? '∞' : isFun ? ('F' + (lv.id - 9)) : (mainNo < 10 ? '0' + mainNo : '' + mainNo);
      const accentHex = (isEndless || isFun) ? '#d46c99' : '#ffcd75';
      const numCol = unlocked ? accentHex : '#45485c';
      const numTxt = this.add.text(-cardW / 2 + 30, 0, numStr, {
        fontFamily: FONT, fontSize: '18px', color: numCol, fontStyle: 'bold'
      }).setOrigin(0.5);

      // 关卡名称
      const dispName = unlocked ? lv.name : '？？？ 未解锁';
      const nameTxt = this.add.text(-cardW / 2 + 62, -15, dispName, {
        fontFamily: FONT, fontSize: '15px', color: unlocked ? accentHex : '#4a4d63', fontStyle: 'bold'
      }).setOrigin(0, 0.5);

      // 副描述
      const prevMain = this.mainIds.filter(id => id < lv.id).pop() || 1;
      let descLine = '';
      if (!unlocked) descLine = `需先通关主线第 ${prevMain} 关（难度 ${this.curDiff}）`;
      else if (isEndless) descLine = '无限生存 · Boss 轮番登场';
      else if (isFun) descLine = '趣味规则 · 独立解锁 · 不计入主线进度';
      else descLine = '首领: ' + lv.bossName + ' · ⏱ ' + Math.round(lv.duration / 60) + ' 分钟'
        + (lv.hazard ? ' · ⚠ ' + (lv.hazard === 'lava' ? '熔岩池' : lv.hazard === 'wisp' ? '游荡幽魂' : lv.hazard) : '');
      const subTxt = this.add.text(-cardW / 2 + 62, 14, descLine,
        { fontFamily: FONT, fontSize: '11px', color: unlocked ? '#94b0c2' : '#3a3d52' }
      ).setOrigin(0, 0.5);

      c.add([bg, badgeBg, numTxt, nameTxt, subTxt]);

      // 最佳战绩（读取该难度下的战绩）
      if (unlocked) {
        const best = meta.getBest(lv.id, this.curDiff);
        if (best > 0) {
          const bStr = isEndless
            ? ('最久 ' + Math.floor(best / 60) + ':' + String(best % 60).padStart(2, '0'))
            : ('最快 ' + Math.floor(best / 60) + ':' + String(best % 60).padStart(2, '0'));
          const bTxt = this.add.text(cardW / 2 - 14, 0, bStr, {
            fontFamily: FONT, fontSize: '11px', color: '#41a6f6', fontStyle: 'bold'
          }).setOrigin(1, 0.5);
          c.add(bTxt);
        }

        // 交互悬停与点击
        bg.setInteractive({ useHandCursor: true });
        bg.on('pointerover', () => bg.setFillStyle(0x282b3d));
        bg.on('pointerout', () => bg.setFillStyle(0x20222f));
        bg.on('pointerdown', () => {
          audio.unlock();
          audio.click();
          this.registry.set('level', lv.id);
          this.scene.start('GameScene', { level: lv.id, difficulty: this.curDiff });
        });
      }

      this.gridContainer.add(c);
    });
  }
}