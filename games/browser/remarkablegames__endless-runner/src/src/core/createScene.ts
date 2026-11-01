import '@babylonjs/core/Audio/audioSceneComponent';

import type { Engine } from '@babylonjs/core/Engines/engine';
import { DirectionalLight } from '@babylonjs/core/Lights/directionalLight';
import { HemisphericLight } from '@babylonjs/core/Lights/hemisphericLight';
import { StandardMaterial } from '@babylonjs/core/Materials/standardMaterial';
import { Color3, Color4 } from '@babylonjs/core/Maths/math.color';
import { Vector3 } from '@babylonjs/core/Maths/math.vector';
import { MeshBuilder } from '@babylonjs/core/Meshes/meshBuilder';
import { Scene } from '@babylonjs/core/scene';

import {
  LANE_X_POSITIONS,
  PLAYER_Z,
  TRACK_LENGTH,
  TRACK_WIDTH,
} from '../config/game-constants';
import { createCamera } from './createCamera';

/**
 * Creates the endless runner scene shell.
 */
export function createScene(engine: Engine): Scene {
  const scene = new Scene(engine);
  scene.clearColor = new Color4(0.04, 0.05, 0.08, 1);

  const camera = createCamera(scene);
  camera.setTarget(new Vector3(0, 1, PLAYER_Z));
  camera.radius = 18;
  camera.alpha = -Math.PI / 2;
  camera.beta = 1.05;
  scene.activeCamera = camera;

  const hemisphereLight = new HemisphericLight(
    'ambientLight',
    new Vector3(0, 1, 0),
    scene,
  );
  hemisphereLight.intensity = 0.75;

  const sunLight = new DirectionalLight(
    'sunLight',
    new Vector3(-0.35, -1, 0.55),
    scene,
  );
  sunLight.position = new Vector3(0, 14, -12);
  sunLight.intensity = 0.7;

  const trackMaterial = new StandardMaterial('trackMaterial', scene);
  trackMaterial.diffuseColor = new Color3(0.11, 0.13, 0.18);

  const laneLineMaterial = new StandardMaterial('laneLineMaterial', scene);
  laneLineMaterial.emissiveColor = new Color3(0.2, 0.95, 0.85);

  const ground = MeshBuilder.CreateGround(
    'track',
    { width: TRACK_WIDTH, height: TRACK_LENGTH },
    scene,
  );
  ground.position.z = -28;
  ground.material = trackMaterial;

  for (const laneX of Object.values(LANE_X_POSITIONS)) {
    const marker = MeshBuilder.CreateGround(
      `lane-marker-${String(laneX)}`,
      { width: 0.08, height: TRACK_LENGTH },
      scene,
    );
    marker.position.set(laneX, 0.01, -28);
    marker.material = laneLineMaterial;
  }

  return scene;
}
