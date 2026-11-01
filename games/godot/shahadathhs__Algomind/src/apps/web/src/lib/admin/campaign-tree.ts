import type { AdminCampaign, LevelSummary } from "./admin-api";
import { moveItem } from "./list-ops";

export type Tree = AdminCampaign;

/** The order the API stores: every world and chapter once, with each chapter's levels in order. */
export function orderBody(tree: Tree) {
  return {
    worlds: tree.worlds.map((w) => ({
      id: w.id,
      chapters: w.chapters.map((c) => ({ id: c.id, levels: c.levels.map((l) => l.id) })),
    })),
  };
}

export function moveWorld(tree: Tree, from: number, to: number): Tree {
  return { ...tree, worlds: moveItem(tree.worlds, from, to) };
}

export function moveChapter(tree: Tree, wi: number, from: number, to: number): Tree {
  return {
    ...tree,
    worlds: tree.worlds.map((w, i) =>
      i === wi ? { ...w, chapters: moveItem(w.chapters, from, to) } : w,
    ),
  };
}

export function moveLevel(tree: Tree, wi: number, ci: number, from: number, to: number): Tree {
  return {
    ...tree,
    worlds: tree.worlds.map((w, i) =>
      i !== wi
        ? w
        : {
            ...w,
            chapters: w.chapters.map((c, j) =>
              j === ci ? { ...c, levels: moveItem(c.levels, from, to) } : c,
            ),
          },
    ),
  };
}

/** Moves a level to the end of another chapter (or to unassigned when chapterId is empty). */
export function assignLevel(tree: Tree, level: LevelSummary, chapterId: string): Tree {
  const stripped = tree.worlds.map((w) => ({
    ...w,
    chapters: w.chapters.map((c) => ({ ...c, levels: c.levels.filter((l) => l.id !== level.id) })),
  }));
  const unassigned = tree.unassigned.filter((l) => l.id !== level.id);
  if (!chapterId) return { worlds: stripped, unassigned: [...unassigned, level] };
  return {
    worlds: stripped.map((w) => ({
      ...w,
      chapters: w.chapters.map((c) =>
        c.id === chapterId ? { ...c, levels: [...c.levels, level] } : c,
      ),
    })),
    unassigned,
  };
}

/** Every chapter as a "World / Chapter" choice for the Place in menu. */
export function chapterChoices(tree: Tree): { id: string; label: string }[] {
  return tree.worlds.flatMap((w) =>
    w.chapters.map((c) => ({ id: c.id, label: `${w.title} / ${c.title}` })),
  );
}
