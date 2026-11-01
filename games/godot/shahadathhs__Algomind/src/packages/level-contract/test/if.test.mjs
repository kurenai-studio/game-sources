// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { programSlots, simulate, validateProgram } from "../dist/index.js";
import { makeLevel } from "./helpers.mjs";

const ALL = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT", "REPEAT_UNTIL", "IF"];
const M = { op: "MOVE_FORWARD" };
const L = { op: "TURN_LEFT" };
const R = { op: "TURN_RIGHT" };
/** @param {string} when @param {any[]} then @param {any[]} [other] @returns {any} */
const iff = (when, then, other = []) => ({ op: "IF", when, then, else: other });
/** @param {any[]} body @returns {any} */
const forever = (body) => ({ op: "REPEAT_UNTIL", until: "GOAL", body });
/** @param {Record<string, any>} [o] */
const level = (o = {}) => makeLevel({ cmds: ALL, ...o });
/** @param {any} lv @param {any} program */
const codes = (lv, program) =>
  validateProgram(lv, program).issues.map((i) => `${i.path}|${i.code}`);

/** The right-hand rule in two decisions. */
const RIGHT_HAND = forever([iff("CLEAR_RIGHT", [R]), iff("CLEAR_AHEAD", [M], [L])]);

test("an IF runs its then branch when the sensor is true and its else branch when it is not", () => {
  const lv = level({ w: 5, h: 5, walls: [[2, 1]], start: [2, 2], dir: "north", goal: [4, 4] });
  const blocked = simulate(lv, [iff("CLEAR_AHEAD", [M], [R, M])]);
  assert.deepEqual(
    blocked.trace.map((t) => t.op),
    ["TURN_RIGHT", "MOVE_FORWARD"],
  );
  assert.deepEqual(
    blocked.trace.map((t) => t.node),
    [
      [0, 1],
      [0, 2],
    ],
  );
  const open = simulate(level({ w: 5, h: 5, start: [2, 2], dir: "north", goal: [4, 4] }), [
    iff("CLEAR_AHEAD", [M], [R, M]),
  ]);
  assert.deepEqual(
    open.trace.map((t) => t.node),
    [[0, 0]],
  );
});

test("reading a sensor is free: only the executed primitives are steps", () => {
  const lv = level({ w: 5, h: 5, start: [2, 2], dir: "north", goal: [4, 4] });
  const result = simulate(lv, [iff("CLEAR_LEFT", [L]), iff("CLEAR_AHEAD", [M, M, M])]);
  assert.equal(result.steps, 4);
});

test("the three sensors look ahead, left and right of the facing, and see walls and the edge", () => {
  const lv = level({ w: 3, h: 3, walls: [[2, 1]], start: [1, 1], dir: "north", goal: [0, 0] });
  // Facing north at (1,1): ahead (1,0) is free, left (0,1) is free, right (2,1) is a wall.
  for (const [when, steps] of [
    ["CLEAR_AHEAD", 1],
    ["CLEAR_LEFT", 1],
    ["CLEAR_RIGHT", 0],
  ]) {
    const result = simulate(lv, [iff(String(when), [{ op: "TURN_LEFT" }])]);
    assert.equal(result.steps, steps, String(when));
  }
  // At the edge: facing west at (0,0) the cell ahead is off the board.
  const edge = level({ w: 3, h: 3, start: [0, 0], dir: "west", goal: [2, 2] });
  assert.equal(simulate(edge, [iff("CLEAR_AHEAD", [M])]).steps, 0);
});

test("an IF inside a loop body is traced with the loop item and the branch position", () => {
  const lv = level({ w: 6, h: 5, start: [0, 2], dir: "east", goal: [5, 4], maxS: 50 });
  const result = simulate(lv, [
    { op: "REPEAT", count: 2, body: [iff("CLEAR_AHEAD", [M, M], [R]), L] },
  ]);
  assert.deepEqual(
    result.trace.map((t) => t.node),
    [
      [0, 0, 0],
      [0, 0, 1],
      [0, 1],
      [0, 0, 0],
      [0, 0, 1],
      [0, 1],
    ],
  );
  assert.deepEqual(
    result.trace.map((t) => t.round),
    [1, 1, 1, 2, 2, 2],
  );
});

