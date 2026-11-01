// Candidate families for worlds 1 and 2. A family builds a board from a seeded generator and says
// which measured numbers make it a good level of its kind. The solver is the judge, not the author.
import { DELTA, GLYPH, emptyGrid, gridToRows } from "./board.mjs";
import { decoy, maze } from "./carve.mjs";
import { DIRECTIONS } from "./directions.mjs";

const MOVE = ["MOVE_FORWARD"];
const MOVE_RIGHT = ["MOVE_FORWARD", "TURN_RIGHT"];
const MOVE_LEFT = ["MOVE_FORWARD", "TURN_LEFT"];
const ALL = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"];

const inside = (w, h, x, y) => x >= 0 && y >= 0 && x < w && y < h;
const turnLeft = (d) => DIRECTIONS[(DIRECTIONS.indexOf(d) + 3) % 4];
const turnRight = (d) => DIRECTIONS[(DIRECTIONS.indexOf(d) + 1) % 4];

/** Walks `steps` cells in `dir` from [x, y], returning the new cell and the cells passed. */
function walk(x, y, dir, steps, path) {
  const [dx, dy] = DELTA[dir];
  for (let i = 0; i < steps; i += 1) {
    x += dx;
    y += dy;
    path.push([x, y]);
  }
  return [x, y];
}

/** Puts the start glyph and goal on a grid; null when a cell is outside it or they coincide. */
function stamp(grid, start, dir, goal) {
  const h = grid.length;
  const w = grid[0].length;
  if (!inside(w, h, start[0], start[1]) || !inside(w, h, goal[0], goal[1])) return null;
  if (start[0] === goal[0] && start[1] === goal[1]) return null;
  grid[start[1]][start[0]] = GLYPH[dir];
  grid[goal[1]][goal[0]] = "G";
  return grid;
}

/** Short wall pieces away from a set of cells, so a board is not empty but the route is unchanged. */
function decorate(grid, r, pieces, avoid) {
  const h = grid.length;
  const w = grid[0].length;
  const blocked = new Set(avoid.map(([x, y]) => `${x},${y}`));
  for (let n = 0; n < pieces; n += 1) {
    const length = r.int(1, 2);
    const horizontal = r.next() < 0.5;
    const x = r.int(0, w - 1);
    const y = r.int(0, h - 1);
    const cells = [];
    for (let i = 0; i < length; i += 1) cells.push(horizontal ? [x + i, y] : [x, y + i]);
    if (cells.some(([cx, cy]) => !inside(w, h, cx, cy) || blocked.has(`${cx},${cy}`))) continue;
    if (cells.some(([cx, cy]) => grid[cy][cx] !== ".")) continue;
    for (const [cx, cy] of cells) grid[cy][cx] = "#";
  }
}

/** A straight line: start, then `distance` cells ahead. */
function straight(r, { size, distance, commands, pieces }) {
  const dir = r.pick(DIRECTIONS);
  const grid = emptyGrid(size, size);
  const sx = r.int(0, size - 1);
  const sy = r.int(0, size - 1);
  const path = [[sx, sy]];
  const goal = walk(sx, sy, dir, distance, path);
  if (!stamp(grid, [sx, sy], dir, goal)) return null;
  decorate(grid, r, pieces, path);
  return { rows: gridToRows(grid), commands };
}

/** Straight runs joined by turns: `turns` lists "L" or "R" between runs. */
function turned(r, { size, runs, turns, commands, pieces }) {
  const grid = emptyGrid(size, size);
  const dir = r.pick(DIRECTIONS);
  const sx = r.int(0, size - 1);
  const sy = r.int(0, size - 1);
  const path = [[sx, sy]];
  let [x, y] = [sx, sy];
  let facing = dir;
  runs.forEach((range, i) => {
    [x, y] = walk(x, y, facing, r.int(range[0], range[1]), path);
    if (i < turns.length) facing = turns[i] === "L" ? turnLeft(facing) : turnRight(facing);
  });
  if (path.some(([px, py]) => !inside(size, size, px, py))) return null;
  // The route must not touch itself, or a shortcut appears.
  if (new Set(path.map((p) => p.join(","))).size !== path.length) return null;
  if (!stamp(grid, [sx, sy], dir, [x, y])) return null;
  decorate(grid, r, pieces, path);
  return { rows: gridToRows(grid), commands };
}

