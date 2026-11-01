"use client";

import { apiMessage } from "@/lib/admin/messages";
import { useCallback, useEffect, useState, type FormEvent } from "react";
import { SessionEndedError } from "@/lib/api/errors";
import type { ClientVersion } from "@/lib/admin/admin-api";
import { Field, Notice, PageHeading, PrimaryAction } from "./ui";
import { useAdminApi } from "./use-admin-api";

const MECHANICS = [
  "move",
  "turn",
  "repeat",
  "repeat_until",
  "if",
  "procedures",
  "multi_board",
  "counter",
  "nested_loops",
  "markers",
  "visit_all",
  "start_program",
  "patrol",
  "keys",
  "delivery",
  "switch",
  "teleport",
  "recursion",
  "ice",
  "belts",
];

/** Which mechanics each released app version supports. Publishing checks the minimum version. */
export function Capabilities() {
  const api = useAdminApi();
  const [items, setItems] = useState<ClientVersion[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [version, setVersion] = useState("");
  const [mechanics, setMechanics] = useState<string[]>(["move", "turn", "repeat"]);
  const [minimum, setMinimum] = useState(false);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    try {
      setItems((await api.listClientVersions()).items);
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    }
  }, [api]);

  useEffect(() => {
    // The state updates run after the request resolves, not synchronously in the effect.
    // oxlint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  async function add(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setBusy(true);
    try {
      await api.createClientVersion({
        version: version.trim(),
        supportedMechanics: mechanics,
        isMinimum: minimum,
      });
      setVersion("");
      setMinimum(false);
      await load();
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    } finally {
      setBusy(false);
    }
  }

  async function makeMinimum(id: string) {
    setError(null);
    try {
      await api.setMinimumClientVersion(id);
      await load();
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    }
  }

  return (
    <div>
      <PageHeading caption="Admin" title="Capabilities" />
      <p className="mb-8 max-w-[640px] text-base font-semibold text-mute">
        A level can be published only when the minimum supported app version can play every mechanic
        it needs. Players on older apps see an update screen once the minimum is raised.
      </p>
      {error && (
        <div className="mb-4">
          <Notice>{error}</Notice>
        </div>
      )}
      {!items && !error && (
        <p role="status" className="text-sm tracking-[2px] uppercase">
          Loading
        </p>
      )}
      {items && (
        <ul className="mb-12 grid max-w-[760px]" aria-label="App versions">
          {items.length === 0 && (
            <li className="text-base font-semibold text-mute">No app versions registered.</li>
          )}
          {items.map((v) => (
            <li
              key={v.id}
              className="flex flex-wrap items-center gap-x-5 gap-y-1 border-t-2 border-ink py-3"
            >
              <span className="text-lg tracking-[1px] tabular-nums uppercase">{v.version}</span>
              <span className="grow text-[15px] font-semibold">
                {v.supportedMechanics.join(", ") || "No mechanics"}
              </span>
              {v.isMinimum ? (
                <span
                  className="tile inline-flex h-7 items-center bg-ink px-2.5 text-xs tracking-[2px] text-on-ink uppercase"
                  style={{ ["--chamfer" as string]: "7px" }}
                >
                  Minimum
                </span>
              ) : (
                <button
                  type="button"
                  onClick={() => {
                    if (
                      window.confirm(
                        `Make ${v.version} the minimum? Publishing checks every level against this version from now on.`,
                      )
                    )
                      void makeMinimum(v.id);
                  }}
                  className="inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px]"
                >
                  Make minimum
                </button>
              )}
            </li>
          ))}
        </ul>
      )}
      <form
        onSubmit={add}
        aria-label="Register an app version"
        className="grid max-w-[480px] gap-5"
      >
        <h2 className="text-xs font-bold tracking-[2px] text-mute uppercase">
          Register an app version
        </h2>
        <Field
          label="Version"
          id="cv-version"
          value={version}
          placeholder="0.1.0"
          onChange={(e) => setVersion(e.target.value)}
          required
        />
        <fieldset>
          <legend className="mb-2 text-xs tracking-[2px] text-mute uppercase">
            Supported mechanics
          </legend>
          <div className="grid gap-1">
            {MECHANICS.map((m) => (
              <label key={m} className="flex min-h-11 items-center gap-3 text-base font-semibold">
                <input
                  type="checkbox"
                  className="h-5 w-5 accent-[var(--ink)]"
                  checked={mechanics.includes(m)}
                  onChange={() =>
                    setMechanics((cur) =>
                      cur.includes(m) ? cur.filter((x) => x !== m) : [...cur, m],
                    )
                  }
                />
                {m}
              </label>
            ))}
          </div>
        </fieldset>
        <label className="flex min-h-11 items-center gap-3 text-base font-semibold">
          <input
            type="checkbox"
            className="h-5 w-5 accent-[var(--ink)]"
            checked={minimum}
            onChange={(e) => setMinimum(e.target.checked)}
          />
          Make this the minimum supported version
        </label>
        <div>
          <PrimaryAction type="submit" disabled={busy || !version.trim()}>
            {busy ? "Adding" : "Add version"}
          </PrimaryAction>
        </div>
      </form>
    </div>
  );
}
