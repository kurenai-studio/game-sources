import { Prisma } from "../../generated/prisma/client.js";
import type { PrismaService } from "../../core/prisma/prisma.service.js";
import type { BoardEntry, BoardView } from "./leaderboards.schemas.js";

type Row = {
  rank: bigint;
  total: bigint;
  publicId: string;
  displayName: string | null;
  hideName: boolean;
  points: number | null;
  slots: number | null;
  steps: number | null;
};

/** Players who may appear: opted in, not hidden by an admin, active, and a player. */
const VISIBLE = Prisma.sql`u."leaderboardOptIn" AND NOT u."leaderboardHidden" AND u."status" = 'ACTIVE' AND u."role" = 'PLAYER'`;

function toEntry(row: Row, me: string | null): BoardEntry {
  return {
    rank: Number(row.rank),
    publicId: row.publicId,
    name: row.hideName || !row.displayName ? "Anonymous" : row.displayName,
    ...(row.points !== null ? { points: row.points } : {}),
    ...(row.slots !== null ? { slots: row.slots, steps: row.steps ?? 0 } : {}),
    you: row.publicId === me,
  };
}

/**
 * Runs a ranked query (a CTE named `ranked` with rank and total columns) and returns the page
 * asked for, plus the signed-in player's row with the two rows either side of it.
 */
async function page(
  prisma: PrismaService,
  ranked: Prisma.Sql,
  paging: { limit: number; offset: number },
  me: string | null,
): Promise<BoardView> {
  const mine = me ?? "";
  const rows = await prisma.$queryRaw<Row[]>`
    ${ranked}
    SELECT * FROM ranked
    WHERE (rank > ${paging.offset} AND rank <= ${paging.offset + paging.limit})
       OR rank BETWEEN (SELECT rank FROM ranked WHERE "publicId" = ${mine}) - 2
                   AND (SELECT rank FROM ranked WHERE "publicId" = ${mine}) + 2
    ORDER BY rank`;
  const total = rows[0] ? Number(rows[0].total) : 0;
  const entries = rows
    .filter((r) => Number(r.rank) > paging.offset && Number(r.rank) <= paging.offset + paging.limit)
    .map((r) => toEntry(r, me));
  const mineRow = rows.find((r) => r.publicId === mine);
  if (!mineRow) return { total, entries, me: null };
  const rank = Number(mineRow.rank);
  return {
    total,
    entries,
    me: {
      entry: toEntry(mineRow, me),
      around: rows.filter((r) => Math.abs(Number(r.rank) - rank) <= 2).map((r) => toEntry(r, me)),
    },
  };
}

/** Points earned in [from, to): ties go to whoever reached the total first. */
export function pointsBoard(
  prisma: PrismaService,
  range: { from: Date; to: Date },
  paging: { limit: number; offset: number },
  me: string | null,
): Promise<BoardView> {
  const ranked = Prisma.sql`WITH totals AS (
      SELECT u."publicId", u."displayName", u."hideName",
             SUM(l."delta")::int AS points, MAX(l."createdAt") AS last_at
      FROM "PointsLedger" l JOIN "User" u ON u."id" = l."userId"
      WHERE ${VISIBLE} AND l."createdAt" >= ${range.from} AND l."createdAt" < ${range.to}
      GROUP BY u."id" HAVING SUM(l."delta") > 0
    ), ranked AS (
      SELECT t.*, NULL::int AS slots, NULL::int AS steps,
             ROW_NUMBER() OVER (ORDER BY points DESC, last_at ASC, "publicId") AS rank,
             COUNT(*) OVER () AS total
      FROM totals t
    )`;
  return page(prisma, ranked, paging, me);
}

/** A level's board: each player's best result on the current published version. */
export function levelBoard(
  prisma: PrismaService,
  slug: string,
  paging: { limit: number; offset: number },
  me: string | null,
): Promise<BoardView> {
  const ranked = Prisma.sql`WITH best AS (
      SELECT DISTINCT ON (s."userId") s."userId", s."slots", s."steps", s."createdAt"
      FROM "Submission" s JOIN "LevelVersion" v ON v."id" = s."levelVersionId"
      WHERE s."levelSlug" = ${slug} AND v."state" = 'PUBLISHED'
      ORDER BY s."userId", s."slots", s."steps", s."createdAt"
    ), ranked AS (
      SELECT u."publicId", u."displayName", u."hideName", NULL::int AS points, b."slots", b."steps",
             ROW_NUMBER() OVER (ORDER BY b."slots", b."steps", b."createdAt", u."publicId") AS rank,
             COUNT(*) OVER () AS total
      FROM best b JOIN "User" u ON u."id" = b."userId"
      WHERE ${VISIBLE}
    )`;
  return page(prisma, ranked, paging, me);
}

/** One day's challenge board: fewest slots, then fewest steps, then earliest. */
export function dailyBoard(
  prisma: PrismaService,
  date: string,
  paging: { limit: number; offset: number },
  me: string | null,
): Promise<BoardView> {
  const ranked = Prisma.sql`WITH ranked AS (
      SELECT u."publicId", u."displayName", u."hideName", NULL::int AS points, r."slots", r."steps",
             ROW_NUMBER() OVER (ORDER BY r."slots", r."steps", r."createdAt", u."publicId") AS rank,
             COUNT(*) OVER () AS total
      FROM "DailyResult" r JOIN "User" u ON u."id" = r."userId"
      WHERE r."date" = ${date} AND ${VISIBLE}
    )`;
  return page(prisma, ranked, paging, me);
}
