import type { Agent } from './Agent';

/**
 * Slowblue: uniform-grid neighbour index, rebuilt every fixed step.
 * Boids is the O(n^2) trap; with a cell equal to the perception radius each agent
 * only inspects 9 buckets, so 500 agents stay inside the frame budget.
 * Buckets are reused between rebuilds to keep the GC quiet on mobile.
 */
export class SpatialHash {
  private buckets = new Map<number, Agent[]>();
  private used: Agent[][] = [];

  constructor(public cellSize: number) {}

  private key(cx: number, cy: number): number {
    // Interleave with large primes; grid is unbounded in world space.
    return (Math.imul(cx, 73856093) ^ Math.imul(cy, 19349663)) | 0;
  }

  build(agents: readonly Agent[], cellSize = this.cellSize): void {
    this.cellSize = Math.max(4, cellSize);
    for (const b of this.used) b.length = 0;
    this.used.length = 0;
    for (const a of agents) {
      if (!a.alive) continue;
      const cx = Math.floor(a.x / this.cellSize);
      const cy = Math.floor(a.y / this.cellSize);
      const k = this.key(cx, cy);
      let bucket = this.buckets.get(k);
      if (bucket === undefined) {
        bucket = [];
        this.buckets.set(k, bucket);
      }
      if (bucket.length === 0) this.used.push(bucket);
      bucket.push(a);
    }
  }

  /** Visits every agent in the 3x3 cell block around (x, y). */
  forEachNear(x: number, y: number, visit: (other: Agent) => void): void {
    const cx = Math.floor(x / this.cellSize);
    const cy = Math.floor(y / this.cellSize);
    for (let j = cy - 1; j <= cy + 1; j++) {
      for (let i = cx - 1; i <= cx + 1; i++) {
        const bucket = this.buckets.get(this.key(i, j));
        if (bucket === undefined) continue;
        for (const other of bucket) visit(other);
      }
    }
  }

  /** Test/debug helper: agents within `radius` of a point (exact distance test). */
  queryRadius(x: number, y: number, radius: number): Agent[] {
    const out: Agent[] = [];
    const r2 = radius * radius;
    this.forEachNear(x, y, (o) => {
      const dx = o.x - x;
      const dy = o.y - y;
      if (dx * dx + dy * dy <= r2) out.push(o);
    });
    return out;
  }

  get occupiedCells(): number {
    return this.used.length;
  }

  /** Occupied cell coordinates, for the debug overlay. */
  debugCells(): { cx: number; cy: number; count: number }[] {
    const out: { cx: number; cy: number; count: number }[] = [];
    for (const bucket of this.used) {
      const first = bucket[0];
      if (first === undefined) continue;
      out.push({
        cx: Math.floor(first.x / this.cellSize),
        cy: Math.floor(first.y / this.cellSize),
        count: bucket.length,
      });
    }
    return out;
  }
}
