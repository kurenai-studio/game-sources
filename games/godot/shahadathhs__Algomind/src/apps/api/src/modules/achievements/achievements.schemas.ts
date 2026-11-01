import { z } from "zod";
import { achievementRuleSchema, type AchievementRule } from "./achievement-rules.js";

const slug = z
  .string()
  .min(2)
  .max(48)
  .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/);

export const achievementInputSchema = z
  .object({
    slug,
    title: z.string().trim().min(2).max(40),
    description: z.string().trim().min(2).max(140),
    rule: achievementRuleSchema,
    active: z.boolean().default(true),
    position: z.number().int().min(0).max(1000).default(0),
  })
  .strict();
export type AchievementInput = z.infer<typeof achievementInputSchema>;

export const achievementUpdateSchema = achievementInputSchema
  .omit({ slug: true })
  .partial()
  .strict();

/** What a player sees: every active badge, earned or not. */
export type MyAchievement = {
  slug: string;
  title: string;
  description: string;
  earnedAt: string | null;
};

/** What the dashboard sees: the badge, its rule in words, and how many players have it. */
export type AdminAchievement = {
  id: string;
  slug: string;
  title: string;
  description: string;
  rule: AchievementRule;
  ruleText: string;
  active: boolean;
  position: number;
  earnedBy: number;
};

/** A badge a submission earned just now, so the game can say so. */
export type EarnedNow = { slug: string; title: string };
