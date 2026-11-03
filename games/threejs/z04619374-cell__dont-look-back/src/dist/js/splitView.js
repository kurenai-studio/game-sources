import * as THREE from 'three';

/** Adapted viewport/scissor technique from three.js webgl_multiple_views (MIT). */
export class SplitView {
  constructor(canvas, stage, world) {
    this.canvas = canvas; this.stage = stage; this.world = world;
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: 'high-performance' });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 1.75));
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.setScissorTest(true); this.width = 0; this.height = 0;
    this.divider = document.querySelector('#divider');
    this.labelB = document.querySelector('#b-label');
    this.reticle = document.querySelector('#reticle');
  }
  render(model) {
    const width = Math.max(1, Math.floor(this.stage.clientWidth));
    const height = Math.max(1, Math.floor(this.stage.clientHeight));
    if (width !== this.width || height !== this.height) {
      this.renderer.setSize(width, height, false); this.width = width; this.height = height;
    }
    const right = Math.floor(width * 0.5 * model.contact);
    const left = width - right;
    this.draw(this.world.cameraA, 0, left, height);
    if (right > 0) this.draw(this.world.cameraB, left, right, height);
    this.divider.style.left = `${left}px`;
    this.divider.hidden = right === 0;
    this.labelB.style.left = `${left + 27}px`;
    this.labelB.hidden = right < 110;
    this.reticle.style.left = `${left / 2}px`;
  }
  draw(camera, x, width, height) {
    camera.aspect = width / height; camera.updateProjectionMatrix();
    this.renderer.setViewport(x, 0, width, height);
    this.renderer.setScissor(x, 0, width, height);
    this.renderer.render(this.world.scene, camera);
  }
}
