import type {
  ACTION_COMMANDS,
  PATROL_PATTERNS,
  COMMAND_NAMES,
  DIFFICULTIES,
  DIRECTIONS,
  PRIMITIVE_COMMANDS,
  SENSORS,
  PROCEDURE_NAMES,
  UNTIL_CONDITIONS,
} from "./constants.js";

/** A command that moves or turns the automaton: what the exact solver searches. */
export type PrimitiveName = (typeof PRIMITIVE_COMMANDS)[number];
/** Any single-step instruction: a move, a turn, INC or MARK. */
export type ActionName = (typeof ACTION_COMMANDS)[number];
export type CommandName = (typeof COMMAND_NAMES)[number];
export type Sensor = (typeof SENSORS)[number];
export type ProcedureName = (typeof PROCEDURE_NAMES)[number];
export type UntilCondition = (typeof UNTIL_CONDITIONS)[number];
export type Direction = (typeof DIRECTIONS)[number];
export type PatrolPattern = (typeof PATROL_PATTERNS)[number];
export type Difficulty = (typeof DIFFICULTIES)[number];

/** [x, y]. x grows right, y grows down. */
export type Position = [number, number];

/** A move, a turn, INC or MARK. */
export interface PrimitiveInstruction {
  op: ActionName;
}
/** A decision: `then` runs when the sensor is true, `else` (possibly empty) when it is false. */
export interface IfInstruction {
  op: "IF";
  when: Sensor;
  then: PrimitiveInstruction[];
  /** Actions to run otherwise, or exactly one IF (an else-if chain). Possibly empty. */
  else: PrimitiveInstruction[] | [IfInstruction];
}
/** Runs the procedure called `name`. Allowed at the top level and as an item of a loop body. */
export interface CallInstruction {
  op: "CALL";
  name: ProcedureName;
  /** Only on a level with the mechanic recursion: the procedure runs only while the sensor is true. */
  when?: Sensor;
}
/** An item of a loop body: a primitive, an IF, or (in the main program only) a CALL. */
export type BodyInstruction = PrimitiveInstruction | IfInstruction | CallInstruction;
/** A loop: `body` runs `count` times. The body holds primitives and IFs, not loops. */
export interface RepeatInstruction {
  op: "REPEAT";
  /** Rounds: 2 to 11, or "N" for the counter's value when the loop starts. */
  count: number | "N";
  body: BodyInstruction[];
}
/**
 * A conditional loop: before each round it checks the condition, and the body runs again only while the
 * condition is false. `BLOCKED` is true when a wall or the board edge is straight ahead. The body holds
 * primitives only; a run that never meets the condition ends at the step limit.
 */
export interface RepeatUntilInstruction {
  op: "REPEAT_UNTIL";
  until: UntilCondition;
  body: BodyInstruction[];
}
/**
 * A procedure definition, at the top level only. It is not run where it stands; a CALL runs its body.
 * The body holds primitives, IFs and loops, never a CALL or another PROC.
 */
export interface ProcInstruction {
  op: "PROC";
  name: ProcedureName;
  body: (
    | PrimitiveInstruction
    | IfInstruction
    | RepeatInstruction
    | RepeatUntilInstruction
    | CallInstruction
  )[];
}
/** One node of a program. Nodes (not bare strings) so a loop can hold a body. */
export type Instruction =
  | PrimitiveInstruction
  | IfInstruction
  | CallInstruction
  | ProcInstruction
  | RepeatInstruction
  | RepeatUntilInstruction;
export type Program = Instruction[];

/** Reach the target cell. */
export interface ReachGoal {
  type: "reach_tile";
  position: Position;
}
/** Enter or start on every floor cell of the board. */
export interface VisitAllGoal {
  type: "visit_all";
}
export type Goal = ReachGoal | VisitAllGoal;

/** One test board: the grid, where the automaton starts, and the target. */
export interface BoardCase {
  board: { width: number; height: number; walls: Position[] };
  initialState: { position: Position; direction: Direction };
  goal: Goal;
}

/** The public level definition served to the game. Never contains the reference solution. */
/**
 * An obstacle that moves by a fixed pattern while the program runs. Its cell depends only on the
 * step number (see `patrolCell`), so a run is as deterministic as without it.
 */
export interface Patrol {
  pattern: PatrolPattern;
  /** The cells it visits, each next to the one before (a ring also closes from the last to the first). */
  cells: Position[];
}

/**
 * A key and the door it opens. The automaton picks the key up by entering its cell; until then the
 * door blocks like a wall (`BLOCKED_BY_DOOR`), and once the key is held the door is an ordinary cell.
 */
export interface Lock {
  key: Position;
  door: Position;
}

/**
 * An item and the dock it belongs on. The automaton picks the item up by entering its cell (only with
 * empty hands: it carries one item at a time) and delivers it by entering the dock. The target counts
 * only once every item is delivered (`UNDELIVERED` otherwise).
 */
