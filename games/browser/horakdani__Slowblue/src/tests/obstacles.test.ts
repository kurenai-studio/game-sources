import { describe, expect, it } from 'vitest';
import { ObstacleSystem, SECTION_SPACING } from '../src/sim/ObstacleSystem';
import { SwarmSimulation } from '../src/sim/SwarmSimulation';
import { inertTuning, makeContext, place, stepMany, W } from './helpers';

const STEP = 5;

/**
 * Flood fill from the entry edge (high Y, where the shoal comes from) to the exit
 * edge (low Y). Answers "can a shoal physically get through this at all".
 */
function routeExists(o: ObstacleSystem, exitY: number, entryY: number): boolean {
  const cols = Math.ceil(W / STEP) + 1;
  const rows = Math.ceil((entryY - exitY) / STEP) + 1;
  const at = (cx: number, ry: number): boolean =>
    o.hit(cx * STEP, entryY - ry * STEP, 1) === null;
  const seen = new Uint8Array(cols * rows);
  const stack: number[] = [];
  for (let cx = 0; cx < cols; cx++) {
    if (at(cx, 0)) {
      seen[cx] = 1;
      stack.push(cx);
    }
  }
  while (stack.length > 0) {
    const i = stack.pop()!;
    const cx = i % cols;
    const ry = Math.floor(i / cols);
    if (ry >= rows - 1) return true;
    for (const [dx, dy] of [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ] as const) {
      const nx = cx + dx;
      const ny = ry + dy;
      if (nx < 0 || nx >= cols || ny < 0 || ny >= rows) continue;
      const j = ny * cols + nx;
      if (seen[j] === 1 || !at(nx, ny)) continue;
      seen[j] = 1;
      stack.push(j);
    }
  }
  return false;
}

describe('ObstacleSystem generation', () => {
  it('produces all three situations in a cycle', () => {
    const o = new ObstacleSystem(W, 7);
    o.ensureAhead(-4000);
    const kinds = o.sections.slice(0, 3).map((s) => s.kind);
    expect(kinds).toEqual(['gate', 'rock', 'narrows']);
  });

  it('spaces sections evenly ahead of the camera', () => {
    const o = new ObstacleSystem(W, 7);
    o.ensureAhead(-4000);
    const ys = o.sections.map((s) => s.lineY);
    expect(ys.length).toBeGreaterThanOrEqual(4);
    expect(ys[0]! - ys[1]!).toBeCloseTo(SECTION_SPACING, 6);
  });

  it('is deterministic per seed and different across seeds', () => {
    const layout = (seed: number): number[] => {
      const o = new ObstacleSystem(W, seed);
      o.ensureAhead(-5000);
      return o.activeBlobs.map((b) => Math.round(b.x * 100));
    };
    expect(layout(11)).toEqual(layout(11));
    expect(layout(11)).not.toEqual(layout(12));
  });

  it('gives every narrows a rescue pod', () => {
    const o = new ObstacleSystem(W, 3);
    o.ensureAhead(-6000);
    const narrows = o.sections.filter((s) => s.kind === 'narrows');
    expect(narrows.length).toBeGreaterThan(0);
    for (const s of narrows) {
      expect(s.podHints.length).toBe(1);
      expect(s.podHints[0]!.x).toBeGreaterThan(0);
      expect(s.podHints[0]!.x).toBeLessThan(W);
    }
  });

  it('leaves a passable gap in every gate', () => {
    const o = new ObstacleSystem(W, 5);
    o.ensureAhead(-9000);
    for (const s of o.sections) {
      if (s.kind !== 'gate') continue;
      let open = 0;
      for (let x = 2; x < W; x += 2) {
        if (o.hit(x, s.lineY, 1) === null) open++;
      }
      // A meaningful slice of the width must be water at the gate line itself.
      expect(open * 2).toBeGreaterThan(W * 0.12);
    }
  });

  it('always leaves a route through, and always actually obstructs', () => {
    // The two invariants that make a section playable at all. A flood fill is the
    // only honest way to check the first: the narrows funnel has dead-end channels
    // either side of it, so counting open spans on a scan line proves nothing.
    // Run deep enough to cover every archetype in every zone, on several seeds -
    // a generator that is only correct on one seed is not correct.
    for (const seed of [5, 41, 907, 12345]) {
      const o = new ObstacleSystem(W, seed);
      o.ensureAhead(-30000);
      expect(o.sections.length).toBeGreaterThan(30);
      expect(new Set(o.sections.map((s) => s.kind)).size).toBe(6);
      for (const s of o.sections) {
        expect(routeExists(o, s.minY - 60, s.maxY + 300), `${s.kind} #${s.id} seed ${seed}`).toBe(
          true,
        );
        let openAtLine = 0;
        for (let x = 1; x < W; x += 2) if (o.hit(x, s.lineY, 1) === null) openAtLine += 2;
        expect(openAtLine, `${s.kind} #${s.id} seed ${seed}`).toBeLessThan(W * 0.62);
      }
    }
  });

  it('keeps the chicane passable at its tightest, on every row', () => {
    const o = new ObstacleSystem(W, 17);
    o.ensureAhead(-30000);
    const drifts = o.sections.filter((s) => s.kind === 'drift');
    expect(drifts.length).toBeGreaterThan(2);
    for (const s of drifts) {
      // Three staggered rows, each with its own gap: the flood fill has to weave.
      expect(routeExists(o, s.minY - 40, s.maxY + 200)).toBe(true);
    }
  });

  it('prunes sections left behind and keeps active blobs in sync', () => {
    const o = new ObstacleSystem(W, 5);
    o.ensureAhead(-4000);
    const before = o.sections.length;
    o.prune(-1500);
    expect(o.sections.length).toBeLessThan(before);
    const minY = Math.min(...o.activeBlobs.map((b) => b.y));
    expect(Number.isFinite(minY)).toBe(true);
  });
});

