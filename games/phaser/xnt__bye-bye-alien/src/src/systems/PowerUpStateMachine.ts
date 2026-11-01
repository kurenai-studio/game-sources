import Phaser from 'phaser';
import { Player } from '../entities/Player';
import { POWERUP_STATS } from '../config/ships';
import {
  GAME_WIDTH,
  GAME_HEIGHT,
  POWERUP_SPAWN_TIME,
  POWERUP_DURATION,
  POWERUP_SPEED,
} from '../config/game';

export type PowerUpState = 'NOTHING' | 'SPAWNED' | 'ACTIVE' | 'GONE';

export interface PowerUpStateMachineCallbacks {
  onSpawn: () => void;
  onCollect: () => void;
  onDeactivate: () => void;
}

export class PowerUpStateMachine {
  private scene: Phaser.Scene;
  private player: Player;
  private callbacks: PowerUpStateMachineCallbacks;

  public state: PowerUpState = 'NOTHING';
  public powerUp: Phaser.Physics.Arcade.Sprite | null = null;
  private powerUpRemaining = 0;
  private powerUpBar!: Phaser.GameObjects.Graphics;

  constructor(scene: Phaser.Scene, player: Player, callbacks: PowerUpStateMachineCallbacks) {
    this.scene = scene;
    this.player = player;
    this.callbacks = callbacks;
  }

  /** Call each frame. Returns 'deactivated' if just deactivated, else 'none'. */
  update(time: number, delta: number, elapsed: number): 'deactivated' | 'none' {
    switch (this.state) {
      case 'NOTHING':
        if (elapsed >= POWERUP_SPAWN_TIME) {
          this.transitionTo('SPAWNED');
        }
        break;

      case 'SPAWNED':
        // Despawn if drifted off-screen
        if (this.powerUp && this.powerUp.x < -40) {
          this.powerUp.destroy();
          this.powerUp = null;
          this.transitionTo('GONE');
        }
        break;

      case 'ACTIVE':
        this.powerUpRemaining -= delta;
        this.updatePowerUpBar();
        if (this.powerUpRemaining <= 0) {
          this.transitionTo('GONE');
          return 'deactivated';
        }
        break;

      case 'GONE':
        // Terminal for this instance
        break;
    }
    return 'none';
  }

  /** Called when player collides with power-up. */
  onCollected(): void {
    if (this.state === 'SPAWNED' && this.powerUp) {
      this.powerUp.destroy();
      this.powerUp = null;
      this.transitionTo('ACTIVE');
    }
  }

  private transitionTo(next: PowerUpState): void {
    this.state = next;

    switch (next) {
      case 'SPAWNED':
        this.spawnPowerUp();
        this.callbacks.onSpawn();
        break;

      case 'ACTIVE':
        this.activate();
        this.callbacks.onCollect();
        break;

      case 'GONE':
        this.deactivate();
        this.callbacks.onDeactivate();
        break;
    }
  }

  private spawnPowerUp(): void {
    const y = Phaser.Math.Between(60, GAME_HEIGHT - 60);
    this.powerUp = this.scene.physics.add.sprite(GAME_WIDTH + 20, y, 'powerup_pickup');
    this.powerUp.setVelocityX(-POWERUP_SPEED);
    this.powerUp.setDepth(8);

    this.scene.tweens.add({
      targets: this.powerUp,
      y: this.powerUp.y - 20,
      yoyo: true,
      repeat: -1,
      duration: 600,
      ease: 'Sine.easeInOut',
    });
  }

  private activate(): void {
    this.powerUpRemaining = POWERUP_DURATION;
    this.player.activatePowerUp(POWERUP_STATS);
    this.powerUpBar = this.scene.add.graphics().setDepth(100);
  }

  private deactivate(): void {
    this.powerUpRemaining = 0;
    this.player.deactivatePowerUp();
    if (this.powerUpBar) {
      this.powerUpBar.destroy();
    }
  }

  private updatePowerUpBar(): void {
    if (!this.powerUpBar) return;
    this.powerUpBar.clear();

    const barW = 120;
    const barH = 8;
    const x = GAME_WIDTH / 2 - barW / 2;
    const y = 10;
    const ratio = Math.max(0, this.powerUpRemaining / POWERUP_DURATION);

    this.powerUpBar.fillStyle(0x222233);
    this.powerUpBar.fillRect(x, y, barW, barH);
    this.powerUpBar.fillStyle(ratio > 0.3 ? 0x44ff88 : 0xffaa44);
    this.powerUpBar.fillRect(x, y, barW * ratio, barH);
    this.powerUpBar.lineStyle(1, 0x44eeff);
    this.powerUpBar.strokeRect(x, y, barW, barH);
  }

  /** Expose remaining time in ms. */
  getRemainingTime(): number {
    return this.powerUpRemaining;
  }

  getRemainingRatio(): number {
    return Math.max(0, this.powerUpRemaining / POWERUP_DURATION);
  }

  isActive(): boolean {
    return this.state === 'ACTIVE';
  }

  /** Force transition to GONE (for testing / special events). */
  forceDeactivate(): void {
    if (this.state === 'ACTIVE' || this.state === 'SPAWNED') {
      this.transitionTo('GONE');
    }
  }
}
