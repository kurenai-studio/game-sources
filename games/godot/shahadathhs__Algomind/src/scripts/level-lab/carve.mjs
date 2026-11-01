// Builders that carve a board out of solid wall, so the shape of the routes is designed and the
// solver only has to confirm it. The solver is still the judge of every candidate.
import { GLYPH, gridToRows } from "./board.mjs";
import { DIRECTIONS } from "./directions.mjs";
import { DELTA } from "./board.mjs";

const solid = (width, height) => Array.from({ length: height }, () => Array(width).fill("#"));

/** A perfect maze: a spanning tree over the cells at even coordinates (recursive backtracker). */
function spanningTree(r, width, height) {
  const grid = solid(width, height);
  const stack = [[0, 0]];
  grid[0][0] = ".";
  const parent = new Map([["0,0", null]]);
  while (stack.length > 0) {
    const [x, y] = stack[stack.length - 1];
    const options = DIRECTIONS.map((d) => [d, x + DELTA[d][0] * 2, y + DELTA[d][1] * 2]).filter(
      ([, nx, ny]) => nx >= 0 && ny >= 0 && nx < width && ny < height && grid[ny][nx] === "#",
    );
    if (options.length === 0) {
      stack.pop();
      continue;
    }
    const [d, nx, ny] = r.pick(options);
    grid[y + DELTA[d][1]][x + DELTA[d][0]] = ".";
    grid[ny][nx] = ".";
    parent.set(`${nx},${ny}`, [x, y]);
    stack.push([nx, ny]);
  }
  return { grid, parent };
}

/** Tree distance from `from` to every cell, over open cells. */
function distances(grid, from) {
  const height = grid.length;
  const width = grid[0].length;
  const dist = new Map([[from.join(","), 0]]);
  const queue = [from];
  for (let i = 0; i < queue.length; i += 1) {
    const [x, y] = queue[i];
    for (const d of DIRECTIONS) {
      const nx = x + DELTA[d][0];
      const ny = y + DELTA[d][1];
      if (nx < 0 || ny < 0 || nx >= width || ny >= height || grid[ny][nx] !== ".") continue;
      if (dist.has(`${nx},${ny}`)) continue;
      dist.set(`${nx},${ny}`, dist.get(`${x},${y}`) + 1);
      queue.push([nx, ny]);
    }
  }
  return dist;
}

/**
 * A maze with exactly one route: start and goal are two far-apart ends of a spanning tree, so every
 * other branch is a deliberate dead end. `width` and `height` must be odd. The start faces along
 * its only opening, so the first command is never a guess.
 */
export function maze(r, { width, height, commands, reach = 0.8 }) {
  const { grid } = spanningTree(r, width, height);
  const open = [];
  grid.forEach((row, y) => row.forEach((c, x) => c === "." && open.push([x, y])));
  const neighbours = ([x, y]) =>
    DIRECTIONS.filter((d) => grid[y + DELTA[d][1]]?.[x + DELTA[d][0]] === ".");
  const ends = open.filter((cell) => neighbours(cell).length === 1);
  if (ends.length < 3) return null;
  const start = r.pick(ends);
  const dist = distances(grid, start);
  const far = Math.max(...ends.map((e) => dist.get(e.join(","))));
  const goals = ends.filter((e) => e !== start && dist.get(e.join(",")) >= far * reach);
  if (goals.length === 0) return null;
  const goal = r.pick(goals);
  const facing = neighbours(start)[0];
  grid[start[1]][start[0]] = GLYPH[facing];
  grid[goal[1]][goal[0]] = "G";
  return { rows: gridToRows(grid), commands };
}

/** Carves a path through cells in order; false if a cell is outside the grid. */
function carve(grid, cells) {
  for (const [x, y] of cells) {
    if (y < 0 || x < 0 || y >= grid.length || x >= grid[0].length) return false;
    grid[y][x] = ".";
  }
  return true;
}

/** Cells walked from `from` along a list of [direction, steps] runs, including `from`. */
function runs(from, list) {
  const cells = [from];
  let [x, y] = from;
  for (const [dir, steps] of list) {
    for (let i = 0; i < steps; i += 1) {
      x += DELTA[dir][0];
      y += DELTA[dir][1];
      cells.push([x, y]);
    }
  }
  return cells;
}

/**
 * A decoy: two designed routes in solid wall. One is a staircase with the fewest moves but many
 * turns (the obvious route). The other goes the long way round with few turns, and is cheaper as a
 * program. Cells between the two routes stay wall, so there is no shortcut. The goal is reached
 * from the side, so the long way costs `extra` more moves than the staircase.
 */
export function decoy(r, { size, steps, extra, commands }) {
  const grid = solid(size, size);
  // The staircase: north then east, `steps` times, one cell each, from the bottom-left corner.
  const stairs = [];
  for (let i = 0; i < steps; i += 1) stairs.push(["north", r.int(1, 2)], ["east", r.int(1, 2)]);
  const start = [0, size - 1];
  const route = runs(start, stairs);
  const goal = route[route.length - 1];
  // The long way: east along the bottom row past the goal column, north to the goal row, then back
  // west `extra / 2` cells onto the goal. It leaves the staircase's cells alone.
  const overshoot = Math.max(1, Math.round(extra / 2));
  const reachX = goal[0] + overshoot;
  const up = start[1] - goal[1];
  const longWay = runs(start, [
    ["east", reachX - start[0]],
    ["north", up],
    ["west", reachX - goal[0]],
  ]);
  if (reachX >= size) return null;
  if (!carve(grid, route) || !carve(grid, longWay)) return null;
  // The two routes may only meet at the start and the goal, or the staircase has a shortcut.
  const key = (c) => c.join(",");
  const shared = longWay.filter((c) => route.some((s) => key(s) === key(c)));
  if (shared.some((c) => key(c) !== key(start) && key(c) !== key(goal))) return null;
  grid[start[1]][start[0]] = GLYPH[stairs[0][0]];
  grid[goal[1]][goal[0]] = "G";
  return { rows: gridToRows(grid), commands };
}
