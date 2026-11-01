import { Injectable } from "@nestjs/common";
import { Prisma } from "../../generated/prisma/client.js";
import { notFound } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AuditService } from "../audit/audit.service.js";
import type {
  ListPlayersQuery,
  PlayerDetail,
  PlayerPage,
  PlayerSummary,
} from "./players.schemas.js";

const SORT_COLUMN = {
  lastActive: 'u."lastActiveAt"',
  points: "COALESCE(l.points, 0)",
  cleared: "COALESCE(p.cleared, 0)",
  created: 'u."createdAt"',
  email: "u.email",
} as const;

type Row = {
  id: string;
  email: string;
  displayName: string | null;
  status: "ACTIVE" | "SUSPENDED";
  createdAt: Date;
  lastActiveAt: Date | null;
  leaderboardOptIn: boolean;
  leaderboardHidden: boolean;
  levelsCleared: number;
  points: number;
};

const iso = (date: Date | null): string | null => (date ? date.toISOString() : null);

/** `%` and `_` in a search are text, not wildcards. */
const likePattern = (q: string): string => `%${q.replace(/[\\%_]/g, (c) => `\\${c}`)}%`;

/** Reading players for the dashboard: the list, one player's detail, and a data export. */
@Injectable()
export class PlayersReadService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async list(query: ListPlayersQuery): Promise<PlayerPage> {
    const conditions: Prisma.Sql[] = [Prisma.sql`u.role = 'PLAYER'`];
    if (query.q) {
      const pattern = likePattern(query.q);
      conditions.push(Prisma.sql`(u.email ILIKE ${pattern} OR u."displayName" ILIKE ${pattern})`);
    }
    if (query.status) conditions.push(Prisma.sql`u.status = ${query.status}::"UserStatus"`);
    const where = Prisma.join(conditions, " AND ");
    // The column and direction come from fixed lists, never from the request text.
    const order = Prisma.raw(
      `${SORT_COLUMN[query.sort]} ${query.order === "asc" ? "ASC" : "DESC"} NULLS LAST`,
    );
    const rows = await this.prisma.$queryRaw<Row[]>`
      SELECT u.id, u.email, u."displayName", u.status, u."createdAt", u."lastActiveAt",
             u."leaderboardOptIn", u."leaderboardHidden",
             COALESCE(p.cleared, 0)::int AS "levelsCleared", COALESCE(l.points, 0)::int AS points
      FROM "User" u
      LEFT JOIN (SELECT "userId", count(*) AS cleared FROM "LevelProgress" GROUP BY 1) p
        ON p."userId" = u.id
      LEFT JOIN (SELECT "userId", sum(delta) AS points FROM "PointsLedger" GROUP BY 1) l
        ON l."userId" = u.id
      WHERE ${where}
      ORDER BY ${order}, u.id
      LIMIT ${query.pageSize} OFFSET ${(query.page - 1) * query.pageSize}`;
    const counted = await this.prisma.$queryRaw<{ total: number }[]>`
      SELECT count(*)::int AS total FROM "User" u WHERE ${where}`;
    return {
      items: rows.map(toSummary),
      total: counted[0]?.total ?? 0,
      page: query.page,
      pageSize: query.pageSize,
    };
  }

  async detail(id: string): Promise<PlayerDetail> {
    const user = await this.prisma.user.findFirst({ where: { id, role: "PLAYER" } });
    if (!user) throw notFound("The player");
    const [progress, ledger, total, sessions, settings] = await Promise.all([
      this.prisma.levelProgress.findMany({ where: { userId: id }, orderBy: { levelSlug: "asc" } }),
      this.prisma.pointsLedger.findMany({
        where: { userId: id },
        orderBy: { createdAt: "desc" },
        take: 100,
      }),
      this.prisma.pointsLedger.aggregate({ where: { userId: id }, _sum: { delta: true } }),
      this.prisma.refreshToken.groupBy({
        by: ["familyId"],
        where: { userId: id, revokedAt: null, expiresAt: { gt: new Date() } },
        _min: { createdAt: true },
        _max: { createdAt: true, expiresAt: true },
      }),
      this.prisma.playerSettings.findUnique({ where: { userId: id } }),
    ]);
    const touched = [
      ...progress.map((p) => p.updatedAt),
      ...(settings ? [settings.updatedAt] : []),
    ];
    const lastSync = touched.length ? new Date(Math.max(...touched.map((d) => d.getTime()))) : null;
    return {
      account: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        status: user.status,
        createdAt: user.createdAt.toISOString(),
        lastActiveAt: iso(user.lastActiveAt),
        publicId: user.publicId,
        leaderboardOptIn: user.leaderboardOptIn,
        hideName: user.hideName,
        leaderboardHidden: user.leaderboardHidden,
      },
      progress: progress.map((p) => ({
        levelSlug: p.levelSlug,
        levelVersion: p.levelVersion,
        bestCommands: p.bestCommands,
        completedAt: p.completedAt.toISOString(),
      })),
      points: {
        total: total._sum.delta ?? 0,
        history: ledger.map((row) => ({
          createdAt: row.createdAt.toISOString(),
          reason: row.reason,
          delta: row.delta,
          levelSlug: row.levelSlug,
          ruleVersion: row.ruleVersion,
        })),
      },
      sessions: sessions.map((s) => ({
        familyId: s.familyId,
        startedAt: (s._min.createdAt ?? new Date(0)).toISOString(),
        lastUsedAt: (s._max.createdAt ?? new Date(0)).toISOString(),
        expiresAt: (s._max.expiresAt ?? new Date(0)).toISOString(),
      })),
      settings: settings
        ? { settings: settings.settings, updatedAt: settings.updatedAt.toISOString() }
        : null,
      lastSyncAt: iso(lastSync),
    };
  }

  /** Everything stored about one player, for a data request. Writing it to the audit log is part of it. */
  async export(id: string, adminId: string) {
    const detail = await this.detail(id);
    const submissions = await this.prisma.submission.findMany({
      where: { userId: id },
      orderBy: { createdAt: "asc" },
    });
    const [dailyResults, badges, shares] = await Promise.all([
      this.prisma.dailyResult.findMany({ where: { userId: id }, orderBy: { date: "asc" } }),
      this.prisma.playerAchievement.findMany({
        where: { userId: id },
        include: { achievement: { select: { slug: true, title: true } } },
      }),
      this.prisma.shareLink.findMany({ where: { userId: id }, orderBy: { createdAt: "asc" } }),
    ]);
    await this.prisma.$transaction((tx) =>
      this.audit.record(tx, {
        userId: adminId,
        action: "PLAYER_EXPORTED",
        entityType: "player",
        entityId: id,
        detail: { email: detail.account.email },
      }),
    );
    return {
      exportedAt: new Date().toISOString(),
      ...detail,
      submissions: submissions.map((s) => ({
        levelSlug: s.levelSlug,
        slots: s.slots,
        steps: s.steps,
        stars: s.stars,
        points: s.points,
        ruleVersion: s.ruleVersion,
        program: s.program,
        createdAt: s.createdAt.toISOString(),
      })),
      dailyResults: dailyResults.map((r) => ({
        date: r.date,
        levelSlug: r.levelSlug,
        slots: r.slots,
        steps: r.steps,
        stars: r.stars,
      })),
      badges: badges.map((b) => ({
        slug: b.achievement.slug,
        title: b.achievement.title,
        earnedAt: b.earnedAt.toISOString(),
      })),
      shareLinks: shares.map((s) => ({
        code: s.code,
        kind: s.kind,
        levelSlug: s.levelSlug,
        date: s.date,
        slots: s.slots,
        steps: s.steps,
        createdAt: s.createdAt.toISOString(),
      })),
    };
  }
}

function toSummary(row: Row): PlayerSummary {
  return {
    id: row.id,
    email: row.email,
    displayName: row.displayName,
    status: row.status,
    createdAt: row.createdAt.toISOString(),
    lastActiveAt: iso(row.lastActiveAt),
    leaderboardOptIn: row.leaderboardOptIn,
    leaderboardHidden: row.leaderboardHidden,
    levelsCleared: row.levelsCleared,
    points: row.points,
  };
}
