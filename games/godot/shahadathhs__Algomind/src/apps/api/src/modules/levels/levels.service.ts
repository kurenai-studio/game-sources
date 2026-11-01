import { randomUUID } from "node:crypto";
import { Injectable } from "@nestjs/common";
import { Prisma } from "../../generated/prisma/client.js";
import type { Level, LevelVersion } from "../../generated/prisma/client.js";
import { conflict, isUniqueViolation, notFound, unprocessable } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AuditService } from "../audit/audit.service.js";
import { contentHash } from "./level-analysis.js";
import {
  type Db,
  type Json,
  lockLevel,
  mirrored,
  requireDraft,
  requireLevel,
  schemaVersionOf,
  SLUG_PATTERN,
  stamp,
  starterContent,
} from "./level-helpers.js";
import type { CreateLevel, LevelView, UpdateDraft } from "./levels.schemas.js";
import { LevelsReadService } from "./levels-read.service.js";

@Injectable()
export class LevelsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly read: LevelsReadService,
  ) {}

  async create(input: CreateLevel, userId: string): Promise<LevelView> {
    const id = randomUUID();
    const base = { ...starterContent(input.title, input.difficulty), ...input.content };
    const content = stamp({ ...base, title: input.title }, { id, slug: input.slug }, 1);
    const referenceSolution = input.referenceSolution ?? [];
    try {
      await this.prisma.$transaction(async (tx) => {
        const level = await tx.level.create({
          data: {
            id,
            slug: input.slug,
            title: input.title,
            difficulty: input.difficulty,
            createdBy: userId,
            updatedBy: userId,
          },
        });
        await tx.levelVersion.create({
          data: {
            levelId: level.id,
            versionNumber: 1,
            schemaVersion: schemaVersionOf(content),
            content: content as Prisma.InputJsonObject,
            referenceSolution: referenceSolution as Prisma.InputJsonArray,
            contentHash: contentHash(content),
            createdBy: userId,
          },
        });
        await tx.level.update({
          where: { id },
          data: mirrored(content, level),
        });
      });
    } catch (error) {
      if (isUniqueViolation(error))
        throw conflict("SLUG_TAKEN", `The slug "${input.slug}" is already used.`);
      throw error;
    }
    return this.read.get(id);
  }

  async saveDraft(id: string, input: UpdateDraft, userId: string): Promise<LevelView> {
    const expected = new Date(input.expectedUpdatedAt);
    try {
      await this.prisma.$transaction(async (tx) => {
        const level = await requireLevel(tx, id);
        const draft = await requireDraft(tx, id);
        if (draft.updatedAt.getTime() !== expected.getTime()) {
          throw conflict(
            "DRAFT_CONFLICT",
            "The draft was changed since you loaded it. Reload to see the latest version.",
          );
        }
        const incoming = (input.content ?? (draft.content as Json)) as Json;
        const requested = incoming.slug;
        let slugValue = level.slug;
        if (typeof requested === "string" && requested !== level.slug) {
          if (SLUG_PATTERN.test(requested) && requested.length <= 64) {
            const everPublished = await tx.levelVersion.count({
              where: { levelId: id, state: { in: ["PUBLISHED", "SUPERSEDED"] } },
            });
            if (everPublished > 0) {
              throw unprocessable("SLUG_LOCKED", "The slug of a published level cannot change.", [
                {
                  path: "content.slug",
                  code: "SLUG_LOCKED",
                  message: "The slug of a level that has been published cannot change.",
                },
              ]);
            }
            slugValue = requested;
          }
        }
        const content = stamp({ ...incoming }, { id, slug: slugValue }, draft.versionNumber);
        // An invalid slug typed by the author stays visible to validate.
        if (typeof requested === "string" && !SLUG_PATTERN.test(requested))
          content.slug = requested;
        const written = await tx.levelVersion.updateMany({
          where: { id: draft.id, state: "DRAFT", updatedAt: expected },
          data: {
            schemaVersion: schemaVersionOf(content),
            content: content as Prisma.InputJsonObject,
            referenceSolution: (input.referenceSolution ??
              (draft.referenceSolution as unknown[])) as Prisma.InputJsonArray,
            contentHash: contentHash(content),
            par: Prisma.DbNull,
            validationSummary: Prisma.DbNull,
          },
        });
        if (written.count === 0) {
          throw conflict("DRAFT_CONFLICT", "The draft was changed since you loaded it.");
        }
        await tx.level.update({
          where: { id },
          data: { slug: slugValue, updatedBy: userId, ...mirrored(content, level) },
        });
      });
    } catch (error) {
      if (isUniqueViolation(error))
        throw conflict("SLUG_TAKEN", "That slug is already used by another level.");
      throw error;
    }
    return this.read.get(id);
  }

  /** Starts a new draft from a published or earlier version. */
  private async startDraft(
    tx: Db,
    level: Level,
    source: LevelVersion,
    userId: string,
  ): Promise<LevelVersion> {
    if (await tx.levelVersion.findFirst({ where: { levelId: level.id, state: "DRAFT" } })) {
      throw conflict("DRAFT_EXISTS", "The level already has a draft. Discard it first.");
    }
    const latest = await tx.levelVersion.aggregate({
      where: { levelId: level.id },
      _max: { versionNumber: true },
    });
    const versionNumber = (latest._max.versionNumber ?? 0) + 1;
    const content = stamp(source.content as Json, level, versionNumber);
    try {
      return await tx.levelVersion.create({
        data: {
          levelId: level.id,
          versionNumber,
          schemaVersion: source.schemaVersion,
          content: content as Prisma.InputJsonObject,
          referenceSolution: source.referenceSolution as Prisma.InputJsonArray,
          contentHash: contentHash(content),
          createdBy: userId,
        },
      });
    } catch (error) {
      if (isUniqueViolation(error))
        throw conflict("DRAFT_EXISTS", "The level already has a draft.");
      throw error;
    }
  }

  async createDraft(id: string, userId: string): Promise<LevelView> {
    await this.prisma.$transaction(async (tx) => {
      await lockLevel(tx, id);
      const level = await requireLevel(tx, id);
      const source =
        (level.currentPublishedVersionId
          ? await tx.levelVersion.findUnique({ where: { id: level.currentPublishedVersionId } })
          : null) ??
        (await tx.levelVersion.findFirst({
          where: { levelId: id },
          orderBy: { versionNumber: "desc" },
        }));
      if (!source) throw conflict("NO_VERSION", "The level has no version to copy.");
      await this.startDraft(tx, level, source, userId);
      await tx.level.update({ where: { id }, data: { updatedBy: userId } });
    });
    return this.read.get(id);
  }

  async restore(id: string, versionId: string, userId: string): Promise<LevelView> {
    await this.prisma.$transaction(async (tx) => {
      await lockLevel(tx, id);
      const level = await requireLevel(tx, id);
      const source = await tx.levelVersion.findFirst({ where: { id: versionId, levelId: id } });
      if (!source) throw notFound("The version");
      const draft = await this.startDraft(tx, level, source, userId);
      await tx.level.update({
        where: { id },
        data: { updatedBy: userId, ...mirrored(draft.content as Json, level) },
      });
      await this.audit.record(tx, {
        userId,
        action: "LEVEL_RESTORED",
        entityType: "level",
        entityId: id,
        detail: {
          slug: level.slug,
          restoredVersionId: source.id,
          restoredVersionNumber: source.versionNumber,
          newDraftVersionNumber: draft.versionNumber,
        },
      });
    });
    return this.read.get(id);
  }

  async discardDraft(id: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      await lockLevel(tx, id);
      const draft = await requireDraft(tx, id);
      const history = await tx.levelVersion.count({
        where: { levelId: id, state: { in: ["PUBLISHED", "SUPERSEDED"] } },
      });
      if (history === 0) {
        throw conflict(
          "NEVER_PUBLISHED",
          "A level that was never published has no earlier version; delete the level instead.",
        );
      }
      await tx.levelVersion.delete({ where: { id: draft.id } });
      const remaining = await tx.levelVersion.findFirst({
        where: { levelId: id },
        orderBy: { versionNumber: "desc" },
      });
      const level = await requireLevel(tx, id);
      if (remaining) {
        await tx.level.update({ where: { id }, data: mirrored(remaining.content as Json, level) });
      }
    });
  }

  async deleteLevel(id: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      await lockLevel(tx, id);
      const history = await tx.levelVersion.count({
        where: { levelId: id, state: { in: ["PUBLISHED", "SUPERSEDED"] } },
      });
      if (history > 0) {
        throw conflict(
          "HAS_HISTORY",
          "A level that has been published cannot be deleted. Unpublish and archive it instead.",
        );
      }
      await tx.level.delete({ where: { id } });
    });
  }

  async duplicate(
    id: string,
    input: { slug?: string; title?: string },
    userId: string,
  ): Promise<LevelView> {
    const source = await requireLevel(this.prisma, id);
    const version =
      (await this.prisma.levelVersion.findFirst({ where: { levelId: id, state: "DRAFT" } })) ??
      (source.currentPublishedVersionId
        ? await this.prisma.levelVersion.findUnique({
            where: { id: source.currentPublishedVersionId },
          })
        : null) ??
      (await this.prisma.levelVersion.findFirst({
        where: { levelId: id },
        orderBy: { versionNumber: "desc" },
      }));
    if (!version) throw conflict("NO_VERSION", "The level has no version to copy.");

    let slug = input.slug;
    if (!slug) {
      const root = `${source.slug}-copy`.slice(0, 60);
      slug = root;
      for (let n = 2; await this.prisma.level.findUnique({ where: { slug } }); n += 1) {
        slug = `${root}-${n}`;
      }
    }
    const title = input.title ?? `${source.title} copy`.slice(0, 60);
    const newId = randomUUID();
    const content = stamp({ ...(version.content as Json), title }, { id: newId, slug }, 1);
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.level.create({
          data: {
            id: newId,
            slug,
            title,
            difficulty: mirrored(content, source).difficulty,
            createdBy: userId,
            updatedBy: userId,
          },
        });
        await tx.levelVersion.create({
          data: {
            levelId: newId,
            versionNumber: 1,
            schemaVersion: version.schemaVersion,
            content: content as Prisma.InputJsonObject,
            referenceSolution: version.referenceSolution as Prisma.InputJsonArray,
            contentHash: contentHash(content),
            createdBy: userId,
          },
        });
      });
    } catch (error) {
      if (isUniqueViolation(error))
        throw conflict("SLUG_TAKEN", `The slug "${slug}" is already used.`);
      throw error;
    }
    return this.read.get(newId);
  }
}
