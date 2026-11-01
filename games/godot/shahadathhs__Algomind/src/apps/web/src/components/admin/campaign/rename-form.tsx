"use client";

import { useState } from "react";
import { Field, OutlineAction } from "../ui";

/** Renames a world or chapter. It closes only when the rename succeeded. */
export function RenameForm({
  kind,
  id,
  initial,
  onRename,
  onCancel,
}: {
  kind: "world" | "chapter";
  id: string;
  initial: string;
  onRename: (title: string) => Promise<boolean>;
  onCancel: () => void;
}) {
  const [text, setText] = useState(initial);
  const [busy, setBusy] = useState(false);

  async function submit() {
    const title = text.trim();
    if (!title || busy) return;
    setBusy(true);
    const renamed = await onRename(title);
    setBusy(false);
    if (renamed) onCancel();
  }

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        void submit();
      }}
      className="flex flex-wrap items-end gap-3"
    >
      <Field
        label={`Rename ${kind}`}
        id={`rename-${id}`}
        value={text}
        maxLength={60}
        onChange={(e) => setText(e.target.value)}
      />
      <OutlineAction type="submit" disabled={busy}>
        Save name
      </OutlineAction>
      <OutlineAction type="button" onClick={onCancel}>
        Cancel
      </OutlineAction>
    </form>
  );
}
