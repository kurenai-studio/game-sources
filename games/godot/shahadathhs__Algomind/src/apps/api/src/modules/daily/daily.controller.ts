import { Controller, Get, Req, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import { JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import type { DailyView, MyDailyView } from "./daily.schemas.js";
import { DailyService } from "./daily.service.js";

@ApiTags("daily")
@Controller()
export class DailyController {
  constructor(private readonly daily: DailyService) {}

  @Get("daily")
  @ApiOperation({
    summary: "Today's challenge and the next few days (UTC), for offline caching.",
    description:
      "Public. The level content comes from GET /levels/:slug. Days with no scheduled level use " +
      "a rotation over the daily pool, so a day is empty only while the pool is.",
  })
  view(): Promise<DailyView> {
    return this.daily.view();
  }

  @Get("me/daily")
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "The player's result for today's challenge and their streak." })
  mine(@Req() req: AuthenticatedRequest): Promise<MyDailyView> {
    return this.daily.mine(req.user.id);
  }
}
