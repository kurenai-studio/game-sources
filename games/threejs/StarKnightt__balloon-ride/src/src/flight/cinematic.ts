/**
 * Cinematic mode (C): a scripted ~50 s camera path for showing the ride off and for recording
 * (scripts/record.mjs). It opens close on the basket (the pilot pulling the burner lever), pulls back and up to
 * reveal the village, the river and the other balloons, then glides out over the golden fields and
 * ends wide. Meanwhile the balloon flies a scripted gentle climb drifting east toward the village.
 *
 * Everything is a pure function of the cinematic time s (seconds since it began), so seek(s) gives
 * the same frame every time: the camera and target follow centripetal Catmull-Rom curves through
 * the key shots, timed by a monotone cubic through the key times (eased in at the start, out at
 * the end, never stopping in between).
 *
 * The opening (0-8 s) is a close shot on the basket laid over that path: the pilot pulling the
 * burner lever, looking up into the flame and the envelope's throat. It holds to OPEN_HOLD, then
 * eases into the path by OPEN_END; from there on the path, its timing and framing are untouched.
 */
import * as THREE from "three";

export const CINE_DURATION = 50;

/** Burner bursts [on, off] (s). */
const BURNS: [number, number][] = [
  [-1, 6.5],
  [23.5, 27.2],
  [39.5, 42.0],
];

/** The balloon's yaw during the cinematic (ride.ts startCinematic). */
const CINE_YAW = 0.4;
/** The opening close shot holds until OPEN_HOLD (s), then eases into the path by OPEN_END. */
const OPEN_HOLD = 2.5;
const OPEN_END = 8;
/** The opening shot in the basket's frame (x right, y up, z the pilot's front; metres), and fov. */
const OPEN_CAM = new THREE.Vector3(-1.45, 2.05, 3.0);
const OPEN_TGT = new THREE.Vector3(-0.15, 2.55, 0.0);
const OPEN_FOV = 56;
const _v = new THREE.Vector3();

const smooth = (a: number, b: number, x: number) => {
  const t = Math.min(1, Math.max(0, (x - a) / (b - a)));
  return t * t * (3 - 2 * t);
};

/** Monotone cubic (Fritsch-Carlson) through (xs, ys), flat at both ends. */
function monotone(xs: number[], ys: number[]): (x: number) => number {
  const n = xs.length;
  const d: number[] = [], m: number[] = new Array(n).fill(0);
  for (let i = 0; i < n - 1; i++) d.push((ys[i + 1] - ys[i]) / (xs[i + 1] - xs[i]));
  for (let i = 1; i < n - 1; i++) m[i] = d[i - 1] * d[i] <= 0 ? 0 : (2 * d[i - 1] * d[i]) / (d[i - 1] + d[i]);
  // Flat ends: ease in from rest, ease out to rest.
  m[0] = 0;
  m[n - 1] = 0;
  return (x: number) => {
    if (x <= xs[0]) return ys[0];
    if (x >= xs[n - 1]) return ys[n - 1];
    let i = 0;
    while (x > xs[i + 1]) i++;
    const h = xs[i + 1] - xs[i], t = (x - xs[i]) / h;
    const t2 = t * t, t3 = t2 * t;
    return (2 * t3 - 3 * t2 + 1) * ys[i] + (t3 - 2 * t2 + t) * h * m[i] + (-2 * t3 + 3 * t2) * ys[i + 1] + (t3 - t2) * h * m[i + 1];
  };
}

export class Cinematic {
  readonly duration = CINE_DURATION;
  /** Balloon start (basket floor). */
  readonly start: THREE.Vector3;
  /** Drift (m/s, x and z). */
  private readonly drift = new THREE.Vector2(4.1, -0.9);
  private readonly camCurve: THREE.CatmullRomCurve3;
  private readonly tgtCurve: THREE.CatmullRomCurve3;
  private readonly u: (s: number) => number;
  private readonly fov: (s: number) => number;

