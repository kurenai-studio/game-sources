import {
  CALL_OP,
  COUNTER_REF,
  DIRECTIONS,
  DIRECTION_DELTAS,
  IF_OP,
  INC_OP,
  LIMITS,
  MARK_OP,
  PROC_OP,
  RECURSION_MECHANIC,
  REPEAT_OP,
} from "./constants.js";
import { patrolMeeting } from "./patrol.js";
import { World, type Motion } from "./world.js";
import { topPlace, isActionNode, isNode, runnable, type Node } from "./program-shape.js";
import type {
  ActionName,
  Direction,
  Level,
  Position,
  PrimitiveInstruction,
  Program,
  RunResult,
  TraceEntry,
} from "./types.js";

/** Rotates a direction by 90 degrees. "left" is counterclockwise, "right" is clockwise. */
export function turn(direction: Direction, side: "left" | "right"): Direction {
  const i = DIRECTIONS.indexOf(direction);
  const next = (i + (side === "right" ? 1 : 3)) % 4;
  return DIRECTIONS[next] as Direction;
}

/** The cell one step ahead of `position` when facing `direction`. May lie outside the board. */
export function cellAhead(position: Position, direction: Direction): Position {
  const [dx, dy] = DIRECTION_DELTAS[direction];
  return [position[0] + dx, position[1] + dy];
}

export function isWall(level: Level, cell: Position): boolean {
  return level.board.walls.some((w) => w[0] === cell[0] && w[1] === cell[1]);
}

export function isInsideBoard(level: Level, cell: Position): boolean {
  return (
    cell[0] >= 0 && cell[1] >= 0 && cell[0] < level.board.width && cell[1] < level.board.height
  );
}

/**
 * Runs `program` on `level`. Deterministic and pure: the inputs are not modified.
 *
 * It expects a level that passed `validateLevel` and does not check `availableCommands`, `requires` or
 * `maxCommands`; call `validateProgram` first. An instruction that is not a known action or a well-formed
 * loop, IF, CALL or PROC stops the run with INVALID_INSTRUCTION (it is never skipped). `program` must be an
 * array. It runs the level's own board only; `simulateAll` runs every board.
 *
 * Every executed action (a move, a turn, INC or MARK) is one step; a loop, IF, CALL or PROC itself costs
 * none, and choosing an IF's branch is free (the sensor is read when the IF is reached). A REPEAT_UNTIL
 * checks its condition before every round, so a loop whose way ahead is already blocked runs its body zero
 * times; the check is free and the loop ends only through the condition, the goal, a failure, or the step
 * limit. A round of a REPEAT_UNTIL that runs no action at all (every IF chose an empty branch) would repeat
 * for ever, so it stops the run with STEP_LIMIT. A REPEAT with count "N" reads the counter when it starts.
 *
 * Two things are tracked while a run goes on. The counter N starts at 1 and INC adds one (up to 11). MARK
 * drops a breadcrumb on the cell the automaton stands on: an arrow to the cell behind it, kept if the cell
 * already has one. The marker sensors read the breadcrumbs.
 *
 * A PROC node is a definition: where it stands it is skipped (it costs nothing and does not run). The main
 * program is the other top-level nodes in order, and a CALL runs the body of the first PROC of that name.
 * The step limit is checked before each top-level node that is run and before each action. The run
 * succeeds the moment the goal is met: the target cell is entered, or (goal `visit_all`) the last floor cell
 * is entered for the first time.
 */
