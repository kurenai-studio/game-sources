// Measures a level with the real solver, plus the numbers that make a puzzle interesting.
import { solve } from "../../packages/level-contract/dist/index.js";
import { DELTA } from "./board.mjs";
import { DIRECTIONS } from "./directions.mjs";

const MOVE_WEIGHT = 1000;

/** Fewest moves over all routes, then fewest turns among those. The "obvious" shortest route. */
function fewestMovesRoute(level) {
  const { width, height } = level.board;
  const walls = new Set(level.board.walls.map(([x, y]) => `${x},${y}`));
  const [gx, gy] = level.goal.position;
  const start = level.initialState;
  const key = (x, y, d) => `${x},${y},${d}`;
  const best = new Map([[key(start.position[0], start.position[1], start.direction), 0]]);
  // Dijkstra with small integer costs: a move is 1000, a turn is 1, so moves are minimised first.
  const buckets = new Map([[0, [[start.position[0], start.position[1], start.direction]]]]);
  const turnable = level.availableCommands;
  for (let cost = 0; cost < 1000 * (width * height); cost += 1) {
    const here = buckets.get(cost);
    if (!here) {
      if (cost > 1000 * width * height) break;
      continue;
    }
    for (const [x, y, d] of here) {
      if (best.get(key(x, y, d)) !== cost) continue;
      if (x === gx && y === gy)
        return { moves: Math.floor(cost / MOVE_WEIGHT), turns: cost % MOVE_WEIGHT };
      const next = [];
      if (turnable.includes("MOVE_FORWARD")) {
        const [dx, dy] = DELTA[d];
        const nx = x + dx;
        const ny = y + dy;
        if (nx >= 0 && ny >= 0 && nx < width && ny < height && !walls.has(`${nx},${ny}`)) {
          next.push([nx, ny, d, MOVE_WEIGHT]);
        }
      }
      const i = DIRECTIONS.indexOf(d);
      if (turnable.includes("TURN_LEFT")) next.push([x, y, DIRECTIONS[(i + 3) % 4], 1]);
      if (turnable.includes("TURN_RIGHT")) next.push([x, y, DIRECTIONS[(i + 1) % 4], 1]);
      for (const [nx, ny, nd, w] of next) {
        const k = key(nx, ny, nd);
        if (cost + w < (best.get(k) ?? Infinity)) {
          best.set(k, cost + w);
          if (!buckets.has(cost + w)) buckets.set(cost + w, []);
          buckets.get(cost + w).push([nx, ny, nd]);
        }
      }
    }
  }
  return null;
}

/** How many different shortest programs there are (a state graph path count). */
function countShortest(level) {
  const { width, height } = level.board;
  const walls = new Set(level.board.walls.map(([x, y]) => `${x},${y}`));
  const [gx, gy] = level.goal.position;
  const start = level.initialState;
  const key = (x, y, d) => `${x},${y},${d}`;
  const dist = new Map([[key(start.position[0], start.position[1], start.direction), 0]]);
  const ways = new Map([[key(start.position[0], start.position[1], start.direction), 1]]);
  let frontier = [[start.position[0], start.position[1], start.direction]];
  let total = 0;
  for (let depth = 0; frontier.length > 0 && total === 0; depth += 1) {
    const next = [];
    for (const [x, y, d] of frontier) {
      const w = ways.get(key(x, y, d));
      const options = [];
      if (level.availableCommands.includes("MOVE_FORWARD")) {
        const [dx, dy] = DELTA[d];
        const nx = x + dx;
        const ny = y + dy;
        if (nx >= 0 && ny >= 0 && nx < width && ny < height && !walls.has(`${nx},${ny}`)) {
          options.push([nx, ny, d]);
        }
      }
      const i = DIRECTIONS.indexOf(d);
      if (level.availableCommands.includes("TURN_LEFT"))
        options.push([x, y, DIRECTIONS[(i + 3) % 4]]);
      if (level.availableCommands.includes("TURN_RIGHT"))
        options.push([x, y, DIRECTIONS[(i + 1) % 4]]);
      for (const [nx, ny, nd] of options) {
        const k = key(nx, ny, nd);
        if (!dist.has(k)) {
          dist.set(k, depth + 1);
          ways.set(k, 0);
          next.push([nx, ny, nd]);
        }
        if (dist.get(k) === depth + 1) ways.set(k, ways.get(k) + w);
      }
    }
    for (const [x, y, d] of next) if (x === gx && y === gy) total += ways.get(key(x, y, d));
    frontier = next;
  }
  return total;
}

function deadEnds(level) {
  const { width, height } = level.board;
  const walls = new Set(level.board.walls.map(([x, y]) => `${x},${y}`));
  const special = new Set([level.initialState.position.join(","), level.goal.position.join(",")]);
  let count = 0;
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      if (walls.has(`${x},${y}`) || special.has(`${x},${y}`)) continue;
      let open = 0;
      for (const [dx, dy] of Object.values(DELTA)) {
        const nx = x + dx;
        const ny = y + dy;
        if (nx >= 0 && ny >= 0 && nx < width && ny < height && !walls.has(`${nx},${ny}`)) open += 1;
      }
      if (open <= 1) count += 1;
    }
  }
  return count;
}

/** The numbers for one level, or null when the goal cannot be reached. */
export function measure(level) {
  const solved = solve(level);
  if (!solved) return null;
  const isLoop = (c) => c === "REPEAT" || c === "REPEAT_UNTIL";
  const loops = level.availableCommands.some(isLoop);
  // Without a loop the shortest program is the flat one; with one, flat par is searched separately.
  const flat = loops
    ? solve({ ...level, availableCommands: level.availableCommands.filter((c) => !isLoop(c)) })
    : solved;
  const moves = solved.program.filter((n) => n.op === "MOVE_FORWARD").length;
  // Wall cost is a flat-program idea; the loop solver is slower and the number is not needed.
  const open = loops ? null : solve({ ...level, board: { ...level.board, walls: [] } });
  const obvious = fewestMovesRoute(level);
  const floor = level.board.width * level.board.height - level.board.walls.length;
  return {
    par: solved.commands,
    // The shortest program that does not use REPEAT, and how many times longer it is than par.
    flatPar: flat ? flat.commands : null,
    loops,
    moves,
    turns: solved.commands - moves,
    // Commands lost to walls: par here against par on the same board with no walls.
    excess: open ? solved.commands - open.commands : 0,
    // Commands the fewest-moves route costs above par. Above zero means the obvious route is not cheapest.
    decoy: obvious ? obvious.moves + obvious.turns - solved.commands : 0,
    // What the fewest-moves route costs as a program (null when the goal cannot be reached).
    obviousCost: obvious ? obvious.moves + obvious.turns : null,
    optimalPrograms: countShortest(level),
    deadEnds: deadEnds(level),
    walls: level.board.walls.length,
    floor,
    size: `${level.board.width}x${level.board.height}`,
  };
}
