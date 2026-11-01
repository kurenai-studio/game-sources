import { z } from "zod";
import { levelSummarySchema } from "../levels/levels.schemas.js";

const iso = z.string().describe("ISO 8601 timestamp");

export const worldSchema = z.object({
  id: z.string(),
  title: z.string(),
  description: z.string(),
  order: z.number().int().describe("Position among worlds, from 0."),
  chapterCount: z.number().int(),
  createdAt: iso,
  updatedAt: iso,
});
export type WorldView = z.infer<typeof worldSchema>;
export const worldListSchema = z.object({ items: z.array(worldSchema).describe("In order.") });

export const chapterSchema = z.object({
  id: z.string(),
  worldId: z.string(),
  title: z.string(),
  order: z.number().int().describe("Position inside the world, from 0."),
  levelCount: z.number().int(),
  createdAt: iso,
  updatedAt: iso,
});
export type ChapterView = z.infer<typeof chapterSchema>;
export const chapterListSchema = z.object({ items: z.array(chapterSchema).describe("In order.") });

export const createWorldSchema = z.object({
  title: z.string().trim().min(1).max(60),
  description: z.string().max(280).default(""),
});
export const updateWorldSchema = z
  .object({
    title: z.string().trim().min(1).max(60).optional(),
    description: z.string().max(280).optional(),
  })
  .refine((v) => Object.keys(v).length > 0, "send at least one field");

export const createChapterSchema = z.object({
  worldId: z.string().min(1).max(64),
  title: z.string().trim().min(1).max(60),
});
export const updateChapterSchema = z.object({ title: z.string().trim().min(1).max(60) });
export const listChaptersQuerySchema = z.object({
  worldId: z.string().max(64).optional().describe("Only chapters of this world."),
});

export const adminCampaignSchema = z.object({
  worlds: z.array(
    worldSchema.omit({ chapterCount: true }).extend({
      chapters: z.array(
        chapterSchema.omit({ levelCount: true }).extend({
          levels: z.array(levelSummarySchema).describe("In play order."),
        }),
      ),
    }),
  ),
  unassigned: z.array(levelSummarySchema).describe("Levels with no chapter; never reach players."),
});
export type AdminCampaign = z.infer<typeof adminCampaignSchema>;

export const orderBodySchema = z.object({
  worlds: z
    .array(
      z.object({
        id: z.string().min(1).max(64),
        chapters: z
          .array(
            z.object({
              id: z.string().min(1).max(64),
              levels: z.array(z.string().min(1).max(64)).max(500),
            }),
          )
          .max(100),
      }),
    )
    .max(100)
    .describe(
      "The complete campaign. List every world and every chapter, each exactly once, in the " +
        "wanted order; a chapter may move to another world. Levels listed under a chapter are " +
        "assigned to it in that order; levels listed nowhere become unassigned.",
    ),
});
export type OrderBody = z.infer<typeof orderBodySchema>;
