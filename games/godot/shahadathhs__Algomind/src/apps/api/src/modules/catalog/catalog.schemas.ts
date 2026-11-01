import { z } from "zod";
import { parSchema } from "../levels/levels.schemas.js";

export const catalogLevelSchema = z.object({
  id: z.string().describe("Stable level id; progress is keyed by it."),
  slug: z.string(),
  title: z.string(),
  difficulty: z.enum(["easy", "medium", "hard"]),
  number: z.number().int().describe("Position in the whole campaign, from 1."),
  worldId: z.string(),
  chapterId: z.string(),
  levelVersion: z.number().int().describe("Changes when the level is republished."),
  schemaVersion: z.number().int(),
  par: parSchema.describe("The shortest solution, for the best result display."),
  maxCommands: z.number().int(),
  requiredMechanics: z
    .array(z.string())
    .describe("Mechanics the app must support; skip the level when it lacks one."),
});
export type CatalogLevel = z.infer<typeof catalogLevelSchema>;

export const catalogChapterSchema = z.object({
  id: z.string(),
  title: z.string(),
  order: z.number().int(),
  levels: z.array(catalogLevelSchema).describe("In play order."),
});

export const catalogWorldSchema = z.object({
  id: z.string(),
  title: z.string(),
  description: z.string(),
  order: z.number().int(),
  chapters: z.array(catalogChapterSchema).describe("Only chapters with a published level."),
});

export const campaignSchema = z.object({
  worlds: z.array(catalogWorldSchema).describe("Only worlds with a published level, in order."),
});
export type Campaign = z.infer<typeof campaignSchema>;

export const campaignBoardsSchema = z.object({
  items: z
    .array(
      z.object({
        slug: z.string(),
        boardCount: z.number().int().describe("1, or more when the level has test boards."),
        content: z
          .record(z.string(), z.unknown())
          .describe("Only what draws the board: its size, walls, start, goal and tiles."),
      }),
    )
    .describe("Every level of the campaign, in campaign order."),
});
export type CampaignBoards = z.infer<typeof campaignBoardsSchema>;

export const levelListSchema = z.object({
  items: z.array(catalogLevelSchema).describe("Flattened campaign order."),
});
export type LevelList = z.infer<typeof levelListSchema>;

export const publicLevelSchema = z.object({
  id: z.string(),
  slug: z.string(),
  schemaVersion: z.number().int(),
  levelVersion: z.number().int(),
  par: parSchema,
  requiredMechanics: z.array(z.string()),
  publishedAt: z.string().describe("ISO 8601"),
  content: z
    .record(z.string(), z.unknown())
    .describe("The level definition in the level contract format (no reference solution)."),
});
export type PublicLevel = z.infer<typeof publicLevelSchema>;
