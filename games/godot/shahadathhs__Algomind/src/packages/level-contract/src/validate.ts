import {
  COMMAND_NAMES,
  REPEAT_OP,
  REPEAT_UNTIL_OP,
  CALL_OP,
  COUNTER_REF,
  IF_OP,
  INC_OP,
  MARK_OP,
  NESTED_LOOPS_MECHANIC,
  RECURSION_MECHANIC,
  NODE_OPS,
  PATROL_PATTERNS,
  PROCEDURE_NAMES,
  PROC_OP,
  SENSORS,
  UNTIL_CONDITIONS,
  DIFFICULTIES,
  DIRECTIONS,
  GOAL_TYPES,
  ID_PATTERN,
  LIMITS,
  MECHANIC_PATTERN,
  SCHEMA_VERSION,
} from "./constants.js";
import { validatePairs } from "./validate-pairs.js";
import { validateTiles } from "./validate-tiles.js";
import type { CommandName, Issue, IssueCode, Level, ValidationResult } from "./types.js";

export type Obj = Record<string, unknown>;

const ID_RE = new RegExp(ID_PATTERN);
const MECHANIC_RE = new RegExp(MECHANIC_PATTERN);

const PUBLIC_KEYS = [
  "schemaVersion",
  "levelId",
  "levelVersion",
  "slug",
  "title",
  "description",
  "difficulty",
  "requires",
  "board",
  "initialState",
  "availableCommands",
  "constraints",
  "goal",
  "extraBoards",
  "startProgram",
  "patrols",
  "locks",
  "deliveries",
  "switches",
  "teleports",
  "ice",
  "belts",
  "hints",
];

