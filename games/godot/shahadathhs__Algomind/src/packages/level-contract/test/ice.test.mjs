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
  const { ice, belts, ...rest } = o;
  const level = makeLevel({
    w: 7,
    h: 3,
    start: [0, 1],
    dir: "east",
    goal: [6, 1],
    maxS: 30,
    ...rest,
  });
  if (ice) level.ice = ice;
  if (belts) level.belts = belts;
  return level;
};

test("a move onto ice slides on while the way is free and stops on the first cell that is not ice", () => {
  const level = hall({
    ice: [
      [2, 1],
      [3, 1],
      [4, 1],
    ],
  });
  const run = simulate(level, [M, M]);
  assert.deepEqual(run.trace[1]?.path, [
    [2, 1],
    [3, 1],
    [4, 1],
    [5, 1],
  ]);
  assert.equal(run.trace[1]?.event, "SLID");
  assert.deepEqual(run.finalState.position, [5, 1]);
});

test("every trace entry of a level with ice or belts has a path; other levels have none", () => {
  const run = simulate(hall({ ice: [[3, 1]] }), [L, R, M]);
  assert.deepEqual(
    run.trace.map((t) => t.path?.length),
    [0, 0, 1],
  );
  assert.equal("path" in /** @type {object} */ (simulate(hall(), [M]).trace[0]), false);
});

test("a belt carries once and does not chain", () => {
  const level = hall({
    belts: [
      { cell: [1, 1], direction: "east" },
      { cell: [2, 1], direction: "east" },
    ],
  });
  const first = simulate(level, [M]);
  assert.deepEqual(
    first.finalState.position,
    [2, 1],
    "carried from the first belt onto the second",
  );
  const second = simulate(level, [M, L]);
  assert.deepEqual(second.finalState.position, [3, 1], "the next action carries on");
});

test("a belt does not start a slide, and a slide ends where it is blocked", () => {
  const belt = simulate(hall({ ice: [[2, 1]], belts: [{ cell: [1, 1], direction: "east" }] }), [M]);
  assert.deepEqual(belt.finalState.position, [2, 1]);
  const wall = simulate(
    hall({
      walls: [[3, 1]],
      ice: [
        [1, 1],
        [2, 1],
      ],
    }),
    [M],
  );
  assert.deepEqual(wall.finalState.position, [2, 1]);
  assert.equal(wall.status, "FAILED");
  assert.equal(wall.reason, "PROGRAM_ENDED");
});

test("the solver uses ice: a long slide is one move", () => {
  const plain = hall();
  const icy = hall({
    ice: [
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
    ],
  });
  assert.equal(solve(plain)?.commands, 6);
  assert.equal(solve(icy)?.commands, 1);
});

test("the solver finds the same length as a brute force over every flat program", () => {
  const level = hall({
    walls: [
      [3, 1],
      [5, 2],
    ],
    ice: [[1, 1]],
    belts: [
      { cell: [2, 1], direction: "south" },
      { cell: [3, 2], direction: "east" },
    ],
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
  assert.equal(brute, 7);
  assert.equal(solve(level)?.commands, 7);
});

test("the validator accepts ice and belts and names every way they can be wrong", () => {
  const level = hall({ ice: [[2, 1]], belts: [{ cell: [3, 1], direction: "east" }] });
  assert.equal(validateLevel(level).ok, true);
  level.ice = [[3, 1]];
  assert.deepEqual(
    validateLevel(level).issues.map((i) => `${i.path}|${i.code}`),
    ["belts[0].cell|BELT_ON_ICE"],
  );
});
