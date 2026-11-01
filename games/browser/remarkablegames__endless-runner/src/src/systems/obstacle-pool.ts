import type { Scene } from '@babylonjs/core/scene';

import { Obstacle } from '../entities/obstacle';
import { ObstacleVisual } from '../entities/obstacle-visual';
import type { LaneIndex } from '../types/input';
import type { ObstacleType } from '../types/obstacle';

interface PooledObstacle {
  obstacle: Obstacle;
  visual: ObstacleVisual;
}

/**
 * Reuses obstacle instances to avoid create/destroy churn during gameplay.
 */
export class ObstaclePool {
  private readonly scene: Scene;
  private readonly pooledObstacles: PooledObstacle[] = [];
  private obstacleCounter = 0;

  constructor(scene: Scene) {
    this.scene = scene;
  }

  /**
   * Acquire an active obstacle from the pool.
   */
  acquire(
    lane: LaneIndex,
    type: ObstacleType,
    zPosition: number,
  ): PooledObstacle {
    const available = this.pooledObstacles.find(
      ({ obstacle }) => !obstacle.getIsActive(),
    );

    if (available) {
      available.obstacle.reactivate(lane, type, zPosition);
      available.visual.sync();
      return available;
    }

    const obstacle = new Obstacle(
      `obstacle-${String(this.obstacleCounter++)}`,
      lane,
      type,
      zPosition,
    );
    const visual = new ObstacleVisual(obstacle, this.scene);
    const pooledObstacle = { obstacle, visual };
    this.pooledObstacles.push(pooledObstacle);
    return pooledObstacle;
  }

  /**
   * Release an obstacle back to the pool.
   */
  release(target: PooledObstacle) {
    target.obstacle.deactivate();
    target.visual.sync();
  }

  /**
   * Active obstacles currently in play.
   */
  getActive(): PooledObstacle[] {
    return this.pooledObstacles.filter(({ obstacle }) =>
      obstacle.getIsActive(),
    );
  }

  /**
   * Return all obstacles to the pool.
   */
  reset() {
    for (const pooledObstacle of this.pooledObstacles) {
      this.release(pooledObstacle);
    }
  }

  /**
   * Dispose Babylon resources.
   */
  dispose() {
    for (const pooledObstacle of this.pooledObstacles) {
      pooledObstacle.visual.dispose();
    }
  }
}

export type { PooledObstacle };
