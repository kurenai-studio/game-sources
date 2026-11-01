import { Injectable } from "@nestjs/common";
import type { Prisma } from "../../generated/prisma/client.js";
import { conflict, notFound } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AuditService } from "../audit/audit.service.js";
import { asPar } from "../levels/level-views.js";
import { addDays, isValidDate, todayUtc } from "./dates.js";
import { pickFromPool } from "./daily-rotation.js";
import type { DailyEntry, DailyView, MyDailyView, PoolLevel } from "./daily.schemas.js";
import { computeStreak, type Streak } from "./streak.js";

type Db = Prisma.TransactionClient | PrismaService;

/** A late sync may still claim a day this many days back. */
const CLAIM_WINDOW_DAYS = 7;
const UPCOMING_DAYS = 3;

/**
 * The daily challenge: one level per UTC day. An admin can schedule a day; any other day falls
 * back to a deterministic rotation over the daily pool. Results count for the best of unlimited
 * attempts, and a streak is consecutive days with a result.
 */
@Injectable()
export class DailyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  private async pool(db: Db = this.prisma): Promise<string[]> {
    const levels = await db.level.findMany({
      where: { dailyPool: true, status: "PUBLISHED", currentPublishedVersionId: { not: null } },
      select: { slug: true },
    });
    return levels.map((l) => l.slug);
  }

  /** Which level a day uses and why, or null when nothing is scheduled and the pool is empty. */
  async resolve(date: string, db: Db = this.prisma) {
    const scheduled = await db.dailyChallenge.findUnique({ where: { date } });
    if (scheduled) {
      // A scheduled level that was unpublished since falls back to the rotation: no empty day.
      const live = await db.level.findFirst({
        where: {
          slug: scheduled.levelSlug,
          status: "PUBLISHED",
          currentPublishedVersionId: { not: null },
        },
        select: { id: true },
      });
      if (live) return { levelSlug: scheduled.levelSlug, source: "scheduled" as const };
    }
    const slug = pickFromPool(date, await this.pool(db));
    return slug ? { levelSlug: slug, source: "rotation" as const } : null;
  }

  async entry(date: string, db: Db = this.prisma): Promise<DailyEntry | null> {
    const picked = await this.resolve(date, db);
    if (!picked) return null;
    const level = await db.level.findUnique({
      where: { slug: picked.levelSlug },
      include: { currentPublishedVersion: true },
    });
    const version = level?.currentPublishedVersion;
    const par = asPar(version?.par);
    if (!level || !version || !par || level.status !== "PUBLISHED") return null;
    const content = version.content as { constraints: { maxCommands: number } };
    return {
      date,
      levelSlug: level.slug,
      levelVersion: version.versionNumber,
      title: level.title,
      difficulty: level.difficulty,
      maxCommands: content.constraints.maxCommands,
      par: par.commands,
      source: picked.source,
    };
  }

  async view(): Promise<DailyView> {
    const today = todayUtc();
    const days = Array.from({ length: UPCOMING_DAYS }, (_, i) => addDays(today, i + 1));
    const [now, ...upcoming] = await Promise.all([today, ...days].map((d) => this.entry(d)));
    return {
      serverDate: today,
      today: now ?? null,
      upcoming: upcoming.filter((e): e is DailyEntry => e !== null),
    };
  }

  /** Every UTC date with a solved daily result, for streaks and badges. */
  async streak(userId: string, db: Db = this.prisma): Promise<Streak> {
    const rows = await db.dailyResult.findMany({ where: { userId }, select: { date: true } });
    return computeStreak(
      rows.map((r) => r.date),
      todayUtc(),
    );
  }

  async mine(userId: string): Promise<MyDailyView> {
    const date = todayUtc();
    const [picked, result, streak] = await Promise.all([
      this.resolve(date),
      this.prisma.dailyResult.findUnique({ where: { userId_date: { userId, date } } }),
      this.streak(userId),
    ]);
    return {
      date,
      levelSlug: picked?.levelSlug ?? null,
      result: result ? { slots: result.slots, steps: result.steps, stars: result.stars } : null,
      streak,
    };
  }

  /**
   * Records a verified solve as the player's result for `dailyDate`, if that day's challenge is
   * this level and the date is today or inside the claim window. Keeps the best result (fewest
   * slots, then steps). Returns whether it counted, and the streak after it.
   */
  async record(
    tx: Prisma.TransactionClient,
    userId: string,
    claim: {
      date: string;
      slug: string;
      version: number;
      slots: number;
      steps: number;
      stars: number;
    },
  ): Promise<{ accepted: boolean; streak: Streak }> {
    const today = todayUtc();
    const inWindow =
      isValidDate(claim.date) &&
      claim.date <= today &&
      claim.date >= addDays(today, -CLAIM_WINDOW_DAYS);
    const picked = inWindow ? await this.resolve(claim.date, tx) : null;
    if (!picked || picked.levelSlug !== claim.slug) {
      return { accepted: false, streak: await this.streak(userId, tx) };
    }
    const earlier = await tx.dailyResult.findUnique({
      where: { userId_date: { userId, date: claim.date } },
    });
    const better =
      !earlier ||
      claim.slots < earlier.slots ||
      (claim.slots === earlier.slots && claim.steps < earlier.steps);
    if (better) {
      await tx.dailyResult.upsert({
        where: { userId_date: { userId, date: claim.date } },
        create: {
          userId,
          date: claim.date,
          levelSlug: claim.slug,
          levelVersion: claim.version,
          slots: claim.slots,
          steps: claim.steps,
          stars: claim.stars,
        },
        update: {
          levelVersion: claim.version,
          slots: claim.slots,
          steps: claim.steps,
          stars: claim.stars,
        },
      });
    }
    return { accepted: true, streak: await this.streak(userId, tx) };
  }

  // ----- admin ---------------------------------------------------------------------------

  /** The next `days` days from `from`, each with its level and whether it is scheduled. */
  async schedule(
    from: string,
    days: number,
  ): Promise<{ items: (DailyEntry | { date: string; levelSlug: null })[] }> {
    const dates = Array.from({ length: days }, (_, i) => addDays(from, i));
    const items = await Promise.all(
      dates.map(async (date) => (await this.entry(date)) ?? { date, levelSlug: null }),
    );
    return { items };
  }

  async setDay(date: string, levelSlug: string, adminId: string): Promise<{ date: string }> {
    if (!isValidDate(date)) throw notFound("The day");
    return this.prisma.$transaction(async (tx) => {
      const level = await tx.level.findUnique({ where: { slug: levelSlug } });
      if (!level || level.status !== "PUBLISHED" || !level.currentPublishedVersionId) {
        throw conflict("LEVEL_NOT_AVAILABLE", "Only a published level can be a daily challenge.");
      }
      if (!level.dailyPool) {
        throw conflict("NOT_IN_POOL", "Add the level to the daily pool first.");
      }
      await tx.dailyChallenge.upsert({
        where: { date },
        create: { date, levelSlug, createdBy: adminId },
        update: { levelSlug, createdBy: adminId },
      });
      await this.audit.record(tx, {
        userId: adminId,
        action: "DAILY_SCHEDULED",
        entityType: "daily",
        entityId: date,
        detail: { levelSlug },
      });
      return { date };
    });
  }

  async clearDay(date: string, adminId: string): Promise<{ date: string }> {
    return this.prisma.$transaction(async (tx) => {
      await tx.dailyChallenge.deleteMany({ where: { date } });
      await this.audit.record(tx, {
        userId: adminId,
        action: "DAILY_CLEARED",
        entityType: "daily",
        entityId: date,
      });
      return { date };
    });
  }

  /** Published levels, with whether each is in the daily pool and whether the campaign uses it. */
  async poolLevels(): Promise<{ items: PoolLevel[] }> {
    const levels = await this.prisma.level.findMany({
      where: { status: "PUBLISHED", currentPublishedVersionId: { not: null } },
      orderBy: [{ dailyPool: "desc" }, { slug: "asc" }],
      select: { slug: true, title: true, difficulty: true, dailyPool: true, chapterId: true },
    });
    return {
      items: levels.map((l) => ({
        slug: l.slug,
        title: l.title,
        difficulty: l.difficulty,
        pool: l.dailyPool,
        inCampaign: l.chapterId !== null,
      })),
    };
  }

  async setPool(slug: string, pool: boolean, adminId: string): Promise<{ pool: boolean }> {
    return this.prisma.$transaction(async (tx) => {
      const level = await tx.level.findUnique({ where: { slug } });
      if (!level) throw notFound("The level");
      if (pool && (level.status !== "PUBLISHED" || !level.currentPublishedVersionId)) {
        throw conflict("LEVEL_NOT_AVAILABLE", "Only a published level can join the daily pool.");
      }
      if (pool && level.chapterId) {
        throw conflict(
          "IN_CAMPAIGN",
          "A level in the campaign cannot be a daily challenge: players would meet it early.",
        );
      }
      await tx.level.update({ where: { slug }, data: { dailyPool: pool } });
      await this.audit.record(tx, {
        userId: adminId,
        action: "DAILY_POOL_CHANGED",
        entityType: "level",
        entityId: level.id,
        detail: { slug, pool },
      });
      return { pool };
    });
  }
}
