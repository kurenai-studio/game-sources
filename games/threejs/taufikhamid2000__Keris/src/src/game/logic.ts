// Pure game logic: no three.js, no DOM. Everything here is unit-tested.
// Coordinates: x/z are the ground plane, y is up. A "yaw" of 0 faces +z and
// the forward vector for a yaw is (sin yaw, cos yaw).

export interface Vec2 {
  x: number;
  z: number;
}
export interface Vec3 {
  x: number;
  y: number;
  z: number;
}
export interface Box {
  minX: number;
  maxX: number;
  minY: number;
  maxY: number;
  minZ: number;
  maxZ: number;
}

export const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

export function wrapAngle(a: number): number {
  let r = a % (Math.PI * 2);
  if (r > Math.PI) r -= Math.PI * 2;
  if (r < -Math.PI) r += Math.PI * 2;
  return r;
}

export const yawTo = (from: Vec2, to: Vec2) => Math.atan2(to.x - from.x, to.z - from.z);
export const dist2D = (a: Vec2, b: Vec2) => Math.hypot(a.x - b.x, a.z - b.z);

/** Is `target` inside the horizontal vision cone (range + half-angle) of an eye facing `facingYaw`? */
export function inVisionCone(
  eye: Vec2,
  facingYaw: number,
  target: Vec2,
  range: number,
  halfAngle: number,
): boolean {
  const dx = target.x - eye.x;
  const dz = target.z - eye.z;
  const d2 = dx * dx + dz * dz;
  if (d2 > range * range) return false;
  if (d2 < 1e-6) return true;
  const diff = Math.abs(wrapAngle(Math.atan2(dx, dz) - facingYaw));
  return diff <= halfAngle;
}

/** Slab test. Returns distance along the (normalised) ray to the box, or null. 0 if origin is inside. */
export function rayBoxDistance(o: Vec3, d: Vec3, b: Box, maxDist = Infinity): number | null {
  let tmin = 0;
  let tmax = maxDist;
  const axes: [number, number, number, number][] = [
    [o.x, d.x, b.minX, b.maxX],
    [o.y, d.y, b.minY, b.maxY],
    [o.z, d.z, b.minZ, b.maxZ],
  ];
  for (const [oo, dd, lo, hi] of axes) {
    if (Math.abs(dd) < 1e-9) {
      if (oo < lo || oo > hi) return null;
    } else {
      let t1 = (lo - oo) / dd;
      let t2 = (hi - oo) / dd;
      if (t1 > t2) [t1, t2] = [t2, t1];
      tmin = Math.max(tmin, t1);
      tmax = Math.min(tmax, t2);
      if (tmin > tmax) return null;
    }
  }
  return tmin;
}

/** Nearest hit of a ray against many boxes. */
export function raycastBoxes(o: Vec3, d: Vec3, boxes: Box[], maxDist: number): number | null {
  let best: number | null = null;
  for (const b of boxes) {
    const t = rayBoxDistance(o, d, b, maxDist);
    if (t !== null && (best === null || t < best)) best = t;
  }
  return best;
}

/** Line of sight: true if no occluding box lies on the segment from -> to. */
export function hasLineOfSight(from: Vec3, to: Vec3, occluders: Box[]): boolean {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const dz = to.z - from.z;
  const len = Math.hypot(dx, dy, dz);
  if (len < 1e-6) return true;
  const dir = { x: dx / len, y: dy / len, z: dz / len };
  const hit = raycastBoxes(from, dir, occluders, len);
  return hit === null || hit >= len - 0.05;
}

export interface VisionParams {
  range: number;
  halfAngle: number;
}

/** Full sight check: cone + line of sight. A hidden player is only seen at point-blank range. */
export function canSee(
  eye: Vec3,
  yaw: number,
  target: Vec3,
  vision: VisionParams,
  occluders: Box[],
  hidden: boolean,
): boolean {
  const range = hidden ? Math.min(vision.range, 1.8) : vision.range;
  if (!inVisionCone({ x: eye.x, z: eye.z }, yaw, { x: target.x, z: target.z }, range, vision.halfAngle)) {
    return false;
  }
  return hasLineOfSight(eye, target, occluders);
}

// ---------------------------------------------------------------- detection

export interface Stance {
  crouched: boolean;
  running: boolean;
}

/** Detection meter gain per second while seen. Closer = faster; crouching slower; running faster. */
export function detectionRate(distance: number, range: number, stance: Stance): number {
  const closeness = clamp(1 - distance / range, 0, 1);
  let rate = 0.3 + 1.9 * closeness;
  if (stance.crouched) rate *= 0.6;
  if (stance.running) rate *= 1.4;
  return rate;
}

