import { apiBaseUrl } from "@/lib/api";
import { type BoardData, type Dir, tilesOf } from "@/lib/board";

/**
 * The published campaign as the public site shows it: worlds, chapters inside a world, and levels
 * inside a chapter, in play order. It is read from the API (`GET /v1/campaign`, then each level's
 * board from `GET /v1/levels/:slug`), so a level appears here the moment it is published from the
 * dashboard. Nothing is bundled: when the API cannot be reached the page says so.
 */
export type Difficulty = "easy" | "medium" | "hard";

export type CampaignLevel = {
  slug: string;
  /** Position in the whole campaign, from 1. */
  number: number;
  title: string;
  difficulty: Difficulty;
  /** The command limit shown to players. */
  maxCommands: number;
  board: BoardData;
  /** How many boards one program must solve (1 unless the level has test boards). */
  boardCount: number;
};

export type Chapter = { id: string; title: string; levels: CampaignLevel[] };

export type World = {
  id: string;
  number: number;
  title: string;
  summary: string;
  chapters: Chapter[];
};

export type CampaignState = { status: "available"; worlds: World[] } | { status: "unavailable" };

export const DIFFICULTY_LABEL: Record<Difficulty, string> = {
  easy: "Easy",
  medium: "Medium",
  hard: "Hard",
};

const REVALIDATE_SECONDS = 60;
const FETCH_TIMEOUT_MS = 8000;
const DIRECTION: Record<string, Dir> = { north: "N", east: "E", south: "S", west: "W" };

type Json = Record<string, unknown>;

