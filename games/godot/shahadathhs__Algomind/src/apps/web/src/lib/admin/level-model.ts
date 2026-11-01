import {
  programSlots,
  simulate,
  simulateAll,
  validateAuthoringLevel,
  solve,
  type AuthoringLevel,
  type CommandName,
  type Level,
  type Program,
  type MultiRunResult,
  type RunResult,
} from "@algomind/level-contract";
import { type BoardData, type Command, type Dir, tilesOf } from "@/lib/board";
import type { Instruction, LevelContent } from "./admin-api";
import { usesSweep } from "./goal-model";

export const BOARD_MIN = 3;
export const BOARD_MAX = 12;
export const MAX_COMMANDS = { min: 1, max: 64 } as const;
export const MAX_STEPS = { min: 1, max: 1000 } as const;

export const COMMANDS: {
  op: CommandName;
  command: Command;
  label: string;
  /** One line under the checkbox in the limits panel. */
  note?: string;
}[] = [
  { op: "MOVE_FORWARD", command: "move", label: "Move forward" },
  { op: "TURN_LEFT", command: "left", label: "Turn left" },
  { op: "TURN_RIGHT", command: "right", label: "Turn right" },
  {
    op: "INC",
    command: "inc",
    label: "Count up",
    note: "Adds one to the counter N (starts at 1, stops at 11). A repeat can count with N.",
  },
  {
    op: "MARK",
    command: "mark",
    label: "Mark",
    note: "Drops a breadcrumb, an arrow to the cell behind. Adds the fresh and back sensors.",
  },
  { op: "REPEAT", command: "repeat", label: "Repeat" },
  { op: "REPEAT_UNTIL", command: "until", label: "Repeat until" },
  { op: "IF", command: "if", label: "If" },
  { op: "PROC", command: "proc", label: "Procedures (define and call)" },
];

/** The most instructions a loop body holds and the range of its count (the contract's limits). */
export const REPEAT_LIMITS = { count: { min: 2, max: 11 }, body: { max: 8 } } as const;

/** The mechanic that lets a loop hold one loop (a level lists it in requires.mechanics). */
export const NESTED_LOOPS = "nested_loops";

/** The mechanic that lets a procedure call procedures and a CALL carry a sensor. */
export const RECURSION = "recursion";

/** The longest else-if chain (the first IF and each IF in an else). */
export const IF_CHAIN_MAX = 6;

/** The most items a procedure body holds (the contract's limit). */
export const PROC_LIMITS = { body: { max: 8 } } as const;

/** The loop instructions: they carry a body and cost 1 slot plus the body. */
export const LOOP_OPS: readonly string[] = ["REPEAT", "REPEAT_UNTIL"];

export function isLoop(node: { op: string }): boolean {
  return LOOP_OPS.includes(node.op);
}

export function isIf(node: { op: string }): boolean {
  return node.op === "IF";
}

export function isProc(node: { op: string }): boolean {
  return node.op === "PROC";
}

export function isCall(node: { op: string }): boolean {
  return node.op === "CALL";
}

/** The one-step actions a level offers (moves, turns, INC, MARK), for the add buttons. */
export function primitivesOf(available: readonly string[]): typeof COMMANDS {
  return COMMANDS.filter((c) => !isLoop(c) && !isIf(c) && !isProc(c) && available.includes(c.op));
}

/** True when the level offers INC (the counter N, and loops that count with it). */
export function offersCounter(content: { availableCommands: string[] }): boolean {
  return content.availableCommands.includes("INC");
}

/** True when the level offers MARK (breadcrumbs and the fresh and back sensors). */
export function offersMarks(content: { availableCommands: string[] }): boolean {
  return content.availableCommands.includes("MARK");
}

/** True when the level lets a loop hold one loop. */
export function offersNestedLoops(content: { requires: { mechanics: string[] } }): boolean {
  return content.requires.mechanics.includes(NESTED_LOOPS);
}

/** True when the level lets a procedure call procedures, itself included. */
export function offersRecursion(content: { requires: { mechanics: string[] } }): boolean {
  return content.requires.mechanics.includes(RECURSION);
}

/** True when the level has any tile of the later worlds (guards, keys, crates, switches, ice, belts, teleporters). */
export function hasTiles(content: LevelContent): boolean {
  return TILE_FIELDS.some((field) => (content[field]?.length ?? 0) > 0);
}

export const TILE_FIELDS = [
  "patrols",
  "locks",
  "deliveries",
  "switches",
  "teleports",
  "ice",
  "belts",
] as const;

export const DIRECTIONS = ["north", "east", "south", "west"] as const;
export type Direction = (typeof DIRECTIONS)[number];

const DIR_LETTER: Record<Direction, Dir> = { north: "N", east: "E", south: "S", west: "W" };

export function commandOf(op: string): Command {
  if (op === "CALL") return "call";
  return COMMANDS.find((c) => c.op === op)?.command ?? "move";
}

