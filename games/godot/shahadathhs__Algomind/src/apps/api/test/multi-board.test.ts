import { describe, expect, it } from "vitest";
import { analyzeLevel } from "../src/modules/levels/level-analysis.js";
import { verifySubmission } from "../src/modules/points/verify-submission.js";
import { buildLevel } from "../src/modules/seed/starter-campaign.seed.js";

const until = { op: "REPEAT_UNTIL", until: "BLOCKED", body: [{ op: "MOVE_FORWARD" }] };
const M = { op: "MOVE_FORWARD" };

/** A corridor n cells long: the automaton starts at the west end and the target is at the east end. */
const corridor = (n: number) => ["#".repeat(n), `>${".".repeat(n - 2)}G`, "#".repeat(n)];

const level = (first: string[], extra: number[], maxCommands: number) =>
  buildLevel(
    {
      slug: "corridors",
      title: "Corridors",
      difficulty: "easy",
      commands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT_UNTIL"],
      maxCommands,
      rows: first,
      extraBoards: extra.map(corridor),
    },
    "multi-board-test",
  );

describe("levels with test boards", () => {
  // The own board is 2 long, so one move is the best program for it alone, and it does not work on
  // the longer boards.
  const multi = level(["###", ">G#", "###"], [8, 12], 4);

  it("are solved only by a program that works on every board, and say so", () => {
    expect(analyzeLevel(multi, [until]).errors).toEqual([]);
    const overfit = analyzeLevel(multi, [M, M, M, M]);
    expect(overfit.referenceSolved).toBe(false);
    expect(overfit.errors[0]?.message).toContain("Board 2");
  });

  it("take par from the reference solution, with the steps of all boards added", () => {
    const analysis = analyzeLevel(multi, [until]);
    expect(analysis.par).toEqual({ commands: 2, steps: 1 + 7 + 11 });
    expect(analysis.requiredMechanics).toContain("multi_board");
    expect(analysis.warnings.map((w) => w.code)).not.toContain("BOARDS_NOT_REQUIRED");
  });

  it("warn when the best program for the first board already solves every board", () => {
    // A first board long enough for the loop to win: the loop is also the general program.
    const same = level(corridor(8), [8], 2);
    expect(analyzeLevel(same, [until]).warnings.map((w) => w.code)).toContain(
      "BOARDS_NOT_REQUIRED",
    );
  });

  it("are submitted as a program that solves every board, and count all the steps", () => {
    expect(verifySubmission(multi, [until])).toEqual({ ok: true, slots: 2, steps: 1 + 7 + 11 });
    expect(verifySubmission(multi, [M, M, M, M])).toMatchObject({
      ok: false,
      code: "PROGRAM_DID_NOT_SOLVE",
    });
  });
});
