import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import { z } from "zod";
import { AdminRoute } from "../../core/http/api-docs.js";
import { parseInput } from "../../core/http/errors.js";
import { AdminGuard, JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import { ReportsService, type ReportView } from "./reports.service.js";

const listQuery = z.object({ status: z.enum(["OPEN", "ALL"]).default("OPEN") });
const resolveBody = z.object({ action: z.enum(["dismiss", "clear_name", "hide"]) }).strict();
const hiddenBody = z.object({ hidden: z.boolean() }).strict();

@ApiTags("admin: leaderboards")
@Controller("admin")
@UseGuards(JwtAuthGuard, AdminGuard)
@AdminRoute()
export class AdminReportsController {
  constructor(private readonly reports: ReportsService) {}

  @Get("reports")
  @ApiOperation({ summary: "Reports of leaderboard names, open ones by default." })
  list(@Query() query: unknown): Promise<{ items: ReportView[] }> {
    return this.reports.list(parseInput(listQuery, query).status);
  }

  @Post("reports/:id/resolve")
  @HttpCode(200)
  @ApiOperation({
    summary: "Dismiss a report, clear the name, or hide the player from the boards.",
  })
  resolve(
    @Param("id") id: string,
    @Body() body: unknown,
    @Req() req: AuthenticatedRequest,
  ): Promise<{ status: string }> {
    return this.reports.resolve(id, parseInput(resolveBody, body).action, req.user.id);
  }

  @Put("players/:id/leaderboard-hidden")
  @ApiOperation({ summary: "Hide a player from every leaderboard, or show them again." })
  hide(
    @Param("id") id: string,
    @Body() body: unknown,
    @Req() req: AuthenticatedRequest,
  ): Promise<{ hidden: boolean }> {
    return this.reports.setHidden(id, parseInput(hiddenBody, body).hidden, req.user.id);
  }
}
