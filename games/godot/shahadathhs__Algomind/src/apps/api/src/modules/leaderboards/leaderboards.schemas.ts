import { z } from "zod";
import { DATE_PATTERN } from "../daily/dates.js";

const paging = {
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).max(100_000).default(0),
};

export const pointsQuerySchema = z.object({
  period: z.enum(["all", "week", "month"]).default("all"),
  ...paging,
});
export const boardQuerySchema = z.object(paging);
export const dateParamSchema = z.string().regex(DATE_PATTERN);
export const slugParamSchema = z
  .string()
  .min(1)
  .max(64)
  .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/);

export const reportBodySchema = z
  .object({
    publicId: z.string().min(8).max(64),
    reason: z.string().trim().min(3).max(200),
  })
  .strict();

/** One row of a board. The name is "Anonymous" for a player who chose to hide it. */
export type BoardEntry = {
  rank: number;
  /** What to report or compare; never the account id or the email. */
  publicId: string;
  name: string;
  /** Points boards. */
  points?: number;
  /** Level and daily boards. */
  slots?: number;
  steps?: number;
  you: boolean;
};

export type BoardView = {
  /** Players ranked on this board. */
  total: number;
  entries: BoardEntry[];
  /** The signed-in player's place, if they are on the board: their entry and the ones around it. */
  me: { entry: BoardEntry; around: BoardEntry[] } | null;
};
