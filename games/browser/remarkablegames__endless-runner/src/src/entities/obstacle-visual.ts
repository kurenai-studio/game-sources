import { StandardMaterial } from '@babylonjs/core/Materials/standardMaterial';
import { Color3 } from '@babylonjs/core/Maths/math.color';
import type { Mesh } from '@babylonjs/core/Meshes/mesh';
import { MeshBuilder } from '@babylonjs/core/Meshes/meshBuilder';
import type { Scene } from '@babylonjs/core/scene';

import { LANE_X_POSITIONS } from '../config/game-constants';
import { Obstacle } from './obstacle';

/**
 * Babylon.js representation of an obstacle.
 */
export class ObstacleVisual {
  private readonly obstacle: Obstacle;
  private readonly mesh: Mesh;
  private readonly material: StandardMaterial;

  constructor(obstacle: Obstacle, scene: Scene) {
    this.obstacle = obstacle;
    this.mesh = MeshBuilder.CreateBox(
      `obstacle-${obstacle.getId()}`,
      {
        width: 1.1,
        height: 1.4,
        depth: 1.1,
      },
      scene,
    );
    this.material = new StandardMaterial(
      `obstacle-material-${obstacle.getId()}`,
      scene,
    );
    this.mesh.material = this.material;
    this.sync();
  }

  /**
   * Sync mesh transform and styling from obstacle state.
   */
  sync() {
    const obstacleType = this.obstacle.getType();

    this.mesh.position.x = LANE_X_POSITIONS[this.obstacle.getLane()];
    this.mesh.position.z = this.obstacle.getZPosition();
    this.mesh.isVisible = this.obstacle.getIsActive();

    if (obstacleType === 'GROUND') {
      this.mesh.scaling.set(1, 1, 1);
      this.mesh.position.y = 0.7;
      this.material.diffuseColor = new Color3(0.89, 0.33, 0.22);
      return;
    }

    if (obstacleType === 'AIRBORNE') {
      this.mesh.scaling.set(1, 0.7, 1);
      this.mesh.position.y = 2.2;
      this.material.diffuseColor = new Color3(0.98, 0.72, 0.12);
      return;
    }

    this.mesh.scaling.set(1, 1.6, 1);
    this.mesh.position.y = 1.1;
    this.material.diffuseColor = new Color3(0.55, 0.2, 0.82);
  }

  /**
   * Expose the render mesh for collisions.
   */
  getMesh(): Mesh {
    return this.mesh;
  }

  /**
   * Dispose resources.
   */
  dispose() {
    this.material.dispose();
    this.mesh.dispose();
  }
}
