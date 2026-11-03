// Third-person player: cute capsule character with glide cape, orbit-follow
// camera, ground raycast against walkable colliders, double jump, respawn.
import * as THREE from 'three';
import { toonMaterial, addOutline } from '../world/toon.js';
import { MOVE, createMoveState, stepVertical, stepHorizontal, shouldRespawn } from './movement.js';

const HOME_SPAWN = new THREE.Vector3(0, 0.5, 3.5);

function buildCharacter() {
  const group = new THREE.Group();
  const bodyMat = toonMaterial(0xfff3d6);
  const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.3, 0.42, 6, 14), bodyMat);
  body.position.y = 0.62;
  addOutline(body, 0.06);
  group.add(body);

  const head = new THREE.Mesh(new THREE.SphereGeometry(0.27, 16, 12), bodyMat);
  head.position.y = 1.18;
  addOutline(head, 0.06);
  group.add(head);

  // eyes
  const eyeMat = new THREE.MeshBasicMaterial({ color: 0x4a3a6a });
  for (const side of [-1, 1]) {
    const eye = new THREE.Mesh(new THREE.SphereGeometry(0.045, 8, 6), eyeMat);
    eye.position.set(side * 0.11, 1.22, 0.23);
    group.add(eye);
  }
  // blush
  const blushMat = new THREE.MeshBasicMaterial({ color: 0xf2b8c6, transparent: true, opacity: 0.7 });
  for (const side of [-1, 1]) {
    const blush = new THREE.Mesh(new THREE.CircleGeometry(0.05, 8), blushMat);
    blush.position.set(side * 0.19, 1.13, 0.2);
    blush.lookAt(blush.position.clone().multiplyScalar(2).add(new THREE.Vector3(0, 1.13, 0)));
    group.add(blush);
  }
  // little sprout on the head
  const sprout = new THREE.Mesh(new THREE.SphereGeometry(0.07, 8, 6), toonMaterial(0x8fdcb4));
  sprout.scale.y = 1.6;
  sprout.position.y = 1.48;
  group.add(sprout);

  // glide cape: small scarf plane at the shoulders, spreads wide while gliding
  const capeGeo = new THREE.PlaneGeometry(0.5, 0.55, 5, 6);
  const cape = new THREE.Mesh(
    capeGeo,
    new THREE.MeshToonMaterial({
      color: 0xcdb4f0,
      side: THREE.DoubleSide,
      emissive: 0xcdb4f0,
      emissiveIntensity: 0.45 // keeps the unlit back face soft lavender
    })
  );
  addOutline(cape, 0.04);
  cape.position.set(0, 0.92, -0.18);
  cape.rotation.x = 1.0; // hangs down the back like a scarf
  group.add(cape);
  const capeBase = capeGeo.attributes.position.array.slice();

  return { group, cape, capeBase, body, head };
}

export class Player {
  constructor(scene, camera, colliders) {
    this.camera = camera;
    this.colliders = colliders;
    this.char = buildCharacter();
    scene.add(this.char.group);

    this.pos = HOME_SPAWN.clone();
    this.lastGrounded = HOME_SPAWN.clone();
    this.move = createMoveState();
    this.heading = Math.PI; // facing -z initially

    // orbit camera state
    this.orbit = { yaw: Math.PI, pitch: 0.38, dist: 8 };

    this.ray = new THREE.Raycaster();
    this.ray.far = 4;
    this._down = new THREE.Vector3(0, -1, 0);
    this._origin = new THREE.Vector3();
    this._wish = new THREE.Vector3();
    this._camTarget = new THREE.Vector3();
    this._camPos = new THREE.Vector3();

    this.onJumpPad = null; // callback set by main
    this._padCooldown = 0;
  }

  teleport(x, y, z) {
    this.pos.set(x, y, z);
    // only checkpoint sensible spots — never the void below the kill plane
    if (y > MOVE.respawnY + 5) this.lastGrounded.set(x, y, z);
    this.move.vx = 0;
    this.move.vy = 0;
    this.move.vz = 0;
    this.move.grounded = false;
  }

  respawn() {
    this.teleport(this.lastGrounded.x, this.lastGrounded.y + 0.4, this.lastGrounded.z);
  }

