import * as THREE from 'three';
import { PLAYER_CONFIG, CAMERA, WORLD, WEAPONS } from '../core/Constants.js';
import { gameState } from '../core/GameState.js';
import { stepRecoil, FOV_KICK_BLEED, FOV_KICK_CAP } from './Gunplay.js';

const TAU = Math.PI * 2;
const UP = new THREE.Vector3(0, 1, 0);
const response = (rate, dt) => 1 - Math.exp(-rate * dt);

const SENS_KEY = 'cinder.sens';
const SENS_MIN = 0.2, SENS_MAX = 4, SENS_STEP = 0.1;

function loadSens() {
  try {
    const v = parseFloat(localStorage.getItem(SENS_KEY));
    if (Number.isFinite(v)) return THREE.MathUtils.clamp(v, SENS_MIN, SENS_MAX);
  } catch { /* storage unavailable (headless/privacy mode) */ }
  // Default 1.5 (autopsy fix 10): kimi ships a flat 3x faster sens; meet
  // halfway. User-adjustable via [ / ] and persisted, so only new installs
  // (or cleared storage) see this.
  return 1.5;
}

export class Player {
  constructor(camera, colliders) {
    this.camera = camera;
    this.colliders = colliders;
    this.pos = new THREE.Vector3(0.35, 0, 3.8);
    this.vel = new THREE.Vector3();
    this.yaw = 0.06;
    this.pitch = 0.02;
    this.eye = PLAYER_CONFIG.EYE;
    this.grounded = true;
    this.vy = 0;
    this.bob = 0;
    this.enabled = false;
    this._tmp = new THREE.Vector3();
    this._wish = new THREE.Vector3();
    this._zero = new THREE.Vector3();
    this.trauma = 0;
    this.sensMult = loadSens();
    this.sensToast = 0;
    /* Camera recoil is a velocity spring added at render time — never
     * written into this.pitch/yaw, so recovery doesn't fight the mouse. */
    this.recoilPitch = 0;
    this.recoilYaw = 0;
    this.recoilVelP = 0;
    this.recoilVelY = 0;
    this.fovKick = 0;
    this.jumpCool = 0;
    this._prevY = 0;
  }

  setSens(v) {
    this.sensMult = THREE.MathUtils.clamp(Math.round(+v * 100) / 100, SENS_MIN, SENS_MAX);
    this.sensToast = 1.8;
    try { localStorage.setItem(SENS_KEY, String(this.sensMult)); } catch { /* ignore */ }
  }

  adjustSens(dir) {
    this.setSens(this.sensMult + dir * SENS_STEP);
  }

  addTrauma(n) {
    this.trauma = Math.min(1, this.trauma + n);
  }

  /** Camera recoil velocity impulse (WEAPON_FIRE recoilVy / recoilVx). */
  kick(y, x) {
    this.recoilVelP += y;
    this.recoilVelY += x;
  }

  addFovKick(n) {
    this.fovKick = Math.min(FOV_KICK_CAP, this.fovKick + (n || 0));
  }

  stepRecoil(dt) {
    stepRecoil(this, dt);
    if (dt > 0) this.fovKick *= Math.exp(-FOV_KICK_BLEED * dt);
  }

  place(x, y, z, yaw, pitch) {
    this.pos.set(x, 0, z);
    this.yaw = yaw;
    this.pitch = pitch;
    this.vel.set(0, 0, 0);
    this.vy = 0;
    this.recoilPitch = 0;
    this.recoilYaw = 0;
    this.recoilVelP = 0;
    this.recoilVelY = 0;
    this.fovKick = 0;
    this.jumpCool = 0;
    this._prevY = 0;
    this.grounded = true;
    this._applyCamera();
  }