function isObject(value: unknown): value is Json {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function point(value: unknown): { x: number; y: number } | null {
  if (!Array.isArray(value) || value.length !== 2) return null;
  const [x, y] = value as unknown[];
  return Number.isInteger(x) && Number.isInteger(y) ? { x: x as number, y: y as number } : null;
}

/** The renderer's board for a published level's content, or null when the content is malformed. */
export function boardFromContent(content: unknown): BoardData | null {
  if (!isObject(content) || !isObject(content.board) || !isObject(content.initialState))
    return null;
  if (!isObject(content.goal)) return null;
  const { width, height, walls } = content.board;
  if (!Number.isInteger(width) || !Number.isInteger(height) || !Array.isArray(walls)) return null;
  const start = point(content.initialState.position);
  const dir = DIRECTION[String(content.initialState.direction)];
  // A sweep board (visit_all) has no target; any other goal needs a position.
  const sweep = content.goal.type === "visit_all";
  const goal = sweep ? undefined : (point(content.goal.position) ?? undefined);
  const wallPoints = walls.map(point);
  if (!start || !dir || (!sweep && !goal) || wallPoints.some((p) => p === null)) return null;
  return {
    width: width as number,
    height: height as number,
    walls: wallPoints as { x: number; y: number }[],
    goal,
    automaton: { ...start, dir },
    ...tilesOf(content),
  };
}

export async function getJson(path: string): Promise<unknown> {
  const res = await fetch(`${apiBaseUrl()}${path}`, {
    headers: { Accept: "application/json" },
    next: { revalidate: REVALIDATE_SECONDS },
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
  });
  if (!res.ok) throw new Error(`${path} answered ${res.status}`);
  return res.json();
}

function difficultyOf(value: unknown): Difficulty {
  return value === "medium" || value === "hard" ? value : "easy";
}

type Boards = { boards: Map<string, BoardData>; boardCounts: Map<string, number> };

function addBoard(into: Boards, slug: string, content: unknown, boardCount: number): void {
  const board = boardFromContent(content);
  if (!board) throw new Error(`Level ${slug} has no readable board`);
  into.boards.set(slug, board);
  into.boardCounts.set(slug, boardCount);
}

/**
 * The board of every level. They come in one request (`/campaign/boards`). An API that does not have
 * that route yet (the site can be deployed before it) is read level by level instead, twelve at a time.
 */
async function readBoards(slugs: string[]): Promise<Boards> {
  const out: Boards = { boards: new Map(), boardCounts: new Map() };
  try {
    const drawn = await getJson("/campaign/boards");
    if (!isObject(drawn) || !Array.isArray(drawn.items)) throw new Error("no boards");
    for (const item of drawn.items as unknown[]) {
      if (!isObject(item) || typeof item.slug !== "string") throw new Error("bad boards");
      addBoard(out, item.slug, item.content, Number(item.boardCount) || 1);
    }
    return out;
  } catch {
    // fall through to the slower way
  }
  let next = 0;
  const runners = Array.from({ length: Math.min(12, slugs.length) }, async () => {
    while (next < slugs.length) {
      const slug = slugs[next++]!;
      const detail = await getJson(`/levels/${encodeURIComponent(slug)}`);
      const content = isObject(detail) ? detail.content : null;
      const extra = isObject(content) ? content.extraBoards : null;
      addBoard(out, slug, content, 1 + (Array.isArray(extra) ? extra.length : 0));
    }
  });
  await Promise.all(runners);
  return out;
}

const MEMORY_MS = 60_000;
let remembered: { at: number; state: CampaignState } | null = null;
let loading: Promise<CampaignState> | null = null;

/**
 * The campaign shown on the site. Reading it takes one request for the tree and one for every level's
 * board, so it is kept in memory for a minute and shared by the pages that ask at the same time. When it
 * is older than that, the page that asks gets the last good copy at once while a fresh one is read, so
 * only the very first visit after a start waits for the API (which may be asleep). Never throws.
 */
export async function getCampaign(): Promise<CampaignState> {
  if (remembered && Date.now() - remembered.at < MEMORY_MS) return remembered.state;
  loading ??= loadCampaign()
    .then((state) => {
      if (state.status === "available") remembered = { at: Date.now(), state };
      return state;
    })
    .finally(() => {
      loading = null;
    });
  return remembered ? remembered.state : loading;
}

/** Reads the campaign from the API. `unavailable` covers any failure or bad data. */
async function loadCampaign(): Promise<CampaignState> {
  try {
    const catalog = await getJson("/campaign");
    if (!isObject(catalog) || !Array.isArray(catalog.worlds)) return { status: "unavailable" };

    const entries: {
      slug: string;
      number: number;
      title: string;
      difficulty: Difficulty;
      maxCommands: number;
    }[] = [];
    for (const world of catalog.worlds as unknown[]) {
      if (!isObject(world) || !Array.isArray(world.chapters)) return { status: "unavailable" };
      for (const chapter of world.chapters as unknown[]) {
        if (!isObject(chapter) || !Array.isArray(chapter.levels)) return { status: "unavailable" };
        for (const level of chapter.levels as unknown[]) {
          if (!isObject(level) || typeof level.slug !== "string") return { status: "unavailable" };
          entries.push({
            slug: level.slug,
            number: entries.length + 1,
            title: String(level.title),
            difficulty: difficultyOf(level.difficulty),
            maxCommands: Number(level.maxCommands),
          });
        }
      }
    }

    const { boards, boardCounts } = await readBoards(entries.map((e) => e.slug));

    const byNumber = new Map(entries.map((e) => [e.slug, e]));
    const worlds: World[] = (catalog.worlds as Json[]).map((world, wi) => ({
      id: String(world.id),
      number: wi + 1,
      title: String(world.title),
      summary: typeof world.description === "string" ? world.description : "",
      chapters: (world.chapters as Json[]).map((chapter) => ({
        id: String(chapter.id),
        title: String(chapter.title),
        levels: (chapter.levels as Json[]).map((level): CampaignLevel => {
          const entry = byNumber.get(String(level.slug))!;
          return {
            ...entry,
            board: boards.get(entry.slug)!,
            boardCount: boardCounts.get(entry.slug) ?? 1,
          };
        }),
      })),
    }));
    return { status: "available", worlds };
  } catch {
    return { status: "unavailable" };
  }
}

export function levelCount(world: World): number {
  return world.chapters.reduce((total, chapter) => total + chapter.levels.length, 0);
}
