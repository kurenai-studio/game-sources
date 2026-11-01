// @ts-check
import { readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export const packageRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
export const fixturesRoot = join(packageRoot, "fixtures");

/**
 * Reads every JSON file in a fixture directory (relative to fixtures/).
 * @param {string} dir
 * @returns {{ name: string, data: any }[]}
 */
export function loadFixtures(dir) {
  const full = join(fixturesRoot, dir);
  return readdirSync(full)
    .filter((f) => f.endsWith(".json"))
    .sort()
    .map((f) => ({
      name: f.replace(/\.json$/, ""),
      data: JSON.parse(readFileSync(join(full, f), "utf8")),
    }));
}

/**
 * A small deterministic PRNG (mulberry32) so generated tests are reproducible.
 * @param {number} seed
 */
export function rng(seed) {
  let a = seed >>> 0;
  const next = () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  return {
    next,
    /** Integer in [min, max]. */
    int: (/** @type {number} */ min, /** @type {number} */ max) =>
      min + Math.floor(next() * (max - min + 1)),
    /** @template T @param {T[]} xs @returns {T} */
    pick: (xs) => /** @type {T} */ (xs[Math.floor(next() * xs.length)]),
  };
}

/**
 * Builds a valid level with sensible defaults.
 * @param {Record<string, any>} [o]
 * @returns {any}
 */
export function makeLevel(o = {}) {
  return {
    schemaVersion: 1,
    levelId: "test-level",
    levelVersion: 1,
    slug: "test-level",
    title: "Test level",
    description: "",
    difficulty: "easy",
    requires: { mechanics: [] },
    board: { width: o.w ?? 5, height: o.h ?? 5, walls: o.walls ?? [] },
    initialState: { position: o.start ?? [0, 4], direction: o.dir ?? "north" },
    availableCommands: o.cmds ?? ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"],
    constraints: { maxCommands: o.maxC ?? 20, maxSteps: o.maxS ?? 100 },
    goal: { type: "reach_tile", position: o.goal ?? [4, 0] },
    hints: [],
  };
}

/** Generates a random valid level from a seeded generator. */
export function randomLevel(/** @type {ReturnType<typeof rng>} */ r) {
  const w = r.int(3, 8);
  const h = r.int(3, 8);
  const density = r.next() * 0.4;
  /** @type {number[][]} */
  const walls = [];
  /** @type {number[][]} */
  const free = [];
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      if (r.next() < density) walls.push([x, y]);
      else free.push([x, y]);
    }
  }
  while (free.length < 2) free.push(/** @type {number[]} */ (walls.pop()));
  const start = r.pick(free);
  let goal = r.pick(free);
  while (goal[0] === start[0] && goal[1] === start[1]) goal = r.pick(free);
  const all = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"];
  const roll = r.next();
  const cmds =
    roll < 0.7
      ? all
      : roll < 0.8
        ? ["MOVE_FORWARD", "TURN_LEFT"]
        : roll < 0.9
          ? ["MOVE_FORWARD", "TURN_RIGHT"]
          : ["MOVE_FORWARD"];
  return makeLevel({
    w,
    h,
    walls: walls.slice(0, 100),
    start,
    goal,
    dir: r.pick(["north", "east", "south", "west"]),
    cmds,
    maxC: r.int(1, 64),
    maxS: r.int(1, 200),
  });
}
