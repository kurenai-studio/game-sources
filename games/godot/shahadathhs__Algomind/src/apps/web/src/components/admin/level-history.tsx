"use client";

import { downloadJson } from "@/lib/admin/download";
import { apiMessage } from "@/lib/admin/messages";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { SessionEndedError } from "@/lib/api/errors";
import type { LevelView, VersionSummary } from "@/lib/admin/admin-api";
import { Notice, OutlineAction, PageHeading } from "./ui";
import { useAdminApi } from "./use-admin-api";

const STATE_LABEL = { DRAFT: "Draft", PUBLISHED: "Live", SUPERSEDED: "Superseded" } as const;

/** Every version of one level, with export and restore-as-draft. Published versions never change. */
export function LevelHistory({ levelId }: { levelId: string }) {
  const api = useAdminApi();
  const [level, setLevel] = useState<LevelView | null>(null);
  const [versions, setVersions] = useState<VersionSummary[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      const [l, v] = await Promise.all([api.getLevel(levelId), api.listVersions(levelId)]);
      setLevel(l);
      setVersions(v.items);
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    }
  }, [api, levelId]);

  useEffect(() => {
    // The state updates run after the request resolves, not synchronously in the effect.
    // oxlint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  async function download(version: VersionSummary) {
    setError(null);
    try {
      const envelope = await api.exportLevel(levelId, version.id);
      downloadJson(`${envelope.meta.slug}-v${version.versionNumber}.json`, envelope);
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    }
  }

  async function restore(versionId: string) {
    setError(null);
    setNotice(null);
    try {
      await api.restoreVersion(levelId, versionId);
      setNotice("Restored as the new draft.");
      await load();
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    }
  }

  if (error && !versions) {
    return (
      <div className="py-6">
        <Notice>{error}</Notice>
      </div>
    );
  }
  if (!versions || !level) {
    return (
      <p role="status" className="py-10 text-sm tracking-[2px] uppercase">
        Loading history
      </p>
    );
  }
  const hasDraft = level.draft !== null;
  return (
    <div>
      <Link
        href={`/admin/levels/${levelId}`}
        className="mb-4 inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px]"
      >
        Back to the level
      </Link>
      <PageHeading caption={level.slug} title={`History: ${level.title}`} />
      {notice && (
        <div className="mb-4">
          <Notice kind="info">{notice}</Notice>
        </div>
      )}
      {error && (
        <div className="mb-4">
          <Notice>{error}</Notice>
        </div>
      )}
      <ol className="grid max-w-[820px]" aria-label="Versions, newest first">
        {versions.map((v) => (
          <li
            key={v.id}
            className="flex flex-wrap items-center gap-x-5 gap-y-1 border-t-2 border-ink py-3"
          >
            <span className="w-12 text-lg tracking-[1px] tabular-nums uppercase">
              v{v.versionNumber}
            </span>
            <span
              className={`tile inline-flex h-7 items-center px-2.5 text-xs tracking-[2px] uppercase ${
                v.state === "PUBLISHED"
                  ? "bg-ink text-on-ink"
                  : v.state === "DRAFT"
                    ? "bg-ground text-ink outline-2 -outline-offset-2 outline-ink"
                    : "bg-strip text-mute"
              }`}
              style={{ ["--chamfer" as string]: "7px" }}
            >
              {STATE_LABEL[v.state]}
            </span>
            <span className="grow text-[15px] font-semibold text-mute">
              {v.par ? `Par ${v.par.commands}` : "No par"} ·{" "}
              {new Date(v.publishedAt ?? v.updatedAt).toLocaleString()}
            </span>
            <button
              type="button"
              onClick={() => void download(v)}
              className="inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px]"
            >
              Export
            </button>
            {v.state !== "DRAFT" && (
              <button
                type="button"
                disabled={hasDraft}
                onClick={() => void restore(v.id)}
                title={hasDraft ? "Discard or publish the current draft first." : undefined}
                className="inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px] disabled:text-mute disabled:no-underline"
              >
                Restore as draft
              </button>
            )}
          </li>
        ))}
      </ol>
      {hasDraft && (
        <p className="mt-4 text-sm font-semibold text-mute">
          Restoring needs no open draft. Discard or publish the current draft first.
        </p>
      )}
      <div className="mt-6">
        <OutlineAction type="button" onClick={() => void load()}>
          Refresh
        </OutlineAction>
      </div>
    </div>
  );
}