  update(dt, input) {
    const st = gameState.player;
    // ADS/scoped state is owned by Weapon.update (per-weapon zoom model);
    // it runs after us each frame, so we read last frame's value here.
    st.sprinting = input.sprint && input.moveZ > 0 && !input.crouch && !st.ads;
    st.crouching = input.crouch;

    if (input.sensUp) this.adjustSens(1);
    if (input.sensDown) this.adjustSens(-1);
    this.sensToast = Math.max(0, this.sensToast - dt);

    // Raw 1:1 look — same multiplier on both axes, no smoothing or acceleration.
    // Scoped sensitivity scales by tan(fov/2)/tan(base/2) so a flick covers
    // the same SCREEN distance at every scope stage (replaces flat ADS_MOUSE
    // while the sniper scope is up).
    let sens = (st.ads ? PLAYER_CONFIG.ADS_MOUSE : PLAYER_CONFIG.MOUSE) * this.sensMult;
    if (st.scoped) {
      const fov = THREE.MathUtils.clamp(this.camera.fov, 4, 110);
      sens = PLAYER_CONFIG.MOUSE * this.sensMult
        * Math.tan(THREE.MathUtils.degToRad(fov * 0.5))
        / Math.tan(THREE.MathUtils.degToRad(CAMERA.FOV * 0.5));
    }
    if (this.enabled) {
      this.yaw -= input.lookX * sens;
      this.pitch -= input.lookY * sens;
    }
    this.pitch = THREE.MathUtils.clamp(this.pitch, -PLAYER_CONFIG.PITCH_MAX, PLAYER_CONFIG.PITCH_MAX);

    const targetEye = st.crouching ? PLAYER_CONFIG.CROUCH_EYE : PLAYER_CONFIG.EYE;
    this.eye += (targetEye - this.eye) * response(12, dt);

    // Active weapon drags the run speed (sniper 0.7×, 0.5× scoped).
    const wcfg = WEAPONS[gameState.activeWeapon] || WEAPONS.rifle;
    const moveMult = (st.scoped && wcfg.scopedMoveMult) ? wcfg.scopedMoveMult : (wcfg.moveMult ?? 1);
    const speed = (st.crouching ? PLAYER_CONFIG.CROUCH
      : st.sprinting ? PLAYER_CONFIG.SPRINT
        : PLAYER_CONFIG.WALK) * moveMult;

    // Camera faces -Z at yaw 0 (rotation.y = yaw, forward = (-sin yaw, 0, -cos yaw)),
    // so W (moveZ = +1) must produce a -Z wish before rotating into world space.
    this._wish.set(input.moveX * PLAYER_CONFIG.STRAFE, 0, -input.moveZ);
    if (input.moveZ < 0) this._wish.z *= PLAYER_CONFIG.BACK;
    if (this._wish.lengthSq() > 1) this._wish.normalize();
    this._wish.multiplyScalar(speed);
    this._wish.applyAxisAngle(UP, this.yaw);

    const accel = this.grounded ? PLAYER_CONFIG.ACCEL : PLAYER_CONFIG.AIR_STEER;
    const brake = this.grounded ? PLAYER_CONFIG.BRAKE : 1.2;
    const horiz = this._tmp.set(this.vel.x, 0, this.vel.z);
    if (this._wish.lengthSq() < 1e-6) {
      horiz.lerp(this._zero, response(brake, dt));
    } else {
      horiz.lerp(this._wish, response(accel, dt));
    }
    this.vel.x = horiz.x;
    this.vel.z = horiz.z;

    this.jumpCool = Math.max(0, this.jumpCool - dt);
    if (this.grounded && input.jump && this.jumpCool <= 0) {
      this.vy = PLAYER_CONFIG.JUMP;
      this.grounded = false;
      this.jumpCool = PLAYER_CONFIG.JUMP_COOL;
    }
    this.vy -= PLAYER_CONFIG.GRAVITY * dt;
    this._prevY = this.pos.y;
    this.pos.x += this.vel.x * dt;
    this.pos.z += this.vel.z * dt;
    this.pos.y += this.vy * dt;
    this._collide();

    const spd = Math.hypot(this.vel.x, this.vel.z);
    // Frequency-capped stride (autopsy fix 5): spd*8.4 hit 7.4 Hz at the old
    // sprint (a buzz, not a stride); ~3.4 Hz max is kimi/CS2-class.
    this.bob += Math.min(spd, 3.6) * dt * 6.0;
    this.trauma = Math.max(0, this.trauma - 1.6 * dt);
    st.speed = spd;
    st.grounded = this.grounded;
    this.stepRecoil(dt);
    this._applyCamera(dt);
  }

