import { describe, expect, it } from "vitest";
import { NavGrid, PathAgent, REPATH, climbDuration, newStuck, pathLen, sampleClimb, shouldRepath, stepStuck, type NavBounds } from "./nav";
import type { Box } from "./logic";

const box = (minX: number, maxX: number, minY: number, maxY: number, minZ: number, maxZ: number): Box => ({ minX, maxX, minY, maxY, minZ, maxZ });
const bounds: NavBounds = { minX: -20, maxX: 20, minZ: -20, maxZ: 20 };

// a wall across x, a stilt house (roof at 2.6 on posts), a 3 m tower with a 1.2 m block beside it
const wall = box(-12, 4, 0, 3, -0.5, 0.5);
const stiltRoof = box(8, 14, 2.4, 2.6, 8, 14);
const posts = [box(8, 8.3, 0, 2.4, 8, 8.3), box(13.7, 14, 0, 2.4, 8, 8.3), box(8, 8.3, 0, 2.4, 13.7, 14), box(13.7, 14, 0, 2.4, 13.7, 14)];
const tower = box(-16, -12, 0, 3, 10, 14);
const step = box(-12, -10, 0, 1.2, 10, 14);
const colliders: Box[] = [wall, stiltRoof, ...posts, tower, step];
const nav = new NavGrid(colliders, bounds);

const sealedBoxes = [box(-6, 6, 0, 3, -6, -5), box(-6, 6, 0, 3, 5, 6), box(-6, -5, 0, 3, -6, 6), box(5, 6, 0, 3, -6, 6)];

describe("nav grid", () => {
  it("has a ground layer and rooftop layers", () => {
    expect(nav.heights[0]).toBe(0);
    expect(nav.heights).toContain(2.6);
    expect(nav.heights).toContain(3);
  });
  it("blocks solid walls but not the open space under a stilt roof", () => {
    expect(nav.walkableAt(0, 0, 0)).toBe(false);
    expect(nav.walkableAt(0, 11, 11)).toBe(true);
    expect(nav.walkableAt(0, 0, 5)).toBe(true);
  });
  it("only makes cells inside the roof footprint walkable on the roof layer", () => {
    const l = nav.heights.indexOf(2.6);
    expect(nav.walkableAt(l, 11, 11)).toBe(true);
    expect(nav.walkableAt(l, 0, 5)).toBe(false);
    expect(nav.walkableAt(l, 8.1, 11)).toBe(false);
  });
});

describe("A*", () => {
  it("finds a straight path in open ground", () => {
    const p = nav.findPath({ x: 5, y: 0, z: 5 }, { x: 15, y: 0, z: 5 })!;
    expect(p.found).toBe(true);
    expect(p.points.length).toBeLessThanOrEqual(3);
    const last = p.points[p.points.length - 1];
    expect(Math.hypot(last.x - 15, last.z - 5)).toBeLessThan(0.5);
  });
  it("routes around a wall instead of through it", () => {
    const p = nav.findPath({ x: -5, y: 0, z: -5 }, { x: -5, y: 0, z: 5 })!;
    expect(p.found).toBe(true);
    const pts = [{ x: -5, y: 0, z: -5 }, ...p.points];
    for (let i = 1; i < pts.length; i++)
      for (let t = 0; t <= 1; t += 0.02) {
        const x = pts[i - 1].x + (pts[i].x - pts[i - 1].x) * t;
        const z = pts[i - 1].z + (pts[i].z - pts[i - 1].z) * t;
        expect(x > -12 && x < 4 && z > -0.5 && z < 0.5).toBe(false);
      }
    expect(pathLen(pts)).toBeGreaterThan(10.5);
  });
  it("walks under the stilt house", () => {
    const p = nav.findPath({ x: 6, y: 0, z: 11 }, { x: 16, y: 0, z: 11 })!;
    expect(p.found).toBe(true);
    expect(pathLen([{ x: 6, y: 0, z: 11 }, ...p.points])).toBeLessThan(11);
  });
  it("smooths: far fewer points than grid cells", () => {
    const p = nav.findPath({ x: 16, y: 0, z: -16 }, { x: -16, y: 0, z: -4 })!;
    expect(p.points.length).toBeLessThan(6);
  });
  it("returns null when there is no walkable ground near the endpoints", () => {
    expect(nav.findPath({ x: 100, y: 0, z: 100 }, { x: 0, y: 0, z: 5 })).toBeNull();
  });
});

