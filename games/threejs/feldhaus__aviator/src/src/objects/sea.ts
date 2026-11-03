import {
  CylinderGeometry,
  Matrix4,
  Mesh,
  MeshPhongMaterial,
  Vector3,
} from 'three';
import { COLOR } from '../color';
import { HALF_PI, TAU } from '../utils/math';

const RADIAL_SEGMENTS = 40;
const HEIGHT_SEGMENTS = 10;

interface IWaveAnimationData {
  index: number;
  position: Vector3;
  angle: number;
  amplitude: number;
  speed: number;
}

export default class Sea {
  public mesh: Mesh;
  private waves: IWaveAnimationData[];

  constructor() {
    // create the geometry (shape) of the cylinder
    const geometry = new CylinderGeometry(
      600,
      600,
      800,
      RADIAL_SEGMENTS,
      HEIGHT_SEGMENTS,
      true,
    );

    // rotate the geometry on the x axis
    geometry.applyMatrix4(new Matrix4().makeRotationX(-HALF_PI));

    // create the material
    const material = new MeshPhongMaterial({
      color: COLOR.blue,
      transparent: true,
      opacity: 0.6,
      flatShading: true,
    });

    this.mesh = new Mesh(geometry, material);

    // allow the sea to receive shadows
    this.mesh.receiveShadow = true;

    this.defineWavesAnimationData();
  }

  public update(): void {
    this.moveWaves();
    this.mesh.rotation.z += 0.005;
  }

  /**
   * Store waves data to use in the animation.
   * @param geometry
   */
  private defineWavesAnimationData(): void {
    const vertices = this.mesh.geometry.attributes.position;
    this.waves = new Array(vertices.count);

    for (let i = 0; i < this.waves.length; i++) {
      const vertex = new Vector3(
        vertices.getX(i),
        vertices.getY(i),
        vertices.getZ(i),
      );
      this.waves[i] = {
        index: i,
        position: vertex.clone(),
        angle: Math.random() * TAU,
        amplitude: 5 + Math.random() * 15,
        speed: 0.016 + Math.random() * 0.032,
      };
    }
  }

  /**
   * Rotate each vertex of the cylinder around its initial position,
   * by giving it a speed rotation, and a distance (radius of the rotation).
   */
  private moveWaves(): void {
    let n = RADIAL_SEGMENTS;
    const vertices = this.mesh.geometry.attributes.position;
    this.waves.forEach((data: IWaveAnimationData) => {
      if (data.index === n) {
        // ensure the continuity of the waves
        n += RADIAL_SEGMENTS + 1;
        vertices.setXY(
          data.index,
          vertices.getX(data.index - RADIAL_SEGMENTS),
          vertices.getY(data.index - RADIAL_SEGMENTS),
        );
      } else {
        vertices.setXY(
          data.index,
          data.position.x + Math.cos(data.angle) * data.amplitude,
          data.position.y + Math.sin(data.angle) * data.amplitude,
        );
        // eslint-disable-next-line no-param-reassign
        data.angle += data.speed;
      }
    });

    // tell the renderer that the geometry of the sea has changed
    // three.js caches the geometries and ignores any changes
    vertices.needsUpdate = true;
  }
}
