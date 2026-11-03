// Pure guard navigation: a layered grid built from the level's colliders (ground, the open
// space under stilt houses, and every rooftop/ledge surface), explicit climb links between
// layers, A* over it, path smoothing, re-path throttling and stuck handling.
// No three.js, no DOM. Everything here is unit-tested.

import { dist2D, type Box, type Vec2, type Vec3 } from "./logic";

export const NAV = {
  cell: 0.5,
  /** clearance kept from solid geometry (guards are ~0.45 wide) */
  radius: 0.5,
  /** tallest step a walker can step over without climbing */
  step: 0.6,
  /** head height: boxes whose underside is above this do not block (under-house space) */
  head: 1.75,
  maxRise: 3.7,
  /** how far outside a wall a climber stands to grab it */
  gap: 0.95,
  linkSpacing: 2.5,
} as const;

export interface NavBounds {
  minX: number;
  maxX: number;
  minZ: number;
  maxZ: number;
  jettyZ?: number;
  jettyHalf?: number;
}

/** An explicit climb edge between two layers. `keys` is the animation path from `from` to `to`. */
export interface ClimbLink {
  from: number;
  to: number;
  up: boolean;
  keys: Vec3[];
  /** yaw the climber faces (towards the wall) */
  faceYaw: number;
  cost: number;
}

export interface PathPoint extends Vec3 {
  node: number;
  /** set when this point is reached from the previous one by climbing this link */
  via: ClimbLink | null;
}

export interface NavPath {
  /** the goal node was reached */
  found: boolean;
  /** the goal was unreachable; the path leads to the closest reachable node */
  partial: boolean;
  points: PathPoint[];
}

const HEAP_EMPTY = -1;

class MinHeap {
  private ids: number[] = [];
  private keys: number[] = [];
  get size() {
    return this.ids.length;
  }
  clear() {
    this.ids.length = 0;
    this.keys.length = 0;
  }
  push(id: number, key: number) {
    const ids = this.ids;
    const keys = this.keys;
    let i = ids.length;
    ids.push(id);
    keys.push(key);
    while (i > 0) {
      const p = (i - 1) >> 1;
      if (keys[p] <= key) break;
      ids[i] = ids[p];
      keys[i] = keys[p];
      i = p;
    }
    ids[i] = id;
    keys[i] = key;
  }
  pop(): number {
    const ids = this.ids;
    const keys = this.keys;
    if (!ids.length) return HEAP_EMPTY;
    const top = ids[0];
    const lid = ids.pop()!;
    const lk = keys.pop()!;
    const n = ids.length;
    if (n > 0) {
      let i = 0;
      for (;;) {
        let c = 2 * i + 1;
        if (c >= n) break;
        if (c + 1 < n && keys[c + 1] < keys[c]) c++;
        if (keys[c] >= lk) break;
        ids[i] = ids[c];
        keys[i] = keys[c];
        i = c;
      }
      ids[i] = lid;
      keys[i] = lk;
    }
    return top;
  }
}

const DIRS: [number, number, number][] = [
  [1, 0, 1],
  [-1, 0, 1],
  [0, 1, 1],
  [0, -1, 1],
  [1, 1, Math.SQRT2],
  [1, -1, Math.SQRT2],
  [-1, 1, Math.SQRT2],
  [-1, -1, Math.SQRT2],
];

/** Does a solid box get in the way of a walker whose feet are at `h`? (same rule as the engine's push-out) */
const blocksAt = (b: Box, h: number) => b.maxY > h + NAV.step && b.minY < h + NAV.head;

export class NavGrid {
  readonly cell = NAV.cell;
  readonly ox: number;
  readonly oz: number;
  readonly w: number;
  readonly h: number;
  readonly size: number;
  /** surface height per layer; layer 0 is the ground (which includes the space under stilt houses) */
  readonly heights: number[] = [0];
  readonly walk: Uint8Array[] = [];
  readonly links = new Map<number, ClimbLink[]>();
  readonly allLinks: ClimbLink[] = [];
  private g!: Float32Array;
  private parent!: Int32Array;
  private via!: Int32Array;
  private stamp!: Uint32Array;
  private closed!: Uint8Array;
  private gen = 0;
  private heap = new MinHeap();

