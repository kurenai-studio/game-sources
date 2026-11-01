import type { LevelSummary } from "@/lib/admin/admin-api";
import { StatusTile } from "../ui";

/** Status plus the "draft ahead" and "live version" notes of one level. */
export function LevelBadges({ level, row }: { level: LevelSummary; row?: boolean }) {
  return (
    <div className={row ? "flex flex-wrap items-center gap-3" : "flex flex-col items-start gap-2"}>
      <StatusTile status={level.status} />
      {level.draftAhead && <span className="text-xs tracking-[2px] uppercase">Draft ahead</span>}
      {level.publishedVersion !== null && (
        <span className="text-xs tracking-[2px] text-mute uppercase">
          Live v{level.publishedVersion}
        </span>
      )}
    </div>
  );
}
