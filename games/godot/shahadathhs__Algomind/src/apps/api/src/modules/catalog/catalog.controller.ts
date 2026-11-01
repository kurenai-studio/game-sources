import { createHash } from "node:crypto";
import { Controller, Get, Param, Res } from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import type { Response } from "express";
import { ErrorOf, ResponseOf } from "../../core/http/api-docs.js";
import {
  campaignBoardsSchema,
  campaignSchema,
  levelListSchema,
  publicLevelSchema,
  type Campaign,
  type CampaignBoards,
  type LevelList,
  type PublicLevel,
} from "./catalog.schemas.js";
import { CatalogService } from "./catalog.service.js";

// Short, because publish and unpublish should show up quickly; stale-while-revalidate keeps the
// catalog fast. Express answers 304 itself when If-None-Match matches the ETag set below.
const CACHE_CONTROL = "public, max-age=60, stale-while-revalidate=300";

function cached(res: Response, etag: string): void {
  res.setHeader("Cache-Control", CACHE_CONTROL);
  res.setHeader("ETag", `"${etag}"`);
}

function digest(value: unknown): string {
  return createHash("sha256").update(JSON.stringify(value)).digest("hex").slice(0, 32);
}

@ApiTags("public catalog")
@Controller()
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get("campaign")
  @ApiOperation({
    summary: "The published campaign as a tree: worlds, chapters, and level summaries in order.",
    description:
      "No authentication. Only published levels assigned to a chapter appear. Sends an ETag " +
      "(answer 304 to If-None-Match) and Cache-Control.",
  })
  @ResponseOf(200, campaignSchema, "The campaign tree.")
  async campaignTree(@Res({ passthrough: true }) res: Response): Promise<Campaign> {
    const body = await this.catalog.campaign();
    cached(res, `c-${digest(body)}`);
    return body;
  }

  @Get("campaign/boards")
  @ApiOperation({
    summary: "The boards of every campaign level in one answer.",
    description:
      "No authentication. For a page that draws every level (the public levels page): only the " +
      "fields that draw a board, never the reference solution. Same visibility, ETag and caching as " +
      "/campaign.",
  })
  @ResponseOf(200, campaignBoardsSchema, "The boards, in campaign order.")
  async campaignBoards(@Res({ passthrough: true }) res: Response): Promise<CampaignBoards> {
    const body = await this.catalog.boards();
    cached(res, `b-${digest(body)}`);
    return body;
  }

  @Get("levels")
  @ApiOperation({
    summary: "Published levels with lightweight metadata, in campaign order.",
    description: "No authentication. Same visibility, ETag and caching as /campaign.",
  })
  @ResponseOf(200, levelListSchema, "The level list.")
  async levelList(@Res({ passthrough: true }) res: Response): Promise<LevelList> {
    const body = await this.catalog.levels();
    cached(res, `l-${digest(body)}`);
    return body;
  }

  @Get("levels/:slug")
  @ApiOperation({
    summary: "The current published version of a level.",
    description:
      "No authentication; never includes the reference solution. The ETag changes only when a " +
      "new version is published.",
  })
  @ResponseOf(200, publicLevelSchema, "schemaVersion, levelVersion, par, and the level content.")
  @ErrorOf(404, "The level does not exist, is not published, or is not placed in a chapter.")
  async level(
    @Param("slug") slug: string,
    @Res({ passthrough: true }) res: Response,
  ): Promise<PublicLevel> {
    const { body, versionId } = await this.catalog.level(slug);
    cached(res, `v-${versionId}`);
    return body;
  }
}