export function simulate(level: Level, program: Program): RunResult {
  if (!Array.isArray(program)) throw new TypeError("program must be an array");

  const world = new World(level);
  const trace: TraceEntry[] = [];
  let counter: number = LIMITS.counter.start;
  // How many procedure calls are running inside each other.
  let depth = 0;
  const cellKey = (cell: Position): number => cell[1] * level.board.width + cell[0];
  // Breadcrumbs: for a cell that has one, the direction (an index into DIRECTIONS) of the cell it points to.
  const crumbs = new Map<number, number>();
  // A level with ice or belts shows each step's route in the trace.
  const routed =
    (level.ice ?? []).length + (level.belts ?? []).length + (level.teleports ?? []).length > 0;

  // The procedures a CALL can reach: the first well-formed definition of each name.
  const procs = new Map<string, Node>();
  const procIndex = new Map<string, number>();
  const top = topPlace(level.requires.mechanics.includes(RECURSION_MECHANIC));
  // Every name a definition gives, so that a CALL inside a definition can be checked.
  const noProcs = new Map<string, Node>();
  for (const node of program as unknown[]) {
    if (isNode(node) && node["op"] === PROC_OP && typeof node["name"] === "string") {
      if (!noProcs.has(node["name"])) noProcs.set(node["name"], node);
    }
  }
  program.forEach((node, i) => {
    const candidate: unknown = node;
    if (!isNode(candidate) || candidate["op"] !== PROC_OP) return;
    const name = candidate["name"];
    if (typeof name !== "string" || procs.has(name)) return;
    if (runnable(candidate, top, noProcs)) {
      procs.set(name, candidate);
      procIndex.set(name, i);
    }
  });

  const finish = (
    status: RunResult["status"],
    reason: RunResult["reason"],
    blockedCell: Position | null,
  ): RunResult => ({
    status,
    reason,
    steps: trace.length,
    finalState: { position: [world.position[0], world.position[1]], direction: world.direction },
    blockedCell,
    trace,
  });

  const atLimit = (): boolean => trace.length >= level.constraints.maxSteps;

  /** Runs one action. Returns the final result when the run ends here, otherwise null. */
  const step = (
    command: ActionName,
    node: number[],
    round: number | null,
    call: number[] | null,
  ): RunResult | null => {
    if (atLimit()) return finish("FAILED", "STEP_LIMIT", null);
    const index = trace.length;
    const from: Position = world.position;
    const entry = (event: TraceEntry["event"], path: Position[] = []): TraceEntry => ({
      index,
      op: command,
      node,
      call,
      counter,
      round,
      position: [world.position[0], world.position[1]],
      direction: world.direction,
      event,
      ...(routed ? { path: path.map((cell): Position => [cell[0], cell[1]]) } : {}),
    });

    let motion: Motion = { path: [], event: null, goal: "none" };
    let base: TraceEntry["event"] = "MOVED";
    if (command === "TURN_LEFT" || command === "TURN_RIGHT") {
      world.direction = turn(world.direction, command === "TURN_LEFT" ? "left" : "right");
      base = "TURNED";
    } else if (command === INC_OP) {
      counter = Math.min(counter + 1, LIMITS.counter.max);
      base = "COUNTED";
    } else if (command === MARK_OP) {
      const here = cellKey(world.position);
      if (!crumbs.has(here)) crumbs.set(here, (DIRECTIONS.indexOf(world.direction) + 2) % 4);
      base = "MARKED";
    } else {
      const blocked = world.blockedAhead();
      if (blocked) {
        trace.push(entry(blocked.event));
        return finish("FAILED", blocked.event, blocked.cell);
      }
      motion = world.move();
    }
    if (command !== "MOVE_FORWARD") motion = world.carry();

    // A patrol that reaches the automaton in this step ends the run (checked before the goal).
    const meeting = patrolMeeting(level, from, world.position, index);
    if (meeting) {
      trace.push(entry("HIT_BY_PATROL", motion.path));
      return finish("FAILED", "HIT_BY_PATROL", meeting);
    }
    if (motion.goal === "undelivered") {
      trace.push(entry("UNDELIVERED", motion.path));
      return finish("FAILED", "UNDELIVERED", null);
    }
    if (motion.goal === "reached") {
      trace.push(entry("GOAL_REACHED", motion.path));
      return finish("SUCCEEDED", "GOAL_REACHED", null);
    }
    const slid = motion.path.length > (command === "MOVE_FORWARD" ? 1 : 0);
    trace.push(
      entry(
        motion.event ?? (slid ? (command === "MOVE_FORWARD" ? "SLID" : "CARRIED") : base),
        motion.path,
      ),
    );
    return null;
  };

  /** True when the sensor reads true: the cell on that side is floor (CLEAR), has no breadcrumb (FRESH), or is the cell this cell's breadcrumb points to (BACK). */
  const sensor = (name: string): boolean => {
    const [kind, side] = name.split("_") as [string, string];
    const { position, direction } = world;
    const facing =
      side === "AHEAD" ? direction : turn(direction, side === "LEFT" ? "left" : "right");
    const cell = cellAhead(position, facing);
    if (!world.canEnter(cell)) return false;
    if (kind === "CLEAR") return true;
    if (kind === "FRESH") return !crumbs.has(cellKey(cell));
    const toward = crumbs.get(cellKey(position));
    if (toward === undefined) return false;
    const [dx, dy] = DIRECTION_DELTAS[DIRECTIONS[toward]!];
    return cell[0] === position[0] + dx && cell[1] === position[1] + dy;
  };

  /** Runs an IF: its `then` actions, or its `else` (actions, or the next IF of an else-if chain). */
  const runIf = (
    node: Node,
    path: number[],
    round: number | null,
    call: number[] | null,
  ): RunResult | null => {
    const then = node["then"] as PrimitiveInstruction[];
    const other = node["else"] as Node[];
    const actions = (list: PrimitiveInstruction[], offset: number): RunResult | null => {
      for (let k = 0; k < list.length; k += 1) {
        const result = step(list[k]!.op, [...path, offset + k], round, call);
        if (result) return result;
      }
      return null;
    };
    if (sensor(node["when"] as string)) return actions(then, 0);
    if (other.length === 1 && other[0]!["op"] === IF_OP) {
      return runIf(other[0]!, [...path, then.length], round, call);
    }
    return actions(other as unknown as PrimitiveInstruction[], then.length);
  };

  /**
   * Runs one checked node at `path`. `round` is the round of the loop it stands in and `call` the CALL that
   * is running it. Returns the final result when the run ends here, otherwise null.
   */
  const run = (
    node: Node,
    path: number[],
    round: number | null,
    call: number[] | null,
  ): RunResult | null => {
    const op = node["op"];
    if (isActionNode(node)) return step(node.op, path, round, call);
    if (op === IF_OP) return runIf(node, path, round, call);

    if (op === CALL_OP) {
      if (node["when"] !== undefined && !sensor(node["when"] as string)) return null;
      const name = node["name"] as string;
      if (!procs.has(name)) return finish("FAILED", "INVALID_INSTRUCTION", null);
      depth += 1;
      if (depth > LIMITS.callDepth) return finish("FAILED", "TOO_DEEP", null);
      const body = procs.get(name)!["body"] as Node[];
      const base = [procIndex.get(name)!];
      for (let j = 0; j < body.length; j += 1) {
        const result = run(body[j]!, [...base, j], null, path);
        if (result) return result;
      }
      depth -= 1;
      return null;
    }

    const body = node["body"] as Node[];
    if (op === REPEAT_OP) {
      const rounds = node["count"] === COUNTER_REF ? counter : (node["count"] as number);
      for (let r = 1; r <= rounds; r += 1) {
        for (let j = 0; j < body.length; j += 1) {
          const result = run(body[j]!, [...path, j], r, call);
          if (result) return result;
        }
      }
      return null;
    }

    // REPEAT_UNTIL
    for (let r = 1; ; r += 1) {
      if (node["until"] === "BLOCKED" && !sensor("CLEAR_AHEAD")) return null;
      const before = trace.length;
      for (let j = 0; j < body.length; j += 1) {
        const result = run(body[j]!, [...path, j], r, call);
        if (result) return result;
      }
      if (trace.length === before) return finish("FAILED", "STEP_LIMIT", null);
    }
  };

  for (let i = 0; i < program.length; i += 1) {
    const node: unknown = program[i];
    if (isNode(node) && node["op"] === PROC_OP) {
      // A definition: skipped when it is well formed, a content error when it is not.
      if (!runnable(node, top, noProcs)) return finish("FAILED", "INVALID_INSTRUCTION", null);
      continue;
    }
    if (atLimit()) return finish("FAILED", "STEP_LIMIT", null);
    if (!runnable(node, top, procs)) return finish("FAILED", "INVALID_INSTRUCTION", null);
    const result = run(node as Node, [i], null, null);
    if (result) return result;
  }

  return finish("FAILED", "PROGRAM_ENDED", null);
}
