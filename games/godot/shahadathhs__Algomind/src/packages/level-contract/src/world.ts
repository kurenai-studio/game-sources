import { DIRECTIONS, DIRECTION_DELTAS } from "./constants.js";
import type { Direction, Level, Position, TraceEvent } from "./types.js";

/** What one action did to the automaton: the cells it entered, what they did, and whether it ended the run. */
export interface Motion {
  /** The cells entered in this action, in order (not the cell it started on). */
  path: Position[];
  /** The effect of the last cell that had one (a key, a crate or dock, a switch), or null. */
  event: TraceEvent | null;
  /** "reached": the target was entered with nothing left to deliver; "undelivered": with something left. */
  goal: "none" | "reached" | "undelivered";
}

/** The parts of a level that never change during a run. */
interface Tables {
  level: Level;
  target: Position | null;
  floorCells: number;
  walls: Set<number>;
  ice: Set<number>;
  belts: Map<number, Direction>;
  /** For each teleporter end, the cell of the other end. */
  portals: Map<number, Position>;
  keyAt: Map<number, number>;
  doorAt: Map<number, number>;
  itemAt: Map<number, number>;
  dockAt: Map<number, number>;
  switchAt: Map<number, number>;
  gateAt: Map<number, number>;
}

function cellMap<T>(list: readonly T[] | undefined, width: number, cell: (t: T) => Position) {
  return new Map((list ?? []).map((t, i) => [cell(t)[1] * width + cell(t)[0], i] as const));
}

function tablesOf(level: Level): Tables {
  const { width, height } = level.board;
  const key = (c: Position): number => c[1] * width + c[0];
  const walls = new Set(level.board.walls.map(key));
  return {
    level,
    target: level.goal.type === "reach_tile" ? level.goal.position : null,
    floorCells: width * height - walls.size,
    walls,
    ice: new Set((level.ice ?? []).map(key)),
    belts: new Map((level.belts ?? []).map((b) => [key(b.cell), b.direction] as const)),
    portals: new Map(
      (level.teleports ?? []).flatMap((t) => [[key(t.a), t.b] as const, [key(t.b), t.a] as const]),
    ),
    keyAt: cellMap(level.locks, width, (l) => l.key),
    doorAt: cellMap(level.locks, width, (l) => l.door),
    itemAt: cellMap(level.deliveries, width, (d) => d.item),
    dockAt: cellMap(level.deliveries, width, (d) => d.dock),
    switchAt: cellMap(level.switches, width, (s) => s.switch),
    gateAt: cellMap(level.switches, width, (s) => s.gate),
  };
}

/**
 * The board and the automaton during a run: where it stands and what it has done to the board (keys held,
 * the item carried, items delivered, switches flipped, cells visited). The simulator and the solver both
 * move the automaton through this class, so a rule lives in one place. The step count, the counter and the
 * breadcrumbs are not part of it, and neither are patrols (which depend on the step).
 */
export class World {
  position: Position;
  direction: Direction;
  held = new Set<number>();
  /** The index of the item being carried, or -1. */
  carrying = -1;
  delivered = new Set<number>();
  /** The switches entered an odd number of times. */
  flipped = new Set<number>();
  visited = new Set<number>();
  private readonly t: Tables;

  constructor(level: Level, from?: World) {
    if (from) {
      this.t = from.t;
      this.position = from.position;
      this.direction = from.direction;
      this.held = new Set(from.held);
      this.carrying = from.carrying;
      this.delivered = new Set(from.delivered);
      this.flipped = new Set(from.flipped);
      this.visited = new Set(from.visited);
      return;
    }
    this.t = tablesOf(level);
    this.position = [level.initialState.position[0], level.initialState.position[1]];
    this.direction = level.initialState.direction;
    this.visited.add(this.key1(this.position));
  }

  clone(): World {
    return new World(this.t.level, this);
  }

  private key1(cell: Position): number {
    return cell[1] * this.t.level.board.width + cell[0];
  }

  private onBoard(cell: Position): boolean {
    const { width, height } = this.t.level.board;
    return cell[0] >= 0 && cell[1] >= 0 && cell[0] < width && cell[1] < height;
  }

  private isShutDoor(cell: Position): boolean {
    const lock = this.t.doorAt.get(this.key1(cell));
    return lock !== undefined && !this.held.has(lock);
  }

  private isShutGate(cell: Position): boolean {
    const pair = this.t.gateAt.get(this.key1(cell));
    return (
      pair !== undefined && (this.t.level.switches![pair]!.open === true) === this.flipped.has(pair)
    );
  }

