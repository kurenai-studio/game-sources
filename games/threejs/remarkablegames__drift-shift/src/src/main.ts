import { createRenderer } from './renderer';
import { createScene } from './scene';

const { renderer } = createRenderer();
const { scene, camera, cube } = createScene();

renderer.setAnimationLoop(animate);

function animate(time: number) {
  cube.rotation.x = time / 2000;
  cube.rotation.y = time / 1000;
  renderer.render(scene, camera);
}

// hide spinner when loaded
document.getElementById('spinner')?.remove();

// pause when tab is hidden
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    renderer.setAnimationLoop(null);
  } else {
    renderer.setAnimationLoop(animate);
  }
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});
