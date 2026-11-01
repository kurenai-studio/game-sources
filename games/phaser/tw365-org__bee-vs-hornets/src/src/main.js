import { GAME_CONFIG } from './config.js';
import { BootScene } from './scenes/BootScene.js';
import { MenuScene } from './scenes/MenuScene.js';
import { GameScene } from './scenes/GameScene.js';
import { GameOverScene } from './scenes/GameOverScene.js';

const phaserConfig = {
  type: Phaser.AUTO,
  width: GAME_CONFIG.WIDTH,
  height: GAME_CONFIG.HEIGHT,
  parent: GAME_CONFIG.PARENT,
  pixelArt: true, // 啟用像素銳利渲染，關閉雙線性過濾
  backgroundColor: '#0a0a10',
  input: {
    gamepad: true
  },
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { y: 0 },
      debug: false
    }
  },
  scene: [BootScene, MenuScene, GameScene, GameOverScene]
};

// 明確載入 Web Fonts 並提供 3 秒逾時保護，防止以 fallback 字型繪製被快取 (T12)
window.addEventListener('DOMContentLoaded', async () => {
  if (document.fonts && document.fonts.load) {
    try {
      await Promise.race([
        Promise.all([
          document.fonts.load('700 11px "Noto Sans TC"'),
          document.fonts.load('10px "Press Start 2P"')
        ]),
        new Promise(resolve => setTimeout(resolve, 3000))
      ]);
    } catch (e) {
      console.warn('Font loading failed or timed out, continuing with fallback:', e);
    }
  }
  new Phaser.Game(phaserConfig);
});
