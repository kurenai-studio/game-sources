import {
  DIRECTIONS,
  DIRECTION_DELTAS,
  LIMITS,
  PRIMITIVE_COMMANDS,
  REPEAT_OP,
  REPEAT_UNTIL_OP,
} from "./constants.js";
import type { Level, PrimitiveName, Program, SolveResult } from "./types.js";

/**
 * The shortest program (par) for a level that offers REPEAT or REPEAT_UNTIL.
 *
 * Par counts slots: a primitive is 1, a REPEAT or REPEAT_UNTIL is 1 plus its body. The search is exact over programs whose
 * loop bodies hold at most `LIMITS.repeatBody.max` primitives, which is also the most a body may hold.
 *
 * Method (any language can reproduce the exact program, not only its size):
 *  1. A state is (x, y, facing). A "behaviour" maps every state to where a piece of program ends, how many
 *     steps it took, or that it failed, or that it entered the goal (the run stops there, successfully).
 *  2. Bodies are enumerated by length 1..8, in this order: length 1 is the available primitives in canonical
 *     order; length k+1 extends each body of length k, in order, by each available primitive in canonical
 *     order. A body whose behaviour equals that of an earlier one is skipped.
 *  3. The edges are every available primitive (cost 1 slot), then, by body length and body order, every
 *     REPEAT(n, body) for n from 2 to `LIMITS.repeatCount.max` when REPEAT is offered, and then the
 *     REPEAT_UNTIL(BLOCKED, body) of that body when REPEAT_UNTIL is offered (each costs 1 + body length).
 *     Edges with the same behaviour and cost as an earlier edge are skipped.
 *  4. A shortest-path search from the start state, with cost (slots, steps) compared in that order, taking
 *     the lowest state index first and updating only on a strictly lower cost. The first edge to reach the
 *     goal at the lowest cost wins, which makes the program unique.
 *
 * `fitsConstraints` reports whether that program obeys `maxCommands` and `maxSteps`; the search ignores both.
 */
