// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { programSlots, simulate, validateLevel, validateProgram } from "../dist/index.js";
import { makeLevel } from "./helpers.mjs";

const ALL = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT", "REPEAT_UNTIL", "INC"];
const M = /** @type {any} */ ({ op: "MOVE_FORWARD" });
const R = /** @type {any} */ ({ op: "TURN_RIGHT" });
const INC = /** @type {any} */ ({ op: "INC" });
/** @param {any} count @param {any[]} body @returns {any} */
const rep = (count, body) => ({ op: "REPEAT", count, body });
/** @param {any[]} body @returns {any} */
const forever = (body) => ({ op: "REPEAT_UNTIL", until: "GOAL", body });
/** @param {Record<string, any>} [o] */
const level = (o = {}) =>
  makeLevel({
    cmds: ALL,
    w: 11,
    h: 11,
    start: [5, 5],
    dir: "north",
    goal: [0, 0],
    maxS: 400,
    ...o,
  });
/** @param {any} lv @param {any} program */
const codes = (lv, program) =>
  validateProgram(lv, program).issues.map((i) => `${i.path}|${i.code}`);
const withNested = (o = {}) => ({ ...level(o), requires: { mechanics: ["nested_loops"] } });

/** An expanding square spiral: N moves, turn, N moves, turn, then N grows. */
const SPIRAL = forever([rep("N", [M]), R, rep("N", [M]), R, INC]);

test("INC adds one to the counter, the trace carries it, and it stops at 11", () => {
  const result = simulate(level(), [INC, INC, M]);
  assert.deepEqual(
    result.trace.map((t) => [t.op, t.event, t.counter]),
    [
      ["INC", "COUNTED", 2],
      ["INC", "COUNTED", 3],
      ["MOVE_FORWARD", "MOVED", 3],
    ],
  );
  assert.equal(result.steps, 3, "INC is a step like a turn");
  const many = simulate(
    level({ maxS: 100 }),
    Array.from({ length: 12 }, () => INC),
  );
  assert.equal(many.trace.at(-1)?.counter, 11);
  assert.equal(simulate(level(), [M]).trace[0]?.counter, 1, "the counter starts at 1");
});

test("a REPEAT with count N reads the counter when it starts, not while it runs", () => {
  const result = simulate(level(), [INC, rep("N", [M, INC])]);
  // N is 2 when the loop starts: two rounds, even though INC runs inside them.
  assert.equal(result.trace.filter((t) => t.op === "MOVE_FORWARD").length, 2);
  assert.equal(result.trace.at(-1)?.counter, 4);
  assert.equal(simulate(level(), [rep("N", [M])]).steps, 1, "N is 1 at the start: one round");
});

test("a loop in a loop: the trace path has three numbers and the round is the inner loop's", () => {
  const program = [rep(2, [M, rep(3, [R])])];
  const result = simulate(level(), program);
  assert.deepEqual(
    result.trace.map((t) => [t.node, t.round]),
    [
      [[0, 0], 1],
      [[0, 1, 0], 1],
      [[0, 1, 0], 2],
      [[0, 1, 0], 3],
      [[0, 0], 2],
      [[0, 1, 0], 1],
      [[0, 1, 0], 2],
      [[0, 1, 0], 3],
    ],
  );
});

test("a third level of loops stops the run", () => {
  const result = simulate(level(), [rep(2, [rep(2, [rep(2, [M])])])]);
  assert.equal(result.reason, "INVALID_INSTRUCTION");
});

test("the expanding spiral reaches a goal on its path with one short program", () => {
  const probe = simulate(level({ goal: [0, 0] }), [SPIRAL]);
  // Pick the cell the spiral reaches on its 30th move and make it the goal.
  const cells = probe.trace.filter((t) => t.event === "MOVED" || t.event === "GOAL_REACHED");
  const goal = cells[29]?.position;
  assert.ok(goal);
  const result = simulate(level({ goal }), [SPIRAL]);
  assert.equal(result.reason, "GOAL_REACHED");
  assert.equal(programSlots([SPIRAL]), 1 + 2 + 1 + 2 + 1 + 1);
});

test("slots are recursive: a loop is 1 plus the slots of its body", () => {
  assert.equal(programSlots([rep(2, [M, rep(3, [R, INC])])]), 1 + 1 + (1 + 2));
});

test("nested loops need the mechanic nested_loops, and only two levels are allowed", () => {
  const nested = [rep(2, [rep(2, [M])])];
  assert.deepEqual(codes(level({ maxC: 64 }), nested), ["program[0].body[0].op|NESTED_REPEAT"]);
  assert.deepEqual(codes(withNested({ maxC: 64 }), nested), []);
  assert.deepEqual(codes(withNested({ maxC: 64 }), [rep(2, [rep(2, [rep(2, [M])])])]), [
    "program[0].body[0].body[0].op|NESTED_REPEAT",
  ]);
  const inUntil = [{ op: "REPEAT_UNTIL", until: "BLOCKED", body: [rep(2, [M])] }];
  assert.deepEqual(codes(withNested({ maxC: 64 }), inUntil), []);
});

test("count N and INC are commands a level offers", () => {
  const without = level({ cmds: ["MOVE_FORWARD", "REPEAT"], maxC: 64 });
  assert.deepEqual(codes(without, [INC]), ["program[0].op|COMMAND_NOT_AVAILABLE"]);
  assert.deepEqual(codes(without, [rep("N", [M])]), ["program[0].count|COMMAND_NOT_AVAILABLE"]);
  assert.deepEqual(codes(level({ maxC: 64 }), [rep("N", [M])]), []);
  assert.deepEqual(codes(level({ maxC: 64 }), [rep("M", [M])]), ["program[0].count|INVALID_TYPE"]);
  assert.deepEqual(codes(level({ maxC: 64 }), [rep(1, [M])]), ["program[0].count|OUT_OF_RANGE"]);
});

test("a level can list the mechanic, and the nested loop passes the level validator in its solution", () => {
  assert.equal(validateLevel(withNested()).ok, true);
});
