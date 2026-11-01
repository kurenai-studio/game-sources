// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { simulate, solve, validateLevel } from "../dist/index.js";
import { makeLevel } from "./helpers.mjs";

const M = /** @type {any} */ ({ op: "MOVE_FORWARD" });
const L = /** @type {any} */ ({ op: "TURN_LEFT" });
const R = /** @type {any} */ ({ op: "TURN_RIGHT" });

/** A 5 by 3 board: start (0,1) facing east, target (4,1). */
const corridor = (/** @type {Record<string, any>} */ o = {}) => {
  const { switches, ...rest } = o;
  const level = makeLevel({
    w: 5,
    h: 3,
    start: [0, 1],
    dir: "east",
    goal: [4, 1],
    maxS: 30,
    ...rest,
  });
  if (switches) level.switches = switches;
  return level;
};

/** Walls above and below the two middle cells, so the gates cannot be walked round. */
const hall = [
  [2, 0],
  [3, 0],
  [2, 2],
  [3, 2],
];

test("a gate blocks until its switch is entered, then it is an ordinary cell", () => {
  const level = corridor({ walls: hall, switches: [{ switch: [1, 0], gate: [3, 1] }] });
  const blocked = simulate(level, [M, M, M, M]);
  assert.equal(blocked.reason, "BLOCKED_BY_GATE");
  assert.deepEqual(blocked.blockedCell, [3, 1]);
  const opened = simulate(level, [L, M, R, M, R, M, L, M, M, M]);
  assert.equal(opened.status, "SUCCEEDED");
  assert.ok(opened.trace.some((t) => t.event === "SWITCHED"));
});

test("a switch flips its gate every time it is entered", () => {
  const level = corridor({ switches: [{ switch: [1, 1], gate: [3, 1] }] });
  const events = simulate(level, [M, L, L, M, L, L, M, M, M]).trace.map((t) => t.event);
  assert.deepEqual(events.filter((e) => e === "SWITCHED").length, 2);
  assert.equal(events.at(-1), "BLOCKED_BY_GATE");
});

test("a gate that starts open is shut by its switch", () => {
  const free = corridor({ switches: [{ switch: [1, 0], gate: [3, 1], open: true }] });
  assert.equal(simulate(free, [M, M, M, M]).status, "SUCCEEDED");
  const trap = corridor({ switches: [{ switch: [1, 1], gate: [3, 1], open: true }] });
  assert.equal(simulate(trap, [M, M, M, M]).reason, "BLOCKED_BY_GATE");
});

test("the solver visits the switch: par is longer than the straight way", () => {
  const level = corridor({ walls: hall, switches: [{ switch: [1, 0], gate: [3, 1] }] });
  const best = solve(level);
  assert.ok(best);
  assert.ok(best.commands > 4);
  assert.equal(simulate(level, best.program).status, "SUCCEEDED");
});

test("the solver avoids a switch that would shut an open gate", () => {
  const level = corridor({
    walls: [
      [2, 0],
      [2, 2],
    ],
    switches: [{ switch: [1, 1], gate: [2, 1], open: true }],
  });
  // The switch is on the only row-1 cell before the gate; going round it costs turns.
  const best = solve(level);
  assert.ok(best);
  assert.equal(simulate(level, best.program).status, "SUCCEEDED");
  assert.ok(best.commands > 4);
});

test("the solver finds the same length as a brute force over every flat program", () => {
  const level = corridor({ walls: hall, switches: [{ switch: [1, 0], gate: [2, 1] }] });
  const ops = [M, L, R];
  /** @type {number | null} */
  let brute = null;
  for (let length = 1; length <= 12 && brute === null; length += 1) {
    const total = 3 ** length;
    for (let n = 0; n < total && brute === null; n += 1) {
      const program = Array.from({ length }, (_, i) => ops[Math.floor(n / 3 ** i) % 3]);
      if (simulate(level, program).status === "SUCCEEDED") brute = length;
    }
  }
  assert.ok(brute !== null);
  assert.equal(solve(level)?.commands, brute);
});

test("the validator accepts switches and names every way they can be wrong", () => {
  const level = corridor({ switches: [{ switch: [1, 0], gate: [3, 1] }] });
  assert.equal(validateLevel(level).ok, true);
  level.switches = [{ switch: [0, 1], gate: [4, 1], open: 1 }];
  assert.deepEqual(
    validateLevel(level).issues.map((i) => `${i.path}|${i.code}`),
    [
      "switches[0].open|INVALID_TYPE",
      "switches[0].switch|SWITCH_ON_START",
      "switches[0].gate|SWITCH_ON_GOAL",
    ],
  );
});
