import { randomUUID } from "node:crypto";
import { Injectable } from "@nestjs/common";
import { SCHEMA_VERSION } from "@algomind/level-contract";
import type { Prisma } from "../../generated/prisma/client.js";
import { conflict, isUniqueViolation, notFound, unprocessable } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AuditService } from "../audit/audit.service.js";
import { analyzeLevel, contentHash } from "./level-analysis.js";
import { type Json, requireLevel, schemaVersionOf, stamp } from "./level-helpers.js";
import type { ExportEnvelope, LevelView } from "./levels.schemas.js";
import { LevelsReadService } from "./levels-read.service.js";

@Injectable()
export class LevelsTransferService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly read: LevelsReadService,
  ) {}

  async export(id: string, versionId?: string): Promise<ExportEnvelope> {
    const level = await requireLevel(this.prisma, id);
    const version = versionId
      ? await this.prisma.levelVersion.findFirst({ where: { id: versionId, levelId: id } })
      : ((await this.prisma.levelVersion.findFirst({ where: { levelId: id, state: "DRAFT" } })) ??
        (level.currentPublishedVersionId
          ? await this.prisma.levelVersion.findUnique({
              where: { id: level.currentPublishedVersionId },
            })
          : null) ??
        (await this.prisma.levelVersion.findFirst({
          where: { levelId: id },
          orderBy: { versionNumber: "desc" },
        })));
    if (!version) throw notFound("The version");
    const analysis = analyzeLevel(version.content, version.referenceSolution);
    if (analysis.errors.length > 0) {
      throw unprocessable(
        "LEVEL_VALIDATION_FAILED",
        "Only a valid level can be exported.",
        analysis.errors,
      );
    }
    const content = version.content as Json;
    return {
      format: "algomind-level",
      schemaVersion: schemaVersionOf(content),
      exportedAt: new Date().toISOString(),
      meta: { title: String(content.title), slug: String(content.slug) },
      level: content,
      referenceSolution: version.referenceSolution as unknown[],
    };
  }

  async import(
    envelope: { schemaVersion: number; level: Json; referenceSolution: unknown[] },
    slugOverride: string | undefined,
    userId: string,
  ): Promise<LevelView> {
    if (envelope.schemaVersion !== SCHEMA_VERSION) {
      throw unprocessable(
        "UNSUPPORTED_SCHEMA_VERSION",
        `This API reads schema version ${SCHEMA_VERSION}; the file has ${envelope.schemaVersion}.`,
        [
          {
            path: "schemaVersion",
            code: "UNSUPPORTED_SCHEMA_VERSION",
            message: `Only schema version ${SCHEMA_VERSION} is supported.`,
          },
        ],
      );
    }
    const slug = slugOverride ?? envelope.level.slug;
    if (typeof slug === "string" && (await this.prisma.level.findUnique({ where: { slug } }))) {
      throw conflict(
        "SLUG_TAKEN",
        `A level with the slug "${slug}" already exists. Import again with a different slug.`,
      );
    }
    const id = randomUUID();
    const content = stamp(
      { ...envelope.level },
      { id, slug: typeof slug === "string" ? slug : "" },
      1,
    );
    const analysis = analyzeLevel(content, envelope.referenceSolution);
    if (analysis.errors.length > 0) {
      throw unprocessable(
        "LEVEL_VALIDATION_FAILED",
        "The file does not contain a valid level.",
        analysis.errors,
      );
    }
    const level = analysis.level!;
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.level.create({
          data: {
            id,
            slug: level.slug,
            title: level.title,
            difficulty: level.difficulty,
            createdBy: userId,
            updatedBy: userId,
          },
        });
        await tx.levelVersion.create({
          data: {
            levelId: id,
            versionNumber: 1,
            schemaVersion: level.schemaVersion,
            content: content as Prisma.InputJsonObject,
            referenceSolution: envelope.referenceSolution as Prisma.InputJsonArray,
            contentHash: contentHash(content),
            createdBy: userId,
          },
        });
        await this.audit.record(tx, {
          userId,
          action: "LEVEL_IMPORTED",
          entityType: "level",
          entityId: id,
          detail: { slug: level.slug, title: level.title },
        });
      });
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw conflict("SLUG_TAKEN", `A level with the slug "${level.slug}" already exists.`);
      }
      throw error;
    }
    return this.read.get(id);
  }
}
