import { describe, expect, it } from "vitest";
import { DEFAULT_POINTS_RULES, scoreResult } from "@algomind/level-contract";
import { programHash, verifySubmission } from "../src/modules/points/verify-submission.js";
import {
  pointsRulesInputSchema,
  submissionBodySchema,
} from "../src/modules/points/points.schemas.js";
import { SOLUTION, level } from "./support/level.js";

describe("verifySubmission", () => {
  it("accepts a program that reaches the goal and reports slots and steps", () => {
    expect(verifySubmission(level(), SOLUTION)).toEqual({ ok: true, slots: 4, steps: 4 });
  });

  it("counts a loop as one slot plus its body", () => {
    const content = level({
      availableCommands: ["MOVE_FORWARD", "REPEAT"],
      constraints: { maxCommands: 6, maxSteps: 20 },
      requires: { mechanics: ["repeat"] },
    });
    const result = verifySubmission(content, [
      { op: "REPEAT", count: 4, body: [{ op: "MOVE_FORWARD" }] },
    ]);
    expect(result).toEqual({ ok: true, slots: 2, steps: 4 });
  });

  it("refuses a program that does not reach the goal: it is not a submission", () => {
    const result = verifySubmission(level(), SOLUTION.slice(0, 3));
    expect(result).toMatchObject({ ok: false, code: "PROGRAM_DID_NOT_SOLVE" });
  });

  it("refuses a program that uses a command the level does not offer", () => {
    const content = level({ availableCommands: ["MOVE_FORWARD"] });
    const result = verifySubmission(content, [...SOLUTION, { op: "TURN_LEFT" }]);
    expect(result).toMatchObject({ ok: false, code: "PROGRAM_INVALID" });
  });

  it("refuses a program longer than the level allows", () => {
    const long = Array.from({ length: 7 }, () => ({ op: "MOVE_FORWARD" }));
    expect(verifySubmission(level(), long)).toMatchObject({ ok: false, code: "PROGRAM_INVALID" });
  });

  it("refuses stored content that is not a valid level", () => {
    expect(verifySubmission({ nope: true }, SOLUTION)).toMatchObject({
      ok: false,
      code: "LEVEL_INVALID",
    });
  });
});

describe("programHash", () => {
  it("is the same for the same program and different otherwise", () => {
    expect(programHash(SOLUTION)).toBe(programHash(SOLUTION.map((n) => ({ ...n }))));
    expect(programHash(SOLUTION)).not.toBe(programHash(SOLUTION.slice(1)));
  });

  it("ignores key order and extra fields on a loop", () => {
    const a = [{ op: "REPEAT", count: 3, body: [{ op: "MOVE_FORWARD" }] }];
    const b = [{ body: [{ op: "MOVE_FORWARD" }], count: 3, op: "REPEAT" }];
    expect(programHash(a)).toBe(programHash(b));
    expect(programHash(a)).not.toBe(
      programHash([{ op: "REPEAT", count: 4, body: [{ op: "MOVE_FORWARD" }] }]),
    );
  });
});

describe("submission input", () => {
  it("takes a program and never a score", () => {
    const body = { levelSlug: "first-step", levelVersion: 1, program: SOLUTION };
    expect(submissionBodySchema.safeParse(body).success).toBe(true);
    expect(submissionBodySchema.safeParse({ ...body, program: [] }).success).toBe(false);
    const withScore = { ...body, program: [{ op: "MOVE_FORWARD", points: 999 }] };
    expect(submissionBodySchema.safeParse(withScore).success).toBe(false);
  });
});

describe("rule sets", () => {
  const { version: _version, ...input } = DEFAULT_POINTS_RULES;

  it("accept the defaults and refuse unknown or negative values", () => {
    expect(pointsRulesInputSchema.safeParse(input).success).toBe(true);
    expect(pointsRulesInputSchema.safeParse({ ...input, parFull: -1 }).success).toBe(false);
    expect(pointsRulesInputSchema.safeParse({ ...input, bonus: 5 }).success).toBe(false);
  });

  it("change what a result is worth without touching the score of the old rules", () => {
    const result = {
      difficulty: "easy" as const,
      par: { commands: 4, steps: 4 },
      slots: 4,
      steps: 4,
    };
    const before = scoreResult(DEFAULT_POINTS_RULES, result);
    const richer = scoreResult({ ...DEFAULT_POINTS_RULES, version: 2, parFull: 50 }, result);
    expect(richer.points).toBe(before.points + 40);
    expect(scoreResult(DEFAULT_POINTS_RULES, result)).toEqual(before);
  });
});