  _applyCamera(dt = 0) {
    const shake = this.trauma * this.trauma;
    /* Trauma shake (hit reactions only — never fired per shot anymore).
     * Old oscillators ran at 82/103/64 Hz — above Nyquist at any playable
     * frame rate, so they rendered as per-frame white noise. 8-11 Hz reads
     * as an actual shake. */
    const t = performance.now() * 0.001;
    const sx = shake * 0.028 * Math.sin(t * 51);
    const sy = shake * 0.022 * Math.sin(t * 67);
    const bobY = Math.sin(this.bob) * PLAYER_CONFIG.BOB * Math.min(1, Math.hypot(this.vel.x, this.vel.z) / 3);
    const bobX = Math.cos(this.bob * 0.5) * PLAYER_CONFIG.BOB * 0.45;
    this.camera.position.set(this.pos.x + bobX + sx, this.pos.y + this.eye + bobY + sy, this.pos.z);
    this.camera.rotation.order = 'YXZ';
    this.camera.rotation.y = this.yaw + this.recoilYaw;
    this.camera.rotation.x = this.pitch + this.recoilPitch;
    this.camera.rotation.z = shake * 0.012 * Math.sin(t * 43);
    // fovTarget is written by Weapon.update from WEAPONS[id].zoom (absolute
    // FOV, 0 = none). Fallback keeps the legacy ADS_FOV formula alive for
    // anything that never touches the new weapon system. Per-shot FOV kick
    // rides on top and is suppressed 75% while ADS.
    const st = gameState.player;
    const sprint = st.sprinting;
    const adsK = st.adsEase ?? (st.ads ? 1 : 0);
    const baseFov = st.fovTarget
      ? st.fovTarget
      : CAMERA.FOV + (st.ads ? PLAYER_CONFIG.ADS_FOV : 0) + (sprint ? PLAYER_CONFIG.SPRINT_FOV : 0);
    const fov = baseFov + this.fovKick * (1 - adsK * 0.75);
    if (Math.abs(this.camera.fov - fov) > 0.05) {
      // dt-based response: frame-rate independent, snap when no dt
      // (place/tools). Scope stages snap ~2.5× faster (instant-ish lerp).
      const rate = st.scoped ? PLAYER_CONFIG.FOV_LERP * 2.5 : PLAYER_CONFIG.FOV_LERP;
      const k = dt > 0 ? 1 - Math.exp(-rate * dt) : 1;
      this.camera.fov += (fov - this.camera.fov) * k;
      this.camera.updateProjectionMatrix();
    }
  }

  _collide() {
    const r = PLAYER_CONFIG.RADIUS;
    const h = this.eye + PLAYER_CONFIG.HEADROOM;
    const step = PLAYER_CONFIG.STEP;
    const g = PLAYER_CONFIG.GRAVITY;
    let supported = this.pos.y <= 0;
    if (this.pos.y <= 0) {
      this.pos.y = 0;
      this.vy = 0;
    }
    for (const c of this.colliders) {
      if (c.max.y <= 0.12) continue;
      const minX = c.min.x - r, maxX = c.max.x + r;
      const minZ = c.min.z - r, maxZ = c.max.z + r;
      if (this.pos.x < minX || this.pos.x > maxX || this.pos.z < minZ || this.pos.z > maxZ) continue;
      const top = c.max.y;
      const bot = c.min.y;
      if (this.pos.y + h < bot) continue;

      // Land / rest on the top face (crate, pallet, stair, fountain curb).
      const onTop = this.pos.y >= top - 0.10 && this.pos.y <= top + 0.14;
      const crossed = this._prevY >= top - 0.02 && this.pos.y < top;
      if ((onTop || crossed) && this.vy <= 0.55) {
        this.pos.y = top;
        this.vy = 0;
        supported = true;
        continue;
      }

      // Jump-over: if this apex clears the top, don't wall-block (the old
      // resolver shoved you back every airborne frame while y < max.y).
      if (this.vy > 0) {
        const apex = this.pos.y + (this.vy * this.vy) / (2 * g) + 0.06;
        if (top <= apex) continue;
      }

      // Walk-up small ledges (pallets 0.22m, curb/plank lips).
      const rise = top - this.pos.y;
      if (rise > 0 && rise <= step && this.vy <= 1.2) {
        this.pos.y = top;
        this.vy = 0;
        supported = true;
        continue;
      }

      if (this.pos.y > top) continue;

      // Wall-slide: zero only the inward axis so a graze keeps forward speed.
      const dxL = this.pos.x - minX, dxR = maxX - this.pos.x;
      const dzL = this.pos.z - minZ, dzR = maxZ - this.pos.z;
      const m = Math.min(dxL, dxR, dzL, dzR);
      if (m === dxL) { this.pos.x = minX; if (this.vel.x < 0) this.vel.x = 0; }
      else if (m === dxR) { this.pos.x = maxX; if (this.vel.x > 0) this.vel.x = 0; }
      else if (m === dzL) { this.pos.z = minZ; if (this.vel.z < 0) this.vel.z = 0; }
      else { this.pos.z = maxZ; if (this.vel.z > 0) this.vel.z = 0; }
    }
    this.grounded = supported;
    this.pos.x = THREE.MathUtils.clamp(this.pos.x, WORLD.PLAY_X[0], WORLD.PLAY_X[1]);
    this.pos.z = THREE.MathUtils.clamp(this.pos.z, WORLD.PLAY_Z[0], WORLD.PLAY_Z[1]);
  }
}
