import * as THREE from 'three';

const canvas = document.querySelector('canvas');

export function createRenderer() {
  if (!canvas) {
    throw new Error('Game canvas not found');
  }

  const renderer = new THREE.WebGLRenderer({ canvas });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setSize(window.innerWidth, window.innerHeight);

  return { renderer };
}
