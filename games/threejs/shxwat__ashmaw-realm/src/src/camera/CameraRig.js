/**
 * Camera rig.
 *
 * One PerspectiveCamera, five behaviours, and a shared *dolly* layer that every
 * mode inherits: handheld noise, impulse shake, focus-pull target, terrain
 * collision and a lens (fov) that can breathe. Modes only ever write a desired
 * position/target; the rig owns how the camera actually gets there, which is why
 * switching modes never snaps.
 *
 * Modes
 *  cinematic — the director drives it (see CinematicDirector)
 *  orbit     — OrbitControls around a focus point
 *  follow    — chase the dragon on a spring, framing it against the horizon
 *  free      — 6-DOF flight (WASD + mouse), the "photo mode"
 *  walk      — first-person on foot in the village, feet glued to the terrain
 */
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { bus, EV } from '../core/EventBus.js';
import { WalkController } from './WalkController.js';
import { height, WORLD } from '../world/Heightfield.js';
import { damp, dampVec3, clamp, lerp, smoothstep, hash11 } from '../utils/MathX.js';

export class CameraRig {
  constructor(canvas, { aspect }) {
    this.camera = new THREE.PerspectiveCamera(46, aspect, 0.6, 12000);
    this.camera.position.set(560, 260, 620);

    this.mode = 'cinematic';
    this.focus = new THREE.Vector3(WORLD.village.x, 60, WORLD.village.z);
    this.desired = this.camera.position.clone();
    this.desiredTarget = this.focus.clone();
    this.smoothing = 0.0004;      // per-second retention; lower = snappier
    this.targetSmoothing = 0.0006;

    // ── orbit ─────────────────────────────────────────────────────────
    this.orbit = new OrbitControls(this.camera, canvas);
    this.orbit.enableDamping = true;
    this.orbit.dampingFactor = 0.045;
    this.orbit.rotateSpeed = 0.55;
    this.orbit.zoomSpeed = 0.9;
    this.orbit.minDistance = 12;
    this.orbit.maxDistance = 2400;
    this.orbit.maxPolarAngle = Math.PI * 0.495;
    this.orbit.enablePan = true;
    this.orbit.panSpeed = 0.7;
    this.orbit.enabled = false;
    this.orbit.target.copy(this.focus);

    // ── free flight ───────────────────────────────────────────────────
    this.free = {
      yaw: 0, pitch: -0.18, speed: 90, boost: 1,
      vel: new THREE.Vector3(),
      keys: new Set(),
      dragging: false,
    };

    // ── walk ──────────────────────────────────────────────────────────
    this.walk = new WalkController(this.camera, canvas);

    // ── shake / handheld ─────────────────────────────────────────────
    this.shake = { amp: 0, freq: 18, decay: 1, t: 0 };
    this.handheld = 0.35;
    this._noiseT = Math.random() * 100;
    this._shakeOffset = new THREE.Vector3();
    this._rollOffset = 0;

    this.fov = 46;
    this.fovTarget = 46;

    this._bindInput(canvas);
    bus.on(EV.SHAKE, ({ amplitude, duration, frequency }) => this.addShake(amplitude, duration, frequency));
  }

  _bindInput(canvas) {
    const F = this.free;
    window.addEventListener('keydown', (e) => {
      F.keys.add(e.code);
      if (e.code === 'ShiftLeft' || e.code === 'ShiftRight') F.boost = 3.4;
    });
    window.addEventListener('keyup', (e) => {
      F.keys.delete(e.code);
      if (e.code === 'ShiftLeft' || e.code === 'ShiftRight') F.boost = 1;
    });
    canvas.addEventListener('pointerdown', (e) => {
      if (this.mode !== 'free') return;
      F.dragging = true;
      canvas.setPointerCapture?.(e.pointerId);
    });
    canvas.addEventListener('pointerup', (e) => {
      F.dragging = false;
      canvas.releasePointerCapture?.(e.pointerId);
    });
    canvas.addEventListener('pointermove', (e) => {
      if (this.mode !== 'free' || !F.dragging) return;
      F.yaw -= e.movementX * 0.0026;
      F.pitch = clamp(F.pitch - e.movementY * 0.0026, -1.45, 1.45);
    });
    canvas.addEventListener('wheel', (e) => {
      if (this.mode !== 'free') return;
      F.speed = clamp(F.speed * (e.deltaY > 0 ? 0.88 : 1.14), 6, 900);
    }, { passive: true });
  }

