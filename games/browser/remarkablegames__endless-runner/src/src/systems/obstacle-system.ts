import type { PooledObstacle } from './obstacle-pool';
import { ObstacleSpawner } from './obstacle-spawner';

/**
 * Moves active obstacles through the world.
 */
export class ObstacleSystem {
  private readonly obstacleSpawner: ObstacleSpawner;

  constructor(obstacleSpawner: ObstacleSpawner) {
    this.obstacleSpawner = obstacleSpawner;
  }

  /**
   * Spawn, move, and sync active obstacles.
   */
  update(
    deltaTime: number,
    speed: number,
    density: number,
    runDuration: number,
  ) {
    this.obstacleSpawner.update(deltaTime, speed, density, runDuration);

    for (const pooledObstacle of this.obstacleSpawner.getActiveObstacles()) {
      pooledObstacle.obstacle.moveForward(speed * deltaTime);
      pooledObstacle.visual.sync();
    }
  }

  /**
   * Expose active obstacles for collision checks.
   */
  getActiveObstacles(): PooledObstacle[] {
    return this.obstacleSpawner.getActiveObstacles();
  }

  /**
   * Reset all obstacle state.
   */
  reset() {
    this.obstacleSpawner.reset();
  }
}
