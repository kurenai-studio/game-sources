import type { LevelContent } from "./admin-api";
import { BOARD_MAX, BOARD_MIN } from "./level-model";
import { dropOutside, hasTile } from "./tile-tools";

export type Tool = "wall" | "floor" | "start" | "goal";

function hasWall(content: LevelContent, x: number, y: number): boolean {
  return content.board.walls.some(([wx, wy]) => wx === x && wy === y);
}

/** Applies one board tool to a cell. Returns the same object when nothing changes. */
export function applyTool(content: LevelContent, tool: Tool, x: number, y: number): LevelContent {
  const [sx, sy] = content.initialState.position;
  // A sweep board has no target cell: nothing is ever "the goal".
  const [gx, gy] = content.goal.position ?? [-1, -1];
  const wall = hasWall(content, x, y);
  switch (tool) {
    case "wall": {
      if (wall || hasTile(content, x, y)) return content;
      if ((x === sx && y === sy) || (x === gx && y === gy)) return content;
      return { ...content, board: { ...content.board, walls: [...content.board.walls, [x, y]] } };
    }
    case "floor": {
      if (!wall) return content;
      return {
        ...content,
        board: {
          ...content.board,
          walls: content.board.walls.filter(([wx, wy]) => wx !== x || wy !== y),
        },
      };
    }
    case "start": {
      if (wall || hasTile(content, x, y) || (x === gx && y === gy) || (x === sx && y === sy))
        return content;
      return { ...content, initialState: { ...content.initialState, position: [x, y] } };
    }
    case "goal": {
      if (!content.goal.position) return content;
      if (wall || hasTile(content, x, y) || (x === sx && y === sy) || (x === gx && y === gy))
        return content;
      return { ...content, goal: { ...content.goal, position: [x, y] } };
    }
  }
}

/** Changes the board size. Walls outside the new board are dropped; start and goal are clamped. */
export function resizeBoard(content: LevelContent, width: number, height: number): LevelContent {
  const w = Math.min(BOARD_MAX, Math.max(BOARD_MIN, Math.round(width)));
  const h = Math.min(BOARD_MAX, Math.max(BOARD_MIN, Math.round(height)));
  const inside = ([x, y]: [number, number]) => x < w && y < h;
  const clamp = ([x, y]: [number, number]): [number, number] => [
    Math.min(x, w - 1),
    Math.min(y, h - 1),
  ];
  let start = clamp(content.initialState.position);
  let goal = content.goal.position ? clamp(content.goal.position) : null;
  const walls = content.board.walls
    .filter(inside)
    .filter(
      ([x, y]) => !(x === start[0] && y === start[1]) && !(goal && x === goal[0] && y === goal[1]),
    );
  if (goal && start[0] === goal[0] && start[1] === goal[1]) {
    goal = [w - 1, h - 1];
    if (goal[0] === start[0] && goal[1] === start[1]) start = [0, 0];
  }
  return dropOutside(
    {
      ...content,
      board: { width: w, height: h, walls },
      initialState: { ...content.initialState, position: start },
      goal: goal ? { ...content.goal, position: goal } : content.goal,
    },
    w,
    h,
  );
}
