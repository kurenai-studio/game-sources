import type { AchievementRule } from "./social-api";

type CountType = Exclude<AchievementRule["type"], "level_solved">;

/** The rule types in the order the form offers them, with what the number counts. */
export const RULE_TYPES: { type: AchievementRule["type"]; label: string; unit: string }[] = [
  { type: "levels_solved", label: "Levels solved", unit: "levels" },
  { type: "stars_total", label: "Stars earned", unit: "stars" },
  { type: "par_levels", label: "Levels solved at par", unit: "levels" },
  { type: "points_total", label: "Points earned", unit: "points" },
  { type: "streak", label: "Daily streak", unit: "days" },
  { type: "daily_solved", label: "Daily challenges solved", unit: "days" },
  { type: "level_solved", label: "One specific level solved", unit: "" },
];

export type RuleDraft = { type: AchievementRule["type"]; value: string; slug: string };

export function draftFromRule(rule: AchievementRule): RuleDraft {
  return rule.type === "level_solved"
    ? { type: rule.type, value: "", slug: rule.slug }
    : { type: rule.type, value: String(rule.value), slug: "" };
}

/** The rule a draft describes, or a sentence saying what is missing. */
export function ruleFromDraft(draft: RuleDraft): AchievementRule | string {
  if (draft.type === "level_solved") {
    const slug = draft.slug.trim();
    return slug ? { type: "level_solved", slug } : "Enter the slug of the level.";
  }
  const value = Number(draft.value);
  if (!Number.isInteger(value) || value < 1) return "Enter a whole number of at least 1.";
  return { type: draft.type as CountType, value };
}
