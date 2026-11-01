"use client";

import { SENSOR_GROUPS } from "@/lib/admin/program-model";
import { SelectField } from "../ui";

/**
 * The sensor of a CALL on a level with the mechanic recursion: the procedure runs only while it is
 * true. Left empty the call always runs. Without a sensor a procedure that calls itself never stops.
 */
export function CallWhen({
  value,
  id,
  where,
  marks,
  onChange,
}: {
  value: string | undefined;
  id: string;
  where: string;
  /** The level offers MARK, so the fresh and back sensors are allowed. */
  marks: boolean;
  onChange: (when: string | undefined) => void;
}) {
  return (
    <div className="mt-2 mb-2 ml-8 grid gap-2 border-l-2 border-ink pl-4">
      <SelectField
        label={`Runs (${where})`}
        id={id}
        value={value ?? ""}
        onChange={(e) => onChange(e.target.value === "" ? undefined : e.target.value)}
      >
        <option value="">Always</option>
        {SENSOR_GROUPS.filter((g) => marks || !g.needsMark).map((group) => (
          <optgroup key={group.label} label={group.label}>
            {group.sensors.map((s) => (
              <option key={s} value={s}>
                While {s.toLowerCase().replace("_", " ")}
              </option>
            ))}
          </optgroup>
        ))}
      </SelectField>
    </div>
  );
}
