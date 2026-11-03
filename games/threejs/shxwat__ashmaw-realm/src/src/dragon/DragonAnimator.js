/**
 * The performance layer: what Ashmaw *does*.
 *
 * A small state machine drives a single continuous flight solver. States never
 * teleport the creature — they only change target altitude, speed, flap
 * amplitude and wing spread, and GSAP eases those scalars. The body then follows
 * physically, so transitions (a dive into a circle, a flare into a landing) come
 * out looking authored without anyone authoring them.
 *
 * States
 *  circle   — banked orbit of the volcano, the default idle
 *  cruise   — long transit along a spline (village flyby, castle approach)
 *  hover    — wings wide, high-amplitude slow flap, nose up
 *  land     — approach → flare → touchdown on the castle's great tower
 *  perched  — folded, breathing, head tracking the camera
 *  takeoff  — crouch → leap → two hard downstrokes → climb
 *  attack   — dive at a target, charge, breathe
 *
 * Banking is derived, not authored: we measure the turn rate of the velocity
 * vector and roll into it, exactly like a real flyer.
 */
import * as THREE from 'three';
import { gsap } from 'gsap';
import { bus, EV } from '../core/EventBus.js';
import { WORLD, height } from '../world/Heightfield.js';
import { TAU, clamp, lerp, damp, smoothstep } from '../utils/MathX.js';

export class DragonAnimator {
  constructor(dragon, { castle, village } = {}) {
    this.d = dragon;
    this.castle = castle;
    this.village = village;

    this.state = 'circle';
    this.t = 0;

    // Flight state.
    this.pos = new THREE.Vector3(WORLD.volcano.x + 430, 330, WORLD.volcano.z + 120);
    this.vel = new THREE.Vector3(0, 0, -46);
    this.forward = new THREE.Vector3(0, 0, -1);
    this.bank = 0;
    this.targetPoint = new THREE.Vector3();

    // Animated scalars (GSAP owns these).
    this.p = {
      speed: 46,
      altitude: 320,
      flapAmp: 1.0,
      flapSpeed: 1.05,
      wingSpread: 1.0,
      neckLook: 0.15,
      mouthOpen: 0.0,
      legTuck: 1.0,
      charge: 0.0,
      orbitRadius: 430,
      turnGain: 1.0,
    };

    this.orbitAngle = 0.6;
    /** Ellipse squash on the orbit's z axis — varied per flight member so
     *  several circling wyrms never trace the same path. */
    this.orbitRatio = 0.88;
    this.circleCenter = new THREE.Vector3(WORLD.volcano.x, 0, WORLD.volcano.z);
    this._tl = null;
    this.onBreath = null;
  }

  /* ── public commands ─────────────────────────────────────────────── */

  setState(s) {
    if (this.state === s) return;
    this.state = s;
    this.t = 0;
    bus.emit(EV.DRAGON_STATE, { state: s });
  }

  circle({ center = this.circleCenter, radius = 430, altitude = 330, speed = 48 } = {}) {
    this._kill();
    this.circleCenter.copy(center);
    this.setState('circle');
    gsap.to(this.p, {
      duration: 3.2, ease: 'power2.inOut',
      speed, altitude, orbitRadius: radius,
      flapAmp: 1.0, flapSpeed: 1.05, wingSpread: 1.0,
      neckLook: 0.15, legTuck: 1, mouthOpen: 0, charge: 0,
    });
  }

  /** Long transit: fly a spline, then resume circling. */
  cruise(points, { speed = 62, then = 'circle' } = {}) {
    this._kill();
    this.setState('cruise');
    this.path = new THREE.CatmullRomCurve3(points, false, 'catmullrom', 0.35);
    this.pathU = 0;
    this.pathLen = this.path.getLength();
    this.pathThen = then;
    gsap.to(this.p, {
      duration: 2.0, ease: 'power2.out',
      speed, flapAmp: 0.82, flapSpeed: 0.95, wingSpread: 1.0, legTuck: 1, neckLook: 0.1,
    });
  }

  hover({ at = null, altitude = null } = {}) {
    this._kill();
    this.setState('hover');
    if (at) this.hoverPoint = at.clone();
    else this.hoverPoint = this.pos.clone();
    gsap.to(this.p, {
      duration: 2.4, ease: 'power2.out',
      speed: 6, altitude: altitude ?? this.hoverPoint.y,
      flapAmp: 1.5, flapSpeed: 0.62, wingSpread: 1.0, neckLook: 0.5, legTuck: 0.4,
    });
  }

