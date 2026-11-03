// Camera rig: chase views with mouse orbit, a driver view, a drone, and a cinematic mode that
// cuts between shots on its own (best with autodrive). The sea is always on the +x side.
import * as THREE from 'three';
import { roadX, roadY, shoreD, terrainHeight } from './road.js';

export const CAMERAS = [
  { id: 'chase', name: 'Chase', fov: 55 },
  { id: 'far', name: 'Far chase', fov: 50 },
  { id: 'driver', name: 'Driver', fov: 70 },
  { id: 'drone', name: 'Drone', fov: 50 },
  { id: 'cinematic', name: 'Cinematic', fov: 40 },
];

const SHOTS = [
  { id: 'roadside', fov: 36, len: [9, 14] },
  { id: 'sideTrack', fov: 42, len: [9, 13] },
  { id: 'drone', fov: 48, len: [11, 15] },
  { id: 'frontLow', fov: 50, len: [7, 10] },
  { id: 'flyover', fov: 46, len: [10, 12] },
  { id: 'seaView', fov: 34, len: [10, 14] },
  { id: 'wheel', fov: 62, len: [5, 7] },
];

const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
const UP = new THREE.Vector3(0, 1, 0), SEA = new THREE.Vector3(1, 0, 0);

export class CameraRig {
  constructor(camera) {
    this.camera = camera;
    this.mode = 'chase';
    this.pos = new THREE.Vector3();
    this.look = new THREE.Vector3();
    this.snap = true;
    this.orbitYaw = 0;
    this.orbitPitch = 0;
    this.zoom = 1;
    this.idle = 10;
    this.shot = null;
    this.showroom = false;
    this.shake = 0;
    this.fov = 55;
  }

  setMode(id) {
    this.mode = id;
    this.snap = true;
    this.shot = null;
    this.orbitYaw = this.orbitPitch = 0;
  }

  get modeName() {
    const m = CAMERAS.find((c) => c.id === this.mode);
    return this.mode === 'cinematic' && this.shot ? `${m.name} · ${this.shot.id}` : m.name;
  }

  next() {
    const i = CAMERAS.findIndex((c) => c.id === this.mode);
    this.setMode(CAMERAS[(i + 1) % CAMERAS.length].id);
  }

  drag(dx, dy) {
    this.orbitYaw -= dx * 0.006;
    this.orbitPitch = clamp(this.orbitPitch + dy * 0.004, -0.3, 1.0);
    this.idle = 0;
  }

  wheel(d) {
    this.zoom = clamp(this.zoom * (1 + d * 0.0012), 0.55, 2.4);
  }

  update(dt, car, obj, t) {
    const p = obj.group.position;
    const fwd = new THREE.Vector3(car.fx, 0, car.fz);
    const right = new THREE.Vector3(-car.fz, 0, car.fx);
    const dir = car.dir;
    let target, look, k = 3, fov = CAMERAS.find((c) => c.id === this.mode).fov;

    this.idle += dt;
    if (this.idle > 1.8 && !this.showroom) {
      const decay = Math.exp(-dt * 1.4);
      this.orbitYaw *= decay;
      this.orbitPitch *= decay;
    }

    if (this.showroom) {
      const a = t * 0.22, dims = obj.dims ?? { length: 4.4, height: 1.5 };
      const r = 3.6 + dims.length * 0.95;
      target = p.clone().add(new THREE.Vector3(Math.sin(a) * r, 0.9 + dims.height * 0.75, Math.cos(a) * r));
      // Aim left of the car so it sits in the right half of the screen, clear of the garage panel.
      const side = p.clone().sub(target).cross(UP).normalize();
      look = p.clone().addScaledVector(UP, 0.7).addScaledVector(side, -2.2);
      k = 8;
      fov = 45;
    } else if (this.mode === 'chase' || this.mode === 'far') {
      const far = this.mode === 'far';
      const dist = (far ? 16 : 9) * this.zoom, height = far ? 6 : 3.4;
      const back = fwd.clone().multiplyScalar(-dist).applyAxisAngle(UP, this.orbitYaw);
      target = p.clone().add(back).addScaledVector(UP, height + dist * Math.sin(this.orbitPitch));
      look = this.idle < 1.8 ? p.clone().addScaledVector(UP, 1) : this.roadAhead(car, 14, 1.2).lerp(p.clone().addScaledVector(UP, 1), Math.min(1, Math.abs(this.orbitYaw)));
      k = 3.2;
      fov += Math.max(0, car.v - 15) * 0.25;
    } else if (this.mode === 'driver') {
      target = obj.group.localToWorld(obj.cockpit.clone());
      const lookDir = fwd.clone().applyAxisAngle(UP, this.orbitYaw);
      look = target.clone().addScaledVector(lookDir, 20).addScaledVector(UP, -1.2 + this.orbitPitch * 8);
      k = 40;
    } else if (this.mode === 'drone') {
      const off = fwd.clone().multiplyScalar(-26).addScaledVector(SEA, 18).applyAxisAngle(UP, this.orbitYaw);
      target = p.clone().add(off).addScaledVector(UP, 13 * this.zoom);
      look = this.roadAhead(car, 12, 0);
      k = 1.5;
    } else {
      ({ target, look, fov, k } = this.cinematic(dt, car, p, fwd, right, dir));
    }

    const a = this.snap ? 1 : 1 - Math.exp(-dt * k);
    this.pos.lerp(target, a);
    this.look.lerp(look, a);
    if (this.snap) { this.pos.copy(target); this.look.copy(look); }
    this.snap = false;
    this.pos.y = Math.max(this.pos.y, terrainHeight(this.pos.x, this.pos.z) + 0.7, 0.9);

    const cam = this.camera;
    cam.position.copy(this.pos);
    if (this.shake > 0) {
      cam.position.x += (Math.random() - 0.5) * this.shake;
      cam.position.y += (Math.random() - 0.5) * this.shake;
      this.shake = Math.max(0, this.shake - dt * 0.6);
    }
    cam.lookAt(this.look);
    this.fov += (fov - this.fov) * Math.min(1, dt * 3);
    if (Math.abs(cam.fov - this.fov) > 0.02) {
      cam.fov = this.fov;
      cam.updateProjectionMatrix();
    }
    for (const o of obj.outlines) o.visible = this.mode !== 'driver' || this.showroom;
  }

