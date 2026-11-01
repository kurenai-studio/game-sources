import { COLLISION_TOLERANCE } from '../config/game-constants';
import { Player } from '../entities/player';
import type { PooledObstacle } from './obstacle-pool';

/**
 * Checks player collisions against active obstacles.
 */
export class CollisionDetector {
  /**
   * Returns true when an obstacle should end the run.
   */
  hasCollision(player: Player, obstacles: PooledObstacle[]): boolean {
    for (const pooledObstacle of obstacles) {
      const obstacle = pooledObstacle.obstacle;

      if (
        obstacle.getLane() !== player.getCurrentLane() ||
        Math.abs(obstacle.getZPosition()) > 0.8 + COLLISION_TOLERANCE
      ) {
        continue;
      }

      if (obstacle.requiresJump() && player.getVerticalPosition() > 1.25) {
        continue;
      }

      if (obstacle.requiresDuck() && player.getIsDucking()) {
        continue;
      }

      if (obstacle.requiresLaneChange()) {
        return true;
      }

      return true;
    }

    return false;
  }
}
