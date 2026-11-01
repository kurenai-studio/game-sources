"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Caption } from "@/components/ui/caption";
import { ApiError, SessionEndedError } from "@/lib/api/errors";
import { Notice } from "./ui";
import { useAdminApi } from "./use-admin-api";

type Overview = {
  draft: number;
  published: number;
  archived: number;
  lastPublish: { at: string; level: string } | null;
};

/** Level counts by status and the last publish, read through the signed-in session. */
export function HomeOverview() {
  const api = useAdminApi();
  const [data, setData] = useState<Overview | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let live = true;
    Promise.all([
      api.listLevels({ status: "DRAFT", pageSize: 1 }),
      api.listLevels({ status: "PUBLISHED", pageSize: 1 }),
      api.listLevels({ status: "ARCHIVED", pageSize: 1 }),
      api.listAudit({ action: "LEVEL_PUBLISHED", pageSize: 1 }),
    ]).then(
      ([draft, published, archived, audit]) => {
        if (!live) return;
        const last = audit.items[0];
        const detail = last?.detail as { slug?: string } | null | undefined;
        setData({
          draft: draft.total,
          published: published.total,
          archived: archived.total,
          lastPublish: last ? { at: last.createdAt, level: detail?.slug ?? last.entityId } : null,
        });
      },
      (err: unknown) => {
        if (!live || err instanceof SessionEndedError) return;
        setError(err instanceof ApiError ? err.message : "The server could not be reached.");
      },
    );
    return () => {
      live = false;
    };
  }, [api]);

  return (
    <section aria-labelledby="overview" className="mb-10">
      <Caption as="h2" className="mb-3">
        <span id="overview">Levels</span>
      </Caption>
      {error && <Notice>{error}</Notice>}
      {!data && !error && (
        <p role="status" className="text-sm tracking-[2px] uppercase">
          Loading
        </p>
      )}
      {data && (
        <>
          <dl className="grid max-w-[560px] grid-cols-3 gap-4">
            {(
              [
                ["Draft", data.draft],
                ["Published", data.published],
                ["Archived", data.archived],
              ] as const
            ).map(([label, value]) => (
              <div key={label}>
                <dt className="text-xs tracking-[2px] text-mute uppercase">{label}</dt>
                <dd className="text-[40px] leading-none tabular-nums">{value}</dd>
              </div>
            ))}
          </dl>
          <p className="mt-4 text-[15px] font-semibold">
            {data.lastPublish
              ? `Last publish: ${data.lastPublish.level}, ${new Date(data.lastPublish.at).toLocaleString()}`
              : "Nothing has been published from the dashboard yet."}
          </p>
          <div className="mt-3">
            <Link
              href="/admin/levels"
              className="inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px]"
            >
              All levels
            </Link>
          </div>
        </>
      )}
    </section>
  );
}
