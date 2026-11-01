import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../core/prisma/prisma.service.js";

export type LevelStat = {
  slug: string;
  title: string;
  difficulty: string;
  world: string | null;
  chapter: string | null;
  pool: boolean;
  par: number;
  limit: number;
  /** Players with a verified clear of the current published version. */
  solvers: number;
  /** The average of each solver's best slot count. */
  avgSlots: number;
  atPar: number;
  /** Within two slots of par, but not at it. */
  nearPar: number;
};

type Row = Omit<LevelStat, "avgSlots"> & { avgSlots: number | null };

/**
 * How each published level is doing, from verified results only (no tracking: a failed run is
 * never recorded). Only the current published version counts, so versions are never mixed.
 */
@Injectable()
export class LevelStatsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(): Promise<{ items: LevelStat[] }> {
    const rows = await this.prisma.$queryRaw<Row[]>`
      SELECT l."slug", l."title", l."difficulty", l."dailyPool" AS pool,
             w."title" AS world, c."title" AS chapter,
             (v."par"->>'commands')::int AS par,
             (v."content"->'constraints'->>'maxCommands')::int AS "limit",
             COUNT(b."userId")::int AS solvers,
             ROUND(AVG(b."slots")::numeric, 1)::float AS "avgSlots",
             (COUNT(*) FILTER (WHERE b."slots" <= (v."par"->>'commands')::int))::int AS "atPar",
             (COUNT(*) FILTER (WHERE b."slots" > (v."par"->>'commands')::int
                                AND b."slots" <= (v."par"->>'commands')::int + 2))::int AS "nearPar"
      FROM "Level" l
      JOIN "LevelVersion" v ON v."id" = l."currentPublishedVersionId"
      LEFT JOIN "Chapter" c ON c."id" = l."chapterId"
      LEFT JOIN "World" w ON w."id" = c."worldId"
      LEFT JOIN (
        SELECT s."levelVersionId", s."userId", MIN(s."slots") AS slots
        FROM "Submission" s JOIN "User" u ON u."id" = s."userId" AND u."role" = 'PLAYER'
        GROUP BY s."levelVersionId", s."userId"
      ) b ON b."levelVersionId" = v."id"
      WHERE l."status" = 'PUBLISHED'
      GROUP BY l."id", v."id", w."id", c."id"
      ORDER BY w."order" NULLS LAST, c."order" NULLS LAST, l."orderInChapter", l."slug"`;
    return { items: rows.map((row) => ({ ...row, avgSlots: row.avgSlots ?? 0 })) };
  }
}
