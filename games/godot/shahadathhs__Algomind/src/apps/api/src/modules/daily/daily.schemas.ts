import { z } from "zod";
import { DATE_PATTERN } from "./dates.js";

export const dateParamSchema = z.string().regex(DATE_PATTERN);
export const slugBodySchema = z
  .object({
    levelSlug: z
      .string()
      .min(1)
      .max(64)
      .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/),
  })
  .strict();
export const poolBodySchema = z.object({ pool: z.boolean() }).strict();
export const scheduleQuerySchema = z.object({
  from: z.string().regex(DATE_PATTERN).optional(),
  days: z.coerce.number().int().min(1).max(90).default(30),
});

/** One day's challenge: which level, and what a player needs to know before opening it. */
export type DailyEntry = {
  date: string;
  levelSlug: string;
  levelVersion: number;
  title: string;
  difficulty: string;
  maxCommands: number;
  par: number;
  /** "scheduled" when an admin chose it, "rotation" when the pool's rotation did. */
  source: "scheduled" | "rotation";
};

export type DailyView = {
  /** The server's UTC date, so a device with a wrong clock still asks for the right day. */
  serverDate: string;
  today: DailyEntry | null;
  /** The next few days, so the game can cache them for offline play. */
  upcoming: DailyEntry[];
};

export type MyDailyView = {
  date: string;
  levelSlug: string | null;
  result: { slots: number; steps: number; stars: number } | null;
  streak: { current: number; best: number };
};

export type PoolLevel = {
  slug: string;
  title: string;
  difficulty: string;
  pool: boolean;
  inCampaign: boolean;
};
