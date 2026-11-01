import { Injectable } from "@nestjs/common";
import { Prisma } from "../../generated/prisma/client.js";
import type { Level, LevelVersion } from "../../generated/prisma/client.js";
import { conflict, unprocessable } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AuditService } from "../audit/audit.service.js";
import { ClientVersionsService } from "../client-versions/client-versions.service.js";
import { analyzeLevel, contentHash, failedGates, type Analysis } from "./level-analysis.js";
import {
  type Db,
  type Json,
  lockLevel,
  mirrored,
  requireDraft,
  requireLevel,
} from "./level-helpers.js";
import { jsonOrNull } from "./level-views.js";
import type { LevelView, ValidateResponse, ValidationSummary } from "./levels.schemas.js";
import { LevelsReadService } from "./levels-read.service.js";

@Injectable()
export class LevelsPublishService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly clients: ClientVersionsService,
    private readonly read: LevelsReadService,
  ) {}

  private async evaluate(db: Db, level: Level, draft: LevelVersion) {
    const analysis: Analysis = analyzeLevel(draft.content, draft.referenceSolution);
    const hash = contentHash(draft.content);
    const [records, minimum, registry] = await Promise.all([
      db.playtestRecord.findMany({
        where: { levelVersion: { levelId: level.id } },
        select: { contentHash: true, solved: true },
      }),
      this.clients.minimum(),
      this.clients.all(),
    ]);
    const solvedForCurrentContent = records.some((r) => r.solved && r.contentHash === hash);
    const failed = failedGates({
      analysis,
      hasSolvedPlaytest: solvedForCurrentContent,
      chapterId: level.chapterId,
      minimum,
      registry,
    });
    const summary: ValidationSummary = {
      ok: analysis.errors.length === 0,
      errors: analysis.errors,
      warnings: analysis.warnings,
      par: analysis.par,
      referenceSolved: analysis.referenceSolved,
      requiredMechanics: analysis.requiredMechanics,
      contentHash: hash,
      validatedAt: new Date().toISOString(),
    };
    const unsupported = minimum
      ? analysis.requiredMechanics.filter((m) => !minimum.supportedMechanics.includes(m))
      : [];
    return {
      analysis,
      summary,
      failed,
      playtests: { count: records.length, solvedForCurrentContent },
      compatibility: {
        minimumVersion: minimum?.version ?? null,
        unsupportedMechanics: unsupported,
      },
    };
  }

  async validate(id: string): Promise<ValidateResponse> {
    const level = await requireLevel(this.prisma, id);
    const draft = await requireDraft(this.prisma, id);
    const result = await this.evaluate(this.prisma, level, draft);
    // Keep the result with the draft without moving its updatedAt (the editor's save token). A
    // save that raced this call wins: the write only applies to the exact row state we read.
    await this.prisma.levelVersion.updateMany({
      where: { id: draft.id, state: "DRAFT", updatedAt: draft.updatedAt },
      data: {
        par: jsonOrNull(result.analysis.par),
        validationSummary: result.summary as unknown as Prisma.InputJsonObject,
        updatedAt: draft.updatedAt,
      },
    });
    return {
      ...result.summary,
      publish: { ready: result.failed.length === 0, failedGates: result.failed },
      playtests: result.playtests,
      compatibility: result.compatibility,
    };
  }

  async publish(
    id: string,
    userId: string,
  ): Promise<{ level: LevelView; publishedVersionId: string }> {
    const publishedVersionId = await this.prisma.$transaction(async (tx) => {
      await lockLevel(tx, id);
      const level = await requireLevel(tx, id);
      const draft = await requireDraft(tx, id);
      const result = await this.evaluate(tx, level, draft);
      if (result.failed.length > 0) {
        throw unprocessable(
          "PUBLISH_BLOCKED",
          `The level cannot be published: ${result.failed.length} check${result.failed.length === 1 ? "" : "s"} failed.`,
          result.failed,
        );
      }
      const previous = await tx.levelVersion.findFirst({
        where: { levelId: id, state: "PUBLISHED" },
      });
      if (previous) {
        await tx.levelVersion.update({ where: { id: previous.id }, data: { state: "SUPERSEDED" } });
      }
      const now = new Date();
      await tx.levelVersion.update({
        where: { id: draft.id },
        data: {
          state: "PUBLISHED",
          publishedAt: now,
          par: result.analysis.par as Prisma.InputJsonObject,
          validationSummary: result.summary as unknown as Prisma.InputJsonObject,
        },
      });
      await tx.level.update({
        where: { id },
        data: {
          status: "PUBLISHED",
          currentPublishedVersionId: draft.id,
          updatedBy: userId,
          ...mirrored(draft.content as Json, level),
        },
      });
      await this.audit.record(tx, {
        userId,
        action: "LEVEL_PUBLISHED",
        entityType: "level",
        entityId: id,
        detail: {
          slug: level.slug,
          versionId: draft.id,
          versionNumber: draft.versionNumber,
          supersededVersionNumber: previous?.versionNumber ?? null,
          par: result.analysis.par as Prisma.InputJsonObject,
        },
      });
      return draft.id;
    });
    return { level: await this.read.get(id), publishedVersionId };
  }

  async unpublish(id: string, archive: boolean, userId: string): Promise<LevelView> {
    await this.prisma.$transaction(async (tx) => {
      await lockLevel(tx, id);
      const level = await requireLevel(tx, id);
      if (!level.currentPublishedVersionId) {
        throw conflict("NOT_PUBLISHED", "The level is not published.");
      }
      const version = await tx.levelVersion.update({
        where: { id: level.currentPublishedVersionId },
        data: { state: "SUPERSEDED" },
      });
      await tx.level.update({
        where: { id },
        data: {
          currentPublishedVersionId: null,
          status: archive ? "ARCHIVED" : "DRAFT",
          updatedBy: userId,
        },
      });
      const detail = {
        slug: level.slug,
        versionId: version.id,
        versionNumber: version.versionNumber,
      };
      await this.audit.record(tx, {
        userId,
        action: "LEVEL_UNPUBLISHED",
        entityType: "level",
        entityId: id,
        detail,
      });
      if (archive) {
        await this.audit.record(tx, {
          userId,
          action: "LEVEL_ARCHIVED",
          entityType: "level",
          entityId: id,
          detail,
        });
      }
    });
    return this.read.get(id);
  }
}
