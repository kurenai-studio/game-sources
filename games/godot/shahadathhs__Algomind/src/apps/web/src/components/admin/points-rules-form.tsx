"use client";

import { useState, type FormEvent } from "react";
import type { PointsRules, PointsRulesInput } from "@/lib/admin/admin-api";
import { Field, PrimaryAction } from "./ui";

type Draft = Record<string, string>;

const FIELDS: { key: string; label: string; hint?: string }[] = [
  { key: "easy", label: "Base, easy" },
  { key: "medium", label: "Base, medium" },
  { key: "hard", label: "Base, hard" },
  { key: "parFull", label: "Bonus at par", hint: "Slots at or under par." },
  { key: "parNear", label: "Bonus near par", hint: "More than par, within the near range." },
  { key: "nearSlots", label: "Near range (slots)", hint: "Also the limit for two stars." },
  { key: "stepsBonus", label: "Bonus for par steps" },
  { key: "firstClear", label: "First clear bonus" },
];

function toDraft(rules: PointsRules): Draft {
  return {
    easy: String(rules.base.easy),
    medium: String(rules.base.medium),
    hard: String(rules.base.hard),
    parFull: String(rules.parFull),
    parNear: String(rules.parNear),
    nearSlots: String(rules.nearSlots),
    stepsBonus: String(rules.stepsBonus),
    firstClear: String(rules.firstClear),
  };
}

/** The numbers of the next rule version, starting from the active one. */
export function PointsRulesForm({
  active,
  busy,
  onCreate,
}: {
  active: PointsRules;
  busy: boolean;
  onCreate: (rules: PointsRulesInput) => void;
}) {
  const [draft, setDraft] = useState<Draft>(() => toDraft(active));

  function submit(e: FormEvent) {
    e.preventDefault();
    const n = (key: string) => Math.max(0, Math.round(Number(draft[key])));
    onCreate({
      base: { easy: n("easy"), medium: n("medium"), hard: n("hard") },
      parFull: n("parFull"),
      parNear: n("parNear"),
      nearSlots: n("nearSlots"),
      stepsBonus: n("stepsBonus"),
      firstClear: n("firstClear"),
    });
  }

  return (
    <form onSubmit={submit} aria-label="New rule version" className="grid max-w-[560px] gap-5">
      <h2 className="text-xs font-bold tracking-[2px] text-mute uppercase">New rule version</h2>
      <div className="grid gap-5 sm:grid-cols-2">
        {FIELDS.map((f) => (
          <Field
            key={f.key}
            label={f.label}
            id={`pr-${f.key}`}
            hint={f.hint}
            type="number"
            min={0}
            max={f.key === "nearSlots" ? 10 : 1000}
            value={draft[f.key]}
            onChange={(e) => setDraft({ ...draft, [f.key]: e.target.value })}
            required
          />
        ))}
      </div>
      <p className="text-sm font-semibold text-mute">
        A new version applies to results from now on. Earlier results keep the version that scored
        them, and nothing already awarded changes.
      </p>
      <div>
        <PrimaryAction type="submit" disabled={busy}>
          {busy ? "Saving" : "Save as next version"}
        </PrimaryAction>
      </div>
    </form>
  );
}
