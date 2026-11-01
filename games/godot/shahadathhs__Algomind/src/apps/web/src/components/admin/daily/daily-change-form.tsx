"use client";

import { useState, type FormEvent } from "react";
import type { PoolLevel } from "@/lib/admin/social-api";
import { DIFFICULTY_LABEL } from "@/lib/campaign";
import { OutlineAction, SelectField } from "../ui";

/** Pick a level from the pool for one day. */
export function DailyChangeForm({
  date,
  current,
  pool,
  busy,
  onSave,
  onCancel,
}: {
  date: string;
  current: string | null;
  pool: PoolLevel[];
  busy: boolean;
  onSave: (slug: string) => void;
  onCancel: () => void;
}) {
  const [slug, setSlug] = useState(current ?? pool[0]?.slug ?? "");

  function submit(e: FormEvent) {
    e.preventDefault();
    if (slug) onSave(slug);
  }

  if (pool.length === 0) {
    return (
      <div className="flex flex-wrap items-center gap-4">
        <p className="text-[15px] font-semibold">The pool is empty. Add a level to it below.</p>
        <OutlineAction type="button" onClick={onCancel}>
          Close
        </OutlineAction>
      </div>
    );
  }
  return (
    <form onSubmit={submit} className="flex flex-wrap items-end gap-3">
      <div className="min-w-[220px]">
        <SelectField
          label="Level for this day"
          id={`daily-pick-${date}`}
          value={slug}
          onChange={(e) => setSlug(e.target.value)}
        >
          {pool.map((l) => (
            <option key={l.slug} value={l.slug}>
              {l.title} ({DIFFICULTY_LABEL[l.difficulty]})
            </option>
          ))}
        </SelectField>
      </div>
      <OutlineAction type="submit" disabled={busy || !slug}>
        Schedule
      </OutlineAction>
      <OutlineAction type="button" onClick={onCancel}>
        Cancel
      </OutlineAction>
    </form>
  );
}