export function solveWithRepeat(level: Level): SolveResult | null {
  if (level.goal.type !== "reach_tile") return null;
  const { width, height } = level.board;
  const size = width * height * 4;
  const FAIL = -1;
  const WIN = -2;
  const STEP_CAP = 60000;

  const walls = new Uint8Array(width * height);
  for (const [x, y] of level.board.walls) walls[y! * width + x!] = 1;
  const goalCell = level.goal.position[1] * width + level.goal.position[0];
  const available = PRIMITIVE_COMMANDS.filter((c) => level.availableCommands.includes(c));

  interface Behaviour {
    end: Int16Array;
    steps: Uint16Array;
  }

  const primitive = (command: PrimitiveName): Behaviour => {
    const end = new Int16Array(size);
    const steps = new Uint16Array(size);
    for (let s = 0; s < size; s += 1) {
      const dir = s & 3;
      const cell = s >> 2;
      const x = cell % width;
      const y = (cell - x) / width;
      steps[s] = 1;
      if (command === "MOVE_FORWARD") {
        const [dx, dy] = DIRECTION_DELTAS[DIRECTIONS[dir]!];
        const nx = x + dx;
        const ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= width || ny >= height || walls[ny * width + nx]) {
          end[s] = FAIL;
        } else {
          end[s] = ny * width + nx === goalCell ? WIN : (ny * width + nx) * 4 + dir;
        }
      } else {
        end[s] = cell * 4 + ((dir + (command === "TURN_LEFT" ? 3 : 1)) & 3);
      }
    }
    return { end, steps };
  };

  const then = (p: Behaviour, q: Behaviour): Behaviour => {
    const end = new Int16Array(size);
    const steps = new Uint16Array(size);
    for (let s = 0; s < size; s += 1) {
      const e = p.end[s]!;
      if (e < 0) {
        end[s] = e;
        steps[s] = p.steps[s]!;
        continue;
      }
      end[s] = q.end[e]!;
      steps[s] = Math.min(STEP_CAP, p.steps[s]! + q.steps[e]!);
    }
    return { end, steps };
  };

  const repeated = (body: Behaviour, count: number): Behaviour => {
    const end = new Int16Array(size);
    const steps = new Uint16Array(size);
    for (let s = 0; s < size; s += 1) {
      let at = s;
      let total = 0;
      for (let i = 0; i < count && at >= 0; i += 1) {
        total = Math.min(STEP_CAP, total + body.steps[at]!);
        at = body.end[at]!;
      }
      end[s] = at;
      steps[s] = total;
    }
    return { end, steps };
  };

  /** True where a wall or the board edge is straight ahead of the state. */
  const blockedAhead = new Uint8Array(size);
  for (let s = 0; s < size; s += 1) {
    const cell = s >> 2;
    const x = cell % width;
    const y = (cell - x) / width;
    const [dx, dy] = DIRECTION_DELTAS[DIRECTIONS[s & 3]!];
    const nx = x + dx;
    const ny = y + dy;
    blockedAhead[s] =
      nx < 0 || ny < 0 || nx >= width || ny >= height || walls[ny * width + nx]! ? 1 : 0;
  }

  /** Runs the body while the way ahead is open. A run that never gets blocked is a failure (step limit). */
  const repeatedUntilBlocked = (body: Behaviour): Behaviour => {
    const end = new Int16Array(size);
    const steps = new Uint16Array(size);
    for (let s = 0; s < size; s += 1) {
      let at = s;
      let total = 0;
      let rounds = 0;
      while (at >= 0 && !blockedAhead[at]) {
        if (rounds > size) {
          at = FAIL;
          break;
        }
        rounds += 1;
        total = Math.min(STEP_CAP, total + body.steps[at]!);
        at = body.end[at]!;
      }
      end[s] = at;
      steps[s] = total;
    }
    return { end, steps };
  };

  /** Skips behaviours already seen; a hash picks the bucket and the arrays are compared in full. */
  const unseen = (() => {
    const buckets = new Map<string, Behaviour[]>();
    return (b: Behaviour, salt: string): boolean => {
      let h1 = 2166136261;
      let h2 = 5381;
      for (let i = 0; i < size; i += 1) {
        const v = (b.end[i]! + 3) * 65537 + b.steps[i]!;
        h1 = Math.imul(h1 ^ v, 16777619);
        h2 = (Math.imul(h2, 33) + v) | 0;
      }
      const key = `${salt}:${h1}:${h2}`;
      const bucket = buckets.get(key) ?? [];
      for (const other of bucket) {
        let same = true;
        for (let i = 0; i < size && same; i += 1) {
          same = other.end[i] === b.end[i] && other.steps[i] === b.steps[i];
        }
        if (same) return false;
      }
      bucket.push(b);
      buckets.set(key, bucket);
      return true;
    };
  })();

  // Bodies by length, deduplicated across all lengths.
  interface Body {
    ops: PrimitiveName[];
    behaviour: Behaviour;
  }
  const atoms = available.map((op) => ({ op, behaviour: primitive(op) }));
  const bodies: Body[][] = [[]];
  for (let length = 1; length <= LIMITS.repeatBody.max; length += 1) {
    const level_: Body[] = [];
    if (length === 1) {
      for (const atom of atoms) {
        if (unseen(atom.behaviour, "body"))
          level_.push({ ops: [atom.op], behaviour: atom.behaviour });
      }
    } else {
      for (const body of bodies[length - 1]!) {
        for (const atom of atoms) {
          const behaviour = then(body.behaviour, atom.behaviour);
          if (unseen(behaviour, "body")) level_.push({ ops: [...body.ops, atom.op], behaviour });
        }
      }
    }
    bodies.push(level_);
  }

  // Edges: every primitive, then every loop.
  interface Edge {
    behaviour: Behaviour;
    slots: number;
    node: Program[number];
  }
  const edges: Edge[] = [];
  for (const atom of atoms) {
    if (unseen(atom.behaviour, "edge1")) {
      edges.push({ behaviour: atom.behaviour, slots: 1, node: { op: atom.op } });
    }
  }
  for (let length = 1; length <= LIMITS.repeatBody.max; length += 1) {
    for (const body of bodies[length]!) {
      if (level.availableCommands.includes(REPEAT_OP)) {
        for (let count = LIMITS.repeatCount.min; count <= LIMITS.repeatCount.max; count += 1) {
          const behaviour = repeated(body.behaviour, count);
          if (!unseen(behaviour, `edge${1 + length}`)) continue;
          edges.push({
            behaviour,
            slots: 1 + length,
            node: { op: REPEAT_OP, count, body: body.ops.map((op) => ({ op })) },
          });
        }
      }
      if (level.availableCommands.includes(REPEAT_UNTIL_OP)) {
        const behaviour = repeatedUntilBlocked(body.behaviour);
        if (!unseen(behaviour, `edge${1 + length}`)) continue;
        edges.push({
          behaviour,
          slots: 1 + length,
          node: { op: REPEAT_UNTIL_OP, until: "BLOCKED", body: body.ops.map((op) => ({ op })) },
        });
      }
    }
  }

  // Shortest path over states. Index `size` stands for "the goal".
  const startDir = DIRECTIONS.indexOf(level.initialState.direction);
  const start =
    (level.initialState.position[1] * width + level.initialState.position[0]) * 4 + startDir;
  const COST_STEPS = 1_000_000;
  const cost = new Float64Array(size + 1).fill(Infinity);
  const previous = new Int32Array(size + 1).fill(-1);
  const via = new Int32Array(size + 1).fill(-1);
  const done = new Uint8Array(size + 1);
  cost[start] = 0;
  for (;;) {
    let at = -1;
    for (let s = 0; s <= size; s += 1) {
      if (!done[s] && cost[s]! < Infinity && (at === -1 || cost[s]! < cost[at]!)) at = s;
    }
    if (at === -1 || at === size) break;
    done[at] = 1;
    for (let e = 0; e < edges.length; e += 1) {
      const edge = edges[e]!;
      const to = edge.behaviour.end[at]!;
      if (to === FAIL) continue;
      const next = cost[at]! + edge.slots * COST_STEPS + edge.behaviour.steps[at]!;
      const target = to === WIN ? size : to;
      if (next < cost[target]!) {
        cost[target] = next;
        previous[target] = at;
        via[target] = e;
      }
    }
  }
  if (cost[size] === Infinity) return null;

  const program: Program = [];
  for (let s = size; s !== start; s = previous[s]!) program.push(edges[via[s]!]!.node);
  program.reverse();
  const total = cost[size]!;
  const commands = Math.floor(total / COST_STEPS);
  const steps = total - commands * COST_STEPS;
  return {
    commands,
    steps,
    program,
    fitsConstraints:
      commands <= level.constraints.maxCommands && steps <= level.constraints.maxSteps,
  };
}
