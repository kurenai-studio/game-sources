import * as THREE from 'three';
import { PointerLockControls } from '../vendor/PointerLockControls.js';

export class Input {
  constructor(model, canvas, camera, onPause, onLockError) {
    this.model = model; this.canvas = canvas; this.onPause = onPause;
    this.dragMode = false; this.sensitivity = 1;
    this.controls = new PointerLockControls(camera, canvas);
    this.controls.minPolarAngle = Math.PI/2 - model.config.pitchLimit;
    this.controls.maxPolarAngle = Math.PI/2 + model.config.pitchLimit;
    this.euler = new THREE.Euler(0,0,0,'YXZ');
    this.controls.addEventListener('change', () => {
      this.euler.setFromQuaternion(camera.quaternion, 'YXZ');
      const delta = Math.atan2(Math.sin(this.euler.y - model.yaw),Math.cos(this.euler.y - model.yaw));
      model.look(delta, this.euler.x - model.pitch);
    });
    this.controls.addEventListener('unlock', () => { if (!this.dragMode) onPause(); });
    document.addEventListener('pointerlockerror', () => { this.dragMode = true; onPause(); onLockError(); });
    document.addEventListener('keydown', event => {
      if (event.code === 'KeyA' && model.status === 'playing' && !event.repeat) { event.preventDefault(); model.setGuard(true); }
      if (event.code === 'Escape') onPause();
    });
    document.addEventListener('keyup', event => { if (event.code === 'KeyA') model.setGuard(false); });
    canvas.addEventListener('mousedown', event => {
      if (event.button === 0 && model.status === 'playing') { event.preventDefault(); model.tap(); }
    });
    canvas.addEventListener('mousemove', event => {
      if (this.dragMode && model.status === 'playing' && (event.buttons & 1)) {
        model.look(-event.movementX * model.config.sensitivity * this.sensitivity, -event.movementY * model.config.sensitivity * this.sensitivity);
      }
    });
    window.addEventListener('blur', onPause);
    document.addEventListener('visibilitychange', () => { if (document.hidden) onPause(); });
  }
  lock() {
    if (this.dragMode) return;
    try { this.controls.lock(); } catch { this.dragMode = true; this.onPause(); }
  }
  unlock() { if (this.controls.isLocked) this.controls.unlock(); }
  setSensitivity(value) { this.sensitivity = value; this.controls.pointerSpeed = value; }
}
