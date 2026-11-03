/**
 * Vertical flight model of a hot air balloon (docs/research.md §a tuning table).
 *
 * `heat` is the envelope temperature relative to equilibrium (0 = neutral buoyancy). The burner
 * adds to it, venting dumps it, and it cools toward a slightly-below-neutral rest, so a balloon
 * left alone settles into a very slow sink. Lift follows heat through a first-order lag (the
 * envelope's thermal inertia, ~5 s; ~2 s while venting), and the vertical speed follows lift with
 * its own inertia (~3 s): a burn first stops a sink, then climbs, and keeps climbing after the flame
 * stops. Horizontal motion is the wind of the balloon's own altitude (see wind.ts).
 */
import * as THREE from "three";
import { windAt } from "./wind";

export const PHYS = {
  /** Heat gained per second of burner. A 4 s standard burn = +0.4 (about +2.4 m/s of climb). */
  burnRate: 0.1,
  /** Heat lost per second while venting. */
  ventRate: 0.08,
  /** Natural cooling: heat relaxes toward `restHeat` with this time constant (s). */
  coolTau: 25,
  /** Heat the envelope settles to with no input: a slow sink of restHeat * liftGain m/s. */
  restHeat: -0.06,
  /** Lift lag (s): heat to effective lift; shorter while venting (the crown dumps hot air at once). */
  liftTau: 5,
  liftTauVent: 2,
  /** Vertical-speed inertia (s). */
  velTau: 3,
  /** Target climb rate (m/s) per unit of lagged heat. */
  liftGain: 6,
  /** Soft (tanh) climb / sink scale and hard clamps (m/s). */
  softUp: 4.2,
  softDown: 3.6,
  maxUp: 5,
  maxDown: 4,
  /** Burner efficiency falls off over this altitude band (m); hard ceiling above it. */
  ceiling: [800, 1150] as [number, number],
  hardCeiling: 1200,
  /** Horizontal speed follows the wind with this time constant (s). */
  driftTau: 4,
  /** Below this height above ground (m) the sink is cushioned toward a gentle touchdown. */
  cushion: 10,
  /** Touchdown speed (m/s): the basket meets the ground no faster than this. */
  touch: 0.3,
  /** Basket pendulum: period (s), damping (1/s), max angle (rad). */
  swayPeriod: 7,
  swayDamp: 0.35,
  swayMax: 1.5 * (Math.PI / 180),
  /** Start: ~120 m over the fields west of the village, in equilibrium. */
  start: new THREE.Vector3(-520, 120, 140),
} as const;

const clamp = (x: number, a: number, b: number) => Math.min(b, Math.max(a, x));
const smooth = (a: number, b: number, x: number) => {
  const t = clamp((x - a) / (b - a), 0, 1);
  return t * t * (3 - 2 * t);
};

export class Flight {
  /** Basket floor centre, world metres. */
  readonly pos = PHYS.start.clone();
  /** World velocity (m/s). */
  readonly vel = new THREE.Vector3();
  /** Envelope heat relative to equilibrium, and its lagged effect on lift. */
  heat = 0;
  lift = 0;
  burner = false;
  vent = false;
  /** Heading of the basket (rad about y): a balloon turns slowly as it drifts. */
  yaw = 0;
  /** Sitting on the ground. */
  grounded = false;
  /** Basket sway angles (rad) about x and z, and their rates. */
  readonly sway = new THREE.Vector2();
  private readonly swayV = new THREE.Vector2();
  private wasBurning = false;
  private readonly wind = new THREE.Vector2();
  private readonly lastWind = new THREE.Vector2();

  constructor(private readonly ground: (x: number, z: number) => number) {
    this.pos.y = Math.max(this.pos.y, this.floor(this.pos.x, this.pos.z) + 5);
  }

  /** Ground or water surface under (x, z). */
  floor(x: number, z: number): number {
    return Math.max(this.ground(x, z), 0);
  }

  /** Height of the basket floor above the ground (m). */
  get agl(): number {
    return this.pos.y - this.floor(this.pos.x, this.pos.z);
  }

