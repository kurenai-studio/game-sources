import { Injectable } from "@nestjs/common";
import type { Request } from "express";
import { notFound } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { TokenService } from "../auth/token.service.js";
import { isValidDate } from "../daily/dates.js";
import { dailyBoard, levelBoard, pointsBoard } from "./board-queries.js";
import type { BoardView } from "./leaderboards.schemas.js";
import { periodRange, type Period } from "./periods.js";

type Paging = { limit: number; offset: number };

/**
 * The boards are public, but only players who opted in (and were not hidden by an admin) appear.
 * A signed-in caller also gets their own place, so they can see where they stand off the top page.
 */
@Injectable()
export class LeaderboardsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
  ) {}

  /** The caller's public id when the request carries a valid token, else null. Never throws. */
  async caller(request: Request): Promise<string | null> {
    const header = request.headers.authorization;
    const match = typeof header === "string" ? /^Bearer (\S+)$/.exec(header) : null;
    if (!match?.[1]) return null;
    try {
      const id = await this.tokens.verifyAccessToken(match[1]);
      const user = await this.prisma.user.findUnique({
        where: { id },
        select: { publicId: true, status: true },
      });
      return user && user.status === "ACTIVE" ? user.publicId : null;
    } catch {
      return null;
    }
  }

  points(period: Period, paging: Paging, me: string | null): Promise<BoardView> {
    return pointsBoard(this.prisma, periodRange(period, new Date()), paging, me);
  }

  async level(slug: string, paging: Paging, me: string | null): Promise<BoardView> {
    const level = await this.prisma.level.findFirst({
      where: { slug, status: "PUBLISHED", currentPublishedVersionId: { not: null } },
      select: { id: true },
    });
    if (!level) throw notFound("The level");
    return levelBoard(this.prisma, slug, paging, me);
  }

  daily(date: string, paging: Paging, me: string | null): Promise<BoardView> {
    if (!isValidDate(date)) throw notFound("The day");
    return dailyBoard(this.prisma, date, paging, me);
  }
}
