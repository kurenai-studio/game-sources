// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { simulate, solve, validateLevel, validateProgram } from "../dist/index.js";
import { makeLevel, rng } from "./helpers.mjs";

const ALL = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT"];
const M = { op: "MOVE_FORWARD" };
const L = { op: "TURN_LEFT" };
const R = { op: "TURN_RIGHT" };
/** @param {number} count @param {any[]} body @returns {any} */
const rep = (count, body) => ({ op: "REPEAT", count, body });
/** @param {Record<string, any>} [o] */
const level = (o = {}) => makeLevel({ cmds: ALL, ...o });
/** @param {any} lv @param {any} program */
const codes = (lv, program) =>
  validateProgram(lv, program).issues.map((i) => `${i.path}|${i.code}`);

test("a REPEAT costs no step of its own: only the primitives it runs are counted", () => {
  const lv = level({ w: 7, h: 7, start: [0, 6], dir: "north", goal: [6, 6], maxS: 100 });
  const result = simulate(lv, [rep(3, [M, M, L, R])]);
  assert.equal(result.reason, "PROGRAM_ENDED");
  assert.equal(result.steps, 12);
  assert.equal(result.trace.length, 12);
});

test("slots: a primitive is 1 and a REPEAT is 1 plus its body", () => {
  const lv = level({ maxC: 5 });
  assert.deepEqual(codes(lv, [rep(6, [M, R, M, L])]), []);
  assert.deepEqual(codes(lv, [rep(6, [M, R, M, L]), M]), ["program|TOO_MANY_COMMANDS"]);
  assert.deepEqual(codes(lv, [M, M, M, M, M]), []);
  assert.deepEqual(codes(lv, [M, M, M, M, M, M]), ["program|TOO_MANY_COMMANDS"]);
});

test("loop limits: count 2 to 11, body 1 to 8 primitives, no loop in a loop", () => {
  const lv = level({ maxC: 64 });
  assert.deepEqual(codes(lv, [rep(2, [M])]), []);
  assert.deepEqual(codes(lv, [rep(11, Array(8).fill(M))]), []);
  assert.deepEqual(codes(lv, [rep(1, [M])]), ["program[0].count|OUT_OF_RANGE"]);
  assert.deepEqual(codes(lv, [rep(12, [M])]), ["program[0].count|OUT_OF_RANGE"]);
  assert.deepEqual(codes(lv, [rep(2, [])]), ["program[0].body|LENGTH_OUT_OF_RANGE"]);
  assert.deepEqual(codes(lv, [rep(2, Array(9).fill(M))]), ["program[0].body|LENGTH_OUT_OF_RANGE"]);
  assert.deepEqual(codes(lv, [rep(2, [rep(2, [M])])]), ["program[0].body[0].op|NESTED_REPEAT"]);
  assert.deepEqual(codes(lv, [{ op: "REPEAT", count: 2 }]), ["program[0].body|REQUIRED"]);
  assert.deepEqual(codes(lv, [{ op: "REPEAT", body: [M] }]), ["program[0].count|REQUIRED"]);
  assert.deepEqual(codes(lv, [{ op: "REPEAT", count: 2.5, body: [M] }]), [
    "program[0].count|INVALID_TYPE",
  ]);
  assert.deepEqual(codes(lv, [{ ...M, count: 2 }]), ["program[0].count|UNKNOWN_FIELD"]);
});