  /** Full landing sequence onto the castle tower (or any point). */
  land(target = this.castle?.perch) {
    if (!target || this.state === 'land' || this.state === 'perched') return;
    this._kill();
    this.setState('land');
    this.landTarget = target.clone();

    const tl = gsap.timeline();
    // 1. Bleed speed, drop the gear, widen the wings.
    tl.to(this.p, {
      duration: 2.6, ease: 'power2.inOut',
      speed: 26, flapAmp: 0.55, flapSpeed: 0.7, wingSpread: 1.0, legTuck: 0.15, neckLook: 0.35,
    });
    // 2. Flare: nose up, wings cupped, big slow beats.
    tl.to(this.p, {
      duration: 1.6, ease: 'power1.out',
      speed: 7, flapAmp: 1.7, flapSpeed: 0.5, legTuck: 0.0, neckLook: 0.75,
    });
    // 3. Settle.
    tl.to(this.p, {
      duration: 1.2, ease: 'power2.out',
      speed: 0.6, flapAmp: 0.25, flapSpeed: 0.5, wingSpread: 0.12, neckLook: 0.3,
      onComplete: () => {
        this.setState('perched');
        bus.emit(EV.SHAKE, { amplitude: 0.55, duration: 0.9, frequency: 16 });
      },
    });
    this._tl = tl;
  }

  takeoff() {
    if (this.state === 'takeoff') return;
    this._kill();
    const wasPerched = this.state === 'perched';
    this.setState('takeoff');

    const tl = gsap.timeline();
    if (wasPerched) {
      // Crouch — load the legs.
      tl.to(this.p, { duration: 0.55, ease: 'power2.in', legTuck: 0.0, wingSpread: 0.3, neckLook: 0.05 });
      // Leap + first downstroke.
      tl.to(this.p, {
        duration: 0.5, ease: 'power3.out',
        wingSpread: 1.0, flapAmp: 2.1, flapSpeed: 1.5, speed: 22, legTuck: 0.2,
        onStart: () => bus.emit(EV.SHAKE, { amplitude: 0.9, duration: 0.6, frequency: 18 }),
      });
    }
    // Hard climb.
    tl.to(this.p, {
      duration: 3.4, ease: 'power2.out',
      speed: 54, altitude: 340, flapAmp: 1.45, flapSpeed: 1.35, legTuck: 1, neckLook: 0.3,
    });
    tl.call(() => this.circle({ radius: 430, altitude: 330, speed: 50 }));
    this._tl = tl;
  }

  /** Dive at a point, charge, and breathe fire. */
  attack(target, { duration = 3.4 } = {}) {
    this._kill();
    this.setState('attack');
    this.attackTarget = (target ?? this.village?.plaza ?? new THREE.Vector3()).clone();

    const tl = gsap.timeline();
    tl.to(this.p, {
      duration: 1.6, ease: 'power2.in',
      speed: 78, altitude: this.attackTarget.y + 120, flapAmp: 0.45, flapSpeed: 0.8,
      wingSpread: 0.86, neckLook: 0.55, legTuck: 1,
    });
    // Inhale — throat lights up before anything comes out.
    tl.to(this.p, { duration: 0.85, ease: 'power2.in', charge: 1.0, mouthOpen: 0.25, neckLook: 0.85 });
    tl.call(() => {
      this.p.charge = 1;
      this.onBreath?.(duration);
    });
    tl.to(this.p, { duration: 0.22, mouthOpen: 1.0 });
    tl.to(this.p, {
      duration, ease: 'none',
      speed: 42, flapAmp: 1.0, flapSpeed: 1.0,
    });
    tl.to(this.p, { duration: 0.6, mouthOpen: 0, charge: 0, neckLook: 0.2 });
    tl.call(() => this.circle({ radius: 430, altitude: 330, speed: 50 }));
    this._tl = tl;
  }

  roar() {
    const tl = gsap.timeline();
    tl.to(this.p, { duration: 0.4, ease: 'power2.out', neckLook: 0.95, mouthOpen: 0.9, charge: 0.5 });
    tl.to(this.p, { duration: 1.1, ease: 'power2.inOut', mouthOpen: 0.55 });
    tl.to(this.p, { duration: 0.7, mouthOpen: 0, charge: 0, neckLook: 0.25 });
    bus.emit(EV.SHAKE, { amplitude: 0.35, duration: 1.4, frequency: 9 });
    // The wave leaves the jaws as they hit full gape.
    tl.call(() => bus.emit(EV.ROAR, { origin: this.pos.clone() }), null, 0.35);
    return tl;
  }

  _kill() {
    this._tl?.kill();
    gsap.killTweensOf(this.p);
  }

  /* ── the solver ──────────────────────────────────────────────────── */