describe("climb links", () => {
  it("links a 2.6 m roof directly to the ground in both directions", () => {
    const roof = nav.heights.indexOf(2.6);
    const up = nav.allLinks.filter((l) => nav.layerOf(l.from) === 0 && nav.layerOf(l.to) === roof);
    const down = nav.allLinks.filter((l) => nav.layerOf(l.from) === roof && nav.layerOf(l.to) === 0);
    expect(up.length).toBeGreaterThan(0);
    expect(down.length).toBe(up.length);
    expect(up.every((l) => l.up)).toBe(true);
  });
  it("climb keys start at the base, rise along the wall and end on the roof", () => {
    const l = nav.allLinks.find((k) => k.up && nav.heights[nav.layerOf(k.to)] === 2.6)!;
    expect(l.keys[0].y).toBe(0);
    expect(l.keys[l.keys.length - 1].y).toBe(2.6);
    const ys = l.keys.map((k) => k.y);
    expect([...ys].sort((a, b) => a - b)).toEqual(ys);
  });
  it("does not link a surface above the max climb rise", () => {
    const high = new NavGrid([box(-3, 3, 0, 6, -3, 3)], bounds);
    expect(high.allLinks.length).toBe(0);
  });
  it("plans a path that climbs onto the roof", () => {
    const p = nav.findPath({ x: 4, y: 0, z: 4 }, { x: 11, y: 2.6, z: 11 })!;
    expect(p.found).toBe(true);
    const climbs = p.points.filter((q) => q.via);
    expect(climbs.length).toBe(1);
    expect(climbs[0].via!.up).toBe(true);
    expect(p.points[p.points.length - 1].y).toBe(2.6);
  });
  it("uses a low block as a stepping stone to a 3 m tower", () => {
    const p = nav.findPath({ x: -8, y: 0, z: 12 }, { x: -14, y: 3, z: 12 })!;
    expect(p.found).toBe(true);
    expect(p.points.filter((q) => q.via).length).toBeGreaterThanOrEqual(1);
    expect(p.points[p.points.length - 1].y).toBe(3);
  });
  it("climb animation is continuous and monotonic going up", () => {
    const l = nav.allLinks.find((k) => k.up && nav.heights[nav.layerOf(k.to)] === 2.6)!;
    const dur = climbDuration(l.keys);
    expect(dur).toBeGreaterThan(0.5);
    let prev = sampleClimb(l.keys, 0);
    for (let t = 0.05; t <= dur + 0.05; t += 0.05) {
      const q = sampleClimb(l.keys, t);
      expect(q.y).toBeGreaterThanOrEqual(prev.y - 1e-9);
      expect(Math.hypot(q.x - prev.x, q.y - prev.y, q.z - prev.z)).toBeLessThan(0.4);
      prev = q;
    }
    expect(prev.y).toBe(2.6);
  });
});

describe("unreachable targets", () => {
  it("returns a partial path to the closest reachable point", () => {
    const sealed = new NavGrid(sealedBoxes, bounds);
    const p = sealed.findPath({ x: 12, y: 0, z: 0 }, { x: 0, y: 0, z: 0 })!;
    expect(p.found).toBe(false);
    expect(p.partial).toBe(true);
    const last = p.points[p.points.length - 1];
    expect(Math.hypot(last.x, last.z)).toBeGreaterThan(5);
    expect(Math.hypot(last.x, last.z)).toBeLessThan(12);
  });
  it("agent reports arrival at the nearest point with reachable=false", () => {
    const sealed = new NavGrid(sealedBoxes, bounds);
    const a = new PathAgent(sealed);
    const pos = { x: 12, y: 0, z: 0 };
    const goal = { x: 0, y: 0, z: 0 };
    let cmd = a.update(pos, goal, 0.016);
    for (let i = 0; i < 2000 && cmd.kind === "walk"; i++) {
      const d = Math.hypot(cmd.to.x - pos.x, cmd.to.z - pos.z) || 1;
      const s = Math.min(0.05, d);
      pos.x += ((cmd.to.x - pos.x) / d) * s;
      pos.z += ((cmd.to.z - pos.z) / d) * s;
      cmd = a.update(pos, goal, 0.016);
    }
    expect(cmd).toEqual({ kind: "arrived", reachable: false });
  });
});

