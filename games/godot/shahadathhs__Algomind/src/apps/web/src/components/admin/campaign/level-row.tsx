import Link from "next/link";
import type { LevelSummary } from "@/lib/admin/admin-api";
import { StatusTile } from "../ui";
import { TextAction } from "../text-action";

export function LevelRow({
  level,
  index,
  last,
  chapterId,
  choices,
  onMove,
  onAssign,
}: {
  level: LevelSummary;
  index?: number;
  last?: boolean;
  chapterId: string;
  choices: { id: string; label: string }[];
  onMove?: (to: number) => void;
  onAssign: (chapterId: string) => void;
}) {
  return (
    <li className="flex flex-wrap items-center gap-x-5 gap-y-1 border-b border-faint py-2">
      {index !== undefined && (
        <span className="w-8 text-sm tracking-[2px] tabular-nums">
          {String(index + 1).padStart(2, "0")}
        </span>
      )}
      <Link
        href={`/admin/levels/${level.id}`}
        className="grow text-base tracking-[1px] uppercase underline decoration-2 underline-offset-[6px]"
      >
        {level.title}
      </Link>
      <StatusTile status={level.status} />
      <div className="flex w-full flex-wrap items-center gap-x-5 sm:w-auto">
        {onMove && index !== undefined && (
          <>
            <TextAction
              disabled={index === 0}
              onClick={() => onMove(index - 1)}
              aria-label={`Move ${level.title} up`}
            >
              Up
            </TextAction>
            <TextAction
              disabled={last}
              onClick={() => onMove(index + 1)}
              aria-label={`Move ${level.title} down`}
            >
              Down
            </TextAction>
          </>
        )}
        <label className="flex items-center gap-2 text-xs tracking-[2px] text-mute uppercase">
          <span className="sr-only">Place {level.title} in</span>
          <span aria-hidden="true">Place in</span>
          <select
            value={chapterId}
            onChange={(e) => onAssign(e.target.value)}
            className="h-11 border-2 border-ink bg-floor px-2 text-[13px] text-ink"
          >
            <option value="">Unassigned</option>
            {choices.map((c) => (
              <option key={c.id} value={c.id}>
                {c.label}
              </option>
            ))}
          </select>
        </label>
      </div>
    </li>
  );
}
