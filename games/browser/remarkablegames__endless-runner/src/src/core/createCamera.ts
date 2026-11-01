import { ArcRotateCamera } from '@babylonjs/core/Cameras/arcRotateCamera';
import { Vector3 } from '@babylonjs/core/Maths/math.vector';
import type { Scene } from '@babylonjs/core/scene';

/**
 * Creates and configures the default ArcRotateCamera
 */
export function createCamera(scene: Scene): ArcRotateCamera {
  const camera = new ArcRotateCamera(
    'camera',
    -Math.PI / 2,
    Math.PI / 2.5,
    10,
    Vector3.Zero(),
    scene,
  );

  camera.attachControl();
  camera.inputs.attached.keyboard.detachControl();
  camera.panningSensibility = 0;
  camera.lowerRadiusLimit = 5;
  camera.upperBetaLimit = camera.beta;
  camera.upperRadiusLimit = 50;
  camera.lowerBetaLimit = camera.beta;
  camera.wheelPrecision = 50;

  return camera;
}
