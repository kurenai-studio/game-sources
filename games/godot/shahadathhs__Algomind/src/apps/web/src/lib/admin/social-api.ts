import type { ApiClient } from "@/lib/api/client";
import type { Difficulty } from "./admin-api";

/** Shapes and calls of the social admin API: daily challenge, badges, reports, level statistics. */

export type DailyDay =
  | {
      date: string;
      levelSlug: string;
      levelVersion: number;
      title: string;
      difficulty: Difficulty;
      maxCommands: number;
      par: number;
      source: "scheduled" | "rotation";
    }
  | { date: string; levelSlug: null };

export type PoolLevel = {
  slug: string;
  title: string;
  difficulty: Difficulty;
  pool: boolean;
  inCampaign: boolean;
};

export type AchievementRule =
  | {
      type:
        "levels_solved" | "stars_total" | "par_levels" | "points_total" | "streak" | "daily_solved";
      value: number;
    }
  | { type: "level_solved"; slug: string };

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

export type AchievementInput = {
  slug: string;
  title: string;
  description: string;
  rule: AchievementRule;
  active?: boolean;
  position?: number;
};
export type AchievementPatch = Partial<Omit<AchievementInput, "slug">>;

export type ReportAction = "dismiss" | "clear_name" | "hide";
export type AdminReport = {
  id: string;
  status: string;
  reason: string;
  createdAt: string;
  resolvedAt: string | null;
  target: {
    id: string;
    publicId: string;
    displayName: string | null;
    hideName: boolean;
    leaderboardHidden: boolean;
  } | null;
};

export type LevelStat = {
  slug: string;
  title: string;
  difficulty: Difficulty;
  world: string | null;
  chapter: string | null;
  pool: boolean;
  par: number;
  limit: number;
  solvers: number;
  avgSlots: number;
  atPar: number;
  nearPar: number;
};

export type ContactInput = {
  displayName: string;
  email: string;
  github: string;
  website: string;
  issues: string;
  note: string;
};
export type AdminContact = ContactInput & { updatedAt: string; updatedByEmail: string | null };

export function socialApi(client: ApiClient) {
  return {
    listDaily: (from: string, days: number) =>
      client.get<{ items: DailyDay[] }>(`admin/daily?from=${from}&days=${days}`),
    scheduleDay: (date: string, levelSlug: string) =>
      client.put<unknown>(`admin/daily/${date}`, { levelSlug }),
    clearDay: (date: string) => client.delete<unknown>(`admin/daily/${date}`),
    listPool: () => client.get<{ items: PoolLevel[] }>("admin/daily/pool"),
    setPool: (slug: string, pool: boolean) =>
      client.put<unknown>(`admin/daily/pool/${slug}`, { pool }),

    listAchievements: () => client.get<{ items: AdminAchievement[] }>("admin/achievements"),
    createAchievement: (body: AchievementInput) =>
      client.post<AdminAchievement>("admin/achievements", body),
    updateAchievement: (id: string, body: AchievementPatch) =>
      client.put<AdminAchievement>(`admin/achievements/${id}`, body),

    listReports: (status: "OPEN" | "ALL") =>
      client.get<{ items: AdminReport[] }>(`admin/reports?status=${status}`),
    resolveReport: (id: string, action: ReportAction) =>
      client.post<unknown>(`admin/reports/${id}/resolve`, { action }),

    setLeaderboardHidden: (playerId: string, hidden: boolean) =>
      client.put<unknown>(`admin/players/${playerId}/leaderboard-hidden`, { hidden }),
    getContact: () => client.get<AdminContact>("admin/contact"),
    saveContact: (body: ContactInput) => client.put<AdminContact>("admin/contact", body),
    levelStats: () => client.get<{ items: LevelStat[] }>("admin/level-stats"),
  };
}

export type SocialApi = ReturnType<typeof socialApi>;