  /** Place the balloon; `y` is world height. Heat and vertical speed reset to level flight. */
  place(x: number, y: number, z: number, t = 0): void {
    this.pos.set(x, Math.max(y, this.floor(x, z)), z);
    this.heat = this.lift = 0;
    this.vel.set(0, 0, 0);
    windAt(x, y, z, t, this.wind);
    this.vel.x = this.wind.x;
    this.vel.z = this.wind.y;
    this.lastWind.copy(this.wind);
    this.grounded = this.agl < 0.05;
    this.sway.set(0, 0);
    this.swayV.set(0, 0);
  }

  step(dt: number, t: number): void {
    if (dt <= 0) return;
    const P = PHYS;
    // Envelope heat.
    const eff = 1 - smooth(P.ceiling[0], P.ceiling[1], this.pos.y);
    if (this.burner) this.heat += P.burnRate * eff * dt;
    if (this.vent) this.heat -= P.ventRate * dt;
    this.heat += (P.restHeat - this.heat) * (1 - Math.exp(-dt / P.coolTau));
    this.heat = clamp(this.heat, -1.2, 1.6);
    // Lagged lift and the vertical speed it asks for.
    const tau = this.vent ? P.liftTauVent : P.liftTau;
    this.lift += (this.heat - this.lift) * (1 - Math.exp(-dt / tau));
    const want = this.lift * P.liftGain;
    let vt = want >= 0 ? P.softUp * Math.tanh(want / P.softUp) : P.softDown * Math.tanh(want / P.softDown);
    vt = clamp(vt, -P.maxDown, P.maxUp);
    let vy = this.vel.y + (vt - this.vel.y) * (1 - Math.exp(-dt / P.velTau));
    // Ground cushion: the sink eases off near the ground so the basket touches down softly.
    const agl = this.agl;
    if (vy < 0 && agl < P.cushion) vy = Math.max(vy, -(P.touch + (agl / P.cushion) * (P.maxDown - P.touch)));
    if (this.pos.y > P.hardCeiling && vy > 0) vy = 0;
    this.vel.y = vy;

    // Horizontal: the air of this altitude carries the balloon; on the ground the basket holds.
    windAt(this.pos.x, this.pos.y, this.pos.z, t, this.wind);
    const kd = 1 - Math.exp(-dt / P.driftTau);
    const hold = this.grounded ? 0 : 1;
    this.vel.x += (this.wind.x * hold - this.vel.x) * (this.grounded ? 1 - Math.exp(-dt / 0.6) : kd);
    this.vel.z += (this.wind.y * hold - this.vel.z) * (this.grounded ? 1 - Math.exp(-dt / 0.6) : kd);

    this.pos.addScaledVector(this.vel, dt);
    const fl = this.floor(this.pos.x, this.pos.z);
    if (this.pos.y <= fl) {
      this.pos.y = fl;
      if (this.vel.y < 0) this.vel.y = 0;
      this.grounded = true;
    } else if (this.pos.y > fl + 0.05) {
      this.grounded = false;
    }
    // Lift off once the envelope is hot enough again.
    if (this.grounded && vt > 0.15) this.grounded = false;

    // A slow, uneven turn of the whole balloon (well under a degree a second).
    if (!this.grounded) this.yaw += (0.004 + 0.006 * Math.sin(t * 0.031) + 0.003 * Math.sin(t * 0.11)) * dt;

    // Basket sway: a damped pendulum kicked by wind changes and by the burner lighting.
    const w = (Math.PI * 2) / P.swayPeriod;
    const ax = (this.wind.x - this.lastWind.x) / dt, az = (this.wind.y - this.lastWind.y) / dt;
    this.lastWind.copy(this.wind);
    if (this.burner && !this.wasBurning) this.swayV.x += 0.004;
    this.wasBurning = this.burner;
    this.swayV.x += (-w * w * this.sway.x - P.swayDamp * this.swayV.x + az * 0.002) * dt;
    this.swayV.y += (-w * w * this.sway.y - P.swayDamp * this.swayV.y - ax * 0.002) * dt;
    // A faint idle rock so it never stands dead still.
    this.swayV.x += Math.sin(t * 0.83) * 0.00004;
    this.swayV.y += Math.cos(t * 0.61) * 0.00004;
    this.sway.addScaledVector(this.swayV, dt);
    this.sway.clampLength(0, P.swayMax);
    if (this.grounded) this.sway.multiplyScalar(1 - Math.min(1, dt * 2));
  }
}
