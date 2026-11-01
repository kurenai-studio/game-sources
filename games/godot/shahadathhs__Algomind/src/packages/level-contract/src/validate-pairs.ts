import { LIMITS } from "./constants.js";
import type { IssueCode } from "./types.js";
import {
  boardFacts,
  checkPair,
  has,
  isInt,
  isObject,
  rejectUnknown,
  samePair,
  type Collector,
  type Obj,
} from "./validate.js";

type Field = "locks" | "deliveries" | "switches" | "teleports";
/** The fields a pair may not share cells with: other pairs, ice cells and belts. */
type Apart = Field | "ice" | "belts";

/** What differs between the kinds of paired cells on a board: keys and doors, items and docks, switches and gates. */
interface PairSpec {
  field: Field;
  parts: [string, string];
  noun: string;
  limits: { min: number; max: number };
  codes: Record<"wall" | "start" | "goal" | "repeat" | "boards" | "sweep", IssueCode>;
  /** The fields whose cells these may not share. */
  apart: Apart[];
  /** An optional boolean on each entry. */
  flag?: string;
}

const SPECS: PairSpec[] = [
  {
    field: "locks",
    parts: ["key", "door"],
    noun: "keys and doors",
    limits: LIMITS.locks,
    apart: [],
    codes: {
      wall: "LOCK_ON_WALL",
      start: "LOCK_ON_START",
      goal: "LOCK_ON_GOAL",
      repeat: "LOCK_CELLS_REPEAT",
      boards: "LOCKS_WITH_BOARDS",
      sweep: "LOCKS_WITH_SWEEP",
    },
  },
  {
    field: "deliveries",
    parts: ["item", "dock"],
    noun: "deliveries",
    limits: LIMITS.deliveries,
    apart: ["locks"],
    codes: {
      wall: "DELIVERY_ON_WALL",
      start: "DELIVERY_ON_START",
      goal: "DELIVERY_ON_GOAL",
      repeat: "DELIVERY_CELLS_REPEAT",
      boards: "DELIVERIES_WITH_BOARDS",
      sweep: "DELIVERIES_WITH_SWEEP",
    },
  },
  {
    field: "switches",
    parts: ["switch", "gate"],
    noun: "switches and gates",
    limits: LIMITS.switches,
    apart: ["locks", "deliveries"],
    flag: "open",
    codes: {
      wall: "SWITCH_ON_WALL",
      start: "SWITCH_ON_START",
      goal: "SWITCH_ON_GOAL",
      repeat: "SWITCH_CELLS_REPEAT",
      boards: "SWITCHES_WITH_BOARDS",
      sweep: "SWITCHES_WITH_SWEEP",
    },
  },
  {
    field: "teleports",
    parts: ["a", "b"],
    noun: "teleporters",
    limits: LIMITS.teleports,
    apart: ["locks", "deliveries", "switches", "ice", "belts"],
    codes: {
      wall: "TELEPORT_ON_WALL",
      start: "TELEPORT_ON_START",
      goal: "TELEPORT_ON_GOAL",
      repeat: "TELEPORT_CELLS_REPEAT",
      boards: "TELEPORTS_WITH_BOARDS",
      sweep: "TELEPORTS_WITH_SWEEP",
    },
  },
];

const PART_NAMES: Record<Field, [string, string]> = {
  locks: ["key", "door"],
  deliveries: ["item", "dock"],
  switches: ["switch", "gate"],
  teleports: ["a", "b"],
};

function asCell(v: unknown): [number, number] | null {
  return Array.isArray(v) && v.length === 2 && isInt(v[0]) && isInt(v[1]) ? [v[0], v[1]] : null;
}

/** The cells named by a field of the level, read leniently (an entry that is not a cell is skipped). */
function cellsOf(root: Obj, field: Apart): [number, number][] {
  const entries = root[field];
  if (!Array.isArray(entries)) return [];
  const out: [number, number][] = [];
  for (const entry of entries) {
    const found =
      field === "ice"
        ? [asCell(entry)]
        : field === "belts"
          ? [isObject(entry) ? asCell(entry["cell"]) : null]
          : PART_NAMES[field].map((part) => (isObject(entry) ? asCell(entry[part]) : null));
    for (const cell of found) if (cell) out.push(cell);
  }
  return out;
}

/** Validates `locks`, `deliveries` and `switches`: pairs of cells on the level's own board, all different. */
export function validatePairs(c: Collector, root: Obj): void {
  for (const spec of SPECS) validateField(c, root, spec);
}

function validateField(c: Collector, root: Obj, spec: PairSpec): void {
  const { field, parts, noun, limits, codes } = spec;
  if (!has(root, field)) return;
  const raw = root[field];
  if (!Array.isArray(raw)) {
    c.add(field, "INVALID_TYPE", `${field} must be an array.`);
    return;
  }
  if (raw.length < limits.min || raw.length > limits.max) {
    c.add(
      field,
      "LENGTH_OUT_OF_RANGE",
      `${field} must have ${limits.min} to ${limits.max} entries, or be left out.`,
    );
  }
  if (has(root, "extraBoards")) {
    c.add(field, codes.boards, `A level with test boards cannot have ${noun}.`);
  }
  const goalType = isObject(root["goal"]) ? root["goal"]["type"] : undefined;
  if (goalType === "visit_all") {
    c.add(field, codes.sweep, `A level that sweeps every cell cannot have ${noun}.`);
  }
  const facts = boardFacts(root);
  const seen: [number, number][] = [];
  for (const other of spec.apart) seen.push(...cellsOf(root, other));
  raw.forEach((entry, i) => {
    const path = `${field}[${i}]`;
    if (!isObject(entry)) {
      c.add(path, "INVALID_TYPE", `${path} must be an object.`);
      return;
    }
    rejectUnknown(c, entry, path, spec.flag ? [...parts, spec.flag] : parts);
    if (spec.flag && has(entry, spec.flag) && typeof entry[spec.flag] !== "boolean") {
      c.add(`${path}.${spec.flag}`, "INVALID_TYPE", `${path}.${spec.flag} must be true or false.`);
    }
    for (const part of parts) {
      const cellPath = `${path}.${part}`;
      if (!has(entry, part)) {
        c.add(cellPath, "REQUIRED", `${cellPath} is required.`);
        continue;
      }
      const pair = checkPair(c, entry[part], cellPath, facts.size);
      if (!pair) continue;
      if (facts.walls.some((w) => samePair(w, pair))) {
        c.add(cellPath, codes.wall, `${cellPath} must not be a wall.`);
      }
      if (facts.start && samePair(facts.start, pair)) {
        c.add(cellPath, codes.start, `${cellPath} must not be the automaton's cell.`);
      }
      if (facts.goal && samePair(facts.goal, pair)) {
        c.add(cellPath, codes.goal, `${cellPath} must not be the target.`);
      }
      if (seen.some((s) => samePair(s, pair))) {
        c.add(cellPath, codes.repeat, `${cellPath} repeats an earlier cell of ${noun}.`);
      } else {
        seen.push(pair);
      }
    }
  });
}
