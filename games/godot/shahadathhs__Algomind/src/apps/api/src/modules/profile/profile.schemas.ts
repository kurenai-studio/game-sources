import { z } from "zod";
import type { RankView } from "./ranks.js";

/** What a player may change about how they appear to others. Every field is optional. */
export const profileBodySchema = z
  .object({
    /** The name shown on boards; null clears it. Checked by name-rules.ts. */
    displayName: z.string().trim().min(1).max(40).nullable().optional(),
    /** Appear on the leaderboards. Off until the player turns it on. */
    leaderboardOptIn: z.boolean().optional(),
    /** Appear as "Anonymous" instead of the name. */
    hideName: z.boolean().optional(),
  })
  .strict();
export type ProfileBody = z.infer<typeof profileBodySchema>;

export type ProfileView = {
  displayName: string | null;
  leaderboardOptIn: boolean;
  hideName: boolean;
  /** What other players see and what a report names. Safe to show; it is not the account id. */
  publicId: string;
  total: number;
  rank: RankView;
};
