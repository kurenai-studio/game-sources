import { describe, expect, it } from "vitest";
import {
  analyzeLevel,
  contentHash,
  failedGates,
  type MinimumClient,
  type RegistryVersion,
} from "../src/modules/levels/level-analysis.js";
import { level, SOLUTION } from "./support/level.js";

const MINIMUM: MinimumClient = { version: "0.0.1", supportedMechanics: ["move", "turn"] };
const REGISTRY: RegistryVersion[] = [{ version: "0.0.1", supportedMechanics: ["move", "turn"] }];

/** Gates for a level, with every other gate satisfied unless the test says otherwise. */
function gates(
  content: unknown,
  solution: unknown,
  overrides: Partial<Parameters<typeof failedGates>[0]> = {},
) {
  return failedGates({
    analysis: analyzeLevel(content, solution),
    hasSolvedPlaytest: true,
    chapterId: "chapter-1",
    minimum: MINIMUM,
    registry: REGISTRY,
    ...overrides,
  });
}

const codes = (issues: { code: string }[]) => issues.map((i) => i.code);

describe("publish gates", () => {
  it("lets a valid, solved, tested, compatible, placed level through", () => {
    expect(gates(level(), SOLUTION)).toEqual([]);
  });

  it("validation: refuses a level the contract rejects, and skips the later checks", () => {
    const failed = gates(level({ board: { width: 99, height: 5, walls: [] } }), SOLUTION);
    expect(failed.some((i) => i.gate === "validation" && i.path === "board.width")).toBe(true);
    expect(failed.some((i) => i.gate === "reference_solution" || i.gate === "par")).toBe(false);
  });

  it("reference solution: refuses a solution that does not reach the goal", () => {
    const failed = gates(level(), [{ op: "MOVE_FORWARD" }]);
    expect(codes(failed)).toContain("REFERENCE_SOLUTION_FAILS");
  });

  it("start program: a debug level's start program must not already solve it", () => {
    const solves = gates(level({ startProgram: SOLUTION }), SOLUTION);
    expect(codes(solves)).toContain("START_PROGRAM_SOLVES");
    expect(solves.find((i) => i.code === "START_PROGRAM_SOLVES")?.gate).toBe("start_program");
  });

  it("start program: a broken program passes, and the level then needs the mechanic", () => {
    const broken = [{ op: "MOVE_FORWARD" }, { op: "MOVE_FORWARD" }, { op: "TURN_LEFT" }];
    // An app that cannot start a tape with a program refuses the level, which is the point.
    const needs = codes(gates(level({ startProgram: broken }), SOLUTION));
    expect(needs).toEqual(["UNSUPPORTED_MECHANIC"]);
    const supported = {
      minimum: { version: "0.0.2", supportedMechanics: ["move", "turn", "start_program"] },
      registry: [{ version: "0.0.2", supportedMechanics: ["move", "turn", "start_program"] }],
    };
    expect(gates(level({ startProgram: broken }), SOLUTION, supported)).toEqual([]);
    const analysis = analyzeLevel(level({ startProgram: broken }), SOLUTION);
    expect(analysis.requiredMechanics).toContain("start_program");
    expect(analyzeLevel(level(), SOLUTION).requiredMechanics).not.toContain("start_program");
  });

  it("start program: one longer than the limit is refused by the validator", () => {
    const tooLong = Array.from({ length: 7 }, () => ({ op: "MOVE_FORWARD" }));
    const failed = gates(level({ startProgram: tooLong }), SOLUTION);
    expect(failed.some((i) => i.gate === "validation" && i.path === "startProgram")).toBe(true);
  });

  it("patrol: a level with guards needs the mechanic, and its par is searched over time", () => {
    // A guard on the far side of the board never meets the straight solution.
    const guarded = level({
      patrols: [
        {
          pattern: "back_and_forth",
          cells: [
            [4, 4],
            [3, 4],
          ],
        },
      ],
    });
    const analysis = analyzeLevel(guarded, SOLUTION);
    expect(analysis.errors).toEqual([]);
    expect(analysis.requiredMechanics).toContain("patrol");
    expect(analyzeLevel(level(), SOLUTION).requiredMechanics).not.toContain("patrol");
    expect(codes(gates(guarded, SOLUTION))).toEqual(["UNSUPPORTED_MECHANIC"]);
  });

  it("patrol: a reference solution that meets a guard does not solve the level", () => {
    const blocked = level({
      patrols: [
        {
          pattern: "loop",
          cells: [
            [1, 3],
            [0, 3],
            [0, 2],
            [1, 2],
          ],
        },
      ],
    });
    const failed = gates(blocked, SOLUTION, {
      minimum: { version: "0.0.2", supportedMechanics: ["move", "turn", "patrol"] },
      registry: [{ version: "0.0.2", supportedMechanics: ["move", "turn", "patrol"] }],
    });
    expect(codes(failed)).toContain("REFERENCE_SOLUTION_FAILS");
  });

  it("keys: a level with doors needs the mechanic, and a door that blocks the way needs its key", () => {
    // The straight way north is shut by a door whose key is one cell to the side.
    const shut = level({ locks: [{ key: [1, 4], door: [0, 2] }] });
    const analysis = analyzeLevel(shut, SOLUTION);
    expect(analysis.requiredMechanics).toContain("keys");
    expect(analyzeLevel(level(), SOLUTION).requiredMechanics).not.toContain("keys");
    // The straight program meets the door, so it is not a solution.
    expect(analysis.errors.map((e) => e.code)).toContain("REFERENCE_SOLUTION_FAILS");
  });

  it("delivery: a level with crates needs the mechanic, and the straight way is not a solution", () => {
    const parcel = level({ deliveries: [{ item: [1, 4], dock: [2, 3] }] });
    const analysis = analyzeLevel(parcel, SOLUTION);
    expect(analysis.requiredMechanics).toContain("delivery");
    expect(analyzeLevel(level(), SOLUTION).requiredMechanics).not.toContain("delivery");
    // The straight program reaches the target with the crate undelivered.
    expect(analysis.errors.map((e) => e.code)).toContain("REFERENCE_SOLUTION_FAILS");
  });

  it("switch: a level with gates needs the mechanic, and a shut gate on the way blocks the straight program", () => {
    const shut = level({ switches: [{ switch: [1, 4], gate: [0, 2] }] });
    const analysis = analyzeLevel(shut, SOLUTION);
    expect(analysis.requiredMechanics).toContain("switch");
    expect(analyzeLevel(level(), SOLUTION).requiredMechanics).not.toContain("switch");
    expect(analysis.errors.map((e) => e.code)).toContain("REFERENCE_SOLUTION_FAILS");
  });

  it("ice and belts: a level with them needs the mechanics, and the slide changes where a move ends", () => {
    const icy = level({
      ice: [
        [0, 3],
        [0, 2],
      ],
    });
    const analysis = analyzeLevel(icy, SOLUTION);
    expect(analysis.requiredMechanics).toContain("ice");
    expect(analysis.requiredMechanics).not.toContain("belts");
    const belted = level({ belts: [{ cell: [0, 3], direction: "east" }] });
    expect(analyzeLevel(belted, SOLUTION).requiredMechanics).toContain("belts");
    expect(analyzeLevel(level(), SOLUTION).requiredMechanics).not.toContain("ice");
  });

  it("teleport: a level with a pair needs the mechanic", () => {
    const portal = level({ teleports: [{ a: [0, 3], b: [4, 0] }] });
    expect(analyzeLevel(portal, SOLUTION).requiredMechanics).toContain("teleport");
    expect(analyzeLevel(level(), SOLUTION).requiredMechanics).not.toContain("teleport");
  });

  it("recursion: a procedure may call itself only on a level that lists the mechanic", () => {
    const recursive = [
      {
        op: "PROC",
        name: "A",
        body: [{ op: "MOVE_FORWARD" }, { op: "CALL", name: "A", when: "CLEAR_AHEAD" }],
      },
      { op: "CALL", name: "A" },
    ];
    const withMechanic = analyzeLevel(
      level({
        availableCommands: ["MOVE_FORWARD", "PROC"],
        requires: { mechanics: ["recursion"] },
      }),
      recursive,
    );
    expect(withMechanic.requiredMechanics).toContain("recursion");
    expect(withMechanic.errors.map((e) => e.code)).not.toContain("CALL_NOT_ALLOWED");
    const without = analyzeLevel(level({ availableCommands: ["MOVE_FORWARD", "PROC"] }), recursive);
    expect(without.errors.map((e) => e.code)).toContain("CALL_NOT_ALLOWED");
  });

  it("par: refuses a goal that cannot be reached", () => {
    const walled = level({
      board: {
        width: 5,
        height: 5,
        walls: [
          [0, 3],
          [1, 4],
        ],
      },
    });
    expect(codes(gates(walled, SOLUTION))).toContain("GOAL_UNREACHABLE");
  });

  it("par: refuses a command limit below the shortest solution", () => {
    // No solution fits under par, so the reference here is a short one that does not solve it.
    const tight = level({ constraints: { maxCommands: 2, maxSteps: 20 } });
    const failed = gates(tight, [{ op: "MOVE_FORWARD" }, { op: "MOVE_FORWARD" }]);
    expect(codes(failed)).toContain("BUDGET_BELOW_PAR");
  });

  it("validation: refuses a reference solution longer than the command limit", () => {
    const tight = level({ constraints: { maxCommands: 2, maxSteps: 20 } });
    expect(codes(gates(tight, SOLUTION))).toContain("TOO_MANY_COMMANDS");
  });

  it("par: refuses a step limit below the shortest solution", () => {
    const tight = level({ constraints: { maxCommands: 6, maxSteps: 2 } });
    expect(codes(gates(tight, SOLUTION))).toContain("STEPS_BELOW_PAR");
  });

  it("playtest: refuses a level with no solved playtest for the current content", () => {
    expect(codes(gates(level(), SOLUTION, { hasSolvedPlaytest: false }))).toEqual([
      "PLAYTEST_REQUIRED",
    ]);
  });

  it("compatibility: refuses when no minimum client version is set", () => {
    expect(codes(gates(level(), SOLUTION, { minimum: null }))).toEqual([
      "NO_MINIMUM_CLIENT_VERSION",
    ]);
  });

  it("compatibility: refuses a mechanic the minimum client does not support, and says where it is", () => {
    const old: MinimumClient = { version: "0.0.1", supportedMechanics: ["move"] };
    const registry: RegistryVersion[] = [
      { version: "0.0.1", supportedMechanics: ["move"] },
      { version: "0.2.0", supportedMechanics: ["move", "turn"] },
    ];
    const failed = gates(level(), SOLUTION, { minimum: old, registry });
    const issue = failed.find((i) => i.code === "UNSUPPORTED_MECHANIC");
    expect(issue?.message).toContain("0.2.0");
  });

  it("placement: refuses a level that is not in a chapter", () => {
    expect(codes(gates(level(), SOLUTION, { chapterId: null }))).toEqual(["PLACEMENT_REQUIRED"]);
  });

  it("reports every failed gate at once, not only the first", () => {
    const failed = gates(level(), SOLUTION, {
      hasSolvedPlaytest: false,
      chapterId: null,
      minimum: null,
    });
    expect(codes(failed).sort()).toEqual(
      ["NO_MINIMUM_CLIENT_VERSION", "PLACEMENT_REQUIRED", "PLAYTEST_REQUIRED"].sort(),
    );
  });

  it("warns, without blocking, when the limit is far above par or the solution is long", () => {
    const loose = level({ constraints: { maxCommands: 40, maxSteps: 100 } });
    const analysis = analyzeLevel(loose, [...SOLUTION, { op: "TURN_LEFT" }, { op: "TURN_RIGHT" }]);
    expect(analysis.errors).toEqual([]);
    expect(analysis.warnings.map((w) => w.code).sort()).toEqual([
      "BUDGET_FAR_ABOVE_PAR",
      "REFERENCE_LONGER_THAN_PAR",
    ]);
  });
});

describe("content hash (ties a playtest to exact content)", () => {
  it("is stable for the same content whatever the key order", () => {
    const a = level();
    const b = Object.fromEntries(Object.entries(a).reverse());
    expect(contentHash(a)).toBe(contentHash(b));
  });

  it("ignores the level version, so a restored draft keeps its playtests", () => {
    expect(contentHash(level({ levelVersion: 1 }))).toBe(contentHash(level({ levelVersion: 7 })));
  });

  it("changes when the board changes, which makes earlier playtests stale", () => {
    expect(contentHash(level())).not.toBe(
      contentHash(level({ board: { width: 5, height: 5, walls: [[2, 2]] } })),
    );
  });
});
