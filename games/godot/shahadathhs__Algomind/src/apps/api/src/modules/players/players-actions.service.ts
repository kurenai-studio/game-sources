import { Injectable } from "@nestjs/common";
import { conflict, isUniqueViolation, notFound } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AuditService, type AuditAction } from "../audit/audit.service.js";
import { deleteReportsOf } from "../leaderboards/reports.service.js";
import { nameKey } from "../profile/name-rules.js";

/**
 * What an admin can do to one player. Each action runs in one transaction with its audit event,
 * so there is never a change without a record. Only players can be acted on, never admins.
 */
@Injectable()
export class PlayersActionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  private async player(
    tx: Parameters<Parameters<PrismaService["$transaction"]>[0]>[0],
    id: string,
  ) {
    const user = await tx.user.findFirst({ where: { id, role: "PLAYER" } });
    if (!user) throw notFound("The player");
    return user;
  }

  private record(
    tx: Parameters<Parameters<PrismaService["$transaction"]>[0]>[0],
    adminId: string,
    action: AuditAction,
    id: string,
    detail: Record<string, string | number | null>,
  ) {
    return this.audit.record(tx, {
      userId: adminId,
      action,
      entityType: "player",
      entityId: id,
      detail,
    });
  }

  /** Signs the player out everywhere: every refresh token is revoked. */
  async revokeSessions(id: string, adminId: string): Promise<{ revoked: number }> {
    return this.prisma.$transaction(async (tx) => {
      const user = await this.player(tx, id);
      const { count } = await tx.refreshToken.updateMany({
        where: { userId: id, revokedAt: null },
        data: { revokedAt: new Date() },
      });
      await this.record(tx, adminId, "PLAYER_SESSIONS_REVOKED", id, { email: user.email, count });
      return { revoked: count };
    });
  }

  /**
   * Clears the cloud progress and the submissions, and takes the points back with ledger entries
   * (the ledger itself is append-only). The player's device keeps its own copy and sends it again
   * at its next sync; this resets the server's record, not the device.
   */
  async resetProgress(id: string, adminId: string): Promise<{ levels: number; points: number }> {
    return this.prisma.$transaction(async (tx) => {
      const user = await this.player(tx, id);
      await tx.$queryRaw`SELECT "id" FROM "User" WHERE "id" = ${id} FOR UPDATE`;
      const earned = await tx.pointsLedger.groupBy({
        by: ["levelSlug"],
        where: { userId: id },
        _sum: { delta: true },
      });
      let points = 0;
      for (const row of earned) {
        const sum = row._sum.delta ?? 0;
        if (sum === 0) continue;
        points += sum;
        await tx.pointsLedger.create({
          data: {
            userId: id,
            reason: "RESET",
            delta: -sum,
            levelSlug: row.levelSlug,
            ruleVersion: 0,
          },
        });
      }
      const progress = await tx.levelProgress.deleteMany({ where: { userId: id } });
      await tx.submission.deleteMany({ where: { userId: id } });
      await this.record(tx, adminId, "PLAYER_PROGRESS_RESET", id, {
        email: user.email,
        levels: progress.count,
        points,
      });
      return { levels: progress.count, points };
    });
  }

  /** Sets or clears (null) the name shown to other players. */
  async setDisplayName(
    id: string,
    displayName: string | null,
    adminId: string,
  ): Promise<{ displayName: string | null }> {
    return this.prisma.$transaction(async (tx) => {
      const user = await this.player(tx, id);
      try {
        await tx.user.update({
          where: { id },
          data: {
            displayName,
            displayNameKey: displayName ? nameKey(displayName) : null,
            // A cleared name leaves nothing to show, so the player leaves the boards until they pick one.
            ...(displayName === null && !user.hideName ? { leaderboardOptIn: false } : {}),
          },
        });
      } catch (error) {
        if (isUniqueViolation(error)) throw conflict("NAME_TAKEN", "That name is already taken.");
        throw error;
      }
      await this.record(tx, adminId, "PLAYER_NAME_CHANGED", id, {
        email: user.email,
        from: user.displayName,
        to: displayName,
      });
      return { displayName };
    });
  }

  /** Blocks sign-in and ends every session now; progress and points are kept. */
  async suspend(id: string, adminId: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const user = await this.player(tx, id);
      if (user.status === "SUSPENDED")
        throw conflict("ALREADY_SUSPENDED", "The player is already suspended.");
      await tx.user.update({ where: { id }, data: { status: "SUSPENDED" } });
      await tx.refreshToken.updateMany({
        where: { userId: id, revokedAt: null },
        data: { revokedAt: new Date() },
      });
      await this.record(tx, adminId, "PLAYER_SUSPENDED", id, { email: user.email });
    });
  }

  async unsuspend(id: string, adminId: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const user = await this.player(tx, id);
      if (user.status !== "SUSPENDED")
        throw conflict("NOT_SUSPENDED", "The player is not suspended.");
      await tx.user.update({ where: { id }, data: { status: "ACTIVE" } });
      await this.record(tx, adminId, "PLAYER_UNSUSPENDED", id, { email: user.email });
    });
  }

  /** Deletes the account and everything that belongs to it. The caller types the email to confirm. */
  async remove(id: string, confirmEmail: string, adminId: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const user = await this.player(tx, id);
      if (user.email !== confirmEmail.trim().toLowerCase()) {
        throw conflict("EMAIL_MISMATCH", "The email typed does not match the player's email.");
      }
      await this.record(tx, adminId, "PLAYER_DELETED", id, { email: user.email });
      await deleteReportsOf(tx, id, user.publicId);
      await tx.user.delete({ where: { id } });
    });
  }
}