/** Advance a 0..1 detection meter: rises while seen, decays otherwise. */
export function stepMeter(meter: number, seen: boolean, rate: number, dt: number, decay = 0.25): number {
  return clamp(seen ? meter + rate * dt : meter - decay * dt, 0, 1);
}

/** How far the player's footsteps carry, in metres. */
export function noiseRadius(stance: Stance, moving: boolean): number {
  if (!moving) return 0;
  if (stance.crouched) return 1.8;
  return stance.running ? 8 : 4;
}

/** True if `player` is in the rear arc of a guard facing `guardYaw`. */
export function isBehind(guard: Vec2, guardYaw: number, player: Vec2, maxDot = -0.25): boolean {
  const dx = player.x - guard.x;
  const dz = player.z - guard.z;
  const len = Math.hypot(dx, dz);
  if (len < 1e-6) return true;
  const dot = (Math.sin(guardYaw) * dx + Math.cos(guardYaw) * dz) / len;
  return dot < maxDot;
}

// ---------------------------------------------------------------- guard brain

export type GuardState = "patrol" | "suspicious" | "alert" | "search";

export interface Brain {
  state: GuardState;
  /** seconds spent in the current "waiting" condition (unsure / lost sight / searching) */
  timer: number;
}

export interface Senses {
  meter: number;
  seesPlayer: boolean;
  heardNoise: boolean;
}

export const BRAIN = {
  suspiciousAt: 0.25,
  alertAt: 1,
  suspiciousCooldown: 4,
  loseSight: 3,
  searchTime: 8,
} as const;

export const newBrain = (): Brain => ({ state: "patrol", timer: 0 });

/** Pure transition function of the guard state machine. */
export function stepBrain(brain: Brain, s: Senses, dt: number): Brain {
  if (s.meter >= BRAIN.alertAt) return brain.state === "alert" ? { ...brain, timer: 0 } : { state: "alert", timer: 0 };

  switch (brain.state) {
    case "patrol":
      if (s.meter >= BRAIN.suspiciousAt || s.heardNoise) return { state: "suspicious", timer: 0 };
      return brain;
    case "suspicious": {
      if (s.seesPlayer || s.meter >= BRAIN.suspiciousAt || s.heardNoise) return { ...brain, timer: 0 };
      const timer = brain.timer + dt;
      return timer >= BRAIN.suspiciousCooldown ? { state: "patrol", timer: 0 } : { ...brain, timer };
    }
    case "alert": {
      if (s.seesPlayer) return { ...brain, timer: 0 };
      const timer = brain.timer + dt;
      return timer >= BRAIN.loseSight ? { state: "search", timer: 0 } : { ...brain, timer };
    }
    case "search": {
      if (s.seesPlayer && s.meter >= BRAIN.suspiciousAt) return { state: "suspicious", timer: 0 };
      const timer = brain.timer + dt;
      return timer >= BRAIN.searchTime ? { state: "patrol", timer: 0 } : { ...brain, timer };
    }
  }
}

/** Another guard shouted: jump straight to alert. */
export const forceAlert = (): Brain => ({ state: "alert", timer: 0 });

// ---------------------------------------------------------------- climbing guards

export const CLIMB = { step: 0.6, maxRise: 3.7, approachGap: 0.95 } as const;

const topContains = (b: Box, p: Vec2, pad = 0.05) =>
  p.x >= b.minX - pad && p.x <= b.maxX + pad && p.z >= b.minZ - pad && p.z <= b.maxZ + pad;

/** Horizontal distance from a point to a box footprint (0 if inside). */
export function distToFootprint(p: Vec2, b: Box): number {
  const dx = p.x - clamp(p.x, b.minX, b.maxX);
  const dz = p.z - clamp(p.z, b.minZ, b.maxZ);
  return Math.hypot(dx, dz);
}

/** Closest point just outside a box footprint, where a climber can stand to grab its edge. */
export function approachPoint(from: Vec2, b: Box, gap: number = CLIMB.approachGap): Vec2 {
  const cx = clamp(from.x, b.minX, b.maxX);
  const cz = clamp(from.z, b.minZ, b.maxZ);
  if (from.x !== cx || from.z !== cz) {
    const dx = from.x - cx;
    const dz = from.z - cz;
    const d = Math.hypot(dx, dz);
    return { x: cx + (dx / d) * gap, z: cz + (dz / d) * gap };
  }
  const opts = [
    { d: from.x - b.minX, x: b.minX - gap, z: from.z },
    { d: b.maxX - from.x, x: b.maxX + gap, z: from.z },
    { d: from.z - b.minZ, x: from.x, z: b.minZ - gap },
    { d: b.maxZ - from.z, x: from.x, z: b.maxZ + gap },
  ].sort((a, c) => a.d - c.d)[0];
  return { x: opts.x, z: opts.z };
}

