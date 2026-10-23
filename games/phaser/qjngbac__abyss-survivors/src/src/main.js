import BootScene from './scenes/BootScene.js';
import MenuScene from './scenes/MenuScene.js';
import LevelSelectScene from './scenes/LevelSelectScene.js';
import GameScene from './scenes/GameScene.js';
import UIScene from './scenes/UIScene.js';
import ShopScene from './scenes/ShopScene.js';
import AchievementsScene from './scenes/AchievementsScene.js';
import CharacterScene from './scenes/CharacterScene.js';
import WaveShopOverlay from './scenes/WaveShopOverlay.js';
import meta from './meta.js';

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game',
  pixelArt: true,
  backgroundColor: '#1a1c2c',
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: 1280,
    height: 720
  },
  physics: { default: 'arcade', arcade: { debug: false } },
  scene: [BootScene, MenuScene, LevelSelectScene, GameScene, UIScene, ShopScene, AchievementsScene, CharacterScene, WaveShopOverlay]
});

// 调试钩子：浏览器控制台可直接访问游戏实例与局外进度（window.__game / window.__meta）
window.__game = game;
window.__meta = meta;
