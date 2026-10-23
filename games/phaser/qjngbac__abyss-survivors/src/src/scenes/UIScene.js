const FONT = '"Microsoft YaHei", "PingFang SC", sans-serif';
const W = 1280, H = 720;
import meta from '../meta.js';
import audio from '../audio.js';
import getData from '../data.js';

// UI 层：与 GameScene 并行运行；HUD 固定屏幕；暂停/升级/结算时 GameScene 暂停，此场景仍可交互
export default class UIScene extends Phaser.Scene {
  constructor() { super('UIScene'); }

  create() {
    this.gameScene = this.scene.get('GameScene');
    this.levelUpVisible = false;
    this.gameOverVisible = false;
    this.pauseVisible = false;
    const gs = this.gameScene;

    // 顶部经验条
    this.add.rectangle(0, 0, W, 10, 0x0d0e1a).setOrigin(0);
    this.xpFill = this.add.rectangle(0, 0, W, 10, 0x41a6f6).setOrigin(0);

    // 头像 + 血条
    this.add.image(30, 52, 'ui-portrait-hero').setDisplaySize(44, 44);
    this.add.rectangle(58, 46, 208, 18, 0x0d0e1a).setOrigin(0);
    this.hpFill = this.add.rectangle(60, 48, 204, 14, 0xb13e53).setOrigin(0);
    this.hpText = this.add.text(162, 55, '', { fontFamily: FONT, fontSize: '13px', color: '#f4f4f4' }).setOrigin(0.5);

    this.levelText = this.add.text(12, 76, 'Lv 1', { fontFamily: FONT, fontSize: '18px', color: '#f4f4f4' });
    const diffBadge = (gs.diffConfig && gs.diffConfig.badge) ? ` [难度${gs.difficulty}·${gs.diffConfig.badge}]` : '';
    const modeTitle = gs.isBrotato ? '⚡ 进化模式' : gs.levelConfig.name;
    this.levelNameText = this.add.text(W / 2, 18, `${modeTitle}${diffBadge}`, {
      fontFamily: FONT, fontSize: '16px', color: gs.isBrotato ? '#d46c99' : '#94b0c2', fontStyle: gs.isBrotato ? 'bold' : 'normal'
    }).setOrigin(0.5, 0);
    this.timerText = this.add.text(W / 2, 38, '00:00', { fontFamily: FONT, fontSize: '22px', color: '#f4f4f4' }).setOrigin(0.5, 0);
    this.killsText = this.add.text(W - 276, 22, '击杀 0', { fontFamily: FONT, fontSize: '17px', color: '#94b0c2' }).setOrigin(1, 0.5);
    this.goldText = this.add.text(W - 276, 48, '金币 0', { fontFamily: FONT, fontSize: '17px', color: '#ffcd75' }).setOrigin(1, 0.5);

    // Boss 血条（Boss 登场时显示；进化模式终幕同时有两只 Boss，第二行显示第二只）
    this.bossBarBg = this.add.rectangle(W / 2, 122, 420, 18, 0x0d0e1a).setOrigin(0.5).setDepth(40).setVisible(false);
    this.bossBarFill = this.add.rectangle(W / 2, 122, 414, 13, 0xb13e53).setOrigin(0.5).setDepth(41).setVisible(false);
    this.bossNameText = this.add.text(W / 2, 122, '', {
      fontFamily: FONT, fontSize: '13px', color: '#f4f4f4', fontStyle: 'bold'
    }).setOrigin(0.5).setDepth(42).setVisible(false);
    this.bossBar2Bg = this.add.rectangle(W / 2, 150, 420, 15, 0x0d0e1a).setOrigin(0.5).setDepth(40).setVisible(false);
    this.bossBar2Fill = this.add.rectangle(W / 2, 150, 414, 10, 0xb13e53).setOrigin(0.5).setDepth(41).setVisible(false);
    this.bossName2Text = this.add.text(W / 2, 150, '', {
      fontFamily: FONT, fontSize: '12px', color: '#f4f4f4', fontStyle: 'bold'
    }).setOrigin(0.5).setDepth(42).setVisible(false);

    // 屏幕外威胁指示箭头 (Boss: 红色, 精英: 紫红色, 黄金哥布林: 金色)
    this.bossArrow = this.add.triangle(0, 0, 0, -9, 18, 0, 0, 9)
      .setFillStyle(0xff6b6b).setDepth(95).setVisible(false);
    this.eliteArrow = this.add.triangle(0, 0, 0, -8, 16, 0, 0, 8)
      .setFillStyle(0xd46c99).setDepth(94).setVisible(false);
    this.goblinArrow = this.add.triangle(0, 0, 0, -8, 16, 0, 0, 8)
      .setFillStyle(0xffcd75).setDepth(94).setVisible(false);

    // 濒死危急晕影层 (血量 < 25% 时心跳红光呼吸)
    this.vignetteGfx = this.add.graphics().setDepth(85);

    // 构筑栏（武器/被动图标随升级刷新）
    this.strip = null;
    this._buildSig = '';

    // 瞄准模式切换按钮（仅键鼠）+ 暂停 / 结束按钮（右上角；按钮放大到 38 高，改善触屏点按）
    if (!gs.isMobile) this.makeAimButton(W - 212, 24, () => this.gameScene.toggleAimMode());
    this.makeButton(W - 124, 24, '⏸ 暂停', () => this.togglePause());
    this.makeButton(W - 42, 24, '✕ 结束', () => this.confirmEndRun());

    // 虚拟摇杆显示
    this.joyGfx = this.add.graphics().setDepth(90);

    this.input.keyboard.on('keydown-R', () => { if (this.gameOverVisible) this.restart(); });
    this.input.keyboard.on('keydown-P', () => this.togglePause());
    this.input.keyboard.on('keydown-ONE', () => this.pickLevelUpOption(0));
    this.input.keyboard.on('keydown-TWO', () => this.pickLevelUpOption(1));
    this.input.keyboard.on('keydown-THREE', () => this.pickLevelUpOption(2));
  }

