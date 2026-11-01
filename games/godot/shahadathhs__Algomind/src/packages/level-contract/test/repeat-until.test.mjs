// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { programSlots, simulate, solve, validateProgram } from "../dist/index.js";
import { makeLevel, rng, randomLevel } from "./helpers.mjs";

const ALL = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT", "REPEAT_UNTIL"];
const M = { op: "MOVE_FORWARD" };
const L = { op: "TURN_LEFT" };
/** @param {any[]} body @returns {any} */
const until = (body) => ({ op: "REPEAT_UNTIL", until: "BLOCKED", body });
/** @param {Record<string, any>} [o] */
const level = (o = {}) => makeLevel({ cmds: ALL, ...o });
/** @param {any} lv @param {any} program */
const codes = (lv, program) =>
  validateProgram(lv, program).issues.map((i) => `${i.path}|${i.code}`);

test("REPEAT_UNTIL runs its body while the way ahead is open, then the next node runs", () => {
  const lv = level({ w: 6, h: 3, start: [0, 2], dir: "east", goal: [5, 0], maxS: 100 });
  const result = simulate(lv, [until([M]), L, until([M])]);
  assert.equal(result.status, "SUCCEEDED");
  assert.equal(result.steps, 5 + 1 + 2);
  assert.deepEqual(result.trace[0]?.node, [0, 0]);
  assert.equal(result.trace[0]?.round, 1);
  assert.equal(result.trace[4]?.round, 5);
  assert.deepEqual(result.trace[5]?.node, [1]);
  assert.equal(result.trace[5]?.round, null);
});

test("the condition is checked before every round, so a blocked start runs the body zero times", () => {
  const lv = level({ w: 3, h: 3, start: [2, 2], dir: "east", goal: [0, 0] });
  const result = simulate(lv, [until([M])]);
  assert.equal(result.reason, "PROGRAM_ENDED");
  assert.equal(result.steps, 0);
});

test("a wall counts as blocked, like the board edge", () => {
  const lv = level({ w: 5, h: 1, walls: [[3, 0]], start: [0, 0], dir: "east", goal: [4, 0] });
  const result = simulate(lv, [until([M])]);
  assert.equal(result.reason, "PROGRAM_ENDED");
  assert.deepEqual(result.finalState.position, [2, 0]);
});

test("the goal ends the run in the middle of the loop", () => {
  const lv = level({ w: 6, h: 1, start: [0, 0], dir: "east", goal: [3, 0] });
  const result = simulate(lv, [until([M])]);
  assert.equal(result.reason, "GOAL_REACHED");
  assert.equal(result.steps, 3);
});

test("a body that is never blocked ends at the step limit", () => {
  const lv = level({ w: 5, h: 5, start: [2, 2], dir: "north", goal: [0, 0], maxS: 7 });
  const result = simulate(lv, [until([L])]);
  assert.equal(result.reason, "STEP_LIMIT");
  assert.equal(result.steps, 7);
});

test("a body that fails inside the loop reports the block", () => {
  const lv = level({ w: 4, h: 2, start: [0, 0], dir: "east", goal: [0, 1] });
  const result = simulate(lv, [until([M, M])]);
  assert.equal(result.reason, "BLOCKED_BY_BOUNDARY");
  assert.deepEqual(result.trace.at(-1)?.node, [0, 1]);
});

test("slots: REPEAT_UNTIL is 1 plus its body", () => {
  assert.equal(programSlots([until([M, L]), M]), 4);
  const lv = level({ maxC: 3 });
  assert.deepEqual(codes(lv, [until([M, L])]), []);
  assert.deepEqual(codes(lv, [until([M, L]), M]), ["program|TOO_MANY_COMMANDS"]);
});

test("REPEAT_UNTIL validation: condition, body, nesting, availability", () => {
  const lv = level({ maxC: 64 });
  assert.deepEqual(codes(lv, [{ op: "REPEAT_UNTIL", body: [M] }]), ["program[0].until|REQUIRED"]);
  assert.deepEqual(codes(lv, [{ op: "REPEAT_UNTIL", until: "NEAR", body: [M] }]), [
    "program[0].until|INVALID_VALUE",
  ]);
  assert.deepEqual(codes(lv, [{ op: "REPEAT_UNTIL", until: 3, body: [M] }]), [
    "program[0].until|INVALID_TYPE",
  ]);
  assert.deepEqual(codes(lv, [{ op: "REPEAT_UNTIL", until: "BLOCKED" }]), [
    "program[0].body|REQUIRED",
  ]);
  assert.deepEqual(codes(lv, [until([])]), ["program[0].body|LENGTH_OUT_OF_RANGE"]);
  assert.deepEqual(codes(lv, [until([until([M])])]), ["program[0].body[0].op|NESTED_REPEAT"]);
  assert.deepEqual(codes(lv, [until([{ op: "REPEAT", count: 2, body: [M] }])]), [
    "program[0].body[0].op|NESTED_REPEAT",
  ]);
  assert.deepEqual(codes(lv, [{ op: "REPEAT_UNTIL", until: "BLOCKED", count: 2, body: [M] }]), [
    "program[0].count|UNKNOWN_FIELD",
  ]);
  assert.deepEqual(codes(lv, [{ op: "REPEAT", count: 2, until: "BLOCKED", body: [M] }]), [
    "program[0].until|UNKNOWN_FIELD",
  ]);
  const without = makeLevel({ cmds: ["MOVE_FORWARD", "REPEAT"] });
  assert.deepEqual(codes(without, [until([M])]), ["program[0].op|COMMAND_NOT_AVAILABLE"]);
});

test("par: a long corridor costs two slots with REPEAT_UNTIL", () => {
  const lv = level({ w: 12, h: 1, start: [0, 0], dir: "east", goal: [11, 0] });
  const par = solve(lv);
  assert.equal(par?.commands, 2);
  assert.equal(par?.program[0]?.op === "REPEAT_UNTIL" || par?.program[0]?.op === "REPEAT", true);
});

test("par: an L-shaped corridor is run, turn, run", () => {
  const walls = [];
  for (let x = 0; x < 5; x += 1) for (let y = 0; y < 5; y += 1) walls.push([x, y]);
  const lv = level({ w: 6, h: 6, walls, start: [0, 5], dir: "east", goal: [5, 0] });
  const par = solve(lv);
  assert.equal(par?.commands, 5);
  assert.equal(simulate(lv, par?.program ?? []).status, "SUCCEEDED");
  const flat = solve({ ...lv, availableCommands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"] });
  assert.equal(flat?.commands, 11);
});

test("random levels: the solver's program always runs to the goal, and is never worse than the flat par", () => {
  const r = rng(4242);
  for (let i = 0; i < 40; i += 1) {
    const base = randomLevel(r);
    const flat = solve({ ...base, availableCommands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"] });
    const loops = solve({ ...base, availableCommands: ALL });
    if (!flat) {
      continue;
    }
    assert.ok(loops, "a level solvable flat is solvable with loops");
    assert.ok(loops.commands <= flat.commands);
    const run = simulate(
      { ...base, availableCommands: ALL, constraints: { ...base.constraints, maxSteps: 1000 } },
      loops.program,
    );
    assert.equal(run.status, "SUCCEEDED");
    assert.equal(run.steps, loops.steps);
  }
});
