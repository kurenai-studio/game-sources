"use client";

import { useCallback, useMemo } from "react";
import { groupStats, MIN_SOLVERS_FOR_DROP, SHARP_DROP } from "@/lib/admin/level-stats";
import { OutlineAction, PageHeading } from "../ui";
import { ResourceMessages } from "../resource-messages";
import { useAdminResource } from "../use-admin-resource";
import { useSocialApi } from "../use-social-api";
import { LevelStatsTable } from "./level-stats-table";

/** How players do on each level, from verified results. */
export function LevelStatsAdmin() {
  const api = useSocialApi();
  const load = useCallback(async () => (await api.levelStats()).items, [api]);
  const { data, error, reload } = useAdminResource(load);
  const groups = useMemo(() => (data ? groupStats(data) : []), [data]);

  return (
    <div>
      <PageHeading caption="Admin" title="Level statistics" />
      <div className="mb-8 grid max-w-[680px] gap-3 text-base font-semibold text-mute">
        <p>
          The numbers come from verified results only: a level counts a player once the server has
          re-run their program and it reached the goal. Failed runs are never recorded, so there is
          no attempt count or failure rate, and nothing here tracks how players play.
        </p>
        <p>
          Slots are commands used; the average is of each solver&apos;s best result. At par counts
          solvers who matched or beat par. Within two counts solvers up to two slots over par, not
          at it. Solvers vs previous compares with the level before in campaign order; a fall of{" "}
          {Math.round(SHARP_DROP * 100)}% or more from a level with at least {MIN_SOLVERS_FOR_DROP}{" "}
          solvers is marked as a sharp drop, which often points to a hard level.
        </p>
      </div>
      <ResourceMessages notice={null} error={error} loading={!data} what="statistics" />
      {!data && error && (
        <OutlineAction type="button" onClick={() => void reload()}>
          Try again
        </OutlineAction>
      )}
      {data && data.length === 0 && (
        <p className="text-base font-semibold text-mute">No published levels yet.</p>
      )}
      {data && data.length > 0 && <LevelStatsTable groups={groups} />}
    </div>
  );
}