  pickLevelUpOption(i) {
    if (!this.levelUpVisible || !this.levelUpOptions) return;
    const opt = this.levelUpOptions[i];
    if (!opt) return;
    this.hideLevelUp();
    this.gameScene.chooseUpgrade(opt);
  }

  makeAimButton(x, y, cb) {
    const c = this.add.container(x, y).setDepth(50);
    const bg = this.add.rectangle(0, 0, 94, 38, 0x20222f).setStrokeStyle(2, 0x4fc3f7);
    const t = this.add.text(0, 0, '🎯 自动 (X)', { fontFamily: FONT, fontSize: '13px', color: '#4fc3f7', fontStyle: 'bold' }).setOrigin(0.5);
    c.add([bg, t]);
    bg.setInteractive({ useHandCursor: true }).on('pointerdown', cb);
    this.aimBtnText = t;
    this.aimBtnBg = bg;
    return c;
  }

  updateAimButton(mode) {
    if (!this.aimBtnText || !this.aimBtnBg) return;
    if (mode === 'cursor') {
      this.aimBtnText.setText('🖱️ 手动 (X)').setColor('#ffe600');
      this.aimBtnBg.setStrokeStyle(2, 0xffe600);
    } else {
      this.aimBtnText.setText('🎯 自动 (X)').setColor('#4fc3f7');
      this.aimBtnBg.setStrokeStyle(2, 0x4fc3f7);
    }
  }

  makeButton(x, y, label, cb) {
    const c = this.add.container(x, y).setDepth(50);
    const bg = this.add.rectangle(0, 0, 74, 38, 0x20222f).setStrokeStyle(2, 0x94b0c2);
    const t = this.add.text(0, 0, label, { fontFamily: FONT, fontSize: '14px', color: '#f4f4f4' }).setOrigin(0.5);
    c.add([bg, t]);
    bg.setInteractive({ useHandCursor: true }).on('pointerdown', cb);
    return c;
  }

  // ---------- 暂停 ----------