describe('collision and avoidance', () => {
  it('detects a point inside a blob and not outside it', () => {
    const o = new ObstacleSystem(W, 1);
    o.ensureAhead(-800);
    const b = o.activeBlobs[0]!;
    expect(o.hit(b.x, b.y)).not.toBeNull();
    // Straight above the chain there is nothing but water.
    expect(o.hit(b.x, b.y - b.r * 5)).toBeNull();
  });

  it('steers away from a surface it is approaching', () => {
    const o = new ObstacleSystem(W, 1);
    o.ensureAhead(-800);
    const b = o.activeBlobs[0]!;
    const out = { x: 0, y: 0 };
    o.avoid(b.x, b.y + b.r + 10, 0, -100, 0.45, 40, out);
    expect(out.y).toBeGreaterThan(0);
  });

  it('applies no avoidance force far from any rock', () => {
    const o = new ObstacleSystem(W, 1);
    o.ensureAhead(-800);
    const out = { x: 1, y: 1 };
    o.avoid(W * 0.5, 400, 0, -100, 0.45, 40, out);
    expect(out.x).toBe(0);
    expect(out.y).toBe(0);
  });

  it('keeps a swarm out of a rock instead of letting it swim through', () => {
    const o = new ObstacleSystem(W, 1);
    o.ensureAhead(-800);
    const b = o.activeBlobs[Math.floor(o.activeBlobs.length / 2)]!;
    const swarm = new SwarmSimulation(1);
    const agents = place(swarm, [{ x: b.x, y: b.y + b.r + 60, vx: 0, vy: -120 }]);
    const ctx = makeContext(
      inertTuning({ obstacleAvoidance: 9, migrationForce: 1.5, cruiseSpeed: 120 }),
      undefined,
      o,
    );
    stepMany(swarm, ctx, 90);
    const d = Math.hypot(agents[0]!.x - b.x, agents[0]!.y - b.y);
    expect(d).toBeGreaterThan(b.r * 0.85);
  });

  it('counts a section as cleared only once the centroid crosses it', () => {
    const o = new ObstacleSystem(W, 1);
    o.ensureAhead(-2000);
    const first = o.sections[0]!;
    expect(o.updateProgress(first.lineY + 10).length).toBe(0);
    expect(o.updateProgress(first.lineY - 100).length).toBe(1);
    expect(o.updateProgress(first.lineY - 200).length).toBe(0);
  });
});
