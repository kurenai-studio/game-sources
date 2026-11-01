// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import {
  LIMITS,
  simulate,
  solve,
  validateAuthoringLevel,
  validateLevel,
  validateProgram,
} from "../dist/index.js";
import { makeLevel, rng } from "./helpers.mjs";

/** @param {any} level */
const codes = (level) => validateLevel(level).issues.map((i) => `${i.path}|${i.code}`);

test("a default test level is valid", () => {
  assert.deepEqual(validateLevel(makeLevel()), { ok: true, issues: [] });
});

test("board side limits are inclusive", () => {
  const { min, max } = LIMITS.boardSide;
  assert.deepEqual(codes(makeLevel({ w: min, h: min, start: [0, 2], goal: [2, 0] })), []);
  assert.deepEqual(codes(makeLevel({ w: max, h: max, start: [0, 0], goal: [11, 11] })), []);
  assert.deepEqual(codes(makeLevel({ w: min - 1, h: max + 1 })), [
    "board.width|OUT_OF_RANGE",
    "board.height|OUT_OF_RANGE",
  ]);
});

test("constraint limits are inclusive", () => {
  const level = makeLevel();
  level.constraints = { maxCommands: LIMITS.maxCommands.max, maxSteps: LIMITS.maxSteps.max };
  assert.deepEqual(codes(level), []);
  level.constraints = { maxCommands: LIMITS.maxCommands.min, maxSteps: LIMITS.maxSteps.min };
  assert.deepEqual(codes(level), []);
  level.constraints = {
    maxCommands: LIMITS.maxCommands.max + 1,
    maxSteps: LIMITS.maxSteps.max + 1,
  };
  assert.deepEqual(codes(level), [
    "constraints.maxCommands|OUT_OF_RANGE",
    "constraints.maxSteps|OUT_OF_RANGE",
  ]);
});

test("exactly the maximum number of walls is accepted", () => {
  /** @type {number[][]} */
  const walls = [];
  for (let y = 1; y < 12 && walls.length < LIMITS.maxWalls; y++) {
    for (let x = 0; x < 12 && walls.length < LIMITS.maxWalls; x++) walls.push([x, y]);
  }
  assert.deepEqual(codes(makeLevel({ w: 12, h: 12, walls, start: [0, 0], goal: [11, 0] })), []);
});

test("string lengths are counted in code points", () => {
  const level = makeLevel();
  level.title = "\u{1D49C}".repeat(LIMITS.title.max);
  assert.deepEqual(codes(level), []);
  level.title = "\u{1D49C}".repeat(LIMITS.title.max + 1);
  assert.deepEqual(codes(level), ["title|LENGTH_OUT_OF_RANGE"]);
});

test("integers must be integers: floats, NaN and Infinity are rejected", () => {
  for (const bad of [5.5, Number.NaN, Number.POSITIVE_INFINITY, "5", null, undefined]) {
    const level = makeLevel();
    level.board.width = bad;
    assert.ok(
      codes(level).includes("board.width|INVALID_TYPE") ||
        codes(level).includes("board.width|REQUIRED"),
    );
  }
});

test("an unsupported schema version reports only that issue", () => {
  assert.deepEqual(codes({ schemaVersion: 2, nonsense: true }), [
    "schemaVersion|UNSUPPORTED_SCHEMA_VERSION",
  ]);
  assert.deepEqual(codes({ schemaVersion: 0 }), ["schemaVersion|UNSUPPORTED_SCHEMA_VERSION"]);
});

test("validators never throw on garbage input", () => {
  const garbage = [
    undefined,
    null,
    0,
    NaN,
    "",
    "level",
    true,
    [],
    [[]],
    {},
    { schemaVersion: 1 },
    () => 1,
    Symbol("x"),
    10n,
    new Date(),
    new Map(),
    Object.create(null),
    { schemaVersion: 1, board: { walls: [[Symbol("x"), 10n]] } },
    {
      get schemaVersion() {
        throw new Error("boom");
      },
    },
    new Proxy(
      {},
      {
        ownKeys() {
          throw new Error("boom");
        },
      },
    ),
  ];
  const level = makeLevel();
  for (const g of garbage) {
    assert.doesNotThrow(() => validateLevel(g));
    assert.doesNotThrow(() => validateAuthoringLevel(g));
    assert.doesNotThrow(() => validateProgram(level, g));
    assert.equal(validateLevel(g).ok, false);
  }
});

