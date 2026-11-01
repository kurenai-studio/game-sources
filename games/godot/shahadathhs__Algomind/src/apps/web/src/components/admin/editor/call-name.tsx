"use client";

import { SelectField } from "../ui";

/** The procedure a CALL runs, chosen from the names the program defines. */
export function CallName({
  value,
  names,
  id,
  where,
  onChange,
}: {
  value: string;
  names: readonly string[];
  id: string;
  where: string;
  onChange: (name: string) => void;
}) {
  const options = names.includes(value) || value === "" ? names : [...names, value];
  return (
    <div className="mt-2 mb-2 ml-8 grid gap-2 border-l-2 border-ink pl-4">
      <SelectField
        label={`Procedure to call (${where})`}
        id={id}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      >
        {options.map((name) => (
          <option key={name} value={name}>
            {names.includes(name) ? name : `${name} (not defined)`}
          </option>
        ))}
      </SelectField>
    </div>
  );
}
