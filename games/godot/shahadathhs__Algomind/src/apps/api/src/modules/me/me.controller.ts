import { Body, Controller, Delete, Get, HttpCode, Post, Put, Req, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";
import { parseInput } from "../../core/http/errors.js";
import { JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import { RateLimiter, tooManyRequests } from "../auth/rate-limiter.js";
import { MeService } from "./me.service.js";
import {
  deleteAccountSchema,
  settingsPayloadSchema,
  syncBodySchema,
  type ProgressView,
  type SettingsPayload,
} from "./me.schemas.js";

/**
 * The signed-in player's cloud progress. Every route needs a valid access token. Progress stays
 * on the device first; the game is the only client that uploads it, and only when signed in.
 */
@ApiTags("me")
@ApiBearerAuth()
@Controller("me")
@UseGuards(JwtAuthGuard)
export class MeController {
  constructor(
    private readonly me: MeService,
    private readonly limiter: RateLimiter,
  ) {}

  @Get("progress")
  @ApiOperation({ summary: "The player's solved levels and synced settings." })
  @ApiResponse({ status: 401, description: "Missing, invalid, or expired access token." })
  progress(@Req() req: AuthenticatedRequest): Promise<ProgressView> {
    return this.me.progress(req.user.id);
  }

  @Post("progress/sync")
  @HttpCode(200)
  @ApiOperation({
    summary: "Send local progress; the server merges it and returns the merged result.",
    description:
      "Idempotent. Union of solved levels, the newer level version wins, the fewer commands win " +
      "for the same version, the earliest completion time is kept, the newest settings win.",
  })
  @ApiResponse({ status: 422, description: "The body is not a valid progress payload." })
  sync(@Body() body: unknown, @Req() req: AuthenticatedRequest): Promise<ProgressView> {
    return this.me.sync(req.user.id, parseInput(syncBodySchema, body));
  }

  @Get("settings")
  @ApiOperation({ summary: "The synced settings, or null when none were saved." })
  settings(@Req() req: AuthenticatedRequest): Promise<SettingsPayload | null> {
    return this.me.settings(req.user.id);
  }

  @Put("settings")
  @ApiOperation({
    summary: "Save the synced settings (last write wins by updatedAt).",
    description:
      "An older updatedAt than the stored one changes nothing; the stored value is returned.",
  })
  saveSettings(@Body() body: unknown, @Req() req: AuthenticatedRequest): Promise<SettingsPayload> {
    return this.me.saveSettings(req.user.id, parseInput(settingsPayloadSchema, body));
  }

  @Delete()
  @HttpCode(204)
  @ApiOperation({
    summary: "Delete the account, its sessions, progress, and settings.",
    description: "Needs the password. The game keeps its local progress.",
  })
  @ApiResponse({ status: 403, description: "Admin accounts cannot be deleted here." })
  @ApiResponse({ status: 422, description: "The password is incorrect." })
  async deleteAccount(@Body() body: unknown, @Req() req: AuthenticatedRequest): Promise<void> {
    const { password } = parseInput(deleteAccountSchema, body);
    const hit = this.limiter.hit(`delete:${req.user.id}`, 5, 15 * 60 * 1000);
    if (!hit.allowed) throw tooManyRequests(hit.retryAfterSeconds);
    await this.me.deleteAccount(req.user.id, password);
  }
}
