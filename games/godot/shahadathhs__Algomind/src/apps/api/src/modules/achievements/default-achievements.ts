import type { AchievementRule } from "./achievement-rules.js";

/** The badges a fresh install starts with. The dashboard can change, add, and switch off any. */
export const DEFAULT_ACHIEVEMENTS: readonly {
  slug: string;
  title: string;
  description: string;
  rule: AchievementRule;
}[] = [
  {
    slug: "first-clear",
    title: "First clear",
    description: "Solve a level.",
    rule: { type: "levels_solved", value: 1 },
  },
  {
    slug: "ten-levels",
    title: "Ten levels",
    description: "Solve ten levels.",
    rule: { type: "levels_solved", value: 10 },
  },
  {
    slug: "twenty-five-levels",
    title: "Twenty-five levels",
    description: "Solve twenty-five levels.",
    rule: { type: "levels_solved", value: 25 },
  },
  {
    slug: "on-par",
    title: "On par",
    description: "Match par on five levels.",
    rule: { type: "par_levels", value: 5 },
  },
  {
    slug: "par-twenty",
    title: "Par twenty",
    description: "Match par on twenty levels.",
    rule: { type: "par_levels", value: 20 },
  },
  {
    slug: "star-collector",
    title: "Star collector",
    description: "Earn thirty stars.",
    rule: { type: "stars_total", value: 30 },
  },
  {
    slug: "first-loop",
    title: "First loop",
    description: "Solve your first level with a loop.",
    rule: { type: "level_solved", slug: "say-it-once" },
  },
  {
    slug: "top-of-the-stairs",
    title: "Top of the stairs",
    description: "Solve the last level of the Loops world.",
    rule: { type: "level_solved", slug: "final-climb" },
  },
  {
    slug: "daily-first",
    title: "Daily start",
    description: "Solve a daily challenge.",
    rule: { type: "daily_solved", value: 1 },
  },
  {
    slug: "streak-three",
    title: "Three in a row",
    description: "Solve the daily challenge three days in a row.",
    rule: { type: "streak", value: 3 },
  },
  {
    slug: "streak-seven",
    title: "A full week",
    description: "Solve the daily challenge seven days in a row.",
    rule: { type: "streak", value: 7 },
  },
  {
    slug: "five-hundred",
    title: "Five hundred",
    description: "Reach 500 points.",
    rule: { type: "points_total", value: 500 },
  },
];
