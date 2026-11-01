import Phaser from 'phaser';
import { Boss } from '../entities/Boss';
import {
  BossStateMachine,
  BossState,
  BossStateMachineCallbacks,
} from './BossStateMachine';

export type { BossState };

/**
 * BossController — wraps BossStateMachine and exposes a stable public API
 * for collision wiring and GameScene.
 */
export class BossController {
  private sm: BossStateMachine;

  // Public mirrors of state machine for backward compatibility
  get boss(): Boss | null { return this.sm.boss; }
  get bossBullets(): Phaser.Physics.Arcade.Group { return this.sm.bossBullets; }

  constructor(scene: Phaser.Scene) {
    const callbacks: BossStateMachineCallbacks = {
      onWarning: () => {},
      onSpawn: () => {},
      onActive: () => {},
      onDead: () => {},
    };
    this.sm = new BossStateMachine(scene, callbacks);
  }

  create(): void {
    this.sm.create();
  }

  update(time: number, delta: number, elapsed: number, playerPos: { x: number; y: number }): void {
    this.sm.update(time, delta, elapsed, playerPos);
  }

  /** Called when collision system reports boss killed. */
  onBossKilled(): void {
    this.sm.onBossKilled();
  }

  /** Expose whether boss is active (alive and arrived). */
  isActive(): boolean {
    return this.sm.isActive();
  }

  /** Expose current state for debugging/inspection. */
  get state(): BossState {
    return this.sm.state;
  }
}
