import { Injectable } from "@nestjs/common";
import type { Prisma } from "../../generated/prisma/client.js";
import { notFound } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { type Db, requireLevel } from "./level-helpers.js";
import {
  loadPlaytestFacts,
  SUMMARY_INCLUDE,
  toLevelSummary,
  toVersionSummary,
  toVersionView,
} from "./level-views.js";
import type {
  LevelPage,
  LevelView,
  ListLevelsQuery,
  VersionSummary,
  VersionView,
} from "./levels.schemas.js";

@Injectable()
export class LevelsReadService {
  constructor(private readonly prisma: PrismaService) {}

  async list(query: ListLevelsQuery): Promise<LevelPage> {
    const and: Prisma.LevelWhereInput[] = [];
    if (query.q) {
      and.push({
        OR: [
          { title: { contains: query.q, mode: "insensitive" } },
          { slug: { contains: query.q, mode: "insensitive" } },
        ],
      });
    }
    if (query.status) and.push({ status: query.status });
    if (query.difficulty) and.push({ difficulty: query.difficulty });
    if (query.chapterId) and.push({ chapterId: query.chapterId });
    if (query.worldId) and.push({ chapter: { worldId: query.worldId } });
    if (query.unassigned)
      and.push(query.unassigned === "true" ? { chapterId: null } : { chapterId: { not: null } });
    if (query.hasDraft) {
      and.push(
        query.hasDraft === "true"
          ? { versions: { some: { state: "DRAFT" } } }
          : { versions: { none: { state: "DRAFT" } } },
      );
    }
    const where: Prisma.LevelWhereInput = and.length ? { AND: and } : {};
    const [total, rows] = await Promise.all([
      this.prisma.level.count({ where }),
      this.prisma.level.findMany({
        where,
        include: SUMMARY_INCLUDE,
        orderBy: [{ [query.sort]: query.order }, { id: "asc" }],
        skip: (query.page - 1) * query.pageSize,
        take: query.pageSize,
      }),
    ]);
    const facts = await loadPlaytestFacts(
      this.prisma,
      rows.map((r) => r.id),
    );
    return {
      items: rows.map((r) => toLevelSummary(r, facts)),
      total,
      page: query.page,
      pageSize: query.pageSize,
    };
  }

  async get(id: string, db: Db = this.prisma): Promise<LevelView> {
    const row = await db.level.findUnique({ where: { id }, include: SUMMARY_INCLUDE });
    if (!row) throw notFound("The level");
    const [draft, published, records] = await Promise.all([
      db.levelVersion.findFirst({ where: { levelId: id, state: "DRAFT" } }),
      row.currentPublishedVersionId
        ? db.levelVersion.findUnique({ where: { id: row.currentPublishedVersionId } })
        : null,
      db.playtestRecord.findMany({
        where: { levelVersion: { levelId: id } },
        select: { contentHash: true, solved: true },
      }),
    ]);
    const facts = records.map((r) => ({ levelId: id, ...r }));
    return {
      ...toLevelSummary(row, facts),
      currentPublishedVersionId: row.currentPublishedVersionId,
      draft: draft ? toVersionView(draft) : null,
      published: published ? toVersionView(published) : null,
      playtests: {
        count: records.length,
        solvedForCurrentContent:
          !!draft && records.some((r) => r.solved && r.contentHash === draft.contentHash),
      },
    };
  }

  async versions(id: string): Promise<{ items: VersionSummary[] }> {
    await requireLevel(this.prisma, id);
    const rows = await this.prisma.levelVersion.findMany({
      where: { levelId: id },
      orderBy: { versionNumber: "desc" },
    });
    return { items: rows.map(toVersionSummary) };
  }

  async version(id: string, versionId: string): Promise<VersionView> {
    const row = await this.prisma.levelVersion.findFirst({ where: { id: versionId, levelId: id } });
    if (!row) throw notFound("The version");
    return toVersionView(row);
  }
}
