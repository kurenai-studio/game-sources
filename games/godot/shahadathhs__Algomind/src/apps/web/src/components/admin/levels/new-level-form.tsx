"use client";

import { useState, type FormEvent } from "react";
import { Caption } from "@/components/ui/caption";
import { SessionEndedError } from "@/lib/api/errors";
import type { Difficulty } from "@/lib/admin/admin-api";
import { SLUG, slugify } from "@/lib/admin/format";
import { apiMessage } from "@/lib/admin/messages";
import { Field, Notice, OutlineAction, PrimaryAction, SelectField } from "../ui";
import { useAdminApi } from "../use-admin-api";

export function NewLevelForm({
  onCancel,
  onCreated,
}: {
  onCancel: () => void;
  onCreated: (id: string) => void;
}) {
  const api = useAdminApi();
  const [title, setTitle] = useState("");
  const [slug, setSlug] = useState("");
  const [slugTouched, setSlugTouched] = useState(false);
  const [difficulty, setDifficulty] = useState<Difficulty>("easy");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (!title.trim()) return setError("Enter a title.");
    if (!SLUG.test(slug)) {
      return setError("The slug uses lowercase letters, digits, and single hyphens.");
    }
    setBusy(true);
    try {
      const level = await api.createLevel({ slug, title: title.trim(), difficulty });
      onCreated(level.id);
    } catch (err) {
      if (err instanceof SessionEndedError) return;
      setError(apiMessage(err));
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} className="mb-10 max-w-[560px]" aria-label="New level">
      <Caption as="h2" className="mb-4">
        New level
      </Caption>
      <div className="grid gap-4">
        <Field
          label="Title"
          id="new-title"
          value={title}
          maxLength={60}
          onChange={(e) => {
            setTitle(e.target.value);
            if (!slugTouched) setSlug(slugify(e.target.value));
          }}
          required
        />
        <Field
          label="Slug"
          id="new-slug"
          value={slug}
          maxLength={60}
          hint="The level's address. It cannot change once published."
          onChange={(e) => {
            setSlugTouched(true);
            setSlug(e.target.value);
          }}
          required
        />
        <SelectField
          label="Difficulty"
          id="new-difficulty"
          value={difficulty}
          onChange={(e) => setDifficulty(e.target.value as Difficulty)}
        >
          <option value="easy">Easy</option>
          <option value="medium">Medium</option>
          <option value="hard">Hard</option>
        </SelectField>
        {error && <Notice>{error}</Notice>}
        <div className="flex flex-wrap gap-3">
          <PrimaryAction type="submit" disabled={busy}>
            {busy ? "Creating" : "Create level"}
          </PrimaryAction>
          <OutlineAction type="button" onClick={onCancel} disabled={busy}>
            Cancel
          </OutlineAction>
        </div>
      </div>
    </form>
  );
}
