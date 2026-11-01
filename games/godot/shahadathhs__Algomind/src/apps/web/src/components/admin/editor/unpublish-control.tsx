"use client";

import { useState } from "react";
import { OutlineAction } from "../ui";

/** Unpublish with a confirmation that says what stays on players' devices. */
export function UnpublishControl({ onUnpublish }: { onUnpublish: (archive: boolean) => void }) {
  const [open, setOpen] = useState(false);
  if (!open) {
    return (
      <OutlineAction type="button" onClick={() => setOpen(true)}>
        Unpublish
      </OutlineAction>
    );
  }
  function confirm(archive: boolean) {
    setOpen(false);
    onUnpublish(archive);
  }
  return (
    <div className="grid max-w-[640px] gap-3">
      <p className="text-base font-semibold">
        Unpublishing removes the level from what players fetch from now on. Copies already
        downloaded to devices stay there; this does not delete them.
      </p>
      <div className="flex flex-wrap gap-3">
        <OutlineAction type="button" onClick={() => confirm(false)}>
          Confirm unpublish
        </OutlineAction>
        <OutlineAction type="button" onClick={() => confirm(true)}>
          Unpublish and archive
        </OutlineAction>
        <OutlineAction type="button" onClick={() => setOpen(false)}>
          Cancel
        </OutlineAction>
      </div>
    </div>
  );
}
