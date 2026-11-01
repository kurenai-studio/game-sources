import { Body, Controller, Get, Param, Post, Put, Req, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import { AdminRoute } from "../../core/http/api-docs.js";
import { parseInput } from "../../core/http/errors.js";
import { AdminGuard, JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import {
  achievementInputSchema,
  achievementUpdateSchema,
  type AdminAchievement,
  type MyAchievement,
} from "./achievements.schemas.js";
import { AchievementsService } from "./achievements.service.js";

@ApiTags("me")
@ApiBearerAuth()
@Controller("me/achievements")
@UseGuards(JwtAuthGuard)
export class MyAchievementsController {
  constructor(private readonly achievements: AchievementsService) {}

  @Get()
  @ApiOperation({ summary: "Every active badge, with when the player earned it (or null)." })
  mine(@Req() req: AuthenticatedRequest): Promise<{ items: MyAchievement[] }> {
    return this.achievements.mine(req.user.id);
  }
}

@ApiTags("admin: achievements")
@Controller("admin/achievements")
@UseGuards(JwtAuthGuard, AdminGuard)
@AdminRoute()
export class AdminAchievementsController {
  constructor(private readonly achievements: AchievementsService) {}

  @Get()
  @ApiOperation({ summary: "Every badge with its rule and how many players earned it." })
  list(): Promise<{ items: AdminAchievement[] }> {
    return this.achievements.list();
  }

  @Post()
  @ApiOperation({ summary: "Create a badge from a rule." })
  create(@Body() body: unknown, @Req() req: AuthenticatedRequest): Promise<AdminAchievement> {
    return this.achievements.create(parseInput(achievementInputSchema, body), req.user.id);
  }

  @Put(":id")
  @ApiOperation({
    summary: "Change a badge's text, rule, order, or whether it is active.",
    description: "A badge a player already earned stays earned, whatever the rule becomes.",
  })
  update(
    @Param("id") id: string,
    @Body() body: unknown,
    @Req() req: AuthenticatedRequest,
  ): Promise<AdminAchievement> {
    return this.achievements.update(id, parseInput(achievementUpdateSchema, body), req.user.id);
  }
}
