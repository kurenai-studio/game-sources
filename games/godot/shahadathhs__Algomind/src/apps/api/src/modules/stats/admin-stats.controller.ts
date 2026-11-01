import { Controller, Get, UseGuards } from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import { AdminRoute } from "../../core/http/api-docs.js";
import { AdminGuard, JwtAuthGuard } from "../auth/auth.module.js";
import { LevelStatsService, type LevelStat } from "./level-stats.service.js";

@ApiTags("admin: statistics")
@Controller("admin/level-stats")
@UseGuards(JwtAuthGuard, AdminGuard)
@AdminRoute()
export class AdminStatsController {
  constructor(private readonly stats: LevelStatsService) {}

  @Get()
  @ApiOperation({
    summary: "Per published level: solvers, average slots, and how many reached par.",
    description: "From verified results only, for the current published version of each level.",
  })
  list(): Promise<{ items: LevelStat[] }> {
    return this.stats.list();
  }
}
