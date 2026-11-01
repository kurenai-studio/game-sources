import { Body, Controller, Get, HttpCode, Post, Req, UseGuards } from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import { AdminRoute } from "../../core/http/api-docs.js";
import { parseInput } from "../../core/http/errors.js";
import { AdminGuard, JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import { PointsRulesService } from "./points-rules.service.js";
import { pointsRulesInputSchema, type RuleSetView } from "./points.schemas.js";

@ApiTags("admin: points")
@Controller("admin/points-rules")
@UseGuards(JwtAuthGuard, AdminGuard)
@AdminRoute()
export class AdminPointsController {
  constructor(private readonly rules: PointsRulesService) {}

  @Get()
  @ApiOperation({ summary: "Every scoring rule version, newest first." })
  list(): Promise<{ items: RuleSetView[] }> {
    return this.rules.list();
  }

  @Post()
  @HttpCode(201)
  @ApiOperation({
    summary: "Create the next rule version and make it active.",
    description: "Earlier versions and the results scored under them are never changed.",
  })
  create(@Body() body: unknown, @Req() req: AuthenticatedRequest): Promise<RuleSetView> {
    return this.rules.create(parseInput(pointsRulesInputSchema, body), req.user.id);
  }
}