/** The goal is behind the automaton, optionally a few cells to one side. */
function behind(r, { size, back, side, commands, pieces }) {
  const dir = r.pick(DIRECTIONS);
  const grid = emptyGrid(size, size);
  const sx = r.int(0, size - 1);
  const sy = r.int(0, size - 1);
  const path = [[sx, sy]];
  const opposite = turnLeft(turnLeft(dir));
  let [x, y] = walk(sx, sy, opposite, r.int(back[0], back[1]), path);
  const sideSteps = r.int(side[0], side[1]);
  if (sideSteps > 0)
    [x, y] = walk(x, y, r.next() < 0.5 ? turnLeft(dir) : turnRight(dir), sideSteps, path);
  if (!stamp(grid, [sx, sy], dir, [x, y])) return null;
  decorate(grid, r, pieces, path);
  return { rows: gridToRows(grid), commands };
}

/** Start on one side, goal on the other, with wall segments across the way. */
function walled(r, { width, height, segments, length, commands }) {
  const grid = emptyGrid(width, height);
  const sx = r.int(0, width - 1);
  const start = [sx, height - 1];
  const goal = [r.int(0, width - 1), r.int(0, Math.floor(height / 2) - 1)];
  const dir = r.next() < 0.7 ? "north" : r.pick(DIRECTIONS);
  for (let n = 0; n < r.int(segments[0], segments[1]); n += 1) {
    const horizontal = r.next() < 0.6;
    const len = r.int(length[0], length[1]);
    const x = r.int(0, width - 1);
    const y = r.int(1, height - 2);
    for (let i = 0; i < len; i += 1) {
      const cx = horizontal ? x + i : x;
      const cy = horizontal ? y : y + i;
      if (inside(width, height, cx, cy)) grid[cy][cx] = "#";
    }
  }
  const at = (p) => grid[p[1]][p[0]];
  if (at(start) === "#" || at(goal) === "#") return null;
  if (!stamp(grid, start, dir, goal)) return null;
  return { rows: gridToRows(grid), commands };
}

