import * as THREE from 'three';

export const TAU = Math.PI * 2;

export const clamp   = (v, a, b) => (v < a ? a : v > b ? b : v);
export const lerp    = (a, b, t) => a + (b - a) * t;
export const invLerp  = (a, b, v) => (v - a) / (b - a);
export const saturate = (v) => clamp(v, 0, 1);

/** Smoothstep with clamping — the ubiquitous falloff. */
export const smoothstep = (e0, e1, x) => {
  const t = saturate((x - e0) / (e1 - e0 || 1e-6));
  return t * t * (3 - 2 * t);
};

export const smootherstep = (e0, e1, x) => {
  const t = saturate((x - e0) / (e1 - e0 || 1e-6));
  return t * t * t * (t * (t * 6 - 15) + 10);
};

/**
 * Frame-rate independent exponential approach.
 * `smoothing` = fraction of the remaining distance left after 1 second.
 */
export const damp = (current, target, smoothing, dt) =>
  lerp(current, target, 1 - Math.pow(smoothing, dt));

export const dampVec3 = (v, target, smoothing, dt) => {
  const t = 1 - Math.pow(smoothing, dt);
  v.x = lerp(v.x, target.x, t);
  v.y = lerp(v.y, target.y, t);
  v.z = lerp(v.z, target.z, t);
  return v;
};

/**
 * Damped spring — used for the dragon's neck & tail chain.
 *
 * Integrated on a *fixed* internal timestep with an accumulator, and that
 * detail is the whole point of this class.
 *
 * The previous version sub-stepped with `steps = min(4, ceil(dt / (1/90)))`
 * and `h = dt / steps`, which makes the integration step size a discontinuous
 * function of the frame time: a frame at 22.3 ms uses 3 sub-steps of 7.4 ms,
 * the next at 21.9 ms uses 2 of 11.0 ms. Explicit integration of a stiff
 * spring is quite sensitive to h, so the effective damping changed frame to
 * frame with the browser's natural frame-time jitter, and the whole spine
 * chain — every node of which runs one of these — twitched. Measured against
 * a constant-dt reference over 2 s of tracking a moving target, realistic
 * frame jitter produced 8x the frame-to-frame jerk (0.350 vs 0.043) and up to
 * 0.70 units of positional deviation. That was the in-flight "turbulence".
 *
 * With a fixed h the trajectory is identical no matter how the frame times
 * fall, so the only thing left moving the creature is the animation itself.
 */
export class Spring3 {
  constructor(position = new THREE.Vector3(), stiffness = 90, damping = 14) {
    this.value    = position.clone();
    this.velocity = new THREE.Vector3();
    this.stiffness = stiffness;
    this.damping   = damping;
    this._coeffDt = -1;      // cached coefficients are valid for this dt
    this._c = { p: 0, pv: 0, v: 0, vp: 0 };
  }

