import { soundManager } from '../audio/SoundManager.js';

export class GameOverScene extends Phaser.Scene {
  constructor() {
    super('GameOverScene');
  }

  create(data) {
    const font = '"Press Start 2P", monospace, sans-serif';
    const finalScore = data.score || 0;
    const finalWave = data.wave || 1;

    // 評級判定
    let rank = 'C';
    let rankColor = '#aaaaaa';
    if (finalScore >= 10000) {
      rank = 'S';
      rankColor = '#ffd700';
    } else if (finalScore >= 5000) {
      rank = 'A';
      rankColor = '#00ffff';
    } else if (finalScore >= 2500) {
      rank = 'B';
      rankColor = '#33ff55';
    }

    // 標題
    this.add.text(240, 130, 'GAME OVER', {
      fontFamily: font,
      fontSize: '24px',
      color: '#ff0044',
      stroke: '#330011',
      strokeThickness: 5
    }).setOrigin(0.5);

    // 戰績結算
    this.add.text(240, 220, `FINAL SCORE`, {
      fontFamily: font,
      fontSize: '11px',
      color: '#8899aa'
    }).setOrigin(0.5);

    this.add.text(240, 255, `${finalScore}`, {
      fontFamily: font,
      fontSize: '22px',
      color: '#ffffff'
    }).setOrigin(0.5);

    this.add.text(240, 310, `WAVE REACHED: ${finalWave}`, {
      fontFamily: font,
      fontSize: '10px',
      color: '#ffcc00'
    }).setOrigin(0.5);

    // 評級徽章
    this.add.text(240, 380, `PILOT RANK`, {
      fontFamily: font,
      fontSize: '9px',
      color: '#8899aa'
    }).setOrigin(0.5);

    const rankText = this.add.text(240, 425, rank, {
      fontFamily: font,
      fontSize: '44px',
      color: rankColor,
      stroke: '#000',
      strokeThickness: 6
    }).setOrigin(0.5);

    this.tweens.add({
      targets: rankText,
      scale: 1.15,
      duration: 400,
      yoyo: true,
      repeat: -1
    });

    // 重新開始指示
    const restartText = this.add.text(240, 540, 'PRESS SPACE TO RETRY', {
      fontFamily: font,
      fontSize: '11px',
      color: '#ffff00'
    }).setOrigin(0.5);

    this.tweens.add({
      targets: restartText,
      alpha: 0.2,
      duration: 500,
      yoyo: true,
      repeat: -1
    });

    // 防止玩家戰鬥中狂按空白鍵導致瞬間略過結算畫面（設定 1.2 秒輸入緩衝冷卻）
    this.readyAt = this.time.now + 1200;

    const tryRestart = () => {
      if (this.time.now < this.readyAt) return;
      soundManager.playUpgrade();
      this.scene.start('GameScene');
    };

    this.input.keyboard.on('keydown-SPACE', tryRestart);
    this.input.on('pointerdown', tryRestart);

    // Gamepad 支援：按 A (button 0) 或 Start (button 9) 重新開始 (遵守 1.2 秒冷卻)
    this.input.gamepad?.on('down', (pad, button) => {
      if (button.index === 0 || button.index === 9) {
        tryRestart();
      }
    });
  }
}