  // input: { x, z (camera-relative wish dir, len<=1), jumpPressed, jumpHeld }
  update(dt, input, time) {
    const m = this.move;

    // camera-relative movement
    const yaw = this.orbit.yaw;
    const sin = Math.sin(yaw);
    const cos = Math.cos(yaw);
    this._wish.set(
      (input.x * cos + input.z * sin) * MOVE.walkSpeed,
      0,
      (-input.x * sin + input.z * cos) * MOVE.walkSpeed
    );
    stepHorizontal(m, this._wish.x, this._wish.z, dt);
    const events = stepVertical(m, input, dt);

    // integrate
    this.pos.x += m.vx * dt;
    this.pos.z += m.vz * dt;
    this.pos.y += m.vy * dt;

    // ground detection: raycast down from waist height
    this._origin.copy(this.pos);
    this._origin.y += 1.0;
    this.ray.set(this._origin, this._down);
    this.ray.far = 1.0 + (m.vy < 0 ? Math.max(0.3, -m.vy * dt + 0.25) : 0.3);
    const hits = this.ray.intersectObjects(this.colliders, false);
    const wasGrounded = m.grounded;
    m.grounded = false;
    if (hits.length && m.vy <= 0.01) {
      const hit = hits[0];
      const groundY = hit.point.y;
      if (this.pos.y <= groundY + 0.28) {
        this.pos.y = groundY;
        m.vy = 0;
        m.grounded = true;
        this.lastGrounded.copy(this.pos);
        // jump pad?
        const pad = hit.object.userData.jumpPad;
        if (pad && this._padCooldown <= 0) {
          m.vy = pad.strength;
          m.grounded = false;
          m.jumpsUsed = 1; // still allow one air jump after the bounce
          pad.pulse = 1;
          this._padCooldown = 0.5;
          if (this.onJumpPad) this.onJumpPad(pad);
        }
      }
    }
    this._padCooldown = Math.max(0, this._padCooldown - dt);
    if (!wasGrounded && m.grounded) events.landed = true;

    // fell off the world -> respawn at last grounded spot
    if (shouldRespawn(this.pos.y)) this.respawn();

    // face movement direction smoothly
    const speed = Math.hypot(m.vx, m.vz);
    if (speed > 0.6) {
      const target = Math.atan2(m.vx, m.vz);
      let d = target - this.heading;
      while (d > Math.PI) d -= Math.PI * 2;
      while (d < -Math.PI) d += Math.PI * 2;
      this.heading += d * Math.min(1, dt * 10);
    }

    // pose character
    const g = this.char.group;
    g.position.copy(this.pos);
    g.rotation.y = this.heading;
    const bob = m.grounded && speed > 0.6 ? Math.abs(Math.sin(time * 9)) * 0.06 : 0;
    this.char.body.position.y = 0.62 + bob;
    this.char.head.position.y = 1.18 + bob;

    // cape: spread while gliding, flutter always
    const cape = this.char.cape;
    const capeSpread = m.gliding ? 1 : 0;
    cape.userData.spread = THREE.MathUtils.lerp(cape.userData.spread ?? 0, capeSpread, Math.min(1, dt * 6));
    const spread = cape.userData.spread;
    cape.rotation.x = 1.0 - spread * 1.45; // scarf -> spread wing
    cape.position.z = -0.18 - spread * 0.28;
    cape.position.y = 0.92 + spread * 0.18;
    cape.scale.set(1 + spread * 1.1, 1 + spread * 0.55, 1);
    const posAttr = cape.geometry.attributes.position;
    const base = this.char.capeBase;
    for (let i = 0; i < posAttr.count; i++) {
      const bx = base[i * 3];
      const by = base[i * 3 + 1];
      const wave = Math.sin(time * (m.gliding ? 11 : 5) + bx * 5 + by * 3) * 0.05 * (0.4 + spread);
      posAttr.array[i * 3 + 2] = base[i * 3 + 2] + wave * (0.5 - by);
    }
    posAttr.needsUpdate = true;

    // orbit-follow camera
    const o = this.orbit;
    this._camTarget.copy(this.pos).add(this._wish.set(0, 1.5, 0));
    const cp = Math.cos(o.pitch);
    this._camPos.set(
      this._camTarget.x + Math.sin(o.yaw) * cp * o.dist,
      this._camTarget.y + Math.sin(o.pitch) * o.dist,
      this._camTarget.z + Math.cos(o.yaw) * cp * o.dist
    );
    this.camera.position.lerp(this._camPos, Math.min(1, dt * 8));
    this.camera.lookAt(this._camTarget);

    return events;
  }
}
