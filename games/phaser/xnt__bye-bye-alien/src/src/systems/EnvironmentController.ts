import Phaser from 'phaser';
import {
  GAME_WIDTH,
  GAME_HEIGHT,
  OBSTACLE_COUNT,
  OBSTACLE_MIN_SIZE,
  OBSTACLE_MAX_SIZE,
} from '../config/game';

export class EnvironmentController {
  private scene: Phaser.Scene;
  private stars: Phaser.GameObjects.Image[] = [];
  public obstacles!: Phaser.Physics.Arcade.StaticGroup;

  constructor(scene: Phaser.Scene) {
    this.scene = scene;
  }

  create(): void {
    this.createStarfield();
    this.createObstacles();
  }

  update(): void {
    this.updateStarfield();
  }

  private createStarfield(): void {
    this.stars = [];
    for (let i = 0; i < 80; i++) {
      const star = this.scene.add.image(
        Phaser.Math.Between(0, GAME_WIDTH),
        Phaser.Math.Between(0, GAME_HEIGHT),
        'star',
      );
      star.setAlpha(0.3 + Math.random() * 0.7);
      star.setDepth(0);
      (star as any)._speed = 0.5 + Math.random() * 1.5;
      this.stars.push(star);
    }
  }

  private updateStarfield(): void {
    for (const star of this.stars) {
      star.x -= (star as any)._speed;
      if (star.x < 0) {
        star.x = GAME_WIDTH;
        star.y = Phaser.Math.Between(0, GAME_HEIGHT);
      }
    }
  }

  private createObstacles(): void {
    this.obstacles = this.scene.physics.add.staticGroup();
    for (let i = 0; i < OBSTACLE_COUNT; i++) {
      const x = Phaser.Math.Between(40, GAME_WIDTH - 40);
      const y = Phaser.Math.Between(100, GAME_HEIGHT - 150);
      const obs = this.obstacles.create(x, y, 'obstacle') as Phaser.Physics.Arcade.Sprite;
      const scale =
        (OBSTACLE_MIN_SIZE + Math.random() * (OBSTACLE_MAX_SIZE - OBSTACLE_MIN_SIZE)) / 32;
      obs.setScale(scale).refreshBody();
      obs.setDepth(3);
      obs.setAlpha(0.85);
    }
  }
}
