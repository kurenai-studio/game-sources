/**
 * First-person walk mode.
 *
 * Pointer-lock look, WASD move, gravity onto the analytic heightfield, plus a
 * gait: a vertical bob and a lateral sway phased off the stride, damped by
 * speed. It also refuses to walk into lava (the terrain is hot; the game says
 * no) and steps up onto low ledges instead of catching on them.
 */
import * as THREE from 'three';
import { height, normalAt, isOnLava, isOnWater } from '../world/Heightfield.js';
import { clamp, lerp, damp, TAU } from '../utils/MathX.js';

const EYE = 1.72;

export class WalkController {
  constructor(camera, canvas) {
    this.camera = camera;
    this.canvas = canvas;
    this.active = false;

    this.pos = new THREE.Vector3();
    this.vel = new THREE.Vector3();
    this.yaw = 0;
    this.pitch = 0;
    this.keys = new Set();
    this.stride = 0;
    this.bob = 0;
    this.grounded = true;

    this._hint = document.getElementById('walkhint');

    this._onMove = (e) => {
      if (!this.active || document.pointerLockElement !== canvas) return;
      this.yaw -= e.movementX * 0.0022;
      this.pitch = clamp(this.pitch - e.movementY * 0.0022, -1.35, 1.35);
    };
    this._onKeyDown = (e) => {
      if (!this.active) return;
      this.keys.add(e.code);
      if (e.code === 'Space' && this.grounded) { this.vel.y = 5.4; this.grounded = false; }
    };
    this._onKeyUp = (e) => this.keys.delete(e.code);
    this._onClick = () => { if (this.active) canvas.requestPointerLock?.(); };

    window.addEventListener('mousemove', this._onMove);
    window.addEventListener('keydown', this._onKeyDown);
    window.addEventListener('keyup', this._onKeyUp);
    canvas.addEventListener('click', this._onClick);
  }

  enter(spot) {
    this.active = true;
    const x = spot.x ?? 0, z = (spot.z ?? 0) + 26;
    this.pos.set(x, height(x, z) + EYE, z);
    this.vel.set(0, 0, 0);
    const dir = new THREE.Vector3();
    this.camera.getWorldDirection(dir);
    this.yaw = Math.atan2(-dir.x, -dir.z);
    this.pitch = 0;
    if (this._hint) this._hint.hidden = false;
  }

  exit() {
    this.active = false;
    document.exitPointerLock?.();
    if (this._hint) this._hint.hidden = true;
  }

  update(dt) {
    if (!this.active) return;

    const fwd = new THREE.Vector3(-Math.sin(this.yaw), 0, -Math.cos(this.yaw));
    const right = new THREE.Vector3(Math.cos(this.yaw), 0, -Math.sin(this.yaw));

    const k = this.keys;
    const run = k.has('ShiftLeft') || k.has('ShiftRight');
    const speed = run ? 9.5 : 3.6;
    const wish = new THREE.Vector3();
    if (k.has('KeyW') || k.has('ArrowUp')) wish.add(fwd);
    if (k.has('KeyS') || k.has('ArrowDown')) wish.sub(fwd);
    if (k.has('KeyD') || k.has('ArrowRight')) wish.add(right);
    if (k.has('KeyA') || k.has('ArrowLeft')) wish.sub(right);
    const moving = wish.lengthSq() > 0;
    if (moving) wish.normalize().multiplyScalar(speed);

    // Slope resistance: uphill is slower.
    const n = normalAt(this.pos.x, this.pos.z, 2);
    const slopeFactor = clamp(1 - (1 - n[1]) * 1.4, 0.35, 1);
    wish.multiplyScalar(slopeFactor);

    this.vel.x = damp(this.vel.x, wish.x, 0.00005, dt);
    this.vel.z = damp(this.vel.z, wish.z, 0.00005, dt);
    this.vel.y -= 22 * dt;

    const next = this.pos.clone().addScaledVector(this.vel, dt);

    // Refuse lava; nudge back out.
    if (isOnLava(next.x, next.z)) {
      const away = new THREE.Vector3(next.x - this.pos.x, 0, next.z - this.pos.z).negate();
      next.x = this.pos.x + away.x * 0.5;
      next.z = this.pos.z + away.z * 0.5;
      this.vel.multiplyScalar(0.2);
    }

    const ground = height(next.x, next.z) + EYE
                 + (isOnWater(next.x, next.z) ? -0.6 : 0);   // wade
    if (next.y <= ground) {
      next.y = ground;
      this.vel.y = 0;
      this.grounded = true;
    } else {
      this.grounded = false;
    }
    this.pos.copy(next);

    // ── gait ─────────────────────────────────────────────────────────
    const sp = Math.hypot(this.vel.x, this.vel.z);
    this.stride += dt * sp * (run ? 1.5 : 1.9);
    const amp = clamp(sp / speed, 0, 1) * (run ? 0.075 : 0.05);
    this.bob = damp(this.bob, Math.sin(this.stride * 2) * amp, 0.0001, dt);
    const sway = Math.sin(this.stride) * amp * 0.6;

    this.camera.position.set(this.pos.x, this.pos.y + this.bob, this.pos.z);
    this.camera.position.addScaledVector(right, sway);

    // Look — apply as an explicit basis so roll never creeps in.
    const look = new THREE.Vector3(
      -Math.sin(this.yaw) * Math.cos(this.pitch),
      Math.sin(this.pitch),
      -Math.cos(this.yaw) * Math.cos(this.pitch),
    );
    this.camera.lookAt(this.camera.position.clone().add(look));
    // A touch of head roll into the stride.
    this.camera.rotateZ(Math.sin(this.stride) * amp * 0.25);
  }

  dispose() {
    window.removeEventListener('mousemove', this._onMove);
    window.removeEventListener('keydown', this._onKeyDown);
    window.removeEventListener('keyup', this._onKeyUp);
    this.canvas.removeEventListener('click', this._onClick);
  }
}
