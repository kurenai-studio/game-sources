import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import { AdminRoute } from "../../core/http/api-docs.js";
import { parseInput } from "../../core/http/errors.js";
import { AdminGuard, JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import { PlayersActionsService } from "./players-actions.service.js";
import { PlayersReadService } from "./players-read.service.js";
import {
  deletePlayerSchema,
  displayNameBodySchema,
  listPlayersQuerySchema,
  type PlayerDetail,
  type PlayerPage,
} from "./players.schemas.js";

@ApiTags("admin: players")
@Controller("admin/players")
@UseGuards(JwtAuthGuard, AdminGuard)
@AdminRoute()
export class AdminPlayersController {
  constructor(
    private readonly reads: PlayersReadService,
    private readonly actions: PlayersActionsService,
  ) {}

  @Get()
  @ApiOperation({ summary: "List players with search, status filter, sorting and paging." })
  list(@Query() query: unknown): Promise<PlayerPage> {
    return this.reads.list(parseInput(listPlayersQuerySchema, query));
  }

  @Get(":id")
  @ApiOperation({ summary: "One player: account, progress, points history, sessions, settings." })
  detail(@Param("id", ParseUUIDPipe) id: string): Promise<PlayerDetail> {
    return this.reads.detail(id);
  }

  @Get(":id/export")
  @ApiOperation({ summary: "Everything stored about one player. Written to the audit log." })
  export(@Param("id", ParseUUIDPipe) id: string, @Req() req: AuthenticatedRequest) {
    return this.reads.export(id, req.user.id);
  }

  @Post(":id/revoke-sessions")
  @HttpCode(200)
  @ApiOperation({ summary: "Sign the player out everywhere." })
  revokeSessions(@Param("id", ParseUUIDPipe) id: string, @Req() req: AuthenticatedRequest) {
    return this.actions.revokeSessions(id, req.user.id);
  }

  @Post(":id/reset-progress")
  @HttpCode(200)
  @ApiOperation({
    summary: "Reset the server's record of progress, submissions and points.",
    description: "The player's device keeps its copy and sends it again at its next sync.",
  })
  resetProgress(@Param("id", ParseUUIDPipe) id: string, @Req() req: AuthenticatedRequest) {
    return this.actions.resetProgress(id, req.user.id);
  }

  @Patch(":id/display-name")
  @ApiOperation({ summary: "Set the player's display name, or clear it with null." })
  setDisplayName(
    @Param("id", ParseUUIDPipe) id: string,
    @Body() body: unknown,
    @Req() req: AuthenticatedRequest,
  ) {
    const { displayName } = parseInput(displayNameBodySchema, body);
    return this.actions.setDisplayName(id, displayName, req.user.id);
  }

  @Post(":id/suspend")
  @HttpCode(204)
  @ApiOperation({ summary: "Block sign-in and end every session. Progress is kept." })
  suspend(@Param("id", ParseUUIDPipe) id: string, @Req() req: AuthenticatedRequest) {
    return this.actions.suspend(id, req.user.id);
  }

  @Post(":id/unsuspend")
  @HttpCode(204)
  @ApiOperation({ summary: "Allow the player to sign in again." })
  unsuspend(@Param("id", ParseUUIDPipe) id: string, @Req() req: AuthenticatedRequest) {
    return this.actions.unsuspend(id, req.user.id);
  }

  @Delete(":id")
  @HttpCode(204)
  @ApiOperation({
    summary: "Delete the account and all its data.",
    description: "The body repeats the player's email to confirm.",
  })
  remove(
    @Param("id", ParseUUIDPipe) id: string,
    @Body() body: unknown,
    @Req() req: AuthenticatedRequest,
  ) {
    const { confirmEmail } = parseInput(deletePlayerSchema, body);
    return this.actions.remove(id, confirmEmail, req.user.id);
  }
}
