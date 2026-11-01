import { Injectable } from "@nestjs/common";
import { scoreResult, type Difficulty } from "@algomind/level-contract";
import type { Prisma } from "../../generated/prisma/client.js";
import { conflict, notFound, unprocessable } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AchievementsService } from "../achievements/achievements.service.js";
import { DailyService } from "../daily/daily.service.js";
import { asPar } from "../levels/level-views.js";
import { PointsRulesService } from "./points-rules.service.js";
import type { PointsView, SubmissionBody, SubmissionResult } from "./points.schemas.js";
import { programHash, verifySubmission } from "./verify-submission.js";

/**
 * Verified submissions and the points ledger. The client sends a program, never a score: the
 * server validates it for the exact level version, runs it, and scores the result. A player's
 * points for a level only ever go up, and only by the amount a better result adds.
 */
@Injectable()
export class SubmissionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly rules: PointsRulesService,
    private readonly daily: DailyService,
    private readonly achievements: AchievementsService,
  ) {}

  async submit(userId: string, input: SubmissionBody): Promise<SubmissionResult> {
    const level = await this.prisma.level.findUnique({ where: { slug: input.levelSlug } });
    const version = level
      ? await this.prisma.levelVersion.findUnique({
          where: {
            levelId_versionNumber: { levelId: level.id, versionNumber: input.levelVersion },
          },
        })
      : null;
    if (!level || !version) throw notFound("The level version");
    // A superseded version still counts while its level is offered; a draft or an unpublished
    // level never does.
    const offered =
      level.status === "PUBLISHED" &&
      (version.state === "PUBLISHED" || version.state === "SUPERSEDED");
    if (!offered) {
      throw conflict("LEVEL_NOT_AVAILABLE", "That level version is not available for scoring.");
    }
    const par = asPar(version.par);
    if (!par) throw conflict("NO_PAR", "The level has no par, so it cannot be scored.");

    const verified = verifySubmission(version.content, input.program);
    if (!verified.ok) {
      const message =
        verified.code === "PROGRAM_DID_NOT_SOLVE"
          ? "The program does not reach the goal, so it is not a submission."
          : "The program is not valid for this level.";
      throw unprocessable(verified.code, message, verified.issues);
    }

    const hash = programHash(input.program);
    const content = version.content as { difficulty: Difficulty };
    const result = await this.prisma.$transaction(async (tx) => {
      // One player's submissions take turns, so two devices cannot both award the same bonus.
      await tx.$queryRaw`SELECT "id" FROM "User" WHERE "id" = ${userId} FOR UPDATE`;
      await tx.user.update({ where: { id: userId }, data: { lastActiveAt: new Date() } });
      const earlier = await tx.submission.findUnique({
        where: {
          userId_levelVersionId_programHash: {
            userId,
            levelVersionId: version.id,
            programHash: hash,
          },
        },
      });
      if (earlier) {
        return {
          duplicate: true,
          verified: { slots: earlier.slots, steps: earlier.steps },
          stars: earlier.stars as 1 | 2 | 3,
          points: earlier.points,
          awarded: 0,
          total: await this.total(tx, userId),
          ruleVersion: earlier.ruleVersion,
          daily: await this.claimDaily(tx, userId, input, version.versionNumber, earlier),
        };
      }
      const rules = await this.rules.active(tx);
      const score = scoreResult(rules, {
        difficulty: content.difficulty,
        par,
        slots: verified.slots,
        steps: verified.steps,
      });
      const submission = await tx.submission.create({
        data: {
          userId,
          levelVersionId: version.id,
          levelSlug: level.slug,
          programHash: hash,
          program: input.program as unknown as Prisma.InputJsonArray,
          slots: verified.slots,
          steps: verified.steps,
          stars: score.stars,
          points: score.levelScore,
          ruleVersion: rules.version,
        },
      });
      const earned = await tx.pointsLedger.aggregate({
        where: { userId, levelSlug: level.slug },
        _sum: { delta: true },
      });
      const before = earned._sum.delta ?? 0;
      const awarded = Math.max(0, score.levelScore - before);
      if (awarded > 0) {
        await tx.pointsLedger.create({
          data: {
            userId,
            reason: before === 0 ? "FIRST_CLEAR" : "IMPROVED_RESULT",
            delta: awarded,
            levelSlug: level.slug,
            levelVersion: version.versionNumber,
            ruleVersion: rules.version,
            submissionId: submission.id,
          },
        });
      }
      return {
        duplicate: false,
        verified: { slots: verified.slots, steps: verified.steps },
        stars: score.stars,
        points: score.levelScore,
        awarded,
        total: await this.total(tx, userId),
        ruleVersion: rules.version,
        daily: await this.claimDaily(tx, userId, input, version.versionNumber, {
          slots: verified.slots,
          steps: verified.steps,
          stars: score.stars,
        }),
      };
    });
    // Badges are read after the result is stored, from everything the player has verified.
    const earned = await this.achievements.evaluate(userId);
    return { ...result, ...(earned.length > 0 ? { achievements: earned } : {}) };
  }

  /** Counts the result for a daily challenge when the submission claims one. */
  private async claimDaily(
    tx: Prisma.TransactionClient,
    userId: string,
    input: SubmissionBody,
    versionNumber: number,
    result: { slots: number; steps: number; stars: number },
  ) {
    if (!input.dailyDate) return undefined;
    return this.daily.record(tx, userId, {
      date: input.dailyDate,
      slug: input.levelSlug,
      version: versionNumber,
      ...result,
    });
  }

  /** The player's total and the best stars and points for each level they have cleared. */
  async points(userId: string): Promise<PointsView> {
    const [ledger, stars] = await Promise.all([
      this.prisma.pointsLedger.groupBy({
        by: ["levelSlug"],
        where: { userId },
        _sum: { delta: true },
      }),
      this.prisma.submission.groupBy({
        by: ["levelSlug"],
        where: { userId },
        _max: { stars: true },
      }),
    ]);
    const starsBySlug = new Map(stars.map((s) => [s.levelSlug, s._max.stars ?? 1]));
    const levels = ledger
      .filter((row): row is typeof row & { levelSlug: string } => row.levelSlug !== null)
      .map((row) => ({
        levelSlug: row.levelSlug,
        stars: starsBySlug.get(row.levelSlug) ?? 1,
        points: row._sum.delta ?? 0,
      }))
      .sort((a, b) => (a.levelSlug < b.levelSlug ? -1 : 1));
    return { total: levels.reduce((sum, l) => sum + l.points, 0), levels };
  }

  private async total(tx: Prisma.TransactionClient, userId: string): Promise<number> {
    const sum = await tx.pointsLedger.aggregate({ where: { userId }, _sum: { delta: true } });
    return sum._sum.delta ?? 0;
  }
}
