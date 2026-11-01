"use client";

import { useState } from "react";
import { dayLabel } from "@/lib/admin/daily-dates";
import type { DailyDay, PoolLevel } from "@/lib/admin/social-api";
import { DIFFICULTY_LABEL } from "@/lib/campaign";
import { LabelTile } from "../ui";
import { TextAction } from "../text-action";
import { DailyChangeForm } from "./daily-change-form";

/** The next days of the daily challenge, with Change (pick from the pool) and Clear. */
export function DailySchedule({
  days,
  today,
  pool,
  busy,
  onSchedule,
  onClear,
}: {
  days: DailyDay[];
  today: string;
  pool: PoolLevel[];
  busy: boolean;
  onSchedule: (date: string, slug: string) => Promise<boolean>;
  onClear: (date: string) => void;
}) {
  const [editing, setEditing] = useState<string | null>(null);

  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[760px] border-collapse text-left">
        <caption className="sr-only">The next {days.length} days of the daily challenge</caption>
        <thead>
          <tr className="border-b-2 border-ink text-xs tracking-[2px] text-mute uppercase">
            {["Day", "Level", "Par / limit", "Set by", "Actions"].map((head) => (
              <th key={head} scope="col" className="py-3 pr-4 font-bold">
                {head}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {days.map((day) => (
            <DayRow
              key={day.date}
              day={day}
              today={today}
              pool={pool}
              busy={busy}
              editing={editing === day.date}
              onEdit={(on) => setEditing(on ? day.date : null)}
              onSchedule={async (slug) => {
                if (await onSchedule(day.date, slug)) setEditing(null);
              }}
              onClear={onClear}
            />
          ))}
        </tbody>
      </table>
    </div>
  );
}

function DayRow({
  day,
  today,
  pool,
  busy,
  editing,
  onEdit,
  onSchedule,
  onClear,
}: {
  day: DailyDay;
  today: string;
  pool: PoolLevel[];
  busy: boolean;
  editing: boolean;
  onEdit: (on: boolean) => void;
  onSchedule: (slug: string) => void;
  onClear: (date: string) => void;
}) {
  const scheduled = day.levelSlug !== null && day.source === "scheduled";
  return (
    <>
      <tr className="border-b border-faint align-top">
        <td className="py-4 pr-4 text-[15px] font-semibold whitespace-nowrap">
          {dayLabel(day.date)}
          {day.date === today && (
            <span className="ml-2 text-xs tracking-[2px] uppercase">Today</span>
          )}
        </td>
        {day.levelSlug === null ? (
          <td colSpan={2} className="py-4 pr-4 text-[15px] font-semibold text-mute">
            No level: the pool is empty.
          </td>
        ) : (
          <>
            <td className="py-4 pr-4">
              <span className="text-base tracking-[1px]">{day.title}</span>
              <p className="mt-1 text-sm font-semibold text-mute">
                {DIFFICULTY_LABEL[day.difficulty]}
              </p>
            </td>
            <td className="py-4 pr-4 text-[15px] font-semibold tabular-nums">
              {day.par} / {day.maxCommands}
            </td>
          </>
        )}
        <td className="py-4 pr-4">
          {day.levelSlug !== null && (
            <LabelTile solid={scheduled}>{scheduled ? "Scheduled" : "Rotation"}</LabelTile>
          )}
        </td>
        <td className="py-1.5">
          <div className="flex flex-wrap gap-x-5">
            <TextAction disabled={busy} onClick={() => onEdit(!editing)}>
              Change
            </TextAction>
            {scheduled && (
              <TextAction disabled={busy} onClick={() => onClear(day.date)}>
                Clear
              </TextAction>
            )}
          </div>
        </td>
      </tr>
      {editing && (
        <tr className="border-b border-faint">
          <td colSpan={5} className="pb-4">
            <DailyChangeForm
              date={day.date}
              current={day.levelSlug}
              pool={pool.filter((l) => l.pool)}
              busy={busy}
              onSave={onSchedule}
              onCancel={() => onEdit(false)}
            />
          </td>
        </tr>
      )}
    </>
  );
}
