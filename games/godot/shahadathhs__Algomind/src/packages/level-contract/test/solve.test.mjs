// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { simulate, solve, validateLevel } from "../dist/index.js";
import { makeLevel, randomLevel, rng } from "./helpers.mjs";

const ORDER = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"];
const DIRS = ["north", "east", "south", "west"];
const DELTA = { north: [0, -1], east: [1, 0], south: [0, 1], west: [-1, 0] };

/**
 * Independent re-implementation of the documented tie-breaking rule, deliberately written differently from
 * src/solve.ts: every queue entry carries its whole program, and states are strings.
 * @param {any} level
 * @returns {string[] | null} op names
 */
function referenceSolve(level) {
  const walls = new Set(level.board.walls.map((/** @type {number[]} */ w) => `${w[0]},${w[1]}`));
  const available = ORDER.filter((c) => level.availableCommands.includes(c));
  const [sx, sy] = level.initialState.position;
  const [gx, gy] = level.goal.position;
  if (sx === gx && sy === gy) return [];
  const startKey = `${sx},${sy},${level.initialState.direction}`;
  const seen = new Set([startKey]);
  /** @type {{ x: number, y: number, d: string, path: string[] }[]} */
  const queue = [{ x: sx, y: sy, d: level.initialState.direction, path: [] }];
  while (queue.length > 0) {
    const cur = /** @type {any} */ (queue.shift());
    for (const op of available) {
      let { x, y, d } = cur;
      if (op === "MOVE_FORWARD") {
        const [dx, dy] = /** @type {any} */ (DELTA)[d];
        x += dx;
        y += dy;
        if (
          x < 0 ||
          y < 0 ||
          x >= level.board.width ||
          y >= level.board.height ||
          walls.has(`${x},${y}`)
        )
          continue;
      } else {
        const i = DIRS.indexOf(d);
        d = DIRS[(i + (op === "TURN_LEFT" ? 3 : 1)) % 4];
      }
      const k = `${x},${y},${d}`;
      if (seen.has(k)) continue;
      seen.add(k);
      const path = [...cur.path, op];
      if (x === gx && y === gy) return path;
      queue.push({ x, y, d, path });
    }
  }
  return null;
}

/**
 * Exhaustively checks whether any program of exactly `length` commands succeeds (ignores maxSteps).
 * @param {any} level
 * @param {number} length
 */
function anyProgramOfLengthSucceeds(level, length) {
  const relaxed = { ...level, constraints: { ...level.constraints, maxSteps: 1000 } };
  const cmds = ORDER.filter((c) => level.availableCommands.includes(c));
  /** @type {string[]} */
  const ops = [];
  /** @returns {boolean} */
  const rec = () => {
    if (ops.length === length) {
      return (
        simulate(
          relaxed,
          ops.map((op) => ({ op: /** @type {any} */ (op) })),
        ).status === "SUCCEEDED"
      );
    }
    for (const c of cmds) {
      ops.push(c);
      const found = rec();
      ops.pop();
      if (found) return true;
    }
    return false;
  };
  return rec();
}

test("solver output, run through the simulator, succeeds with exactly the reported steps (300 random boards)", () => {
  const r = rng(20260101);
  let solved = 0;
  let unreachable = 0;
  for (let n = 0; n < 300; n++) {
    const level = randomLevel(r);
    assert.deepEqual(validateLevel(level).issues, [], `generated level ${n} must be valid`);
    const solution = solve(level);
    if (solution === null) {
      unreachable += 1;
      continue;
    }
    solved += 1;
    const relaxed = { ...level, constraints: { ...level.constraints, maxSteps: 1000 } };
    const run = simulate(relaxed, solution.program);
    assert.equal(run.status, "SUCCEEDED", `level ${n}`);
    assert.equal(run.reason, "GOAL_REACHED");
    assert.equal(run.steps, solution.steps);
    assert.equal(solution.steps, solution.commands);
    assert.equal(solution.program.length, solution.commands);
    assert.equal(
      solution.fitsConstraints,
      solution.commands <= level.constraints.maxCommands &&
        solution.steps <= level.constraints.maxSteps,
    );
    // Every command the solver used is allowed.
    for (const node of solution.program) assert.ok(level.availableCommands.includes(node.op));
    // fitsConstraints agrees with running the real level.
    const real = simulate(level, solution.program);
    assert.equal(real.status === "SUCCEEDED", solution.steps <= level.constraints.maxSteps);
  }
  assert.ok(solved > 50, `expected many solvable boards, got ${solved}`);
  assert.ok(unreachable > 5, `expected some unreachable boards, got ${unreachable}`);
});

