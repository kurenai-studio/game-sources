/**
 * World layout: every hand-placed feature of the countryside, in world metres (x east, z south,
 * y up; water at y = 0). Later phases read these (balloon launch field, wind, cinematic paths).
 *
 * The detailed world is a square of +-MAP_HALF around the village; the heightfield and its field
 * map run a little further (+-GRID_HALF) so the edge is lost in the haze, and a coarse painted ring
 * carries the land on to the distant ridges.
 */

export type P2 = readonly [number, number];

/** The playable countryside: 6 km square centred on the village. */
export const MAP_HALF = 3000;
/** Heightfield / field-map extent (chunked, LOD'd terrain). */
export const GRID_HALF = 4000;
/** Coarse far-land ring out to here (fog hides its end; the painted ridges stand beyond). */
export const OUTER_HALF = 11000;

/** Water surface height (river and lake share one level, so one planar mirror serves both). */
export const WATER_Y = 0;
/** Ground level the village is levelled to. */
export const VILLAGE_Y = 5;

export const VILLAGE = { x: 0, z: 0, r: 240 } as const;
/** Village green (ellipse) in the north-west quarter, between the west road and the north road. */
export const GREEN = { x: -112, z: -82, rx: 40, rz: 27 } as const;
/** Paved market square on the crossroads (local rect, yaw 0). */
export const SQUARE = { x: -6, z: -10, hx: 25, hz: 18 } as const;
export const CHURCH = { x: 52, z: -78, yaw: 0.12 } as const;
/** Windmill on its own hill north-west of the village. */
export const WINDMILL = { x: -390, z: -400, hill: 24, hillR: 230 } as const;
/** The stone arch bridge where the south road crosses the river. */
export const BRIDGE = { x: 2, z: 132, yaw: 0.0, len: 46, width: 6.5 } as const;

/** Lake in a hollow north-east of the village: noisy ellipse. */
export const LAKE = { x: 700, z: -660, rx: 270, rz: 175, rot: 0.38 } as const;

/** River centreline (Catmull-Rom control points, west edge to east edge) and its half-width at the waterline. */
export const RIVER_PTS: P2[] = [
  [-11000, -1200], [-7000, -950], [-4600, -700], [-3800, -520], [-3300, -330], [-2900, -480], [-2520, -250],
  [-2200, -40], [-1930, 290], [-1640, 140], [-1400, 400], [-1110, 530], [-860, 300], [-640, 420], [-430, 210],
  [-210, 175], [2, 132], [190, 160], [400, 270], [600, 430], [850, 340], [1080, 380], [1330, 290], [1600, 470],
  [1820, 700], [2100, 620], [2350, 850], [2620, 700], [2900, 880], [3200, 1060], [3700, 1150], [4600, 1300],
  [7000, 1500], [11000, 1900],
];
export const RIVER_HW = { min: 10, max: 17 } as const;

/** Roads: main roads (6 m) and lanes (4 m). Control points, smoothed. */
export interface RoadDef {
  name: string;
  w: number;
  pts: P2[];
}
export const ROADS: RoadDef[] = [
  { name: "west", w: 6, pts: [[-4300, -760], [-3000, -640], [-2300, -580], [-1500, -390], [-800, -140], [-260, -34], [-6, -10]] },
  { name: "east", w: 6, pts: [[-6, -10], [280, -44], [800, -200], [1400, -250], [2200, -120], [3000, -300], [4300, -360]] },
  { name: "south", w: 6, pts: [[-6, -10], [-2, 60], [2, 132], [8, 220], [-60, 500], [-250, 900], [-300, 1500], [-150, 2200], [100, 3000], [180, 4300]] },
  { name: "north", w: 5, pts: [[-6, -10], [-34, -130], [40, -460], [-80, -900], [100, -1500], [300, -2200], [200, -3000], [260, -4300]] },
  { name: "lane-se", w: 4, pts: [[-60, 500], [300, 640], [700, 800], [1300, 900], [2000, 1250], [3000, 1500], [4300, 1700]] },
  { name: "lane-nw", w: 4, pts: [[-1500, -390], [-1580, -800], [-1650, -1250], [-1500, -2000], [-1700, -3000], [-1800, -4300]] },
  { name: "lane-mill", w: 3.5, pts: [[-34, -130], [-200, -260], [-372, -386]] },
  { name: "lane-sw", w: 4, pts: [[-250, 900], [-800, 1000], [-1400, 1250], [-2200, 1300], [-3000, 1100], [-4300, 1000]] },
  { name: "lane-ne", w: 4, pts: [[1400, -250], [1500, -800], [1350, -1400], [1700, -2100], [2300, -2600], [3000, -3000]] },
  { name: "lane-farm-e", w: 3.5, pts: [[800, -200], [980, 60], [1180, 140]] },
  { name: "lane-farm-w", w: 3.5, pts: [[-1150, -250], [-1100, -40], [-1180, 60]] },
];

