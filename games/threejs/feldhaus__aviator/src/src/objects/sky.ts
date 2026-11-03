import { Object3D } from 'three';
import Cloud from './cloud';
import { HALF_PI, TAU } from '../utils/math';

export default class Sky {
  public mesh: Object3D;

  constructor() {
    // create an empty container that will hold the different parts of the sky
    this.mesh = new Object3D();

    // choose a number of clouds to be scattered in the sky
    const nClouds = 20;

    // distribute the clouds consistently (place them according to a uniform angle)
    const stepAngle = TAU / nClouds;

    // create the clouds
    for (let i = 0; i < nClouds; i++) {
      const cloud = new Cloud();

      // set the rotation and the position of each cloud
      const angle = stepAngle * i;
      const distance = 750 + Math.random() * 200;
      cloud.mesh.position.x = Math.cos(angle) * distance;
      cloud.mesh.position.y = Math.sin(angle) * distance;

      // rotate the cloud according to its position
      cloud.mesh.rotation.z = angle + HALF_PI;

      // position the clouds at random depths inside of the scene
      cloud.mesh.position.z = -400 - Math.random() * 400;

      // we also set a random scale for each cloud
      const scale = 1 + Math.random() * 2;
      cloud.mesh.scale.set(scale, scale, scale);

      // do not forget to add the mesh of each cloud in the scene
      this.mesh.add(cloud.mesh);
    }
  }

  public update(): void {
    this.mesh.rotation.z += 0.01;
  }
}
