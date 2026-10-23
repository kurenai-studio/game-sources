import { TETRIS } from "../objects/TETRIS";

export default class PreloadScene extends Phaser.Scene {

  defaults: TETRIS;

  constructor() {
    super({ key: 'PreloadScene' });
    this.defaults = new TETRIS();
  }

  preload() {
    // this.load.image('phaser-logo', 'assets/img/phaser-logo.png');

    this.load.image('background', 'assets/img/background.png');
    // this.load.image('banner', 'assets/img/banner.png');

    this.load.spritesheet('block', 'assets/img/blocks.png', { frameWidth: this.defaults.BLOCK_WIDTH, frameHeight: this.defaults.BLOCK_WIDTH });
  }

  create() {
    this.scene.start('MainScene');
  }
}
