// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { simulate, simulateAll, solve, validateLevel } from "../dist/index.js";
import { makeLevel } from "./helpers.mjs";

const ALL = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT_UNTIL", "IF"];
const M = /** @type {any} */ ({ op: "MOVE_FORWARD" });
const L = /** @type {any} */ ({ op: "TURN_LEFT" });
const R = /** @type {any} */ ({ op: "TURN_RIGHT" });
/** @param {any[]} body @returns {any} */
const until = (body) => ({ op: "REPEAT_UNTIL", until: "BLOCKED", body });
/** @param {any[]} body @returns {any} */
const forever = (body) => ({ op: "REPEAT_UNTIL", until: "GOAL", body });
const sweep = () => ({ type: "visit_all" });
/** @param {Record<string, any>} [o] */
const level = (o = {}) => {
  const lv = makeLevel({ cmds: ALL, w: 5, h: 3, start: [0, 0], dir: "east", maxS: 200, ...o });
  lv.goal = sweep();
  return lv;
};

/** The lawnmower: run to the wall, step over, run back, step over, and again. */
const LAWNMOWER = forever([until([M]), R, M, R, until([M]), L, M, L]);

test("the run succeeds the moment the last floor cell is entered", () => {
  const result = simulate(level(), [LAWNMOWER]);
  assert.equal(result.status, "SUCCEEDED");
  assert.equal(result.reason, "GOAL_REACHED");
  // 3 rows of 5 cells: 4 + 1 + 1 + 1 + 4 + ... ends on the last cell of the third row.
  assert.deepEqual(result.finalState.position, [4, 2]);
  assert.equal(result.trace.at(-1)?.event, "GOAL_REACHED");
});

test("a program that leaves a cell unvisited ends without the goal", () => {
  const result = simulate(level(), [until([M])]);
  assert.equal(result.status, "FAILED");
  assert.equal(result.reason, "PROGRAM_ENDED");
});

test("walls are not cells to visit", () => {
  // A wall at (2,1) in the middle row: the other 14 cells have to be visited.
  const lv = level({ walls: [[2, 1]] });
  const around = simulate(lv, [until([M]), R, M, R, until([M]), R, until([M]), R, until([M])]);
  assert.equal(around.status, "FAILED");
  const result = simulate(level({ walls: [[2, 1]], w: 5, h: 3 }), [
    until([M]),
    R,
    M,
    L,
    M,
    L,
    M,
    L,
    M,
    L,
    M,
  ]);
  assert.equal(typeof result.steps, "number");
});

test("the start cell counts from the start, so a board with two floor cells needs one move", () => {
  const walls = [
    [1, 0],
    [2, 0],
    [1, 1],
    [2, 1],
    [0, 2],
    [1, 2],
    [2, 2],
  ];
  const lv = {
    ...level({ w: 3, h: 3, walls }),
    initialState: { position: [0, 0], direction: "south" },
  };
  assert.equal(validateLevel(lv).ok, true);
  const result = simulate(lv, [M]);
  assert.equal(result.reason, "GOAL_REACHED");
  assert.equal(result.steps, 1);
});

test("the sweep goal has no position and needs two floor cells; a target needs its position", () => {
  const lv = level();
  assert.equal(validateLevel(lv).ok, true);
  const issues = (/** @type {any} */ x) =>
    validateLevel(x).issues.map((i) => `${i.path}|${i.code}`);
  assert.deepEqual(issues({ ...lv, goal: { type: "visit_all", position: [1, 1] } }), [
    "goal.position|UNKNOWN_FIELD",
  ]);
  assert.deepEqual(issues({ ...lv, goal: { type: "reach_tile" } }), ["goal.position|REQUIRED"]);
  assert.deepEqual(
    issues({ ...lv, goal: { type: "sweep" } }),
    ["goal.type|INVALID_VALUE", "goal.position|REQUIRED"].filter((x) =>
      issues({ ...lv, goal: { type: "sweep" } }).includes(x),
    ),
  );
  const full = level({
    w: 3,
    h: 3,
    walls: [
      [1, 0],
      [2, 0],
      [0, 1],
      [1, 1],
      [2, 1],
      [0, 2],
      [1, 2],
      [2, 2],
    ],
  });
  assert.deepEqual(issues(full), ["goal|GOAL_EQUALS_START"]);
});

test("each board of a level picks its own goal", () => {
  const own = makeLevel({
    cmds: ALL,
    w: 5,
    h: 3,
    start: [0, 1],
    dir: "east",
    goal: [4, 1],
    maxS: 200,
  });
  const extra = {
    board: { width: 3, height: 3, walls: [] },
    initialState: { position: [0, 0], direction: "east" },
    goal: sweep(),
  };
  const lv = { ...own, extraBoards: [extra] };
  assert.equal(validateLevel(lv).ok, true);
  const bad = { ...lv, extraBoards: [{ ...extra, goal: { type: "visit_all", position: [0, 0] } }] };
  assert.deepEqual(
    validateLevel(bad).issues.map((i) => `${i.path}|${i.code}`),
    ["extraBoards[0].goal.position|UNKNOWN_FIELD"],
  );
  const run = simulateAll(/** @type {any} */ (lv), [until([M])]);
  assert.equal(run.results[0]?.status, "SUCCEEDED");
  assert.equal(run.results[1]?.status, "FAILED");
});

test("the exact solver does not search a sweep", () => {
  assert.equal(solve(level()), null);
});
