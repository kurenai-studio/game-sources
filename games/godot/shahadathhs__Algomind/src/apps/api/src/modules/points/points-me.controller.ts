import { Body, Controller, Get, HttpCode, Post, Req, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";
import { parseInput } from "../../core/http/errors.js";
import { JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import { RateLimiter, tooManyRequests } from "../auth/rate-limiter.js";
import { submissionBodySchema, type PointsView, type SubmissionResult } from "./points.schemas.js";
import { SubmissionsService } from "./submissions.service.js";

/** The signed-in player's verified results and points. The game uploads through its sync only. */
@ApiTags("me")
@ApiBearerAuth()
@Controller("me")
@UseGuards(JwtAuthGuard)
export class PointsMeController {
  constructor(
    private readonly submissions: SubmissionsService,
    private readonly limiter: RateLimiter,
  ) {}

  @Post("submissions")
  @HttpCode(200)
  @ApiOperation({
    summary: "Submit a program for a level version; the server verifies and scores it.",
    description:
      "Idempotent on the program: sending the same program for the same level version again " +
      "returns the stored result and awards nothing. The client never sends a score.",
  })
  @ApiResponse({ status: 409, description: "The level version is not available for scoring." })
  @ApiResponse({ status: 422, description: "The program is invalid or does not reach the goal." })
  submit(@Body() body: unknown, @Req() req: AuthenticatedRequest): Promise<SubmissionResult> {
    const hit = this.limiter.hit(`submit:${req.user.id}`, 120, 60 * 1000);
    if (!hit.allowed) throw tooManyRequests(hit.retryAfterSeconds);
    return this.submissions.submit(req.user.id, parseInput(submissionBodySchema, body));
  }

  @Get("points")
  @ApiOperation({ summary: "The player's total points and best result per level." })
  points(@Req() req: AuthenticatedRequest): Promise<PointsView> {
    return this.submissions.points(req.user.id);
  }
}
