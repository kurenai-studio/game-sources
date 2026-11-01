import { DIRECTIONS, PRIMITIVE_COMMANDS, REPEAT_OP, REPEAT_UNTIL_OP } from "./constants.js";
import { patrolMeeting } from "./patrol.js";
import { cellAhead, isInsideBoard, isWall, turn } from "./simulate.js";
import type { Direction, Level, Position, PrimitiveName, Program, SolveResult } from "./types.js";
import { solveWithRepeat } from "./solve-repeat.js";
import { World } from "./world.js";

interface Node {
  x: number;
  y: number;
  dir: number; // index into DIRECTIONS
  parent: number; // index into the node list, -1 for the start
  op: PrimitiveName | null; // the command that produced this node
}

/**
 * Finds the shortest program (par) for the level, or null when the goal cannot be reached.
 *
 * Breadth-first search over states (x, y, facing). Tie-breaking, so any language can reproduce the exact
 * program and not only its length:
 *  1. The queue is FIFO and starts with the initial state.
 *  2. A state taken from the queue is expanded by trying the commands in the fixed order
 *     MOVE_FORWARD, TURN_LEFT, TURN_RIGHT, skipping commands not in `availableCommands`.
 *  3. A state is recorded the first time it is discovered; later discoveries are ignored.
 *  4. MOVE_FORWARD produces no state when the target is off the board or a wall.
 *  5. The search stops at the first discovered state whose cell is the goal; the program is the path to it.
 *
 * `fitsConstraints` reports whether that program obeys `maxCommands` and `maxSteps`; the search itself
 * ignores both. Expects a level that passed `validateLevel`.
 */
export function solve(level: Level): SolveResult | null {
  // Only a target can be searched for; the sweep goal (visit_all) has no exact par.
  if (level.goal.type !== "reach_tile") return null;
  // Patrols make the state depend on the step number, so the search is over (x, y, facing, step).
  // Keys add the keys held to the state, so the same layered search serves them.
  if (hasExtras(level)) return solveWorld(level);
  if (
    level.availableCommands.includes(REPEAT_OP) ||
    level.availableCommands.includes(REPEAT_UNTIL_OP)
  ) {
    return solveWithRepeat(level);
  }
  const available = PRIMITIVE_COMMANDS.filter((c) => level.availableCommands.includes(c));
  const goal = level.goal.position;
  const { width, height } = level.board;
  const startDir = DIRECTIONS.indexOf(level.initialState.direction);

  const nodes: Node[] = [
    {
      x: level.initialState.position[0],
      y: level.initialState.position[1],
      dir: startDir,
      parent: -1,
      op: null,
    },
  ];
  const seen = new Set<number>([key(nodes[0]!.x, nodes[0]!.y, startDir, width, height)]);

  const finish = (last: number): SolveResult => {
    const ops: PrimitiveName[] = [];
    for (let i = last; i > 0; i = nodes[i]!.parent) ops.push(nodes[i]!.op as PrimitiveName);
    ops.reverse();
    const program: Program = ops.map((op) => ({ op }));
    return {
      commands: program.length,
      steps: program.length,
      program,
      fitsConstraints:
        program.length <= level.constraints.maxCommands &&
        program.length <= level.constraints.maxSteps,
    };
  };

  if (nodes[0]!.x === goal[0] && nodes[0]!.y === goal[1]) return finish(0);

  for (let head = 0; head < nodes.length; head += 1) {
    const cur = nodes[head]!;
    for (const op of available) {
      let x = cur.x;
      let y = cur.y;
      let dir = cur.dir;
      if (op === "MOVE_FORWARD") {
        const target: Position = cellAhead([x, y], DIRECTIONS[dir] as Direction);
        if (!isInsideBoard(level, target) || isWall(level, target)) continue;
        x = target[0];
        y = target[1];
      } else {
        dir = DIRECTIONS.indexOf(
          turn(DIRECTIONS[dir] as Direction, op === "TURN_LEFT" ? "left" : "right"),
        );
      }
      const k = key(x, y, dir, width, height);
      if (seen.has(k)) continue;
      seen.add(k);
      nodes.push({ x, y, dir, parent: head, op });
      if (x === goal[0] && y === goal[1]) return finish(nodes.length - 1);
    }
  }
  return null;
}

const hasPatrols = (level: Level): boolean => (level.patrols ?? []).length > 0;
const hasExtras = (level: Level): boolean =>
  [
    level.patrols,
    level.locks,
    level.deliveries,
    level.switches,
    level.ice,
    level.belts,
    level.teleports,
  ].some((list) => (list ?? []).length > 0);

/**
 * The shortest flat program for a level with patrols, keys, crates, switches, ice or belts: breadth first
 * over the states of the run (see `World.key`), layer by layer, one layer per step, because where a patrol
 * stands depends on the step. A command that would end in a collision with a patrol (see `patrolMeeting`),
 * or in a failure of the world (a blocked move, the target entered with a crate left), is not tried; the
 * goal is tested after that, as in the simulator. With patrols a state is kept once per layer, without them
 * once for the whole search. Loops are not searched: with REPEAT on offer the API takes the better of this
 * and the reference solution. The same tie-breaking as `solve`: commands in the order MOVE_FORWARD,
 * TURN_LEFT, TURN_RIGHT, a state kept the first time it is found.
 */
function solveWorld(level: Level): SolveResult | null {
  if (level.goal.type !== "reach_tile") return null;
  const available = PRIMITIVE_COMMANDS.filter((c) => level.availableCommands.includes(c));
  const patrolled = hasPatrols(level);
  const nodes: { world: World; parent: number; op: PrimitiveName | null }[] = [
    { world: new World(level), parent: -1, op: null },
  ];
  const finish = (last: number): SolveResult => {
    const ops: PrimitiveName[] = [];
    for (let i = last; i > 0; i = nodes[i]!.parent) ops.push(nodes[i]!.op as PrimitiveName);
    ops.reverse();
    const program: Program = ops.map((op) => ({ op }));
    return {
      commands: program.length,
      steps: program.length,
      program,
      fitsConstraints:
        program.length <= level.constraints.maxCommands &&
        program.length <= level.constraints.maxSteps,
    };
  };

  const everSeen = new Set<string>([nodes[0]!.world.key()]);
  let layer = [0];
  for (let depth = 0; depth < level.constraints.maxSteps && layer.length > 0; depth += 1) {
    const next: number[] = [];
    const seen = patrolled ? new Set<string>() : everSeen;
    for (const head of layer) {
      const cur = nodes[head]!.world;
      for (const op of available) {
        const world = cur.clone();
        const from = world.position;
        let goal: "none" | "reached" | "undelivered" = "none";
        if (op === "MOVE_FORWARD") {
          if (world.blockedAhead()) continue;
          goal = world.move().goal;
        } else {
          world.direction = turn(world.direction, op === "TURN_LEFT" ? "left" : "right");
          goal = world.carry().goal;
        }
        if (patrolMeeting(level, from, world.position, depth)) continue;
        if (goal === "undelivered") continue;
        if (goal === "reached") {
          nodes.push({ world, parent: head, op });
          return finish(nodes.length - 1);
        }
        const k = world.key();
        if (seen.has(k)) continue;
        seen.add(k);
        nodes.push({ world, parent: head, op });
        next.push(nodes.length - 1);
      }
    }
    layer = next;
  }
  return null;
}

function key(x: number, y: number, dir: number, width: number, height: number): number {
  return (dir * height + y) * width + x;
}
