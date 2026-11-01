import { Injectable } from "@nestjs/common";
import { conflict, notFound } from "../../core/http/errors.js";
import type { Prisma } from "../../generated/prisma/client.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AuditService } from "../audit/audit.service.js";

/** Removes the reports a player made and the reports about them (they are not foreign keys). */
export function deleteReportsOf(tx: Prisma.TransactionClient, userId: string, publicId: string) {
  return tx.report.deleteMany({
    where: { OR: [{ reporterId: userId }, { targetPublic: publicId }] },
  });
}

export type ReportView = {
  id: string;
  status: string;
  reason: string;
  createdAt: string;
  resolvedAt: string | null;
  /** What the admin needs to act: the reported player's name and current state. */
  target: {
    id: string;
    publicId: string;
    displayName: string | null;
    hideName: boolean;
    leaderboardHidden: boolean;
  } | null;
};

/**
 * Players report a leaderboard name; an admin dismisses the report, clears the name, or hides the
 * player from every board. Each resolution runs with its audit event in one transaction.
 */
@Injectable()
export class ReportsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async create(reporterId: string, publicId: string, reason: string): Promise<{ received: true }> {
    const target = await this.prisma.user.findUnique({ where: { publicId } });
    if (!target || target.role !== "PLAYER") throw notFound("The player");
    if (target.id === reporterId) throw conflict("OWN_NAME", "You cannot report yourself.");
    await this.prisma.report.upsert({
      where: { reporterId_targetPublic: { reporterId, targetPublic: publicId } },
      create: { reporterId, targetPublic: publicId, reason },
      // A repeat report from the same player is one report; it reopens only if it was dismissed.
      update: {},
    });
    return { received: true };
  }

  async list(status: "OPEN" | "ALL"): Promise<{ items: ReportView[] }> {
    const reports = await this.prisma.report.findMany({
      where: status === "OPEN" ? { status: "OPEN" } : {},
      orderBy: { createdAt: "desc" },
      take: 200,
    });
    const targets = await this.prisma.user.findMany({
      where: { publicId: { in: reports.map((r) => r.targetPublic) } },
      select: {
        id: true,
        publicId: true,
        displayName: true,
        hideName: true,
        leaderboardHidden: true,
      },
    });
    const byPublic = new Map(targets.map((t) => [t.publicId, t]));
    return {
      items: reports.map((r) => ({
        id: r.id,
        status: r.status,
        reason: r.reason,
        createdAt: r.createdAt.toISOString(),
        resolvedAt: r.resolvedAt?.toISOString() ?? null,
        target: byPublic.get(r.targetPublic) ?? null,
      })),
    };
  }

  async resolve(
    id: string,
    action: "dismiss" | "clear_name" | "hide",
    adminId: string,
  ): Promise<{ status: string }> {
    return this.prisma.$transaction(async (tx) => {
      const report = await tx.report.findUnique({ where: { id } });
      if (!report) throw notFound("The report");
      const target = await tx.user.findUnique({ where: { publicId: report.targetPublic } });
      if (target && action === "clear_name") {
        await tx.user.update({
          where: { id: target.id },
          data: { displayName: null, displayNameKey: null, leaderboardOptIn: false },
        });
      } else if (target && action === "hide") {
        await tx.user.update({ where: { id: target.id }, data: { leaderboardHidden: true } });
      }
      const status = action === "dismiss" ? "DISMISSED" : "ACTIONED";
      await tx.report.update({ where: { id }, data: { status, resolvedAt: new Date() } });
      await this.audit.record(tx, {
        userId: adminId,
        action: "REPORT_RESOLVED",
        entityType: "report",
        entityId: id,
        detail: { action, player: target?.id ?? null },
      });
      return { status };
    });
  }

  /** Hides a player from every board (or shows them again), by an admin's decision. */
  async setHidden(
    playerId: string,
    hidden: boolean,
    adminId: string,
  ): Promise<{ hidden: boolean }> {
    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.findFirst({ where: { id: playerId, role: "PLAYER" } });
      if (!user) throw notFound("The player");
      await tx.user.update({ where: { id: playerId }, data: { leaderboardHidden: hidden } });
      await this.audit.record(tx, {
        userId: adminId,
        action: hidden ? "PLAYER_LEADERBOARD_HIDDEN" : "PLAYER_LEADERBOARD_UNHIDDEN",
        entityType: "player",
        entityId: playerId,
        detail: { email: user.email },
      });
      return { hidden };
    });
  }
}
