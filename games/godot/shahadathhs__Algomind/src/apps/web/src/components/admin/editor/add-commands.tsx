"use client";

import type { Instruction } from "@/lib/admin/admin-api";
import { REPEAT_LIMITS, primitivesOf } from "@/lib/admin/level-model";
import { newCall, newIf, newProc } from "@/lib/admin/program-model";
import { OutlineAction } from "../ui";

/**
 * The add buttons of one list. Moves and turns always; loops and procedures only where `loops` or
 * `freeName` are given; a call only where `callNames` is given (disabled while nothing is defined).
 */
export function AddCommands({
  available,
  label,
  disabled = false,
  loops = false,
  ifs = true,
  callNames,
  freeName,
  onAdd,
}: {
  available: string[];
  label: string;
  disabled?: boolean;
  /** Offer Repeat and Repeat until (a list that may hold loops). */
  loops?: boolean;
  ifs?: boolean;
  /** The defined names: shows Add call. Omit where a call may not stand. */
  callNames?: readonly string[];
  /** The next free procedure name, or null when A, B and C are all defined. Omit where a PROC may not stand. */
  freeName?: string | null;
  onAdd: (node: Instruction) => void;
}) {
  const button = (key: string, text: string, node: Instruction, off = disabled) => (
    <OutlineAction key={key} type="button" disabled={off} onClick={() => onAdd(node)}>
      {text}
    </OutlineAction>
  );
  return (
    <div className="flex flex-wrap gap-3" role="group" aria-label={label}>
      {primitivesOf(available).map((c) =>
        button(c.op, `Add ${c.label.toLowerCase()}`, { op: c.op }),
      )}
      {loops &&
        available.includes("REPEAT") &&
        button("REPEAT", "Add repeat", { op: "REPEAT", count: REPEAT_LIMITS.count.min, body: [] })}
      {loops &&
        available.includes("REPEAT_UNTIL") &&
        button("REPEAT_UNTIL", "Add repeat until", {
          op: "REPEAT_UNTIL",
          until: "BLOCKED",
          body: [],
        })}
      {ifs && available.includes("IF") && button("IF", "Add if", newIf())}
      {freeName !== undefined &&
        available.includes("PROC") &&
        button("PROC", "Add procedure", newProc(freeName ?? "A"), disabled || freeName === null)}
      {callNames !== undefined &&
        available.includes("PROC") &&
        button(
          "CALL",
          "Add call",
          newCall(callNames[0] ?? "A"),
          disabled || callNames.length === 0,
        )}
    </div>
  );
}
