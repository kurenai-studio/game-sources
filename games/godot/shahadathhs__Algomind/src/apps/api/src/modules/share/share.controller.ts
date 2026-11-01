import { Body, Controller, Get, HttpCode, Param, Post, Req, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";
import { parseInput } from "../../core/http/errors.js";
import { JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import { RateLimiter, tooManyRequests } from "../auth/rate-limiter.js";
import { codeParamSchema, shareBodySchema, type ShareView } from "./share.schemas.js";
import { ShareService } from "./share.service.js";

@ApiTags("share")
@Controller()
export class ShareController {
  constructor(
    private readonly share: ShareService,
    private readonly limiter: RateLimiter,
  ) {}

  @Post("me/share")
  @HttpCode(200)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: "Make (or reuse) a share link for one of the player's verified results.",
    description: "Returns a code and the site path of its public page, for example /s/abcd2345.",
  })
  @ApiResponse({ status: 409, description: "The player has no solved result to share." })
  create(@Body() body: unknown, @Req() req: AuthenticatedRequest) {
    const hit = this.limiter.hit(`share:${req.user.id}`, 30, 24 * 60 * 60 * 1000);
    if (!hit.allowed) throw tooManyRequests(hit.retryAfterSeconds);
    return this.share.create(req.user.id, parseInput(shareBodySchema, body));
  }

  @Get("share/:code")
  @ApiOperation({
    summary: "The public, spoiler-free card behind a share link.",
    description: "No program, no name, no account id: the level, the slots, the steps, and par.",
  })
  get(@Param("code") code: string): Promise<ShareView> {
    return this.share.get(parseInput(codeParamSchema, code));
  }
}