  setMode(mode) {
    if (this.mode === mode) return;
    this.mode = mode;

    this.orbit.enabled = mode === 'orbit';
    if (mode === 'orbit') {
      this.orbit.target.copy(this.focus);
      this.orbit.update();
    }

    if (mode === 'free') {
      // Adopt the current look direction so there's no jump.
      const dir = new THREE.Vector3();
      this.camera.getWorldDirection(dir);
      this.free.yaw = Math.atan2(-dir.x, -dir.z);
      this.free.pitch = Math.asin(clamp(dir.y, -1, 1));
    }

    if (mode === 'walk') this.walk.enter(WORLD.village);
    else this.walk.exit();

    bus.emit(EV.CAMERA_MODE, { mode });
  }

  addShake(amplitude = 1, duration = 0.6, frequency = 18) {
    this.shake.amp = Math.max(this.shake.amp, amplitude);
    this.shake.decay = 1 / Math.max(0.05, duration);
    this.shake.freq = frequency;
  }

  /** Cinematic/follow modes write here; the rig eases toward it. */
  setDesired(pos, target, { smoothing, targetSmoothing, fov } = {}) {
    this.desired.copy(pos);
    this.desiredTarget.copy(target);
    if (smoothing != null) this.smoothing = smoothing;
    if (targetSmoothing != null) this.targetSmoothing = targetSmoothing;
    if (fov != null) this.fovTarget = fov;
  }

  update(dt, { dragon } = {}) {
    switch (this.mode) {
      case 'orbit':
        this.orbit.update();
        this.focus.copy(this.orbit.target);
        break;

      case 'free':
        this._updateFree(dt);
        break;

      case 'walk':
        this.walk.update(dt);
        this.focus.copy(this.camera.position).addScaledVector(
          this.camera.getWorldDirection(new THREE.Vector3()), 40,
        );
        break;

      case 'follow':
        if (dragon) this._updateFollow(dt, dragon);
        this._applyDesired(dt);
        break;

      default:  // cinematic — desired set by the director
        this._applyDesired(dt);
        break;
    }

    this._applyShake(dt);

    // Lens.
    this.fov = damp(this.fov, this.fovTarget, 0.002, dt);
    if (Math.abs(this.camera.fov - this.fov) > 1e-3) {
      this.camera.fov = this.fov;
      this.camera.updateProjectionMatrix();
    }
  }

  _applyDesired(dt) {
    dampVec3(this.camera.position, this.desired, this.smoothing, dt);
    dampVec3(this.focus, this.desiredTarget, this.targetSmoothing, dt);
    // Keep the lens out of the ground. The terrain carries real small-scale
    // relief (rib/terrace noise on the volcano flank especially), so sampling
    // it raw every frame and clamping instantly turned every passing bump into
    // a sharp camera pop — a chase low over rough ground read as turbulence.
    // Smoothing the floor itself lets the rig glide over that relief instead.
    const rawFloor = height(this.camera.position.x, this.camera.position.z) + 2.2;
    this._floorY = this._floorY == null ? rawFloor : damp(this._floorY, rawFloor, 0.02, dt);
    if (this.camera.position.y < this._floorY) this.camera.position.y = this._floorY;
    this.camera.lookAt(this.focus);
  }

  _updateFree(dt) {
    const F = this.free;
    const dir = new THREE.Vector3(
      -Math.sin(F.yaw) * Math.cos(F.pitch),
      Math.sin(F.pitch),
      -Math.cos(F.yaw) * Math.cos(F.pitch),
    );
    const right = new THREE.Vector3(Math.cos(F.yaw), 0, -Math.sin(F.yaw));
    const move = new THREE.Vector3();
    const k = F.keys;
    if (k.has('KeyW') || k.has('ArrowUp')) move.add(dir);
    if (k.has('KeyS') || k.has('ArrowDown')) move.sub(dir);
    if (k.has('KeyD') || k.has('ArrowRight')) move.add(right);
    if (k.has('KeyA') || k.has('ArrowLeft')) move.sub(right);
    if (k.has('KeyE') || k.has('Space')) move.y += 1;
    if (k.has('KeyQ') || k.has('ControlLeft')) move.y -= 1;
    if (move.lengthSq() > 0) move.normalize().multiplyScalar(F.speed * F.boost);

    dampVec3(F.vel, move, 0.0005, dt);
    this.camera.position.addScaledVector(F.vel, dt);

    const floor = height(this.camera.position.x, this.camera.position.z) + 3;
    if (this.camera.position.y < floor) this.camera.position.y = floor;

    this.focus.copy(this.camera.position).addScaledVector(dir, 120);
    this.camera.lookAt(this.focus);
  }

