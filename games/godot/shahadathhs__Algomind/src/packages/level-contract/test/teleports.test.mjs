// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { simulate, solve, validateLevel } from "../dist/index.js";
import { makeLevel } from "./helpers.mjs";

const M = /** @type {any} */ ({ op: "MOVE_FORWARD" });
const L = /** @type {any} */ ({ op: "TURN_LEFT" });
const R = /** @type {any} */ ({ op: "TURN_RIGHT" });

/** A 7 by 3 board: start (0,1) facing east, target (6,1). */
const hall = (/** @type {Record<string, any>} */ o = {}) => {
  const { teleports, ...rest } = o;
  const level = makeLevel({
    w: 7,
    h: 3,
    start: [0, 1],
    dir: "east",
    goal: [6, 1],
    maxS: 30,
    ...rest,
  });
  if (teleports) level.teleports = teleports;
  return level;
};

test("entering one end puts the automaton on the other, in the same step, facing the same way", () => {
  const level = hall({ teleports: [{ a: [2, 1], b: [5, 3 - 2] }] });
  const run = simulate(level, [M, M]);
  assert.equal(run.trace[1]?.event, "TELEPORTED");
  assert.deepEqual(run.trace[1]?.path, [
    [2, 1],
    [5, 1],
  ]);
  assert.deepEqual(run.finalState, { position: [5, 1], direction: "east" });
});

test("arriving does not teleport back, and the second end works in turn", () => {
  const level = hall({ teleports: [{ a: [2, 0], b: [5, 0] }] });
  const there = simulate(level, [L, M, R, M, M, M]);
  assert.equal(there.trace[4]?.event, "TELEPORTED");
  assert.equal(there.trace[5]?.event, "MOVED", "stepping off the far end is an ordinary move");
  const back = simulate(hall({ teleports: [{ a: [2, 1], b: [1, 0] }] }), [M, M, L, M]);
  assert.deepEqual(back.trace[1]?.path, [
    [2, 1],
    [1, 0],
  ]);
});

test("the solver uses a pair: a wall across the board is crossed through it", () => {
  const walled = hall({
    walls: [
      [3, 0],
      [3, 1],
      [3, 2],
    ],
  });
  assert.equal(solve(walled), null);
  const through = hall({
    walls: [
      [3, 0],
      [3, 1],
      [3, 2],
    ],
    teleports: [{ a: [2, 1], b: [4, 1] }],
  });
  assert.equal(solve(through)?.commands, 4);
});

test("the solver finds the same length as a brute force over every flat program", () => {
  const level = hall({
    walls: [
      [3, 0],
      [3, 1],
    ],
    teleports: [{ a: [1, 0], b: [5, 0] }],
  });
  const ops = [M, L, R];
  /** @type {number | null} */
  let brute = null;
  for (let length = 1; length <= 11 && brute === null; length += 1) {
    const total = 3 ** length;
    for (let n = 0; n < total && brute === null; n += 1) {
      const program = Array.from({ length }, (_, i) => ops[Math.floor(n / 3 ** i) % 3]);
      if (simulate(level, program).status === "SUCCEEDED") brute = length;
    }
  }
  assert.ok(brute !== null);
  assert.equal(solve(level)?.commands, brute);
});

test("the validator accepts teleporters and names every way they can be wrong", () => {
  const level = hall({ teleports: [{ a: [1, 0], b: [5, 2] }] });
  assert.equal(validateLevel(level).ok, true);
  level.teleports = [{ a: [0, 1], b: [6, 1] }];
  assert.deepEqual(
    validateLevel(level).issues.map((i) => `${i.path}|${i.code}`),
    ["teleports[0].a|TELEPORT_ON_START", "teleports[0].b|TELEPORT_ON_GOAL"],
  );
});