  constructor(
    readonly colliders: Box[],
    readonly bounds: NavBounds,
  ) {
    this.ox = bounds.minX;
    this.oz = bounds.minZ;
    this.w = Math.ceil((bounds.maxX - bounds.minX) / this.cell);
    this.h = Math.ceil((bounds.maxZ - bounds.minZ) / this.cell);
    this.size = this.w * this.h;
    this.build();
  }

  get layers() {
    return this.heights.length;
  }

  // ------------------------------------------------------------ geometry helpers
  cx(ix: number) {
    return this.ox + (ix + 0.5) * this.cell;
  }
  cz(iz: number) {
    return this.oz + (iz + 0.5) * this.cell;
  }
  ix(x: number) {
    return Math.floor((x - this.ox) / this.cell);
  }
  iz(z: number) {
    return Math.floor((z - this.oz) / this.cell);
  }
  inGrid(ix: number, iz: number) {
    return ix >= 0 && iz >= 0 && ix < this.w && iz < this.h;
  }
  id(layer: number, ix: number, iz: number) {
    return layer * this.size + iz * this.w + ix;
  }
  layerOf(id: number) {
    return Math.floor(id / this.size);
  }
  ixOf(id: number) {
    return (id % this.size) % this.w;
  }
  izOf(id: number) {
    return Math.floor((id % this.size) / this.w);
  }
  pos(id: number): Vec3 {
    return { x: this.cx(this.ixOf(id)), y: this.heights[this.layerOf(id)], z: this.cz(this.izOf(id)) };
  }
  isWalkable(layer: number, ix: number, iz: number) {
    return this.inGrid(ix, iz) && this.walk[layer][iz * this.w + ix] === 1;
  }
  walkableAt(layer: number, x: number, z: number) {
    return this.isWalkable(layer, this.ix(x), this.iz(z));
  }

  // ------------------------------------------------------------ build
  private build() {
    const { w, h, size } = this;
    const inflate = NAV.radius;
    const groundOk = new Uint8Array(size);
    const jz = this.bounds.jettyZ;
    const jh = this.bounds.jettyHalf ?? Infinity;
    for (let iz = 0; iz < h; iz++)
      for (let ix = 0; ix < w; ix++) {
        const x = this.cx(ix);
        const z = this.cz(iz);
        if (jz !== undefined && z < jz && Math.abs(x) > jh - 0.4) continue;
        groundOk[iz * w + ix] = 1;
      }
    this.rasterBlockers(groundOk, 0, inflate);
    this.walk.push(groundOk);

    // rooftop / ledge surfaces: group box tops by height
    const byH = new Map<number, Box[]>();
    for (const b of this.colliders) {
      if (b.maxY < 0.8) continue;
      if (b.maxX - b.minX < 1 || b.maxZ - b.minZ < 1) continue; // posts, rails
      const key = Math.round(b.maxY * 100) / 100;
      const arr = byH.get(key);
      if (arr) arr.push(b);
      else byH.set(key, [b]);
    }
    for (const hKey of [...byH.keys()].sort((a, b) => a - b)) {
      const cover = new Uint8Array(size);
      for (const b of byH.get(hKey)!) {
        const x0 = Math.max(0, this.ix(b.minX));
        const x1 = Math.min(w - 1, this.ix(b.maxX));
        const z0 = Math.max(0, this.iz(b.minZ));
        const z1 = Math.min(h - 1, this.iz(b.maxZ));
        for (let iz = z0; iz <= z1; iz++)
          for (let ix = x0; ix <= x1; ix++) {
            const x = this.cx(ix);
            const z = this.cz(iz);
            if (x >= b.minX && x <= b.maxX && z >= b.minZ && z <= b.maxZ) cover[iz * w + ix] = 1;
          }
      }
      // erode so a walker never stands on the very lip
      const ok = new Uint8Array(size);
      let any = false;
      for (let iz = 1; iz < h - 1; iz++)
        for (let ix = 1; ix < w - 1; ix++) {
          const i = iz * w + ix;
          if (cover[i] && cover[i - 1] && cover[i + 1] && cover[i - w] && cover[i + w]) {
            ok[i] = 1;
            any = true;
          }
        }
      if (!any) continue;
      this.rasterBlockers(ok, hKey, inflate);
      this.heights.push(hKey);
      this.walk.push(ok);
    }

    this.g = new Float32Array(this.layers * size);
    this.parent = new Int32Array(this.layers * size);
    this.via = new Int32Array(this.layers * size);
    this.stamp = new Uint32Array(this.layers * size);
    this.closed = new Uint8Array(this.layers * size);
    this.buildLinks();
  }

