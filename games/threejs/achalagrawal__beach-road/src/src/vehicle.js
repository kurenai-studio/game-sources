// Arcade car physics on an endless road, plus the driver layer: manual, cruise control and autodrive.
// Steering convention: positive steer turns right. Car forward is (-sin yaw, -cos yaw) in xz.
import { roadX, roadXd, roadY, curvature, heading, LANE, ROAD_HALF, EDGE } from './road.js';

const G = 9.81;
const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
const wrap = (a) => Math.atan2(Math.sin(a), Math.cos(a));

export class Vehicle {
  constructor(spec) {
    this.x = 0; this.z = 0; this.y = 0; this.yaw = 0; this.v = 0;
    this.steer = 0; this.yawRate = 0; this.pitch = 0; this.roll = 0;
    this.gear = 0; this.rpm = 800; this.shiftTimer = 0;
    this.throttle = 0; this.brake = 0;
    this.onShoulder = false; this.impact = 0; this.stuck = 0;
    this.setSpec(spec);
  }

  setSpec(spec) {
    this.spec = spec;
    this.vmax = spec.stats.topSpeed / 3.6;
    const n = spec.engine.character === 'electric' ? 1 : Math.max(1, spec.engine.gears);
    this.gearTops = Array.from({ length: n }, (_, i) => this.vmax * ((i + 1) / n) ** 0.8);
    this.gear = Math.min(this.gear, n - 1);
  }

  place(z, lane, dir) {
    this.z = z;
    this.x = roadX(z) + lane;
    this.yaw = heading(z, dir);
    this.y = roadY(z);
    this.v = 0;
    this.steer = 0;
  }

  // How far the car points away from the road direction it is closest to (0 = aligned).
  get misalignment() {
    return Math.abs(wrap(this.yaw - heading(this.z, this.dir)));
  }

  // Put the car back in the right-hand lane, facing along the road the way it was mostly heading.
  recover() {
    const dir = this.dir;
    this.place(this.z, (dir < 0 ? 1 : -1) * LANE, dir);
    this.stuck = 0;
  }

  get fx() { return -Math.sin(this.yaw); }
  get fz() { return -Math.cos(this.yaw); }
  // Travel direction along z based on where the car faces (-1 = toward -z, the default).
  get dir() { return this.fz < 0 ? -1 : 1; }
  get offset() { return this.x - roadX(this.z); }

  // Full lock at walking pace; at speed, only as much angle as the tyres can hold
  // (lateral grip of roughly 0.8-1g, so full steer at 80 km/h is a ~60 m turn).
  maxSteerNow() {
    const S = this.spec.stats, v = Math.abs(this.v);
    const aLat = 5 + 5 * S.grip;
    return Math.min(S.steer, Math.atan((aLat * this.spec.dims.wheelbase) / Math.max(v * v, 1)));
  }

