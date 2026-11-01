import type { ReactNode } from "react";
import Link from "next/link";
import type { LevelSummary } from "@/lib/admin/admin-api";
import { parText, placementText, playtestText, when } from "@/lib/admin/format";
import { LevelBadges } from "./level-badges";

/** The narrow-screen level list, one entry per level. */
export function LevelsCards({
  items,
  actions,
}: {
  items: LevelSummary[];
  actions: (level: LevelSummary) => ReactNode;
}) {
  return (
    <ul className="grid sm:hidden" aria-label="Levels">
      {items.map((level) => (
        <li key={level.id} className="border-b border-faint py-4">
          <Link
            href={`/admin/levels/${level.id}`}
            className="text-lg tracking-[1px] uppercase underline decoration-2 underline-offset-[6px]"
          >
            {level.title}
          </Link>
          <p className="mt-1 text-sm font-semibold text-mute">
            {level.slug} · {level.difficulty}
          </p>
          <div className="mt-3">
            <LevelBadges level={level} row />
          </div>
          <dl className="mt-3 grid grid-cols-[auto_1fr] gap-x-4 gap-y-1 text-[15px] font-semibold">
            <dt className="text-mute">Placement</dt>
            <dd>{placementText(level)}</dd>
            <dt className="text-mute">Par</dt>
            <dd>{parText(level)}</dd>
            <dt className="text-mute">Playtest</dt>
            <dd>{playtestText(level)}</dd>
            <dt className="text-mute">Updated</dt>
            <dd>{when(level.updatedAt)}</dd>
          </dl>
          <div className="mt-2">{actions(level)}</div>
        </li>
      ))}
    </ul>
  );
}
