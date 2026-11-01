import Phaser from 'phaser';
import { GAME_WIDTH } from '../config/game';

export class HudController {
  private scene: Phaser.Scene;
  private hpText!: Phaser.GameObjects.Text;
  private scoreText!: Phaser.GameObjects.Text;
  private timerText!: Phaser.GameObjects.Text;

  constructor(scene: Phaser.Scene) {
    this.scene = scene;
  }

  create(initialHp: number): void {
    const style: Phaser.Types.GameObjects.Text.TextStyle = {
      fontSize: '16px',
      color: '#ffffff',
      fontFamily: 'monospace',
    };

    this.hpText = this.scene.add.text(10, 10, `HP: ${initialHp}`, style).setDepth(100);
    this.scoreText = this.scene.add.text(10, 30, 'SCORE: 0', style).setDepth(100);
    this.timerText = this.scene.add
      .text(GAME_WIDTH - 10, 10, 'TIME: 0s', { ...style, align: 'right' })
      .setOrigin(1, 0)
      .setDepth(100);
  }

  update(hp: number, score: number, elapsedMs: number): void {
    this.hpText.setText(`HP: ${Math.max(0, hp)}`);
    this.scoreText.setText(`SCORE: ${score}`);
    const seconds = Math.floor(elapsedMs / 1000);
    this.timerText.setText(`TIME: ${seconds}s`);
  }
}
