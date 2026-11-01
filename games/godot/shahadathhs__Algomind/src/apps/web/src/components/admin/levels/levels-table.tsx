import type { ReactNode } from "react";
import Link from "next/link";
import type { LevelSummary } from "@/lib/admin/admin-api";
import { parText, placementText, playtestText, when } from "@/lib/admin/format";
import { LevelBadges } from "./level-badges";

const HEADS = ["Level", "Status", "Placement", "Par", "Playtest", "Updated"];

/** The wide-screen level table. */
export function LevelsTable({
  items,
  total,
  page,
  pageCount,
  actions,
}: {
  items: LevelSummary[];
  total: number;
  page: number;
  pageCount: number;
  actions: (level: LevelSummary) => ReactNode;
}) {
  return (
    <div className="hidden overflow-x-auto sm:block">
      <table className="w-full min-w-[820px] border-collapse text-left">
        <caption className="sr-only">
          Levels, {total} in total, page {page} of {pageCount}
        </caption>
        <thead>
          <tr className="border-b-2 border-ink text-xs tracking-[2px] text-mute uppercase">
            {HEADS.map((head) => (
              <th key={head} scope="col" className="py-3 pr-4 font-bold">
                {head}
              </th>
            ))}
            <th scope="col" className="py-3 font-bold">
              <span className="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {items.map((level) => (
            <tr key={level.id} className="border-b border-faint align-top">
              <td className="py-4 pr-4">
                <Link
                  href={`/admin/levels/${level.id}`}
                  className="text-lg tracking-[1px] uppercase underline decoration-2 underline-offset-[6px]"
                >
                  {level.title}
                </Link>
                <p className="mt-1 text-sm font-semibold text-mute">
                  {level.slug} · {level.difficulty}
                </p>
              </td>
              <td className="py-4 pr-4">
                <LevelBadges level={level} />
              </td>
              <td className="py-4 pr-4 text-[15px] font-semibold">{placementText(level)}</td>
              <td className="py-4 pr-4 text-[15px] font-semibold tabular-nums">{parText(level)}</td>
              <td className="py-4 pr-4 text-[15px] font-semibold">{playtestText(level)}</td>
              <td className="py-4 pr-4 text-[15px] font-semibold">{when(level.updatedAt)}</td>
              <td className="py-4">{actions(level)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
