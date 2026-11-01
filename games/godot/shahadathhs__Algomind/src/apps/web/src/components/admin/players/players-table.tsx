import Link from "next/link";
import type { PlayerSummary } from "@/lib/admin/admin-api";
import { when } from "@/lib/admin/format";
import { PlayerStatusTile } from "./player-status";

/** One player per row; on a narrow screen the table scrolls sideways instead of squeezing. */
export function PlayersTable({
  items,
  total,
  page,
  pageCount,
}: {
  items: PlayerSummary[];
  total: number;
  page: number;
  pageCount: number;
}) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[720px] border-collapse text-left">
        <caption className="sr-only">
          Players, {total} in total, page {page} of {pageCount}
        </caption>
        <thead>
          <tr className="border-b-2 border-ink text-xs tracking-[2px] text-mute uppercase">
            {["Player", "Status", "Cleared", "Points", "Last active"].map((head) => (
              <th key={head} scope="col" className="py-3 pr-4 font-bold">
                {head}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {items.map((p) => (
            <tr key={p.id} className="border-b border-faint align-top">
              <td className="py-4 pr-4">
                <Link
                  href={`/admin/players/${p.id}`}
                  className="text-base tracking-[1px] underline decoration-2 underline-offset-[6px]"
                >
                  {p.email}
                </Link>
                {p.displayName && (
                  <p className="mt-1 text-sm font-semibold text-mute">{p.displayName}</p>
                )}
                {(p.leaderboardHidden || p.leaderboardOptIn) && (
                  <p className="mt-1 text-xs tracking-[2px] text-mute uppercase">
                    {p.leaderboardHidden ? "Hidden from boards" : "On the boards"}
                  </p>
                )}
              </td>
              <td className="py-4 pr-4">
                <PlayerStatusTile status={p.status} />
              </td>
              <td className="py-4 pr-4 text-[15px] font-semibold tabular-nums">
                {p.levelsCleared}
              </td>
              <td className="py-4 pr-4 text-[15px] font-semibold tabular-nums">{p.points}</td>
              <td className="py-4 text-[15px] font-semibold">
                {p.lastActiveAt ? when(p.lastActiveAt) : "Never"}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
