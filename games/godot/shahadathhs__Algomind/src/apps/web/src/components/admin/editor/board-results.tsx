import { explainResult, type MultiRunResult } from "@/lib/admin/level-model";

/** A check or a cross in a small square; the word beside it carries the meaning too. */
export function ResultMark({ ok }: { ok: boolean }) {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" aria-hidden="true" className="shrink-0">
      <path
        d={ok ? "M2 7.5 5.5 11 12 3" : "M3 3 11 11 M11 3 3 11"}
        fill="none"
        stroke="currentColor"
        strokeWidth="2.5"
      />
    </svg>
  );
}

/** One row per board: check or cross, the word, the steps, and the reason a failed board gave. */
export function BoardResults({ run }: { run: MultiRunResult }) {
  if (run.results.length < 2) return null;
  return (
    <ul className="grid gap-1" aria-label="Result per board">
      {run.results.map((r, i) => {
        const ok = r.status === "SUCCEEDED";
        return (
          <li key={i} className="flex flex-wrap items-center gap-x-3 text-[15px] font-semibold">
            <span className="inline-flex items-center gap-2">
              <ResultMark ok={ok} />
              Board {i + 1}: {ok ? "Solved" : "Failed"}
            </span>
            <span className="text-mute">
              {r.steps} {r.steps === 1 ? "step" : "steps"}
              {!ok && `, ${explainResult(r)}`}
            </span>
          </li>
        );
      })}
    </ul>
  );
}
