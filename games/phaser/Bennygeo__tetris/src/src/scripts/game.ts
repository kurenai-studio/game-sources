import 'phaser';
import MainScene from './scenes/mainScene'
import PreloadScene from './scenes/preloadScene'

import * as configData from '../assets/JSON/config.json';
import { Block } from './objects/Block';
// import * as settings from './JSON/settings.json';

const DEFAULT_WIDTH = configData.stage.width;
const DEFAULT_HEIGHT = configData.stage.height;

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  backgroundColor: '#ffffff',

  scale: {
    parent: 'phaser-game',
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: DEFAULT_WIDTH,
    height: DEFAULT_HEIGHT
  },

  scene: [PreloadScene, MainScene],

  physics: {
    default: 'arcade',
    arcade: {
      debug: false,
      gravity: { y: 400 }
    }
  }
}


window.addEventListener('load', () => {
  const game = new Phaser.Game(config);
});
