import { apiBaseUrl } from "@/lib/api";
import type { BoardData } from "@/lib/board";
import { boardFromContent, getJson, type Difficulty } from "@/lib/campaign";

/** A shared result as the public page shows it: the level and the numbers, never a player. */
export type Share = {
  kind: "level" | "daily";
  levelSlug: string;
  title: string;
  difficulty: Difficulty;
  /** UTC date of a daily result, as YYYY-MM-DD. */
  date: string | null;
  slots: number;
  steps: number;
  par: number;
};

export type ShareState =
  { status: "found"; share: Share } | { status: "missing" } | { status: "unavailable" };

const REVALIDATE_SECONDS = 60;
const FETCH_TIMEOUT_MS = 8000;
const CODE = /^[0-9a-z]{8}$/;

function isShare(value: unknown): value is Share {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return (
    (v.kind === "level" || v.kind === "daily") &&
    typeof v.levelSlug === "string" &&
    typeof v.title === "string" &&
    (v.difficulty === "easy" || v.difficulty === "medium" || v.difficulty === "hard") &&
    (v.date === null || typeof v.date === "string") &&
    Number.isInteger(v.slots) &&
    Number.isInteger(v.steps) &&
    Number.isInteger(v.par)
  );
}

/** Reads a share code from the API. Never throws; a code that cannot exist is missing at once. */
export async function getShare(code: string): Promise<ShareState> {
  if (!CODE.test(code)) return { status: "missing" };
  try {
    const res = await fetch(`${apiBaseUrl()}/share/${code}`, {
      headers: { Accept: "application/json" },
      next: { revalidate: REVALIDATE_SECONDS },
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
    });
    if (res.status === 404) return { status: "missing" };
    if (!res.ok) return { status: "unavailable" };
    const body: unknown = await res.json();
    return isShare(body) ? { status: "found", share: body } : { status: "unavailable" };
  } catch {
    return { status: "unavailable" };
  }
}

/** The shared level's board (the puzzle, no solution), or null when it cannot be read. */
export async function getShareBoard(levelSlug: string): Promise<BoardData | null> {
  try {
    const level = await getJson(`/levels/${encodeURIComponent(levelSlug)}`);
    const content =
      typeof level === "object" && level !== null ? (level as { content?: unknown }).content : null;
    return boardFromContent(content);
  } catch {
    return null;
  }
}

/** "20 Oct 2026" for a YYYY-MM-DD date, read as UTC. */
export function shareDate(date: string): string {
  return new Date(`${date}T00:00:00Z`).toLocaleDateString("en", {
    timeZone: "UTC",
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

export function shareCaption(share: Share): string {
  return share.kind === "daily" && share.date ? `Daily, ${shareDate(share.date)}` : "Shared result";
}

const plural = (n: number, word: string) => `${n} ${word}${n === 1 ? "" : "s"}`;

/** "7 commands, par 5, 9 steps". */
export function resultText(share: Share): string {
  return `${plural(share.slots, "command")}, par ${share.par}, ${plural(share.steps, "step")}`;
}

/** A plain note when the result is at or under par; null otherwise. */
export function parNote(share: Share): string | null {
  if (share.slots === share.par) return "This result matches par.";
  if (share.slots < share.par) return "This result is under par.";
  return null;
}