  /** Clear cells within `inflate` of any collider that blocks a walker standing at height `hh`. */
  private rasterBlockers(grid: Uint8Array, hh: number, inflate: number) {
    for (const b of this.colliders) {
      if (!blocksAt(b, hh)) continue;
      const x0 = Math.max(0, this.ix(b.minX - inflate));
      const x1 = Math.min(this.w - 1, this.ix(b.maxX + inflate));
      const z0 = Math.max(0, this.iz(b.minZ - inflate));
      const z1 = Math.min(this.h - 1, this.iz(b.maxZ + inflate));
      for (let iz = z0; iz <= z1; iz++)
        for (let ix = x0; ix <= x1; ix++) {
          const x = this.cx(ix);
          const z = this.cz(iz);
          if (x > b.minX - inflate && x < b.maxX + inflate && z > b.minZ - inflate && z < b.maxZ + inflate) grid[iz * this.w + ix] = 0;
        }
    }
  }

  /** Is the column at (x, z) between heights lo..hi occupied by something other than `except`? */
  private ceilingAbove(x: number, z: number, lo: number, hi: number, except: Box) {
    for (const b of this.colliders) {
      if (b === except) continue;
      if (b.minY < lo + 1.0 || b.minY >= hi) continue;
      if (x >= b.minX - 0.3 && x <= b.maxX + 0.3 && z >= b.minZ - 0.3 && z <= b.maxZ + 0.3) return true;
    }
    return false;
  }

  private addLink(link: ClimbLink) {
    const arr = this.links.get(link.from);
    if (arr) arr.push(link);
    else this.links.set(link.from, [link]);
    this.allLinks.push(link);
  }