  constructor(private readonly ground: (x: number, z: number) => number) {
    const gh = (x: number, z: number) => Math.max(0, ground(x, z));
    const sx = -470, sz = 150;
    this.start = new THREE.Vector3(sx, gh(sx, sz) + 70, sz);
    const B = (s: number) => this.balloonAt(s, new THREE.Vector3());
    const rel = (s: number, x: number, y: number, z: number) => B(s).add(new THREE.Vector3(x, y, z));
    const abs = (x: number, h: number, z: number) => new THREE.Vector3(x, gh(x, z) + h, z);
    const keys: [number, THREE.Vector3, THREE.Vector3, number][] = [
      // Close on the basket, looking up into the roaring burner and the mouth.
      [0, rel(0, 3.3, 1.9, 3.4), rel(0, 0, 4.9, 0), 58],
      [6, rel(6, 12, 4, 17), rel(6, 0, 8, 0), 54],
      // Pulling back and up: the whole balloon against the land.
      [13, rel(13, 28, 20, 44), rel(13, 0, 11, 0), 50],
      // Round behind it: the village, the river and the festival open up ahead.
      [21, rel(21, -64, 52, 50), rel(21, 70, -6, -18), 50],
      [29, rel(29, -110, 105, 20), abs(-40, 10, 10), 50],
      // Out over the golden fields south of the village, looking back up the valley.
      [37, abs(-190, 150, 400), abs(-60, 40, 90), 50],
      [45, abs(60, 230, 560), abs(-70, 40, 30), 50],
      // Wide, from above the low puffs (their crowns and shadows below), not level with one.
      [50, abs(230, 420, 720), abs(-90, 30, -40), 52],
    ];
    this.camCurve = new THREE.CatmullRomCurve3(keys.map((k) => k[1]), false, "centripetal");
    this.tgtCurve = new THREE.CatmullRomCurve3(keys.map((k) => k[2]), false, "centripetal");
    const ts = keys.map((k) => k[0]);
    this.u = monotone(ts, keys.map((_, i) => i / (keys.length - 1)));
    this.fov = monotone(ts, keys.map((k) => k[3]));
  }

  /** The balloon's basket floor at cinematic time s: an easterly drift and a gentle climb. */
  balloonAt(s: number, out: THREE.Vector3): THREE.Vector3 {
    const c = Math.min(Math.max(s, 0), this.duration + 10);
    const climb = 95 * smooth(3, 48, c) + 6 * smooth(23.5, 34, c);
    return out.set(this.start.x + this.drift.x * c, this.start.y + climb, this.start.z + this.drift.y * c);
  }

  /** Drift heading (x, z): which way the festival is laid out. */
  heading(out = new THREE.Vector2()): THREE.Vector2 {
    return out.copy(this.drift).normalize();
  }

  burning(s: number): boolean {
    return BURNS.some(([a, b]) => s >= a && s < b);
  }

  /** Flame size 0..1 at s: lights fast (0.08 s), dies a little slower (0.18 s), as Flame eases. */
  flame(s: number): number {
    let l = 0;
    for (const [a, b] of BURNS) {
      if (s < a) continue;
      const peak = 1 - Math.exp(-(Math.min(s, b) - a) / 0.08);
      l = s < b ? peak : peak * Math.exp(-(s - b) / 0.18);
      if (s < b) break;
    }
    return l;
  }

  /** Place `camera` for cinematic time s. */
  pose(s: number, camera: THREE.PerspectiveCamera): void {
    const u = this.u(Math.min(Math.max(s, 0), this.duration));
    const p = this.camCurve.getPoint(u);
    const t = this.tgtCurve.getPoint(u);
    let fov = this.fov(s);
    if (s < OPEN_END) {
      // The opening: the close shot on the basket (it rides with the balloon), easing into the path.
      const w = 1 - smooth(OPEN_HOLD, OPEN_END, s);
      const b = this.balloonAt(s, _v);
      const c = Math.cos(CINE_YAW), sn = Math.sin(CINE_YAW);
      const L = (q: THREE.Vector3) => new THREE.Vector3(b.x + q.x * c + q.z * sn, b.y + q.y, b.z - q.x * sn + q.z * c);
      p.lerp(L(OPEN_CAM), w);
      t.lerp(L(OPEN_TGT), w);
      fov += (OPEN_FOV - fov) * w;
    }
    p.y = Math.max(p.y, Math.max(0, this.ground(p.x, p.z)) + 3);
    camera.position.copy(p);
    camera.up.set(0, 1, 0);
    camera.lookAt(t);
    if (camera.fov !== fov || camera.near !== 0.3) {
      camera.fov = fov;
      camera.near = 0.3;
      camera.updateProjectionMatrix();
    }
    camera.updateMatrixWorld();
  }
}
