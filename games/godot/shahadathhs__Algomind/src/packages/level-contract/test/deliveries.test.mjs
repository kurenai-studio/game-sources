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
  const { deliveries, locks, ...rest } = o;
  const level = makeLevel({
    w: 5,
    h: 3,
    start: [0, 1],
    dir: "east",
    goal: [4, 1],
    maxS: 16,
    ...rest,
  });
  if (deliveries) level.deliveries = deliveries;
  if (locks) level.locks = locks;
  return level;
};

test("an item is carried to its dock, and only then does the target count", () => {
  const level = corridor({ deliveries: [{ item: [1, 1], dock: [3, 1] }] });
  const run = simulate(level, [M, M, M, M]);
  assert.equal(run.status, "SUCCEEDED");
  assert.deepEqual(
    run.trace.map((t) => t.event),
    ["ITEM_TAKEN", "MOVED", "ITEM_DROPPED", "GOAL_REACHED"],
  );
  const early = simulate(corridor({ deliveries: [{ item: [1, 0], dock: [2, 0] }] }), [M, M, M, M]);
  assert.equal(early.reason, "UNDELIVERED");
  assert.equal(early.trace.at(-1)?.event, "UNDELIVERED");
  assert.deepEqual(early.finalState.position, [4, 1]);
});

test("hands hold one item: a second item is left where it lies", () => {
  const level = corridor({
    deliveries: [
      { item: [1, 1], dock: [3, 0] },
      { item: [2, 1], dock: [3, 2] },
    ],
  });
  const run = simulate(level, [M, M]);
  assert.deepEqual(
    run.trace.map((t) => t.event),
    ["ITEM_TAKEN", "MOVED"],
  );
});

test("a dock accepts only its own item", () => {
  const level = corridor({
    deliveries: [
      { item: [1, 1], dock: [3, 0] },
      { item: [0, 0], dock: [2, 1] },
    ],
  });
  const run = simulate(level, [M, M]);
  assert.equal(run.trace[1]?.event, "MOVED");
});

test("the solver carries the item: par is longer than the straight way", () => {
  const level = corridor({ deliveries: [{ item: [1, 0], dock: [3, 0] }] });
  const best = solve(level);
  assert.ok(best);
  assert.ok(best.commands > 4);
  assert.equal(simulate(level, best.program).status, "SUCCEEDED");
});

test("the solver finds the same length as a brute force over every flat program", () => {
  const level = corridor({ deliveries: [{ item: [1, 0], dock: [2, 1] }] });
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

test("an item behind a wall leaves the level unsolvable", () => {
  const level = corridor({
    walls: [
      [2, 0],
      [3, 1],
      [4, 0],
    ],
    deliveries: [{ item: [3, 0], dock: [1, 1] }],
  });
  assert.equal(solve(level), null);
});

test("the validator accepts deliveries and names every way they can be wrong", () => {
  const level = corridor({ deliveries: [{ item: [1, 0], dock: [3, 1] }] });
  assert.equal(validateLevel(level).ok, true);
  level.deliveries = [{ item: [0, 1], dock: [4, 1] }];
  assert.deepEqual(
    validateLevel(level).issues.map((i) => `${i.path}|${i.code}`),
    ["deliveries[0].item|DELIVERY_ON_START", "deliveries[0].dock|DELIVERY_ON_GOAL"],
  );
});
