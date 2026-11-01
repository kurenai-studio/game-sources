import { Injectable } from "@nestjs/common";
import type { Prisma } from "../../generated/prisma/client.js";
import { conflict, isUniqueViolation, notFound } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AuditService } from "../audit/audit.service.js";
import { DailyService } from "../daily/daily.service.js";
import {
  achievementRuleSchema,
  describeRule,
  ruleMet,
  type AchievementRule,
  type PlayerStats,
} from "./achievement-rules.js";
import type {
  AchievementInput,
  AdminAchievement,
  EarnedNow,
  MyAchievement,
} from "./achievements.schemas.js";

/**
 * Badges are data: a rule the dashboard edits. After a verified result the server reads the
 * player's stats, awards every active badge whose rule is now met, and never takes one back.
 */
@Injectable()
export class AchievementsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly daily: DailyService,
    private readonly audit: AuditService,
  ) {}

  /** What the rules can read about a player, from their verified results. */
  async stats(userId: string): Promise<PlayerStats> {
    const [slugs, stars, par, points, streak, dailySolved] = await Promise.all([
      this.prisma.submission.findMany({
        where: { userId },
        distinct: ["levelSlug"],
        select: { levelSlug: true },
      }),
      this.prisma.$queryRaw<{ total: number }[]>`
        SELECT COALESCE(SUM(m.stars), 0)::int AS total
        FROM (SELECT MAX("stars") AS stars FROM "Submission" WHERE "userId" = ${userId}
              GROUP BY "levelSlug") m`,
      this.prisma.$queryRaw<{ total: number }[]>`
        SELECT COUNT(DISTINCT s."levelSlug")::int AS total
        FROM "Submission" s JOIN "LevelVersion" v ON v."id" = s."levelVersionId"
        WHERE s."userId" = ${userId} AND s."slots" <= (v."par"->>'commands')::int`,
      this.prisma.pointsLedger.aggregate({ where: { userId }, _sum: { delta: true } }),
      this.daily.streak(userId),
      this.prisma.dailyResult.count({ where: { userId } }),
    ]);
    return {
      levelsSolved: slugs.length,
      starsTotal: stars[0]?.total ?? 0,
      parLevels: par[0]?.total ?? 0,
      points: points._sum.delta ?? 0,
      streak: streak.current,
      dailySolved,
      solvedSlugs: new Set(slugs.map((s) => s.levelSlug)),
    };
  }

  /** Awards every active badge the player now qualifies for. Returns the ones earned just now. */
  async evaluate(userId: string): Promise<EarnedNow[]> {
    const [badges, have, stats] = await Promise.all([
      this.prisma.achievement.findMany({ where: { active: true } }),
      this.prisma.playerAchievement.findMany({
        where: { userId },
        select: { achievementId: true },
      }),
      this.stats(userId),
    ]);
    const owned = new Set(have.map((h) => h.achievementId));
    const earned = badges.filter((badge) => {
      const rule = achievementRuleSchema.safeParse(badge.rule);
      return !owned.has(badge.id) && rule.success && ruleMet(rule.data, stats);
    });
    if (earned.length === 0) return [];
    await this.prisma.playerAchievement.createMany({
      data: earned.map((badge) => ({ userId, achievementId: badge.id })),
      skipDuplicates: true,
    });
    return earned.map((badge) => ({ slug: badge.slug, title: badge.title }));
  }

  async mine(userId: string): Promise<{ items: MyAchievement[] }> {
    const [badges, have] = await Promise.all([
      this.prisma.achievement.findMany({
        where: { active: true },
        orderBy: [{ position: "asc" }, { createdAt: "asc" }],
      }),
      this.prisma.playerAchievement.findMany({ where: { userId } }),
    ]);
    const when = new Map(have.map((h) => [h.achievementId, h.earnedAt]));
    return {
      items: badges.map((b) => ({
        slug: b.slug,
        title: b.title,
        description: b.description,
        earnedAt: when.get(b.id)?.toISOString() ?? null,
      })),
    };
  }

  // ----- admin ---------------------------------------------------------------------------

  private view(
    row: Prisma.AchievementGetPayload<{ include: { _count: { select: { earned: true } } } }>,
  ): AdminAchievement {
    const rule = achievementRuleSchema.parse(row.rule);
    return {
      id: row.id,
      slug: row.slug,
      title: row.title,
      description: row.description,
      rule,
      ruleText: describeRule(rule),
      active: row.active,
      position: row.position,
      earnedBy: row._count.earned,
    };
  }

  async list(): Promise<{ items: AdminAchievement[] }> {
    const rows = await this.prisma.achievement.findMany({
      orderBy: [{ position: "asc" }, { createdAt: "asc" }],
      include: { _count: { select: { earned: true } } },
    });
    return { items: rows.map((row) => this.view(row)) };
  }

  async create(input: AchievementInput, adminId: string): Promise<AdminAchievement> {
    try {
      return await this.prisma.$transaction(async (tx) => {
        const row = await tx.achievement.create({
          data: { ...input, rule: input.rule as unknown as Prisma.InputJsonObject },
          include: { _count: { select: { earned: true } } },
        });
        await this.audit.record(tx, {
          userId: adminId,
          action: "ACHIEVEMENT_CREATED",
          entityType: "achievement",
          entityId: row.id,
          detail: { slug: row.slug },
        });
        return this.view(row);
      });
    } catch (error) {
      if (isUniqueViolation(error)) throw conflict("SLUG_TAKEN", "That slug is already used.");
      throw error;
    }
  }

  async update(
    id: string,
    input: Partial<Omit<AchievementInput, "slug">>,
    adminId: string,
  ): Promise<AdminAchievement> {
    return this.prisma.$transaction(async (tx) => {
      const found = await tx.achievement.findUnique({ where: { id } });
      if (!found) throw notFound("The badge");
      const { rule, ...rest } = input;
      const row = await tx.achievement.update({
        where: { id },
        data: { ...rest, ...(rule ? { rule: rule as unknown as Prisma.InputJsonObject } : {}) },
        include: { _count: { select: { earned: true } } },
      });
      await this.audit.record(tx, {
        userId: adminId,
        action: "ACHIEVEMENT_UPDATED",
        entityType: "achievement",
        entityId: id,
        detail: { slug: row.slug, active: row.active },
      });
      return this.view(row);
    });
  }
}

export type { AchievementRule };
