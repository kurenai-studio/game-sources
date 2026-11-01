"use client";

import Link from "next/link";
import { useState } from "react";
import { BoardPanel } from "./editor/board-panel";
import { ChecksPanel } from "./editor/checks-panel";
import { localCheck, parIsReferenceFor } from "@/lib/admin/level-model";
import { DetailsPanel } from "./editor/details-panel";
import { EditorTabs, type TabId } from "./editor/editor-tabs";
import { LimitsPanel } from "./editor/limits-panel";
import { PlaytestPanel } from "./editor/playtest-panel";
import { PreviewPanel } from "./editor/preview-panel";
import { SolutionPanel } from "./editor/solution-panel";
import { UnpublishControl } from "./editor/unpublish-control";
import { useLevelDraft, type SaveState } from "./editor/use-level-draft";
import { Notice, OutlineAction, PrimaryAction, StatusTile } from "./ui";

const SAVE_LABEL: Record<SaveState, string> = {
  saved: "Saved",
  unsaved: "Unsaved changes",
  saving: "Saving",
  failed: "Save failed",
};

/** The level editor: tabs over one draft, an explicit Save draft, and edits that survive a reload. */
export function LevelEditor({ levelId }: { levelId: string }) {
  const {
    load,
    level,
    content,
    solution,
    save,
    notice,
    conflict,
    restorable,
    fetchLevel,
    edit,
    saveDraft,
    startDraft,
    unpublish,
    discardDraft,
    restoreBackup,
    dropBackup,
  } = useLevelDraft(levelId);
  const [tab, setTab] = useState<TabId>("details");
  const [playtestKey, setPlaytestKey] = useState(0);

  if (load.kind === "loading") {
    return (
      <p role="status" className="py-10 text-sm tracking-[2px] uppercase">
        Loading level
      </p>
    );
  }
  if (load.kind === "error" || !level) {
    return (
      <div className="py-6">
        <Notice>{load.kind === "error" ? load.message : "Level not found."}</Notice>
        <div className="mt-4 flex gap-3">
          <OutlineAction type="button" onClick={() => void fetchLevel()}>
            Try again
          </OutlineAction>
          <Link
            href="/admin/levels"
            className="inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px]"
          >
            All levels
          </Link>
        </div>
      </div>
    );
  }

  const dirty = save === "unsaved" || save === "saving" || save === "failed";
  const hasDraft = level.draft !== null && content !== null;

  return (
    <div>
      <div className="mb-4 flex flex-wrap gap-x-6">
        <Link
          href="/admin/levels"
          className="inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px]"
        >
          All levels
        </Link>
        <Link
          href={`/admin/history/${levelId}`}
          className="inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px]"
        >
          History
        </Link>
      </div>
      <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="mb-2 text-xs tracking-[2px] text-mute uppercase">
            {level.slug}
            {level.draft && ` · draft v${level.draft.versionNumber}`}
            {level.publishedVersion !== null && ` · live v${level.publishedVersion}`}
          </p>
          <h1 className="flex flex-wrap items-center gap-4 text-[34px] leading-tight tracking-[1px] uppercase">
            {content?.title || level.title}
            <StatusTile status={level.status} />
          </h1>
        </div>
        {hasDraft && (
          <div className="flex flex-wrap items-center gap-4">
            <p role="status" className="text-sm tracking-[2px] uppercase">
              {SAVE_LABEL[save]}
            </p>
            <PrimaryAction
              type="button"
              onClick={() => void saveDraft()}
              disabled={save === "saving" || save === "saved"}
            >
              Save draft
            </PrimaryAction>
          </div>
        )}
      </div>

      {notice && (
        <div className="mb-4">
          <Notice kind={notice.kind}>{notice.text}</Notice>
        </div>
      )}
      {level.status === "PUBLISHED" && (
        <div className="mb-6">
          <UnpublishControl onUnpublish={(archive) => void unpublish(archive)} />
        </div>
      )}
      {conflict && (
        <div className="mb-6 flex flex-wrap items-center gap-4">
          <p className="text-base font-semibold">
            Your edits are still on this page and in the local backup.
          </p>
          <OutlineAction type="button" onClick={() => void fetchLevel()}>
            Load the newer draft
          </OutlineAction>
        </div>
      )}
      {restorable && (
        <div className="mb-6 flex flex-wrap items-center gap-4">
          <p className="text-base font-semibold">
            Unsaved edits from {new Date(restorable.savedAt).toLocaleString()} were found on this
            device.
          </p>
          <OutlineAction type="button" onClick={restoreBackup}>
            Restore them
          </OutlineAction>
          <OutlineAction type="button" onClick={dropBackup}>
            Discard them
          </OutlineAction>
        </div>
      )}

      {!hasDraft ? (
        <div className="grid max-w-[560px] gap-4 py-4">
          <p className="text-base font-semibold">
            This level is live as v{level.publishedVersion}. Players keep that version while you
            edit a new draft.
          </p>
          <div>
            <OutlineAction type="button" onClick={() => void startDraft()}>
              Start a new draft
            </OutlineAction>
          </div>
        </div>
      ) : (
        <>
          <EditorTabs tab={tab} onSelect={setTab} />
          <div role="tabpanel" id={`panel-${tab}`} aria-labelledby={`tab-${tab}`}>
            {tab === "details" && (
              <DetailsPanel
                content={content}
                slug={level.slug}
                onChange={(c) => edit(c, solution)}
              />
            )}
            {tab === "board" && (
              <BoardPanel content={content} onChange={(c) => edit(c, solution)} />
            )}
            {tab === "limits" && (
              <LimitsPanel content={content} onChange={(c) => edit(c, solution)} />
            )}
            {tab === "solution" && (
              <SolutionPanel
                content={content}
                solution={solution}
                onSolution={(s) => edit(content, s)}
                onContent={(c) => edit(c, solution)}
              />
            )}
            {tab === "preview" && (
              <PreviewPanel key={JSON.stringify(solution)} content={content} solution={solution} />
            )}
            {tab === "playtest" && (
              <PlaytestPanel
                key={playtestKey}
                levelId={levelId}
                hasDraft
                commandsHint={solution.length}
                onRecorded={() => setPlaytestKey((n) => n + 1)}
              />
            )}
            {tab === "checks" && (
              <ChecksPanel
                levelId={levelId}
                dirty={dirty}
                hasDraft
                parIsReference={content !== null && parIsReferenceFor(content)}
                localRun={localCheck(content, solution).run}
              />
            )}
          </div>
          {level.publishedVersion !== null && (
            <div className="mt-10">
              <OutlineAction type="button" onClick={() => void discardDraft()}>
                Discard this draft
              </OutlineAction>
            </div>
          )}
        </>
      )}
    </div>
  );
}
