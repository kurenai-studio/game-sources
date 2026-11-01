"use client";

import { useState } from "react";
import { Field, OutlineAction } from "../ui";

/** An Add button that opens a one-field form. It closes only when the create succeeded. */
export function NewTitleForm({
  openLabel,
  fieldLabel,
  fieldId,
  submitLabel,
  onCreate,
}: {
  openLabel: string;
  fieldLabel: string;
  fieldId: string;
  submitLabel: string;
  onCreate: (title: string) => Promise<boolean>;
}) {
  const [title, setTitle] = useState("");
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);

  if (!open) {
    return (
      <OutlineAction type="button" onClick={() => setOpen(true)}>
        {openLabel}
      </OutlineAction>
    );
  }

  async function submit() {
    const value = title.trim();
    if (!value || busy) return;
    setBusy(true);
    const created = await onCreate(value);
    setBusy(false);
    if (created) {
      setTitle("");
      setOpen(false);
    }
  }

  return (
    <form
      className="flex flex-wrap items-end gap-3"
      onSubmit={(e) => {
        e.preventDefault();
        void submit();
      }}
    >
      <Field
        label={fieldLabel}
        id={fieldId}
        value={title}
        maxLength={60}
        onChange={(e) => setTitle(e.target.value)}
      />
      <OutlineAction type="submit" disabled={busy}>
        {submitLabel}
      </OutlineAction>
      <OutlineAction type="button" onClick={() => setOpen(false)}>
        Cancel
      </OutlineAction>
    </form>
  );
}
