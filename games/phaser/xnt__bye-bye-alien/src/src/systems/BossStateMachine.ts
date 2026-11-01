import Phaser from 'phaser';
import { Boss } from '../entities/Boss';
import {
  GAME_WIDTH,
  GAME_HEIGHT,
  BOSS_SPAWN_TIME,
} from '../config/game';

export type BossState = 'IDLE' | 'WARNING' | 'SPAWNED' | 'ACTIVE' | 'DEAD';

export interface BossStateMachineCallbacks {
  onWarning: () => void;
  onSpawn: () => void;
  onActive: () => void;
  onDead: () => void;
}

export class BossStateMachine {
  private scene: Phaser.Scene;
  private callbacks: BossStateMachineCallbacks;

  public state: BossState = 'IDLE';
  public boss: Boss | null = null;
  public bossBullets!: Phaser.Physics.Arcade.Group;
  public bossHpBar!: Phaser.GameObjects.Graphics;
  private bossWarningText: Phaser.GameObjects.Text | null = null;

  constructor(scene: Phaser.Scene, callbacks: BossStateMachineCallbacks) {
    this.scene = scene;
    this.callbacks = callbacks;
  }

  create(): void {
    this.bossBullets = this.scene.physics.add.group({
      defaultKey: 'bullet_boss',
      maxSize: 40,
    });
  }

  /** Call each frame. Returns true if boss is alive and should be updated. */
  update(time: number, delta: number, elapsed: number, playerPos: { x: number; y: number }): boolean {
    switch (this.state) {
      case 'IDLE':
        if (elapsed >= BOSS_SPAWN_TIME - 5000) {
          this.transitionTo('WARNING');
        }
        break;

      case 'WARNING':
        // Warning handled in transition; just wait for spawn time
        if (elapsed >= BOSS_SPAWN_TIME) {
          this.transitionTo('SPAWNED');
        }
        break;

      case 'SPAWNED':
        if (this.boss && this.boss.active) {
          this.boss.update(time, delta);
          // Check if boss has arrived (Boss entity manages its own arrived flag)
          if ((this.boss as any).arrived) {
            this.transitionTo('ACTIVE');
          }
        }
        break;

      case 'ACTIVE':
        if (this.boss && this.boss.active) {
          this.boss.update(time, delta);
          this.boss.fire(time, this.bossBullets, playerPos);
          this.updateBossHpBar();
          return true;
        } else {
          // Boss was destroyed externally (e.g., collision)
          this.transitionTo('DEAD');
        }
        break;

      case 'DEAD':
        // Terminal state; nothing more to do
        break;
    }
    return false;
  }

  private transitionTo(next: BossState): void {
    const prev = this.state;
    this.state = next;

    switch (next) {
      case 'WARNING':
        this.showBossWarning();
        this.callbacks.onWarning();
        break;

      case 'SPAWNED':
        this.spawnBoss();
        this.callbacks.onSpawn();
        break;

      case 'ACTIVE':
        this.callbacks.onActive();
        break;

      case 'DEAD':
        // Clean up
        if (this.bossHpBar) this.bossHpBar.destroy();
        this.callbacks.onDead();
        break;
    }
  }

  private showBossWarning(): void {
    this.bossWarningText = this.scene.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 - 40, '⚠ MOTHERSHIP INCOMING ⚠', {
        fontSize: '24px',
        color: '#ff4444',
        fontFamily: 'monospace',
      })
      .setOrigin(0.5)
      .setDepth(100);

    this.scene.tweens.add({
      targets: this.bossWarningText,
      alpha: 0,
      yoyo: true,
      repeat: 5,
      duration: 400,
      onComplete: () => {
        this.bossWarningText?.destroy();
        this.bossWarningText = null;
      },
    });
  }

  private spawnBoss(): void {
    this.boss = new Boss(this.scene, GAME_WIDTH + 60, GAME_HEIGHT / 2);
    this.bossHpBar = this.scene.add.graphics().setDepth(100);
  }

  private updateBossHpBar(): void {
    if (!this.boss || !this.bossHpBar) return;
    this.bossHpBar.clear();

    const barW = 200;
    const barH = 12;
    const x = (GAME_WIDTH - barW) / 2;
    const y = GAME_HEIGHT - 30;
    const ratio = Math.max(0, this.boss.hp / this.boss.maxHp);

    this.bossHpBar.fillStyle(0x333333);
    this.bossHpBar.fillRect(x, y, barW, barH);
    this.bossHpBar.fillStyle(ratio > 0.3 ? 0xff3333 : 0xff0000);
    this.bossHpBar.fillRect(x, y, barW * ratio, barH);
    this.bossHpBar.lineStyle(1, 0xffffff);
    this.bossHpBar.strokeRect(x, y, barW, barH);
  }

  /** Called when collision system reports boss killed. */
  onBossKilled(): void {
    console.log('[BossSM] onBossKilled called, state=', this.state);
    if (this.state === 'ACTIVE' || this.state === 'SPAWNED') {
      this.boss = null;
      this.transitionTo('DEAD');
      console.log('[BossSM] -> DEAD');
    } else {
      console.log('[BossSM] ignored (not ACTIVE/SPAWNED)');
    }
  }

  isActive(): boolean {
    return this.state === 'ACTIVE' && this.boss !== null && this.boss.active;
  }

  isAlive(): boolean {
    return this.boss !== null && this.boss.active;
  }
}
