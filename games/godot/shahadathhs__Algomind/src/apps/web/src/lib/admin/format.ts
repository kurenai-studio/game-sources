import type { LevelSummary } from "./admin-api";

export const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export const PLAYTEST_LABEL: Record<string, string> = {
  NONE: "None",
  STALE: "Stale",
  FAILED: "Failed",
  SOLVED: "Solved",
};

export function slugify(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60);
}

export function placementText(level: LevelSummary): string {
  const p = level.placement;
  if (!p.chapterId) return "Unassigned";
  return `${p.worldTitle ?? "?"} / ${p.chapterTitle ?? "?"} / ${p.orderInChapter + 1}`;
}

export function when(iso: string): string {
  return new Date(iso).toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" });
}

export function parText(level: LevelSummary): string {
  return level.par ? `${level.par.commands} commands` : "Not set";
}

export function playtestText(level: LevelSummary): string {
  return level.playtestState ? (PLAYTEST_LABEL[level.playtestState] ?? "None") : "No draft";
}