/** Farmsteads: house + barn + yard, facing `yaw`. */
export const FARMS: { x: number; z: number; yaw: number }[] = [
  { x: -1640, z: -1270, yaw: 0.3 },
  { x: 1310, z: 935, yaw: -0.2 },
  { x: -1420, z: 1270, yaw: 0.1 },
  { x: 1520, z: -820, yaw: 1.4 },
  { x: -1210, z: 70, yaw: -0.4 },
  { x: 1200, z: 160, yaw: 0.6 },
  { x: 2050, z: 1290, yaw: 0.4 },
  { x: -300, z: 1520, yaw: 1.5 },
  { x: 120, z: -1520, yaw: -1.2 },
  { x: -2300, z: -560, yaw: 0.2 },
  { x: 2250, z: -150, yaw: 0.1 },
  { x: -2250, z: 1320, yaw: 0.0 },
];

// ------------------------------------------------------------------ polyline helpers

/** Catmull-Rom through the control points, resampled every `step` metres. */
export function smoothPath(pts: readonly P2[], step = 8): [number, number][] {
  const out: [number, number][] = [];
  const n = pts.length;
  const at = (i: number) => pts[Math.max(0, Math.min(n - 1, i))];
  for (let i = 0; i < n - 1; i++) {
    const p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
    const len = Math.hypot(p2[0] - p1[0], p2[1] - p1[1]);
    const k = Math.max(1, Math.ceil(len / step));
    for (let j = 0; j < k; j++) {
      const t = j / k, t2 = t * t, t3 = t2 * t;
      const f = (a: number, b: number, c: number, d: number) =>
        0.5 * (2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3);
      out.push([f(p0[0], p1[0], p2[0], p3[0]), f(p0[1], p1[1], p2[1], p3[1])]);
    }
  }
  out.push([pts[n - 1][0], pts[n - 1][1]]);
  return out;
}

/** Segment soup with a uniform bucket grid, for nearest-distance queries. */
export class SegIndex {
  private readonly cell: number;
  private readonly buckets = new Map<number, number[]>();
  /** Flat segments: ax, az, bx, bz, value (e.g. half width). */
  readonly seg: number[] = [];

  constructor(cell = 80) {
    this.cell = cell;
  }

  add(path: readonly (readonly [number, number])[], value: (i: number, n: number) => number): void {
    for (let i = 0; i < path.length - 1; i++) {
      const id = this.seg.length / 5;
      const [ax, az] = path[i], [bx, bz] = path[i + 1];
      this.seg.push(ax, az, bx, bz, value(i, path.length - 1));
      const c = this.cell;
      const x0 = Math.floor(Math.min(ax, bx) / c), x1 = Math.floor(Math.max(ax, bx) / c);
      const z0 = Math.floor(Math.min(az, bz) / c), z1 = Math.floor(Math.max(az, bz) / c);
      for (let x = x0; x <= x1; x++) for (let z = z0; z <= z1; z++) {
        const k = x * 100003 + z;
        let b = this.buckets.get(k);
        if (!b) this.buckets.set(k, (b = []));
        b.push(id);
      }
    }
  }

