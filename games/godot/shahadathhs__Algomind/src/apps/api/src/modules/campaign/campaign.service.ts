import { Injectable } from "@nestjs/common";
import { conflict, notFound, unprocessable } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AuditService } from "../audit/audit.service.js";
import { loadPlaytestFacts, SUMMARY_INCLUDE, toLevelSummary } from "../levels/level-views.js";
import type { AdminCampaign, ChapterView, OrderBody, WorldView } from "./campaign.schemas.js";

type WorldRow = {
  id: string;
  title: string;
  description: string;
  order: number;
  createdAt: Date;
  updatedAt: Date;
};
type ChapterRow = {
  id: string;
  worldId: string;
  title: string;
  order: number;
  createdAt: Date;
  updatedAt: Date;
};

const toWorld = (w: WorldRow, chapterCount: number): WorldView => ({
  id: w.id,
  title: w.title,
  description: w.description,
  order: w.order,
  chapterCount,
  createdAt: w.createdAt.toISOString(),
  updatedAt: w.updatedAt.toISOString(),
});

const toChapter = (c: ChapterRow, levelCount: number): ChapterView => ({
  id: c.id,
  worldId: c.worldId,
  title: c.title,
  order: c.order,
  levelCount,
  createdAt: c.createdAt.toISOString(),
  updatedAt: c.updatedAt.toISOString(),
});

