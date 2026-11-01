import { describe, expect, it } from "vitest";
import { analyzeLevel } from "../src/modules/levels/level-analysis.js";
import { programHash, verifySubmission } from "../src/modules/points/verify-submission.js";
import { buildLevel } from "../src/modules/seed/starter-campaign.seed.js";

const M = { op: "MOVE_FORWARD" };
const R = { op: "TURN_RIGHT" };
const L = { op: "TURN_LEFT" };
const INC = { op: "INC" };
const MARK = { op: "MARK" };
const until = (body: unknown[]) => ({ op: "REPEAT_UNTIL", until: "BLOCKED", body });
const forever = (body: unknown[]) => ({ op: "REPEAT_UNTIL", until: "GOAL", body });
const rep = (count: number | string, body: unknown[]) => ({ op: "REPEAT", count, body });
const iff = (when: string, then: unknown[], other: unknown[] = []) => ({
  op: "IF",
  when,
  then,
  else: other,
});

describe("a sweep level (no target on the board)", () => {
  const lawnmower = forever([until([M]), R, M, R, until([M]), L, M, L]);
  const level = buildLevel(
    {
      slug: "sweep",
      title: "Sweep",
      difficulty: "easy",
      commands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT_UNTIL"],
      maxCommands: 11,
      maxSteps: 100,
      rows: ["> . . . .", ". . . . .", ". . . . ."].map((r) => r.replaceAll(" ", "")),
    } as never,
    "sweep-test",
  );

  it("takes its par from the reference solution and needs the visit_all mechanic", () => {
    const withMechanic = { ...level, requires: { mechanics: ["nested_loops"] } };
    const analysis = analyzeLevel(withMechanic, [lawnmower]);
    expect(analysis.errors).toEqual([]);
    expect(analysis.par?.commands).toBe(11);
    expect(analysis.requiredMechanics).toEqual(
      expect.arrayContaining(["visit_all", "nested_loops"]),
    );
  });

  it("is verified by sweeping every cell, and a partial sweep is refused", () => {
    const withMechanic = { ...level, requires: { mechanics: ["nested_loops"] } };
    expect(verifySubmission(withMechanic, [lawnmower])).toMatchObject({ ok: true, slots: 11 });
    expect(verifySubmission(withMechanic, [until([M])])).toMatchObject({
      ok: false,
      code: "PROGRAM_DID_NOT_SOLVE",
    });
  });
});

describe("counter and breadcrumb levels", () => {
  it("derive their mechanics from the commands they offer", () => {
    const level = buildLevel(
      {
        slug: "counter",
        title: "Counter",
        difficulty: "easy",
        commands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT", "INC", "MARK", "IF"],
        maxCommands: 30,
        maxSteps: 100,
        rows: ["...", ">.G", "..."],
      } as never,
      "counter-test",
    );
    const analysis = analyzeLevel(level, [M, M]);
    expect(analysis.errors).toEqual([]);
    expect(analysis.requiredMechanics).toEqual(
      expect.arrayContaining(["counter", "markers", "if"]),
    );
  });

  it("hash programs by counts, nesting and else-if chains in full", () => {
    const a = programHash([rep("N", [M, INC])] as never);
    expect(a).not.toBe(programHash([rep(2, [M, INC])] as never));
    const chainA = programHash([
      iff("FRESH_AHEAD", [M], [iff("BACK_LEFT", [L, M], [R, R, M])]),
    ] as never);
    const chainB = programHash([
      iff("FRESH_AHEAD", [M], [iff("BACK_RIGHT", [L, M], [R, R, M])]),
    ] as never);
    expect(chainA).not.toBe(chainB);
    expect(programHash([MARK] as never)).not.toBe(programHash([M] as never));
  });
});
