"use client";

import { TextAction } from "../text-action";

/** One row of a list: its number, its text, and up, down and remove. `name` names it for assistive technology. */
export function ItemRow({
  index,
  count,
  text,
  name,
  onMove,
  onRemove,
}: {
  index: number;
  count: number;
  text: string;
  /** E.g. "command 2 of loop 1". */
  name: string;
  onMove: (to: number) => void;
  onRemove: () => void;
}) {
  return (
    <div className="flex flex-wrap items-center gap-x-4">
      <span className="w-8 text-sm tracking-[2px] tabular-nums">
        {String(index + 1).padStart(2, "0")}
      </span>
      <span className="grow text-base tracking-[1px] uppercase">{text}</span>
      <TextAction
        disabled={index === 0}
        onClick={() => onMove(index - 1)}
        aria-label={`Move ${name} up`}
      >
        Up
      </TextAction>
      <TextAction
        disabled={index === count - 1}
        onClick={() => onMove(index + 1)}
        aria-label={`Move ${name} down`}
      >
        Down
      </TextAction>
      <TextAction onClick={onRemove} aria-label={`Remove ${name}`}>
        Remove
      </TextAction>
    </div>
  );
}
