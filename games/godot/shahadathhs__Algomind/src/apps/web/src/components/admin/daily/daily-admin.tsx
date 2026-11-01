"use client";

import { useCallback } from "react";
import { todayUtc } from "@/lib/admin/daily-dates";
import { Caption } from "@/components/ui/caption";
import { OutlineAction, PageHeading } from "../ui";
import { ResourceMessages } from "../resource-messages";
import { useAdminResource } from "../use-admin-resource";
import { useSocialApi } from "../use-social-api";
import { DailyPool } from "./daily-pool";
import { DailySchedule } from "./daily-schedule";
import type { PoolLevel } from "@/lib/admin/social-api";

const DAYS = 30;

/** The daily challenge: the next 30 days and the pool of levels it draws from. */
export function DailyAdmin() {
  const api = useSocialApi();
  const load = useCallback(async () => {
    const from = todayUtc();
    const [days, pool] = await Promise.all([api.listDaily(from, DAYS), api.listPool()]);
    return { from, days: days.items, pool: pool.items };
  }, [api]);
  const { data, error, notice, busy, run, reload } = useAdminResource(load);

  return (
    <div>
      <PageHeading caption="Admin" title="Daily" />
      <p className="mb-8 max-w-[640px] text-base font-semibold text-mute">
        Every player gets the same level each day, and the day changes at midnight UTC. A day with
        nothing scheduled is on rotation: the pool is shuffled into a fixed order and every level
        comes once before any repeats, so the calendar never runs out. Adding or removing a pool
        level changes which level the rotation gives on unscheduled days. Schedule a day to choose
        its level yourself; only levels in the pool can be scheduled.
      </p>
      <ResourceMessages notice={notice} error={error} loading={!data} what="the daily challenge" />
      {!data && error && (
        <OutlineAction type="button" onClick={() => void reload()}>
          Try again
        </OutlineAction>
      )}
      {data && (
        <>
          <Caption as="h2" className="mb-3">
            Next {DAYS} days
          </Caption>
          <DailySchedule
            days={data.days}
            today={data.from}
            pool={data.pool}
            busy={busy}
            onSchedule={(date, slug) =>
              run(() => api.scheduleDay(date, slug), `Scheduled ${date}.`)
            }
            onClear={(date) => {
              if (window.confirm(`Clear ${date}? It goes back to the rotation.`))
                void run(() => api.clearDay(date), `Cleared ${date}; it is on rotation.`);
            }}
          />
          <Caption as="h2" className="mt-12 mb-3">
            Pool
          </Caption>
          <p className="mb-4 max-w-[640px] text-[15px] font-semibold text-mute">
            The pool is the set of levels that exist only for the daily challenge. Players do not
            meet them in the campaign.
          </p>
          <DailyPool
            levels={data.pool}
            busy={busy}
            onToggle={(l: PoolLevel) => {
              const msg = l.pool
                ? `Remove ${l.title} from the pool? Days scheduled with it stay as they are.`
                : null;
              if (msg && !window.confirm(msg)) return;
              void run(
                () => api.setPool(l.slug, !l.pool),
                `${l.title} ${l.pool ? "left" : "joined"} the pool.`,
              );
            }}
          />
        </>
      )}
    </div>
  );
}