/** The board renderer's data for a level definition, optionally with a run's trail. */
export function boardData(
  content: LevelContent,
  extra: {
    automaton?: { x: number; y: number; dir: Direction };
    trail?: [number, number][];
    hit?: [number, number];
    crumbs?: { x: number; y: number; dir: Direction }[];
  } = {},
): BoardData {
  const [sx, sy] = content.initialState.position;
  const at = extra.automaton ?? { x: sx, y: sy, dir: content.initialState.direction };
  return {
    width: content.board.width,
    height: content.board.height,
    walls: content.board.walls.map(([x, y]) => ({ x, y })),
    goal: content.goal.position && { x: content.goal.position[0], y: content.goal.position[1] },
    automaton: { x: at.x, y: at.y, dir: DIR_LETTER[at.dir] },
    ...tilesOf(content as unknown as Record<string, unknown>),
    trail: extra.trail?.map(([x, y]) => ({ x, y })),
    crumbs: extra.crumbs?.map((c) => ({ x: c.x, y: c.y, dir: DIR_LETTER[c.dir] })),
    hitWall: extra.hit ? { x: extra.hit[0], y: extra.hit[1] } : undefined,
  };
}

/** True when the level lets players use IF. */
export function offersIf(content: { availableCommands: string[] }): boolean {
  return content.availableCommands.includes("IF");
}

/** True when the level lets players use PROC and CALL. */
export function offersProcedures(content: { availableCommands: string[] }): boolean {
  return content.availableCommands.includes("PROC");
}

/**
 * True when the exact solver cannot give par, so the reference solution is par: IF, PROC, INC or
 * MARK offered, nested loops allowed, test boards, or a sweep goal on any board.
 */
export function parIsReferenceFor(content: LevelContent): boolean {
  return (
    offersIf(content) ||
    offersProcedures(content) ||
    offersCounter(content) ||
    offersMarks(content) ||
    offersNestedLoops(content) ||
    offersRecursion(content) ||
    // The exact search moves through the tiles but not through loops.
    (hasTiles(content) &&
      (content.availableCommands.includes("REPEAT") ||
        content.availableCommands.includes("REPEAT_UNTIL"))) ||
    (content.extraBoards?.length ?? 0) > 0 ||
    usesSweep(content)
  );
}

/** What the browser can tell an author before the server is asked (the server stays the authority). */
export function localCheck(content: LevelContent, referenceSolution: Instruction[]) {
  const authoring = { ...content, referenceSolution } as unknown as AuthoringLevel;
  const validation = validateAuthoringLevel(authoring);
  if (!validation.ok)
    return {
      validation,
      solved: null,
      run: null as MultiRunResult | null,
      par: null as null | { commands: number; steps: number },
      parIsReference: false,
    };
  const level = content as unknown as Level;
  const run = simulateAll(level, referenceSolution as Program);
  const solved = run.status === "SUCCEEDED";
  // The exact solver ignores IF, PROC and test boards, so such a level has its reference solution as par (total steps).
  const referencePar = parIsReferenceFor(content)
    ? { commands: slotsOf(referenceSolution), steps: run.steps }
    : null;
  const best = referencePar ? null : solve(level);
  return {
    validation,
    solved,
    run: run as MultiRunResult | null,
    par: referencePar ?? (best ? { commands: best.commands, steps: best.steps } : null),
    parIsReference: referencePar !== null,
  };
}

export { explainResult } from "@algomind/level-contract";
export type { MultiRunResult, RunResult };
export { programSlots, simulate, simulateAll };

/** The slots a program uses (a loop is 1 plus its body), the number the command limit counts. */
export function slotsOf(program: Instruction[]): number {
  return programSlots(program as Program);
}

/** The unsaved-edit backup. It holds level content only, never tokens or credentials. */
export type DraftBackup = {
  savedAt: number;
  baseUpdatedAt: string;
  content: LevelContent;
  referenceSolution: Instruction[];
};

const BACKUP_PREFIX = "algomind-admin-draft:";

export function readBackup(levelId: string): DraftBackup | null {
  try {
    const raw = window.localStorage.getItem(BACKUP_PREFIX + levelId);
    return raw ? (JSON.parse(raw) as DraftBackup) : null;
  } catch {
    return null;
  }
}

export function writeBackup(levelId: string, backup: DraftBackup): void {
  try {
    window.localStorage.setItem(BACKUP_PREFIX + levelId, JSON.stringify(backup));
  } catch {
    // Storage may be blocked; saving to the server is the real path.
  }
}

export function clearBackup(levelId: string): void {
  try {
    window.localStorage.removeItem(BACKUP_PREFIX + levelId);
  } catch {
    // Nothing to clear.
  }
}

/** What "par" means for this level: the fewest slots, or the reference solution's when IF, PROC, INC, MARK, nested loops, a sweep goal or test boards are used. */
export function parName(content: LevelContent): string {
  return parIsReferenceFor(content) ? "Reference solution" : "Par";
}
