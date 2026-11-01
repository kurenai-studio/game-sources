import Phaser from 'phaser';
import { GAME_HEIGHT, GAME_WIDTH } from '@/game/config';

export class MenuScene extends Phaser.Scene {
  private ember!: Phaser.GameObjects.Arc;

  constructor() {
    super('MenuScene');
  }

  create(): void {
    this.cameras.main.setBackgroundColor('#08070a');
    this.cameras.main.setBounds(0, 0, GAME_WIDTH, GAME_HEIGHT);
    this.syncViewport();
    const graphics = this.add.graphics();
    graphics.fillStyle(0x100d12).fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
    graphics.lineStyle(2, 0x2c242b, 0.6);
    for (let ring = 0; ring < 8; ring += 1) {
      graphics.strokeEllipse(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 20, 170 + ring * 74, 110 + ring * 44);
    }
    graphics.lineStyle(1, 0x6d4a43, 0.18);
    for (let ray = 0; ray < 22; ray += 1) {
      const angle = (Math.PI * 2 * ray) / 22;
      graphics.lineBetween(
        GAME_WIDTH / 2 + Math.cos(angle) * 90,
        GAME_HEIGHT / 2 + 20 + Math.sin(angle) * 58,
        GAME_WIDTH / 2 + Math.cos(angle) * 540,
        GAME_HEIGHT / 2 + 20 + Math.sin(angle) * 340,
      );
    }
    graphics.fillStyle(0x050406, 0.82).fillEllipse(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 26, 280, 175);
    graphics.lineStyle(4, 0x5e4a4c, 0.34).strokeEllipse(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 26, 285, 180);

    this.ember = this.add.circle(GAME_WIDTH / 2, GAME_HEIGHT / 2 - 64, 7, 0xd99355, 0.85);
    this.ember.setBlendMode(Phaser.BlendModes.ADD);
    this.tweens.add({
      targets: this.ember,
      scale: { from: 0.7, to: 1.5 },
      alpha: { from: 0.4, to: 0.95 },
      duration: 1_500,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.InOut',
    });

    const emitter = this.add.particles(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 90, 'ash-particle', {
      x: { min: -240, max: 240 },
      y: { min: -20, max: 30 },
      lifespan: { min: 2_800, max: 5_200 },
      speedY: { min: -28, max: -8 },
      speedX: { min: -8, max: 8 },
      scale: { start: 0.55, end: 0 },
      alpha: { start: 0.35, end: 0 },
      frequency: 190,
      quantity: 1,
      blendMode: Phaser.BlendModes.ADD,
    });
    emitter.setDepth(2);
  }

  syncViewport(): void {
    this.cameras.main.centerOn(GAME_WIDTH / 2, GAME_HEIGHT / 2);
  }
}
