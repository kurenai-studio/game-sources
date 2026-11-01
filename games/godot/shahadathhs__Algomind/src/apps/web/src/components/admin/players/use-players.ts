"use client";

import { useCallback, useEffect, useState } from "react";
import { SessionEndedError } from "@/lib/api/errors";
import type { Page, PlayerQuery, PlayerSummary } from "@/lib/admin/admin-api";
import { apiMessage } from "@/lib/admin/messages";
import { useAdminApi } from "../use-admin-api";

export const PAGE_SIZE = 25;

export type Filters = Required<Pick<PlayerQuery, "sort" | "order">> & {
  q: string;
  status: "" | "ACTIVE" | "SUSPENDED";
};

export type View =
  | { kind: "loading" }
  | { kind: "error"; message: string }
  | { kind: "ready"; page: Page<PlayerSummary> };

const NO_FILTERS: Filters = { q: "", status: "", sort: "lastActive", order: "desc" };

/** The player list for the current filters and page. Any filter change goes back to page 1. */
export function usePlayers() {
  const api = useAdminApi();
  const [view, setView] = useState<View>({ kind: "loading" });
  const [filters, setFilters] = useState<Filters>(NO_FILTERS);
  const [page, setPage] = useState(1);
  const [reload, setReload] = useState(0);
  const refresh = useCallback(() => setReload((n) => n + 1), []);

  function change(next: Partial<Filters>) {
    setFilters((f) => ({ ...f, ...next }));
    setPage(1);
  }

  useEffect(() => {
    let live = true;
    const timer = setTimeout(() => {
      setView({ kind: "loading" });
      api
        .listPlayers({
          q: filters.q.trim() || undefined,
          status: filters.status || undefined,
          sort: filters.sort,
          order: filters.order,
          page,
          pageSize: PAGE_SIZE,
        })
        .then(
          (result) => live && setView({ kind: "ready", page: result }),
          (err: unknown) => {
            if (!live || err instanceof SessionEndedError) return;
            setView({ kind: "error", message: apiMessage(err) });
          },
        );
    }, 200);
    return () => {
      live = false;
      clearTimeout(timer);
    };
  }, [api, filters, page, reload]);

  return { view, filters, change, page, setPage, refresh };
}