test("the solver returns the exact program of an independent implementation of the documented tie-breaking", () => {
  const r = rng(777);
  for (let n = 0; n < 300; n++) {
    const level = randomLevel(r);
    const expected = referenceSolve(level);
    const actual = solve(level);
    if (expected === null) {
      assert.equal(actual, null, `level ${n}`);
    } else {
      assert.deepEqual(
        actual?.program.map((p) => p.op),
        expected,
        `level ${n}`,
      );
    }
  }
});

test("no shorter program exists (exhaustive search on small boards)", () => {
  const r = rng(99);
  let checked = 0;
  for (let n = 0; n < 150; n++) {
    const level = randomLevel(r);
    const solution = solve(level);
    if (solution === null || solution.commands === 0 || solution.commands > 8) continue;
    checked += 1;
    for (let len = 0; len < solution.commands; len++) {
      assert.equal(
        anyProgramOfLengthSucceeds(level, len),
        false,
        `level ${n}: length ${len} should not succeed`,
      );
    }
    assert.equal(anyProgramOfLengthSucceeds(level, solution.commands), true);
  }
  assert.ok(checked > 20, `expected to check many levels, checked ${checked}`);
});

test("returns null for a goal that cannot be reached and respects availableCommands", () => {
  const walled = makeLevel({
    walls: [
      [3, 0],
      [3, 1],
      [4, 1],
    ],
  });
  assert.equal(solve(walled), null);
  assert.equal(solve(makeLevel({ cmds: ["TURN_LEFT", "TURN_RIGHT"] })), null);
  assert.equal(solve(makeLevel({ cmds: ["MOVE_FORWARD"], start: [0, 4], goal: [4, 0] })), null);
  const onlyForward = solve(makeLevel({ cmds: ["MOVE_FORWARD"], start: [0, 4], goal: [0, 0] }));
  assert.deepEqual(
    onlyForward?.program.map((p) => p.op),
    ["MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD"],
  );
});

test("tie-breaking prefers MOVE_FORWARD, then TURN_LEFT, then TURN_RIGHT", () => {
  // Facing north with the goal directly behind: TL TL MF and TR TR MF both have length 3.
  const behind = solve(makeLevel({ start: [2, 2], goal: [2, 3], dir: "north" }));
  assert.deepEqual(
    behind?.program.map((p) => p.op),
    ["TURN_LEFT", "TURN_LEFT", "MOVE_FORWARD"],
  );
});

test("fitsConstraints reflects both maxCommands and maxSteps", () => {
  assert.equal(
    solve(makeLevel({ start: [0, 4], goal: [0, 1], maxC: 3, maxS: 3 }))?.fitsConstraints,
    true,
  );
  assert.equal(
    solve(makeLevel({ start: [0, 4], goal: [0, 1], maxC: 2, maxS: 3 }))?.fitsConstraints,
    false,
  );
  assert.equal(
    solve(makeLevel({ start: [0, 4], goal: [0, 1], maxC: 3, maxS: 2 }))?.fitsConstraints,
    false,
  );
});

test("the solver does not modify its input", () => {
  const level = makeLevel({ walls: [[2, 2]], start: [0, 2], dir: "east", goal: [4, 2] });
  const copy = structuredClone(level);
  solve(level);
  assert.deepEqual(level, copy);
});

test("the largest board is solved quickly", () => {
  const level = makeLevel({
    w: 12,
    h: 12,
    start: [0, 0],
    dir: "east",
    goal: [11, 11],
    maxC: 64,
    maxS: 1000,
  });
  const t = Date.now();
  const solution = solve(level);
  assert.equal(solution?.commands, 23);
  assert.ok(Date.now() - t < 1000);
});
