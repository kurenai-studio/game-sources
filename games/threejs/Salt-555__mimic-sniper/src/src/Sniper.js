import * as THREE from 'three';
import { WeaponState } from './core/WeaponState.js';

export class Sniper {
  constructor(camera, input, effects) {
    this.camera = camera;
    this.input = input;
    this.effects = effects;
    this.weapon = new WeaponState();
    this.raycaster = new THREE.Raycaster();
    this.yaw = 0;
    this.pitch = -0.39;
    this.scoped = false;
    this.breath = 100;
    this.swayTime = 0;
    this.shots = 0;
    this.hits = 0;
    this.camera.position.set(0, 14.25, 33);
  }

  update(dt, active) {
    this.weapon.update(dt);
    if (!active) return;
    const delta = this.input.consumeMouseDelta();
    const sensitivity = this.scoped ? 0.00075 : 0.0018;
    this.yaw -= delta.x * sensitivity;
    this.pitch -= delta.y * sensitivity;
    this.yaw = THREE.MathUtils.clamp(this.yaw, -1.12, 1.12);
    this.pitch = THREE.MathUtils.clamp(this.pitch, -0.65, 0.2);
    this.scoped = this.input.scopeHeld;

    const holding = this.input.keys.has('ShiftLeft') && this.breath > 0 && this.scoped;
    this.breath = THREE.MathUtils.clamp(this.breath + (holding ? -24 : 11) * dt, 0, 100);
    this.swayTime += dt;
    const sway = holding ? 0.0002 : (this.scoped ? 0.0024 : 0.0004);
    const swayPitch = Math.sin(this.swayTime * 1.7) * sway;
    const swayYaw = Math.cos(this.swayTime * 1.2) * sway * 0.65;
    this.camera.rotation.set(this.pitch + swayPitch, this.yaw + swayYaw, 0, 'YXZ');

    const targetFov = this.scoped ? 13 : 58;
    this.camera.fov = THREE.MathUtils.damp(this.camera.fov, targetFov, 10, dt);
    this.camera.updateProjectionMatrix();

    if (this.input.keys.has('KeyR')) this.weapon.startReload();
  }

  fire(objects) {
    if (!this.weapon.fire()) return null;
    this.shots += 1;
    this.raycaster.setFromCamera(new THREE.Vector2(0, 0), this.camera);
    const hit = this.raycaster.intersectObjects(objects, true)[0];
    const end = hit?.point ?? this.raycaster.ray.at(120, new THREE.Vector3());
    this.effects.tracer(this.camera.position, end);
    this.camera.rotation.x += 0.025;
    if (hit) this.effects.burst(hit.point, hit.object.userData.isMimic ? 0x060707 : 0xc4b39a, 18);
    if (hit?.object.userData.isMimic) this.hits += 1;
    return hit ?? null;
  }

  reset() {
    this.weapon = new WeaponState();
    this.shots = 0;
    this.hits = 0;
    this.breath = 100;
    this.scoped = false;
    this.camera.fov = 58;
    this.camera.updateProjectionMatrix();
  }
}
