"use client";

import { useEffect, useState, type FormEvent } from "react";
import { Caption } from "@/components/ui/caption";
import { SessionEndedError } from "@/lib/api/errors";
import type { Difficulty, Playtest } from "@/lib/admin/admin-api";
import { Field, Notice, OutlineAction, SelectField } from "../ui";
import { useAdminApi } from "../use-admin-api";
import { apiMessage } from "@/lib/admin/messages";

export function PlaytestPanel({
  levelId,
  hasDraft,
  commandsHint,
  onRecorded,
}: {
  levelId: string;
  hasDraft: boolean;
  commandsHint: number;
  onRecorded: () => void;
}) {
  const api = useAdminApi();
  const [records, setRecords] = useState<Playtest[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [tester, setTester] = useState("");
  const [solved, setSolved] = useState(true);
  const [commands, setCommands] = useState(String(commandsHint));
  const [difficulty, setDifficulty] = useState<"" | Difficulty>("");
  const [notes, setNotes] = useState("");

  useEffect(() => {
    let live = true;
    api.listPlaytests(levelId).then(
      (r) => live && setRecords(r.items),
      (err: unknown) => {
        if (live && !(err instanceof SessionEndedError)) setError(apiMessage(err));
      },
    );
    return () => {
      live = false;
    };
  }, [api, levelId]);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (!tester.trim()) return setError("Enter the tester's name.");
    setBusy(true);
    try {
      await api.addPlaytest(levelId, {
        testerName: tester.trim(),
        solved,
        commandsUsed: commands === "" ? undefined : Number(commands),
        perceivedDifficulty: difficulty || undefined,
        notes,
      });
      setNotes("");
      const r = await api.listPlaytests(levelId);
      setRecords(r.items);
      onRecorded();
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="grid gap-10 lg:grid-cols-2">
      <form onSubmit={submit} aria-label="Record a playtest" className="grid content-start gap-5">
        <Caption as="h2">Record a playtest</Caption>
        {!hasDraft && <Notice kind="info">Start a draft to record a playtest.</Notice>}
        <Field
          label="Tester"
          id="pt-tester"
          value={tester}
          maxLength={80}
          onChange={(e) => setTester(e.target.value)}
        />
        <SelectField
          label="Result"
          id="pt-solved"
          value={solved ? "yes" : "no"}
          onChange={(e) => setSolved(e.target.value === "yes")}
        >
          <option value="yes">Solved</option>
          <option value="no">Not solved</option>
        </SelectField>
        <Field
          label="Commands used"
          id="pt-commands"
          type="number"
          min={0}
          max={1000}
          value={commands}
          onChange={(e) => setCommands(e.target.value)}
        />
        <SelectField
          label="Perceived difficulty"
          id="pt-difficulty"
          value={difficulty}
          onChange={(e) => setDifficulty(e.target.value as "" | Difficulty)}
        >
          <option value="">Not given</option>
          <option value="easy">Easy</option>
          <option value="medium">Medium</option>
          <option value="hard">Hard</option>
        </SelectField>
        <Field
          label="Notes"
          id="pt-notes"
          value={notes}
          maxLength={1000}
          onChange={(e) => setNotes(e.target.value)}
        />
        {error && <Notice>{error}</Notice>}
        <div>
          <OutlineAction type="submit" disabled={busy || !hasDraft}>
            {busy ? "Recording" : "Record playtest"}
          </OutlineAction>
        </div>
      </form>
      <div>
        <Caption as="h2" className="mb-3">
          Records
        </Caption>
        {records === null && !error && (
          <p role="status" className="text-sm tracking-[2px] uppercase">
            Loading
          </p>
        )}
        {records?.length === 0 && (
          <p className="text-base font-semibold text-mute">No playtests recorded.</p>
        )}
        <ul className="grid gap-3">
          {records?.map((r) => (
            <li key={r.id} className="border-t-2 border-ink pt-3">
              <p className="text-base tracking-[1px] uppercase">
                {r.testerName} · {r.solved ? "Solved" : "Not solved"}
              </p>
              <p className="mt-1 text-sm font-semibold text-mute">
                {r.current ? "Current content" : "Stale: the level changed since"} · v
                {r.versionNumber}
                {r.commandsUsed !== null && ` · ${r.commandsUsed} commands`}
                {r.perceivedDifficulty && ` · ${r.perceivedDifficulty}`}
              </p>
              {r.notes && <p className="mt-1 text-[15px] font-semibold">{r.notes}</p>}
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
