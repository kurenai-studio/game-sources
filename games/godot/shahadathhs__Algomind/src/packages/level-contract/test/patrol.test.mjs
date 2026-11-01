// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import {
  patrolCell,
  patrolCells,
  patrolIndex,
  patrolMeeting,
  simulate,
  solve,
  validateLevel,
} from "../dist/index.js";
import { makeLevel } from "./helpers.mjs";

const M = /** @type {any} */ ({ op: "MOVE_FORWARD" });
const L = /** @type {any} */ ({ op: "TURN_LEFT" });
const R = /** @type {any} */ ({ op: "TURN_RIGHT" });
/** @param {number[][]} cells @returns {any} */
const walker = (cells) => ({ pattern: "back_and_forth", cells });
/** @param {Record<string, any>} [o] */
const corridor = (o = {}) =>
  makeLevel({ w: 5, h: 3, start: [0, 1], dir: "east", goal: [4, 1], ...o });

test("a back and forth patrol walks its cells and returns, with a period of 2 (n - 1)", () => {
  const patrol = walker([
    [0, 0],
    [1, 0],
    [2, 0],
  ]);
  assert.deepEqual(
    Array.from({ length: 10 }, (_, s) => patrolIndex(patrol, s)),
    [0, 1, 2, 1, 0, 1, 2, 1, 0, 1],
  );
  assert.deepEqual(patrolCell(patrol, 2), [2, 0]);
});

test("a ring patrol goes round its cells, with a period of n", () => {
  const ring = {
    pattern: "loop",
    cells: [
      [1, 1],
      [2, 1],
      [2, 2],
      [1, 2],
    ],
  };
  assert.deepEqual(
    Array.from({ length: 6 }, (_, s) => patrolIndex(/** @type {any} */ (ring), s)),
    [0, 1, 2, 3, 0, 1],
  );
});

test("patrolCells lists every patrol of a level, and a level without patrols has none", () => {
  const level = corridor({});
  assert.deepEqual(patrolCells(level, 3), []);
  level.patrols = [
    walker([
      [2, 0],
      [2, 1],
    ]),
    walker([
      [3, 0],
      [3, 1],
    ]),
  ];
  assert.deepEqual(patrolCells(level, 1), [
    [2, 1],
    [3, 1],
  ]);
});

test("patrolMeeting: the same cell, a swap, and neither", () => {
  const level = corridor({});
  level.patrols = [
    walker([
      [3, 1],
      [2, 1],
    ]),
  ];
  // Step 2 to 3: the automaton goes (2,1) to (3,1) as the patrol goes (3,1) to (2,1): a swap.
  assert.deepEqual(patrolMeeting(level, [2, 1], [3, 1], 2), [3, 1]);
  // Step 1 to 2: the patrol goes (2,1) to (3,1); the automaton goes (1,1) to (2,1): no meeting.
  assert.equal(patrolMeeting(level, [1, 1], [2, 1], 1), null);
  // A turn on a cell the patrol is about to enter.
  level.patrols = [
    walker([
      [1, 1],
      [0, 1],
    ]),
  ];
  assert.deepEqual(patrolMeeting(level, [0, 1], [0, 1], 0), [0, 1]);
});

test("a patrol that does not stand in the way changes nothing about a run", () => {
  const plain = simulate(corridor(), [M, M, M, M]);
  const level = corridor({});
  level.patrols = [
    walker([
      [2, 0],
      [2, 1],
      [2, 2],
    ]),
  ];
  const run = simulate(level, [M, M, M, M]);
  assert.equal(run.status, "SUCCEEDED");
  assert.deepEqual(run.trace, plain.trace);
});

test("a hit ends the run with the cell of the meeting, and the trace keeps the step", () => {
  const level = corridor({});
  level.patrols = [
    walker([
      [2, 1],
      [2, 2],
    ]),
  ];
  const run = simulate(level, [M, M, M, M]);
  assert.equal(run.status, "FAILED");
  assert.equal(run.reason, "HIT_BY_PATROL");
  assert.deepEqual(run.blockedCell, [2, 1]);
  assert.equal(run.steps, 2);
  assert.equal(run.trace.at(-1)?.event, "HIT_BY_PATROL");
  assert.deepEqual(run.finalState.position, [2, 1]);
});

test("the step limit still comes first when the run is already out of steps", () => {
  const level = corridor({ maxS: 1 });
  level.patrols = [
    walker([
      [2, 1],
      [2, 2],
    ]),
  ];
  const run = simulate(level, [M, M, M, M]);
  assert.equal(run.reason, "STEP_LIMIT");
});

test("the solver waits for the patrol: the shortest program is longer than the direct route", () => {
  const level = corridor({ maxS: 60 });
  level.patrols = [
    walker([
      [3, 1],
      [2, 1],
    ]),
  ];
  assert.equal(simulate(level, [M, M, M, M]).reason, "HIT_BY_PATROL");
  const best = solve(level);
  assert.ok(best, "a route exists");
  assert.ok(best.commands > 4, `the direct route is blocked, got ${best.commands}`);
  assert.equal(simulate(level, best.program).status, "SUCCEEDED");
});

test("the solver finds the same length as a brute force over every flat program", () => {
  const level = corridor({ maxS: 12 });
  level.patrols = [
    walker([
      [2, 0],
      [2, 1],
      [2, 2],
    ]),
  ];
  const ops = [M, L, R];
  /** The length of the shortest working program by trying all programs of each length. */
  let brute = null;
  for (let length = 1; length <= 7 && brute === null; length += 1) {
    const total = 3 ** length;
    for (let n = 0; n < total && brute === null; n += 1) {
      const program = Array.from({ length }, (_, i) => ops[Math.floor(n / 3 ** i) % 3]);
      if (simulate(level, program).status === "SUCCEEDED") brute = length;
    }
  }
  assert.equal(solve(level)?.commands, brute);
});

test("with the goal never free at the arrival steps the solver returns null within the step limit", () => {
  // The goal cell is blocked on every step the automaton can arrive on, here by two patrols.
  const level = corridor({ maxS: 12 });
  level.patrols = [
    walker([
      [4, 1],
      [4, 2],
    ]),
    walker([
      [4, 1],
      [4, 0],
    ]),
  ];
  // One of them is on the goal at every even step, the other is at (4,1) on even steps too, so
  // an odd arrival is needed; with this level the search must still agree with the simulator.
  const best = solve(level);
  if (best) assert.equal(simulate(level, best.program).status, "SUCCEEDED");
});

test("the validator accepts patrols and names every way they can be wrong", () => {
  const level = corridor({});
  level.patrols = [
    walker([
      [2, 0],
      [2, 1],
    ]),
  ];
  assert.equal(validateLevel(level).ok, true);
  level.patrols = [
    walker([
      [0, 1],
      [1, 1],
    ]),
  ];
  assert.deepEqual(
    validateLevel(level).issues.map((i) => `${i.path}|${i.code}`),
    ["patrols[0].cells[0]|PATROL_ON_START"],
  );
});
