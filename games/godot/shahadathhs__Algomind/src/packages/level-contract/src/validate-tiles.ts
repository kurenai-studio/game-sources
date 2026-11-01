import { DIRECTIONS, LIMITS } from "./constants.js";
import {
  boardFacts,
  checkPair,
  enumField,
  has,
  rejectUnknown,
  samePair,
  type Collector,
  type Obj,
} from "./validate.js";

type Cell = [number, number];

/** Checks the length of a list of tiles and that the level has no test boards. Returns the list or null. */
function tileList(
  c: Collector,
  root: Obj,
  field: "ice" | "belts",
  limits: { min: number; max: number },
  boards: "ICE_WITH_BOARDS" | "BELTS_WITH_BOARDS",
): unknown[] | null {
  if (!has(root, field)) return null;
  const raw = root[field];
  if (!Array.isArray(raw)) {
    c.add(field, "INVALID_TYPE", `${field} must be an array.`);
    return null;
  }
  if (raw.length < limits.min || raw.length > limits.max) {
    c.add(
      field,
      "LENGTH_OUT_OF_RANGE",
      `${field} must have ${limits.min} to ${limits.max} entries, or be left out.`,
    );
  }
  if (has(root, "extraBoards")) {
    c.add(field, boards, `A level with test boards cannot have ${field}.`);
  }
  return raw;
}

/** Validates `ice` (a list of cells) and `belts` (cells with a direction). */
export function validateTiles(c: Collector, root: Obj): void {
  const facts = boardFacts(root);
  const iceCells: Cell[] = [];
  const ice = tileList(c, root, "ice", LIMITS.ice, "ICE_WITH_BOARDS");
  ice?.forEach((entry, i) => {
    const path = `ice[${i}]`;
    const pair = checkPair(c, entry, path, facts.size);
    if (!pair) return;
    if (facts.walls.some((w) => samePair(w, pair))) {
      c.add(path, "ICE_ON_WALL", `${path} must not be a wall.`);
    }
    if (iceCells.some((s) => samePair(s, pair))) {
      c.add(path, "ICE_CELLS_REPEAT", `${path} repeats an earlier ice cell.`);
    } else {
      iceCells.push(pair);
    }
  });

  const beltCells: Cell[] = [];
  const belts = tileList(c, root, "belts", LIMITS.belts, "BELTS_WITH_BOARDS");
  belts?.forEach((entry, i) => {
    const path = `belts[${i}]`;
    if (typeof entry !== "object" || entry === null || Array.isArray(entry)) {
      c.add(path, "INVALID_TYPE", `${path} must be an object.`);
      return;
    }
    const belt = entry as Obj;
    rejectUnknown(c, belt, path, ["cell", "direction"]);
    enumField(c, belt, path, "direction", DIRECTIONS);
    const cellPath = `${path}.cell`;
    if (!has(belt, "cell")) {
      c.add(cellPath, "REQUIRED", `${cellPath} is required.`);
      return;
    }
    const pair = checkPair(c, belt["cell"], cellPath, facts.size);
    if (!pair) return;
    if (facts.walls.some((w) => samePair(w, pair))) {
      c.add(cellPath, "BELT_ON_WALL", `${cellPath} must not be a wall.`);
    }
    if (iceCells.some((s) => samePair(s, pair))) {
      c.add(cellPath, "BELT_ON_ICE", `${cellPath} must not be an ice cell.`);
    }
    if (beltCells.some((s) => samePair(s, pair))) {
      c.add(cellPath, "BELT_CELLS_REPEAT", `${cellPath} repeats an earlier belt.`);
    } else {
      beltCells.push(pair);
    }
  });
}
