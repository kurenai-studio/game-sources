import {
  BoxGeometry, Mesh, MeshPhongMaterial, Object3D,
} from 'three';
import { COLOR } from '../color';
import { TAU } from '../utils/math';

export default class Cloud {
  public mesh: Object3D;

  constructor() {
    // create an empty container that will hold the different parts of the cloud
    this.mesh = new Object3D();

    // create a cube geometry
    // this shape will be duplicated to create the cloud
    const geometry = new BoxGeometry(20, 20, 20);

    // create a material
    const material = new MeshPhongMaterial({
      color: COLOR.white,
    });

    // duplicate the geometry a random number of times
    const nCubes = 3 + Math.floor(Math.random() * 3);
    for (let i = 0; i < nCubes; i++) {
      // create the mesh by cloning the geometry
      const cube = new Mesh(geometry, material);

      // set the position and the rotation of each cube randomly
      cube.position.x = i * 15;
      cube.position.y = Math.random() * 10;
      cube.position.z = Math.random() * 10;
      cube.rotation.z = Math.random() * TAU;
      cube.rotation.y = Math.random() * TAU;

      // set the size of the cube randomly
      const scale = 0.1 + Math.random() * 0.9;
      cube.scale.set(scale, scale, scale);

      // allow each cube to cast and to receive shadows
      cube.castShadow = true;
      cube.receiveShadow = true;

      // add the cube to the container we first created
      this.mesh.add(cube);
    }
  }
}