  /**
   * Nearest segment within `reach` metres: distance, the segment's value, the segment index and
   * the parameter along it. Infinity distance when nothing is that close.
   */
  near(x: number, z: number, reach: number): { d: number; v: number; i: number; t: number } {
    const c = this.cell, s = this.seg;
    const r = Math.ceil(reach / c);
    const cx = Math.floor(x / c), cz = Math.floor(z / c);
    let best = Infinity, bv = 0, bi = -1, bt = 0;
    for (let ix = cx - r; ix <= cx + r; ix++) for (let iz = cz - r; iz <= cz + r; iz++) {
      const b = this.buckets.get(ix * 100003 + iz);
      if (!b) continue;
      for (const id of b) {
        const o = id * 5;
        const ax = s[o], az = s[o + 1], dx = s[o + 2] - ax, dz = s[o + 3] - az;
        const l2 = dx * dx + dz * dz || 1;
        const t = Math.max(0, Math.min(1, ((x - ax) * dx + (z - az) * dz) / l2));
        const ex = ax + dx * t - x, ez = az + dz * t - z;
        const d = Math.sqrt(ex * ex + ez * ez);
        if (d < best) {
          best = d;
          bv = s[o + 4];
          bi = id;
          bt = t;
        }
      }
    }
    return best <= reach ? { d: best, v: bv, i: bi, t: bt } : { d: Infinity, v: 0, i: -1, t: 0 };
  }
}

export const RIVER_PATH = smoothPath(RIVER_PTS, 8);
export const ROAD_PATHS = ROADS.map((r) => ({ ...r, path: smoothPath(r.pts, 6) }));

/** River half-width along its length: narrow upstream (west), broader downstream. */
export const riverHalfWidth = (i: number, n: number) =>
  RIVER_HW.min + (RIVER_HW.max - RIVER_HW.min) * (i / n) + 2.6 * Math.sin(i * 0.043) + 1.6 * Math.sin(i * 0.131 + 1.3) + 0.8 * Math.sin(i * 0.37);

export const riverIndex = new SegIndex(60);
riverIndex.add(RIVER_PATH, riverHalfWidth);

export const roadIndex = new SegIndex(60);
for (const r of ROAD_PATHS) roadIndex.add(r.path, () => r.w * 0.5);

/** Lake shore radius toward angle `a` (local frame), as a multiple of the ellipse. */
function lakeWobble(a: number): number {
  return 1 + 0.1 * Math.sin(a * 3 + 0.7) + 0.06 * Math.sin(a * 5 + 2.1) + 0.04 * Math.sin(a * 8 + 4);
}

/** Signed distance (approx., metres) to the lake shore: negative inside. */
export function lakeDist(x: number, z: number): number {
  const c = Math.cos(LAKE.rot), s = Math.sin(LAKE.rot);
  const dx = x - LAKE.x, dz = z - LAKE.z;
  const lx = dx * c + dz * s, lz = -dx * s + dz * c;
  const a = Math.atan2(lz / LAKE.rz, lx / LAKE.rx);
  const w = lakeWobble(a);
  const q = Math.hypot(lx / (LAKE.rx * w), lz / (LAKE.rz * w));
  return (q - 1) * Math.min(LAKE.rx, LAKE.rz) * w;
}

/** Lake shoreline polygon (world xz), for painting the field map. */
export function lakeShore(n = 160): [number, number][] {
  const c = Math.cos(LAKE.rot), s = Math.sin(LAKE.rot);
  const out: [number, number][] = [];
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2;
    const w = lakeWobble(a);
    const lx = Math.cos(a) * LAKE.rx * w, lz = Math.sin(a) * LAKE.rz * w;
    out.push([LAKE.x + lx * c - lz * s, LAKE.z + lx * s + lz * c]);
  }
  return out;
}

/** Distance from the village green's edge (negative inside). */
export function greenDist(x: number, z: number): number {
  const q = Math.hypot((x - GREEN.x) / GREEN.rx, (z - GREEN.z) / GREEN.rz);
  return (q - 1) * Math.min(GREEN.rx, GREEN.rz);
}
