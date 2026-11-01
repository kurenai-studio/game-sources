import { z } from "zod";

export const listPlayersQuerySchema = z.object({
  q: z.string().trim().max(100).optional(),
  status: z.enum(["ACTIVE", "SUSPENDED"]).optional(),
  sort: z.enum(["lastActive", "points", "cleared", "created", "email"]).default("lastActive"),
  order: z.enum(["asc", "desc"]).default("desc"),
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(25),
});
export type ListPlayersQuery = z.infer<typeof listPlayersQuerySchema>;

/** A name shown to other players: letters, digits, spaces and a few separators. Null clears it. */
export const displayNameBodySchema = z.object({
  displayName: z
    .string()
    .trim()
    .min(2)
    .max(24)
    .regex(/^[\p{L}\p{N}][\p{L}\p{N} ._-]*$/u, "letters, digits, spaces, dots, dashes")
    .nullable(),
});

export const deletePlayerSchema = z.object({ confirmEmail: z.string().min(1).max(254) });

export type PlayerSummary = {
  id: string;
  email: string;
  displayName: string | null;
  status: "ACTIVE" | "SUSPENDED";
  createdAt: string;
  lastActiveAt: string | null;
  /** On a leaderboard by their own choice, and whether an admin hid them. */
  leaderboardOptIn: boolean;
  leaderboardHidden: boolean;
  levelsCleared: number;
  points: number;
};
export type PlayerPage = { items: PlayerSummary[]; total: number; page: number; pageSize: number };

export type PlayerDetail = {
  account: Omit<PlayerSummary, "levelsCleared" | "points"> & {
    publicId: string;
    leaderboardOptIn: boolean;
    hideName: boolean;
    leaderboardHidden: boolean;
  };
  progress: {
    levelSlug: string;
    levelVersion: number;
    bestCommands: number;
    completedAt: string;
  }[];
  points: {
    total: number;
    history: {
      createdAt: string;
      reason: string;
      delta: number;
      levelSlug: string | null;
      ruleVersion: number;
    }[];
  };
  sessions: { familyId: string; startedAt: string; lastUsedAt: string; expiresAt: string }[];
  settings: { settings: unknown; updatedAt: string } | null;
  lastSyncAt: string | null;
};