export interface ClimbPlan {
  /** the box to climb next */
  box: Box;
  /** where to stand before climbing */
  approach: Vec2;
}

/**
 * How does a guard standing at height `climberY` reach a goal (x, z, y)?
 * Returns the next box to climb (a stepping stone or the goal's own box) and the point to
 * stand at, or null if no climb is needed / none is possible.
 */
export function planClimb(climber: Vec2, climberY: number, goal: Vec3, boxes: Box[]): ClimbPlan | null {
  if (goal.y <= climberY + CLIMB.step) return null;
  // the box whose top the goal stands on
  let goalBox: Box | null = null;
  for (const b of boxes) {
    if (b.maxY > goal.y + CLIMB.step || b.maxY <= climberY + CLIMB.step) continue;
    if (!topContains(b, goal)) continue;
    if (!goalBox || b.maxY > goalBox.maxY) goalBox = b;
  }
  if (!goalBox) return null;
  let best: Box | null = null;
  let bestScore = Infinity;
  for (const b of boxes) {
    const rise = b.maxY - climberY;
    if (rise <= CLIMB.step || rise > CLIMB.maxRise) continue;
    if (b.maxY > goalBox.maxY + 1e-6) continue;
    let extra = 0;
    if (b !== goalBox) {
      if (goalBox.maxY - b.maxY > CLIMB.maxRise) continue; // cannot go on from there
      const gap =
        Math.max(0, b.minX - goalBox.maxX, goalBox.minX - b.maxX) + Math.max(0, b.minZ - goalBox.maxZ, goalBox.minZ - b.maxZ);
      if (gap > 2) continue; // a stepping stone must touch the goal's box
      extra = 8 + gap;
    }
    const score = distToFootprint(climber, b) + extra;
    if (score < bestScore) {
      bestScore = score;
      best = b;
    }
  }
  if (!best) return null;
  return { box: best, approach: approachPoint(climber, best) };
}

/** Landing point on top of `box` for a climber who grabbed it from `from`. */
export function landingPoint(from: Vec2, box: Box, inset = 0.5): Vec2 {
  const ix = Math.min(inset, (box.maxX - box.minX) / 2);
  const iz = Math.min(inset, (box.maxZ - box.minZ) / 2);
  return { x: clamp(from.x, box.minX + ix, box.maxX - ix), z: clamp(from.z, box.minZ + iz, box.maxZ - iz) };
}

// ---------------------------------------------------------------- bodies

export const BODY = { range: 12, noticeAt: 0.3, discoverAt: 1, eyeHeight: 0.3, hiddenRange: 1.8 } as const;

export interface Cover {
  x: number;
  z: number;
  r: number;
}

/** A body is hidden when it lies inside a haystack or bush. */
export function isBodyHidden(body: Vec2, covers: Cover[]): boolean {
  return covers.some((c) => dist2D(body, c) < c.r);
}

/** Can a guard see a body on the ground? Hidden bodies only at point-blank range. */
export function canSeeBody(eye: Vec3, yaw: number, body: Vec2, vision: VisionParams, occluders: Box[], hidden: boolean, bodyY = 0): boolean {
  const range = Math.min(vision.range, hidden ? BODY.hiddenRange : BODY.range);
  return canSee(eye, yaw, { x: body.x, y: bodyY + BODY.eyeHeight, z: body.z }, { range, halfAngle: vision.halfAngle }, occluders, false);
}

/** Body awareness meter (0..1): rises while a body is in view (faster when close), fades otherwise. */
export function stepBodyMeter(meter: number, sees: boolean, distance: number, dt: number): number {
  const closeness = clamp(1 - distance / BODY.range, 0, 1);
  return clamp(sees ? meter + (0.5 + 1.5 * closeness) * dt : meter - 0.2 * dt, 0, 1);
}

export type BodyReaction = "none" | "suspicious" | "discovered";

export function bodyReaction(meter: number): BodyReaction {
  if (meter >= BODY.discoverAt) return "discovered";
  return meter >= BODY.noticeAt ? "suspicious" : "none";
}
