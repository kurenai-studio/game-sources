"use client";

import { useEffect, useState } from "react";
import { ApiError, SessionEndedError } from "@/lib/api/errors";
import { readReadiness, type Readiness } from "@/lib/api/client";
import { Caption } from "@/components/ui/caption";
import { OutlineAction } from "./ui";
import { useSessionManager } from "./session-provider";

type View = { kind: "loading" } | { kind: "done"; value: Readiness } | { kind: "forbidden" };

const LABEL: Record<Readiness, string> = {
  ready: "Ready",
  "database-down": "Up, database down",
  unreachable: "Unreachable",
};

/** API health, read through the signed-in session. Shows a label and a mark, never color alone. */
export function ApiStatus() {
  const manager = useSessionManager();
  const [view, setView] = useState<View>({ kind: "loading" });

  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let live = true;
    readReadiness(manager.request).then(
      (value) => live && setView({ kind: "done", value }),
      (err: unknown) => {
        if (!live || err instanceof SessionEndedError) return;
        if (err instanceof ApiError && err.status === 403) setView({ kind: "forbidden" });
        else setView({ kind: "done", value: "unreachable" });
      },
    );
    return () => {
      live = false;
    };
  }, [manager, attempt]);

  function check() {
    setView({ kind: "loading" });
    setAttempt((n) => n + 1);
  }

  const ok = view.kind === "done" && view.value === "ready";
  return (
    <section aria-labelledby="api-status">
      <Caption as="h2" className="mb-3">
        <span id="api-status">API</span>
      </Caption>
      <div className="flex flex-wrap items-center gap-4">
        <p
          role="status"
          className="flex min-h-11 items-center gap-3 text-lg tracking-[1px] uppercase"
        >
          <span
            aria-hidden="true"
            className={`tile inline-flex h-7 w-7 items-center justify-center text-sm ${
              ok
                ? "bg-ink text-on-ink"
                : "bg-ground text-ink outline-2 -outline-offset-2 outline-ink"
            }`}
            style={{ ["--chamfer" as string]: "7px" }}
          >
            {view.kind === "loading" ? "·" : ok ? "OK" : "!"}
          </span>
          {view.kind === "loading" && "Checking"}
          {view.kind === "forbidden" && "Forbidden"}
          {view.kind === "done" && LABEL[view.value]}
        </p>
        {view.kind !== "loading" && (
          <OutlineAction type="button" onClick={check}>
            Check again
          </OutlineAction>
        )}
      </div>
      {view.kind === "forbidden" && (
        <p className="mt-3 text-[15px] font-semibold text-mute">
          This account is not allowed to read the API status.
        </p>
      )}
    </section>
  );
}