  roadAhead(car, dist, lift) {
    const z = car.z + car.dir * dist;
    return new THREE.Vector3(roadX(z) + car.offset, roadY(z) + lift, z);
  }

  cinematic(dt, car, p, fwd, right, dir) {
    if (!this.shot || (this.shot.timeLeft -= dt) <= 0 || this.shot.done) {
      let next;
      do next = SHOTS[Math.floor(Math.random() * SHOTS.length)];
      while (this.shot && next.id === this.shot.id);
      this.shot = { ...next, timeLeft: next.len[0] + Math.random() * (next.len[1] - next.len[0]), age: 0, side: Math.random() < 0.5 ? -1 : 1 };
      this.snap = true;
    }
    const s = this.shot;
    s.age += dt;
    let target, look = p.clone().addScaledVector(UP, 0.9), k = 2.5;
    switch (s.id) {
      case 'roadside': {
        if (!s.spot) {
          const z = car.z + dir * (90 + Math.max(car.v, 5) * 2.5), x = roadX(z) + 10.5;
          s.spot = new THREE.Vector3(x, Math.max(terrainHeight(x, z), roadY(z) - 3, 0.5) + 1.3, z);
        }
        target = s.spot;
        k = 50;
        if ((car.z - s.spot.z) * dir > 35) s.done = true;
        break;
      }
      case 'sideTrack':
        target = p.clone().addScaledVector(SEA, -11).addScaledVector(fwd, 4).addScaledVector(UP, 2.2);
        look = p.clone().addScaledVector(SEA, 4).addScaledVector(UP, 1);
        k = 4;
        break;
      case 'drone': {
        const a = s.age * 0.05 * s.side;
        target = p.clone().add(new THREE.Vector3(18, 14, -dir * 24).applyAxisAngle(UP, a));
        look = this.roadAhead(car, 10, 0);
        k = 1.5;
        break;
      }
      case 'frontLow':
        target = p.clone().addScaledVector(fwd, 12).addScaledVector(UP, 1.0).addScaledVector(right, 1.6 * s.side);
        k = 6;
        break;
      case 'flyover': {
        const u = clamp(s.age / s.timeLeft, 0, 1);
        target = p.clone().addScaledVector(fwd, -40 + 80 * u).addScaledVector(UP, 24).addScaledVector(SEA, 8);
        k = 3;
        break;
      }
      case 'seaView': {
        const z = car.z + dir * 30;
        target = new THREE.Vector3(roadX(z) + shoreD(z) + 55, 5, z);
        k = 2;
        break;
      }
      default: // wheel
        target = p.clone().addScaledVector(right, 1.5 * s.side).addScaledVector(fwd, -1.0).addScaledVector(UP, 0.45);
        look = p.clone().addScaledVector(fwd, 7).addScaledVector(UP, 0.4);
        k = 20;
    }
    return { target, look, fov: s.fov, k };
  }
}
