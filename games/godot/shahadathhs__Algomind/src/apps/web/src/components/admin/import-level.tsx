"use client";

import Link from "next/link";
import { useState, type ChangeEvent } from "react";
import { ApiError, SessionEndedError } from "@/lib/api/errors";
import { Field, Notice, OutlineAction, PageHeading, PrimaryAction } from "./ui";
import { useAdminApi } from "./use-admin-api";

type Issue = { path?: string; code?: string; message?: string };

/** Import a level file into a new draft. Nothing existing is ever overwritten. */
export function ImportLevel() {
  const api = useAdminApi();
  const [envelope, setEnvelope] = useState<unknown>(null);
  const [fileName, setFileName] = useState("");
  const [slug, setSlug] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [issues, setIssues] = useState<Issue[]>([]);
  const [busy, setBusy] = useState(false);
  const [created, setCreated] = useState<{ id: string; title: string } | null>(null);

  async function pick(e: ChangeEvent<HTMLInputElement>) {
    setError(null);
    setIssues([]);
    setCreated(null);
    const file = e.target.files?.[0];
    if (!file) return;
    setFileName(file.name);
    if (file.size > 256 * 1024) {
      setEnvelope(null);
      return setError("The file is larger than 256 KB.");
    }
    try {
      setEnvelope(JSON.parse(await file.text()));
    } catch {
      setEnvelope(null);
      setError("The file is not valid JSON.");
    }
  }

  async function submit() {
    if (!envelope) return;
    setBusy(true);
    setError(null);
    setIssues([]);
    try {
      const level = await api.importLevel(envelope, slug.trim() || undefined);
      setCreated({ id: level.id, title: level.title });
    } catch (err) {
      if (err instanceof SessionEndedError) return;
      if (err instanceof ApiError) {
        if (err.code === "SLUG_TAKEN")
          setError("That slug is taken. Enter a new slug below and import again.");
        else if (err.code === "UNSUPPORTED_SCHEMA_VERSION") setError(err.message);
        else setError(err.message);
        if (Array.isArray(err.issues)) setIssues(err.issues as Issue[]);
      } else setError("The server could not be reached.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <PageHeading caption="Admin" title="Import" />
      <p className="mb-8 max-w-[640px] text-base font-semibold text-mute">
        Choose a level file exported from the dashboard. It is fully validated and becomes a new
        draft; no existing level or version is changed.
      </p>
      <div className="grid max-w-[560px] gap-5">
        <div>
          <label
            htmlFor="import-file"
            className="mb-2 block text-xs tracking-[2px] text-mute uppercase"
          >
            Level file
          </label>
          <input
            id="import-file"
            type="file"
            accept="application/json,.json"
            onChange={(e) => void pick(e)}
            className="block w-full text-base font-semibold"
          />
          {fileName && <p className="mt-2 text-sm font-semibold text-mute">{fileName}</p>}
        </div>
        <Field
          label="New slug (optional)"
          id="import-slug"
          value={slug}
          onChange={(e) => setSlug(e.target.value)}
          hint="Use this when the slug in the file is already taken."
        />
        {error && <Notice>{error}</Notice>}
        {issues.length > 0 && (
          <ul className="grid gap-2" aria-label="Problems found">
            {issues.map((issue, i) => (
              <li key={i} className="border-t border-faint pt-2 text-[15px] font-semibold">
                <span className="mr-3 text-mute">{issue.path || "level"}</span>
                {issue.message ?? issue.code}
              </li>
            ))}
          </ul>
        )}
        {created ? (
          <div className="grid gap-3">
            <Notice kind="info">Imported {created.title} as a new draft.</Notice>
            <div>
              <Link
                href={`/admin/levels/${created.id}`}
                className="inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px]"
              >
                Open the draft
              </Link>
            </div>
          </div>
        ) : (
          <div className="flex gap-3">
            <PrimaryAction type="button" onClick={() => void submit()} disabled={!envelope || busy}>
              {busy ? "Importing" : "Import level"}
            </PrimaryAction>
            <OutlineAction
              type="button"
              onClick={() => {
                setEnvelope(null);
                setFileName("");
                setError(null);
                setIssues([]);
              }}
            >
              Clear
            </OutlineAction>
          </div>
        )}
      </div>
    </div>
  );
}