/** Each family: a builder and what a good level of its kind measures. Ranges are inclusive. */
export const FAMILIES = {
  "moves-short": {
    world: 1,
    chapter: "Moves",
    idea: "Move forward until the goal. One tile.",
    build: (r) => straight(r, { size: 5, distance: 2, commands: MOVE, pieces: 1 }),
    accept: (m) => m.par === 2,
  },
  "moves-count": {
    world: 1,
    chapter: "Moves",
    idea: "Count the cells. Walls beside the way do not matter.",
    build: (r) => straight(r, { size: 6, distance: 4, commands: MOVE, pieces: 3 }),
    accept: (m) => m.par === 4,
  },
  "moves-far": {
    world: 1,
    chapter: "Moves",
    idea: "A longer run, counted exactly.",
    build: (r) => straight(r, { size: 7, distance: 6, commands: MOVE, pieces: 3 }),
    accept: (m) => m.par === 6,
  },
  "turn-right": {
    world: 1,
    chapter: "Turns",
    idea: "Move, turn right, move. The first turn.",
    build: (r) =>
      turned(r, {
        size: 5,
        runs: [
          [2, 3],
          [2, 3],
        ],
        turns: ["R"],
        commands: MOVE_RIGHT,
        pieces: 2,
      }),
    accept: (m) => m.turns === 1,
  },
  "turn-left": {
    world: 1,
    chapter: "Turns",
    idea: "Move, turn left, move. The other way.",
    build: (r) =>
      turned(r, {
        size: 5,
        runs: [
          [2, 3],
          [2, 3],
        ],
        turns: ["L"],
        commands: MOVE_LEFT,
        pieces: 2,
      }),
    accept: (m) => m.turns === 1,
  },
  "turn-around": {
    world: 1,
    chapter: "Turns",
    idea: "The goal is behind. Turn twice.",
    build: (r) => behind(r, { size: 5, back: [2, 3], side: [0, 0], commands: ALL, pieces: 2 }),
    accept: (m) => m.turns === 2,
  },
  "turn-two": {
    world: 1,
    chapter: "Turns",
    idea: "Two turns: right then left, or the reverse.",
    build: (r) => {
      const turns = r.next() < 0.5 ? ["R", "L"] : ["L", "R"];
      return turned(r, {
        size: 6,
        runs: [
          [1, 2],
          [2, 3],
          [1, 3],
        ],
        turns,
        commands: ALL,
        pieces: 2,
      });
    },
    accept: (m) => m.turns === 2,
  },
  "detour-wall": {
    world: 2,
    chapter: "Detours",
    idea: "A wall in the way. Go around it.",
    build: (r) =>
      walled(r, { width: 6, height: 6, segments: [1, 2], length: [3, 4], commands: ALL }),
    accept: (m) => m.excess >= 2 && m.excess <= 6 && m.par >= 8 && m.par <= 14 && m.deadEnds <= 1,
  },
  "detour-dead-end": {
    world: 2,
    chapter: "Detours",
    idea: "One way looks open and leads nowhere.",
    build: (r) =>
      walled(r, { width: 7, height: 7, segments: [2, 3], length: [3, 5], commands: ALL }),
    accept: (m) => m.excess >= 3 && m.deadEnds >= 1 && m.par >= 10 && m.par <= 18,
  },
  "detour-long": {
    world: 2,
    chapter: "Detours",
    idea: "The wall is long. The gap is at the far end.",
    build: (r) =>
      walled(r, { width: 8, height: 8, segments: [2, 3], length: [5, 7], commands: ALL }),
    accept: (m) => m.excess >= 5 && m.par >= 14 && m.par <= 22,
  },
  "budget-open": {
    world: 2,
    chapter: "Budgets",
    idea: "The limit equals par. Count the turns.",
    build: (r) =>
      walled(r, { width: 6, height: 6, segments: [1, 2], length: [2, 4], commands: ALL }),
    accept: (m) => m.par >= 8 && m.par <= 13 && m.turns >= 3,
  },
  "budget-decoy": {
    world: 2,
    chapter: "Budgets",
    idea: "The route with the fewest moves is not the cheapest program.",
    tries: 60000,
    build: (r) =>
      walled(r, { width: 7, height: 7, segments: [2, 4], length: [2, 4], commands: ALL }),
    accept: (m) => m.decoy >= 1 && m.par >= 9 && m.par <= 20,
  },
  "budget-maze": {
    world: 2,
    chapter: "Budgets",
    idea: "A maze where the limit is par.",
    build: (r) =>
      walled(r, { width: 8, height: 8, segments: [3, 5], length: [3, 6], commands: ALL }),
    accept: (m) => m.deadEnds >= 2 && m.par >= 16 && m.par <= 26,
  },
  // Carved boards: the route shapes are designed, then the solver confirms them.
  "budget-tree-maze": {
    world: 2,
    chapter: "Budgets",
    idea: "A maze with one route and deliberate dead ends; the limit is par.",
    build: (r) => maze(r, { width: 9, height: 9, commands: ALL }),
    accept: (m) => m.deadEnds >= 3 && m.par >= 16 && m.par <= 28 && m.optimalPrograms <= 2,
  },
  "budget-carved-decoy": {
    world: 2,
    chapter: "Budgets",
    idea: "The staircase has the fewest moves; the long way round is the cheaper program.",
    build: (r) => decoy(r, { size: 8, steps: r.int(3, 4), extra: r.int(2, 4), commands: ALL }),
    accept: (m) => m.decoy >= 2 && m.par >= 10 && m.par <= 22,
  },
};

// ---- Loop families (world 3). A corridor carved from a repeating pattern: the only route is the
// pattern, so a loop is what fits a tight limit. The solver proves the corridor has no shortcut. ----

const WITH_REPEAT = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT"];
const BODIES = {
  stairs: ["M", "R", "M", "L"],
  "stairs-left": ["M", "L", "M", "R"],
  wide: ["M", "M", "R", "M", "M", "L"],
  steep: ["M", "M", "M", "R", "M", "L"],
  "long-step": ["M", "R", "M", "M", "L"],
  hook: ["M", "M", "R", "M", "R", "M", "M", "L"],
};

