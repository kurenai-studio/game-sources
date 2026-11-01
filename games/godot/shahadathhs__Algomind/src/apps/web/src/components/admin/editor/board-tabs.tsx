"use client";

import type { ReactNode } from "react";

/** One tab per board (Board 1 is the level's own); optional extra content, such as a result mark, per tab. */
export function BoardTabs({
  count,
  selected,
  onSelect,
  mark,
}: {
  count: number;
  selected: number;
  onSelect: (index: number) => void;
  mark?: (index: number) => ReactNode;
}) {
  return (
    <div role="group" aria-label="Boards" className="mb-4 flex flex-wrap gap-2">
      {Array.from({ length: count }, (_, i) => (
        <button
          key={i}
          type="button"
          aria-pressed={selected === i}
          onClick={() => onSelect(i)}
          className={`tile inline-flex h-11 items-center gap-2 px-4 text-[13px] tracking-[2px] uppercase ${
            selected === i ? "bg-ink text-on-ink" : "bg-strip text-ink"
          }`}
          style={{ ["--chamfer" as string]: "10px" }}
        >
          Board {i + 1}
          {mark?.(i)}
        </button>
      ))}
    </div>
  );
}
