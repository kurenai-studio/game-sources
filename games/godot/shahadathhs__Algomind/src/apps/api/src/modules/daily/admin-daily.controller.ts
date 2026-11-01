import { Body, Controller, Delete, Get, Param, Put, Query, Req, UseGuards } from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import { AdminRoute } from "../../core/http/api-docs.js";
import { parseInput } from "../../core/http/errors.js";
import { AdminGuard, JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import { addDays, todayUtc } from "./dates.js";
import {
  dateParamSchema,
  poolBodySchema,
  scheduleQuerySchema,
  slugBodySchema,
  type PoolLevel,
} from "./daily.schemas.js";
import { DailyService } from "./daily.service.js";

@ApiTags("admin: daily")
@Controller("admin/daily")
@UseGuards(JwtAuthGuard, AdminGuard)
@AdminRoute()
export class AdminDailyController {
  constructor(private readonly daily: DailyService) {}

  @Get()
  @ApiOperation({ summary: "The next days with their challenge and whether it is scheduled." })
  schedule(@Query() query: unknown) {
    const q = parseInput(scheduleQuerySchema, query);
    return this.daily.schedule(q.from ?? addDays(todayUtc(), -1), q.days);
  }

  @Get("pool")
  @ApiOperation({ summary: "Published levels with their daily pool membership." })
  pool(): Promise<{ items: PoolLevel[] }> {
    return this.daily.poolLevels();
  }

  @Put("pool/:slug")
  @ApiOperation({ summary: "Add a published level to the daily pool, or remove it." })
  setPool(@Param("slug") slug: string, @Body() body: unknown, @Req() req: AuthenticatedRequest) {
    return this.daily.setPool(slug, parseInput(poolBodySchema, body).pool, req.user.id);
  }

  @Put(":date")
  @ApiOperation({ summary: "Schedule a pool level for a UTC day." })
  setDay(@Param("date") date: string, @Body() body: unknown, @Req() req: AuthenticatedRequest) {
    return this.daily.setDay(
      parseInput(dateParamSchema, date),
      parseInput(slugBodySchema, body).levelSlug,
      req.user.id,
    );
  }

  @Delete(":date")
  @ApiOperation({ summary: "Remove a day's schedule; the rotation fills it again." })
  clearDay(@Param("date") date: string, @Req() req: AuthenticatedRequest) {
    return this.daily.clearDay(parseInput(dateParamSchema, date), req.user.id);
  }
}
