// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { REASON_MESSAGES, explainResult, simulate, turn } from "../dist/index.js";
import { makeLevel } from "./helpers.mjs";

/** @param {string} s @returns {any[]} */
const prog = (s) =>
  s
    .split(/\s+/)
    .filter(Boolean)
    .map((t) => ({
      op:
        /** @type {Record<string,string>} */ ({
          MF: "MOVE_FORWARD",
          TL: "TURN_LEFT",
          TR: "TURN_RIGHT",
        })[t] ?? t,
    }));

test("turn rotates 90 degrees", () => {
  assert.equal(turn("north", "left"), "west");
  assert.equal(turn("west", "left"), "south");
  assert.equal(turn("south", "left"), "east");
  assert.equal(turn("east", "left"), "north");
  assert.equal(turn("north", "right"), "east");
  assert.equal(turn("east", "right"), "south");
  assert.equal(turn("south", "right"), "west");
  assert.equal(turn("west", "right"), "north");
});

test("y grows downward: north decreases y, south increases y", () => {
  const level = makeLevel({ start: [2, 2], dir: "north", goal: [4, 4] });
  assert.deepEqual(simulate(level, prog("MF")).finalState.position, [2, 1]);
  assert.deepEqual(
    simulate({ ...level, initialState: { position: [2, 2], direction: "south" } }, prog("MF"))
      .finalState.position,
    [2, 3],
  );
  assert.deepEqual(
    simulate({ ...level, initialState: { position: [2, 2], direction: "east" } }, prog("MF"))
      .finalState.position,
    [3, 2],
  );
  assert.deepEqual(
    simulate({ ...level, initialState: { position: [2, 2], direction: "west" } }, prog("MF"))
      .finalState.position,
    [1, 2],
  );
});

test("a blocked move is a counted, traced step and leaves the position unchanged", () => {
  const level = makeLevel({ walls: [[2, 2]], start: [1, 2], dir: "east", goal: [4, 4] });
  const result = simulate(level, prog("MF TL"));
  assert.equal(result.status, "FAILED");
  assert.equal(result.reason, "BLOCKED_BY_WALL");
  assert.equal(result.steps, 1);
  assert.deepEqual(result.blockedCell, [2, 2]);
  assert.deepEqual(result.trace, [
    {
      index: 0,
      op: "MOVE_FORWARD",
      node: [0],
      call: null,
      counter: 1,
      round: null,
      position: [1, 2],
      direction: "east",
      event: "BLOCKED_BY_WALL",
    },
  ]);
});

test("the goal cell is not special for turns, and entering it ends the run at once", () => {
  const level = makeLevel({ start: [0, 4], dir: "north", goal: [0, 2] });
  const result = simulate(level, prog("MF MF MF MF"));
  assert.equal(result.status, "SUCCEEDED");
  assert.equal(result.steps, 2);
  assert.equal(result.trace.at(-1)?.event, "GOAL_REACHED");
});

test("the wall check and the board edge both apply to the cell ahead only", () => {
  const level = makeLevel({ walls: [[1, 0]], start: [0, 0], dir: "east", goal: [4, 4] });
  assert.equal(simulate(level, prog("TL MF")).reason, "BLOCKED_BY_BOUNDARY");
  assert.equal(simulate(level, prog("MF")).reason, "BLOCKED_BY_WALL");
});

test("step limit: stops before executing step maxSteps + 1, but a program of exactly maxSteps is fine", () => {
  const level = makeLevel({ maxS: 2, start: [0, 0], dir: "east", goal: [4, 4] });
  assert.equal(simulate(level, prog("TL TL")).reason, "PROGRAM_ENDED");
  const over = simulate(level, prog("TL TL TL"));
  assert.equal(over.reason, "STEP_LIMIT");
  assert.equal(over.steps, 2);
  assert.equal(over.trace.length, 2);
});

test("simulate is pure and deterministic: inputs are not modified and repeated runs match", () => {
  const level = makeLevel({ walls: [[2, 2]], start: [0, 2], dir: "east", goal: [4, 2] });
  const program = prog("MF TL MF TR MF MF TR MF TL MF");
  const levelCopy = structuredClone(level);
  const programCopy = structuredClone(program);
  const first = simulate(level, program);
  const second = simulate(level, program);
  assert.deepEqual(first, second);
  assert.deepEqual(level, levelCopy);
  assert.deepEqual(program, programCopy);
  // Mutating a result must not affect later results or the level.
  first.finalState.position[0] = 99;
  first.trace[0].position[0] = 99;
  assert.deepEqual(level, levelCopy);
  assert.deepEqual(simulate(level, program), second);
});

test("simulate works on frozen inputs", () => {
  const level = structuredClone(makeLevel({ start: [0, 4], dir: "north", goal: [0, 3] }));
  const deepFreeze = (/** @type {any} */ o) => {
    for (const v of Object.values(o)) if (v && typeof v === "object") deepFreeze(v);
    return Object.freeze(o);
  };
  assert.equal(simulate(deepFreeze(level), deepFreeze(prog("MF"))).status, "SUCCEEDED");
});

test("malformed instruction nodes stop the run and are never skipped", () => {
  const level = makeLevel({ start: [0, 4], dir: "north", goal: [0, 0] });
  for (const bad of [
    null,
    5,
    "MOVE_FORWARD",
    {},
    { op: 3 },
    { op: "move_forward" },
    { op: "JUMP" },
  ]) {
    // @ts-expect-error deliberately wrong input
    const result = simulate(level, [{ op: "MOVE_FORWARD" }, bad, { op: "MOVE_FORWARD" }]);
    assert.equal(result.reason, "INVALID_INSTRUCTION");
    assert.equal(result.steps, 1);
    assert.deepEqual(result.finalState.position, [0, 3]);
  }
});

test("a non-array program is a programming error and throws", () => {
  assert.throws(() => simulate(makeLevel(), /** @type {any} */ (null)), TypeError);
});

test("explainResult has plain-language text for every reason", () => {
  const reasons = [
    "GOAL_REACHED",
    "BLOCKED_BY_WALL",
    "BLOCKED_BY_BOUNDARY",
    "PROGRAM_ENDED",
    "STEP_LIMIT",
    "HIT_BY_PATROL",
    "BLOCKED_BY_DOOR",
    "UNDELIVERED",
    "BLOCKED_BY_GATE",
    "TOO_DEEP",
    "INVALID_INSTRUCTION",
  ];
  assert.deepEqual(Object.keys(REASON_MESSAGES).sort(), [...reasons].sort());
  for (const reason of reasons) {
    const text = explainResult({ reason: /** @type {any} */ (reason) });
    assert.match(text, /^[A-Z].*\.$/);
    assert.ok(!text.includes("_"), "no raw codes in player-facing text");
    assert.ok(!text.includes("!"));
  }
  assert.equal(
    explainResult({ reason: "BLOCKED_BY_WALL" }),
    "The automaton tried to move into a wall.",
  );
  assert.equal(explainResult({ reason: "PROGRAM_ENDED" }), "The program ended before the goal.");
  assert.equal(
    explainResult({ reason: "STEP_LIMIT" }),
    "The program ran too long and was stopped.",
  );
  assert.equal(explainResult({ reason: "GOAL_REACHED" }), "Level solved.");
});
