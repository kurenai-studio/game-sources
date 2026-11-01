import { simulate } from "./simulate.js";
import type { BoardCase, Level, MultiRunResult, Program } from "./types.js";

/** Every board of a level: its own first, then the extra test boards. */
export function boardsOf(level: Level): BoardCase[] {
  return [
    { board: level.board, initialState: level.initialState, goal: level.goal },
    ...(level.extraBoards ?? []),
  ];
}

/** The level as if `index` were its only board (0 is its own board): what `simulate` runs. */
export function levelOnBoard(level: Level, index: number): Level {
  const { extraBoards: _extra, ...rest } = level;
  const chosen = boardsOf(level)[index];
  if (!chosen) throw new RangeError(`the level has no board ${index}`);
  return { ...rest, board: chosen.board, initialState: chosen.initialState, goal: chosen.goal };
}

/**
 * Runs `program` on every board of the level and reports each run. The level is solved only when every
 * run succeeded. All boards are always run, so the result shows every board that fails, not only the
 * first. A level without extra boards gives one result, the same as `simulate`.
 */
export function simulateAll(level: Level, program: Program): MultiRunResult {
  const results = boardsOf(level).map((_, i) => simulate(levelOnBoard(level, i), program));
  const failed = results.findIndex((r) => r.status !== "SUCCEEDED");
  return {
    status: failed === -1 ? "SUCCEEDED" : "FAILED",
    firstFailure: failed === -1 ? null : failed,
    steps: results.reduce((sum, r) => sum + r.steps, 0),
    results,
  };
}
