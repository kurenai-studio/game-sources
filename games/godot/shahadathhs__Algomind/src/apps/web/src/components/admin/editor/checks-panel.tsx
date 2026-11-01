"use client";

import Link from "next/link";
import { useState } from "react";
import { Caption } from "@/components/ui/caption";
import { SessionEndedError } from "@/lib/api/errors";
import type { ValidateResult } from "@/lib/admin/admin-api";
import { Notice, OutlineAction } from "../ui";
import { useAdminApi } from "../use-admin-api";
import { apiMessage } from "@/lib/admin/messages";
import type { MultiRunResult } from "@/lib/admin/level-model";
import { BoardResults } from "./board-results";
import { IssueList } from "./issue-list";

export function ChecksPanel({
  levelId,
  dirty,
  hasDraft,
  parIsReference = false,
  localRun = null,
}: {
  levelId: string;
  dirty: boolean;
  /** The level offers IF or PROC: the API sets par to the reference solution. */
  parIsReference?: boolean;
  hasDraft: boolean;
  /** The reference solution run on every board in the browser, when the level has several boards. */
  localRun?: MultiRunResult | null;
}) {
  const api = useAdminApi();
  const [result, setResult] = useState<ValidateResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState<"" | "validate">("");

  async function validate() {
    setError(null);
    setBusy("validate");
    try {
      setResult(await api.validateLevel(levelId));
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    } finally {
      setBusy("");
    }
  }

  return (
    <div className="grid max-w-[760px] gap-6">
      {!hasDraft && <Notice kind="info">Start a draft to validate or publish.</Notice>}
      {dirty && hasDraft && (
        <Notice kind="info">Save the draft first. Checks run on the saved draft.</Notice>
      )}
      <div className="flex flex-wrap gap-3">
        <OutlineAction
          type="button"
          onClick={() => void validate()}
          disabled={!hasDraft || dirty || busy !== ""}
        >
          {busy === "validate" ? "Checking" : "Run checks"}
        </OutlineAction>
        {hasDraft && !dirty && (
          <Link
            href={`/admin/publish/${levelId}`}
            className="inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px]"
          >
            Review and publish
          </Link>
        )}
      </div>
      {error && <Notice>{error}</Notice>}
      {localRun && localRun.results.length > 1 && (
        <div>
          <Caption as="h3" className="mb-2">
            Reference solution on each board
          </Caption>
          <BoardResults run={localRun} />
        </div>
      )}
      {result && (
        <div className="grid gap-6">
          <div>
            <Caption as="h3" className="mb-2">
              Summary
            </Caption>
            <dl className="grid grid-cols-[auto_1fr] gap-x-6 gap-y-1 text-[15px] font-semibold">
              <dt className="text-mute">Valid</dt>
              <dd>{result.ok ? "Yes" : "No"}</dd>
              <dt className="text-mute">Reference solved</dt>
              <dd>{result.referenceSolved ? "Yes" : "No"}</dd>
              <dt className="text-mute">{parIsReference ? "Par (reference solution)" : "Par"}</dt>
              <dd>
                {result.par
                  ? `${result.par.commands} commands, ${result.par.steps} steps`
                  : "Not available"}
              </dd>
              <dt className="text-mute">Mechanics</dt>
              <dd>{result.requiredMechanics.join(", ") || "None"}</dd>
              <dt className="text-mute">Playtest for this content</dt>
              <dd>{result.playtests.solvedForCurrentContent ? "Solved" : "Missing"}</dd>
              <dt className="text-mute">Minimum client</dt>
              <dd>{result.compatibility.minimumVersion ?? "None set"}</dd>
              <dt className="text-mute">Ready to publish</dt>
              <dd>{result.publish.ready ? "Yes" : "No"}</dd>
            </dl>
          </div>
          <IssueList title="Errors" issues={result.errors} />
          <IssueList title="Warnings" issues={result.warnings} />
          <IssueList title="Publishing would be blocked by" issues={result.publish.failedGates} />
        </div>
      )}
    </div>
  );
}
