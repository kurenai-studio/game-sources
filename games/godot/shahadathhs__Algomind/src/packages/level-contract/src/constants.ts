/** Schema version this package reads and writes. Anything else is rejected. */
export const SCHEMA_VERSION = 1;

/** The commands that move or turn the automaton, in the canonical order used by the solver. */
export const PRIMITIVE_COMMANDS = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"] as const;

/** Adds one to the counter N (stops at 11). Offered by listing INC; it also lets a REPEAT count with N. */
export const INC_OP = "INC";

/**
 * Drops a breadcrumb on the cell the automaton stands on: an arrow that points back to the cell it came
 * from (the cell behind it). A cell that already has one keeps it. Offered by listing MARK.
 */
export const MARK_OP = "MARK";

/** Every instruction that moves, turns, counts or marks: one slot and one step each. */
export const ACTION_COMMANDS = [...PRIMITIVE_COMMANDS, INC_OP, MARK_OP] as const;

/** The value of REPEAT.count that means "the counter N, read when the loop starts". */
export const COUNTER_REF = "N";

/** The mechanic a level lists in requires.mechanics to allow a loop inside a loop. */
export const NESTED_LOOPS_MECHANIC = "nested_loops";
/** A level that lists this mechanic lets a procedure CALL (itself or another) and a CALL carry a sensor. */
export const RECURSION_MECHANIC = "recursion";

/** The loop instruction: a count (a number, or "N") and a body of actions, IFs and one inner loop. */
export const REPEAT_OP = "REPEAT";

/** The conditional loop: it runs its body while the way ahead is open. */
export const REPEAT_UNTIL_OP = "REPEAT_UNTIL";

/**
 * The conditions a REPEAT_UNTIL can wait for. BLOCKED: a wall or the board edge is straight ahead.
 * GOAL is never true at the start of a round (entering the goal ends the run), so that loop runs until
 * the goal, a failure, or the step limit.
 */
export const UNTIL_CONDITIONS = ["BLOCKED", "GOAL"] as const;

/** The decision instruction: a sensor, a `then` branch and an `else` branch of primitives. */
export const IF_OP = "IF";

/**
 * What an IF can look at, each about the cell ahead, to the left or to the right. CLEAR: on the board and
 * not a wall. FRESH: such a cell with no breadcrumb. BACK: the cell this cell's breadcrumb points to (the
 * one the automaton first came from). The marker sensors need MARK offered.
 */
export const SENSORS = [
  "CLEAR_AHEAD",
  "CLEAR_LEFT",
  "CLEAR_RIGHT",
  "FRESH_AHEAD",
  "FRESH_LEFT",
  "FRESH_RIGHT",
  "BACK_AHEAD",
  "BACK_LEFT",
  "BACK_RIGHT",
] as const;

/** A named piece of program, defined once at the top level and run by CALL. */
export const PROC_OP = "PROC";

/** Runs the procedure of that name. Offered together with PROC: a level that lists PROC allows both. */
export const CALL_OP = "CALL";

/** The names a procedure can have. At most one procedure per name, so at most three. */
export const PROCEDURE_NAMES = ["A", "B", "C"] as const;

/** Every command a level can offer, in the canonical order. */
export const COMMAND_NAMES = [
  ...ACTION_COMMANDS,
  REPEAT_OP,
  REPEAT_UNTIL_OP,
  IF_OP,
  PROC_OP,
] as const;

/** Every op a program node can have: the commands, and CALL, which is offered by PROC. */
export const NODE_OPS = [...COMMAND_NAMES, CALL_OP] as const;

/** Directions in clockwise order starting at north. */
export const DIRECTIONS = ["north", "east", "south", "west"] as const;

export const DIFFICULTIES = ["easy", "medium", "hard"] as const;

export const GOAL_TYPES = ["reach_tile", "visit_all"] as const;

/**
 * How a patrol walks its cells: back and forth along the list (1, 2, 3, 2, 1, 2, ...) or round it
 * as a ring (1, 2, 3, 4, 1, ...). Its cell depends only on the step number.
 */
export const PATROL_PATTERNS = ["back_and_forth", "loop"] as const;

/** Unit step for each direction. x grows right, y grows down (0,0 is the top-left cell). */
export const DIRECTION_DELTAS = {
  north: [0, -1],
  east: [1, 0],
  south: [0, 1],
  west: [-1, 0],
} as const;

/** Inclusive limits enforced by the validator. The JSON Schema repeats them; a test keeps both in sync. */
export const LIMITS = {
  boardSide: { min: 3, max: 12 },
  maxWalls: 100,
  maxCommands: { min: 1, max: 64 },
  maxSteps: { min: 1, max: 1000 },
  /** Items in a loop body (primitives and IFs), and the number of repetitions. A loop cannot contain a loop. */
  repeatBody: { min: 1, max: 8 },
  repeatCount: { min: 2, max: 11 },
  /** Extra test boards a level may carry besides its own board (one program must solve every board). */
  extraBoards: { min: 1, max: 5 },
  /** Items in a procedure body (primitives, IFs and loops, not CALLs). */
  procBody: { min: 1, max: 8 },
  /** Primitives in the two branches of an IF. An IF cannot contain an IF or a loop. */
  ifThen: { min: 1, max: 4 },
  ifElse: { min: 0, max: 4 },
  /** How many IFs an else-if chain may hold (the first IF and each IF in an else). */
  ifChain: 6,
  /** The counter N: its value at the start of a run, and the most it reaches. */
  counter: { start: 1, max: 11 },
  /** Patrols on a level, and the cells of one: a ring (loop) needs at least four. */
  patrols: { min: 1, max: 3 },
  patrolCells: { min: 2, max: 12 },
  patrolLoopCells: { min: 4, max: 12 },
  /** Key and door pairs on a level. */
  locks: { min: 1, max: 3 },
  /** Items to deliver on a level. */
  deliveries: { min: 1, max: 3 },
  /** Switch and gate pairs on a level. */
  switches: { min: 1, max: 3 },
  /** How many procedure calls may be running inside each other (the CALL of the main program is the first). */
  callDepth: 24,
  /** Ice cells and belts on a level. */
  /** Teleporter pairs on a level. */
  teleports: { min: 1, max: 3 },
  ice: { min: 1, max: 30 },
  belts: { min: 1, max: 20 },
  levelVersion: { min: 1, max: 1_000_000 },
  /** Lengths are counted in Unicode code points. */
  levelId: { min: 1, max: 64 },
  slug: { min: 1, max: 64 },
  title: { min: 1, max: 60 },
  description: { min: 0, max: 280 },
  hints: { maxCount: 5, itemLength: { min: 1, max: 140 } },
  mechanics: { maxCount: 8, itemLength: { min: 1, max: 32 } },
} as const;

/** Lowercase letters and digits in groups separated by single hyphens. Used by levelId and slug. */
export const ID_PATTERN = "^[a-z0-9]+(-[a-z0-9]+)*$";
/** Lowercase letter first, then lowercase letters, digits, and underscores. Used by mechanic names. */
export const MECHANIC_PATTERN = "^[a-z][a-z0-9_]*$";
