import { StandardMaterial } from '@babylonjs/core/Materials/standardMaterial';
import { Color3 } from '@babylonjs/core/Maths/math.color';
import type { Mesh } from '@babylonjs/core/Meshes/mesh';
import { MeshBuilder } from '@babylonjs/core/Meshes/meshBuilder';
import { TransformNode } from '@babylonjs/core/Meshes/transformNode';
import type { Scene } from '@babylonjs/core/scene';

import { LANE_X_POSITIONS } from '../config/game-constants';
import { Player } from './player';

/**
 * Babylon.js representation of the player.
 */
export class PlayerVisual {
  private readonly player: Player;
  private readonly root: TransformNode;
  private readonly body: Mesh;
  private readonly material: StandardMaterial;

  constructor(player: Player, scene: Scene) {
    this.player = player;
    this.root = new TransformNode('playerRoot', scene);
    this.body = MeshBuilder.CreateBox(
      'playerBody',
      {
        width: 0.9,
        height: 1.8,
        depth: 0.9,
      },
      scene,
    );
    this.material = new StandardMaterial('playerMaterial', scene);
    this.material.diffuseColor = new Color3(0.16, 0.68, 0.95);
    this.body.material = this.material;
    this.body.parent = this.root;
    this.body.position.y = 0.9;
    this.syncImmediate();
  }

  /**
   * Update visual state to match the player entity.
   */
  update() {
    const laneX = this.player.getInterpolatedX(LANE_X_POSITIONS);
    const verticalPosition = this.player.getVerticalPosition();
    const duckScale = this.player.getIsDucking() ? 0.55 : 1;

    this.root.position.x = laneX;
    this.root.position.y = verticalPosition;
    this.body.scaling.y = duckScale;
    this.body.position.y = 0.9 * duckScale;
  }

  /**
   * Root node for positioning and camera framing.
   */
  getRoot(): TransformNode {
    return this.root;
  }

  /**
   * Collision mesh.
   */
  getMesh(): Mesh {
    return this.body;
  }

  /**
   * Reset to the default position after restart.
   */
  syncImmediate() {
    this.root.position.x = LANE_X_POSITIONS[this.player.getCurrentLane()];
    this.root.position.y = 0;
    this.root.position.z = 0;
    this.body.scaling.y = 1;
    this.body.position.y = 0.9;
  }

  /**
   * Dispose Babylon resources.
   */
  dispose() {
    this.material.dispose();
    this.body.dispose();
    this.root.dispose();
  }
}