export interface Delivery {
  item: Position;
  dock: Position;
}

/**
 * A switch and the gate it toggles. Entering the switch's cell flips the gate (shut to open, open to
 * shut), every time. A shut gate blocks like a wall (`BLOCKED_BY_GATE`). The gate starts shut unless
 * `open` is true.
 */
export interface Switch {
  switch: Position;
  gate: Position;
  open?: boolean;
}

/** Two cells joined by a teleporter: entering one puts the automaton on the other, in the same step. */
export interface Teleport {
  a: Position;
  b: Position;
}

/** A belt: after every action that leaves the automaton on `cell`, it is carried one cell in `direction`. */
export interface Belt {
  cell: Position;
  direction: Direction;
}

export interface Level {
  schemaVersion: 1;
  levelId: string;
  levelVersion: number;
  slug: string;
  title: string;
  description: string;
  difficulty: Difficulty;
  requires: { mechanics: string[] };
  board: { width: number; height: number; walls: Position[] };
  initialState: { position: Position; direction: Direction };
  availableCommands: CommandName[];
  constraints: { maxCommands: number; maxSteps: number };
  goal: Goal;
  /**
   * More test boards. When present, one program must solve this level's own board and every one of
   * these. Slots and the step limit are the same for each board; the limit applies to each run.
   */
  extraBoards?: BoardCase[];
  /**
   * A program the tape starts with, for a level about fixing a program (a debug level). It is
   * checked like any program of the level (known and available commands, within maxCommands), but
   * it need not solve the level; the publish gate in the API requires that it does not.
   */
  startProgram?: Program;
  /**
   * Patrols on the level's own board (not allowed together with `extraBoards`). A run fails when
   * the automaton and a patrol share a cell after a step, or swap cells in one step.
   */
  patrols?: Patrol[];
  /**
   * Key and door pairs on the level's own board (not with `extraBoards` or the sweep goal). Keys are
   * picked up by entering their cell and kept for the rest of the run.
   */
  locks?: Lock[];
  /**
   * Items to carry to their docks on the level's own board (not with `extraBoards` or the sweep goal).
   * The run succeeds on entering the target with every item delivered.
   */
  deliveries?: Delivery[];
  /**
   * Switches and the gates they toggle on the level's own board (not with `extraBoards` or the sweep
   * goal). The state of a gate depends only on how often its switch cell has been entered.
   */
  switches?: Switch[];
  /**
   * Ice cells on the level's own board (not with `extraBoards`). A move onto ice goes on sliding in the
   * same direction while the next cell is free; it stops on a cell that is not ice.
   */
  ice?: Position[];
  /**
   * Teleporter pairs on the level's own board (not with `extraBoards` or the sweep goal). Entering one end
   * of a pair puts the automaton on the other end, facing the same way; arriving does not teleport it
   * back. The cells of a pair are not on ice, belts or any other tile.
   */
  teleports?: Teleport[];
  /**
   * Belts on the level's own board (not with `extraBoards`). After an action that leaves the automaton on a
   * belt it is carried one cell in the belt's direction, unless that cell is blocked.
   */
  belts?: Belt[];
  hints: string[];
}

/** The level as stored for authors: the public definition plus the reference solution. Never served publicly. */
export interface AuthoringLevel extends Level {
  referenceSolution: Program;
}

export type IssueCode =
  | "INVALID_TYPE"
  | "REQUIRED"
  | "UNKNOWN_FIELD"
  | "UNSUPPORTED_SCHEMA_VERSION"
  | "OUT_OF_RANGE"
  | "LENGTH_OUT_OF_RANGE"
  | "INVALID_FORMAT"
  | "INVALID_VALUE"
  | "OUTSIDE_BOARD"
  | "DUPLICATE_WALL"
  | "START_ON_WALL"
  | "GOAL_ON_WALL"
  | "GOAL_EQUALS_START"
  | "UNKNOWN_COMMAND"
  | "DUPLICATE_COMMAND"
  | "DUPLICATE_MECHANIC"
  | "COMMAND_NOT_AVAILABLE"
  | "TOO_MANY_COMMANDS"
  | "NESTED_REPEAT"
  | "NESTED_IF"
  | "NESTED_PROC"
  | "CALL_NOT_ALLOWED"
  | "DUPLICATE_PROCEDURE"
  | "UNDEFINED_PROCEDURE"
  | "LOCK_ON_WALL"
  | "LOCK_ON_START"
  | "LOCK_ON_GOAL"
  | "LOCK_CELLS_REPEAT"
  | "LOCKS_WITH_BOARDS"
  | "LOCKS_WITH_SWEEP"
  | "DELIVERY_ON_WALL"
  | "DELIVERY_ON_START"
  | "DELIVERY_ON_GOAL"
  | "DELIVERY_CELLS_REPEAT"
  | "DELIVERIES_WITH_BOARDS"
  | "DELIVERIES_WITH_SWEEP"
  | "TELEPORT_ON_WALL"
  | "TELEPORT_ON_START"
  | "TELEPORT_ON_GOAL"
  | "TELEPORT_CELLS_REPEAT"
  | "TELEPORTS_WITH_BOARDS"
  | "TELEPORTS_WITH_SWEEP"
  | "ICE_ON_WALL"
  | "ICE_CELLS_REPEAT"
  | "ICE_WITH_BOARDS"
  | "BELT_ON_WALL"
  | "BELT_CELLS_REPEAT"
  | "BELT_ON_ICE"
  | "BELTS_WITH_BOARDS"
  | "SWITCH_ON_WALL"
  | "SWITCH_ON_START"
  | "SWITCH_ON_GOAL"
  | "SWITCH_CELLS_REPEAT"
  | "SWITCHES_WITH_BOARDS"
  | "SWITCHES_WITH_SWEEP"
  | "PATROL_ON_WALL"
  | "PATROL_ON_START"
  | "PATROL_CELLS_REPEAT"
  | "PATROL_NOT_CONNECTED"
  | "PATROLS_WITH_BOARDS";