  update(dt, c) {
    const S = this.spec.stats, v = this.v;
    this.throttle = c.throttle;
    this.brake = c.brake;

    const target = clamp(c.steer, -1, 1) * this.maxSteerNow();
    // The wheels swing to full lock in about a quarter second whatever the lock is, so they feel the same at any speed.
    const slew = Math.max(this.maxSteerNow(), 0.05) * 4 * dt;
    this.steer += clamp(target - this.steer, -slew, slew);

    let a = 0;
    if (c.throttle > 0) a += v >= -0.3 ? S.accel * c.throttle * Math.max(0, 1 - (v / this.vmax) ** 2.5) : S.brake * c.throttle;
    if (c.brake > 0) a -= v > 0.3 ? S.brake * c.brake : (v > -6 ? S.accel * 0.6 * c.brake : 0);
    const resist = 0.12 + (this.onShoulder ? 1.1 : 0) + 0.00045 * v * v + (c.throttle < 0.05 && v > 0 ? 0.3 + 0.5 * v / this.vmax : 0);
    a -= G * Math.sin(this.pitch) * 0.6;
    let nv = v + a * dt;
    // Resistance can only slow the car down, never push it back through zero.
    nv = nv > 0 ? Math.max(0, nv - resist * dt) : Math.min(0, nv + resist * dt);
    if (Math.abs(nv) < 0.04 && c.throttle === 0 && c.brake === 0) nv = 0;
    this.v = nv;

    this.yawRate = -(this.v / this.spec.dims.wheelbase) * Math.tan(this.steer) * (0.85 + 0.15 * S.grip);
    this.yaw = wrap(this.yaw + this.yawRate * dt);
    this.x += this.fx * this.v * dt;
    this.z += this.fz * this.v * dt;

    // Soft road edges: slide along them instead of leaving the road.
    const rx = roadX(this.z), off = this.x - rx, lim = EDGE + 0.2;
    this.onShoulder = Math.abs(off) > ROAD_HALF - 0.3;
    this.impact = 0;
    if (Math.abs(off) <= lim) this.stuck = 0;
    else {
      this.x = rx + Math.sign(off) * lim;
      const roadYaw = heading(this.z, this.dir), delta = wrap(this.yaw - roadYaw);
      this.impact = Math.abs(this.v * Math.sin(delta));
      if (Math.abs(delta) > 1.2) {
        // Nose into the barrier: stop. Reversing gets out; keep pushing forward and the car rights itself.
        this.v = 0;
        this.stuck += c.throttle > 0.3 ? dt : 0;
        if (this.stuck > 1.2) this.recover();
      } else {
        // Keep only the speed along the barrier, scrape a little, and point slightly back inward.
        this.v *= Math.cos(delta);
        this.v -= Math.sign(this.v) * Math.min(Math.abs(this.v), 1.5 * dt);
        // Of the two headings either side of the road direction, take the one that moves the car
        // back toward the centre line (measured relative to the curving road, not world x).
        const e = 0.03, s = Math.sign(this.v || 1), slope = roadXd(this.z);
        const offRate = (y) => (-Math.sin(y) + slope * Math.cos(y)) * s;
        this.yaw = Math.sign(offRate(roadYaw + e)) === -Math.sign(off) ? roadYaw + e : roadYaw - e;
      }
    }

    const yf = roadY(this.z + this.fz * 1.4), yb = roadY(this.z - this.fz * 1.4);
    this.pitch = Math.atan2(yf - yb, 2.8);
    this.y = roadY(this.z);
    this.roll += (clamp(this.yawRate * this.v * 0.012, -0.06, 0.06) - this.roll) * Math.min(1, dt * 5);

    this.updateEngine(dt);
  }

  updateEngine(dt) {
    const e = this.spec.engine, n = this.gearTops.length, speed = Math.abs(this.v);
    this.shiftTimer = Math.max(0, this.shiftTimer - dt);
    if (this.shiftTimer === 0) {
      if (this.gear < n - 1 && speed > this.gearTops[this.gear] * 0.92) { this.gear++; this.shiftTimer = 0.35; }
      else if (this.gear > 0 && speed < this.gearTops[this.gear - 1] * 0.6) { this.gear--; this.shiftTimer = 0.25; }
    }
    const frac = clamp(speed / this.gearTops[this.gear], 0, 1);
    let target = e.idle + (e.redline - e.idle) * 0.95 * frac ** 0.9;
    if (speed < 0.5) target = e.idle + this.throttle * 1400;
    if (this.shiftTimer > 0.2) target *= 0.85;
    this.rpm += (target - this.rpm) * Math.min(1, dt * 8);
  }

  get gearLabel() {
    if (this.v < -0.3) return 'R';
    if (Math.abs(this.v) < 0.3 && this.throttle === 0) return 'N';
    return this.gearTops.length === 1 ? 'D' : `D${this.gear + 1}`;
  }
}

// ---------------------------------------------------------------- driver

export const MODES = { manual: 'Manual', cruise: 'Cruise', auto: 'Autodrive' };

export class Driver {
  constructor(vehicle) {
    this.car = vehicle;
    this.mode = 'manual';
    this.setSpeed = 22;
    this.laneOff = LANE;
    this.overtaking = null;
    this.integral = 0;
    this.boosting = false;
    this.onEvent = () => {};
  }

  setMode(mode) {
    if (mode === this.mode) return;
    if (mode !== 'manual' && this.mode === 'manual') this.setSpeed = Math.max(this.car.v, 8);
    if (mode === 'auto') this.laneOff = this.car.offset;
    this.mode = mode;
    this.overtaking = null;
    this.integral = 0;
  }

  toggleAuto() { this.setMode(this.mode === 'auto' ? 'manual' : 'auto'); }
  toggleCruise() { this.setMode(this.mode === 'manual' ? 'cruise' : 'manual'); }
  adjustSpeed(delta) {
    this.setSpeed = clamp(this.setSpeed + delta, 3, this.car.vmax);
    if (this.mode === 'manual') this.setMode('cruise');
  }

