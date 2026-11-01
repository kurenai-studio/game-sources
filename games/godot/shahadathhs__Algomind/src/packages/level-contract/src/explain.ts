import type { RunReason, RunResult } from "./types.js";

/**
 * Plain-language text for every run reason, in one place. Style follows docs/README_VISUAL_DESIGN.md
 * section 7; the game may show these in capitals.
 */
export const REASON_MESSAGES: Record<RunReason, string> = {
  GOAL_REACHED: "Level solved.",
  BLOCKED_BY_WALL: "The automaton tried to move into a wall.",
  BLOCKED_BY_BOUNDARY: "The automaton tried to move off the board.",
  PROGRAM_ENDED: "The program ended before the goal.",
  STEP_LIMIT: "The program ran too long and was stopped.",
  HIT_BY_PATROL: "A guard reached the automaton.",
  BLOCKED_BY_DOOR: "The automaton tried to go through a locked door.",
  BLOCKED_BY_GATE: "The automaton tried to go through a shut gate.",
  TOO_DEEP: "The procedures called each other too many times.",
  UNDELIVERED: "The automaton reached the target before every item was delivered.",
  INVALID_INSTRUCTION: "The program contains an instruction this level cannot run.",
};

/** Returns the plain-language explanation of a run result. */
export function explainResult(result: Pick<RunResult, "reason">): string {
  return REASON_MESSAGES[result.reason];
}
