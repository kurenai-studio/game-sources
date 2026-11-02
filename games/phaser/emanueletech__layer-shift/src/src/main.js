import Phaser from 'phaser';
import { W, H, C } from './theme.js';
import { makeTextures } from './textures.js';
import TitleScene from './scenes/Title.js';
import GameScene from './scenes/Game.js';
import ResultsScene from './scenes/Results.js';

class BootScene extends Phaser.Scene {
  constructor() { super('boot'); }
  create() {
    makeTextures(this);
    // Wait for the bundled fonts so the first texts are not drawn with a fallback face.
    const ready = document.fonts ? Promise.race([document.fonts.ready, new Promise((r) => setTimeout(r, 1500))]) : Promise.resolve();
    ready.then(() => this.scene.start('title'));
  }
}

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game',
  width: W,
  height: H,
  backgroundColor: C.bg0,
  antialias: true,
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
  scene: [BootScene, TitleScene, GameScene, ResultsScene],
});
window.__game = game;