test("random mutations never throw, and a level that passes is safe to simulate and solve", () => {
  const r = rng(1234);
  const junk = [
    null,
    undefined,
    0,
    -1,
    1.5,
    "x",
    "",
    [],
    {},
    [1, 2],
    [[0, 0]],
    true,
    "MOVE_FORWARD",
    { op: "x" },
  ];
  let accepted = 0;
  for (let n = 0; n < 2000; n++) {
    /** @type {any} */
    const level = makeLevel({ walls: [[1, 1]], start: [0, 4], goal: [4, 0] });
    /** @type {string[][]} */
    const targets = [
      ["levelId"],
      ["levelVersion"],
      ["board"],
      ["board", "width"],
      ["board", "walls"],
      ["board", "walls", "0"],
      ["initialState"],
      ["initialState", "position"],
      ["initialState", "direction"],
      ["goal"],
      ["goal", "position"],
      ["availableCommands"],
      ["availableCommands", "0"],
      ["constraints"],
      ["constraints", "maxSteps"],
      ["hints"],
      ["requires"],
    ];
    for (let k = r.int(1, 3); k > 0; k--) {
      const t = r.pick(targets);
      /** @type {any} */
      let o = level;
      for (const key of t.slice(0, -1)) o = o?.[key];
      const last = /** @type {string} */ (t[t.length - 1]);
      if (o && typeof o === "object") {
        if (r.next() < 0.3) delete o[last];
        else o[last] = r.pick(junk);
      }
    }
    const result = validateLevel(level);
    assert.equal(result.ok, result.issues.length === 0);
    if (result.ok) {
      accepted += 1;
      assert.doesNotThrow(() => simulate(level, [{ op: "MOVE_FORWARD" }, { op: "TURN_LEFT" }]));
      assert.doesNotThrow(() => solve(level));
    }
  }
  assert.ok(accepted > 0, "the mutation test should sometimes produce valid levels");
});

test("validateProgram checks ops, availability, shape and length", () => {
  const level = makeLevel({ cmds: ["MOVE_FORWARD", "TURN_LEFT"], maxC: 3 });
  const check = (/** @type {unknown} */ p) =>
    validateProgram(level, p).issues.map((i) => `${i.path}|${i.code}`);
  assert.deepEqual(check([]), []);
  assert.deepEqual(
    check([{ op: "MOVE_FORWARD" }, { op: "TURN_LEFT" }, { op: "MOVE_FORWARD" }]),
    [],
  );
  assert.deepEqual(check(Array.from({ length: 4 }, () => ({ op: "MOVE_FORWARD" }))), [
    "program|TOO_MANY_COMMANDS",
  ]);
  assert.deepEqual(check([{ op: "TURN_RIGHT" }]), ["program[0].op|COMMAND_NOT_AVAILABLE"]);
  assert.deepEqual(check([{ op: "JUMP" }]), ["program[0].op|UNKNOWN_COMMAND"]);
  assert.deepEqual(check(["MOVE_FORWARD"]), ["program[0]|INVALID_TYPE"]);
  assert.deepEqual(check([{}]), ["program[0].op|REQUIRED"]);
  assert.deepEqual(check([{ op: 1 }]), ["program[0].op|INVALID_TYPE"]);
  assert.deepEqual(check([{ op: "MOVE_FORWARD", n: 2 }]), ["program[0].n|UNKNOWN_FIELD"]);
  assert.deepEqual(check("MOVE_FORWARD"), ["program|INVALID_TYPE"]);
  assert.deepEqual(check(null), ["program|INVALID_TYPE"]);
});

test("issues carry path, stable code and a human message", () => {
  const level = makeLevel();
  level.board.width = 2;
  const [issue] = validateLevel(level).issues;
  assert.deepEqual(Object.keys(issue ?? {}).sort(), ["code", "message", "path"]);
  assert.equal(issue?.path, "board.width");
  assert.equal(issue?.code, "OUT_OF_RANGE");
  assert.match(issue?.message ?? "", /between 3 and 12/);
});
