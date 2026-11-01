import { soundManager } from '../audio/SoundManager.js';

export class MenuScene extends Phaser.Scene {
  constructor() {
    super('MenuScene');
  }

  create() {
    const font = '"Press Start 2P", monospace, sans-serif';

    // 背景隨機星點
    for (let i = 0; i < 40; i++) {
      const x = Phaser.Math.Between(0, 480);
      const y = Phaser.Math.Between(0, 640);
      const size = Phaser.Math.Between(1, 3);
      this.add.rectangle(x, y, size, size, 0xffffff, Math.random() * 0.7 + 0.3);
    }

    // 主標題
    this.add.text(240, 110, 'BEE VS HORNETS', {
      fontFamily: font,
      fontSize: '20px',
      color: '#ffcc00',
      stroke: '#ff0055',
      strokeThickness: 5
    }).setOrigin(0.5);

    this.add.text(240, 145, '小蜜蜂大戰虎頭蜂', {
      fontFamily: font,
      fontSize: '13px',
      color: '#00ffff'
    }).setOrigin(0.5);

    // 精靈展示
    this.add.sprite(240, 205, 'player_bee_1').setScale(2);
    this.add.sprite(170, 205, 'hornet_normal').setScale(1.8);
    this.add.sprite(310, 205, 'hornet_armored').setScale(1.8);

    // 重武器套件預覽面板
    const panelY = 270;
    this.add.text(240, panelY, '--- HEAVY WEAPON SYSTEM ---', {
      fontFamily: font,
      fontSize: '9px',
      color: '#8899aa'
    }).setOrigin(0.5);

    const weaponList = [
      { lv: 'LV.0', name: '雙連發蜂針', score: '起始配備', color: '#00ffff' },
      { lv: 'LV.1', name: '花蜜散彈針', score: '1,000 PTS', color: '#ffdd00' },
      { lv: 'LV.2', name: '蜂王追蹤微導彈', score: '2,500 PTS', color: '#33ff55' },
      { lv: 'LV.3', name: '重型等離子轟爆砲', score: '5,000 PTS', color: '#ff00ff' }
    ];

    const chFont = '"Noto Sans TC", "Press Start 2P", sans-serif';

    weaponList.forEach((w, idx) => {
      const y = panelY + 28 + idx * 24;
      this.add.text(80, y, `${w.lv} ${w.name}`, {
        fontFamily: chFont,
        fontSize: '11px',
        color: w.color
      });
      this.add.text(400, y, w.score, {
        fontFamily: font,
        fontSize: '9px',
        color: '#aaaaaa'
      }).setOrigin(1, 0);
    });

    // 操作指南
    const ctrlY = 410;
    this.add.text(240, ctrlY, '--- CONTROLS ---', {
      fontFamily: font,
      fontSize: '9px',
      color: '#8899aa'
    }).setOrigin(0.5);

    this.add.text(240, ctrlY + 24, '← → / A D / 搖桿 : 左右穿梭', { fontFamily: chFont, fontSize: '11px', color: '#ffffff' }).setOrigin(0.5);
    this.add.text(240, ctrlY + 44, '↑ ↓ / W S / 搖桿 : 微調身位', { fontFamily: chFont, fontSize: '11px', color: '#ffffff' }).setOrigin(0.5);
    this.add.text(240, ctrlY + 64, 'SPACE / 手把 A : 高速連射', { fontFamily: chFont, fontSize: '11px', color: '#00ffff' }).setOrigin(0.5);
    this.add.text(240, ctrlY + 84, 'X B / 手把 B X : 花粉全屏核爆', { fontFamily: chFont, fontSize: '11px', color: '#ff0077' }).setOrigin(0.5);

    // 開始提示 (呼吸燈閃爍)
    const startText = this.add.text(240, 560, 'PRESS SPACE TO START', {
      fontFamily: font,
      fontSize: '12px',
      color: '#ffff00',
      stroke: '#000',
      strokeThickness: 3
    }).setOrigin(0.5);

    this.tweens.add({
      targets: startText,
      alpha: 0.1,
      duration: 500,
      yoyo: true,
      repeat: -1
    });

    const startGame = () => {
      soundManager.init();
      soundManager.playUpgrade();
      this.scene.start('GameScene');
    };

    // 鍵盤監聽開始
    this.input.keyboard.on('keydown-SPACE', startGame);
    this.input.on('pointerdown', startGame);

    // Gamepad 支援：按 A (button 0) 或 Start (button 9) 開始
    this.input.gamepad?.on('down', (pad, button) => {
      if (button.index === 0 || button.index === 9) {
        startGame();
      }
    });
  }
}
