import { z } from "zod";

const slug = z
  .string()
  .min(1)
  .max(64)
  .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/, "lowercase letters, digits, and single hyphens");

/** Unix seconds (fractions allowed): what the game stores. */
const seconds = z.number().min(0).max(4_102_444_800);

/** The settings that follow a player. Unknown keys are refused, so nothing else gets stored. */
export const syncedSettingsSchema = z
  .object({
    theme: z.enum(["system", "light", "dark"]).optional(),
    reduceMotion: z.boolean().optional(),
    sound: z.boolean().optional(),
    music: z.boolean().optional(),
    vibration: z.boolean().optional(),
    runSpeed: z.enum(["slow", "normal", "fast"]).optional(),
  })
  .strict();

export const settingsPayloadSchema = z.object({
  settings: syncedSettingsSchema,
  updatedAt: seconds.describe("When the player last changed them, in Unix seconds."),
});

export const completionSchema = z.object({
  levelSlug: slug,
  levelVersion: z.number().int().min(1).max(1_000_000),
  bestCommands: z.number().int().min(1).max(64),
  completedAt: seconds.optional(),
});

export const syncBodySchema = z.object({
  completed: z.array(completionSchema).max(1000),
  settings: settingsPayloadSchema.optional(),
});

export const deleteAccountSchema = z.object({ password: z.string().min(1).max(128) });

export type Completion = z.infer<typeof completionSchema>;
export type SyncBody = z.infer<typeof syncBodySchema>;
export type SettingsPayload = z.infer<typeof settingsPayloadSchema>;

export type ProgressView = {
  completed: {
    levelSlug: string;
    levelVersion: number;
    bestCommands: number;
    completedAt: number;
  }[];
  settings: SettingsPayload | null;
};
