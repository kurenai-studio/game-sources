"use client";

import { moveItem } from "@/lib/admin/list-ops";
import type { Primitive } from "@/lib/admin/admin-api";
import { COMMANDS } from "@/lib/admin/level-model";
import { OutlineAction } from "../ui";
import { TextAction } from "../text-action";

/** One branch of an IF: its primitives with up, down and remove, and the buttons that add more. */
export function BranchList({
  title,
  items,
  max,
  primitives,
  where,
  onChange,
}: {
  title: string;
  items: Primitive[];
  max: number;
  primitives: typeof COMMANDS;
  /** Names the IF for assistive technology, e.g. "step 2". */
  where: string;
  onChange: (next: Primitive[]) => void;
}) {
  const full = items.length >= max;
  const label = (op: string) => COMMANDS.find((c) => c.op === op)?.label ?? op;
  return (
    <div className="grid gap-1">
      <p className="text-xs tracking-[2px] text-mute uppercase">{title}</p>
      <ol className="grid gap-1" aria-label={`${title} of ${where}`}>
        {items.map((b, k) => (
          <li key={k} className="flex flex-wrap items-center gap-x-4 py-1">
            <span className="w-8 text-sm tracking-[2px] tabular-nums">
              {String(k + 1).padStart(2, "0")}
            </span>
            <span className="grow text-base tracking-[1px] uppercase">{label(b.op)}</span>
            <TextAction
              disabled={k === 0}
              onClick={() => onChange(moveItem(items, k, k - 1))}
              aria-label={`Move ${title.toLowerCase()} command ${k + 1} of ${where} up`}
            >
              Up
            </TextAction>
            <TextAction
              disabled={k === items.length - 1}
              onClick={() => onChange(moveItem(items, k, k + 1))}
              aria-label={`Move ${title.toLowerCase()} command ${k + 1} of ${where} down`}
            >
              Down
            </TextAction>
            <TextAction
              onClick={() => onChange(items.filter((_, j) => j !== k))}
              aria-label={`Remove ${title.toLowerCase()} command ${k + 1} of ${where}`}
            >
              Remove
            </TextAction>
          </li>
        ))}
      </ol>
      <div
        className="flex flex-wrap gap-3"
        role="group"
        aria-label={`Add a command to ${title.toLowerCase()} of ${where}`}
      >
        {primitives.map((c) => (
          <OutlineAction
            key={c.op}
            type="button"
            disabled={full}
            onClick={() => onChange([...items, { op: c.op }])}
          >
            Add {c.label.toLowerCase()}
          </OutlineAction>
        ))}
      </div>
      {full && (
        <p className="text-sm font-semibold text-mute">A branch holds at most {max} commands.</p>
      )}
    </div>
  );
}