  /** True when the automaton can step onto the cell: on the board, no wall, no shut door or gate. */
  canEnter(cell: Position): boolean {
    return (
      this.onBoard(cell) &&
      !this.t.walls.has(this.key1(cell)) &&
      !this.isShutDoor(cell) &&
      !this.isShutGate(cell)
    );
  }

  /** Why a move ahead fails (the reason doubles as the trace event) and the cell in the way, or null. */
  blockedAhead(): {
    event: "BLOCKED_BY_BOUNDARY" | "BLOCKED_BY_WALL" | "BLOCKED_BY_DOOR" | "BLOCKED_BY_GATE";
    cell: Position;
  } | null {
    const cell = this.ahead(this.position);
    if (!this.onBoard(cell)) return { event: "BLOCKED_BY_BOUNDARY", cell };
    if (this.t.walls.has(this.key1(cell))) return { event: "BLOCKED_BY_WALL", cell };
    if (this.isShutDoor(cell)) return { event: "BLOCKED_BY_DOOR", cell };
    if (this.isShutGate(cell)) return { event: "BLOCKED_BY_GATE", cell };
    return null;
  }

  private ahead(cell: Position): Position {
    const [dx, dy] = DIRECTION_DELTAS[this.direction];
    return [cell[0] + dx, cell[1] + dy];
  }

  /**
   * Moves one cell ahead (the way must not be blocked). On ice the automaton goes on sliding while the next
   * cell is enterable; it stops on a cell that is not ice. Then a belt under it carries it one cell. The
   * move ends the moment the target is entered.
   */
  move(): Motion {
    const motion: Motion = { path: [], event: null, goal: "none" };
    for (;;) {
      const next = this.ahead(this.position);
      if (this.enter(next, motion)) return motion;
      if (motion.event === "TELEPORTED") break;
      if (!this.t.ice.has(this.key1(next)) || !this.canEnter(this.ahead(next))) break;
    }
    this.carryInto(motion);
    return motion;
  }

  /** After an action that does not move the automaton: a belt under it carries it one cell. */
  carry(): Motion {
    const motion: Motion = { path: [], event: null, goal: "none" };
    this.carryInto(motion);
    return motion;
  }

  private carryInto(motion: Motion): void {
    const belt = this.t.belts.get(this.key1(this.position));
    if (belt === undefined) return;
    const [dx, dy] = DIRECTION_DELTAS[belt];
    const next: Position = [this.position[0] + dx, this.position[1] + dy];
    if (this.canEnter(next)) this.enter(next, motion);
  }

  /** Enters a cell and applies what lies there. Returns true when the target ended the move. */
  private enter(cell: Position, motion: Motion): boolean {
    const t = this.t;
    const at = this.key1(cell);
    this.position = cell;
    this.visited.add(at);
    motion.path.push(cell);
    const reached = t.target
      ? cell[0] === t.target[0] && cell[1] === t.target[1]
      : this.visited.size === t.floorCells;
    if (reached) {
      motion.goal = this.delivered.size < t.itemAt.size ? "undelivered" : "reached";
      return true;
    }
    const far = t.portals.get(at);
    if (far) {
      this.position = far;
      this.visited.add(this.key1(far));
      motion.path.push(far);
      motion.event = "TELEPORTED";
      return false;
    }
    const lock = t.keyAt.get(at);
    const dock = t.dockAt.get(at);
    const item = t.itemAt.get(at);
    const pair = t.switchAt.get(at);
    if (lock !== undefined && !this.held.has(lock)) {
      this.held.add(lock);
      motion.event = "KEY_TAKEN";
    } else if (dock !== undefined && dock === this.carrying) {
      this.delivered.add(dock);
      this.carrying = -1;
      motion.event = "ITEM_DROPPED";
    } else if (item !== undefined && this.carrying < 0 && !this.delivered.has(item)) {
      this.carrying = item;
      motion.event = "ITEM_TAKEN";
    } else if (pair !== undefined) {
      if (!this.flipped.delete(pair)) this.flipped.add(pair);
      motion.event = "SWITCHED";
    }
    return false;
  }

  /** A key for the state of the run: equal for two runs that can go on in the same way. */
  key(): string {
    const sorted = (set: Set<number>): string => [...set].sort((a, b) => a - b).join(".");
    const swept = this.t.target ? "" : `|${sorted(this.visited)}`;
    return `${this.position[0]},${this.position[1]},${DIRECTIONS.indexOf(this.direction)}|${sorted(this.held)}|${this.carrying}|${sorted(this.delivered)}|${sorted(this.flipped)}${swept}`;
  }
}
