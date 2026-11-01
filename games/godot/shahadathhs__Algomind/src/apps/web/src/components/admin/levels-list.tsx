"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Caption } from "@/components/ui/caption";
import { SessionEndedError } from "@/lib/api/errors";
import type { LevelSummary } from "@/lib/admin/admin-api";
import { apiMessage } from "@/lib/admin/messages";
import { Notice, OutlineAction, PrimaryAction } from "./ui";
import { useAdminApi } from "./use-admin-api";
import { LevelFilters } from "./levels/level-filters";
import { LevelRowActions } from "./levels/level-row-actions";
import { LevelsCards } from "./levels/levels-cards";
import { LevelsTable } from "./levels/levels-table";
import { NewLevelForm } from "./levels/new-level-form";
import { useLevels } from "./levels/use-levels";

/** The level table: search, filters, sort, paging, and the create, duplicate and delete actions. */
export function LevelsList() {
  const api = useAdminApi();
  const router = useRouter();
  const { view, filters, change, page, setPage, refresh } = useLevels();
  const [creating, setCreating] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null);

  async function duplicate(level: LevelSummary) {
    setNotice(null);
    try {
      const copy = await api.duplicateLevel(level.id);
      router.push(`/admin/levels/${copy.id}`);
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setNotice(apiMessage(err));
    }
  }

  async function remove(level: LevelSummary) {
    setNotice(null);
    setConfirmDelete(null);
    try {
      await api.deleteLevel(level.id);
      refresh();
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setNotice(apiMessage(err));
    }
  }

  const rowActions = (level: LevelSummary) => (
    <LevelRowActions
      level={level}
      confirming={confirmDelete === level.id}
      onDuplicate={() => void duplicate(level)}
      onAskDelete={() => setConfirmDelete(level.id)}
      onConfirmDelete={() => void remove(level)}
      onKeep={() => setConfirmDelete(null)}
    />
  );

  const pageCount =
    view.kind === "ready" ? Math.max(1, Math.ceil(view.page.total / view.page.pageSize)) : 1;
  const filtered = Boolean(filters.q || filters.status || filters.placement);

  return (
    <div>
      <div className="mb-8 flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="mb-2 text-xs tracking-[2px] text-mute uppercase">Admin</p>
          <h1 className="text-[34px] leading-tight tracking-[1px] uppercase">Levels</h1>
        </div>
        {!creating && (
          <PrimaryAction type="button" onClick={() => setCreating(true)}>
            New level
          </PrimaryAction>
        )}
      </div>

      {creating && (
        <NewLevelForm
          onCancel={() => setCreating(false)}
          onCreated={(id) => router.push(`/admin/levels/${id}`)}
        />
      )}

      <LevelFilters filters={filters} onChange={change} />

      {notice && (
        <div className="mb-4">
          <Notice>{notice}</Notice>
        </div>
      )}

      {view.kind === "loading" && (
        <p role="status" className="py-10 text-sm tracking-[2px] uppercase">
          Loading levels
        </p>
      )}
      {view.kind === "error" && (
        <div className="py-6">
          <Notice>{view.message}</Notice>
          <div className="mt-4">
            <OutlineAction type="button" onClick={refresh}>
              Try again
            </OutlineAction>
          </div>
        </div>
      )}
      {view.kind === "ready" && view.page.items.length === 0 && (
        <div className="py-10">
          <Caption>No levels</Caption>
          <p className="mt-2 max-w-[520px] text-base font-semibold text-mute">
            {filtered
              ? "No level matches these filters."
              : "There are no levels yet. Create the first one."}
          </p>
        </div>
      )}
      {view.kind === "ready" && view.page.items.length > 0 && (
        <>
          <LevelsTable
            items={view.page.items}
            total={view.page.total}
            page={view.page.page}
            pageCount={pageCount}
            actions={rowActions}
          />
          <LevelsCards items={view.page.items} actions={rowActions} />
          <nav aria-label="Pages" className="mt-6 flex items-center gap-4">
            <OutlineAction
              type="button"
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
            >
              Previous
            </OutlineAction>
            <span className="text-sm tracking-[2px] uppercase tabular-nums">
              {view.page.page} / {pageCount}
            </span>
            <OutlineAction
              type="button"
              disabled={page >= pageCount}
              onClick={() => setPage((p) => p + 1)}
            >
              Next
            </OutlineAction>
          </nav>
        </>
      )}
    </div>
  );
}