test("a loop needs REPEAT in availableCommands, and so does its body's use of primitives", () => {
  const without = makeLevel({ cmds: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"] });
  assert.deepEqual(codes(without, [rep(2, [M])]), ["program[0].op|COMMAND_NOT_AVAILABLE"]);
  const onlyMove = level({ cmds: ["MOVE_FORWARD", "REPEAT"] });
  assert.deepEqual(codes(onlyMove, [rep(2, [M, L])]), [
    "program[0].body[1].op|COMMAND_NOT_AVAILABLE",
  ]);
});

test("REPEAT is a known command for a level; unknown names still are not", () => {
  assert.equal(validateLevel(level()).ok, true);
  const bad = level({ cmds: ["MOVE_FORWARD", "REPEATS"] });
  assert.deepEqual(
    validateLevel(bad).issues.map((i) => `${i.path}|${i.code}`),
    ["availableCommands[1]|UNKNOWN_COMMAND"],
  );
});

test("reaching the goal inside a loop ends the run: nothing after it runs or is counted", () => {
  const lv = level({ start: [0, 2], dir: "east", goal: [2, 2] });
  const result = simulate(lv, [rep(5, [M, M, L])]);
  assert.equal(result.status, "SUCCEEDED");
  assert.equal(result.steps, 2);
  assert.deepEqual(result.trace.at(-1)?.node, [0, 1]);
  assert.equal(result.trace.at(-1)?.round, 1);
});

test("the step limit applies inside a loop, before each primitive", () => {
  const lv = level({ w: 8, h: 3, start: [0, 1], dir: "east", goal: [7, 0], maxS: 5 });
  const result = simulate(lv, [rep(4, [M, M])]);
  assert.equal(result.reason, "STEP_LIMIT");
  assert.equal(result.steps, 5);
});

test("a blocked move inside a loop names the instruction and the round", () => {
  const lv = level({ walls: [[4, 4]], start: [0, 4], dir: "east", goal: [0, 0] });
  const result = simulate(lv, [rep(3, [M, M])]);
  assert.equal(result.reason, "BLOCKED_BY_WALL");
  assert.deepEqual(result.blockedCell, [4, 4]);
  assert.deepEqual(result.trace.at(-1)?.node, [0, 1]);
  assert.equal(result.trace.at(-1)?.round, 2);
});

test("a malformed loop stops the run instead of being skipped", () => {
  const lv = level();
  for (const bad of [
    { op: "REPEAT", count: 1, body: [M] },
    { op: "REPEAT", count: 2, body: [] },
    { op: "REPEAT", count: 2, body: [rep(2, [rep(2, [M])])] },
    { op: "REPEAT", count: "2", body: [M] },
    { op: "REPEAT", count: 2 },
  ]) {
    const result = simulate(lv, /** @type {any} */ ([bad]));
    assert.equal(result.reason, "INVALID_INSTRUCTION");
    assert.equal(result.steps, 0);
  }
});

/**
 * Brute force with the real simulator: the fewest slots of any program whose loops follow the rules, searched
 * up to `limit` slots. Independent of the solver, which uses behaviour tables and a shortest-path search.
 * @param {any} lv
 * @param {number} limit
 */
function bruteForcePar(lv, limit) {
  const prims = [M, L, R];
  /** @type {any[][]} */
  const atomsBySize = [[]];
  atomsBySize[1] = prims;
  /** @param {number} n @returns {any[][]} */
  const bodies = (n) => {
    /** @type {any[][]} */
    let out = [[]];
    for (let i = 0; i < n; i += 1) out = out.flatMap((b) => prims.map((p) => [...b, p]));
    return out;
  };
  for (let size = 2; size <= limit; size += 1) {
    atomsBySize[size] = bodies(size - 1).flatMap((body) =>
      Array.from({ length: 10 }, (_, k) => rep(k + 2, body)),
    );
  }
  let best = Infinity;
  /** @param {any[]} program @param {number} used */
  const search = (program, used) => {
    if (used >= best) return;
    if (program.length > 0 && simulate(lv, program).status === "SUCCEEDED") {
      best = used;
      return;
    }
    for (let size = 1; size <= limit - used && used + size < best; size += 1) {
      for (const atom of atomsBySize[size] ?? []) search([...program, atom], used + size);
    }
  };
  search([], 0);
  return best === Infinity ? null : best;
}

test("par with REPEAT equals a brute-force search of all programs, on random small boards", () => {
  const r = rng(20260519);
  let checked = 0;
  for (let n = 0; n < 40; n += 1) {
    const w = r.int(3, 5);
    const h = r.int(3, 5);
    /** @type {number[][]} */
    const walls = [];
    /** @type {number[][]} */
    const free = [];
    for (let y = 0; y < h; y += 1) {
      for (let x = 0; x < w; x += 1) (r.next() < 0.25 ? walls : free).push([x, y]);
    }
    if (free.length < 2) continue;
    const start = r.pick(free);
    let goal = r.pick(free);
    while (goal[0] === start[0] && goal[1] === start[1]) goal = r.pick(free);
    const lv = level({
      w,
      h,
      walls,
      start,
      goal,
      dir: r.pick(["north", "east", "south", "west"]),
      maxC: 64,
      maxS: 1000,
    });
    const solved = solve(lv);
    const brute = bruteForcePar(lv, 5);
    if (brute === null) {
      assert.ok(
        solved === null || solved.commands > 5,
        `level ${n}: brute force found nothing within 5`,
      );
    } else {
      assert.ok(solved, `level ${n}: solver found nothing but brute force found ${brute}`);
      assert.equal(solved.commands, brute, `level ${n}`);
      assert.equal(simulate(lv, solved.program).status, "SUCCEEDED");
      checked += 1;
    }
  }
  assert.ok(checked >= 10, `only ${checked} boards were within reach of the brute force`);
});

test("the solver's program always solves the level and fits the loop rules", () => {
  const r = rng(7);
  for (let n = 0; n < 60; n += 1) {
    const w = r.int(3, 12);
    const h = r.int(3, 12);
    /** @type {number[][]} */
    const walls = [];
    /** @type {number[][]} */
    const free = [];
    for (let y = 0; y < h; y += 1) {
      for (let x = 0; x < w; x += 1) (r.next() < 0.3 ? walls : free).push([x, y]);
    }
    if (free.length < 2) continue;
    const start = r.pick(free);
    let goal = r.pick(free);
    while (goal[0] === start[0] && goal[1] === start[1]) goal = r.pick(free);
    const lv = level({
      w,
      h,
      walls,
      start,
      goal,
      dir: r.pick(["north", "south"]),
      maxC: 64,
      maxS: 1000,
    });
    const solved = solve(lv);
    if (!solved) continue;
    assert.deepEqual(
      validateProgram({ ...lv, constraints: { maxCommands: 64, maxSteps: 1000 } }, solved.program)
        .issues,
      [],
    );
    const run = simulate(lv, solved.program);
    assert.equal(run.status, "SUCCEEDED");
    assert.equal(run.steps, solved.steps);
    const flat = solve({ ...lv, availableCommands: ALL.slice(0, 3) });
    assert.ok(flat && solved.commands <= flat.commands);
  }
});

test("the solver on the largest board stays fast enough for the publish gate", () => {
  const walls = [];
  for (let x = 0; x < 11; x += 2)
    for (let y = 1; y < 11; y += 2) if ((x + y) % 4 === 1) walls.push([x, y]);
  const lv = level({
    w: 12,
    h: 12,
    walls,
    start: [0, 11],
    dir: "north",
    goal: [11, 0],
    maxC: 64,
    maxS: 1000,
  });
  const t0 = performance.now();
  const solved = solve(lv);
  const ms = performance.now() - t0;
  assert.ok(solved);
  assert.ok(ms < 3000, `solve took ${ms.toFixed(0)} ms`);
});

test("without REPEAT offered the solver is unchanged: the loop search is not used", () => {
  const lv = makeLevel({ w: 7, h: 7, start: [0, 6], goal: [0, 0] });
  const solved = solve(lv);
  assert.equal(solved?.commands, 6);
  assert.ok(solved?.program.every((n) => n.op === "MOVE_FORWARD"));
});
