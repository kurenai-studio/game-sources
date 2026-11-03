import * as THREE from 'three';

export function createScene() {
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000,
  );

  const cube = new THREE.Mesh(
    new THREE.BoxGeometry(1, 1, 1),
    new THREE.MeshBasicMaterial({ color: 0x00ff00 }),
  );
  scene.add(cube);

  camera.position.z = 5;

  // development helpers
  if (import.meta.env.DEV) {
    scene.add(new THREE.AxesHelper(2));
    scene.add(new THREE.GridHelper(10, 10));
    scene.add(new THREE.CameraHelper(camera));
  }

  return { scene, camera, cube };
}
