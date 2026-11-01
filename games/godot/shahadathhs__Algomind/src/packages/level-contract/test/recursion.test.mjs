// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { LIMITS, programSlots, simulate, validateProgram } from "../dist/index.js";
import { makeLevel } from "./helpers.mjs";

const M = /** @type {any} */ ({ op: "MOVE_FORWARD" });
const L = /** @type {any} */ ({ op: "TURN_LEFT" });
const call = (/** @type {string} */ name, /** @type {string} */ when = "") =>
  /** @type {any} */ (when ? { op: "CALL", name, when } : { op: "CALL", name });
const proc = (/** @type {string} */ name, /** @type {any[]} */ body) =>
  /** @type {any} */ ({ op: "PROC", name, body });

/** A 7 by 3 board with the mechanic recursion and every command a recursive program needs. */
const hall = (/** @type {Record<string, any>} */ o = {}) => {
  const level = makeLevel({
    w: 7,
    h: 3,
    start: [0, 1],
    dir: "east",
    goal: [6, 1],
    maxS: 100,
    maxC: 12,
    cmds: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "IF", "PROC"],
    ...o,
  });
  level.requires = { mechanics: ["recursion"] };
  return level;
};

test("a procedure that calls itself while the way is clear walks to the wall", () => {
  const level = hall({ walls: [[4, 1]], goal: [3, 1] });
  const run = simulate(level, [proc("A", [M, call("A", "CLEAR_AHEAD")]), call("A")]);
  assert.equal(run.status, "SUCCEEDED");
  assert.equal(run.steps, 3);
});

test("the trace names the innermost CALL, and the CALL path of the main program is its own", () => {
  const level = hall({ walls: [[3, 1]], goal: [2, 1] });
  const run = simulate(level, [proc("A", [M, call("A", "CLEAR_AHEAD")]), call("A")]);
  assert.deepEqual(run.trace[0]?.call, [1]);
  assert.deepEqual(run.trace[0]?.node, [0, 0]);
  assert.deepEqual(run.trace[1]?.call, [0, 1], "the second M runs inside the CALL in the body");
});

test("a recursion with no base case ends at the depth limit, with its steps counted", () => {
  const run = simulate(hall(), [proc("A", [L, call("A")]), call("A")]);
  assert.equal(run.reason, "TOO_DEEP");
  assert.equal(run.steps, LIMITS.callDepth);
});

test("the sensor of a CALL is read when the CALL is reached and costs nothing", () => {
  const level = hall({ walls: [[1, 1]], goal: [0, 0] });
  const run = simulate(level, [proc("A", [M]), call("A", "CLEAR_AHEAD"), L, M]);
  assert.equal(run.status, "SUCCEEDED");
  assert.equal(run.steps, 2);
});

test("a CALL counts one slot, in a procedure as anywhere", () => {
  assert.equal(programSlots([proc("A", [M, call("A", "CLEAR_AHEAD")]), call("A")]), 4);
});

test("the mechanic gates a CALL in a procedure and a sensor on a CALL", () => {
  const program = [proc("A", [M, call("A", "CLEAR_AHEAD")]), call("A")];
  assert.equal(validateProgram(hall(), program).ok, true);
  const plain = hall();
  plain.requires = { mechanics: [] };
  assert.deepEqual(
    validateProgram(plain, program).issues.map((i) => `${i.path}|${i.code}`),
    ["program[0].body[1].op|CALL_NOT_ALLOWED"],
  );
});
