import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { contentHash } from "./level-analysis.js";
import { requireDraft, requireLevel } from "./level-helpers.js";
import { toPlaytestView } from "./level-views.js";
import type { PlaytestBody, PlaytestView } from "./levels.schemas.js";

@Injectable()
export class LevelsPlaytestService {
  constructor(private readonly prisma: PrismaService) {}

  async createPlaytest(id: string, input: PlaytestBody, userId: string): Promise<PlaytestView> {
    await requireLevel(this.prisma, id);
    const draft = await requireDraft(this.prisma, id);
    const row = await this.prisma.playtestRecord.create({
      data: {
        levelVersionId: draft.id,
        contentHash: contentHash(draft.content),
        testerName: input.testerName,
        solved: input.solved,
        commandsUsed: input.commandsUsed ?? null,
        perceivedDifficulty: input.perceivedDifficulty ?? null,
        notes: input.notes,
        createdBy: userId,
      },
      include: { levelVersion: { select: { versionNumber: true } } },
    });
    return toPlaytestView(row, row.contentHash);
  }

  async listPlaytests(id: string): Promise<{ items: PlaytestView[] }> {
    await requireLevel(this.prisma, id);
    const level = await this.prisma.level.findUnique({
      where: { id },
      select: { currentPublishedVersionId: true },
    });
    const reference =
      (await this.prisma.levelVersion.findFirst({ where: { levelId: id, state: "DRAFT" } })) ??
      (level?.currentPublishedVersionId
        ? await this.prisma.levelVersion.findUnique({
            where: { id: level.currentPublishedVersionId },
          })
        : null);
    const rows = await this.prisma.playtestRecord.findMany({
      where: { levelVersion: { levelId: id } },
      orderBy: { createdAt: "desc" },
      include: { levelVersion: { select: { versionNumber: true } } },
    });
    return { items: rows.map((r) => toPlaytestView(r, reference?.contentHash ?? null)) };
  }
}
