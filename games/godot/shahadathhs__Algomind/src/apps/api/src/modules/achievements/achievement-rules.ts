import { z } from "zod";

/** A badge's condition, as data the dashboard edits. */
export const achievementRuleSchema = z.discriminatedUnion("type", [
  z
    .object({ type: z.literal("levels_solved"), value: z.number().int().min(1).max(10_000) })
    .strict(),
  z
    .object({ type: z.literal("stars_total"), value: z.number().int().min(1).max(100_000) })
    .strict(),
  z.object({ type: z.literal("par_levels"), value: z.number().int().min(1).max(10_000) }).strict(),
  z
    .object({ type: z.literal("points_total"), value: z.number().int().min(1).max(10_000_000) })
    .strict(),
  z.object({ type: z.literal("streak"), value: z.number().int().min(1).max(3650) }).strict(),
  z
    .object({ type: z.literal("daily_solved"), value: z.number().int().min(1).max(10_000) })
    .strict(),
  z
    .object({
      type: z.literal("level_solved"),
      slug: z
        .string()
        .min(1)
        .max(64)
        .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/),
    })
    .strict(),
]);
export type AchievementRule = z.infer<typeof achievementRuleSchema>;

/** What a player has done, as the rules read it. */
export type PlayerStats = {
  levelsSolved: number;
  starsTotal: number;
  parLevels: number;
  points: number;
  streak: number;
  dailySolved: number;
  solvedSlugs: ReadonlySet<string>;
};

/** True when the player's stats satisfy the rule. Pure. */
export function ruleMet(rule: AchievementRule, stats: PlayerStats): boolean {
  switch (rule.type) {
    case "levels_solved":
      return stats.levelsSolved >= rule.value;
    case "stars_total":
      return stats.starsTotal >= rule.value;
    case "par_levels":
      return stats.parLevels >= rule.value;
    case "points_total":
      return stats.points >= rule.value;
    case "streak":
      return stats.streak >= rule.value;
    case "daily_solved":
      return stats.dailySolved >= rule.value;
    case "level_solved":
      return stats.solvedSlugs.has(rule.slug);
  }
}

/** A short plain-language description of a rule, for the dashboard list. */
export function describeRule(rule: AchievementRule): string {
  switch (rule.type) {
    case "levels_solved":
      return `Solve ${rule.value} ${rule.value === 1 ? "level" : "levels"}`;
    case "stars_total":
      return `Earn ${rule.value} ${rule.value === 1 ? "star" : "stars"} in total`;
    case "par_levels":
      return `Match par on ${rule.value} ${rule.value === 1 ? "level" : "levels"}`;
    case "points_total":
      return `Reach ${rule.value} points`;
    case "streak":
      return `A streak of ${rule.value} ${rule.value === 1 ? "day" : "days"}`;
    case "daily_solved":
      return `Solve ${rule.value} daily ${rule.value === 1 ? "challenge" : "challenges"}`;
    case "level_solved":
      return `Solve the level ${rule.slug}`;
  }
}
