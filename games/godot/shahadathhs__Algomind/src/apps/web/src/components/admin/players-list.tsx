"use client";

import { Caption } from "@/components/ui/caption";
import { Notice, OutlineAction, PageHeading } from "./ui";
import { PlayerFilters } from "./players/player-filters";
import { PlayersTable } from "./players/players-table";
import { usePlayers } from "./players/use-players";

/** The players: search, filter by status, sort by activity, points or levels cleared. */
export function PlayersList() {
  const { view, filters, change, page, setPage, refresh } = usePlayers();
  const pageCount =
    view.kind === "ready" ? Math.max(1, Math.ceil(view.page.total / view.page.pageSize)) : 1;
  const filtered = Boolean(filters.q || filters.status);

  return (
    <div>
      <PageHeading caption="Admin" title="Players" />
      <PlayerFilters filters={filters} onChange={change} />
      {view.kind === "loading" && (
        <p role="status" className="py-10 text-sm tracking-[2px] uppercase">
          Loading players
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
          <Caption>No players</Caption>
          <p className="mt-2 max-w-[520px] text-base font-semibold text-mute">
            {filtered ? "No player matches these filters." : "Nobody has signed up yet."}
          </p>
        </div>
      )}
      {view.kind === "ready" && view.page.items.length > 0 && (
        <>
          <PlayersTable
            items={view.page.items}
            total={view.page.total}
            page={view.page.page}
            pageCount={pageCount}
          />
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
