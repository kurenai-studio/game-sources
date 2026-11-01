import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import type { Request } from "express";
import { parseInput } from "../../core/http/errors.js";
import { JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import { RateLimiter, tooManyRequests } from "../auth/rate-limiter.js";
import {
  boardQuerySchema,
  dateParamSchema,
  pointsQuerySchema,
  reportBodySchema,
  slugParamSchema,
  type BoardView,
} from "./leaderboards.schemas.js";
import { LeaderboardsService } from "./leaderboards.service.js";
import { ReportsService } from "./reports.service.js";

/**
 * Public boards of players who opted in. Send an access token to also get your own place. A
 * player appears under their display name, or as "Anonymous" if they chose to hide it; never
 * under an email.
 */
@ApiTags("leaderboards")
@Controller("leaderboards")
export class LeaderboardsController {
  constructor(
    private readonly boards: LeaderboardsService,
    private readonly reports: ReportsService,
    private readonly limiter: RateLimiter,
  ) {}

  @Get("points")
  @ApiOperation({ summary: "Points earned all time, this week, or this month (UTC)." })
  async points(@Query() query: unknown, @Req() req: Request): Promise<BoardView> {
    const q = parseInput(pointsQuerySchema, query);
    return this.boards.points(q.period, q, await this.boards.caller(req));
  }

  @Get("levels/:slug")
  @ApiOperation({ summary: "A level's board: fewest slots, then fewest steps." })
  async level(
    @Param("slug") slug: string,
    @Query() query: unknown,
    @Req() req: Request,
  ): Promise<BoardView> {
    return this.boards.level(
      parseInput(slugParamSchema, slug),
      parseInput(boardQuerySchema, query),
      await this.boards.caller(req),
    );
  }

  @Get("daily/:date")
  @ApiOperation({ summary: "One day's challenge board (a UTC date, YYYY-MM-DD)." })
  async daily(
    @Param("date") date: string,
    @Query() query: unknown,
    @Req() req: Request,
  ): Promise<BoardView> {
    return this.boards.daily(
      parseInput(dateParamSchema, date),
      parseInput(boardQuerySchema, query),
      await this.boards.caller(req),
    );
  }

  @Post("report")
  @HttpCode(200)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Report a leaderboard name for an admin to review." })
  report(@Body() body: unknown, @Req() req: AuthenticatedRequest): Promise<{ received: true }> {
    const hit = this.limiter.hit(`report:${req.user.id}`, 10, 24 * 60 * 60 * 1000);
    if (!hit.allowed) throw tooManyRequests(hit.retryAfterSeconds);
    const input = parseInput(reportBodySchema, body);
    return this.reports.create(req.user.id, input.publicId, input.reason);
  }
}