@Injectable()
export class CampaignService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  // ---- worlds ------------------------------------------------------------------------------

  async listWorlds(): Promise<{ items: WorldView[] }> {
    const rows = await this.prisma.world.findMany({
      orderBy: [{ order: "asc" }, { createdAt: "asc" }],
      include: { _count: { select: { chapters: true } } },
    });
    return { items: rows.map((w) => toWorld(w, w._count.chapters)) };
  }

  async createWorld(input: { title: string; description: string }): Promise<WorldView> {
    const last = await this.prisma.world.aggregate({ _max: { order: true } });
    const row = await this.prisma.world.create({
      data: { ...input, order: (last._max.order ?? -1) + 1 },
    });
    return toWorld(row, 0);
  }

  async updateWorld(
    id: string,
    input: { title?: string; description?: string },
  ): Promise<WorldView> {
    const exists = await this.prisma.world.findUnique({ where: { id }, select: { id: true } });
    if (!exists) throw notFound("The world");
    const row = await this.prisma.world.update({
      where: { id },
      data: input,
      include: { _count: { select: { chapters: true } } },
    });
    return toWorld(row, row._count.chapters);
  }

  async deleteWorld(id: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const world = await tx.world.findUnique({
        where: { id },
        include: { _count: { select: { chapters: true } } },
      });
      if (!world) throw notFound("The world");
      if (world._count.chapters > 0) {
        throw conflict("NOT_EMPTY", "The world still has chapters. Move or delete them first.");
      }
      await tx.world.delete({ where: { id } });
    });
  }

  // ---- chapters ----------------------------------------------------------------------------

  async listChapters(worldId?: string): Promise<{ items: ChapterView[] }> {
    const rows = await this.prisma.chapter.findMany({
      where: worldId ? { worldId } : {},
      orderBy: [{ world: { order: "asc" } }, { order: "asc" }, { createdAt: "asc" }],
      include: { _count: { select: { levels: true } } },
    });
    return { items: rows.map((c) => toChapter(c, c._count.levels)) };
  }

  async createChapter(input: { worldId: string; title: string }): Promise<ChapterView> {
    const world = await this.prisma.world.findUnique({
      where: { id: input.worldId },
      select: { id: true },
    });
    if (!world) {
      throw unprocessable("VALIDATION_FAILED", "The request is invalid.", [
        { path: "worldId", code: "NOT_FOUND", message: "The world does not exist." },
      ]);
    }
    const last = await this.prisma.chapter.aggregate({
      where: { worldId: input.worldId },
      _max: { order: true },
    });
    const row = await this.prisma.chapter.create({
      data: { ...input, order: (last._max.order ?? -1) + 1 },
    });
    return toChapter(row, 0);
  }

  async updateChapter(id: string, input: { title: string }): Promise<ChapterView> {
    const exists = await this.prisma.chapter.findUnique({ where: { id }, select: { id: true } });
    if (!exists) throw notFound("The chapter");
    const row = await this.prisma.chapter.update({
      where: { id },
      data: input,
      include: { _count: { select: { levels: true } } },
    });
    return toChapter(row, row._count.levels);
  }

  async deleteChapter(id: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const chapter = await tx.chapter.findUnique({
        where: { id },
        include: { _count: { select: { levels: true } } },
      });
      if (!chapter) throw notFound("The chapter");
      if (chapter._count.levels > 0) {
        throw conflict("NOT_EMPTY", "The chapter still has levels. Move them first.");
      }
      await tx.chapter.delete({ where: { id } });
    });
  }

  // ---- the tree and its order --------------------------------------------------------------

  async tree(): Promise<AdminCampaign> {
    const [worlds, chapters, levels] = await Promise.all([
      this.prisma.world.findMany({ orderBy: [{ order: "asc" }, { createdAt: "asc" }] }),
      this.prisma.chapter.findMany({ orderBy: [{ order: "asc" }, { createdAt: "asc" }] }),
      this.prisma.level.findMany({
        include: SUMMARY_INCLUDE,
        orderBy: [{ orderInChapter: "asc" }, { createdAt: "asc" }],
      }),
    ]);
    const facts = await loadPlaytestFacts(
      this.prisma,
      levels.map((l) => l.id),
    );
    const summaries = levels.map((l) => ({
      chapterId: l.chapterId,
      summary: toLevelSummary(l, facts),
    }));
    return {
      worlds: worlds.map((w) => ({
        id: w.id,
        title: w.title,
        description: w.description,
        order: w.order,
        createdAt: w.createdAt.toISOString(),
        updatedAt: w.updatedAt.toISOString(),
        chapters: chapters
          .filter((c) => c.worldId === w.id)
          .map((c) => ({
            id: c.id,
            worldId: c.worldId,
            title: c.title,
            order: c.order,
            createdAt: c.createdAt.toISOString(),
            updatedAt: c.updatedAt.toISOString(),
            levels: summaries.filter((s) => s.chapterId === c.id).map((s) => s.summary),
          })),
      })),
      unassigned: summaries.filter((s) => s.chapterId === null).map((s) => s.summary),
    };
  }

  /**
   * Replaces the whole campaign order in one transaction. The request must name every world and
   * every chapter exactly once; levels it lists are assigned in order, the rest become unassigned.
   */
  async reorder(input: OrderBody, userId: string): Promise<AdminCampaign> {
    await this.prisma.$transaction(async (tx) => {
      const [worlds, chapters, levels] = await Promise.all([
        tx.world.findMany(),
        tx.chapter.findMany(),
        tx.level.findMany({
          select: {
            id: true,
            slug: true,
            chapterId: true,
            orderInChapter: true,
            currentPublishedVersionId: true,
            dailyPool: true,
          },
        }),
      ]);

      const problems: { path: string; code: string; message: string }[] = [];
      const seen = (kind: string, path: string, ids: string[], known: Set<string>) => {
        const used = new Set<string>();
        ids.forEach((id, i) => {
          if (!known.has(id)) {
            problems.push({
              path: `${path}[${i}]`,
              code: "UNKNOWN_ID",
              message: `Unknown ${kind} ${id}.`,
            });
          } else if (used.has(id)) {
            problems.push({
              path: `${path}[${i}]`,
              code: "DUPLICATE_ID",
              message: `${kind} ${id} is listed twice.`,
            });
          }
          used.add(id);
        });
        return used;
      };
      const worldIds = seen(
        "world",
        "worlds",
        input.worlds.map((w) => w.id),
        new Set(worlds.map((w) => w.id)),
      );
      const chapterIds = new Set<string>();
      const levelIds = new Set<string>();
      const chapterKnown = new Set(chapters.map((c) => c.id));
      const levelKnown = new Set(levels.map((l) => l.id));
      input.worlds.forEach((w, wi) => {
        const listed = seen(
          "chapter",
          `worlds[${wi}].chapters`,
          w.chapters.map((c) => c.id),
          chapterKnown,
        );
        for (const id of listed) {
          if (chapterIds.has(id)) {
            problems.push({
              path: `worlds[${wi}].chapters`,
              code: "DUPLICATE_ID",
              message: `Chapter ${id} is listed twice.`,
            });
          }
          chapterIds.add(id);
        }
        w.chapters.forEach((c, ci) => {
          const own = seen("level", `worlds[${wi}].chapters[${ci}].levels`, c.levels, levelKnown);
          for (const id of own) {
            if (levelIds.has(id)) {
              problems.push({
                path: `worlds[${wi}].chapters[${ci}].levels`,
                code: "DUPLICATE_ID",
                message: `Level ${id} is listed twice.`,
              });
            }
            levelIds.add(id);
          }
        });
      });
      if (worldIds.size !== worlds.length) {
        problems.push({
          path: "worlds",
          code: "INCOMPLETE",
          message: "Every world must be listed.",
        });
      }
      if (chapterIds.size !== chapters.length) {
        problems.push({
          path: "worlds",
          code: "INCOMPLETE",
          message: "Every chapter must be listed.",
        });
      }
      // A daily-pool level is kept out of the campaign so players meet it only on its day.
      for (const level of levels) {
        if (level.dailyPool && levelIds.has(level.id)) {
          problems.push({
            path: "worlds",
            code: "IN_DAILY_POOL",
            message: `Level ${level.slug} is in the daily pool, so it cannot be placed in a chapter.`,
          });
        }
      }
      if (problems.length > 0) {
        throw unprocessable("INVALID_ORDER", "The campaign order is not valid.", problems);
      }

      const worldOrder = new Map(worlds.map((w) => [w.id, w.order]));
      const chapterState = new Map(chapters.map((c) => [c.id, c]));
      const levelState = new Map(levels.map((l) => [l.id, l]));
      let changedLevels = 0;
      const unassignedPublished: string[] = [];

      for (const [wi, w] of input.worlds.entries()) {
        if (worldOrder.get(w.id) !== wi) {
          await tx.world.update({ where: { id: w.id }, data: { order: wi } });
        }
        for (const [ci, c] of w.chapters.entries()) {
          const current = chapterState.get(c.id)!;
          if (current.worldId !== w.id || current.order !== ci) {
            await tx.chapter.update({ where: { id: c.id }, data: { worldId: w.id, order: ci } });
          }
          for (const [li, levelId] of c.levels.entries()) {
            const level = levelState.get(levelId)!;
            if (level.chapterId !== c.id || level.orderInChapter !== li) {
              await tx.level.update({
                where: { id: levelId },
                data: { chapterId: c.id, orderInChapter: li, updatedBy: userId },
              });
              changedLevels += 1;
            }
          }
        }
      }
      for (const level of levels) {
        if (levelIds.has(level.id) || level.chapterId === null) continue;
        await tx.level.update({
          where: { id: level.id },
          data: { chapterId: null, orderInChapter: 0, updatedBy: userId },
        });
        changedLevels += 1;
        if (level.currentPublishedVersionId) unassignedPublished.push(level.slug);
      }

      await this.audit.record(tx, {
        userId,
        action: "CAMPAIGN_REORDERED",
        entityType: "campaign",
        entityId: "campaign",
        detail: {
          worlds: input.worlds.length,
          chapters: chapters.length,
          levelsAssigned: levelIds.size,
          levelsChanged: changedLevels,
          unassignedPublished,
        },
      });
    });
    return this.tree();
  }
}
