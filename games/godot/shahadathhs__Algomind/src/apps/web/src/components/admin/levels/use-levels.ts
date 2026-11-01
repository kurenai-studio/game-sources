"use client";

import { useCallback, useEffect, useState } from "react";
import { SessionEndedError } from "@/lib/api/errors";
import type { LevelSummary, Page } from "@/lib/admin/admin-api";
import { apiMessage } from "@/lib/admin/messages";
import { useAdminApi } from "../use-admin-api";
import type { Filters } from "./level-filters";

export const PAGE_SIZE = 20;

export type View =
  | { kind: "loading" }
  | { kind: "error"; message: string }
  | { kind: "ready"; page: Page<LevelSummary> };

const NO_FILTERS: Filters = { q: "", status: "", placement: "", sort: "updatedAt" };

/** The level list for the current filters and page, reloaded on `refresh`. */
export function useLevels() {
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
      const { q, status, placement, sort } = filters;
      api
        .listLevels({
          q: q.trim() || undefined,
          status: status || undefined,
          unassigned: placement === "unassigned" ? true : undefined,
          sort,
          order: sort === "updatedAt" || sort === "createdAt" ? "desc" : "asc",
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
