import {
  simulate,
  solve,
  type Level,
  type Position,
  type TraceEntry,
} from "@algomind/level-contract";
import type { BoardData, Dir } from "@/lib/board";
import { LANDING_LEVEL } from "@/lib/landing-level";

/**
 * Frames of one real level for the landing page drawings. The level is a copy of the seed's
 * "Around the wall" (landing-level.ts, kept honest by an API test), and every frame is computed
 * from it with the contract's solver and simulator, so the board, the program, the counts and the
 * trail are what the game shows for that level.
 */
const level = LANDING_LEVEL.level as unknown as Level;

const COMMAND_OF: Record<string, Primitive> = {
  MOVE_FORWARD: "move",
  TURN_LEFT: "left",
  TURN_RIGHT: "right",
};
const OP_OF = { move: "MOVE_FORWARD", left: "TURN_LEFT", right: "TURN_RIGHT" } as const;
/** The commands a drawn program uses (no loops in the landing frames). */
type Primitive = keyof typeof OP_OF;
const DIR_OF: Record<string, Dir> = { north: "N", east: "E", south: "S", west: "W" };

export const LEVEL_TITLE = level.title.toUpperCase();
export const LEVEL_NUMBER = String(LANDING_LEVEL.number).padStart(2, "0");
export const COMMAND_BUDGET = level.constraints.maxCommands;

const best = solve(level);
if (!best) throw new Error("The landing level has no solution");

/** The shortest program for the level, as tape commands. */
export const SOLUTION: readonly Primitive[] = best.program.map((node) => {
  const command = COMMAND_OF[node.op];
  if (!command) throw new Error(`The landing level's solution uses ${node.op}`);
  return command;
});
export const PAR = best.commands;

/** A different program that runs into a wall: Move, Left, Move, Right, Move. */
export const FAILED_PROGRAM: readonly Primitive[] = ["move", "left", "move", "right", "move"];

const program = (commands: readonly Primitive[]) =>
  commands.map((command) => ({ op: OP_OF[command] }));

const solved = simulate(level, program(SOLUTION));
const failed = simulate(level, program(FAILED_PROGRAM));
if (solved.status !== "SUCCEEDED") throw new Error("The landing solution does not solve the level");
if (failed.reason !== "BLOCKED_BY_WALL") {
  throw new Error("The landing failure program must run into a wall");
}

const cell = ([x, y]: Position) => ({ x, y });

/** The board before any step. */
export const READY_BOARD: BoardData = {
  width: level.board.width,
  height: level.board.height,
  walls: level.board.walls.map(cell),
  goal: level.goal.type === "reach_tile" ? cell(level.goal.position) : undefined,
  automaton: {
    ...cell(level.initialState.position),
    dir: DIR_OF[level.initialState.direction]!,
  },
};

/** The board after `steps` events of a run: where the automaton is and the cells it passed. */
function boardAfter(trace: TraceEntry[], steps: number, hit?: Position): BoardData {
  const last = trace[steps - 1]!;
  const here = last.position;
  const passed = [level.initialState.position, ...trace.slice(0, steps - 1).map((t) => t.position)];
  const trail: Position[] = [];
  for (const p of passed) {
    const known = trail.some((q) => q[0] === p[0] && q[1] === p[1]);
    if (!known && !(p[0] === here[0] && p[1] === here[1])) trail.push(p);
  }
  return {
    ...READY_BOARD,
    automaton: { ...cell(here), dir: DIR_OF[last.direction]! },
    trail: trail.map(cell),
    hitWall: hit ? cell(hit) : undefined,
  };
}

/** The instruction under the read-head in the running frame (zero-based): the fifth step. */
export const RUNNING_STEP = 4;
/** Instructions shown on the tape while building. */
export const READY_COUNT = 4;

export const RUNNING_BOARD = boardAfter(solved.trace, RUNNING_STEP + 1);
/** The board after each step of the solving run, in order (the last one reaches the target). */
export const RUN_BOARDS: BoardData[] = solved.trace.map((_, i) => boardAfter(solved.trace, i + 1));
export const FAILED_BOARD = boardAfter(failed.trace, failed.steps, failed.blockedCell ?? undefined);
export const SOLVED_BOARD = boardAfter(solved.trace, solved.steps);

/** The numbers the solved frame shows. */
export const SOLVED_STATS = {
  used: SOLUTION.length,
  limit: COMMAND_BUDGET,
  steps: solved.steps,
  best: PAR,
};
