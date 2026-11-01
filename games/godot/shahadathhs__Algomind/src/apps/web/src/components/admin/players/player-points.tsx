import type { PlayerDetail } from "@/lib/admin/admin-api";
import { when } from "@/lib/admin/format";

const REASON: Record<string, string> = {
  FIRST_CLEAR: "First clear",
  IMPROVED_RESULT: "Better result",
  RESET: "Reset by an admin",
};

/** The points ledger, newest first: every change with its reason and the rule version. */
export function PlayerPoints({ points }: { points: PlayerDetail["points"] }) {
  return (
    <section aria-label="Points history" className="mb-10">
      <h2 className="mb-3 text-xs font-bold tracking-[2px] text-mute uppercase">
        Points history, {points.total} in total
      </h2>
      {points.history.length === 0 ? (
        <p className="text-base font-semibold text-mute">No points yet.</p>
      ) : (
        <ul className="grid max-w-[760px]">
          {points.history.map((h, i) => (
            <li
              key={i}
              className="grid gap-x-5 border-t border-faint py-2 text-[15px] font-semibold sm:grid-cols-[160px_1fr_80px_90px]"
            >
              <span className="text-mute">{when(h.createdAt)}</span>
              <span>
                {REASON[h.reason] ?? h.reason}
                {h.levelSlug ? `, ${h.levelSlug}` : ""}
              </span>
              <span className="tabular-nums">{h.delta > 0 ? `+${h.delta}` : h.delta}</span>
              <span className="text-mute">
                {h.ruleVersion > 0 ? `rules v${h.ruleVersion}` : ""}
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
