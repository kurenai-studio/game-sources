import { Injectable } from "@nestjs/common";
import type { Prisma } from "../../generated/prisma/client.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import type { AuditEventView, AuditListQuery, AuditPage } from "./audit.schemas.js";
import { WebRevalidator } from "./web-revalidator.js";

export const AUDIT_ACTIONS = [
  "LEVEL_PUBLISHED",
  "LEVEL_UNPUBLISHED",
  "LEVEL_ARCHIVED",
  "LEVEL_IMPORTED",
  "LEVEL_RESTORED",
  "CAMPAIGN_REORDERED",
  "POINTS_RULES_CHANGED",
  "PLAYER_SESSIONS_REVOKED",
  "PLAYER_PROGRESS_RESET",
  "PLAYER_NAME_CHANGED",
  "PLAYER_SUSPENDED",
  "PLAYER_UNSUSPENDED",
  "PLAYER_DELETED",
  "PLAYER_EXPORTED",
  "PLAYER_LEADERBOARD_HIDDEN",
  "PLAYER_LEADERBOARD_UNHIDDEN",
  "REPORT_RESOLVED",
  "DAILY_SCHEDULED",
  "DAILY_CLEARED",
  "DAILY_POOL_CHANGED",
  "ACHIEVEMENT_CREATED",
  "ACHIEVEMENT_UPDATED",
  "CONTACT_UPDATED",
] as const;
export type AuditAction = (typeof AUDIT_ACTIONS)[number];

type Db = Prisma.TransactionClient | PrismaService;

@Injectable()
export class AuditService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly web: WebRevalidator,
  ) {}

  /** Writes an event with the caller's client, so inside a transaction it commits with the change. */
  async record(
    db: Db,
    event: {
      userId: string;
      action: AuditAction;
      entityType: string;
      entityId: string;
      detail?: Prisma.InputJsonValue;
    },
  ): Promise<void> {
    await db.auditEvent.create({ data: event });
    // Every audited action changes what the public site shows (publish, unpublish, reorder, ...).
    this.web.notify();
  }

  async list(query: AuditListQuery): Promise<AuditPage> {
    const where: Prisma.AuditEventWhereInput = {
      ...(query.action ? { action: query.action } : {}),
      ...(query.entityType ? { entityType: query.entityType } : {}),
      ...(query.entityId ? { entityId: query.entityId } : {}),
    };
    const [total, rows] = await Promise.all([
      this.prisma.auditEvent.count({ where }),
      this.prisma.auditEvent.findMany({
        where,
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        skip: (query.page - 1) * query.pageSize,
        take: query.pageSize,
      }),
    ]);
    const userIds = [...new Set(rows.map((r) => r.userId).filter((id): id is string => !!id))];
    const users = userIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: userIds } },
          select: { id: true, email: true },
        })
      : [];
    const emails = new Map(users.map((u) => [u.id, u.email]));
    const items: AuditEventView[] = rows.map((r) => ({
      id: r.id,
      action: r.action,
      entityType: r.entityType,
      entityId: r.entityId,
      detail: (r.detail ?? null) as Record<string, unknown> | null,
      userId: r.userId,
      userEmail: r.userId ? (emails.get(r.userId) ?? null) : null,
      createdAt: r.createdAt.toISOString(),
    }));
    return { items, total, page: query.page, pageSize: query.pageSize };
  }
}
