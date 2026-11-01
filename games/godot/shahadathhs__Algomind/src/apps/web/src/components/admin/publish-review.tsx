"use client";

import { apiMessage } from "@/lib/admin/messages";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { BoardView } from "@/components/ui/board-view";
import { Caption } from "@/components/ui/caption";
import { ApiError, SessionEndedError } from "@/lib/api/errors";
import type { CheckIssue, LevelView, ValidateResult } from "@/lib/admin/admin-api";
import { boardIssuePath } from "@/lib/admin/board-model";
import { boardData, parName } from "@/lib/admin/level-model";
import { diff } from "@/lib/admin/publish-diff";
import { Notice, OutlineAction, PageHeading, PrimaryAction } from "./ui";
import { useAdminApi } from "./use-admin-api";

/** The publish review: the gates, what changes against the live version, and a confirmation. */
export function PublishReview({ levelId }: { levelId: string }) {
  const api = useAdminApi();
  const [level, setLevel] = useState<LevelView | null>(null);
  const [result, setResult] = useState<ValidateResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [blocked, setBlocked] = useState<CheckIssue[]>([]);
  const [busy, setBusy] = useState(false);
  const [published, setPublished] = useState(false);

  const load = useCallback(async () => {
    setError(null);
    try {
      const view = await api.getLevel(levelId);
      setLevel(view);
      if (view.draft) setResult(await api.validateLevel(levelId));
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    }
  }, [api, levelId]);

  useEffect(() => {
    // The state updates run after the requests resolve, not synchronously in the effect.
    // oxlint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  async function publish() {
    setBusy(true);
    setError(null);
    setBlocked([]);
    try {
      await api.publishLevel(levelId);
      setPublished(true);
    } catch (err) {
      if (err instanceof SessionEndedError) return;
      if (err instanceof ApiError && err.code === "PUBLISH_BLOCKED" && Array.isArray(err.issues)) {
        setBlocked(err.issues as CheckIssue[]);
        setError("Publishing is blocked. Fix the issues below.");
      } else setError(apiMessage(err));
    } finally {
      setBusy(false);
    }
  }

  if (error && !level) {
    return (
      <div className="py-6">
        <Notice>{error}</Notice>
      </div>
    );
  }
  if (!level) {
    return (
      <p role="status" className="py-10 text-sm tracking-[2px] uppercase">
        Loading review
      </p>
    );
  }

  const back = (
    <Link
      href={`/admin/levels/${levelId}`}
      className="mb-4 inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px]"
    >
      Back to the level
    </Link>
  );

  if (published) {
    return (
      <div>
        {back}
        <PageHeading caption={level.slug} title="Published" />
        <Notice kind="info">
          The draft is now the live version. Players receive it the next time they fetch the level.
        </Notice>
      </div>
    );
  }

  if (!level.draft) {
    return (
      <div>
        {back}
        <PageHeading caption={level.slug} title="Publish review" />
        <p className="text-base font-semibold">
          There is no draft to publish. Start a new draft first.
        </p>
      </div>
    );
  }

  const draft = level.draft;
  const live = level.published;
  const changes = diff(live ?? null, draft);
  const failed = result?.publish.failedGates ?? [];
  const ready = result?.publish.ready === true;

  return (
    <div>
      {back}
      <PageHeading caption={level.slug} title={`Publish review: ${draft.content.title}`} />

      <section aria-labelledby="gates" className="mb-10 max-w-[760px]">
        <Caption as="h2" className="mb-3">
          <span id="gates">Checks</span>
        </Caption>
        {!result ? (
          <p role="status" className="text-sm tracking-[2px] uppercase">
            Checking
          </p>
        ) : (
          <>
            <p className="mb-3 text-lg tracking-[1px] uppercase">
              {ready
                ? "Ready to publish"
                : `Blocked by ${failed.length} ${failed.length === 1 ? "check" : "checks"}`}
            </p>
            <dl className="mb-4 grid grid-cols-[auto_1fr] gap-x-6 gap-y-1 text-[15px] font-semibold">
              <dt className="text-mute">Reference solution</dt>
              <dd>{result.referenceSolved ? "Solves the level" : "Does not solve the level"}</dd>
              <dt className="text-mute">{parName(draft.content)}</dt>
              <dd>
                {result.par
                  ? `${result.par.commands} commands, limit ${draft.content.constraints.maxCommands}`
                  : "Not available"}
              </dd>
              <dt className="text-mute">Playtest for this content</dt>
              <dd>{result.playtests.solvedForCurrentContent ? "Solved" : "Missing"}</dd>
              <dt className="text-mute">Mechanics needed</dt>
              <dd>{result.requiredMechanics.join(", ") || "None"}</dd>
              <dt className="text-mute">Minimum app version</dt>
              <dd>
                {result.compatibility.minimumVersion ?? "None set"}
                {result.compatibility.unsupportedMechanics.length > 0 &&
                  ` (does not support ${result.compatibility.unsupportedMechanics.join(", ")})`}
              </dd>
            </dl>
            {failed.length > 0 && (
              <ul className="grid gap-2" aria-label="Failed checks">
                {failed.map((issue, i) => (
                  <li
                    key={i}
                    className="flex flex-wrap gap-x-3 border-t border-faint pt-2 text-[15px] font-semibold"
                  >
                    <span className="text-xs tracking-[2px] uppercase">
                      {issue.gate.replace("_", " ")}
                    </span>
                    <span className="text-mute">{boardIssuePath(issue.path) || "level"}</span>
                    <span>{issue.message}</span>
                  </li>
                ))}
              </ul>
            )}
            {result.warnings.length > 0 && (
              <ul className="mt-4 grid gap-2" aria-label="Warnings">
                {result.warnings.map((w, i) => (
                  <li key={i} className="border-t border-faint pt-2 text-[15px] font-semibold">
                    <span className="mr-3 text-xs tracking-[2px] uppercase">Warning</span>
                    {w.message}
                  </li>
                ))}
              </ul>
            )}
          </>
        )}
      </section>

      <section aria-labelledby="changes" className="mb-10">
        <Caption as="h2" className="mb-4">
          <span id="changes">
            {live ? `Changes since live v${live.versionNumber}` : "First publication"}
          </span>
        </Caption>
        <div className="mb-6 grid max-w-[640px] grid-cols-2 gap-6">
          <div>
            <Caption className="mb-2">{live ? `Live v${live.versionNumber}` : "Live"}</Caption>
            {live ? (
              <BoardView board={boardData(live.content)} label="Board of the live version." />
            ) : (
              <p className="text-base font-semibold text-mute">Not published yet.</p>
            )}
          </div>
          <div>
            <Caption className="mb-2">{`Draft v${draft.versionNumber}`}</Caption>
            <BoardView board={boardData(draft.content)} label="Board of the draft." />
          </div>
        </div>
        {changes.length === 0 ? (
          <p className="text-base font-semibold text-mute">
            No field differs from the live version.
          </p>
        ) : (
          <ul className="grid max-w-[760px]" aria-label="Changed fields">
            {changes.map((c) => (
              <li
                key={c.field}
                className="grid gap-x-6 border-t border-faint py-2 text-[15px] font-semibold sm:grid-cols-[160px_1fr_1fr]"
              >
                <span className="text-xs tracking-[2px] uppercase">{c.field}</span>
                <span className="text-mute">Before: {c.from}</span>
                <span>After: {c.to}</span>
              </li>
            ))}
          </ul>
        )}
      </section>

      {error && (
        <div className="mb-4">
          <Notice>{error}</Notice>
        </div>
      )}
      {blocked.length > 0 && (
        <ul className="mb-6 grid max-w-[760px] gap-2" aria-label="Publish blocked by">
          {blocked.map((issue, i) => (
            <li key={i} className="border-t border-faint pt-2 text-[15px] font-semibold">
              <span className="mr-3 text-xs tracking-[2px] uppercase">
                {issue.gate.replace("_", " ")}
              </span>
              {issue.message}
            </li>
          ))}
        </ul>
      )}
      <p className="mb-4 max-w-[640px] text-base font-semibold">
        Publishing freezes draft v{draft.versionNumber}. It cannot be edited afterwards; changing it
        later creates a new draft.
      </p>
      <div className="flex flex-wrap gap-3">
        <PrimaryAction type="button" onClick={() => void publish()} disabled={!ready || busy}>
          {busy ? "Publishing" : "Publish"}
        </PrimaryAction>
        <OutlineAction type="button" onClick={() => void load()} disabled={busy}>
          Check again
        </OutlineAction>
      </div>
    </div>
  );
}