  private buildLinks() {
    for (let layer = 1; layer < this.layers; layer++) {
      const T = this.heights[layer];
      const boxes = this.colliders.filter((b) => Math.abs(b.maxY - T) < 0.006 && b.maxX - b.minX >= 1 && b.maxZ - b.minZ >= 1);
      for (const b of boxes) {
        // outward normals of the four sides, plus the side's extent
        const sides: { nx: number; nz: number; lo: number; hi: number }[] = [
          { nx: -1, nz: 0, lo: b.minZ, hi: b.maxZ },
          { nx: 1, nz: 0, lo: b.minZ, hi: b.maxZ },
          { nx: 0, nz: -1, lo: b.minX, hi: b.maxX },
          { nx: 0, nz: 1, lo: b.minX, hi: b.maxX },
        ];
        for (const s of sides) {
          const len = s.hi - s.lo;
          const samples: number[] = [];
          if (len < 2 * 0.75 + 0.5) samples.push((s.lo + s.hi) / 2);
          else for (let u = s.lo + 0.75; u <= s.hi - 0.75 + 1e-6; u += NAV.linkSpacing) samples.push(u);
          for (const u of samples) {
            const wall: Vec2 =
              s.nx !== 0 ? { x: s.nx < 0 ? b.minX : b.maxX, z: u } : { x: u, z: s.nz < 0 ? b.minZ : b.maxZ };
            const base = { x: wall.x + s.nx * NAV.gap, z: wall.z + s.nz * NAV.gap };
            const land = { x: wall.x - s.nx * NAV.gap, z: wall.z - s.nz * NAV.gap };
            const lix = this.ix(land.x);
            const liz = this.iz(land.z);
            if (!this.isWalkable(layer, lix, liz)) continue;
            const bix = this.ix(base.x);
            const biz = this.iz(base.z);
            for (let lower = 0; lower < this.layers; lower++) {
              if (lower === layer) continue;
              const hl = this.heights[lower];
              const rise = T - hl;
              if (rise <= NAV.step || rise > NAV.maxRise) continue;
              if (!this.isWalkable(lower, bix, biz)) continue;
              const hang = { x: wall.x + s.nx * 0.4, z: wall.z + s.nz * 0.4 };
              if (this.ceilingAbove(hang.x, hang.z, hl, T, b) || this.ceilingAbove(this.cx(bix), this.cz(biz), hl, T, b)) continue;
              const bottom = this.id(lower, bix, biz);
              const top = this.id(layer, lix, liz);
              const bp = this.pos(bottom);
              const tp = this.pos(top);
              const faceYaw = Math.atan2(-s.nx, -s.nz);
              const keys: Vec3[] = [
                bp,
                { x: hang.x, y: hl, z: hang.z },
                { x: hang.x, y: T - 0.5, z: hang.z },
                { x: wall.x - s.nx * 0.3, y: T, z: wall.z - s.nz * 0.3 },
                tp,
              ];
              const upCost = pathLen(keys) * 1.6;
              this.addLink({ from: bottom, to: top, up: true, keys, faceYaw, cost: upCost });
              this.addLink({ from: top, to: bottom, up: false, keys: [...keys].reverse(), faceYaw, cost: pathLen(keys) * 1.1 });
            }
          }
        }
      }
    }
  }

  // ------------------------------------------------------------ queries
  /** Closest walkable node to a world position (layer picked by height). -1 if the grid has none nearby. */
  nearestNode(p: Vec3, maxRadius = 4): number {
    const R = Math.ceil(maxRadius / this.cell);
    const cix = this.ix(p.x);
    const ciz = this.iz(p.z);
    for (const tol of [1.6, Infinity]) {
      let best = -1;
      let bestScore = Infinity;
      for (let layer = 0; layer < this.layers; layer++) {
        const dy = Math.abs(this.heights[layer] - p.y);
        if (dy > tol) continue;
        for (let dz = -R; dz <= R; dz++)
          for (let dx = -R; dx <= R; dx++) {
            const ix = cix + dx;
            const iz = ciz + dz;
            if (!this.isWalkable(layer, ix, iz)) continue;
            const score = Math.hypot(this.cx(ix) - p.x, this.cz(iz) - p.z) + 2 * dy;
            if (score < bestScore) {
              bestScore = score;
              best = this.id(layer, ix, iz);
            }
          }
      }
      if (best >= 0) return best;
    }
    return -1;
  }

  /** Centre of the nearest walkable cell on the same layer: used to un-snag a stuck walker. */
  snap(p: Vec3): Vec3 | null {
    const n = this.nearestNode(p, 3);
    return n < 0 ? null : this.pos(n);
  }

  /** Straight walk between two points stays on walkable cells of `layer`. The first `skip` metres are ignored. */
  lineWalkable(layer: number, a: Vec2, b: Vec2, skip = 0): boolean {
    const d = Math.hypot(b.x - a.x, b.z - a.z);
    const n = Math.max(1, Math.ceil(d / (this.cell * 0.5)));
    for (let i = 1; i <= n; i++) {
      const t = i / n;
      if (t * d < skip) continue;
      if (!this.walkableAt(layer, a.x + (b.x - a.x) * t, a.z + (b.z - a.z) * t)) return false;
    }
    return true;
  }