export function isObject(v: unknown): v is Obj {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

export function has(o: Obj, key: string): boolean {
  return Object.prototype.hasOwnProperty.call(o, key);
}

export function isInt(v: unknown): v is number {
  return typeof v === "number" && Number.isSafeInteger(v);
}

function isNodeOp(v: unknown): v is CommandName | typeof CALL_OP {
  return typeof v === "string" && (NODE_OPS as readonly string[]).includes(v);
}

function isCommandName(v: unknown): v is CommandName {
  return typeof v === "string" && (COMMAND_NAMES as readonly string[]).includes(v);
}

function codePoints(s: string): number {
  let n = 0;
  for (const _ of s) n += 1;
  return n;
}

function join(base: string, key: string): string {
  return base === "" ? key : `${base}.${key}`;
}

export class Collector {
  issues: Issue[] = [];
  add(path: string, code: IssueCode, message: string): void {
    this.issues.push({ path, code, message });
  }
}

/** Reads a required field; reports REQUIRED when absent. */
function field(c: Collector, o: Obj, base: string, key: string): unknown {
  if (!has(o, key)) {
    c.add(join(base, key), "REQUIRED", `${join(base, key)} is required.`);
    return undefined;
  }
  return o[key];
}

/** Reports every key of `o` that is not in `allowed`. */
export function rejectUnknown(
  c: Collector,
  o: Obj,
  base: string,
  allowed: readonly string[],
): void {
  for (const key of Object.keys(o)) {
    if (!allowed.includes(key)) {
      c.add(join(base, key), "UNKNOWN_FIELD", `${join(base, key)} is not a known field.`);
    }
  }
}

/** Reads a required object field. Returns null (after reporting) when absent or not an object. */
function objectField(c: Collector, o: Obj, base: string, key: string): Obj | null {
  const v = field(c, o, base, key);
  if (v === undefined && !has(o, key)) return null;
  if (!isObject(v)) {
    c.add(join(base, key), "INVALID_TYPE", `${join(base, key)} must be an object.`);
    return null;
  }
  return v;
}

function intField(
  c: Collector,
  o: Obj,
  base: string,
  key: string,
  min: number,
  max: number,
): number | null {
  const path = join(base, key);
  if (!has(o, key)) {
    c.add(path, "REQUIRED", `${path} is required.`);
    return null;
  }
  const v = o[key];
  if (!isInt(v)) {
    c.add(path, "INVALID_TYPE", `${path} must be an integer.`);
    return null;
  }
  if (v < min || v > max) {
    c.add(path, "OUT_OF_RANGE", `${path} must be between ${min} and ${max}.`);
    return null;
  }
  return v;
}

function stringField(
  c: Collector,
  o: Obj,
  base: string,
  key: string,
  min: number,
  max: number,
  pattern?: RegExp,
): string | null {
  const path = join(base, key);
  if (!has(o, key)) {
    c.add(path, "REQUIRED", `${path} is required.`);
    return null;
  }
  return checkString(c, o[key], path, min, max, pattern);
}

function checkString(
  c: Collector,
  v: unknown,
  path: string,
  min: number,
  max: number,
  pattern?: RegExp,
): string | null {
  if (typeof v !== "string") {
    c.add(path, "INVALID_TYPE", `${path} must be a string.`);
    return null;
  }
  const len = codePoints(v);
  if (len < min || len > max) {
    c.add(path, "LENGTH_OUT_OF_RANGE", `${path} must be ${min} to ${max} characters long.`);
    return null;
  }
  if (pattern && !pattern.test(v)) {
    c.add(path, "INVALID_FORMAT", `${path} has an invalid format.`);
    return null;
  }
  return v;
}

export function enumField(
  c: Collector,
  o: Obj,
  base: string,
  key: string,
  allowed: readonly string[],
): string | null {
  const path = join(base, key);
  if (!has(o, key)) {
    c.add(path, "REQUIRED", `${path} is required.`);
    return null;
  }
  const v = o[key];
  if (typeof v !== "string") {
    c.add(path, "INVALID_TYPE", `${path} must be a string.`);
    return null;
  }
  if (!allowed.includes(v)) {
    c.add(path, "INVALID_VALUE", `${path} must be one of: ${allowed.join(", ")}.`);
    return null;
  }
  return v;
}

/**
 * Checks that `v` is a pair [x, y] of integers. Reports INVALID_TYPE otherwise and returns null.
 * When the board size is known and the cell lies outside it, reports OUTSIDE_BOARD but still returns the pair
 * so the later wall / start / goal comparisons can run.
 */
export function checkPair(
  c: Collector,
  v: unknown,
  path: string,
  size: { width: number; height: number } | null,
): [number, number] | null {
  if (!Array.isArray(v) || v.length !== 2 || !isInt(v[0]) || !isInt(v[1])) {
    c.add(path, "INVALID_TYPE", `${path} must be a pair [x, y] of integers.`);
    return null;
  }
  const x = v[0];
  const y = v[1];
  if (size && (x < 0 || y < 0 || x >= size.width || y >= size.height)) {
    c.add(
      path,
      "OUTSIDE_BOARD",
      `${path} must be inside the ${size.width} by ${size.height} board.`,
    );
  }
  return [x, y];
}

export function samePair(a: [number, number], b: [number, number]): boolean {
  return a[0] === b[0] && a[1] === b[1];
}

/** The path of `key` under `prefix` ("" is the level itself, "extraBoards[0]" a test board). */
function under(prefix: string, key: string): string {
  return prefix === "" ? key : `${prefix}.${key}`;
}

function validateBoardAndCells(c: Collector, root: Obj, prefix = ""): void {
  const boardPath = under(prefix, "board");
  const initialPath = under(prefix, "initialState");
  const goalBase = under(prefix, "goal");
  const board = objectField(c, root, prefix, "board");
  let size: { width: number; height: number } | null = null;
  let walls: ([number, number] | null)[] = [];
  if (board) {
    rejectUnknown(c, board, boardPath, ["width", "height", "walls"]);
    const side = LIMITS.boardSide;
    const width = intField(c, board, boardPath, "width", side.min, side.max);
    const height = intField(c, board, boardPath, "height", side.min, side.max);
    if (width !== null && height !== null) size = { width, height };
    walls = validateWalls(c, board, size, boardPath);
  }

  const wellFormedWalls = walls.filter((w): w is [number, number] => w !== null);

  const initial = objectField(c, root, prefix, "initialState");
  let start: [number, number] | null = null;
  if (initial) {
    rejectUnknown(c, initial, initialPath, ["position", "direction"]);
    if (has(initial, "position")) {
      start = checkPair(c, initial["position"], `${initialPath}.position`, size);
    } else {
      c.add(`${initialPath}.position`, "REQUIRED", `${initialPath}.position is required.`);
    }
    enumField(c, initial, initialPath, "direction", DIRECTIONS);
  }

  const goal = objectField(c, root, prefix, "goal");
  let goalPos: [number, number] | null = null;
  let visitAll = false;
  if (goal) {
    visitAll = goal["type"] === "visit_all";
    rejectUnknown(c, goal, goalBase, visitAll ? ["type"] : ["type", "position"]);
    enumField(c, goal, goalBase, "type", GOAL_TYPES);
    if (visitAll) {
      // The sweep needs somewhere to go: at least two floor cells, the start and one more.
      const distinct = new Set(wellFormedWalls.map((w) => `${w[0]},${w[1]}`)).size;
      if (size && size.width * size.height - distinct < 2) {
        c.add(goalBase, "GOAL_EQUALS_START", "The board needs at least two floor cells to sweep.");
      }
    } else if (has(goal, "position")) {
      goalPos = checkPair(c, goal["position"], `${goalBase}.position`, size);
    } else {
      c.add(`${goalBase}.position`, "REQUIRED", `${goalBase}.position is required.`);
    }
  }

  if (start && wellFormedWalls.some((w) => samePair(w, start))) {
    c.add(`${initialPath}.position`, "START_ON_WALL", "The start cell must not be a wall.");
  }
  if (goalPos && wellFormedWalls.some((w) => samePair(w, goalPos))) {
    c.add(`${goalBase}.position`, "GOAL_ON_WALL", "The goal cell must not be a wall.");
  }
  if (start && goalPos && samePair(start, goalPos)) {
    c.add(
      `${goalBase}.position`,
      "GOAL_EQUALS_START",
      "The goal cell must differ from the start cell.",
    );
  }
}

/** Returns one entry per wall: the pair, or null when that entry is malformed. */
function validateWalls(
  c: Collector,
  board: Obj,
  size: { width: number; height: number } | null,
  boardPath = "board",
): ([number, number] | null)[] {
  const wallsPath = `${boardPath}.walls`;
  if (!has(board, "walls")) {
    c.add(wallsPath, "REQUIRED", `${wallsPath} is required.`);
    return [];
  }
  const raw = board["walls"];
  if (!Array.isArray(raw)) {
    c.add(wallsPath, "INVALID_TYPE", `${wallsPath} must be an array.`);
    return [];
  }
  if (raw.length > LIMITS.maxWalls) {
    c.add(
      wallsPath,
      "LENGTH_OUT_OF_RANGE",
      `${wallsPath} must have at most ${LIMITS.maxWalls} entries.`,
    );
  }
  const out: ([number, number] | null)[] = [];
  const seen: [number, number][] = [];
  raw.forEach((entry, i) => {
    const path = `${wallsPath}[${i}]`;
    const pair = checkPair(c, entry, path, size);
    out.push(pair);
    if (pair) {
      if (seen.some((s) => samePair(s, pair))) {
        c.add(path, "DUPLICATE_WALL", `${path} repeats an earlier wall.`);
      } else {
        seen.push(pair);
      }
    }
  });
  return out;
}

/** The board facts the patrol checks need, read the way validateBoardAndCells reads them. */
export function boardFacts(root: Obj): {
  size: { width: number; height: number } | null;
  walls: [number, number][];
  start: [number, number] | null;
  goal: [number, number] | null;
} {
  const side = LIMITS.boardSide;
  const board = isObject(root["board"]) ? root["board"] : null;
  const dim = (v: unknown): number | null =>
    isInt(v) && v >= side.min && v <= side.max ? v : null;
  const width = board ? dim(board["width"]) : null;
  const height = board ? dim(board["height"]) : null;
  const walls: [number, number][] = [];
  if (board && Array.isArray(board["walls"])) {
    for (const w of board["walls"]) {
      if (Array.isArray(w) && w.length === 2 && isInt(w[0]) && isInt(w[1]))
        walls.push([w[0], w[1]]);
    }
  }
  const initial = isObject(root["initialState"]) ? root["initialState"] : null;
  const p = initial ? initial["position"] : undefined;
  const start: [number, number] | null =
    Array.isArray(p) && p.length === 2 && isInt(p[0]) && isInt(p[1]) ? [p[0], p[1]] : null;
  const goalCell = isObject(root["goal"]) ? root["goal"]["position"] : undefined;
  const goal: [number, number] | null =
    Array.isArray(goalCell) && goalCell.length === 2 && isInt(goalCell[0]) && isInt(goalCell[1])
      ? [goalCell[0], goalCell[1]]
      : null;
  return {
    size: width !== null && height !== null ? { width, height } : null,
    walls,
    start,
    goal,
  };
}

const adjacent = (a: [number, number], b: [number, number]): boolean =>
  Math.abs(a[0] - b[0]) + Math.abs(a[1] - b[1]) === 1;

function validatePatrols(c: Collector, root: Obj): void {
  if (!has(root, "patrols")) return;
  const raw = root["patrols"];
  if (!Array.isArray(raw)) {
    c.add("patrols", "INVALID_TYPE", "patrols must be an array.");
    return;
  }
  const lim = LIMITS.patrols;
  if (raw.length < lim.min || raw.length > lim.max) {
    c.add(
      "patrols",
      "LENGTH_OUT_OF_RANGE",
      `patrols must have ${lim.min} to ${lim.max} entries, or be left out.`,
    );
  }
  if (has(root, "extraBoards")) {
    c.add("patrols", "PATROLS_WITH_BOARDS", "A level with test boards cannot have patrols.");
  }
  const facts = boardFacts(root);
  raw.forEach((entry, i) => {
    const path = `patrols[${i}]`;
    if (!isObject(entry)) {
      c.add(path, "INVALID_TYPE", `${path} must be an object.`);
      return;
    }
    rejectUnknown(c, entry, path, ["pattern", "cells"]);
    const pattern = enumField(c, entry, path, "pattern", PATROL_PATTERNS);
    const cellsPath = `${path}.cells`;
    if (!has(entry, "cells")) {
      c.add(cellsPath, "REQUIRED", `${cellsPath} is required.`);
      return;
    }
    const cells = entry["cells"];
    if (!Array.isArray(cells)) {
      c.add(cellsPath, "INVALID_TYPE", `${cellsPath} must be an array.`);
      return;
    }
    const range = pattern === "loop" ? LIMITS.patrolLoopCells : LIMITS.patrolCells;
    if (cells.length < range.min || cells.length > range.max) {
      c.add(
        cellsPath,
        "LENGTH_OUT_OF_RANGE",
        `${cellsPath} must have ${range.min} to ${range.max} cells.`,
      );
    }
    const pairs: ([number, number] | null)[] = [];
    const seen: [number, number][] = [];
    cells.forEach((cell, j) => {
      const cellPath = `${cellsPath}[${j}]`;
      const pair = checkPair(c, cell, cellPath, facts.size);
      pairs.push(pair);
      if (!pair) return;
      if (facts.walls.some((w) => samePair(w, pair))) {
        c.add(cellPath, "PATROL_ON_WALL", `${cellPath} must not be a wall.`);
      }
      if (seen.some((s) => samePair(s, pair))) {
        c.add(cellPath, "PATROL_CELLS_REPEAT", `${cellPath} repeats an earlier cell.`);
      } else {
        seen.push(pair);
      }
      const before = pairs[j - 1];
      if (j > 0 && before && !adjacent(before, pair)) {
        c.add(cellPath, "PATROL_NOT_CONNECTED", `${cellPath} must be next to the cell before it.`);
      }
    });
    const first = pairs[0];
    if (first && facts.start && samePair(first, facts.start)) {
      c.add(
        `${cellsPath}[0]`,
        "PATROL_ON_START",
        "A patrol must not start on the automaton's cell.",
      );
    }
    const last = pairs[pairs.length - 1];
    if (pattern === "loop" && first && last && pairs.length > 1 && !adjacent(last, first)) {
      c.add(
        cellsPath,
        "PATROL_NOT_CONNECTED",
        "A ring must close: the last cell is next to the first.",
      );
    }
  });
}

function validateExtraBoards(c: Collector, root: Obj): void {
  if (!has(root, "extraBoards")) return;
  const raw = root["extraBoards"];
  if (!Array.isArray(raw)) {
    c.add("extraBoards", "INVALID_TYPE", "extraBoards must be an array.");
    return;
  }
  const lim = LIMITS.extraBoards;
  if (raw.length < lim.min || raw.length > lim.max) {
    c.add(
      "extraBoards",
      "LENGTH_OUT_OF_RANGE",
      `extraBoards must have ${lim.min} to ${lim.max} boards, or be left out.`,
    );
  }
  raw.forEach((entry, i) => {
    const path = `extraBoards[${i}]`;
    if (!isObject(entry)) {
      c.add(path, "INVALID_TYPE", `${path} must be an object.`);
      return;
    }
    rejectUnknown(c, entry, path, ["board", "initialState", "goal"]);
    validateBoardAndCells(c, entry, path);
  });
}

function validateCommands(c: Collector, root: Obj): void {
  if (!has(root, "availableCommands")) {
    c.add("availableCommands", "REQUIRED", "availableCommands is required.");
    return;
  }
  const raw = root["availableCommands"];
  if (!Array.isArray(raw)) {
    c.add("availableCommands", "INVALID_TYPE", "availableCommands must be an array.");
    return;
  }
  if (raw.length < 1) {
    c.add("availableCommands", "LENGTH_OUT_OF_RANGE", "availableCommands must not be empty.");
  }
  const seen: string[] = [];
  raw.forEach((item, i) => {
    const path = `availableCommands[${i}]`;
    if (typeof item !== "string") {
      c.add(path, "INVALID_TYPE", `${path} must be a string.`);
    } else if (!isCommandName(item)) {
      c.add(path, "UNKNOWN_COMMAND", `${path} is not a known command.`);
    } else if (seen.includes(item)) {
      c.add(path, "DUPLICATE_COMMAND", `${path} repeats an earlier command.`);
    } else {
      seen.push(item);
    }
  });
}

function validateRequires(c: Collector, root: Obj): void {
  const requires = objectField(c, root, "", "requires");
  if (!requires) return;
  rejectUnknown(c, requires, "requires", ["mechanics"]);
  if (!has(requires, "mechanics")) {
    c.add("requires.mechanics", "REQUIRED", "requires.mechanics is required.");
    return;
  }
  const raw = requires["mechanics"];
  if (!Array.isArray(raw)) {
    c.add("requires.mechanics", "INVALID_TYPE", "requires.mechanics must be an array.");
    return;
  }
  const lim = LIMITS.mechanics;
  if (raw.length > lim.maxCount) {
    c.add(
      "requires.mechanics",
      "LENGTH_OUT_OF_RANGE",
      `requires.mechanics must have at most ${lim.maxCount} entries.`,
    );
  }
  const seen: string[] = [];
  raw.forEach((item, i) => {
    const path = `requires.mechanics[${i}]`;
    const s = checkString(c, item, path, lim.itemLength.min, lim.itemLength.max, MECHANIC_RE);
    if (s === null) return;
    if (seen.includes(s)) {
      c.add(path, "DUPLICATE_MECHANIC", `${path} repeats an earlier mechanic.`);
    } else {
      seen.push(s);
    }
  });
}

function validateConstraints(c: Collector, root: Obj): void {
  const constraints = objectField(c, root, "", "constraints");
  if (!constraints) return;
  rejectUnknown(c, constraints, "constraints", ["maxCommands", "maxSteps"]);
  intField(
    c,
    constraints,
    "constraints",
    "maxCommands",
    LIMITS.maxCommands.min,
    LIMITS.maxCommands.max,
  );
  intField(c, constraints, "constraints", "maxSteps", LIMITS.maxSteps.min, LIMITS.maxSteps.max);
}

function validateHints(c: Collector, root: Obj): void {
  if (!has(root, "hints")) {
    c.add("hints", "REQUIRED", "hints is required.");
    return;
  }
  const raw = root["hints"];
  if (!Array.isArray(raw)) {
    c.add("hints", "INVALID_TYPE", "hints must be an array.");
    return;
  }
  const lim = LIMITS.hints;
  if (raw.length > lim.maxCount) {
    c.add("hints", "LENGTH_OUT_OF_RANGE", `hints must have at most ${lim.maxCount} entries.`);
  }
  raw.forEach((item, i) => {
    checkString(c, item, `hints[${i}]`, lim.itemLength.min, lim.itemLength.max);
  });
}

function validateLevelWith(input: unknown, authoring: boolean): ValidationResult {
  const c = new Collector();
  try {
    run(c, input, authoring);
  } catch {
    // Defensive: validation never throws on any input (for example a hostile getter or Proxy).
    c.add("", "INVALID_TYPE", "The level could not be read.");
  }
  return { ok: c.issues.length === 0, issues: c.issues };
}

function run(c: Collector, input: unknown, authoring: boolean): void {
  if (!isObject(input)) {
    c.add("", "INVALID_TYPE", "The level must be an object.");
    return;
  }

  // An unsupported schema version is rejected on its own: nothing else can be trusted.
  if (has(input, "schemaVersion") && isInt(input["schemaVersion"])) {
    if (input["schemaVersion"] !== SCHEMA_VERSION) {
      c.add(
        "schemaVersion",
        "UNSUPPORTED_SCHEMA_VERSION",
        `schemaVersion ${input["schemaVersion"]} is not supported; expected ${SCHEMA_VERSION}.`,
      );
      return;
    }
  } else if (has(input, "schemaVersion")) {
    c.add("schemaVersion", "INVALID_TYPE", "schemaVersion must be an integer.");
  } else {
    c.add("schemaVersion", "REQUIRED", "schemaVersion is required.");
  }

  rejectUnknown(c, input, "", authoring ? [...PUBLIC_KEYS, "referenceSolution"] : PUBLIC_KEYS);

  const ids = LIMITS.levelId;
  stringField(c, input, "", "levelId", ids.min, ids.max, ID_RE);
  intField(c, input, "", "levelVersion", LIMITS.levelVersion.min, LIMITS.levelVersion.max);
  stringField(c, input, "", "slug", LIMITS.slug.min, LIMITS.slug.max, ID_RE);
  stringField(c, input, "", "title", LIMITS.title.min, LIMITS.title.max);
  stringField(c, input, "", "description", LIMITS.description.min, LIMITS.description.max);
  enumField(c, input, "", "difficulty", DIFFICULTIES);
  validateRequires(c, input);
  validateBoardAndCells(c, input);
  validateExtraBoards(c, input);
  validatePatrols(c, input);
  validatePairs(c, input);
  validateTiles(c, input);
  validateCommands(c, input);
  validateConstraints(c, input);
  validateHints(c, input);
  if (has(input, "startProgram")) {
    checkProgram(c, input["startProgram"], "startProgram", programLimits(input));
  }

  if (authoring) {
    if (!has(input, "referenceSolution")) {
      c.add("referenceSolution", "REQUIRED", "referenceSolution is required.");
    } else {
      checkProgram(c, input["referenceSolution"], "referenceSolution", programLimits(input));
    }
  }
}

/** Best-effort read of availableCommands / maxCommands from a level that may have other problems. */
type ProgramLimits = {
  available: CommandName[] | null;
  max: number | null;
  /** The level lists the mechanic nested_loops: a loop may hold one loop. */
  nested: boolean;
  /** The level lists the mechanic recursion: a procedure may CALL, and a CALL may carry a sensor. */
  recursion: boolean;
};

function programLimits(level: unknown): ProgramLimits {
  if (!isObject(level)) return { available: null, max: null, nested: false, recursion: false };
  let available: CommandName[] | null = null;
  if (Array.isArray(level["availableCommands"])) {
    available = level["availableCommands"].filter(isCommandName);
  }
  let max: number | null = null;
  const constraints = level["constraints"];
  if (isObject(constraints) && isInt(constraints["maxCommands"])) max = constraints["maxCommands"];
  const requires = level["requires"];
  const mechanics = isObject(requires) ? requires["mechanics"] : undefined;
  const nested = Array.isArray(mechanics) && mechanics.includes(NESTED_LOOPS_MECHANIC);
  const recursion = Array.isArray(mechanics) && mechanics.includes(RECURSION_MECHANIC);
  return { available, max, nested, recursion };
}

function checkProgram(c: Collector, program: unknown, base: string, limits: ProgramLimits): void {
  if (!Array.isArray(program)) {
    c.add(base, "INVALID_TYPE", `${base} must be an array of instructions.`);
    return;
  }
  // Slots: a primitive and a CALL are 1; a loop, an IF and a PROC are 1 plus what they hold.
  let slots = 0;
  /**
   * Where a node stands: at the top, in a loop body (and how deep), inside an IF branch, or in a
   * procedure body.
   */
  type Place = {
    top: boolean;
    /** Inside a procedure body (a CALL may not stand there). */
    inProc: boolean;
    /** How many loops enclose the node. */
    loops: number;
    /** Inside an IF branch. */
    branch: boolean;
  };
  const TOP: Place = { top: true, inProc: false, loops: 0, branch: false };
  const procNames = new Set<string>();
  for (const node of program) {
    if (isObject(node) && node["op"] === PROC_OP && typeof node["name"] === "string") {
      procNames.add(node["name"]);
    }
  }
  const defined = new Set<string>();

  /** Checks the op of a node. `nested` is true when the place does not allow it (reported once). */
  const checkOp = (
    node: Obj,
    path: string,
    place: Place,
  ): { op: CommandName | typeof CALL_OP | null; nested: boolean } => {
    const opPath = `${path}.op`;
    if (!has(node, "op")) {
      c.add(opPath, "REQUIRED", `${opPath} is required.`);
      return { op: null, nested: false };
    }
    const op = node["op"];
    if (typeof op !== "string") {
      c.add(opPath, "INVALID_TYPE", `${opPath} must be a string.`);
      return { op: null, nested: false };
    }
    if (!isNodeOp(op)) {
      c.add(opPath, "UNKNOWN_COMMAND", `${opPath} is not a known command.`);
      return { op: null, nested: false };
    }
    const isLoopOp = op === REPEAT_OP || op === REPEAT_UNTIL_OP;
    // A loop may hold one more loop only when the level lists the mechanic nested_loops.
    const loopAllowed =
      !place.branch && (place.loops === 0 || (place.loops === 1 && limits.nested));
    if (isLoopOp && !loopAllowed) {
      c.add(opPath, "NESTED_REPEAT", `${opPath}: a loop cannot contain a loop here.`);
      return { op: null, nested: true };
    }
    if (op === IF_OP && place.branch) {
      c.add(opPath, "NESTED_IF", `${opPath}: an IF cannot contain an IF.`);
      return { op: null, nested: true };
    }
    if (op === PROC_OP && !place.top) {
      c.add(opPath, "NESTED_PROC", `${opPath}: a procedure can only be defined at the top level.`);
      return { op: null, nested: true };
    }
    const inProcBody = place.inProc && place.loops === 0 && !place.branch;
    if (op === CALL_OP && (place.branch || (place.inProc && !(limits.recursion && inProcBody)))) {
      c.add(
        opPath,
        "CALL_NOT_ALLOWED",
        `${opPath}: a CALL stands at the top level or in a loop of the main program (and, with the recursion mechanic, in the body of a procedure).`,
      );
      return { op: null, nested: true };
    }
    const needed = op === CALL_OP ? PROC_OP : op;
    if (limits.available && !limits.available.includes(needed)) {
      c.add(opPath, "COMMAND_NOT_AVAILABLE", `${op} is not available in this level.`);
    }
    return { op, nested: false };
  };

  const allowedKeys = (op: string | null): string[] =>
    op === REPEAT_OP
      ? ["op", "count", "body"]
      : op === REPEAT_UNTIL_OP
        ? ["op", "until", "body"]
        : op === IF_OP
          ? ["op", "when", "then", "else"]
          : op === PROC_OP
            ? ["op", "name", "body"]
            : op === CALL_OP
              ? limits.recursion
                ? ["op", "name", "when"]
                : ["op", "name"]
              : ["op"];

  /** An array of instructions of one place: returns the list, or null when it is not an array. */
  const checkList = (
    node: Obj,
    key: string,
    path: string,
    range: { min: number; max: number },
    required: boolean,
  ): unknown[] | null => {
    const listPath = `${path}.${key}`;
    if (!has(node, key)) {
      if (required) c.add(listPath, "REQUIRED", `${listPath} is required.`);
      return null;
    }
    const list = node[key];
    if (!Array.isArray(list)) {
      c.add(listPath, "INVALID_TYPE", `${listPath} must be an array of instructions.`);
      return null;
    }
    if (list.length < range.min || list.length > range.max) {
      c.add(
        listPath,
        "LENGTH_OUT_OF_RANGE",
        `${listPath} must have ${range.min} to ${range.max} instructions.`,
      );
    }
    return list;
  };

  /** The name of a PROC or a CALL. */
  const checkName = (node: Obj, path: string): string | null => {
    const namePath = `${path}.name`;
    if (!has(node, "name")) {
      c.add(namePath, "REQUIRED", `${namePath} is required.`);
    } else if (typeof node["name"] !== "string") {
      c.add(namePath, "INVALID_TYPE", `${namePath} must be a string.`);
    } else if (!(PROCEDURE_NAMES as readonly string[]).includes(node["name"])) {
      c.add(namePath, "INVALID_VALUE", `${namePath} must be one of ${PROCEDURE_NAMES.join(", ")}.`);
    } else {
      return node["name"];
    }
    return null;
  };

  /** One instruction in a place: checks it, counts its slots, and goes into what it holds. */
  const checkItem = (item: unknown, path: string, place: Place): void => {
    if (!isObject(item)) {
      c.add(path, "INVALID_TYPE", `${path} must be an instruction object.`);
      slots += 1;
      return;
    }
    const { op, nested } = checkOp(item, path, place);
    // A node the place does not allow is reported once, not field by field.
    if (!nested) {
      rejectUnknown(
        c,
        item,
        path,
        allowedKeys(op ?? (typeof item["op"] === "string" ? null : null)),
      );
    }
    slots += 1;
    if (op === REPEAT_OP || op === REPEAT_UNTIL_OP) {
      checkLoop(item, path, op, { ...place, top: false, loops: place.loops + 1 });
    } else if (op === IF_OP) {
      checkIf(item, path, place);
    } else if (op === PROC_OP) {
      checkProc(item, path);
    } else if (op === CALL_OP) {
      const name = checkName(item, path);
      if (name !== null && !procNames.has(name)) {
        c.add(
          `${path}.name`,
          "UNDEFINED_PROCEDURE",
          `${path}.name: no procedure ${name} is defined.`,
        );
      }
      if (limits.recursion && has(item, "when")) {
        const whenPath = `${path}.when`;
        if (typeof item["when"] !== "string") {
          c.add(whenPath, "INVALID_TYPE", `${whenPath} must be a string.`);
        } else if (!(SENSORS as readonly string[]).includes(item["when"])) {
          c.add(whenPath, "INVALID_VALUE", `${whenPath} must be one of ${SENSORS.join(", ")}.`);
        }
      }
    }
  };

  const checkProc = (node: Obj, path: string): void => {
    const name = checkName(node, path);
    if (name !== null) {
      if (defined.has(name)) {
        c.add(`${path}.name`, "DUPLICATE_PROCEDURE", `${path}.name: ${name} is defined twice.`);
      }
      defined.add(name);
    }
    const body = checkList(node, "body", path, LIMITS.procBody, true);
    const procPlace: Place = { top: false, inProc: true, loops: 0, branch: false };
    body?.forEach((inner, j) => checkItem(inner, `${path}.body[${j}]`, procPlace));
  };

  /**
   * The fields and branches of an IF node whose op was already checked. `chain` is how many IFs of an
   * else-if chain have been seen, this one included.
   */
  const checkIf = (node: Obj, path: string, place: Place, chain = 1): void => {
    const whenPath = `${path}.when`;
    if (!has(node, "when")) {
      c.add(whenPath, "REQUIRED", `${whenPath} is required.`);
    } else if (typeof node["when"] !== "string") {
      c.add(whenPath, "INVALID_TYPE", `${whenPath} must be a string.`);
    } else if (!(SENSORS as readonly string[]).includes(node["when"])) {
      c.add(whenPath, "INVALID_VALUE", `${whenPath} must be one of ${SENSORS.join(", ")}.`);
    } else if (
      !node["when"].startsWith("CLEAR_") &&
      limits.available &&
      !limits.available.includes(MARK_OP)
    ) {
      c.add(
        whenPath,
        "COMMAND_NOT_AVAILABLE",
        `${node["when"]} needs MARK, which is not available in this level.`,
      );
    }
    const branchPlace: Place = { ...place, top: false, branch: true };
    const thenList = checkList(node, "then", path, LIMITS.ifThen, true);
    thenList?.forEach((inner, j) => checkItem(inner, `${path}.then[${j}]`, branchPlace));
    const other = checkList(node, "else", path, LIMITS.ifElse, true);
    if (!other) return;
    const next =
      other.length === 1 && isObject(other[0]) && other[0]["op"] === IF_OP ? other[0] : null;
    if (next === null) {
      other.forEach((inner, j) => checkItem(inner, `${path}.else[${j}]`, branchPlace));
      return;
    }
    // An else-if chain: the else holds exactly one more IF.
    const nextPath = `${path}.else[0]`;
    if (chain >= LIMITS.ifChain) {
      c.add(
        `${nextPath}.op`,
        "NESTED_IF",
        `${nextPath}.op: an else-if chain holds at most ${LIMITS.ifChain} IFs.`,
      );
      return;
    }
    rejectUnknown(c, next, nextPath, allowedKeys(IF_OP));
    slots += 1;
    checkIf(next, nextPath, place, chain + 1);
  };

  const checkLoop = (node: Obj, path: string, known: CommandName, bodyPlace: Place): void => {
    if (known === REPEAT_OP) {
      const countPath = `${path}.count`;
      if (!has(node, "count")) {
        c.add(countPath, "REQUIRED", `${countPath} is required.`);
      } else if (node["count"] === COUNTER_REF) {
        // The counter needs INC offered.
        if (limits.available && !limits.available.includes(INC_OP)) {
          c.add(
            countPath,
            "COMMAND_NOT_AVAILABLE",
            `${countPath}: the counter needs INC, which is not available in this level.`,
          );
        }
      } else if (!isInt(node["count"])) {
        c.add(countPath, "INVALID_TYPE", `${countPath} must be an integer or "${COUNTER_REF}".`);
      } else if (node["count"] < LIMITS.repeatCount.min || node["count"] > LIMITS.repeatCount.max) {
        c.add(
          countPath,
          "OUT_OF_RANGE",
          `${countPath} must be from ${LIMITS.repeatCount.min} to ${LIMITS.repeatCount.max}.`,
        );
      }
    } else {
      const untilPath = `${path}.until`;
      if (!has(node, "until")) {
        c.add(untilPath, "REQUIRED", `${untilPath} is required.`);
      } else if (typeof node["until"] !== "string") {
        c.add(untilPath, "INVALID_TYPE", `${untilPath} must be a string.`);
      } else if (!(UNTIL_CONDITIONS as readonly string[]).includes(node["until"])) {
        c.add(
          untilPath,
          "INVALID_VALUE",
          `${untilPath} must be one of ${UNTIL_CONDITIONS.join(", ")}.`,
        );
      }
    }
    const body = checkList(node, "body", path, LIMITS.repeatBody, true);
    body?.forEach((inner, j) => checkItem(inner, `${path}.body[${j}]`, bodyPlace));
  };

  program.forEach((node, i) => checkItem(node, `${base}[${i}]`, TOP));
  if (limits.max !== null && slots > limits.max) {
    c.add(
      base,
      "TOO_MANY_COMMANDS",
      `${base} uses ${slots} slots; this level allows ${limits.max}.`,
    );
  }
}

/** Validates a public level definition (no `referenceSolution` allowed). Never throws. */
export function validateLevel(input: unknown): ValidationResult {
  return validateLevelWith(input, false);
}

/** Validates an authoring level: the public definition plus a required `referenceSolution`. Never throws. */
export function validateAuthoringLevel(input: unknown): ValidationResult {
  return validateLevelWith(input, true);
}

/**
 * Validates a program against a (valid) level: every instruction is well formed, its op is known and listed in
 * `availableCommands`, and the program is no longer than `constraints.maxCommands`. An empty program is valid.
 * Never throws.
 */
export function validateProgram(level: Level, program: unknown): ValidationResult {
  const c = new Collector();
  try {
    checkProgram(c, program, "program", programLimits(level));
  } catch {
    c.add("program", "INVALID_TYPE", "The program could not be read.");
  }
  return { ok: c.issues.length === 0, issues: c.issues };
}