  togglePause() {
    const gs = this.gameScene;
    if (gs.gameOver || this.gameOverVisible || this.levelUpVisible) return;
    if (this.pauseVisible) { this.closePause(); return; }
    this.pauseVisible = true;
    gs.scene.pause();
    this.pauseContainer = this.add.container(0, 0).setDepth(110);
    this.pauseContainer.add(this.add.rectangle(W / 2, H / 2, W, H, 0x000000, 0.65));
    this.pauseContainer.add(this.add.text(W / 2, H / 2 - 120, '已 暂 停', {
      fontFamily: FONT, fontSize: '48px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(0.5));
    this.pauseContainer.add(this.pauseBtn(W / 2, H / 2 - 20, '▶ 继续游戏', () => this.closePause(), 0x41a6f6));
    this.pauseContainer.add(this.pauseBtn(W / 2, H / 2 + 50, '✕ 结束本局', () => { this.closePause(); this.endRun(); }, 0xb13e53));
    this.pauseContainer.add(this.pauseBtn(W / 2, H / 2 + 120, '⌂ 返回主菜单', () => this.toMenu(), 0x94b0c2));

    // 音量调节行：音量  [ − ]  [═════进度条═════]  [ ＋ ]  100%
    const volRow = this.add.container(W / 2, H / 2 + 195);
    const volLabel = this.add.text(-210, 0, '音量', {
      fontFamily: FONT, fontSize: '18px', color: '#f4f4f4', fontStyle: 'bold'
    }).setOrigin(0.5);

    const barW = 180, barH = 12;
    const barStartX = -90; // 从 -90 到 +90
    const volBg = this.add.rectangle(barStartX, 0, barW, barH, 0x0d0e1a).setOrigin(0, 0.5);
    const volFill = this.add.rectangle(barStartX, 0, barW, barH, 0x41a6f6).setOrigin(0, 0.5);

    const mkBtn = (x, label, d) => {
      const b = this.add.rectangle(x, 0, 42, 38, 0x20222f).setStrokeStyle(2, 0x94b0c2);
      const t = this.add.text(x, 0, label, { fontFamily: FONT, fontSize: '22px', color: '#f4f4f4', fontStyle: 'bold' }).setOrigin(0.5);
      b.setInteractive({ useHandCursor: true }).on('pointerdown', () => {
        applyVol(audio.getVolume() + d);
      });
      b.on('pointerover', () => b.setFillStyle(0x2d3248));
      b.on('pointerout', () => b.setFillStyle(0x20222f));
      volRow.add([b, t]);
    };

    mkBtn(-135, '−', -0.1);
    mkBtn(135, '＋', 0.1);

    const volPct = this.add.text(210, 0, '100%', {
      fontFamily: FONT, fontSize: '16px', color: '#f4f4f4', fontStyle: 'bold'
    }).setOrigin(0.5);

    const applyVol = (v) => {
      audio.setVolume(v);
      const cur = audio.getVolume();
      volFill.displayWidth = Math.max(0, barW * cur);
      volPct.setText(Math.round(cur * 100) + '%');
    };

    volRow.add([volLabel, volBg, volFill, volPct]);
    applyVol(audio.getVolume());

    // 背景音乐开关（与音效共用主音量，另有固定低增益）
    const mBtn = this.add.rectangle(-160, 46, 170, 34, 0x1e3a2f).setStrokeStyle(2, 0x38b764);
    const mText = this.add.text(-160, 46, '', { fontFamily: FONT, fontSize: '16px', fontStyle: 'bold' }).setOrigin(0.5);
    const refreshMusicBtn = () => {
      const on = audio.musicEnabled;
      mBtn.setFillStyle(on ? 0x1e3a2f : 0x14151f);
      mBtn.setStrokeStyle(2, on ? 0x38b764 : 0x3a3d52);
      mText.setText(on ? '♪ 音乐：开' : '♪ 音乐：关');
      mText.setColor(on ? '#38b764' : '#565a73');
    };
    mBtn.setInteractive({ useHandCursor: true }).on('pointerdown', () => {
      audio.toggleMusic();
      audio.click();
      refreshMusicBtn();
    });
    volRow.add([mBtn, mText]);
    refreshMusicBtn();

    this.pauseContainer.add(volRow);
    this.pauseContainer.add(this.add.text(W / 2, H / 2 + 290, 'M 键静音 · 音乐与音量在本面板调节，切到后台自动静音', {
      fontFamily: FONT, fontSize: '13px', color: '#565a73'
    }).setOrigin(0.5));
  }

  pauseBtn(x, y, label, cb, color) {
    const c = this.add.container(x, y);
    const bg = this.add.rectangle(0, 0, 300, 56, 0x20222f).setStrokeStyle(3, color);
    const t = this.add.text(0, 0, label, { fontFamily: FONT, fontSize: '24px', color }).setOrigin(0.5);
    c.add([bg, t]);
    bg.setInteractive({ useHandCursor: true }).on('pointerdown', cb);
    return c;
  }

  closePause() {
    if (!this.pauseVisible) return;
    this.pauseVisible = false;
    if (this.pauseContainer) { this.pauseContainer.destroy(); this.pauseContainer = null; }
    this.gameScene.scene.resume();
  }

  endRun() {
    if (this.gameScene.gameOver || this.gameOverVisible || this.levelUpVisible) return;
    this.gameScene.triggerGameOver(false, true); // 放弃本局
  }

  // 右上角「✕ 结束」：2.6 秒内再点一次才真正放弃，避免误触直接毁掉一局
  confirmEndRun() {
    if (this.gameScene.gameOver || this.gameOverVisible || this.levelUpVisible) return;
    if (this._endArmedUntil && this.time.now < this._endArmedUntil) {
      this._endArmedUntil = 0;
      this.endRun();
      return;
    }
    this._endArmedUntil = this.time.now + 2600;
    this.toast('再次点击「✕ 结束」确认放弃本局');
  }

  toMenu() {
    this.pauseVisible = false;
    if (this.pauseContainer) { this.pauseContainer.destroy(); this.pauseContainer = null; }
    this.hideLevelUp();
    this.gameOverVisible = false;
    if (this.gameOverContainer) { this.gameOverContainer.destroy(); this.gameOverContainer = null; }
    this.gameScene.scene.stop();
    this.scene.start('MenuScene');
  }

  update() {
    const gs = this.gameScene;
    if (!gs || !gs.scene.isActive() || !gs.xpSystem) return;

    const xs = gs.xpSystem;
    this.xpFill.displayWidth = W * Phaser.Math.Clamp(xs.xp / xs.need(), 0, 1);
    this.levelText.setText(`Lv ${xs.level}`);

    // 计时：土豆兄弟模式显示波次倒计时；普通关卡显示 Boss 倒计时；无尽模式显示生存时间
    if (gs.isBrotato) {
      const wave = gs.brotoWave || 1;
      const maxWave = gs.brotoMaxWave || 20;
      const remain = Math.max(0, Math.ceil(gs.brotoWaveTimer || 0));
      const isFinal = wave >= maxWave;
      this.timerText.setText(isFinal ? `WAVE ${wave}/${maxWave}  ⚔ 全歼双首领` : `WAVE ${wave}/${maxWave}  ⏱ ${remain}s`);
      this.timerText.setColor(isFinal || remain <= 5 ? '#b13e53' : '#ffcd75');
    } else if (!isFinite(gs.levelDuration)) {
      const e = Math.floor(gs.elapsed);
      this.timerText.setText(`已生存 ${Math.floor(e / 60)}:${String(e % 60).padStart(2, '0')}`);
      this.timerText.setColor('#ffcd75');
    } else {
      const remain = Math.max(0, gs.levelDuration - Math.floor(gs.elapsed));
      if (remain > 0) {
        this.timerText.setText(`BOSS ${Math.floor(remain / 60)}:${String(remain % 60).padStart(2, '0')}`);
        this.timerText.setColor(remain <= 30 ? '#b13e53' : '#f4f4f4');
      } else {
        this.timerText.setText('BOSS 来了！');
        this.timerText.setColor('#b13e53');
      }
    }
    this.killsText.setText(`击杀 ${gs.kills}`);
    this.goldText.setText(gs.isBrotato ? `局内币 ${gs.coins}` : `金币 ${gs.coins}`);

    const hpRatio = Phaser.Math.Clamp(gs.player.hp / gs.player.maxHp, 0, 1);
    this.hpFill.displayWidth = 204 * hpRatio;
    this.hpText.setText(`${Math.ceil(gs.player.hp)} / ${gs.player.maxHp}`);

    // 低血量危急反馈 (<25%): 红色呼吸晕影 + 心跳音效
    this.updateLowHpFeedback(gs, hpRatio);

    // Boss 血条 + 屏幕外多目标威胁雷达 (Boss / 精英 / 黄金哥布林) + 构筑栏
    const bosses = this.findBosses(gs);
    this.updateBossBar(gs, bosses);
    if (!gs.gameOver) {
      this.updateOffscreenArrow(this.bossArrow, bosses[0] || null, gs.cameras.main);
      this.updateOffscreenArrow(this.eliteArrow, this.findElite(gs), gs.cameras.main);
      this.updateOffscreenArrow(this.goblinArrow, this.findGoblin(gs), gs.cameras.main);
    } else {
      this.bossArrow.setVisible(false);
      this.eliteArrow.setVisible(false);
      this.goblinArrow.setVisible(false);
    }
    this.updateBuildStrip(gs);

    this.drawJoystick(gs);
  }

  // 低血量危急边框渐变红光脉动与心跳声
  updateLowHpFeedback(gs, hpRatio) {
    if (!this.vignetteGfx) return;
    this.vignetteGfx.clear();
    if (gs.gameOver || (gs.player && gs.player.dead) || hpRatio >= 0.25) return;

    // 心跳音效（audio.heartbeat 内部已节流 650ms）
    try { audio.heartbeat(); } catch (e) {}

    // 呼吸红晕随血量降低越发剧烈
    const urgency = 1 - (hpRatio / 0.25); // 0 ~ 1
    const pulse = 0.5 + Math.sin(this.time.now / 150) * 0.5;
    const alpha = (0.18 + urgency * 0.28) * (0.6 + pulse * 0.4);

    const borderThickness = 48 + urgency * 26;
    this.vignetteGfx.fillStyle(0xb13e53, alpha * 0.35);
    this.vignetteGfx.fillRect(0, 0, W, borderThickness);
    this.vignetteGfx.fillRect(0, H - borderThickness, W, borderThickness);
    this.vignetteGfx.fillRect(0, 0, borderThickness, H);
    this.vignetteGfx.fillRect(W - borderThickness, 0, borderThickness, H);

    this.vignetteGfx.lineStyle(4, 0xff2a45, alpha * 0.85);
    this.vignetteGfx.strokeRect(2, 2, W - 4, H - 4);
  }

  findBosses(gs) {
    return gs.enemies.getChildren().filter(e => e.active && e.cfg && e.cfg.behavior === 'boss');
  }

  findElite(gs) {
    return gs.enemies.getChildren().find(e => e.active && e.cfg && e.cfg.elite && e.cfg.behavior !== 'boss') || null;
  }

  findGoblin(gs) {
    return gs.enemies.getChildren().find(e => e.active && e.cfg && e.cfg.goldGoblin) || null;
  }

  updateBossBar(gs, bosses) {
    const list = (!gs.gameOver && bosses) ? bosses.slice(0, 2) : [];
    const rows = [
      { bg: this.bossBarBg, fill: this.bossBarFill, text: this.bossNameText },
      { bg: this.bossBar2Bg, fill: this.bossBar2Fill, text: this.bossName2Text }
    ];
    rows.forEach((row, i) => {
      const b = list[i];
      if (!b) {
        row.bg.setVisible(false); row.fill.setVisible(false); row.text.setVisible(false);
        return;
      }
      row.bg.setVisible(true); row.fill.setVisible(true); row.text.setVisible(true);
      const ratio = Phaser.Math.Clamp(b.hp / b.maxHp, 0, 1);
      row.fill.displayWidth = 414 * ratio;
      row.fill.setFillStyle(b.enraged ? 0xff5050 : 0xb13e53);
      row.text.setText((b.enraged ? '🔥 ' : '') + b.cfg.name);
    });
  }

  // 通用屏幕外目标追踪指示箭头（Boss / 精英 / 黄金哥布林）
  updateOffscreenArrow(arrow, target, cam) {
    if (!arrow) return;
    if (!target || !target.active) {
      arrow.setVisible(false);
      return;
    }
    const sx = target.x - cam.scrollX, sy = target.y - cam.scrollY;
    // 如果已经在屏幕视野内，隐藏指示箭头
    if (sx > 30 && sx < W - 30 && sy > 30 && sy < H - 30) {
      arrow.setVisible(false);
      return;
    }
    const cx = W / 2, cy = H / 2;
    const a = Math.atan2(sy - cy, sx - cx);
    const rx = W / 2 - 70, ry = H / 2 - 70;
    const tx = Math.abs(Math.cos(a)) > 0.001 ? Math.abs(rx / Math.cos(a)) : Infinity;
    const ty = Math.abs(Math.sin(a)) > 0.001 ? Math.abs(ry / Math.sin(a)) : Infinity;
    const t = Math.min(tx, ty);
    arrow.setPosition(cx + Math.cos(a) * t, cy + Math.sin(a) * t)
      .setRotation(a).setVisible(true);
  }

  // 构筑栏：武器/被动图标随升级自动刷新
  updateBuildStrip(gs) {
    const sig = gs.weapons.map(w => w.id + ':' + w.level + (w.evolved ? 'E' : '')).join(',') +
      '|' + Object.entries(gs.player.passiveLevels).map(([k, v]) => k + v).join(',');
    if (sig === this._buildSig) return;
    this._buildSig = sig;
    if (this.strip) this.strip.destroy();
    this.strip = this.add.container(0, 0).setDepth(20);
    let x = 62;
    gs.weapons.forEach(w => {
      const icon = this.add.image(x, 84, w.def.icon).setDisplaySize(24, 24);
      if (w.evolved) icon.setTint(0xd46c99);
      const lv = this.add.text(x + 10, 94, String(w.level), {
        fontFamily: FONT, fontSize: '10px', color: '#ffcd75'
      }).setOrigin(0.5);
      this.strip.add([icon, lv]);
      x += 28;
    });
    x = 62;
    Object.entries(gs.player.passiveLevels).forEach(([id, lv]) => {
      const icon = this.add.image(x, 112, 'icon-passive-' + id).setDisplaySize(22, 22);
      const badge = this.add.text(x + 9, 122, String(lv), {
        fontFamily: FONT, fontSize: '10px', color: '#41a6f6'
      }).setOrigin(0.5);
      this.strip.add([icon, badge]);
      x += 26;
    });
  }

  drawJoystick(gs) {
    this.joyGfx.clear();
    const js = gs.joystick;
    if (!js || !js.active || gs.gameOver || this.levelUpVisible) return;
    this.joyGfx.lineStyle(2, 0x94b0c2, 0.4);
    this.joyGfx.strokeCircle(js.ox, js.oy, 60);
    this.joyGfx.fillStyle(0x94b0c2, 0.35);
    this.joyGfx.fillCircle(js.ox + js.dx, js.oy + js.dy, 26);
  }

  // ---------- 升级三选一 ----------

  showLevelUp(options) {
    this.hideLevelUp();
    this.levelUpVisible = true;
    this.levelUpOptions = options;
    this.levelUpContainer = this.add.container(0, 0).setDepth(100);

    const container = this.levelUpContainer;
    const dim = this.add.rectangle(W / 2, H / 2, W, H, 0x000000, 0.7);
    container.add(dim);
    container.add(this.add.text(W / 2, 120, '升 级 ！选 择 一 项', {
      fontFamily: FONT, fontSize: '42px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(0.5));
    container.add(this.add.text(W / 2, 168, '点击卡片 · 或按 1 / 2 / 3 键选择', {
      fontFamily: FONT, fontSize: '14px', color: '#94b0c2'
    }).setOrigin(0.5));

    const n = options.length;
    const gap = n > 2 ? 360 : (n === 2 ? 340 : 0);
    const firstX = W / 2 - (n - 1) * gap / 2;

    options.forEach((opt, i) => {
      const cx = firstX + i * gap;
      const card = this.add.container(cx, H / 2 + 70);
      const border = opt.kind === 'curse' ? 0xb13e53 : (opt.kind === 'evolve' ? 0xd46c99 : (opt.isNew ? 0x41a6f6 : 0xffcd75));
      const bg = this.add.rectangle(0, 0, 320, 250, 0x20222f).setStrokeStyle(3, border);
      const icon = this.add.image(0, -78, opt.icon || 'icon-passive-heart').setDisplaySize(56, 56);
      const titlePrefix = opt.kind === 'curse' ? '☠ ' : (opt.kind === 'evolve' ? '✦ ' : (opt.isNew ? '★ ' : ''));
      const titleColor = opt.kind === 'curse' ? '#ff6b6b' : (opt.kind === 'evolve' ? '#d46c99' : (opt.isNew ? '#41a6f6' : '#ffcd75'));
      const title = this.add.text(0, -14, titlePrefix + opt.name, {
        fontFamily: FONT, fontSize: '30px', color: titleColor, fontStyle: 'bold'
      }).setOrigin(0.5);
      const desc = this.add.text(0, 48, opt.desc, {
        fontFamily: FONT, fontSize: '18px', color: '#f4f4f4',
        wordWrap: { width: 260 },
        align: 'center', lineSpacing: 4
      }).setOrigin(0.5);
      desc.setWordWrapWidth(260, true); // 中文按字符断行（config 的 useAdvanced 在部分版本不生效）
      const keyHint = this.add.text(0, 100, `[ 按 ${i + 1} ]`, {
        fontFamily: FONT, fontSize: '14px', color: '#565a73', fontStyle: 'bold'
      }).setOrigin(0.5);
      card.add([bg, icon, title, desc, keyHint]);
      bg.setInteractive({ useHandCursor: true }).on('pointerdown', () => this.pickLevelUpOption(i));
      container.add(card);
    });

    // 重掷按钮：花费局内金币刷新选项
    const gs = this.gameScene;
    const cost = gs.rerollCost();
    const rerollBtn = this.add.container(W / 2, H / 2 + 235);
    const rbg = this.add.rectangle(0, 0, 230, 44, 0x20222f)
      .setStrokeStyle(2, gs.coins >= cost ? 0x94b0c2 : 0x4a4d63);
    const rtext = this.add.text(0, 0, `↻ 重掷（${cost} 金币）`, {
      fontFamily: FONT, fontSize: '19px', color: gs.coins >= cost ? '#f4f4f4' : '#565a73'
    }).setOrigin(0.5);
    rerollBtn.add([rbg, rtext]);
    rbg.setInteractive({ useHandCursor: true }).on('pointerdown', () => {
      if (!this.levelUpVisible) return;
      if (!gs.rerollLevelUps()) {
        this.tweens.add({ targets: rerollBtn, x: W / 2 - 10, duration: 50, yoyo: true, repeat: 3 });
      }
    });
    container.add(rerollBtn);
  }

  hideLevelUp() {
    this.levelUpVisible = false;
    this.levelUpOptions = null;
    if (this.levelUpContainer) {
      this.levelUpContainer.destroy();
      this.levelUpContainer = null;
    }
  }

  // 无尽模式：Boss 来袭横幅
  flashBoss(name) {
    if (this.gameOverVisible) return;
    const t = this.add.text(W / 2, 150, `⚠ ${name} 来袭！`, {
      fontFamily: FONT, fontSize: '40px', color: '#ff6b6b', fontStyle: 'bold',
      stroke: '#000000', strokeThickness: 6
    }).setOrigin(0.5).setDepth(120);
    this.tweens.add({ targets: t, alpha: 0, delay: 1800, duration: 700, onComplete: () => t.destroy() });
  }

  // 通用提示（成就解锁 / 金币奖励等）：屏幕上方弹出，最多同屏 4 条，超出顶掉最旧一条
  toast(msg) {
    if (!this._toasts) this._toasts = [];
    while (this._toasts.length >= 4) {
      const oldest = this._toasts.shift();
      if (oldest && oldest.active) oldest.destroy();
    }
    this.reflowToasts();
    const y = 120 + this._toasts.length * 46;
    const t = this.add.text(W / 2, y, msg, {
      fontFamily: FONT, fontSize: '22px', color: '#ffcd75', fontStyle: 'bold',
      stroke: '#000000', strokeThickness: 5,
      backgroundColor: 'rgba(13,14,26,0.75)', padding: { x: 14, y: 6 }
    }).setOrigin(0.5).setDepth(130);
    this._toasts.push(t);
    this.tweens.add({ targets: t, alpha: 0, delay: 2200, duration: 600, onComplete: () => { t.destroy(); this.reflowToasts(); } });
  }

  reflowToasts() {
    if (!this._toasts) return;
    this._toasts = this._toasts.filter(t => t && t.active);
    this._toasts.forEach((t, i) => { t.y = 120 + i * 46; });
  }

  // ---------- 结算（死亡 / 放弃 / 通关） ----------

  showGameOver(victory, elapsed, kills, forfeit) {
    this.gameOverVisible = true;
    const gs = this.gameScene;
    const m = Math.floor(elapsed / 60), s = Math.floor(elapsed % 60);

    this.gameOverContainer = this.add.container(0, 0).setDepth(100);
    const c = this.gameOverContainer;
    c.add(this.add.rectangle(W / 2, H / 2, W, H, 0x000000, 0.75));

    if (victory) {
      c.add(this.add.text(W / 2, H / 2 - 150, gs.isBrotato ? '进 化 登 顶 ！' : '通 关 ！', {
        fontFamily: FONT, fontSize: '60px', color: '#ffcd75', fontStyle: 'bold'
      }).setOrigin(0.5));
      c.add(this.add.text(W / 2, H / 2 - 75,
        gs.isBrotato ? '成功突破 20 波竞技场极限，成为终极幸存者！' : `${gs.levelConfig.name} 完成，深渊暂获安宁`, {
        fontFamily: FONT, fontSize: '24px', color: '#38b764'
      }).setOrigin(0.5));
    } else {
      c.add(this.add.text(W / 2, H / 2 - 150, forfeit ? '本 局 结 束' : '你 倒 下 了', {
        fontFamily: FONT, fontSize: '54px', color: forfeit ? '#94b0c2' : '#b13e53', fontStyle: 'bold'
      }).setOrigin(0.5));
      if (gs.isBrotato) {
        c.add(this.add.text(W / 2, H / 2 - 80, `止步于第 ${gs.brotoWave} 波 / 20 波`, {
          fontFamily: FONT, fontSize: '22px', color: '#ff6b6b'
        }).setOrigin(0.5));
      }
    }
    const diffStr = (gs.diffConfig && gs.diffConfig.badge) ? `　·　难度 ${gs.difficulty}（${gs.diffConfig.badge}）` : '';
    c.add(this.add.text(W / 2, H / 2 - 5,
      `本次生存 ${m} 分 ${s} 秒　·　击杀 ${kills}${diffStr}`,
      { fontFamily: FONT, fontSize: '24px', color: '#f4f4f4' }).setOrigin(0.5));
    if (gs.isBrotato) {
      const earned = (gs.brotatoGoldEarned !== undefined) ? gs.brotatoGoldEarned : (kills || 0);
      const cap = (gs.brotatoGoldCap !== undefined) ? gs.brotatoGoldCap : (150 + (gs.brotoWave || 1) * 20);
      c.add(this.add.text(W / 2, H / 2 + 42,
        `带出金币 +${earned}（击杀 ${kills} 怪 · 波次上限 ${cap} · 局内金币不带回）`,
        { fontFamily: FONT, fontSize: '19px', color: '#ffcd75', fontStyle: 'bold' }).setOrigin(0.5));
    } else {
      const bonusStr = (gs.diffConfig && gs.diffConfig.goldMul > 1) ? `（含难度加成 +${Math.round((gs.diffConfig.goldMul - 1) * 100)}%）` : '';
      c.add(this.add.text(W / 2, H / 2 + 42,
        `金币 +${gs.coins}${bonusStr}（已存入商店）`,
        { fontFamily: FONT, fontSize: '20px', color: '#ffcd75' }).setOrigin(0.5));
    }

    // 按钮：再来一局 / 下一关（通关且有关） / 返回主菜单
    const btnRow = (x, y, label, cb, color) => {
      const bg = this.add.rectangle(x, y, 240, 54, 0x20222f).setStrokeStyle(3, color);
      const t = this.add.text(x, y, label, { fontFamily: FONT, fontSize: '22px', color }).setOrigin(0.5);
      bg.setInteractive({ useHandCursor: true }).on('pointerdown', cb);
      c.add([bg, t]);
    };

    if (gs.isBrotato) {
      btnRow(W / 2 - 140, H / 2 + 105, '↻ 再来一局', () => this.restart(), '#d46c99');
      btnRow(W / 2 + 140, H / 2 + 105, '⌂ 主菜单', () => this.toMenu(), '#94b0c2');
    } else {
      btnRow(W / 2 - 280, H / 2 + 100, '↻ 再来一局', () => this.restart(), '#41a6f6');
      const nextLv = victory ? this.nextMainLevel(gs.levelId) : null;
      if (nextLv) {
        btnRow(W / 2, H / 2 + 100, '→ 下一关', () => this.nextLevel(), '#38b764');
        btnRow(W / 2 + 280, H / 2 + 100, '⌂ 主菜单', () => this.toMenu(), '#94b0c2');
      } else {
        btnRow(W / 2 + 140, H / 2 + 100, '⌂ 主菜单', () => this.toMenu(), '#94b0c2');
      }
    }
  }

  // 主线下一关：跳过趣味关与无尽模式（它们从关卡选择进入）
  nextMainLevel(curId) {
    const main = getData(this, 'levels').levels.filter(l => !l.fun && !l.endless).map(l => l.id);
    const idx = main.indexOf(curId);
    return (idx >= 0 && idx < main.length - 1) ? main[idx + 1] : null;
  }

  restart() {
    if (!this.gameOverVisible) return;
    this.gameOverVisible = false;
    if (this.gameOverContainer) { this.gameOverContainer.destroy(); this.gameOverContainer = null; }
    this.scene.stop();
    const gs = this.gameScene;
    const diff = (gs && gs.difficulty) || 1;
    if (gs && gs.isBrotato) {
      this.scene.get('GameScene').scene.restart({ mode: 'brotato', wave: 1, difficulty: diff });
    } else {
      const curLevel = (gs && gs.levelId) || this.registry.get('level') || 1;
      this.scene.get('GameScene').scene.restart({ level: curLevel, difficulty: diff });
    }
  }

  nextLevel() {
    if (!this.gameOverVisible) return;
    const gs = this.gameScene;
    const curLevel = (gs && gs.levelId) || this.registry.get('level') || 1;
    const diff = (gs && gs.difficulty) || 1;
    const next = this.nextMainLevel(curLevel);
    if (!next) return;
    this.registry.set('level', next);
    this.gameOverVisible = false;
    if (this.gameOverContainer) { this.gameOverContainer.destroy(); this.gameOverContainer = null; }
    this.scene.stop();
    this.scene.get('GameScene').scene.restart({ level: next, difficulty: diff });
  }
}
