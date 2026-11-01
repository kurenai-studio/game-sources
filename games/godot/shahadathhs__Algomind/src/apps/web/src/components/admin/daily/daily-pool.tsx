"use client";

import type { PoolLevel } from "@/lib/admin/social-api";
import { DIFFICULTY_LABEL } from "@/lib/campaign";
import { LabelTile, OutlineAction } from "../ui";

/** Published levels, with whether each is in the daily pool. Campaign levels cannot join it. */
export function DailyPool({
  levels,
  busy,
  onToggle,
}: {
  levels: PoolLevel[];
  busy: boolean;
  onToggle: (level: PoolLevel) => void;
}) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[640px] border-collapse text-left">
        <caption className="sr-only">Published levels and the daily pool</caption>
        <thead>
          <tr className="border-b-2 border-ink text-xs tracking-[2px] text-mute uppercase">
            {["Level", "Difficulty", "Where", "Action"].map((head) => (
              <th key={head} scope="col" className="py-3 pr-4 font-bold">
                {head}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {levels.map((l) => (
            <tr key={l.slug} className="border-b border-faint align-middle">
              <td className="py-3 pr-4 text-base tracking-[1px]">{l.title}</td>
              <td className="py-3 pr-4 text-[15px] font-semibold">
                {DIFFICULTY_LABEL[l.difficulty]}
              </td>
              <td className="py-3 pr-4">
                {l.inCampaign ? (
                  <LabelTile>Campaign</LabelTile>
                ) : (
                  <LabelTile solid={l.pool}>{l.pool ? "In pool" : "Not in pool"}</LabelTile>
                )}
              </td>
              <td className="py-3">
                {l.inCampaign ? (
                  <p className="text-sm font-semibold text-mute">
                    A campaign level cannot join the pool.
                  </p>
                ) : (
                  <OutlineAction type="button" disabled={busy} onClick={() => onToggle(l)}>
                    {l.pool ? "Remove from pool" : "Add to pool"}
                  </OutlineAction>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
