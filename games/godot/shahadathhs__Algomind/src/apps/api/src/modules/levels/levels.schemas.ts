import { DIFFICULTIES, ID_PATTERN } from "@algomind/level-contract";
import { z } from "zod";

// ---- shared pieces --------------------------------------------------------------------------

const iso = z.string().describe("ISO 8601 timestamp");
const slug = z
  .string()
  .min(1)
  .max(64)
  .regex(new RegExp(ID_PATTERN), "lowercase words with hyphens");
const jsonObject = z.record(z.string(), z.unknown());
const program = z.array(z.unknown()).max(256);

export const GATES = [
  "validation",
  "reference_solution",
  "start_program",
  "par",
  "playtest",
  "compatibility",
  "placement",
] as const;

export const checkIssueSchema = z.object({
  gate: z.enum(GATES).describe("The check that produced the issue."),
  path: z.string().describe("Field path, e.g. board.width, referenceSolution, chapterId."),
  code: z.string().describe("Stable machine-readable code."),
  message: z.string().describe("Human-readable text; do not match on it."),
});
export type CheckIssue = z.infer<typeof checkIssueSchema>;

export const parSchema = z.object({
  commands: z.number().int().describe("Fewest commands that solve the level."),
  steps: z.number().int(),
});
export type Par = z.infer<typeof parSchema>;

export const validationSummarySchema = z.object({
  ok: z.boolean().describe("True when there are no errors."),
  errors: z.array(checkIssueSchema),
  warnings: z.array(checkIssueSchema),
  par: parSchema.nullable().describe("Null when the level is invalid or unsolvable."),
  referenceSolved: z.boolean(),
  requiredMechanics: z.array(z.string()),
  contentHash: z.string(),
  validatedAt: iso,
});
export type ValidationSummary = z.infer<typeof validationSummarySchema>;

// ---- responses ------------------------------------------------------------------------------

export const versionSummarySchema = z.object({
  id: z.string(),
  versionNumber: z.number().int(),
  schemaVersion: z.number().int(),
  state: z.enum(["DRAFT", "PUBLISHED", "SUPERSEDED"]),
  par: parSchema.nullable(),
  contentHash: z.string(),
  validationSummary: validationSummarySchema.nullable().describe("Result of the last validate."),
  createdBy: z.string().nullable(),
  createdAt: iso,
  updatedAt: iso.describe("For a draft, send this back as expectedUpdatedAt when saving."),
  publishedAt: iso.nullable(),
});
export type VersionSummary = z.infer<typeof versionSummarySchema>;

export const versionSchema = versionSummarySchema.extend({
  content: jsonObject.describe("The level definition (the public level contract)."),
  referenceSolution: z.array(z.unknown()).describe("Never served by public endpoints."),
});
export type VersionView = z.infer<typeof versionSchema>;

export const placementSchema = z.object({
  chapterId: z.string().nullable(),
  chapterTitle: z.string().nullable(),
  worldId: z.string().nullable(),
  worldTitle: z.string().nullable(),
  orderInChapter: z.number().int(),
});

export const playtestStateSchema = z
  .enum(["NONE", "STALE", "FAILED", "SOLVED"])
  .describe(
    "For the draft: NONE (no records), STALE (records exist but none for the current content), " +
      "FAILED (only failed records for the current content), SOLVED (a solved record exists for the current content).",
  );

export const levelSummarySchema = z.object({
  id: z.string(),
  slug: z.string(),
  title: z.string(),
  difficulty: z.string(),
  status: z.enum(["DRAFT", "PUBLISHED", "ARCHIVED"]),
  placement: placementSchema,
  publishedVersion: z.number().int().nullable().describe("versionNumber of the live version."),
  draftVersion: z.number().int().nullable().describe("versionNumber of the working draft."),
  draftAhead: z.boolean().describe("A published level that has a newer draft."),
  par: parSchema
    .nullable()
    .describe("Par of the draft when there is one, else of the live version."),
  playtestState: playtestStateSchema.nullable().describe("Null when the level has no draft."),
  createdAt: iso,
  updatedAt: iso,
});
export type LevelSummary = z.infer<typeof levelSummarySchema>;

export const levelSchema = levelSummarySchema.extend({
  currentPublishedVersionId: z.string().nullable(),
  draft: versionSchema.nullable().describe("The working copy, if any."),
  published: versionSchema.nullable().describe("The version players get, if any."),
  playtests: z.object({
    count: z.number().int().describe("Records for the draft's versions of this level."),
    solvedForCurrentContent: z.boolean(),
  }),
});
export type LevelView = z.infer<typeof levelSchema>;

export const levelPageSchema = z.object({
  items: z.array(levelSummarySchema),
  total: z.number().int(),
  page: z.number().int(),
  pageSize: z.number().int(),
});
export type LevelPage = z.infer<typeof levelPageSchema>;

