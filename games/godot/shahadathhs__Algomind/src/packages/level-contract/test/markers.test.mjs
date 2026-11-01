// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { programSlots, simulate, solve, validateProgram } from "../dist/index.js";
import { makeLevel } from "./helpers.mjs";

const ALL = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT_UNTIL", "IF", "MARK"];
const M = /** @type {any} */ ({ op: "MOVE_FORWARD" });
const L = /** @type {any} */ ({ op: "TURN_LEFT" });
const R = /** @type {any} */ ({ op: "TURN_RIGHT" });
const MARK = /** @type {any} */ ({ op: "MARK" });
/** @param {string} when @param {any[]} then @param {any[]} [other] @returns {any} */
const iff = (when, then, other = []) => ({ op: "IF", when, then, else: other });
/** @param {any[]} body @returns {any} */
const forever = (body) => ({ op: "REPEAT_UNTIL", until: "GOAL", body });
/** @param {Record<string, any>} [o] */
const level = (o = {}) =>
  makeLevel({ cmds: ALL, w: 7, h: 5, start: [3, 2], dir: "east", goal: [0, 0], maxS: 400, ...o });
/** @param {any} lv @param {any} program */
const codes = (lv, program) =>
  validateProgram(lv, program).issues.map((i) => `${i.path}|${i.code}`);

