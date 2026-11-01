import Phaser from 'phaser';
import { Player } from '../entities/Player';
import {
  PowerUpStateMachine,
  PowerUpState,
  PowerUpStateMachineCallbacks,
} from './PowerUpStateMachine';

export type { PowerUpState };

/**
 * PowerUpController — wraps PowerUpStateMachine, exposes stable public API.
 */
export class PowerUpController {
  private sm: PowerUpStateMachine;

  // Public mirrors for backward compatibility
  get powerUp(): Phaser.Physics.Arcade.Sprite | null { return this.sm.powerUp; }
  get powerUpActive(): boolean { return this.sm.isActive(); }
  public powerUpBullets: Phaser.Physics.Arcade.Group | null = null;

  constructor(scene: Phaser.Scene, player: Player) {
    const callbacks: PowerUpStateMachineCallbacks = {
      onSpawn: () => {},
      onCollect: () => { this.powerUpBullets = player.bullets; },
      onDeactivate: () => { this.powerUpBullets = null; },
    };
    this.sm = new PowerUpStateMachine(scene, player, callbacks);
  }

  create(): void {}

  update(time: number, delta: number, elapsed: number): 'deactivated' | 'none' {
    return this.sm.update(time, delta, elapsed);
  }

  onCollected(): void {
    this.sm.onCollected();
  }

  /** Force deactivate (e.g., for testing or special events). */
  deactivate(): void {
    this.sm.forceDeactivate();
  }

  getRemainingRatio(): number { return this.sm.getRemainingRatio(); }
  getRemainingTime(): number { return this.sm.getRemainingTime(); }

  get state(): PowerUpState { return this.sm.state; }
}