export const versionListSchema = z.object({
  items: z.array(versionSummarySchema).describe("Newest version first."),
});

export const validateResponseSchema = validationSummarySchema.extend({
  publish: z.object({
    ready: z.boolean().describe("Every publish gate passes."),
    failedGates: z.array(checkIssueSchema).describe("What publish would reject, in the same form."),
  }),
  playtests: z.object({ count: z.number().int(), solvedForCurrentContent: z.boolean() }),
  compatibility: z.object({
    minimumVersion: z.string().nullable(),
    unsupportedMechanics: z.array(z.string()),
  }),
});
export type ValidateResponse = z.infer<typeof validateResponseSchema>;

export const playtestSchema = z.object({
  id: z.string(),
  levelVersionId: z.string(),
  versionNumber: z.number().int(),
  contentHash: z.string(),
  current: z.boolean().describe("Its contentHash equals the draft's."),
  testerName: z.string(),
  solved: z.boolean(),
  commandsUsed: z.number().int().nullable(),
  perceivedDifficulty: z.enum(DIFFICULTIES).nullable(),
  notes: z.string(),
  createdAt: iso,
});
export type PlaytestView = z.infer<typeof playtestSchema>;

export const playtestListSchema = z.object({ items: z.array(playtestSchema) });

export const publishResponseSchema = z.object({
  level: levelSchema,
  publishedVersionId: z.string(),
});

export const exportEnvelopeSchema = z.object({
  format: z.literal("algomind-level"),
  schemaVersion: z.number().int().describe("Contract schema version of the level."),
  exportedAt: iso,
  meta: z.object({ title: z.string(), slug: z.string() }),
  level: jsonObject.describe("The level content (public contract form)."),
  referenceSolution: z.array(z.unknown()),
});
export type ExportEnvelope = z.infer<typeof exportEnvelopeSchema>;

// ---- requests -------------------------------------------------------------------------------

export const listLevelsQuerySchema = z.object({
  q: z.string().trim().max(80).optional().describe("Substring of the title or slug."),
  status: z.enum(["DRAFT", "PUBLISHED", "ARCHIVED"]).optional(),
  difficulty: z.enum(DIFFICULTIES).optional(),
  worldId: z.string().max(64).optional(),
  chapterId: z.string().max(64).optional(),
  unassigned: z.enum(["true", "false"]).optional().describe("true: only levels with no chapter."),
  hasDraft: z.enum(["true", "false"]).optional(),
  sort: z.enum(["updatedAt", "createdAt", "title", "slug"]).default("updatedAt"),
  order: z.enum(["asc", "desc"]).default("desc"),
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(25),
});
export type ListLevelsQuery = z.infer<typeof listLevelsQuerySchema>;

export const createLevelSchema = z.object({
  slug,
  title: z.string().min(1).max(60),
  difficulty: z.enum(DIFFICULTIES).default("easy"),
  content: jsonObject
    .optional()
    .describe("A full or partial level definition. A starter board is used when omitted."),
  referenceSolution: program.optional(),
});
export type CreateLevel = z.infer<typeof createLevelSchema>;

export const updateDraftSchema = z
  .object({
    expectedUpdatedAt: z.iso
      .datetime()
      .describe("The draft's updatedAt as last read. A mismatch answers 409 DRAFT_CONFLICT."),
    content: jsonObject
      .optional()
      .describe("Replaces the draft content. May be incomplete; validate reports problems."),
    referenceSolution: program.optional(),
  })
  .refine((v) => v.content !== undefined || v.referenceSolution !== undefined, {
    message: "send content, referenceSolution, or both",
    path: ["content"],
  });
export type UpdateDraft = z.infer<typeof updateDraftSchema>;

export const playtestBodySchema = z.object({
  testerName: z.string().trim().min(1).max(80),
  solved: z.boolean(),
  commandsUsed: z.number().int().min(0).max(1000).optional(),
  perceivedDifficulty: z.enum(DIFFICULTIES).optional(),
  notes: z.string().max(1000).default(""),
});
export type PlaytestBody = z.infer<typeof playtestBodySchema>;

export const unpublishBodySchema = z.object({
  archive: z.boolean().default(false).describe("Also mark the level ARCHIVED."),
});

export const duplicateBodySchema = z.object({
  slug: slug.optional().describe("Defaults to <slug>-copy."),
  title: z.string().min(1).max(60).optional(),
});

export const importEnvelopeSchema = z.object({
  format: z.literal("algomind-level"),
  schemaVersion: z.number().int(),
  exportedAt: z.string().max(40).optional(),
  meta: z.object({ title: z.string().max(200), slug: z.string().max(100) }).optional(),
  level: jsonObject,
  referenceSolution: program,
});
export const importQuerySchema = z.object({
  slug: slug.optional().describe("Import under this slug instead of the one in the file."),
});
