import { ForbiddenException, Injectable } from "@nestjs/common";
import type { Prisma } from "../../generated/prisma/client.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { unprocessable } from "../../core/http/errors.js";
import { PasswordService } from "../auth/password.service.js";
import { deleteReportsOf } from "../leaderboards/reports.service.js";
import { mergeCompletion, shouldReplaceSettings } from "./me.merge.js";
import type { ProgressView, SettingsPayload, SyncBody } from "./me.schemas.js";

const toDate = (seconds: number): Date => new Date(Math.round(seconds * 1000));
const toSeconds = (date: Date): number => date.getTime() / 1000;

/**
 * A player's cloud progress. The merge only ever adds or improves, so a sync can never lose a
 * completion, and running the same sync twice leaves the same result:
 *  - a level solved on either side stays solved;
 *  - for one level the newer level version wins (a score is never read against other content);
 *  - for the same version the fewer commands win;
 *  - the earliest completion time is kept;
 *  - settings: the newest change wins.
 */
@Injectable()
export class MeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly passwords: PasswordService,
  ) {}

  async progress(userId: string): Promise<ProgressView> {
    return this.read(this.prisma, userId);
  }

  async sync(userId: string, input: SyncBody): Promise<ProgressView> {
    return this.prisma.$transaction(async (tx) => {
      // Two syncs of one player (two devices, or a retry) take turns: the second reads what the
      // first wrote instead of merging from the same stale snapshot.
      await tx.$queryRaw`SELECT "id" FROM "User" WHERE "id" = ${userId} FOR UPDATE`;
      await tx.user.update({ where: { id: userId }, data: { lastActiveAt: new Date() } });
      const stored = new Map(
        (await tx.levelProgress.findMany({ where: { userId } })).map((row) => [row.levelSlug, row]),
      );
      for (const item of input.completed) {
        const at = toDate(item.completedAt ?? Date.now() / 1000);
        const row = stored.get(item.levelSlug);
        if (!row) {
          const created = await tx.levelProgress.create({
            data: {
              userId,
              levelSlug: item.levelSlug,
              levelVersion: item.levelVersion,
              bestCommands: item.bestCommands,
              completedAt: at,
            },
          });
          stored.set(item.levelSlug, created);
          continue;
        }
        const merged = mergeCompletion(row, {
          levelVersion: item.levelVersion,
          bestCommands: item.bestCommands,
          completedAt: at,
        });
        if (merged.action === "update") {
          stored.set(
            item.levelSlug,
            await tx.levelProgress.update({ where: { id: row.id }, data: merged.data }),
          );
        }
      }
      if (input.settings) await this.putSettings(tx, userId, input.settings);
      return this.read(tx, userId);
    });
  }

  async settings(userId: string): Promise<SettingsPayload | null> {
    return (await this.read(this.prisma, userId)).settings;
  }

  /** Last write wins by the player's own timestamp. Returns what is stored afterwards. */
  async saveSettings(userId: string, input: SettingsPayload): Promise<SettingsPayload> {
    await this.prisma.$transaction((tx) => this.putSettings(tx, userId, input));
    return (await this.settings(userId)) as SettingsPayload;
  }

  /** Deletes the account and, by cascade, its sessions, progress, results, badges, and share links. */
  async deleteAccount(userId: string, password: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) return true;
    if (user.role === "ADMIN") {
      throw new ForbiddenException({
        code: "FORBIDDEN",
        message: "Admin accounts cannot be deleted here.",
      });
    }
    if (!(await this.passwords.verify(user.passwordHash, password))) {
      throw unprocessable("PASSWORD_INCORRECT", "The password is incorrect.", [
        { path: "password", code: "INCORRECT", message: "The password is incorrect." },
      ]);
    }
    await this.prisma.$transaction(async (tx) => {
      await deleteReportsOf(tx, userId, user.publicId);
      await tx.user.delete({ where: { id: userId } });
    });
    return true;
  }

  private async putSettings(
    tx: Prisma.TransactionClient,
    userId: string,
    input: SettingsPayload,
  ): Promise<void> {
    const at = toDate(input.updatedAt);
    const current = await tx.playerSettings.findUnique({ where: { userId } });
    if (!shouldReplaceSettings(current?.updatedAt ?? null, at)) return;
    await tx.playerSettings.upsert({
      where: { userId },
      create: { userId, settings: input.settings as Prisma.InputJsonObject, updatedAt: at },
      update: { settings: input.settings as Prisma.InputJsonObject, updatedAt: at },
    });
  }

  private async read(
    db: Prisma.TransactionClient | PrismaService,
    userId: string,
  ): Promise<ProgressView> {
    const [rows, settings] = await Promise.all([
      db.levelProgress.findMany({ where: { userId }, orderBy: { levelSlug: "asc" } }),
      db.playerSettings.findUnique({ where: { userId } }),
    ]);
    return {
      completed: rows.map((row) => ({
        levelSlug: row.levelSlug,
        levelVersion: row.levelVersion,
        bestCommands: row.bestCommands,
        completedAt: toSeconds(row.completedAt),
      })),
      settings: settings
        ? {
            settings: settings.settings as SettingsPayload["settings"],
            updatedAt: toSeconds(settings.updatedAt),
          }
        : null,
    };
  }
}
