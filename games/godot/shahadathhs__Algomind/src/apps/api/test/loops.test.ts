import { describe, expect, it } from "vitest";
import {
  analyzeLevel,
  failedGates,
  type MinimumClient,
  type RegistryVersion,
} from "../src/modules/levels/level-analysis.js";
import { level } from "./support/level.js";

const COMMANDS = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT"];
const M = { op: "MOVE_FORWARD" };
const R = { op: "TURN_RIGHT" };
const L = { op: "TURN_LEFT" };
const rep = (count: number, body: unknown[]) => ({ op: "REPEAT", count, body });

/** A 7 by 7 staircase corridor: the only route climbs one cell up and one right, six times. */
const STAIRS = (() => {
  const walls: [number, number][] = [];
  const path = new Set<string>();
  let [x, y] = [0, 6];
  path.add(`${x},${y}`);
  for (let i = 0; i < 6; i += 1) {
    y -= 1;
    path.add(`${x},${y}`);
    x += 1;
    path.add(`${x},${y}`);
  }
  for (let wy = 0; wy < 7; wy += 1) {
    for (let wx = 0; wx < 7; wx += 1) if (!path.has(`${wx},${wy}`)) walls.push([wx, wy]);
  }
  return level({
    board: { width: 7, height: 7, walls },
    initialState: { position: [0, 6], direction: "north" },
    goal: { type: "reach_tile", position: [6, 0] },
    availableCommands: COMMANDS,
    constraints: { maxCommands: 5, maxSteps: 40 },
  });
})();

const SOLUTION = [rep(6, [M, R, M, L])];

describe("levels that offer REPEAT", () => {
  it("are solved by a reference solution that uses a loop, with par counted in slots", () => {
    const analysis = analyzeLevel(STAIRS, SOLUTION);
    expect(analysis.errors).toEqual([]);
    expect(analysis.referenceSolved).toBe(true);
    expect(analysis.par).toEqual({ commands: 5, steps: 23 });
    expect(analysis.requiredMechanics).toContain("repeat");
  });

  it("need the repeat mechanic from the client, and say so", () => {
    const old: MinimumClient = { version: "0.0.1", supportedMechanics: ["move", "turn"] };
    const registry: RegistryVersion[] = [
      { version: "0.0.1", supportedMechanics: ["move", "turn"] },
      { version: "0.3.0", supportedMechanics: ["move", "turn", "repeat"] },
    ];
    const failed = failedGates({
      analysis: analyzeLevel(STAIRS, SOLUTION),
      hasSolvedPlaytest: true,
      chapterId: "chapter-1",
      minimum: old,
      registry,
    });
    const issue = failed.find((i) => i.code === "UNSUPPORTED_MECHANIC");
    expect(issue?.message).toContain("0.3.0");
    expect(issue?.message).toContain("repeat");
  });

  it("publish when the minimum client supports repeat", () => {
    const minimum: MinimumClient = {
      version: "0.1.0",
      supportedMechanics: ["move", "turn", "repeat"],
    };
    const failed = failedGates({
      analysis: analyzeLevel(STAIRS, SOLUTION),
      hasSolvedPlaytest: true,
      chapterId: "chapter-1",
      minimum,
      registry: [{ version: "0.1.0", supportedMechanics: ["move", "turn", "repeat"] }],
    });
    expect(failed).toEqual([]);
  });

  it("refuse a reference solution that uses more slots than the limit allows", () => {
    // The loop costs 5 slots; a limit of 4 is below it, so validation stops the level.
    const tight = { ...STAIRS, constraints: { maxCommands: 4, maxSteps: 40 } };
    const analysis = analyzeLevel(tight, SOLUTION);
    expect(analysis.errors.map((e) => e.code)).toEqual(["TOO_MANY_COMMANDS"]);
  });

  it("warn when a loop is optional because the plain program already fits the limit", () => {
    const loose = {
      ...STAIRS,
      constraints: { maxCommands: 40, maxSteps: 100 },
    };
    const warnings = analyzeLevel(loose, SOLUTION).warnings.map((w) => w.code);
    expect(warnings).toContain("LOOP_NOT_REQUIRED");
  });

  it("do not warn when the limit forces a loop", () => {
    const warnings = analyzeLevel(STAIRS, SOLUTION).warnings.map((w) => w.code);
    expect(warnings).not.toContain("LOOP_NOT_REQUIRED");
  });

  it("count a reference solution longer than par in slots, not in nodes", () => {
    // Two loops are 2 nodes but 10 slots; par is 5, so this reference is longer than par.
    const roomy = { ...STAIRS, constraints: { maxCommands: 12, maxSteps: 100 } };
    const analysis = analyzeLevel(roomy, [rep(3, [M, R, M, L]), rep(3, [M, R, M, L])]);
    expect(analysis.errors).toEqual([]);
    expect(analysis.warnings.map((w) => w.code)).toContain("REFERENCE_LONGER_THAN_PAR");
  });

  it("reject a loop inside a loop, with its own code", () => {
    const analysis = analyzeLevel(STAIRS, [rep(2, [rep(2, [M])])]);
    expect(analysis.errors.some((e) => e.path.endsWith("body[0].op"))).toBe(true);
  });
});