  holdSpeed(target, dt) {
    const err = target - this.car.v;
    this.integral = clamp(this.integral + err * dt, -4, 8);
    const throttle = clamp(0.45 * err + 0.08 * this.integral + 0.05, 0, 1);
    const brake = err < -1.5 ? clamp(-err * 0.2, 0, 0.8) : 0;
    return { throttle: brake > 0 ? 0 : throttle, brake };
  }

  update(dt, input, traffic) {
    const car = this.car;
    if (this.mode === 'manual') return input;

    if (input.brake > 0.1) {
      this.onEvent(this.mode === 'auto' ? 'auto-off' : 'cruise-off');
      this.setMode('manual');
      return input;
    }
    if (this.mode === 'auto' && Math.abs(input.steer) > 0.35) {
      this.onEvent('auto-to-cruise');
      this.setMode('cruise');
    }
    // Pressing the throttle overrides; letting go keeps the faster speed.
    if (input.throttle > 0.1) this.boosting = true;
    else if (this.boosting) {
      this.boosting = false;
      if (car.v > this.setSpeed + 0.5) this.setSpeed = Math.min(car.v, car.vmax);
    }

    let target = this.setSpeed, steer = input.steer;
    if (this.mode === 'auto') {
      const plan = this.autopilot(dt, traffic);
      steer = plan.steer;
      target = plan.speed;
    }
    const ctl = this.holdSpeed(target, dt);
    if (this.boosting) { ctl.throttle = Math.max(ctl.throttle, input.throttle); ctl.brake = 0; }
    return { throttle: ctl.throttle, brake: ctl.brake, steer };
  }

  autopilot(dt, traffic) {
    const car = this.car;
    // Autodrive can't steer a car that is sideways or stopped across the road, so straighten it up first.
    if (car.misalignment > 1.0 && Math.abs(car.v) < 6) {
      car.recover();
      this.laneOff = car.offset;
    }
    const dir = car.dir, v = Math.max(car.v, 0);
    const home = (dir < 0 ? 1 : -1) * LANE; // keep right

    // Speed limits from curves ahead.
    let kMax = 0, kFar = 0;
    for (let s = 0; s <= 80; s += 20) kMax = Math.max(kMax, curvature(car.z + dir * s));
    for (let s = 80; s <= 240; s += 40) kFar = Math.max(kFar, curvature(car.z + dir * s));
    let speed = Math.min(this.setSpeed, Math.sqrt(3.2 / Math.max(kMax, 1e-5)));

    const leader = traffic.leader(car.z, dir, home, this.overtaking);
    if (this.overtaking) {
      const rel = traffic.relativePosition(this.overtaking, car.z, dir);
      const blocked = !traffic.oncomingClear(car.z, dir, -home, 140);
      if (rel === null || rel < -14 || (blocked && rel > 4)) this.overtaking = null;
      else speed = Math.min(this.setSpeed + 3, car.vmax);
    } else if (leader) {
      const want = 10 + 1.5 * v;
      speed = Math.min(speed, Math.max(0, leader.speed + (leader.gap - want) * 0.35));
      if (leader.gap < 55 && leader.speed < this.setSpeed - 2.5 && kFar < 1 / 380 && kMax < 1 / 380
        && traffic.oncomingClear(car.z, dir, -home, 340) && traffic.laneClear(car.z, dir, -home, 25)) {
        this.overtaking = leader.id;
        this.onEvent('overtake');
      }
    }

    const targetOff = this.overtaking ? -home : home;
    this.laneOff += clamp(targetOff - this.laneOff, -1.6 * dt, 1.6 * dt);

    // Pure pursuit toward a point on the target lane ahead.
    const ld = clamp(7 + v * 0.8, 7, 40);
    const zt = car.z + dir * ld, xt = roadX(zt) + this.laneOff;
    const dx = xt - car.x, dz = zt - car.z;
    const rightX = -car.fz, rightZ = car.fx;
    const alpha = Math.atan2(dx * rightX + dz * rightZ, dx * car.fx + dz * car.fz);
    const delta = Math.atan((2 * car.spec.dims.wheelbase * Math.sin(alpha)) / ld);
    return { steer: clamp(delta / car.maxSteerNow(), -1, 1), speed };
  }
}