  // ------------------------------------------------------------ A*
  /**
   * A* from `start` to `goal` over the layered grid and climb links. When the goal cannot be
   * reached, the result is `partial` and leads to the reachable node nearest to the goal.
   * Returns null only if neither endpoint has a walkable node nearby.
   */
  findPath(start: Vec3, goal: Vec3): NavPath | null {
    const sn = this.nearestNode(start, 3);
    const gn = this.nearestNode(goal, 4);
    if (sn < 0 || gn < 0) return null;
    const gp = this.pos(gn);
    const gx = gp.x;
    const gz = gp.z;
    const goalLayer = this.layerOf(gn);
    const gen = ++this.gen;
    const { g, parent, via, stamp, closed, heap } = this;
    heap.clear();
    const hOf = (id: number) => Math.hypot(this.cx(this.ixOf(id)) - gx, this.cz(this.izOf(id)) - gz) + (this.layerOf(id) === goalLayer ? 0 : 0.01);
    g[sn] = 0;
    parent[sn] = -1;
    via[sn] = -1;
    stamp[sn] = gen;
    closed[sn] = 0;
    heap.push(sn, hOf(sn));
    let best = sn;
    let bestH = Infinity;
    let found = false;
    let guard = 0;
    while (heap.size && guard++ < 400000) {
      const cur = heap.pop();
      if (stamp[cur] === gen && closed[cur] === 1) continue;
      closed[cur] = 1;
      if (cur === gn) {
        found = true;
        break;
      }
      const hc = hOf(cur);
      if (hc < bestH) {
        bestH = hc;
        best = cur;
      }
      const layer = this.layerOf(cur);
      const cix = this.ixOf(cur);
      const ciz = this.izOf(cur);
      const grid = this.walk[layer];
      for (let k = 0; k < 8; k++) {
        const [dx, dz, c] = DIRS[k];
        const ix = cix + dx;
        const iz = ciz + dz;
        if (ix < 0 || iz < 0 || ix >= this.w || iz >= this.h) continue;
        if (!grid[iz * this.w + ix]) continue;
        if (dx !== 0 && dz !== 0 && (!grid[ciz * this.w + ix] || !grid[iz * this.w + cix])) continue; // no corner cutting
        this.relax(cur, this.id(layer, ix, iz), g[cur] + c * this.cell, -1, gen, hOf);
      }
      const ls = this.links.get(cur);
      if (ls) for (const l of ls) this.relax(cur, l.to, g[cur] + l.cost, this.allLinks.indexOf(l), gen, hOf);
    }
    const end = found ? gn : best;
    const chain: { id: number; link: ClimbLink | null }[] = [];
    for (let n = end; n !== -1; n = parent[n]) chain.push({ id: n, link: via[n] >= 0 ? this.allLinks[via[n]] : null });
    chain.reverse();
    return { found, partial: !found, points: this.smooth(chain, start) };
  }

  private relax(from: number, to: number, ng: number, linkIdx: number, gen: number, hOf: (id: number) => number) {
    const { g, parent, via, stamp, closed } = this;
    if (stamp[to] !== gen) {
      stamp[to] = gen;
      closed[to] = 0;
      g[to] = Infinity;
    }
    if (closed[to] === 1 || ng >= g[to]) return;
    g[to] = ng;
    parent[to] = from;
    via[to] = linkIdx;
    this.heap.push(to, ng + hOf(to));
  }

