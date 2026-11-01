import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import { AdminRoute, BodyOf, ErrorOf, QueryOf, ResponseOf } from "../../core/http/api-docs.js";
import { parseInput } from "../../core/http/errors.js";
import { AdminGuard, JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import {
  adminCampaignSchema,
  chapterListSchema,
  chapterSchema,
  createChapterSchema,
  createWorldSchema,
  listChaptersQuerySchema,
  orderBodySchema,
  updateChapterSchema,
  updateWorldSchema,
  worldListSchema,
  worldSchema,
  type AdminCampaign,
  type ChapterView,
  type WorldView,
} from "./campaign.schemas.js";
import { CampaignService } from "./campaign.service.js";

@ApiTags("admin: campaign")
@Controller("admin")
@UseGuards(JwtAuthGuard, AdminGuard)
@AdminRoute()
export class AdminCampaignController {
  constructor(private readonly campaign: CampaignService) {}

  @Get("campaign")
  @ApiOperation({
    summary:
      "The whole campaign for editing: every world, chapter and level, plus unassigned levels.",
  })
  @ResponseOf(200, adminCampaignSchema, "The tree in play order, with level summaries.")
  tree(): Promise<AdminCampaign> {
    return this.campaign.tree();
  }

  @Put("campaign/order")
  @ApiOperation({
    summary: "Reorder worlds, chapters and levels and assign levels to chapters.",
    description:
      "Declarative and transactional: send the complete tree of ids. Placement lives on levels, " +
      "so no level version changes. Levels left out become unassigned (a published level that " +
      "is unassigned disappears from the public catalog). Audited as CAMPAIGN_REORDERED.",
  })
  @BodyOf(orderBodySchema)
  @ResponseOf(200, adminCampaignSchema, "The new tree.")
  @ErrorOf(
    422,
    "VALIDATION_FAILED, or INVALID_ORDER with an issue per unknown, duplicate or missing id.",
  )
  reorder(@Body() body: unknown, @Req() req: AuthenticatedRequest): Promise<AdminCampaign> {
    return this.campaign.reorder(parseInput(orderBodySchema, body), req.user.id);
  }

  @Get("worlds")
  @ApiOperation({ summary: "Worlds in order." })
  @ResponseOf(200, worldListSchema, "All worlds.")
  worlds(): Promise<{ items: WorldView[] }> {
    return this.campaign.listWorlds();
  }

  @Post("worlds")
  @HttpCode(201)
  @ApiOperation({ summary: "Create a world at the end of the campaign." })
  @BodyOf(createWorldSchema)
  @ResponseOf(201, worldSchema, "The world.")
  @ErrorOf(422, "VALIDATION_FAILED.")
  createWorld(@Body() body: unknown): Promise<WorldView> {
    return this.campaign.createWorld(parseInput(createWorldSchema, body));
  }

  @Patch("worlds/:id")
  @ApiOperation({ summary: "Rename a world or change its description." })
  @BodyOf(updateWorldSchema)
  @ResponseOf(200, worldSchema, "The world.")
  @ErrorOf(404, "NOT_FOUND.")
  updateWorld(@Param("id") id: string, @Body() body: unknown): Promise<WorldView> {
    return this.campaign.updateWorld(id, parseInput(updateWorldSchema, body));
  }

  @Delete("worlds/:id")
  @HttpCode(204)
  @ApiOperation({ summary: "Delete an empty world." })
  @ResponseOf(204, null, "Deleted.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "NOT_EMPTY: the world still has chapters.")
  async deleteWorld(@Param("id") id: string): Promise<void> {
    await this.campaign.deleteWorld(id);
  }

  @Get("chapters")
  @ApiOperation({ summary: "Chapters in campaign order, optionally of one world." })
  @QueryOf(listChaptersQuerySchema)
  @ResponseOf(200, chapterListSchema, "Chapters.")
  chapters(@Query() query: unknown): Promise<{ items: ChapterView[] }> {
    return this.campaign.listChapters(parseInput(listChaptersQuerySchema, query).worldId);
  }

  @Post("chapters")
  @HttpCode(201)
  @ApiOperation({ summary: "Create a chapter at the end of a world." })
  @BodyOf(createChapterSchema)
  @ResponseOf(201, chapterSchema, "The chapter.")
  @ErrorOf(422, "VALIDATION_FAILED (including an unknown worldId).")
  createChapter(@Body() body: unknown): Promise<ChapterView> {
    return this.campaign.createChapter(parseInput(createChapterSchema, body));
  }

  @Patch("chapters/:id")
  @ApiOperation({ summary: "Rename a chapter (move it with PUT /admin/campaign/order)." })
  @BodyOf(updateChapterSchema)
  @ResponseOf(200, chapterSchema, "The chapter.")
  @ErrorOf(404, "NOT_FOUND.")
  updateChapter(@Param("id") id: string, @Body() body: unknown): Promise<ChapterView> {
    return this.campaign.updateChapter(id, parseInput(updateChapterSchema, body));
  }

  @Delete("chapters/:id")
  @HttpCode(204)
  @ApiOperation({ summary: "Delete an empty chapter." })
  @ResponseOf(204, null, "Deleted.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "NOT_EMPTY: the chapter still has levels.")
  async deleteChapter(@Param("id") id: string): Promise<void> {
    await this.campaign.deleteChapter(id);
  }
}