describe("re-path throttle", () => {
  const g = { x: 0, y: 0, z: 0 };
  it("does not re-plan a stationary goal inside the minimum interval", () => {
    expect(shouldRepath({ hasPath: true, goal: g, plannedGoal: g, sincePlan: 0.1 })).toBe(false);
  });
  it("does not re-plan for small goal movement", () => {
    expect(shouldRepath({ hasPath: true, goal: { x: 0.5, y: 0, z: 0 }, plannedGoal: g, sincePlan: 1 })).toBe(false);
  });
  it("re-plans when the goal moved far, but not before the min interval", () => {
    const far = { x: 5, y: 0, z: 0 };
    expect(shouldRepath({ hasPath: true, goal: far, plannedGoal: g, sincePlan: REPATH.minInterval - 0.01 })).toBe(false);
    expect(shouldRepath({ hasPath: true, goal: far, plannedGoal: g, sincePlan: REPATH.minInterval + 0.01 })).toBe(true);
  });
  it("refreshes stale paths and retries missing ones", () => {
    expect(shouldRepath({ hasPath: true, goal: g, plannedGoal: g, sincePlan: REPATH.maxAge + 0.1 })).toBe(true);
    expect(shouldRepath({ hasPath: false, goal: g, plannedGoal: null, sincePlan: REPATH.retry + 0.1 })).toBe(true);
    expect(shouldRepath({ hasPath: false, goal: g, plannedGoal: null, sincePlan: 0.1 })).toBe(false);
  });
  it("agent plans rarely while chasing a nearby moving goal", () => {
    const a = new PathAgent(nav);
    const pos = { x: 5, y: 0, z: 5 };
    for (let i = 0; i < 100; i++) a.update(pos, { x: 14 + Math.sin(i / 10), y: 0, z: 5 }, 0.016);
    expect(a.plans).toBeLessThanOrEqual(4);
  });
});

describe("stuck handling", () => {
  it("flags a walker that makes no progress, and stays quiet when moving", () => {
    let s = newStuck(0, 0);
    let flagged = false;
    for (let i = 0; i < 100; i++) {
      const r = stepStuck(s, 0, 0, 0.05);
      s = r.state;
      flagged ||= r.stuck;
    }
    expect(flagged).toBe(true);
    s = newStuck(0, 0);
    let any = false;
    for (let i = 0; i < 100; i++) {
      const r = stepStuck(s, i * 0.1, 0, 0.05);
      s = r.state;
      any ||= r.stuck;
    }
    expect(any).toBe(false);
  });
  it("agent escalates replan, snap, then legacy fallback when it never moves", () => {
    const a = new PathAgent(nav);
    const pos = { x: 5, y: 0, z: 5 };
    const goal = { x: 15, y: 0, z: 5 };
    const kinds = new Set<string>();
    for (let i = 0; i < 400; i++) kinds.add(a.update(pos, goal, 0.05).kind);
    expect(a.stuckEvents).toBeGreaterThanOrEqual(3);
    expect(a.plans).toBeGreaterThanOrEqual(3);
    expect(kinds.has("fallback")).toBe(true);
    expect(kinds.has("walk")).toBe(true);
  });
  it("agent falls back when there is no nav node for the goal", () => {
    const a = new PathAgent(nav);
    expect(a.update({ x: 5, y: 0, z: 5 }, { x: 500, y: 0, z: 500 }, 0.05).kind).toBe("fallback");
  });
});

describe("path agent end to end", () => {
  it("walks to the climb link, climbs and reaches a rooftop goal", () => {
    const a = new PathAgent(nav);
    const pos = { x: 4, y: 0, z: 4 };
    const goal = { x: 11, y: 2.6, z: 11 };
    let sawClimb = false;
    for (let i = 0; i < 4000; i++) {
      const cmd = a.update(pos, goal, 0.02);
      if (cmd.kind === "walk") {
        const d = Math.hypot(cmd.to.x - pos.x, cmd.to.z - pos.z) || 1;
        const s = Math.min(0.08, d);
        pos.x += ((cmd.to.x - pos.x) / d) * s;
        pos.z += ((cmd.to.z - pos.z) / d) * s;
      } else if (cmd.kind === "climb") {
        sawClimb = true;
        const end = cmd.link.keys[cmd.link.keys.length - 1];
        pos.x = end.x;
        pos.y = end.y;
        pos.z = end.z;
        a.finishClimb();
      } else if (cmd.kind === "arrived") break;
    }
    expect(sawClimb).toBe(true);
    expect(pos.y).toBe(2.6);
    expect(Math.hypot(pos.x - 11, pos.z - 11)).toBeLessThan(1);
  });
});
