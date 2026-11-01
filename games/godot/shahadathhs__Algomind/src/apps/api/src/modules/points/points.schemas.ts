import { z } from "zod";

const points = z.number().int().min(0).max(1000);

/** A rule set as the dashboard edits it. The version is assigned by the server. */
export const pointsRulesInputSchema = z
  .object({
    base: z.object({ easy: points, medium: points, hard: points }).strict(),
    parFull: points,
    parNear: points,
    nearSlots: z.number().int().min(0).max(10),
    stepsBonus: points,
    firstClear: points,
  })
  .strict();
export type PointsRulesInput = z.infer<typeof pointsRulesInputSchema>;

export const pointsRulesSchema = pointsRulesInputSchema.extend({
  version: z.number().int().min(1),
});

export const ruleSetViewSchema = z.object({
  version: z.number().int(),
  rules: pointsRulesSchema,
  active: z.boolean(),
  createdAt: z.string(),
});
export type RuleSetView = z.infer<typeof ruleSetViewSchema>;

const node = z
  .object({
    op: z.string().min(1).max(32),
    count: z.number().int().optional(),
    body: z
      .array(z.object({ op: z.string().min(1).max(32) }).strict())
      .max(16)
      .optional(),
  })
  .strict();

/** What the game submits: the level version it played and the program. Never a score. */
export const submissionBodySchema = z.object({
  levelSlug: z
    .string()
    .min(1)
    .max(64)
    .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/),
  levelVersion: z.number().int().min(1).max(1_000_000),
  program: z.array(node).min(1).max(64),
  /** Claims the result for a daily challenge: the UTC date of the day it was played. */
  dailyDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional(),
});
export type SubmissionBody = z.infer<typeof submissionBodySchema>;

export type SubmissionResult = {
  /** True when this exact program was already submitted for this level version. */
  duplicate: boolean;
  verified: { slots: number; steps: number };
  stars: 1 | 2 | 3;
  /** What the result is worth, first-clear bonus included. */
  points: number;
  /** What this submission added to the player's total (0 when it did not beat an earlier result). */
  awarded: number;
  total: number;
  ruleVersion: number;
  /** Set when the submission claimed a daily challenge: whether it counted, and the streak. */
  daily?: { accepted: boolean; streak: { current: number; best: number } };
  /** Badges this submission earned just now. */
  achievements?: { slug: string; title: string }[];
};

export type PointsView = {
  total: number;
  levels: { levelSlug: string; stars: number; points: number }[];
};