  /** String-pull each same-layer run; climb links split the runs and are kept as `via` points. */
  private smooth(chain: { id: number; link: ClimbLink | null }[], origin: Vec3): PathPoint[] {
    const out: PathPoint[] = [];
    let runStart = 0;
    const flushRun = (from: number, to: number, anchor: Vec2, skip: number) => {
      // nodes chain[from..to] are on one layer; anchor is where the walk starts
      const layer = this.layerOf(chain[from].id);
      let a: Vec2 = anchor;
      let i = from;
      let aSkip = skip;
      while (i <= to) {
        let j = i;
        while (j + 1 <= to && this.lineWalkable(layer, a, this.pos(chain[j + 1].id), aSkip)) j++;
        const p = this.pos(chain[j].id);
        out.push({ ...p, node: chain[j].id, via: null });
        a = p;
        aSkip = 0;
        i = j + 1;
      }
    };
    let anchor: Vec2 = origin;
    let skip = 0.8;
    for (let i = 1; i <= chain.length; i++) {
      if (i === chain.length || chain[i].link) {
        flushRun(runStart, i - 1, anchor, skip);
        if (i < chain.length) {
          const l = chain[i].link!;
          const p = this.pos(chain[i].id);
          out.push({ ...p, node: chain[i].id, via: l });
          anchor = p;
          skip = 0;
          runStart = i + 1;
          // the landing node itself is the anchor of the next run
          if (runStart > chain.length - 1) break;
        }
      }
    }
    return out;
  }
}

export function pathLen(pts: Vec3[]): number {
  let s = 0;
  for (let i = 1; i < pts.length; i++) s += Math.hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y, pts[i].z - pts[i - 1].z);
  return s;
}

export const buildNav = (colliders: Box[], bounds: NavBounds) => new NavGrid(colliders, bounds);

// ---------------------------------------------------------------- climb animation

const CLIMB_H_SPEED = 1.8;
const CLIMB_V_SPEED = 2.2;

const segTime = (a: Vec3, b: Vec3) => Math.max(Math.abs(b.y - a.y) / CLIMB_V_SPEED, Math.hypot(b.x - a.x, b.z - a.z) / CLIMB_H_SPEED, 0.05);

export function climbDuration(keys: Vec3[]): number {
  let t = 0;
  for (let i = 1; i < keys.length; i++) t += segTime(keys[i - 1], keys[i]);
  return t;
}

/** Position `t` seconds into a climb along `keys`: up the wall face, over the lip, onto the surface. */
export function sampleClimb(keys: Vec3[], t: number): Vec3 {
  let rest = Math.max(0, t);
  for (let i = 1; i < keys.length; i++) {
    const a = keys[i - 1];
    const b = keys[i];
    const d = segTime(a, b);
    if (rest <= d) {
      const k = rest / d;
      return { x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k, z: a.z + (b.z - a.z) * k };
    }
    rest -= d;
  }
  return { ...keys[keys.length - 1] };
}

// ---------------------------------------------------------------- re-path throttle

export const REPATH = {
  /** goal moved this far (m) => path is stale */
  moveThreshold: 1.5,
  /** never re-plan more often than this (s) */
  minInterval: 0.4,
  /** refresh even a static goal's path this often while still walking (s) */
  maxAge: 4,
  /** retry interval after a failed plan (s) */
  retry: 0.6,
} as const;

export function shouldRepath(args: {
  hasPath: boolean;
  goal: Vec3;
  plannedGoal: Vec3 | null;
  sincePlan: number;
}): boolean {
  const { hasPath, goal, plannedGoal, sincePlan } = args;
  if (!hasPath || !plannedGoal) return sincePlan >= REPATH.retry;
  if (sincePlan < REPATH.minInterval) return false;
  if (dist2D(goal, plannedGoal) > REPATH.moveThreshold || Math.abs(goal.y - plannedGoal.y) > 1) return true;
  return sincePlan >= REPATH.maxAge;
}

// ---------------------------------------------------------------- stuck detection

export interface StuckState {
  x: number;
  z: number;
  t: number;
  count: number;
}
export const newStuck = (x = 0, z = 0): StuckState => ({ x, z, t: 0, count: 0 });
export const STUCK = { window: 1.2, minMove: 0.3 } as const;

