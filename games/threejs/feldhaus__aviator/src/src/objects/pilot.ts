import {
  BoxGeometry,
  Matrix4,
  Mesh,
  MeshLambertMaterial,
  MeshPhongMaterial,
  Object3D,
} from 'three';
import { COLOR } from '../color';

export default class Pilot {
  public mesh: Object3D;
  private hairAngle: number;
  private hairTop: Object3D;

  constructor() {
    // create an empty container that will hold the different parts of the pilot
    this.mesh = new Object3D();

    // hairAngle is a property used to animate the hair later
    this.hairAngle = 0;

    this.createBody();
    this.createHead();
    this.createHair();
    this.createGlasses();
  }

  /**
   * Animate the hair.
   */
  public update() {
    // update them according to the angle
    this.hairTop.children.forEach((hair: Object3D, index) => {
      // eslint-disable-next-line no-param-reassign
      hair.scale.y = 0.75 + Math.cos(this.hairAngle + index / 3) * 0.25;
    });

    // increment the angle for the next frame
    this.hairAngle += 0.06;
  }

  /**
   * Create the body.
   */
  private createBody() {
    const bodyGeom = new BoxGeometry(15, 15, 15);
    const bodyMat = new MeshPhongMaterial({
      color: COLOR.brown,
      flatShading: true,
    });
    const body = new Mesh(bodyGeom, bodyMat);
    body.position.set(2, -12, 0);
    this.mesh.add(body);
  }

  /**
   * Create the head.
   */
  private createHead() {
    const faceGeom = new BoxGeometry(10, 10, 10);
    const faceMat = new MeshLambertMaterial({
      color: COLOR.pink,
    });
    const face = new Mesh(faceGeom, faceMat);
    this.mesh.add(face);

    const earGeom = new BoxGeometry(2, 3, 2);

    const earL = new Mesh(earGeom, faceMat);
    earL.position.set(0, 0, -6);
    this.mesh.add(earL);

    const earR = earL.clone();
    earR.position.set(0, 0, 6);
    this.mesh.add(earR);
  }

  /**
   * Create the hair.
   */
  private createHair() {
    const hairGeom = new BoxGeometry(4, 4, 4);
    const hairMat = new MeshLambertMaterial({
      color: COLOR.brown,
    });
    const hair = new Mesh(hairGeom, hairMat);

    // align the shape of the hair to its bottom boundary, that will make it easier to scale
    hair.geometry.applyMatrix4(new Matrix4().makeTranslation(0, 2, 0));

    // create a container for the hair
    const hairs = new Object3D();

    // create a container for the hairs at the top of the head (the ones that will be animated)
    this.hairTop = new Object3D();

    // create the hairs at the top of the head and position them on a 3 x 4 grid
    const startPosZ = -4;
    const startPosX = -4;
    for (let i = 0; i < 12; i++) {
      const col = i % 3;
      const row = Math.floor(i / 3);
      const clone = hair.clone();
      clone.position.set(startPosX + row * 4, 0, startPosZ + col * 4);
      this.hairTop.add(clone);
    }
    hairs.add(this.hairTop);

    // create the hairs at the side of the face
    const hairSideGeom = new BoxGeometry(12, 4, 2);
    hairSideGeom.applyMatrix4(new Matrix4().makeTranslation(-6, 0, 0));

    const hairSideR = new Mesh(hairSideGeom, hairMat);
    hairSideR.position.set(8, -2, 6);
    hairs.add(hairSideR);

    const hairSideL = hairSideR.clone();
    hairSideL.position.set(8, -2, -6);
    hairs.add(hairSideL);

    // create the hairs at the back of the head
    const hairBackGeom = new BoxGeometry(2, 8, 10);
    const hairBack = new Mesh(hairBackGeom, hairMat);
    hairBack.position.set(-1, -4, 0);
    hairs.add(hairBack);
    hairs.position.set(-5, 5, 0);

    this.mesh.add(hairs);
  }

  /**
   * Create the glasses.
   */
  private createGlasses() {
    const glassGeom = new BoxGeometry(5, 5, 5);
    const glassMat = new MeshLambertMaterial({
      color: COLOR.brown,
    });

    const glassR = new Mesh(glassGeom, glassMat);
    glassR.position.set(6, 0, 3);
    this.mesh.add(glassR);

    const glassL = glassR.clone();
    glassL.position.z = -glassR.position.z;
    this.mesh.add(glassL);

    const glassFrameGeom = new BoxGeometry(11, 1, 11);
    const glassFrame = new Mesh(glassFrameGeom, glassMat);
    this.mesh.add(glassFrame);
  }
}