  /**
   * Chase cam.
   *
   * Sits behind, above and *off to one side*, on a spring, and leads the turn
   * so the dragon banks into frame instead of sliding out of it.
   *
   * The two things that made this shot unusable before:
   *
   *  · Distance. It sat 52–88 units back from a creature with a 143-unit
   *    wingspan, so the wings ran off both edges of the frame and the shot was
   *    an abstract close-up of a shoulder. Framing has to be driven by the
   *    subject's size, not by a constant, so the offsets below are expressed
   *    in wingspans.
   *  · Angle. It sat *directly* behind, which is the one angle from which a
   *    flyer reads as a silhouette with no depth — you see tail and the backs
   *    of both wings, and the animation may as well not be running. Pushing it
   *    round to a three-quarter rear puts one wing near and one far, which is
   *    what gives the shot parallax and makes the flapping legible.
   */
  _updateFollow(dt, dragon) {
    const p = dragon.pos;
    const fwd = dragon.forward.clone().normalize();
    const speed = dragon.vel.length();
    const fast = clamp(speed / 80, 0, 1);

    // Frame relative to the creature. ~90 units of half-span at scale 1.35.
    const SPAN = 90;
    const back = SPAN * lerp(1.35, 2.05, fast);
    const up = SPAN * lerp(0.26, 0.42, fast);
    const side = SPAN * 0.62;

    const worldUp = new THREE.Vector3(0, 1, 0);
    const right = new THREE.Vector3().crossVectors(worldUp, fwd).normalize();

    // Three-quarter rear, drifting to the outside of the turn with the bank.
    const desired = p.clone()
      .addScaledVector(fwd, -back)
      .addScaledVector(right, side + dragon.bank * 46)
      .addScaledVector(worldUp, up);

    const ground = height(desired.x, desired.z) + 22;
    desired.y = Math.max(desired.y, ground);

    // Look slightly ahead of the creature so it sits back in frame with room
    // to fly into, rather than pinned dead centre.
    const target = p.clone().addScaledVector(fwd, SPAN * 0.34);
    this.setDesired(desired, target, {
      smoothing: 0.0016, targetSmoothing: 0.0009,
      fov: lerp(44, 54, fast),
    });
  }

  _applyShake(dt) {
    // Undo last frame's offset so shake never accumulates into drift.
    this.camera.position.sub(this._shakeOffset);
    this._shakeOffset.set(0, 0, 0);

    this._noiseT += dt;
    const s = this.shake;
    if (s.amp > 0.0001) {
      s.t += dt;
      s.amp = Math.max(0, s.amp - s.decay * dt * s.amp * 2.2 - 0.02 * dt);
      const f = s.freq;
      const a = s.amp;
      this._shakeOffset.set(
        Math.sin(s.t * f * 1.00 + 1.3) * a,
        Math.sin(s.t * f * 1.37 + 2.1) * a * 0.85,
        Math.sin(s.t * f * 0.83 + 3.7) * a * 0.6,
      );
      this._rollOffset = Math.sin(s.t * f * 0.61) * a * 0.006;
    } else {
      this._rollOffset = damp(this._rollOffset, 0, 0.0001, dt);
    }

    // Handheld: slow, small, always there. Sells "operator" over "gimbal".
    if (this.handheld > 0 && this.mode !== 'walk') {
      const t = this._noiseT;
      const hs = this.handheld;
      this._shakeOffset.x += Math.sin(t * 0.63) * Math.sin(t * 0.21) * hs * 0.42;
      this._shakeOffset.y += Math.sin(t * 0.51 + 1.7) * Math.sin(t * 0.17) * hs * 0.34;
      this._shakeOffset.z += Math.sin(t * 0.44 + 3.1) * hs * 0.22;
    }

    this.camera.position.add(this._shakeOffset);
    // Roll last: every mode has already resolved orientation via lookAt, so a
    // local Z rotation is a clean dutch-tilt on top of it.
    if (Math.abs(this._rollOffset) > 1e-5) this.camera.rotateZ(this._rollOffset);
  }

  resize(aspect) {
    this.camera.aspect = aspect;
    this.camera.updateProjectionMatrix();
  }
}
