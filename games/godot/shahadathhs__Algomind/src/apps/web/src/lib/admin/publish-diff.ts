import type { Instruction, LevelContent } from "./admin-api";
import { boardCaseOf, boardCount } from "./board-model";
import { slotsOf } from "./level-model";
import { goalText } from "./goal-model";
import { countKinds } from "./program-model";

export type Change = { field: string; from: string; to: string };

type Version = { content: LevelContent; referenceSolution: Instruction[] };

const plural = (n: number, word: string) => `${n} ${word}${n === 1 ? "" : "s"}`;

/** The reference solution in a few words: its slots, and how many loops, ifs, procedures and calls. */
function solutionText(program: Instruction[]): string {
  const { counted, until, ifs, elseIfs, procs, calls, nested, incs, marks, byN } =
    countKinds(program);
  const slots = plural(slotsOf(program), "slot");
  const parts = [
    counted > 0 ? plural(counted, "loop") : "",
    until > 0 ? plural(until, "until-loop") : "",
    nested > 0 ? plural(nested, "nested loop") : "",
    byN > 0 ? plural(byN, "loop counted by N") : "",
    ifs > 0 ? plural(ifs, "if") : "",
    elseIfs > 0 ? plural(elseIfs, "else-if") : "",
    incs > 0 ? plural(incs, "counter step") : "",
    marks > 0 ? plural(marks, "breadcrumb mark") : "",
    procs > 0 ? plural(procs, "procedure") : "",
    calls > 0 ? plural(calls, "call") : "",
  ].filter(Boolean);
  return parts.length === 0 ? `${slots}, no loops` : `${slots}, ${parts.join(", ")}`;
}

/** One board in a few words: size, walls, start and goal. */
function boardText(content: LevelContent, index: number): string {
  const { board, initialState, goal } = boardCaseOf(content, index);
  return `${board.width} by ${board.height}, ${plural(board.walls.length, "wall")}, start ${initialState.position.join(", ")} facing ${initialState.direction}, goal ${goalText(goal)}`;
}

function describe(version: Version | null): Record<string, string> {
  if (!version) return {};
  const { content, referenceSolution } = version;
  return {
    Title: content.title,
    Description: content.description || "None",
    Difficulty: content.difficulty,
    "Board size": `${content.board.width} by ${content.board.height}`,
    Walls: String(content.board.walls.length),
    Start: `${content.initialState.position.join(", ")} facing ${content.initialState.direction}`,
    Goal: goalText(content.goal),
    Boards: plural(boardCount(content), "board"),
    ...Object.fromEntries(
      Array.from({ length: boardCount(content) - 1 }, (_, i) => [
        `Board ${i + 2}`,
        boardText(content, i + 1),
      ]),
    ),
    Commands: content.availableCommands.join(", "),
    "Max commands": String(content.constraints.maxCommands),
    "Max steps": String(content.constraints.maxSteps),
    Hints: content.hints.length ? content.hints.join(" / ") : "None",
    Solution: solutionText(referenceSolution),
  };
}

/** The field-by-field differences between the live version and the draft. */
export function diff(live: Version | null, draft: Version): Change[] {
  const before = describe(live);
  const after = describe(draft);
  const changes: Change[] = [];
  for (const field of Object.keys(after)) {
    const from = before[field] ?? "Not published";
    const to = after[field]!;
    if (from !== to) changes.push({ field, from, to });
  }
  return changes;
}