/** The Tremaux search: mark the cell, fresh cell ahead, right, left; otherwise follow the breadcrumb back. */
const TREMAUX = forever([
  MARK,
  iff(
    "FRESH_AHEAD",
    [M],
    [
      iff(
        "FRESH_RIGHT",
        [R, M],
        [
          iff(
            "FRESH_LEFT",
            [L, M],
            [
              iff(
                "BACK_AHEAD",
                [M],
                [iff("BACK_RIGHT", [R, M], [iff("BACK_LEFT", [L, M], [R, R, M])])],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
]);

test("MARK drops a breadcrumb that points behind the automaton, and it is a traced step", () => {
  const result = simulate(level(), [M, MARK, iff("BACK_AHEAD", [L]), R, R, iff("BACK_AHEAD", [R])]);
  assert.deepEqual(
    result.trace.map((t) => [t.op, t.event]),
    [
      ["MOVE_FORWARD", "MOVED"],
      ["MARK", "MARKED"],
      ["TURN_RIGHT", "TURNED"],
      ["TURN_RIGHT", "TURNED"],
      ["TURN_RIGHT", "TURNED"],
    ],
  );
  // After the move east the crumb points west (the start cell). Facing east BACK_AHEAD is false (else is
  // empty); after two right turns the automaton faces west and BACK_AHEAD is true.
});

test("a cell with a breadcrumb keeps it: marking again after turning changes nothing", () => {
  // Mark facing east (arrow west), turn to face north, mark again: the arrow still points west.
  const result = simulate(level(), [M, MARK, L, MARK, iff("BACK_LEFT", [R, R, R])]);
  // Facing north, west is on the left: BACK_LEFT is true, so three right turns run.
  assert.equal(result.trace.filter((t) => t.op === "TURN_RIGHT").length, 3);
});

test("FRESH means a floor cell with no breadcrumb: walls, the edge and marked cells are not fresh", () => {
  const lv = level({ walls: [[4, 2]] });
  assert.equal(simulate(lv, [iff("FRESH_AHEAD", [M])]).steps, 0, "a wall is not fresh");
  assert.equal(
    simulate(lv, [iff("FRESH_LEFT", [L])]).steps,
    1,
    "the open cell to the left is fresh",
  );
  const edge = level({ start: [6, 2], dir: "east" });
  assert.equal(simulate(edge, [iff("FRESH_AHEAD", [M])]).steps, 0, "the board edge is not fresh");
  // A cell that has a breadcrumb is not fresh any more: mark here, step back and look.
  const marked = simulate(level(), [MARK, R, R, M, R, R, iff("FRESH_AHEAD", [M], [L])]);
  assert.equal(marked.trace.at(-1)?.op, "TURN_LEFT");
});

test("BACK is only the cell the automaton's own breadcrumb points to; with no breadcrumb nothing is BACK", () => {
  const lv = level();
  assert.equal(simulate(lv, [iff("BACK_AHEAD", [M], [L])]).trace[0]?.op, "TURN_LEFT");
  const withCrumb = simulate(lv, [MARK, R, R, iff("BACK_AHEAD", [M], [L])]);
  assert.equal(withCrumb.trace.at(-1)?.op, "MOVE_FORWARD");
});

test("an else-if chain runs one branch, and the trace path goes into the nested IF", () => {
  const lv = level({ walls: [[4, 2]] });
  const chain = iff("CLEAR_AHEAD", [M], [iff("CLEAR_RIGHT", [R, M], [L, M])]);
  const result = simulate(lv, [chain]);
  // Ahead is a wall, right (south) is clear: R then M. then.length is 1, so the nested IF is at index 1.
  assert.deepEqual(
    result.trace.map((t) => [t.op, t.node]),
    [
      ["TURN_RIGHT", [0, 1, 0]],
      ["MOVE_FORWARD", [0, 1, 1]],
    ],
  );
  const last = simulate(
    level({
      walls: [
        [4, 2],
        [3, 3],
      ],
    }),
    [chain],
  );
  assert.deepEqual(
    last.trace.map((t) => [t.op, t.node]),
    [
      ["TURN_LEFT", [0, 1, 2]],
      ["MOVE_FORWARD", [0, 1, 3]],
    ],
  );
});

test("slots of an else-if chain: each IF is 1 plus its actions, the last else counts its actions", () => {
  assert.equal(
    programSlots([iff("CLEAR_AHEAD", [M], [iff("CLEAR_RIGHT", [R, M], [L, M])])]),
    1 + 1 + (1 + 2 + 2),
  );
  assert.equal(programSlots([TREMAUX]), 21);
});

test("an else-if chain: one IF in the else, at most six IFs, nothing else beside it", () => {
  const lv = level({ maxC: 64 });
  assert.deepEqual(codes(lv, [iff("CLEAR_AHEAD", [M], [iff("CLEAR_LEFT", [M])])]), []);
  assert.deepEqual(codes(lv, [iff("CLEAR_AHEAD", [M], [iff("CLEAR_LEFT", [M]), M])]), [
    "program[0].else[0].op|NESTED_IF",
  ]);
  assert.deepEqual(codes(lv, [iff("CLEAR_AHEAD", [iff("CLEAR_LEFT", [M])])]), [
    "program[0].then[0].op|NESTED_IF",
  ]);
  const chainOf = (/** @type {number} */ n) => {
    /** @type {any} */
    let node = iff("CLEAR_AHEAD", [M]);
    for (let i = 1; i < n; i += 1) node = iff("CLEAR_AHEAD", [M], [node]);
    return node;
  };
  assert.deepEqual(codes(lv, [chainOf(6)]), []);
  assert.equal(codes(lv, [chainOf(7)]).length, 1);
});

test("marker sensors need MARK offered", () => {
  const without = level({ cmds: ["MOVE_FORWARD", "IF"], maxC: 64 });
  assert.deepEqual(codes(without, [iff("FRESH_AHEAD", [M])]), [
    "program[0].when|COMMAND_NOT_AVAILABLE",
  ]);
  assert.deepEqual(codes(without, [iff("CLEAR_AHEAD", [M])]), []);
  assert.deepEqual(codes(level({ maxC: 64 }), [iff("BACK_LEFT", [M])]), []);
});

test("the Tremaux search finishes a maze with a loop, where the right-hand rule goes round for ever", () => {
  const rows = [
    "#########",
    "#.......#",
    "#.#####.#",
    "#.#...#.#",
    "#.#.#.#.#",
    "#.#.#...#",
    "#.#.#####",
    "#...#####",
    "#########",
  ];
  /** @type {number[][]} */
  const walls = [];
  rows.forEach((row, y) =>
    row.split("").forEach((ch, x) => {
      if (ch === "#") walls.push([x, y]);
    }),
  );
  // The goal is inside the little room (4,3): the room's walls are joined to the rest, but the corridor loops.
  const lv = level({ w: 9, h: 9, walls, start: [1, 1], dir: "east", goal: [3, 5], maxS: 600 });
  const result = simulate(lv, [TREMAUX]);
  assert.equal(result.reason, "GOAL_REACHED", String(result.steps));
  assert.equal(solve(lv)?.commands !== undefined, true);
});