  /**
   * Advance the spring exactly, using the closed-form solution of the damped
   * harmonic oscillator over the interval.
   *
   * Taking the target as constant across a frame (it is — it's recomputed once
   * per frame), the error e = value - target obeys e'' + d·e' + k·e = 0, which
   * has an exact solution. So instead of integrating numerically we evaluate
   * that solution at `dt`. The result is *analytically* frame-rate independent:
   * two frames of 8 ms produce bit-for-bit the trajectory of one frame of
   * 16 ms, at any frame time, with no sub-stepping and no accumulator.
   *
   * That property is the entire reason this exists. The original stepped
   * explicitly with `steps = min(4, ceil(dt / (1/90)))` and `h = dt / steps`,
   * making the integration step a discontinuous function of frame time — a
   * 22.3 ms frame took 3 steps of 7.4 ms, a 21.9 ms frame took 2 of 11.0 ms,
   * and since an explicit integrator's effective damping depends on h, the
   * spine's response changed frame to frame with the browser's ordinary frame
   * jitter. Every node of the dragon's spine runs one of these, so the whole
   * body twitched: the in-flight "turbulence".
   *
   * (An intermediate attempt used a fixed timestep with an accumulator. That
   * fixes determinism but not smoothness — the sim then advances in whole
   * 1/180 chunks while frames do not, so the *rendered* pose still lurches.
   * Measured, it was worse than what it replaced. The closed form has neither
   * problem.)
   */
  step(target, dt) {
    if (dt <= 0) return this.value;

    // Coefficients depend only on (k, d, dt); frame times repeat, so cache.
    if (dt !== this._coeffDt) {
      this._coeffDt = dt;
      const k = this.stiffness;
      const d = this.damping;
      const a = d * 0.5;
      const disc = d * d - 4 * k;
      const c = this._c;

      if (disc < -1e-9) {
        // Underdamped — the usual case for these constants.
        const wd = Math.sqrt(k - a * a);
        const e = Math.exp(-a * dt);
        const co = Math.cos(wd * dt);
        const si = Math.sin(wd * dt);
        c.p  = e * (co + (a / wd) * si);          // e(dt) from e0
        c.pv = e * (si / wd);                     // e(dt) from v0
        c.v  = e * (-(k / wd) * si);              // v(dt) from e0
        c.vv = e * (co - (a / wd) * si);          // v(dt) from v0
      } else if (disc > 1e-9) {
        // Overdamped.
        const r = Math.sqrt(disc) * 0.5;
        const r1 = -a + r;
        const r2 = -a - r;
        const e1 = Math.exp(r1 * dt);
        const e2 = Math.exp(r2 * dt);
        const inv = 1 / (r1 - r2);
        c.p  = (r1 * e2 - r2 * e1) * inv;
        c.pv = (e1 - e2) * inv;
        c.v  = r1 * r2 * (e2 - e1) * inv;
        c.vv = (r1 * e1 - r2 * e2) * inv;
      } else {
        // Critically damped.
        const e = Math.exp(-a * dt);
        c.p  = e * (1 + a * dt);
        c.pv = e * dt;
        c.v  = e * (-a * a * dt);
        c.vv = e * (1 - a * dt);
      }
    }

    const c = this._c;
    const ex = this.value.x - target.x;
    const ey = this.value.y - target.y;
    const ez = this.value.z - target.z;
    const vx = this.velocity.x;
    const vy = this.velocity.y;
    const vz = this.velocity.z;

    this.value.set(
      target.x + ex * c.p + vx * c.pv,
      target.y + ey * c.p + vy * c.pv,
      target.z + ez * c.p + vz * c.pv,
    );
    this.velocity.set(
      ex * c.v + vx * c.vv,
      ey * c.v + vy * c.vv,
      ez * c.v + vz * c.vv,
    );
    return this.value;
  }
}

/** Deterministic pseudo-random from an integer — for stable per-instance jitter. */
export const hash11 = (n) => {
  let x = Math.sin(n * 127.1) * 43758.5453123;
  return x - Math.floor(x);
};
export const hash21 = (a, b) => {
  const x = Math.sin(a * 127.1 + b * 311.7) * 43758.5453123;
  return x - Math.floor(x);
};

/** Blue-noise-ish scatter: Mitchell's best-candidate, cheap and good enough. */
export function scatterPoints({ count, radius, center = [0, 0], minDist = 0, rng, reject }) {
  const pts = [];
  let guard = count * 60;
  while (pts.length < count && guard-- > 0) {
    const a = rng() * TAU;
    const r = radius * Math.sqrt(rng());
    const x = center[0] + Math.cos(a) * r;
    const z = center[1] + Math.sin(a) * r;
    if (reject && reject(x, z)) continue;
    if (minDist > 0) {
      let ok = true;
      for (let i = pts.length - 1; i >= 0; i--) {
        const dx = pts[i][0] - x, dz = pts[i][1] - z;
        if (dx * dx + dz * dz < minDist * minDist) { ok = false; break; }
      }
      if (!ok) continue;
    }
    pts.push([x, z]);
  }
  return pts;
}

export const wrap = (v, min, max) => {
  const span = max - min;
  return min + ((((v - min) % span) + span) % span);
};

/** Project a world point to normalised screen space [0..1]. */
const _p = new THREE.Vector3();
export function worldToScreen(world, camera, out = new THREE.Vector2()) {
  _p.copy(world).project(camera);
  out.set(_p.x * 0.5 + 0.5, _p.y * 0.5 + 0.5);
  return out;
}
export function isInFrontOf(world, camera) {
  _p.copy(world).project(camera);
  return _p.z < 1;
}
