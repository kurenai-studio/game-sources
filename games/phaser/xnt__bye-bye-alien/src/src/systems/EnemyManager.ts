import Phaser from 'phaser';
import { Alien } from '../entities/Alien';
import { ALIEN_SPAWN_INTERVAL, GAME_WIDTH, GAME_HEIGHT } from '../config/game';

export class EnemyManager {
  private scene: Phaser.Scene;
  public aliens: Alien[] = [];
  public alienBullets!: Phaser.Physics.Arcade.Group;
  private alienTimer = 0;

  constructor(scene: Phaser.Scene) {
    this.scene = scene;
  }

  create(): void {
    this.alienBullets = this.scene.physics.add.group({
      defaultKey: 'bullet_alien',
      maxSize: 60,
    });
  }

  /** Call each frame; handles spawning + updating + firing aliens. */
  update(time: number, delta: number): void {
    // Spawn logic
    this.alienTimer += delta;
    if (this.alienTimer >= ALIEN_SPAWN_INTERVAL) {
      this.alienTimer = 0;
      this.spawnAlien();
    }

    // Update + fire each alien
    for (let i = this.aliens.length - 1; i >= 0; i--) {
      const alien = this.aliens[i];
      if (!alien.active) {
        this.aliens.splice(i, 1);
        continue;
      }
      alien.update(time, delta);
      alien.fire(time, this.alienBullets);
    }
  }

  private spawnAlien(): void {
    const y = Phaser.Math.Between(40, GAME_HEIGHT - 40);
    const alien = new Alien(this.scene, GAME_WIDTH + 30, y);
    this.aliens.push(alien);
  }

  /** Remove a dead alien from the array (called after collision handling). */
  removeAlien(alien: Alien): void {
    const idx = this.aliens.indexOf(alien);
    if (idx >= 0) this.aliens.splice(idx, 1);
  }
}
