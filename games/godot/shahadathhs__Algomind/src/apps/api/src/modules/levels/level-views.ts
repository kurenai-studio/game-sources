import { Prisma } from "../../generated/prisma/client.js";
import type { LevelVersion } from "../../generated/prisma/client.js";
import type {
  LevelSummary,
  Par,
  PlaytestView,
  ValidationSummary,
  VersionSummary,
  VersionView,
} from "./levels.schemas.js";

export const SUMMARY_INCLUDE = {
  chapter: { include: { world: true } },
  currentPublishedVersion: { select: { versionNumber: true, par: true } },
  versions: {
    where: { state: "DRAFT" },
    select: { versionNumber: true, par: true, contentHash: true },
  },
} satisfies Prisma.LevelInclude;

export type LevelRow = Prisma.LevelGetPayload<{ include: typeof SUMMARY_INCLUDE }>;

export type PlaytestFact = { levelId: string; contentHash: string; solved: boolean };

/** A stored par with a stable key order (jsonb does not keep one). */
export function asPar(value: unknown): Par | null {
  if (!value || typeof value !== "object") return null;
  const { commands, steps } = value as Par;
  return { commands, steps };
}

type FactsDb = Prisma.TransactionClient;

/** Every playtest record of the given levels, reduced to what the playtest state needs. */
export async function loadPlaytestFacts(db: FactsDb, levelIds: string[]): Promise<PlaytestFact[]> {
  if (levelIds.length === 0) return [];
  const rows = await db.playtestRecord.findMany({
    where: { levelVersion: { levelId: { in: levelIds } } },
    select: { contentHash: true, solved: true, levelVersion: { select: { levelId: true } } },
  });
  return rows.map((r) => ({
    levelId: r.levelVersion.levelId,
    contentHash: r.contentHash,
    solved: r.solved,
  }));
}

export function toVersionSummary(row: LevelVersion): VersionSummary {
  return {
    id: row.id,
    versionNumber: row.versionNumber,
    schemaVersion: row.schemaVersion,
    state: row.state,
    par: asPar(row.par),
    contentHash: row.contentHash,
    validationSummary: (row.validationSummary ?? null) as ValidationSummary | null,
    createdBy: row.createdBy,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
    publishedAt: row.publishedAt?.toISOString() ?? null,
  };
}

export function toVersionView(row: LevelVersion): VersionView {
  return {
    ...toVersionSummary(row),
    content: row.content as Record<string, unknown>,
    referenceSolution: row.referenceSolution as unknown[],
  };
}

/** The draft's playtest state, given every record of the level. */
export function playtestState(
  draftHash: string,
  records: { contentHash: string; solved: boolean }[],
): NonNullable<LevelSummary["playtestState"]> {
  if (records.length === 0) return "NONE";
  const current = records.filter((r) => r.contentHash === draftHash);
  if (current.length === 0) return "STALE";
  return current.some((r) => r.solved) ? "SOLVED" : "FAILED";
}

export function toLevelSummary(row: LevelRow, facts: PlaytestFact[]): LevelSummary {
  const draft = row.versions[0] ?? null;
  const published = row.currentPublishedVersion;
  const own = facts.filter((f) => f.levelId === row.id);
  return {
    id: row.id,
    slug: row.slug,
    title: row.title,
    difficulty: row.difficulty,
    status: row.status,
    placement: {
      chapterId: row.chapterId,
      chapterTitle: row.chapter?.title ?? null,
      worldId: row.chapter?.worldId ?? null,
      worldTitle: row.chapter?.world.title ?? null,
      orderInChapter: row.orderInChapter,
    },
    publishedVersion: published?.versionNumber ?? null,
    draftVersion: draft?.versionNumber ?? null,
    draftAhead: !!draft && !!published,
    par: asPar(draft?.par ?? published?.par),
    playtestState: draft ? playtestState(draft.contentHash, own) : null,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

export function toPlaytestView(
  row: {
    id: string;
    levelVersionId: string;
    contentHash: string;
    testerName: string;
    solved: boolean;
    commandsUsed: number | null;
    perceivedDifficulty: string | null;
    notes: string;
    createdAt: Date;
    levelVersion: { versionNumber: number };
  },
  currentHash: string | null,
): PlaytestView {
  return {
    id: row.id,
    levelVersionId: row.levelVersionId,
    versionNumber: row.levelVersion.versionNumber,
    contentHash: row.contentHash,
    current: row.contentHash === currentHash,
    testerName: row.testerName,
    solved: row.solved,
    commandsUsed: row.commandsUsed,
    perceivedDifficulty: row.perceivedDifficulty as PlaytestView["perceivedDifficulty"],
    notes: row.notes,
    createdAt: row.createdAt.toISOString(),
  };
}

/** Prisma needs an explicit marker to write SQL NULL into a Json column. */
export function jsonOrNull(value: unknown): Prisma.InputJsonValue | typeof Prisma.DbNull {
  return value === null || value === undefined ? Prisma.DbNull : (value as Prisma.InputJsonValue);
}
