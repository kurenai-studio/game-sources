import { TextureGenerator } from '../gfx/TextureGenerator.js';
import { soundManager } from '../audio/SoundManager.js';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('BootScene');
  }

  create() {
    // 1. 動態生成所有像素紋理
    TextureGenerator.generateAll(this);

    // 2. 進入標題選單 (選單按鍵時會自動初始化與解鎖 Web Audio)
    this.scene.start('MenuScene');
  }
}
