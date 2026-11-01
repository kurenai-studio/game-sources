// Boards as text rows: `.` floor, `#` wall, `G` goal, `^ > v <` the automaton and its facing.
export const FACING = { "^": "north", ">": "east", v: "south", "<": "west" };
export const GLYPH = { north: "^", east: ">", south: "v", west: "<" };
export const DELTA = { north: [0, -1], east: [1, 0], south: [0, 1], west: [-1, 0] };
export const ALL_COMMANDS = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"];

/** A deterministic PRNG (mulberry32), so a search with the same seed gives the same candidates. */
export function rng(seed) {
  let a = seed >>> 0;
  const next = () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  return {
    next,
    int: (min, max) => min + Math.floor(next() * (max - min + 1)),
    pick: (list) => list[Math.floor(next() * list.length)],
  };
}

/** Parses rows into the pieces of a level. */
export function parseRows(rows) {
  const walls = [];
  let goal;
  let start;
  rows.forEach((row, y) =>
    [...row].forEach((cell, x) => {
      if (cell === "#") walls.push([x, y]);
      else if (cell === "G") goal = [x, y];
      else if (cell in FACING) start = { position: [x, y], direction: FACING[cell] };
    }),
  );
  // A board without a G is a sweep: the goal is to visit every floor cell.
  if (!start) throw new Error("A board needs one automaton ^ > v <");
  return { width: rows[0].length, height: rows.length, walls, goal, start };
}

/** Builds a public level (contract schema version 1) from rows and a definition. */
export function levelFromRows(rows, def = {}) {
  const board = parseRows(rows);
  return {
    schemaVersion: 1,
    levelId: def.slug ?? "lab-level",
    levelVersion: 1,
    slug: def.slug ?? "lab-level",
    title: def.title ?? "Lab level",
    description: "",
    difficulty: def.difficulty ?? "easy",
    requires: { mechanics: [] },
    board: { width: board.width, height: board.height, walls: board.walls },
    initialState: board.start,
    availableCommands: def.commands ?? ALL_COMMANDS,
    constraints: { maxCommands: def.maxCommands ?? 64, maxSteps: def.maxSteps ?? 200 },
    goal: board.goal ? { type: "reach_tile", position: board.goal } : { type: "visit_all" },
    hints: def.hints ?? [],
  };
}

/** Rows from a grid of characters. */
export function gridToRows(grid) {
  return grid.map((row) => row.join(""));
}

export function emptyGrid(width, height) {
  return Array.from({ length: height }, () => Array(width).fill("."));
}

const ROTATE = { north: "east", east: "south", south: "west", west: "north" };
const MIRROR = { north: "north", south: "south", east: "west", west: "east" };

function rotate(rows) {
  const height = rows.length;
  const width = rows[0].length;
  const out = [];
  for (let x = 0; x < width; x += 1) {
    let line = "";
    for (let y = height - 1; y >= 0; y -= 1) {
      const c = rows[y][x];
      line += c in FACING ? GLYPH[ROTATE[FACING[c]]] : c;
    }
    out.push(line);
  }
  return out;
}

function mirror(rows) {
  return rows.map((row) =>
    [...row]
      .reverse()
      .map((c) => (c in FACING ? GLYPH[MIRROR[FACING[c]]] : c))
      .join(""),
  );
}

/** The same board under the eight rotations and mirrors: used to drop look-alike candidates. */
export function canonical(rows) {
  const forms = [];
  let current = rows;
  for (let i = 0; i < 4; i += 1) {
    forms.push(current.join("/"), mirror(current).join("/"));
    current = rotate(current);
  }
  return forms.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0))[0];
}
