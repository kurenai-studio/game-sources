import type { Goal, LevelContent } from "./admin-api";
import { boardCaseOf, boardCount } from "./board-model";

export const GOAL_LABELS: Record<string, string> = {
  reach_tile: "Reach a tile",
  visit_all: "Visit every cell",
};

/** True for a sweep goal: the run succeeds when every floor cell has been entered. */
export function isSweep(goal: Goal): boolean {
  return goal.type === "visit_all";
}

/** True when the level's own board or any extra board has a sweep goal. */
export function usesSweep(content: LevelContent): boolean {
  return Array.from({ length: boardCount(content) }, (_, i) => boardCaseOf(content, i)).some((b) =>
    isSweep(b.goal),
  );
}

/** The floor (non-wall) cells of a board: what a sweep must visit. */
export function floorCells(board: { width: number; height: number; walls: [number, number][] }) {
  return board.width * board.height - new Set(board.walls.map(([x, y]) => `${x},${y}`)).size;
}

/** Switches a board (viewed as the level's only one) between reaching a tile and sweeping. */
export function setGoalType(content: LevelContent, type: string): LevelContent {
  if (type === content.goal.type) return content;
  if (type === "visit_all") return { ...content, goal: { type } };
  const { width, height, walls } = content.board;
  const [sx, sy] = content.initialState.position;
  // The first free cell from the bottom right that is not a wall and not the start.
  for (let y = height - 1; y >= 0; y--) {
    for (let x = width - 1; x >= 0; x--) {
      const wall = walls.some(([wx, wy]) => wx === x && wy === y);
      if (!wall && !(x === sx && y === sy)) return { ...content, goal: { type, position: [x, y] } };
    }
  }
  return { ...content, goal: { type, position: [sx, sy] } };
}

/** The goal in words, for the publish diff. */
export function goalText(goal: Goal): string {
  return isSweep(goal) ? "Visit every cell" : (goal.position ?? []).join(", ");
}