/** Carves a corridor along `moves` (letters M, L, R) from the origin facing `dir`. */
function carve(moves, dir) {
  const cells = [[0, 0]];
  let [x, y] = [0, 0];
  let facing = dir;
  for (const m of moves) {
    if (m === "L") facing = turnLeft(facing);
    else if (m === "R") facing = turnRight(facing);
    else {
      const [dx, dy] = DELTA[facing];
      x += dx;
      y += dy;
      cells.push([x, y]);
    }
  }
  // A route that crosses itself would put the goal on the start or make a shortcut.
  if (new Set(cells.map((c) => c.join(","))).size !== cells.length) return null;
  const xs = cells.map((c) => c[0]);
  const ys = cells.map((c) => c[1]);
  const minX = Math.min(...xs);
  const minY = Math.min(...ys);
  const width = Math.max(3, Math.max(...xs) - minX + 1);
  const height = Math.max(3, Math.max(...ys) - minY + 1);
  if (width > 12 || height > 12) return null;
  const grid = Array.from({ length: height }, () => Array(width).fill("#"));
  for (const [cx, cy] of cells) grid[cy - minY][cx - minX] = ".";
  const start = [cells[0][0] - minX, cells[0][1] - minY];
  const goal = [x - minX, y - minY];
  grid[start[1]][start[0]] = GLYPH[dir];
  grid[goal[1]][goal[0]] = "G";
  return gridToRows(grid);
}

/** A run, then a repeating body, then a run. `meta.flatLength` is the length of the carved route. */
function patterned(r, { bodies, rounds, runs, commands }) {
  const name = r.pick(bodies);
  const body = BODIES[name];
  const count = r.int(rounds[0], rounds[1]);
  const before = r.int(runs[0], runs[1]);
  const after = r.int(runs[0], runs[1]);
  const moves = [
    ...Array(before).fill("M"),
    ...(before > 0 && r.next() < 0.5 ? [r.next() < 0.5 ? "L" : "R"] : []),
    ...Array(count).fill(body).flat(),
    ...Array(after).fill("M"),
  ];
  // A turn after the last move is never needed: the run ends on entering the goal.
  while (moves.length > 0 && moves[moves.length - 1] !== "M") moves.pop();
  const dir = r.pick(DIRECTIONS);
  const rows = carve(moves, dir);
  if (!rows) return null;
  return { rows, commands, meta: { body: name, count, flatLength: moves.length } };
}

const loopLevel = (m, meta) =>
  m.loops && m.flatPar === meta.flatLength && m.flatPar >= m.par + 5 && m.deadEnds === 0;

FAMILIES["loop-stairs"] = {
  tries: 150,
  world: 3,
  chapter: "Repeat",
  idea: "One small pattern, repeated. A loop says it once.",
  build: (r) =>
    patterned(r, {
      bodies: ["stairs", "stairs-left"],
      rounds: [4, 6],
      runs: [0, 0],
      commands: WITH_REPEAT,
    }),
  accept: loopLevel,
};
FAMILIES["loop-steps"] = {
  tries: 150,
  world: 3,
  chapter: "Patterns",
  idea: "A longer pattern, repeated.",
  build: (r) =>
    patterned(r, {
      bodies: ["wide", "steep", "long-step"],
      rounds: [3, 5],
      runs: [0, 0],
      commands: WITH_REPEAT,
    }),
  accept: loopLevel,
};
FAMILIES["loop-glue"] = {
  tries: 150,
  world: 3,
  chapter: "Patterns",
  idea: "A run, a pattern, a run: loops and the moves between them.",
  build: (r) =>
    patterned(r, {
      bodies: ["stairs", "wide", "steep", "stairs-left"],
      rounds: [3, 4],
      runs: [2, 4],
      commands: WITH_REPEAT,
    }),
  accept: (m, meta) => loopLevel(m, meta) && m.par >= 9,
};
FAMILIES["loop-hook"] = {
  tries: 150,
  world: 3,
  chapter: "Patterns",
  idea: "A hook pattern that doubles back, repeated.",
  build: (r) =>
    patterned(r, { bodies: ["hook"], rounds: [2, 3], runs: [0, 1], commands: WITH_REPEAT }),
  accept: loopLevel,
};
