import { describe, expect, it } from "vitest";
import { analyzeLevel } from "../src/modules/levels/level-analysis.js";
import { programHash } from "../src/modules/points/verify-submission.js";
import { LEVELS, buildLevel } from "../src/modules/seed/starter-campaign.seed.js";
import { level } from "./support/level.js";

const M = { op: "MOVE_FORWARD" };
const R = { op: "TURN_RIGHT" };
const L = { op: "TURN_LEFT" };
const iff = (when: string, then: { op: string }[], other: { op: string }[] = []) => ({
  op: "IF",
  when,
  then,
  else: other,
});
const RIGHT_HAND = [
  {
    op: "REPEAT_UNTIL",
    until: "GOAL",
    body: [iff("CLEAR_RIGHT", [R]), iff("CLEAR_AHEAD", [M], [L])],
  },
];

describe("levels that offer IF", () => {
  const entry = LEVELS.find((l) => l.def.slug === "small-maze")!;
  const maze = buildLevel(entry.def, "if-test-maze");

  it("take their par from the reference solution, in slots", () => {
    const analysis = analyzeLevel(maze, RIGHT_HAND);
    expect(analysis.errors).toEqual([]);
    expect(analysis.referenceSolved).toBe(true);
    expect(analysis.par?.commands).toBe(6);
    expect(analysis.requiredMechanics).toEqual(
      expect.arrayContaining(["if", "repeat_until", "move", "turn"]),
    );
    expect(analysis.warnings.map((w) => w.code)).not.toContain("IF_NOT_REQUIRED");
  });

  it("refuse a reference solution that is over the limit", () => {
    const tight = { ...maze, constraints: { ...maze.constraints, maxCommands: 5 } };
    expect(analyzeLevel(tight, RIGHT_HAND).errors.map((e) => e.code)).toContain(
      "TOO_MANY_COMMANDS",
    );
  });

  it("warn when the decision is optional", () => {
    const easy = level({
      availableCommands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "IF"],
      constraints: { maxCommands: 8, maxSteps: 20 },
    });
    const analysis = analyzeLevel(easy, [iff("CLEAR_AHEAD", [M], [R]), M, M, M, M]);
    expect(analysis.warnings.map((w) => w.code)).toContain("IF_NOT_REQUIRED");
  });

  it("hash a program by its structure, branches and conditions included", () => {
    const base = programHash([iff("CLEAR_AHEAD", [M], [R])]);
    expect(base).toBe(programHash([iff("CLEAR_AHEAD", [M], [R])]));
    expect(base).not.toBe(programHash([iff("CLEAR_LEFT", [M], [R])]));
    expect(base).not.toBe(programHash([iff("CLEAR_AHEAD", [R], [M])]));
    expect(programHash(RIGHT_HAND)).not.toBe(
      programHash([{ ...RIGHT_HAND[0]!, until: "BLOCKED" }]),
    );
  });
});
