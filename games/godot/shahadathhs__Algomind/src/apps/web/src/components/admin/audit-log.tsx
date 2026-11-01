"use client";

import { useEffect, useState } from "react";
import { Caption } from "@/components/ui/caption";
import { ApiError, SessionEndedError } from "@/lib/api/errors";
import type { AuditEvent, Page } from "@/lib/admin/admin-api";
import { Notice, OutlineAction, PageHeading, SelectField } from "./ui";
import { useAdminApi } from "./use-admin-api";

const ACTIONS: { value: string; label: string }[] = [
  { value: "", label: "All" },
  { value: "LEVEL_PUBLISHED", label: "Level published" },
  { value: "LEVEL_UNPUBLISHED", label: "Level unpublished" },
  { value: "LEVEL_ARCHIVED", label: "Level archived" },
  { value: "LEVEL_IMPORTED", label: "Level imported" },
  { value: "LEVEL_RESTORED", label: "Level restored" },
  { value: "CAMPAIGN_REORDERED", label: "Campaign reordered" },
  { value: "POINTS_RULES_CHANGED", label: "Points rules changed" },
];

function label(action: string): string {
  return ACTIONS.find((a) => a.value === action)?.label ?? action;
}

function summary(detail: AuditEvent["detail"]): string {
  if (!detail) return "";
  return Object.entries(detail)
    .map(([k, v]) => `${k}: ${typeof v === "string" ? v : JSON.stringify(v)}`)
    .join(", ");
}

/** Who did what and when: publishes, unpublishes, imports, restores, and reorders. */
export function AuditLog() {
  const api = useAdminApi();
  const [action, setAction] = useState("");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<Page<AuditEvent> | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let live = true;
    api.listAudit({ action: action || undefined, page, pageSize: 25 }).then(
      (r) => {
        if (!live) return;
        setError(null);
        setData(r);
      },
      (err: unknown) => {
        if (!live || err instanceof SessionEndedError) return;
        setError(err instanceof ApiError ? err.message : "The server could not be reached.");
      },
    );
    return () => {
      live = false;
    };
  }, [api, action, page]);

  const pages = data ? Math.max(1, Math.ceil(data.total / data.pageSize)) : 1;
  return (
    <div>
      <PageHeading caption="Admin" title="Audit log" />
      <div className="mb-6 max-w-[320px]">
        <SelectField
          label="Action"
          id="audit-action"
          value={action}
          onChange={(e) => {
            setAction(e.target.value);
            setPage(1);
          }}
        >
          {ACTIONS.map((a) => (
            <option key={a.value} value={a.value}>
              {a.label}
            </option>
          ))}
        </SelectField>
      </div>
      {error && <Notice>{error}</Notice>}
      {!data && !error && (
        <p role="status" className="text-sm tracking-[2px] uppercase">
          Loading
        </p>
      )}
      {data && data.items.length === 0 && (
        <p className="py-6 text-base font-semibold text-mute">No events recorded.</p>
      )}
      {data && data.items.length > 0 && (
        <>
          <ol className="grid" aria-label="Audit events">
            {data.items.map((e) => (
              <li key={e.id} className="border-t-2 border-ink py-3">
                <p className="flex flex-wrap items-baseline gap-x-4 text-base tracking-[1px] uppercase">
                  {label(e.action)}
                  <span className="text-sm text-mute">
                    {new Date(e.createdAt).toLocaleString()}
                  </span>
                </p>
                <p className="mt-1 text-sm font-semibold text-mute">
                  {e.userEmail ?? "Unknown user"} · {e.entityType} {e.entityId}
                </p>
                {e.detail && <p className="mt-1 text-[15px] font-semibold">{summary(e.detail)}</p>}
              </li>
            ))}
          </ol>
          <nav aria-label="Pages" className="mt-6 flex items-center gap-4">
            <OutlineAction type="button" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
              Previous
            </OutlineAction>
            <span className="text-sm tracking-[2px] uppercase tabular-nums">
              {data.page} / {pages}
            </span>
            <OutlineAction
              type="button"
              disabled={page >= pages}
              onClick={() => setPage((p) => p + 1)}
            >
              Next
            </OutlineAction>
          </nav>
        </>
      )}
      <Caption className="mt-10">Newest first</Caption>
    </div>
  );
}
