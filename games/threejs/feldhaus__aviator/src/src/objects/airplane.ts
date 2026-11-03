import {
  BoxGeometry, Mesh, MeshPhongMaterial, Object3D, Vector2,
} from 'three';
import { COLOR } from '../color';
import Pilot from './pilot';

export default class AirPlane {
  public mesh: Object3D;
  private propeller: Mesh;
  private pilot: Pilot;

  constructor() {
    // create an empty container that will hold the different parts of the airplane
    this.mesh = new Object3D();

    this.createCockipt();
    this.createEngine();
    this.createTail();
    this.createWing();
    this.createWindshield();
    this.createPropeller();

    this.pilot = new Pilot();
    this.pilot.mesh.position.set(-10, 27, 0);
    this.mesh.add(this.pilot.mesh);
  }

  /**
   * Move the airplane vertically, rotate it, and rotate the propeller.
   * @param target
   */
  public update(target: Vector2): void {
    // move the airplane at each frame by adding a fraction of the remaining distance
    this.mesh.position.y += (target.y - this.mesh.position.y) * 0.1;

    // rotate the airplane proportionally to the remaining distance
    this.mesh.rotation.z = (target.y - this.mesh.position.y) * 0.012;
    this.mesh.rotation.x = (this.mesh.position.y - target.y) * 0.006;

    this.propeller.rotation.x += 0.3;

    this.pilot.update();
  }

  /**
   * Create the cabin.
   */
  private createCockipt() {
    const geomCockpit = new BoxGeometry(60, 50, 50, 1, 1, 1);
    const vertices = geomCockpit.attributes.position;
    vertices.setY(4, vertices.getY(4) - 10);
    vertices.setZ(4, vertices.getZ(4) + 20);
    vertices.setY(5, vertices.getY(5) - 10);
    vertices.setZ(5, vertices.getZ(5) - 20);
    vertices.setY(6, vertices.getY(6) + 30);
    vertices.setZ(6, vertices.getZ(6) + 20);
    vertices.setZ(7, vertices.getZ(7) + 30);
    vertices.setZ(7, vertices.getZ(7) - 20);
    const matCockpit = new MeshPhongMaterial({
      color: COLOR.red,
      flatShading: true,
    });
    const cockpit = new Mesh(geomCockpit, matCockpit);
    cockpit.castShadow = true;
    cockpit.receiveShadow = true;
    this.mesh.add(cockpit);
  }

  /**
   * Create the engine.
   */
  private createEngine() {
    const geomEngine = new BoxGeometry(20, 50, 50, 1, 1, 1);
    const matEngine = new MeshPhongMaterial({
      color: COLOR.white,
      flatShading: true,
    });
    const engine = new Mesh(geomEngine, matEngine);
    engine.position.x = 40;
    engine.castShadow = true;
    engine.receiveShadow = true;
    this.mesh.add(engine);
  }

  /**
   * Create the tail.
   */
  private createTail() {
    const geomTail = new BoxGeometry(15, 20, 5, 1, 1, 1);
    const matTail = new MeshPhongMaterial({
      color: COLOR.red,
      flatShading: true,
    });
    const tailPlane = new Mesh(geomTail, matTail);
    tailPlane.position.set(-35, 25, 0);
    tailPlane.castShadow = true;
    tailPlane.receiveShadow = true;
    this.mesh.add(tailPlane);
  }

  /**
   * Create the wing.
   */
  private createWing() {
    const geomWing = new BoxGeometry(40, 8, 150, 1, 1, 1);
    const vertices = geomWing.attributes.position;
    vertices.setZ(0, 30);
    vertices.setZ(2, 30);
    vertices.setZ(1, -30);
    vertices.setZ(3, -30);
    const matWing = new MeshPhongMaterial({
      color: COLOR.red,
      flatShading: true,
    });
    const sideWing = new Mesh(geomWing, matWing);
    sideWing.castShadow = true;
    sideWing.receiveShadow = true;
    this.mesh.add(sideWing);
  }

  /**
   * Create the windshield.
   */
  private createWindshield() {
    const geometry = new BoxGeometry(3, 15, 20, 1, 1, 1);
    const material = new MeshPhongMaterial({
      color: COLOR.white,
      transparent: true,
      opacity: 0.3,
      flatShading: true,
    });
    const windshield = new Mesh(geometry, material);
    windshield.position.set(5, 27, 0);
    windshield.castShadow = true;
    windshield.receiveShadow = true;

    this.mesh.add(windshield);
  }

  /**
   * Create the propeller.
   */
  private createPropeller() {
    const geomPropeller = new BoxGeometry(20, 10, 10, 1, 1, 1);
    const matPropeller = new MeshPhongMaterial({
      color: COLOR.brown,
      flatShading: true,
    });
    this.propeller = new Mesh(geomPropeller, matPropeller);
    this.propeller.castShadow = true;
    this.propeller.receiveShadow = true;

    const geomBlade = new BoxGeometry(1, 100, 20, 1, 1, 1);
    const matBlade = new MeshPhongMaterial({
      color: COLOR.brownDark,
      flatShading: true,
    });

    const blade = new Mesh(geomBlade, matBlade);
    blade.position.set(8, 0, 0);
    blade.castShadow = true;
    blade.receiveShadow = true;
    this.propeller.add(blade);
    this.propeller.position.set(50, 0, 0);
    this.mesh.add(this.propeller);
  }
}
