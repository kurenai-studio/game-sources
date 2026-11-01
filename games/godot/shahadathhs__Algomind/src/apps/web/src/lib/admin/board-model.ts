import type { LevelContent } from "./admin-api";

/** One board of a level: its own is board 0, the extra test boards follow. */
export type BoardCase = Pick<LevelContent, "board" | "initialState" | "goal">;

/** The most boards a level has: its own and up to five test boards (the contract's limit). */
export const MAX_BOARDS = 6;

export function boardCount(content: LevelContent): number {
  return 1 + (content.extraBoards?.length ?? 0);
}

export function boardCaseOf(content: LevelContent, index: number): BoardCase {
  const own = { board: content.board, initialState: content.initialState, goal: content.goal };
  return index <= 0 ? own : (content.extraBoards?.[index - 1] ?? own);
}

/** The content as if board `index` were the level's only board, for the board tools and the renderer. */
export function onBoard(content: LevelContent, index: number): LevelContent {
  const { extraBoards: _extra, ...rest } = content;
  return { ...rest, ...boardCaseOf(content, index) };
}

/** Applies an edit made on one board's view back to that board only. */
export function editBoard(
  content: LevelContent,
  index: number,
  edit: (view: LevelContent) => LevelContent,
): LevelContent {
  const view = onBoard(content, index);
  const next = edit(view);
  if (next === view) return content;
  const changed: BoardCase = {
    board: next.board,
    initialState: next.initialState,
    goal: next.goal,
  };
  if (index <= 0) return { ...content, ...changed };
  const extraBoards = (content.extraBoards ?? []).map((b, i) => (i === index - 1 ? changed : b));
  return { ...content, extraBoards };
}

const EMPTY_BOARD: BoardCase = {
  board: { width: 5, height: 3, walls: [] },
  initialState: { position: [0, 1], direction: "east" },
  goal: { type: "reach_tile", position: [4, 1] },
};

/** Adds a test board, a copy of board `copyOf` or an empty one with a start and a goal. */
export function addBoard(content: LevelContent, copyOf: number | null): LevelContent {
  if (boardCount(content) >= MAX_BOARDS) return content;
  const source = copyOf === null ? EMPTY_BOARD : boardCaseOf(content, copyOf);
  const copy: BoardCase = JSON.parse(JSON.stringify(source)) as BoardCase;
  return { ...content, extraBoards: [...(content.extraBoards ?? []), copy] };
}

/** Removes a test board. Board 1, the level's own, cannot be removed. */
export function removeBoard(content: LevelContent, index: number): LevelContent {
  if (index <= 0 || !content.extraBoards?.[index - 1]) return content;
  const { extraBoards, ...rest } = content;
  const left = extraBoards.filter((_, i) => i !== index - 1);
  return left.length > 0 ? { ...rest, extraBoards: left } : rest;
}

/** Names the board an issue path belongs to: "extraBoards[1].goal.position" becomes "Board 3: goal.position". */
export function boardIssuePath(path: string): string {
  const m = /^extraBoards\[(\d+)\]\.?(.*)$/.exec(path);
  if (!m) return path;
  const name = `Board ${Number(m[1]) + 2}`;
  return m[2] ? `${name}: ${m[2]}` : name;
}