export interface Issue {
  /** JSON-pointer-like location, e.g. "board.width" or "board.walls[2]". "" is the document root. */
  path: string;
  /** Stable machine-readable code. */
  code: IssueCode;
  /** Human-readable text. Not part of the contract; do not match on it. */
  message: string;
}

export interface ValidationResult {
  ok: boolean;
  issues: Issue[];
}

export interface State {
  position: Position;
  direction: Direction;
}

export type RunStatus = "SUCCEEDED" | "FAILED";
export type RunReason =
  | "GOAL_REACHED"
  | "BLOCKED_BY_WALL"
  | "BLOCKED_BY_BOUNDARY"
  | "PROGRAM_ENDED"
  | "STEP_LIMIT"
  | "HIT_BY_PATROL"
  | "BLOCKED_BY_DOOR"
  | "UNDELIVERED"
  | "BLOCKED_BY_GATE"
  | "TOO_DEEP"
  | "INVALID_INSTRUCTION";

export type TraceEvent =
  | "MOVED"
  | "TURNED"
  | "COUNTED"
  | "MARKED"
  | "GOAL_REACHED"
  | "BLOCKED_BY_WALL"
  | "BLOCKED_BY_BOUNDARY"
  | "HIT_BY_PATROL"
  | "BLOCKED_BY_DOOR"
  | "KEY_TAKEN"
  | "ITEM_TAKEN"
  | "ITEM_DROPPED"
  | "UNDELIVERED"
  | "BLOCKED_BY_GATE"
  | "SWITCHED"
  | "SLID"
  | "TELEPORTED"
  | "CARRIED";

export interface TraceEntry {
  /** 0-based index of the executed step. */
  index: number;
  op: ActionName;
  /**
   * Where the instruction sits in the program: [i] at the top level, [i, j] inside the body of loop i,
   * [i, k] inside the branches of the IF at i, and [i, j, k] inside the IF at body item j of loop i. k
   * counts the `then` primitives first and the `else` primitives after them. Inside a procedure the path
   * starts with the index p of the PROC node and goes on as if the PROC were a loop: [p, j, ...].
   */
  node: number[];
  /**
   * The path of the CALL node whose procedure is running this instruction, or null in the main
   * program. A primitive inside a procedure has `node` `[p, ...]`, where p is the index of the PROC.
   */
  call: number[] | null;
  /** The counter N after the step (1 when the level has no counter). */
  counter: number;
  /** 1-based repetition of the loop the instruction ran in; null outside a loop. */
  round: number | null;
  /** State after the step. */
  position: Position;
  direction: Direction;
  event: TraceEvent;
  /**
   * Only on a level with ice, belts or teleporters: the cells the step entered, in order (empty for a turn, INC or MARK
   * that moved nothing). The last one is `position`.
   */
  path?: Position[];
}

export interface RunResult {
  status: RunStatus;
  reason: RunReason;
  /** Number of executed steps; always equals trace.length. */
  steps: number;
  finalState: State;
  /** The cell the automaton tried to enter, for the two BLOCKED reasons; otherwise null. */
  blockedCell: Position | null;
  trace: TraceEntry[];
}

/** The result of one program on every board of a level: the level's own board first. */
export interface MultiRunResult {
  /** SUCCEEDED only when every board succeeded. */
  status: RunStatus;
  /** Index of the first board that failed (0 is the level's own board), or null. */
  firstFailure: number | null;
  /** The sum of the steps of all runs. */
  steps: number;
  results: RunResult[];
}

export interface SolveResult {
  commands: number;
  steps: number;
  program: Program;
  /** True when commands <= constraints.maxCommands and steps <= constraints.maxSteps. */
  fitsConstraints: boolean;
}