/** Called every frame the walker is asked to move. `stuck` is true on the frame a window passes with no progress. */
export function stepStuck(s: StuckState, x: number, z: number, dt: number): { state: StuckState; stuck: boolean } {
  const t = s.t + dt;
  if (t < STUCK.window) return { state: { ...s, t }, stuck: false };
  const moved = Math.hypot(x - s.x, z - s.z);
  if (moved < STUCK.minMove) return { state: { x, z, t: 0, count: s.count + 1 }, stuck: true };
  return { state: { x, z, t: 0, count: 0 }, stuck: false };
}

// ---------------------------------------------------------------- path agent

export type AgentCmd =
  | { kind: "walk"; to: Vec2 }
  | { kind: "climb"; link: ClimbLink }
  | { kind: "wait" }
  /** at the end of the path; `reachable` is false if the goal itself could not be reached */
  | { kind: "arrived"; reachable: boolean }
  /** navigation cannot help; caller should use its legacy direct movement */
  | { kind: "fallback" };

/** Follows A* paths for one guard: throttled re-planning, climb hand-off, stuck escalation. */
export class PathAgent {
  path: NavPath | null = null;
  idx = 0;
  plans = 0;
  plannedGoal: Vec3 | null = null;
  sincePlan = Infinity;
  climbing = false;
  stuck = newStuck();
  stuckEvents = 0;
  private fallbackT = 0;
  private forceReplan = false;

  constructor(private nav: NavGrid) {}

  reset() {
    this.path = null;
    this.idx = 0;
    this.plannedGoal = null;
    this.sincePlan = Infinity;
    this.climbing = false;
    this.stuck = newStuck();
    this.fallbackT = 0;
    this.forceReplan = false;
  }

  /** Call when the engine has finished the climb the agent asked for. */
  finishClimb() {
    this.climbing = false;
    this.idx++;
    this.stuck = newStuck();
  }

  update(pos: Vec3, goal: Vec3, dt: number): AgentCmd {
    if (this.climbing) return { kind: "wait" };
    this.sincePlan += dt;
    if (this.fallbackT > 0) {
      this.fallbackT -= dt;
      return { kind: "fallback" };
    }
    const forced = this.forceReplan;
    if (forced || shouldRepath({ hasPath: !!this.path, goal, plannedGoal: this.plannedGoal, sincePlan: this.sincePlan })) {
      this.forceReplan = false;
      this.path = this.nav.findPath(pos, goal);
      this.plannedGoal = { ...goal };
      this.sincePlan = 0;
      this.idx = 0;
      this.plans++;
      // a stuck-triggered replan keeps its escalation count; any other replan starts fresh
      this.stuck = { ...newStuck(pos.x, pos.z), count: forced ? this.stuck.count : 0 };
    }
    const path = this.path;
    if (!path) return { kind: "fallback" };

    while (this.idx < path.points.length) {
      const p = path.points[this.idx];
      if (p.via) {
        this.climbing = true;
        return { kind: "climb", link: p.via };
      }
      const reach = this.idx === path.points.length - 1 ? 0.35 : 0.5;
      if (Math.hypot(p.x - pos.x, p.z - pos.z) < reach) this.idx++;
      else break;
    }
    if (this.idx >= path.points.length) return { kind: "arrived", reachable: path.found };

    const next = path.points[this.idx];
    const s = stepStuck(this.stuck, pos.x, pos.z, dt);
    this.stuck = s.state;
    if (s.stuck) {
      this.stuckEvents++;
      if (s.state.count === 1) {
        this.forceReplan = true;
      } else if (s.state.count === 2) {
        const sn = this.nav.snap(pos);
        this.forceReplan = true;
        if (sn) return { kind: "walk", to: sn };
      } else {
        this.fallbackT = 1.5;
        this.forceReplan = true;
        return { kind: "fallback" };
      }
    }
    return { kind: "walk", to: { x: next.x, z: next.z } };
  }
}