  update(dt, camera) {
    this.t += dt;
    const P = this.p;
    const desired = new THREE.Vector3();

    switch (this.state) {
      case 'circle': {
        const c = this.circleCenter;
        const r = Math.max(40, P.orbitRadius);
        const ry = this.orbitRatio;

        /**
         * Advance the orbit by *arc length*.
         *
         * The old form was `orbitAngle += speed / r * dt`, which is only the
         * arc-length rate when the orbit is a circle. The path is an ellipse
         * (r, r·ry), whose speed per unit angle is r·√(sin²θ + ry²cos²θ) — so
         * with a constant dθ/dt the target point slowed to ry of its nominal
         * speed near the minor axis and ran at full speed near the major one.
         *
         * The body, meanwhile, is held at a constant P.speed by the velocity
         * clamp below. So on every lap it overtook the target through the slow
         * arc and fell behind through the fast one, and the solver spent the
         * whole orbit correcting a lead/lag error that never settled. That
         * error is what the body reads as a turn, so the creature rolled back
         * and forth continuously: bank on the most eccentric wyrm (ry = 0.74)
         * swung across ±0.75 rad, while the roundest (ry = 0.92) barely moved.
         * The eccentricity correlated with the wobble because it *was* the
         * wobble.
         *
         * Dividing by the true |dP/dθ| makes the target travel at a constant
         * P.speed all the way round, so there is nothing left to chase.
         */
        const s = Math.sin(this.orbitAngle);
        const cs = Math.cos(this.orbitAngle);
        const dPdTheta = Math.max(1e-3, r * Math.sqrt(s * s + ry * ry * cs * cs));
        this.orbitAngle += (P.speed / dPdTheta) * dt;

        desired.set(
          c.x + Math.cos(this.orbitAngle) * r,
          P.altitude + Math.sin(this.orbitAngle * 2.1) * 26,
          c.z + Math.sin(this.orbitAngle) * r * ry,
        );
        break;
      }
      case 'cruise': {
        this.pathU = Math.min(1, this.pathU + (P.speed * dt) / this.pathLen);
        this.path.getPointAt(this.pathU, desired);
        if (this.pathU >= 1 - 1e-4) {
          if (this.pathThen === 'land') this.land();
          else this.circle({ radius: 430, altitude: 330, speed: 50 });
        }
        break;
      }
      case 'hover': {
        desired.copy(this.hoverPoint);
        desired.y = P.altitude + Math.sin(this.t * 0.9) * 5;
        break;
      }
      case 'land': {
        const tgt = this.landTarget;
        // Curved approach: come in downwind, aligned with the tower.
        const toTarget = new THREE.Vector3().subVectors(tgt, this.pos);
        const dist = toTarget.length();
        const approach = clamp(dist / 220, 0, 1);
        desired.copy(tgt)
          .addScaledVector(this.forward.clone().setY(0).normalize(), -approach * 90)
          .setY(lerp(tgt.y + 3, tgt.y + 90, approach));
        break;
      }
      case 'perched': {
        desired.copy(this.landTarget ?? this.pos);
        desired.y += 0.4 * Math.sin(this.t * 0.9);   // breathing bob
        break;
      }
      case 'takeoff': {
        const base = this.landTarget ?? this.pos;
        const climb = smoothstep(0.4, 3.6, this.t);
        desired.copy(base)
          .addScaledVector(this.forward.clone().setY(0).normalize(), climb * 220)
          .setY(lerp(base.y, P.altitude, climb));
        break;
      }
      case 'pinned': {
        // Hold station exactly where placed — used by the shot tooling and by
        // anything that wants to freeze the creature without freezing the world.
        desired.copy(this.pos);
        break;
      }
      case 'attack': {
        const tgt = this.attackTarget;
        const toT = new THREE.Vector3().subVectors(tgt, this.pos);
        const flat = toT.clone().setY(0);
        const dist = flat.length();
        // Aim to level out ~120m above and 90m short, then overfly.
        const lead = Math.max(90, dist * 0.55);
        desired.copy(tgt)
          .add(flat.normalize().multiplyScalar(-lead))
          .setY(Math.max(tgt.y + 45, P.altitude));
        break;
      }
    }

    // ── steer ────────────────────────────────────────────────────────
    const toDesired = new THREE.Vector3().subVectors(desired, this.pos);
    const grounded = this.state === 'perched' || this.state === 'pinned';
    let steer = null;

    if (grounded) {
      this.pos.lerp(desired, 1 - Math.pow(0.0001, dt));
      this.vel.multiplyScalar(1 - 4 * dt);
    } else {
      steer = toDesired.clone().normalize().multiplyScalar(P.speed).sub(this.vel);
      const maxAccel = 46 * P.turnGain;
      if (steer.length() > maxAccel) steer.setLength(maxAccel);
      this.vel.addScaledVector(steer, dt * 1.6);

      // Clamp to the commanded speed and keep it out of the ground.
      const sp = this.vel.length();
      if (sp > 1e-4) this.vel.multiplyScalar(lerp(sp, Math.max(P.speed, 2), 1 - Math.pow(0.02, dt)) / sp);
      this.pos.addScaledVector(this.vel, dt);

      const ground = height(this.pos.x, this.pos.z) + 14;
      if (this.pos.y < ground) {
        this.pos.y = damp(this.pos.y, ground, 0.0005, dt);
        this.vel.y = Math.max(this.vel.y, 0);
      }
    }

    // ── orientation & banking ────────────────────────────────────────
    const fwdTarget = grounded
      ? this._perchedFacing(camera)
      : this.vel.clone().normalize();
    if (fwdTarget.lengthSq() > 1e-6) {
      this.forward.lerp(fwdTarget, 1 - Math.pow(0.0006, dt)).normalize();
    }

    /**
     * Bank angle — from the curvature of the *flown path*, not the control error.
     *
     * Two earlier attempts both produced a full-body wobble, because bank
     * rotates the entire body frame in Dragon.js:
     *
     *  1. `cross(prevForward, forward).y / dt` — a finite difference of an
     *     already-lerped vector divided by frame time. Pure derivative noise,
     *     amplified without bound as dt shrinks.
     *  2. The lateral component of `steer`. This looked principled but is
     *     worse than it appears: `steer` is desiredVelocity − velocity, i.e.
     *     the *control error*. Once the creature is tracking its orbit that is
     *     a small difference of two nearly-equal vectors, so its lateral
     *     component flips sign every time the solver over- or under-shoots.
     *     Measured on a background wyrm in steady circling flight, bank swung
     *     between −0.59 and +0.59 rad — sign-flipping continuously — with 40x
     *     the frame-to-frame jerk of the hero. (The hero *looked* fine only
     *     because its bank was saturated against the ±0.8 clamp, which pinned
     *     it and hid the same oscillation.)
     *
     * A real flyer's bank is set by the turn it is actually making, so that is
     * what gets measured here: low-pass the heading first, then take its turn
     * rate. Differentiating a smoothed signal is stable, where smoothing a
     * differentiated one is not — and a coordinated turn gives the bank angle
     * in closed form, tan(φ) = v·ω / g, so there is no arbitrary gain to tune
     * and the result is a physically correct angle rather than a scaled error.
     */
    let bankTarget = 0;
    if (!grounded && this.vel.lengthSq() > 4) {
      const dir = this.vel.clone().normalize();
      if (!this._bankDir) this._bankDir = dir.clone();

      const prev = this._bankDir.clone();
      // Frame-rate independent low-pass on the heading (~0.24 s time constant).
      this._bankDir.lerp(dir, 1 - Math.pow(0.015, dt)).normalize();

      // Signed turn rate about world up, in rad/s. Both operands are smoothed,
      // so this quotient stays bounded as dt varies.
      const cross = prev.x * this._bankDir.z - prev.z * this._bankDir.x;
      const dot = prev.x * this._bankDir.x + prev.z * this._bankDir.z;
      const omega = Math.atan2(cross, dot) / Math.max(dt, 1e-4);

      // Coordinated turn: tan(bank) = v·ω / g.
      const v = this.vel.length();
      bankTarget = clamp(Math.atan((omega * v) / 9.81), -0.85, 0.85);
    }
    // Long final smoothing (~0.35 s). Real aircraft roll into a turn over about
    // this long; it also filters whatever survives the steps above.
    this.bank = damp(this.bank, bankTarget, 0.06, dt);

    // ── pose the body ────────────────────────────────────────────────
    this.d.update(dt, {
      position: this.pos,
      forward: this.forward,
      bank: this.bank,
      speed: this.vel.length(),
      flapAmp: P.flapAmp * (grounded ? 0.12 : 1),
      flapSpeed: P.flapSpeed,
      wingSpread: P.wingSpread,
      neckLook: P.neckLook,
      mouthOpen: P.mouthOpen,
      legTuck: grounded ? 0 : P.legTuck,
      charge: P.charge,
    });
  }

  /** When perched, the head tracks whoever is watching. */
  _perchedFacing(camera) {
    if (!camera) return this.forward;
    const to = new THREE.Vector3().subVectors(camera.position, this.pos).setY(0);
    if (to.lengthSq() < 1) return this.forward;
    return to.normalize();
  }

  /** A cinematic village flyby, low and fast. */
  flyby() {
    const v = this.village?.plaza ?? new THREE.Vector3(0, 40, 0);
    const pts = [
      new THREE.Vector3(v.x + 620, v.y + 210, v.z - 520),
      new THREE.Vector3(v.x + 260, v.y + 120, v.z - 220),
      new THREE.Vector3(v.x + 40, v.y + 58, v.z + 20),
      new THREE.Vector3(v.x - 200, v.y + 74, v.z + 200),
      new THREE.Vector3(v.x - 520, v.y + 190, v.z + 420),
    ];
    this.cruise(pts, { speed: 74 });
  }
}
