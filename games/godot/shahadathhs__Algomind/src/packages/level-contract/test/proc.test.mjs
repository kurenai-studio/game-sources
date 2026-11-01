// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { programSlots, simulate, validateProgram } from "../dist/index.js";
import { makeLevel } from "./helpers.mjs";

const ALL = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT", "REPEAT_UNTIL", "IF", "PROC"];
const M = { op: "MOVE_FORWARD" };
const L = { op: "TURN_LEFT" };
const R = { op: "TURN_RIGHT" };
/** @param {string} name @param {any[]} body @returns {any} */
const proc = (name, body) => ({ op: "PROC", name, body });
/** @param {string} name @returns {any} */
const call = (name) => ({ op: "CALL", name });
/** @param {number} count @param {any[]} body @returns {any} */
const rep = (count, body) => ({ op: "REPEAT", count, body });
/** @param {Record<string, any>} [o] */
const level = (o = {}) =>
  makeLevel({ cmds: ALL, w: 9, h: 9, start: [0, 8], goal: [8, 0], maxS: 100, ...o });
/** @param {any} lv @param {any} program */
const codes = (lv, program) =>
  validateProgram(lv, program).issues.map((i) => `${i.path}|${i.code}`);

test("a PROC is not run where it stands: only a CALL runs its body", () => {
  const result = simulate(level(), [proc("A", [M, M]), M, call("A"), call("A")]);
  assert.equal(result.reason, "PROGRAM_ENDED");
  assert.equal(result.steps, 5);
});

test("a call may come before the definition, and the first definition of a name is the one that runs", () => {
  const result = simulate(level(), [call("A"), proc("A", [M, M]), proc("A", [M])]);
  assert.equal(result.steps, 2);
});

test("trace: a primitive in a procedure has the PROC index in its node and the CALL path in call", () => {
  const result = simulate(level(), [M, proc("A", [M, rep(2, [L])]), call("A")]);
  assert.deepEqual(
    result.trace.map((t) => [t.node, t.call, t.round]),
    [
      [[0], null, null],
      [[1, 0], [2], null],
      [[1, 1, 0], [2], 1],
      [[1, 1, 0], [2], 2],
    ],
  );
});

test("a CALL in a loop body of the main program runs the procedure every round", () => {
  const result = simulate(level(), [proc("A", [M]), rep(3, [call("A"), R])]);
  assert.equal(result.steps, 6);
  assert.deepEqual(
    result.trace.slice(0, 2).map((t) => [t.node, t.call, t.round]),
    [
      [[0, 0], [1, 0], null],
      [[1, 1], null, 1],
    ],
  );
});

test("the goal inside a procedure ends the run", () => {
  const lv = level({ w: 4, h: 3, start: [0, 1], dir: "east", goal: [2, 1] });
  const result = simulate(lv, [proc("A", [M, M, M]), call("A")]);
  assert.equal(result.reason, "GOAL_REACHED");
  assert.equal(result.steps, 2);
});

test("a call to a missing procedure, or a malformed PROC, stops the run", () => {
  const lv = level();
  assert.equal(simulate(lv, [M, call("A")]).reason, "INVALID_INSTRUCTION");
  assert.equal(simulate(lv, [M, call("A")]).steps, 1);
  assert.equal(simulate(lv, [proc("A", []), M]).reason, "INVALID_INSTRUCTION");
  assert.equal(simulate(lv, [proc("A", [call("A")]), call("A")]).reason, "INVALID_INSTRUCTION");
});

test("slots: a PROC is 1 plus its body, a CALL is 1", () => {
  assert.equal(programSlots([proc("A", [M, rep(2, [M, L])]), call("A"), call("A")]), 1 + 1 + 3 + 2);
  const lv = level({ maxC: 6 });
  assert.deepEqual(codes(lv, [proc("A", [M, M, M]), call("A"), call("A")]), []);
  assert.deepEqual(codes(lv, [proc("A", [M, M, M]), call("A"), call("A"), call("A")]), [
    "program|TOO_MANY_COMMANDS",
  ]);
});

test("procedure validation: names, places, bodies, availability", () => {
  const lv = level({ maxC: 64 });
  assert.deepEqual(codes(lv, [proc("A", [M]), call("A")]), []);
  assert.deepEqual(codes(lv, [proc("D", [M])]), ["program[0].name|INVALID_VALUE"]);
  assert.deepEqual(codes(lv, [{ op: "PROC", body: [M] }]), ["program[0].name|REQUIRED"]);
  assert.deepEqual(codes(lv, [{ op: "CALL", name: 4 }]), ["program[0].name|INVALID_TYPE"]);
  assert.deepEqual(codes(lv, [call("A")]), ["program[0].name|UNDEFINED_PROCEDURE"]);
  assert.deepEqual(codes(lv, [proc("A", [M]), proc("A", [L])]), [
    "program[1].name|DUPLICATE_PROCEDURE",
  ]);
  assert.deepEqual(codes(lv, [proc("A", [])]), ["program[0].body|LENGTH_OUT_OF_RANGE"]);
  assert.deepEqual(codes(lv, [proc("A", Array(9).fill(M))]), [
    "program[0].body|LENGTH_OUT_OF_RANGE",
  ]);
  assert.deepEqual(codes(lv, [proc("A", [proc("B", [M])])]), ["program[0].body[0].op|NESTED_PROC"]);
  assert.deepEqual(codes(lv, [proc("A", [M]), proc("B", [call("A")])]), [
    "program[1].body[0].op|CALL_NOT_ALLOWED",
  ]);
  assert.deepEqual(
    codes(lv, [proc("A", [M]), { op: "IF", when: "CLEAR_AHEAD", then: [call("A")], else: [] }]),
    ["program[1].then[0].op|CALL_NOT_ALLOWED"],
  );
  assert.deepEqual(codes(lv, [proc("A", [M]), rep(2, [call("A")])]), []);
  assert.deepEqual(codes(lv, [proc("A", [M]), proc("B", [rep(2, [call("A")])])]), [
    "program[1].body[0].body[0].op|CALL_NOT_ALLOWED",
  ]);
  assert.deepEqual(codes(lv, [proc("A", [rep(2, [M, L]), M])]), []);
  assert.deepEqual(codes(lv, [proc("A", [rep(2, [rep(2, [M])])])]), [
    "program[0].body[0].body[0].op|NESTED_REPEAT",
  ]);
  assert.deepEqual(codes(lv, [{ op: "CALL", name: "A", body: [M] }, proc("A", [M])]), [
    "program[0].body|UNKNOWN_FIELD",
  ]);
  const without = makeLevel({ cmds: ["MOVE_FORWARD", "REPEAT"] });
  assert.deepEqual(codes(without, [proc("A", [M]), call("A")]), [
    "program[0].op|COMMAND_NOT_AVAILABLE",
    "program[1].op|COMMAND_NOT_AVAILABLE",
  ]);
});
