"use client";

import { REPEAT_LIMITS } from "@/lib/admin/level-model";
import type { Instruction } from "@/lib/admin/admin-api";
import { SelectField } from "../ui";

const ROUNDS = Array.from(
  { length: REPEAT_LIMITS.count.max - REPEAT_LIMITS.count.min + 1 },
  (_, i) => REPEAT_LIMITS.count.min + i,
);

/** The rounds of a counted loop: 2 to 11, or N (the counter's value when the loop starts) when INC is offered. */
export function LoopCount({
  id,
  value,
  counter,
  onChange,
}: {
  id: string;
  value: Instruction["count"];
  /** The level offers INC, so N may be chosen. */
  counter: boolean;
  onChange: (count: number | "N") => void;
}) {
  const current = value ?? REPEAT_LIMITS.count.min;
  return (
    <div>
      <SelectField
        label={`Rounds (${REPEAT_LIMITS.count.min} to ${REPEAT_LIMITS.count.max}${counter ? ", or N" : ""})`}
        id={id}
        value={String(current)}
        onChange={(e) => onChange(e.target.value === "N" ? "N" : Number(e.target.value))}
      >
        {ROUNDS.map((n) => (
          <option key={n} value={n}>
            {n}
          </option>
        ))}
        {(counter || current === "N") && <option value="N">N (the counter)</option>}
      </SelectField>
      {current === "N" && !counter && (
        <p className="mt-2 text-sm font-semibold text-mute">
          N needs the Count up command. Allow it in Limits or pick a number.
        </p>
      )}
    </div>
  );
}
