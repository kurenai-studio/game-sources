import { Body, Controller, Get, Put, Req, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";
import { parseInput } from "../../core/http/errors.js";
import { JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import { RateLimiter, tooManyRequests } from "../auth/rate-limiter.js";
import { profileBodySchema, type ProfileView } from "./profile.schemas.js";
import { ProfileService } from "./profile.service.js";

/** How the signed-in player appears to others. Nothing is public until they turn it on. */
@ApiTags("me")
@ApiBearerAuth()
@Controller("me/profile")
@UseGuards(JwtAuthGuard)
export class ProfileController {
  constructor(
    private readonly profile: ProfileService,
    private readonly limiter: RateLimiter,
  ) {}

  @Get()
  @ApiOperation({ summary: "The display name, leaderboard choices, total points, and rank." })
  get(@Req() req: AuthenticatedRequest): Promise<ProfileView> {
    return this.profile.get(req.user.id);
  }

  @Put()
  @ApiOperation({
    summary: "Change the display name and whether to appear on the leaderboards.",
    description:
      "Appearing on a leaderboard needs a display name or hidden-name mode. A name is 3 to 20 " +
      "letters, digits, spaces, dashes or underscores, unique ignoring case, and checked against a " +
      "short list of abusive and impersonating words.",
  })
  @ApiResponse({ status: 409, description: "The name is already taken." })
  @ApiResponse({ status: 422, description: "The name is not allowed, or a name is required." })
  update(@Body() body: unknown, @Req() req: AuthenticatedRequest): Promise<ProfileView> {
    const hit = this.limiter.hit(`profile:${req.user.id}`, 20, 60 * 1000);
    if (!hit.allowed) throw tooManyRequests(hit.retryAfterSeconds);
    return this.profile.update(req.user.id, parseInput(profileBodySchema, body));
  }
}