test("REPEAT_UNTIL GOAL keeps going until the goal: the right-hand rule solves a maze", () => {
  // A spiral corridor: following the right-hand wall reaches the centre.
  /** @type {number[][]} */
  const walls = [];
  const rows = ["#######", "#.....#", "#.###.#", "#.#...#", "#.#####", "#......", "#######"];
  rows.forEach((row, y) =>
    row.split("").forEach((ch, x) => {
      if (ch === "#") walls.push([x, y]);
    }),
  );
  const lv = level({ w: 7, h: 7, walls, start: [1, 5], dir: "east", goal: [3, 3], maxS: 200 });
  const result = simulate(lv, [RIGHT_HAND]);
  assert.equal(result.reason, "GOAL_REACHED", JSON.stringify(result.finalState));
});

test("a round that runs no primitive would repeat for ever: it stops the run", () => {
  const lv = level({ w: 5, h: 5, walls: [[2, 1]], start: [2, 2], dir: "north", goal: [4, 4] });
  const result = simulate(lv, [forever([iff("CLEAR_AHEAD", [M])])]);
  assert.equal(result.reason, "STEP_LIMIT");
  assert.equal(result.steps, 0);
});

test("REPEAT_UNTIL GOAL ends at the step limit when the goal is never reached", () => {
  const lv = level({ w: 5, h: 5, start: [2, 2], dir: "north", goal: [4, 4], maxS: 9 });
  const result = simulate(lv, [forever([L])]);
  assert.equal(result.reason, "STEP_LIMIT");
  assert.equal(result.steps, 9);
});

test("slots: an IF is 1 plus its branches and a loop is 1 plus the slots of its body", () => {
  assert.equal(programSlots([iff("CLEAR_AHEAD", [M], [R, M])]), 4);
  assert.equal(programSlots([RIGHT_HAND]), 6);
  const lv = level({ maxC: 6 });
  assert.deepEqual(codes(lv, [RIGHT_HAND]), []);
  assert.deepEqual(codes(lv, [RIGHT_HAND, M]), ["program|TOO_MANY_COMMANDS"]);
});

test("IF validation: sensor, branches, nesting, availability", () => {
  const lv = level({ maxC: 64 });
  assert.deepEqual(codes(lv, [{ op: "IF", then: [M], else: [] }]), ["program[0].when|REQUIRED"]);
  assert.deepEqual(codes(lv, [iff("CLEAR_BEHIND", [M])]), ["program[0].when|INVALID_VALUE"]);
  assert.deepEqual(codes(lv, [{ op: "IF", when: 3, then: [M], else: [] }]), [
    "program[0].when|INVALID_TYPE",
  ]);
  assert.deepEqual(codes(lv, [iff("CLEAR_AHEAD", [])]), ["program[0].then|LENGTH_OUT_OF_RANGE"]);
  assert.deepEqual(codes(lv, [iff("CLEAR_AHEAD", [M, M, M, M, M])]), [
    "program[0].then|LENGTH_OUT_OF_RANGE",
  ]);
  assert.deepEqual(codes(lv, [iff("CLEAR_AHEAD", [M], [M, M, M, M, M])]), [
    "program[0].else|LENGTH_OUT_OF_RANGE",
  ]);
  assert.deepEqual(codes(lv, [{ op: "IF", when: "CLEAR_AHEAD", then: [M] }]), [
    "program[0].else|REQUIRED",
  ]);
  assert.deepEqual(codes(lv, [iff("CLEAR_AHEAD", [iff("CLEAR_LEFT", [M])])]), [
    "program[0].then[0].op|NESTED_IF",
  ]);
  assert.deepEqual(codes(lv, [iff("CLEAR_AHEAD", [M], [{ op: "REPEAT", count: 2, body: [M] }])]), [
    "program[0].else[0].op|NESTED_REPEAT",
  ]);
  assert.deepEqual(codes(lv, [{ op: "REPEAT", count: 2, body: [iff("CLEAR_AHEAD", [M]), M] }]), []);
  assert.deepEqual(
    codes(lv, [{ op: "REPEAT", count: 2, body: [{ op: "REPEAT", count: 2, body: [M] }] }]),
    ["program[0].body[0].op|NESTED_REPEAT"],
  );
  assert.deepEqual(codes(lv, [{ ...iff("CLEAR_AHEAD", [M]), count: 2 }]), [
    "program[0].count|UNKNOWN_FIELD",
  ]);
  const without = makeLevel({ cmds: ["MOVE_FORWARD", "REPEAT"] });
  assert.deepEqual(codes(without, [iff("CLEAR_AHEAD", [M])]), [
    "program[0].op|COMMAND_NOT_AVAILABLE",
  ]);
  assert.deepEqual(codes(without, [{ op: "REPEAT", count: 2, body: [iff("CLEAR_AHEAD", [M])] }]), [
    "program[0].body[0].op|COMMAND_NOT_AVAILABLE",
  ]);
});
