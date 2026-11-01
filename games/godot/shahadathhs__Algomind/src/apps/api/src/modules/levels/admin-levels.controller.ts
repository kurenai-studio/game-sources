import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import { AdminRoute, BodyOf, ErrorOf, QueryOf, ResponseOf } from "../../core/http/api-docs.js";
import { parseInput } from "../../core/http/errors.js";
import { AdminGuard, JwtAuthGuard } from "../auth/auth.module.js";
import type { AuthenticatedRequest } from "../auth/auth.types.js";
import { LevelsPlaytestService } from "./levels-playtest.service.js";
import { LevelsPublishService } from "./levels-publish.service.js";
import { LevelsReadService } from "./levels-read.service.js";
import { LevelsTransferService } from "./levels-transfer.service.js";
import { LevelsService } from "./levels.service.js";
import {
  createLevelSchema,
  duplicateBodySchema,
  exportEnvelopeSchema,
  importEnvelopeSchema,
  importQuerySchema,
  levelPageSchema,
  levelSchema,
  listLevelsQuerySchema,
  playtestBodySchema,
  playtestListSchema,
  playtestSchema,
  publishResponseSchema,
  unpublishBodySchema,
  updateDraftSchema,
  validateResponseSchema,
  versionListSchema,
  versionSchema,
  type ExportEnvelope,
  type LevelPage,
  type LevelView,
  type PlaytestView,
  type ValidateResponse,
  type VersionSummary,
  type VersionView,
} from "./levels.schemas.js";
import { z } from "zod";

const exportQuerySchema = z.object({
  version: z.string().max(64).optional().describe("A version id. Defaults to draft, else live."),
});

@ApiTags("admin: levels")
@Controller("admin/levels")
@UseGuards(JwtAuthGuard, AdminGuard)
@AdminRoute()
export class AdminLevelsController {
  constructor(
    private readonly levels: LevelsService,
    private readonly reads: LevelsReadService,
    private readonly publication: LevelsPublishService,
    private readonly playtestRecords: LevelsPlaytestService,
    private readonly transfers: LevelsTransferService,
  ) {}

  @Get()
  @ApiOperation({ summary: "List levels with filters, search, sorting, and paging." })
  @QueryOf(listLevelsQuerySchema)
  @ResponseOf(200, levelPageSchema, "One page of level summaries.")
  list(@Query() query: unknown): Promise<LevelPage> {
    return this.reads.list(parseInput(listLevelsQuerySchema, query));
  }

  @Post()
  @HttpCode(201)
  @ApiOperation({
    summary: "Create a level with its first draft.",
    description:
      "The draft starts from a 5x5 starter board unless content is given. Content may be " +
      "incomplete; validate reports what is missing. The server sets levelId, levelVersion and slug.",
  })
  @BodyOf(createLevelSchema)
  @ResponseOf(201, levelSchema, "The new level, with its draft.")
  @ErrorOf(409, "SLUG_TAKEN.")
  @ErrorOf(422, "VALIDATION_FAILED.")
  create(@Body() body: unknown, @Req() req: AuthenticatedRequest): Promise<LevelView> {
    return this.levels.create(parseInput(createLevelSchema, body), req.user.id);
  }

  @Post("import")
  @HttpCode(201)
  @ApiOperation({
    summary: "Import an exported level file into a NEW draft level.",
    description:
      "Never overwrites an existing level. The file is fully validated first (contract rules, " +
      "reference solution, par). Placement is never imported.",
  })
  @QueryOf(importQuerySchema)
  @BodyOf(importEnvelopeSchema)
  @ResponseOf(201, levelSchema, "The new level, with its draft.")
  @ErrorOf(409, "SLUG_TAKEN: import again with ?slug=.")
  @ErrorOf(
    422,
    "VALIDATION_FAILED (bad envelope), UNSUPPORTED_SCHEMA_VERSION, or LEVEL_VALIDATION_FAILED with issues.",
  )
  import(
    @Body() body: unknown,
    @Query() query: unknown,
    @Req() req: AuthenticatedRequest,
  ): Promise<LevelView> {
    const envelope = parseInput(importEnvelopeSchema, body);
    const { slug } = parseInput(importQuerySchema, query);
    return this.transfers.import(envelope, slug, req.user.id);
  }

