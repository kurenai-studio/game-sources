import type { LevelSummary } from "@/lib/admin/admin-api";
import { LevelRow } from "./level-row";

export function UnassignedSection({
  levels,
  choices,
  onAssign,
}: {
  levels: LevelSummary[];
  choices: { id: string; label: string }[];
  onAssign: (level: LevelSummary, chapterId: string) => void;
}) {
  return (
    <section aria-label="Unassigned levels" className="mt-14">
      <div className="border-b-2 border-ink pb-3">
        <h2 className="text-[26px] leading-tight tracking-[1px] uppercase">Unassigned</h2>
        <p className="mt-1 text-sm font-semibold text-mute">
          These levels never reach players until they are placed in a chapter.
        </p>
      </div>
      {levels.length === 0 ? (
        <p className="py-4 text-base font-semibold text-mute">Every level is placed.</p>
      ) : (
        <ul className="grid">
          {levels.map((level) => (
            <LevelRow
              key={level.id}
              level={level}
              chapterId=""
              choices={choices}
              onAssign={(id) => onAssign(level, id)}
            />
          ))}
        </ul>
      )}
    </section>
  );
}
