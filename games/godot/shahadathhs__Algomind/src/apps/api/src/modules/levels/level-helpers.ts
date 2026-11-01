import { DIFFICULTIES, ID_PATTERN, SCHEMA_VERSION } from "@algomind/level-contract";
import type { Prisma } from "../../generated/prisma/client.js";
import type { Level, LevelVersion } from "../../generated/prisma/client.js";
import { conflict, notFound } from "../../core/http/errors.js";

export type Db = Prisma.TransactionClient;
export type Json = Record<string, unknown>;

export const SLUG_PATTERN = new RegExp(ID_PATTERN);

/** The server owns the identity fields of a version: level id, version number, and slug. */
export function stamp(
  content: Json,
  level: { id: string; slug: string },
  versionNumber: number,
): Json {
  return { ...content, levelId: level.id, levelVersion: versionNumber, slug: level.slug };
}

export function starterContent(title: string, difficulty: string): Json {
  return {
    schemaVersion: SCHEMA_VERSION,
    title,
    description: "",
    difficulty,
    requires: { mechanics: [] },
    board: { width: 5, height: 5, walls: [] },
    initialState: { position: [0, 4], direction: "north" },
    availableCommands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"],
    constraints: { maxCommands: 10, maxSteps: 30 },
    goal: { type: "reach_tile", position: [4, 0] },
    hints: [],
  };
}

export function schemaVersionOf(content: Json): number {
  return Number.isInteger(content.schemaVersion)
    ? (content.schemaVersion as number)
    : SCHEMA_VERSION;
}

/** Title and difficulty mirrored on the level row, when the content carries usable values. */
export function mirrored(content: Json, level: Pick<Level, "title" | "difficulty">) {
  const title = content.title;
  const difficulty = content.difficulty;
  return {
    title:
      typeof title === "string" && title.length >= 1 && Array.from(title).length <= 60
        ? title
        : level.title,
    difficulty:
      typeof difficulty === "string" && (DIFFICULTIES as readonly string[]).includes(difficulty)
        ? difficulty
        : level.difficulty,
  };
}

export async function requireLevel(db: Db, id: string): Promise<Level> {
  const level = await db.level.findUnique({ where: { id } });
  if (!level) throw notFound("The level");
  return level;
}

export async function requireDraft(db: Db, levelId: string): Promise<LevelVersion> {
  const draft = await db.levelVersion.findFirst({ where: { levelId, state: "DRAFT" } });
  if (!draft) {
    throw conflict(
      "NO_DRAFT",
      "The level has no draft. Create one from the current version first.",
    );
  }
  return draft;
}

/** Serializes publishing, unpublishing and draft creation for one level. */
export async function lockLevel(tx: Db, id: string): Promise<void> {
  const rows = await tx.$queryRaw<
    { id: string }[]
  >`SELECT "id" FROM "Level" WHERE "id" = ${id} FOR UPDATE`;
  if (rows.length === 0) throw notFound("The level");
}
