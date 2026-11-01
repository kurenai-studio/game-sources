export class HUD {
  constructor(scene) {
    this.scene = scene;
    this.fontFamily = '"Press Start 2P", monospace, sans-serif';
    this.createElements();
  }

  createElements() {
    // 頂部常駐：分數與武器
    this.scoreText = this.scene.add.text(16, 12, 'SCORE: 0', {
      fontFamily: this.fontFamily,
      fontSize: '11px',
      color: '#ffffff'
    }).setScrollFactor(0).setDepth(200);

    this.weaponText = this.scene.add.text(16, 28, 'WEAPON: LV.0 雙連發蜂針', {
      fontFamily: this.fontFamily,
      fontSize: '9px',
      color: '#00ffff'
    }).setScrollFactor(0).setDepth(200);

    // 底部血條與炸彈
    this.hpLabel = this.scene.add.text(16, 614, 'HP', {
      fontFamily: this.fontFamily,
      fontSize: '9px',
      color: '#ffdd00'
    }).setScrollFactor(0).setDepth(200);

    // 血條背景框
    this.hpBarBg = this.scene.add.rectangle(100, 618, 120, 10, 0x222222).setOrigin(0, 0.5).setDepth(200);
    this.hpBar = this.scene.add.rectangle(100, 618, 120, 10, 0x00ff88).setOrigin(0, 0.5).setDepth(201);

    // 炸彈儲備
    this.bombText = this.scene.add.text(320, 614, 'BOMB: [X][X]', {
      fontFamily: this.fontFamily,
      fontSize: '9px',
      color: '#ff0077'
    }).setScrollFactor(0).setDepth(200);

    // 升級橫幅 (初始隱藏)
    this.banner = this.scene.add.text(240, 260, '', {
      fontFamily: this.fontFamily,
      fontSize: '14px',
      color: '#ffea00',
      align: 'center',
      stroke: '#000',
      strokeThickness: 4
    }).setOrigin(0.5).setScrollFactor(0).setDepth(250).setAlpha(0);

    // Boss 血量條 (緊湊並列於右上方，避免遮擋左側 SCORE / WEAPON)
    this.bossLabel = this.scene.add.text(464, 12, 'WARNING: QUEEN', {
      fontFamily: this.fontFamily,
      fontSize: '8px',
      color: '#ff0055'
    }).setOrigin(1, 0).setDepth(202).setVisible(false);

    this.bossHpBg = this.scene.add.rectangle(464, 28, 160, 8, 0x220011).setOrigin(1, 0.5).setDepth(200).setVisible(false);
    this.bossHpBar = this.scene.add.rectangle(304, 28, 160, 8, 0xff0055).setOrigin(0, 0.5).setDepth(201).setVisible(false);
  }

  updateScore(score) {
    this.scoreText.setText(`SCORE: ${score}`);
  }

  updateWeapon(weaponConfig) {
    this.weaponText.setText(`WEAPON: LV.${weaponConfig.id} ${weaponConfig.name}`);
    const colorHex = '#' + weaponConfig.color.toString(16).padStart(6, '0');
    this.weaponText.setColor(colorHex);
  }

  updateHp(current, max) {
    const ratio = Math.max(0, current / max);
    this.hpBar.width = 120 * ratio;
    if (ratio < 0.25) {
      this.hpBar.setFillStyle(0xff0044);
    } else if (ratio < 0.5) {
      this.hpBar.setFillStyle(0xffaa00);
    } else {
      this.hpBar.setFillStyle(0x00ff88);
    }
  }

  updateBombs(count) {
    const icons = Array(count).fill('[X]').join(' ');
    this.bombText.setText(`BOMB: ${icons || 'EMPTY'}`);
  }

  showUpgradeBanner(weaponConfig) {
    this.banner.setText(`★ WEAPON UPGRADE! ★\n\n[ ${weaponConfig.name} ]`);
    this.banner.setAlpha(1);
    this.banner.setScale(0.7);

    this.scene.tweens.add({
      targets: this.banner,
      scale: 1.1,
      duration: 250,
      yoyo: true,
      repeat: 3,
      onComplete: () => {
        this.scene.tweens.add({
          targets: this.banner,
          alpha: 0,
          y: 230,
          duration: 400,
          onComplete: () => {
            this.banner.y = 260;
          }
        });
      }
    });
  }

  showBossHp(show, current = 0, max = 1) {
    this.bossHpBg.setVisible(show);
    this.bossHpBar.setVisible(show);
    this.bossLabel.setVisible(show);

    if (show) {
      const ratio = Math.max(0, current / max);
      this.bossHpBar.width = 160 * ratio;
    }
  }
}
