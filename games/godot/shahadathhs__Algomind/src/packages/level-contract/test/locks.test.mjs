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
  const { locks, patrols, ...rest } = o;
  const level = makeLevel({
    w: 5,
    h: 3,
    start: [0, 1],
    dir: "east",
    goal: [4, 1],
    maxS: 14,
    ...rest,
  });
  if (locks) level.locks = locks;
  if (patrols) level.patrols = patrols;
  return level;
};

test("a door blocks until its key is held, then it is an ordinary cell", () => {
  const level = corridor({ locks: [{ key: [1, 0], door: [3, 1] }] });
  const blocked = simulate(level, [M, M, M, M]);
  assert.equal(blocked.reason, "BLOCKED_BY_DOOR");
  assert.deepEqual(blocked.blockedCell, [3, 1]);
  assert.equal(blocked.trace.at(-1)?.event, "BLOCKED_BY_DOOR");
  const opened = simulate(level, [L, M, R, M, R, M, L, M, M, M]);
  assert.equal(opened.status, "SUCCEEDED");
  assert.equal(opened.trace[1]?.event, "MOVED");
  assert.ok(opened.trace.some((t) => t.event === "KEY_TAKEN"));
});

test("a patrol and a key on one level: the hit comes before the key", () => {
  const level = corridor({
    locks: [{ key: [1, 1], door: [3, 1] }],
    patrols: [
      {
        pattern: "back_and_forth",
        cells: [
          [1, 2],
          [1, 1],
        ],
      },
    ],
  });
  const run = simulate(level, [M, M, M, M]);
  assert.equal(run.reason, "HIT_BY_PATROL");
  assert.ok(!run.trace.some((t) => t.event === "KEY_TAKEN"));
});

test("the solver fetches the key: par is longer than the straight way", () => {
  const level = corridor({ locks: [{ key: [1, 0], door: [3, 1] }] });
  const best = solve(level);
  assert.ok(best);
  assert.ok(best.commands > 4);
  assert.equal(simulate(level, best.program).status, "SUCCEEDED");
});

test("the solver finds the same length as a brute force over every flat program", () => {
  const level = corridor({
    locks: [
      { key: [1, 0], door: [2, 1] },
      { key: [1, 2], door: [3, 1] },
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
  assert.ok(brute !== null);
  assert.equal(solve(level)?.commands, brute);
});

test("an unreachable key leaves the level unsolvable", () => {
  const level = corridor({
    walls: [
      [2, 0],
      [2, 2],
    ],
    locks: [{ key: [3, 0], door: [2, 1] }],
  });
  assert.equal(solve(level), null);
});

test("the validator accepts keys and names every way they can be wrong", () => {
  const level = corridor({ locks: [{ key: [1, 0], door: [3, 1] }] });
  assert.equal(validateLevel(level).ok, true);
  level.locks = [{ key: [0, 1], door: [4, 1] }];
  assert.deepEqual(
    validateLevel(level).issues.map((i) => `${i.path}|${i.code}`),
    ["locks[0].key|LOCK_ON_START", "locks[0].door|LOCK_ON_GOAL"],
  );
});