  @Get(":id")
  @ApiOperation({ summary: "A level with its draft and live version (authoring content)." })
  @ResponseOf(200, levelSchema, "The level.")
  @ErrorOf(404, "NOT_FOUND.")
  get(@Param("id") id: string): Promise<LevelView> {
    return this.reads.get(id);
  }

  @Patch(":id")
  @ApiOperation({
    summary: "Save the draft (never publishes).",
    description:
      "Optimistic concurrency: send the draft's updatedAt as expectedUpdatedAt. If the draft " +
      "changed meanwhile the answer is 409 DRAFT_CONFLICT and nothing is written. A level with no " +
      "draft answers 409 NO_DRAFT (create one with POST /admin/levels/{id}/draft). The slug of a " +
      "level that was ever published cannot change (422 SLUG_LOCKED).",
  })
  @BodyOf(updateDraftSchema)
  @ResponseOf(200, levelSchema, "The level with the saved draft (use draft.updatedAt next).")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "DRAFT_CONFLICT, NO_DRAFT, or SLUG_TAKEN.")
  @ErrorOf(422, "VALIDATION_FAILED or SLUG_LOCKED.")
  save(
    @Param("id") id: string,
    @Body() body: unknown,
    @Req() req: AuthenticatedRequest,
  ): Promise<LevelView> {
    return this.levels.saveDraft(id, parseInput(updateDraftSchema, body), req.user.id);
  }

  @Delete(":id")
  @HttpCode(204)
  @ApiOperation({ summary: "Delete a level that was never published." })
  @ResponseOf(204, null, "Deleted.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "HAS_HISTORY: the level has been published; unpublish and archive it instead.")
  async remove(@Param("id") id: string): Promise<void> {
    await this.levels.deleteLevel(id);
  }

  @Post(":id/draft")
  @HttpCode(201)
  @ApiOperation({
    summary: "Start a new draft from the live version (edit a published level).",
    description: "Copies the live version, or the newest version when the level is unpublished.",
  })
  @ResponseOf(201, levelSchema, "The level with its new draft.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "DRAFT_EXISTS.")
  createDraft(@Param("id") id: string, @Req() req: AuthenticatedRequest): Promise<LevelView> {
    return this.levels.createDraft(id, req.user.id);
  }

  @Delete(":id/draft")
  @HttpCode(204)
  @ApiOperation({ summary: "Discard the draft of a level that has an earlier version." })
  @ResponseOf(204, null, "Discarded.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "NO_DRAFT, or NEVER_PUBLISHED (delete the level instead).")
  async discardDraft(@Param("id") id: string): Promise<void> {
    await this.levels.discardDraft(id);
  }

  @Post(":id/validate")
  @HttpCode(200)
  @ApiOperation({
    summary: "Validate the draft: contract rules, reference solution, solver par, mechanics.",
    description:
      "Always 200 with the findings. publish.failedGates lists everything the publish gates " +
      "would reject, in the same form as the PUBLISH_BLOCKED 422. The result is stored with the " +
      "draft without changing its updatedAt.",
  })
  @ResponseOf(200, validateResponseSchema, "Errors, warnings, par, and publish readiness.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "NO_DRAFT.")
  validate(@Param("id") id: string): Promise<ValidateResponse> {
    return this.publication.validate(id);
  }

  @Post(":id/publish")
  @HttpCode(200)
  @ApiOperation({
    summary: "Publish the draft as a new immutable version.",
    description:
      "Blocked (422 PUBLISH_BLOCKED, issues list every failed gate with gate, code, and path) " +
      "unless: the draft validates, the reference solution solves it, the budget is at least par, " +
      "a solved playtest exists for the current content, the minimum supported app version " +
      "supports the required mechanics, and the level is assigned to a chapter. Transactional.",
  })
  @ResponseOf(200, publishResponseSchema, "The published level.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "NO_DRAFT.")
  @ErrorOf(422, "PUBLISH_BLOCKED.")
  publish(@Param("id") id: string, @Req() req: AuthenticatedRequest) {
    return this.publication.publish(id, req.user.id);
  }

  @Post(":id/unpublish")
  @HttpCode(200)
  @ApiOperation({
    summary: "Remove the level from the public catalog.",
    description:
      "The live version becomes SUPERSEDED and stays for history. Devices keep copies they " +
      "already downloaded. archive: true also marks the level ARCHIVED.",
  })
  @BodyOf(unpublishBodySchema)
  @ResponseOf(200, levelSchema, "The level.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "NOT_PUBLISHED.")
  unpublish(
    @Param("id") id: string,
    @Body() body: unknown,
    @Req() req: AuthenticatedRequest,
  ): Promise<LevelView> {
    const { archive } = parseInput(unpublishBodySchema, body ?? {});
    return this.publication.unpublish(id, archive, req.user.id);
  }

  @Get(":id/versions")
  @ApiOperation({ summary: "Version history, newest first (without content)." })
  @ResponseOf(200, versionListSchema, "All versions.")
  @ErrorOf(404, "NOT_FOUND.")
  versions(@Param("id") id: string): Promise<{ items: VersionSummary[] }> {
    return this.reads.versions(id);
  }

  @Get(":id/versions/:versionId")
  @ApiOperation({ summary: "One version with its content and reference solution." })
  @ResponseOf(200, versionSchema, "The version.")
  @ErrorOf(404, "NOT_FOUND.")
  version(@Param("id") id: string, @Param("versionId") versionId: string): Promise<VersionView> {
    return this.reads.version(id, versionId);
  }

  @Post(":id/restore/:versionId")
  @HttpCode(201)
  @ApiOperation({ summary: "Restore an earlier version as the new draft." })
  @ResponseOf(201, levelSchema, "The level with the restored draft.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "DRAFT_EXISTS: discard the current draft first.")
  restore(
    @Param("id") id: string,
    @Param("versionId") versionId: string,
    @Req() req: AuthenticatedRequest,
  ): Promise<LevelView> {
    return this.levels.restore(id, versionId, req.user.id);
  }

  @Post(":id/duplicate")
  @HttpCode(201)
  @ApiOperation({ summary: "Clone as a new draft level (unplaced, never published)." })
  @BodyOf(duplicateBodySchema)
  @ResponseOf(201, levelSchema, "The new level.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "SLUG_TAKEN.")
  duplicate(
    @Param("id") id: string,
    @Body() body: unknown,
    @Req() req: AuthenticatedRequest,
  ): Promise<LevelView> {
    return this.levels.duplicate(id, parseInput(duplicateBodySchema, body ?? {}), req.user.id);
  }

  @Get(":id/playtests")
  @ApiOperation({ summary: "Playtest records for the level, newest first." })
  @ResponseOf(200, playtestListSchema, "Records; current marks those matching the draft content.")
  @ErrorOf(404, "NOT_FOUND.")
  playtests(@Param("id") id: string): Promise<{ items: PlaytestView[] }> {
    return this.playtestRecords.listPlaytests(id);
  }

  @Post(":id/playtests")
  @HttpCode(201)
  @ApiOperation({
    summary: "Record a playtest of the current draft content.",
    description:
      "The record is tied to the draft's contentHash and goes stale when content changes.",
  })
  @BodyOf(playtestBodySchema)
  @ResponseOf(201, playtestSchema, "The record.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(409, "NO_DRAFT.")
  createPlaytest(
    @Param("id") id: string,
    @Body() body: unknown,
    @Req() req: AuthenticatedRequest,
  ): Promise<PlaytestView> {
    return this.playtestRecords.createPlaytest(
      id,
      parseInput(playtestBodySchema, body),
      req.user.id,
    );
  }

  @Get(":id/export")
  @ApiOperation({
    summary: "Export a validated level as a JSON envelope.",
    description: "Contains the level content and reference solution; never placement or playtests.",
  })
  @QueryOf(exportQuerySchema)
  @ResponseOf(200, exportEnvelopeSchema, "The envelope, ready to import.")
  @ErrorOf(404, "NOT_FOUND.")
  @ErrorOf(422, "LEVEL_VALIDATION_FAILED: only a valid level can be exported.")
  export(@Param("id") id: string, @Query() query: unknown): Promise<ExportEnvelope> {
    const { version } = parseInput(exportQuerySchema, query);
    return this.transfers.export(id, version);
  }
}
