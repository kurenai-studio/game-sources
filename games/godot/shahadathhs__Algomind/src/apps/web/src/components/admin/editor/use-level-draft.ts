"use client";

import { useCallback, useEffect, useState } from "react";
import { ApiError, SessionEndedError } from "@/lib/api/errors";
import type { Instruction, LevelContent, LevelView } from "@/lib/admin/admin-api";
import { apiMessage } from "@/lib/admin/messages";
import { clearBackup, readBackup, writeBackup } from "@/lib/admin/level-model";
import { useAdminApi } from "../use-admin-api";

export type SaveState = "saved" | "unsaved" | "saving" | "failed";
export type Load = { kind: "loading" } | { kind: "error"; message: string } | { kind: "ready" };
export type EditorNotice = { kind: "error" | "info"; text: string };

/** One level and its draft: loading, local edits with a backup, and the calls that change it. */
export function useLevelDraft(levelId: string) {
  const api = useAdminApi();
  const [load, setLoad] = useState<Load>({ kind: "loading" });
  const [level, setLevel] = useState<LevelView | null>(null);
  const [content, setContent] = useState<LevelContent | null>(null);
  const [solution, setSolution] = useState<Instruction[]>([]);
  const [baseUpdatedAt, setBaseUpdatedAt] = useState("");
  const [save, setSave] = useState<SaveState>("saved");
  const [notice, setNotice] = useState<EditorNotice | null>(null);
  const [conflict, setConflict] = useState(false);
  const [restorable, setRestorable] = useState<ReturnType<typeof readBackup>>(null);

  const adopt = useCallback((view: LevelView) => {
    setLevel(view);
    setContent(view.draft?.content ?? null);
    setSolution(view.draft?.referenceSolution ?? []);
    setBaseUpdatedAt(view.draft?.updatedAt ?? "");
    setSave("saved");
    setConflict(false);
  }, []);

  const fetchLevel = useCallback(async () => {
    setLoad({ kind: "loading" });
    try {
      const view = await api.getLevel(levelId);
      adopt(view);
      if (view.draft) {
        const backup = readBackup(levelId);
        setRestorable(backup && backup.baseUpdatedAt === view.draft.updatedAt ? backup : null);
        if (backup && backup.baseUpdatedAt !== view.draft.updatedAt) clearBackup(levelId);
      }
      setLoad({ kind: "ready" });
    } catch (err) {
      if (err instanceof SessionEndedError) return;
      setLoad({ kind: "error", message: apiMessage(err) });
    }
  }, [api, levelId, adopt]);

  useEffect(() => {
    // Loading starts the fetch; the setState calls inside run after the request, not synchronously.
    // oxlint-disable-next-line react-hooks/set-state-in-effect
    void fetchLevel();
  }, [fetchLevel]);

  // Warn before leaving with unsaved edits.
  useEffect(() => {
    if (save !== "unsaved" && save !== "failed") return;
    const handler = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener("beforeunload", handler);
    return () => window.removeEventListener("beforeunload", handler);
  }, [save]);

  function edit(nextContent: LevelContent, nextSolution: Instruction[]) {
    setContent(nextContent);
    setSolution(nextSolution);
    setSave("unsaved");
    setNotice(null);
    setRestorable(null);
    writeBackup(levelId, {
      savedAt: Date.now(),
      baseUpdatedAt,
      content: nextContent,
      referenceSolution: nextSolution,
    });
  }

  function fail(err: unknown) {
    if (!(err instanceof SessionEndedError)) setNotice({ kind: "error", text: apiMessage(err) });
  }

  async function saveDraft() {
    if (!content) return;
    setSave("saving");
    setNotice(null);
    try {
      const view = await api.saveDraft(levelId, {
        expectedUpdatedAt: baseUpdatedAt,
        content,
        referenceSolution: solution,
      });
      setLevel(view);
      if (view.draft) setBaseUpdatedAt(view.draft.updatedAt);
      clearBackup(levelId);
      setSave("saved");
    } catch (err) {
      setSave("failed");
      if (err instanceof SessionEndedError) {
        setNotice({
          kind: "error",
          text: "The session ended. Your edits are kept on this device.",
        });
      } else if (err instanceof ApiError && err.code === "DRAFT_CONFLICT") {
        setConflict(true);
        setNotice({
          kind: "error",
          text: "A newer version of this draft was saved elsewhere. Nothing was overwritten.",
        });
      } else {
        setNotice({ kind: "error", text: apiMessage(err) });
      }
    }
  }

  async function startDraft() {
    setNotice(null);
    try {
      adopt(await api.startDraft(levelId));
    } catch (err) {
      fail(err);
    }
  }

  async function unpublish(archive: boolean) {
    setNotice(null);
    try {
      adopt(await api.unpublishLevel(levelId, archive));
      setNotice({
        kind: "info",
        text: archive
          ? "The level is archived and no longer offered to players."
          : "The level is no longer offered to players.",
      });
    } catch (err) {
      fail(err);
    }
  }

  async function discardDraft() {
    setNotice(null);
    try {
      clearBackup(levelId);
      adopt(await api.discardDraft(levelId));
    } catch (err) {
      fail(err);
    }
  }

  function restoreBackup() {
    if (!restorable) return;
    edit(restorable.content, restorable.referenceSolution);
    setRestorable(null);
  }

  function dropBackup() {
    clearBackup(levelId);
    setRestorable(null);
  }

  return {
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
  };
}
