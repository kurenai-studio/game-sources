import Link from "next/link";
import { when } from "@/lib/admin/format";
import type { AdminReport, ReportAction } from "@/lib/admin/social-api";
import { LabelTile } from "../ui";
import { TextAction } from "../text-action";

/** One report: who was reported, why, and the three ways to close it. */
export function ReportRow({
  report,
  busy,
  onResolve,
}: {
  report: AdminReport;
  busy: boolean;
  onResolve: (report: AdminReport, action: ReportAction) => void;
}) {
  const t = report.target;
  const open = report.status === "OPEN";
  const name = t ? (t.displayName ?? (t.hideName ? "Anonymous" : "No name")) : "Player deleted";
  return (
    <li className="border-t-2 border-ink py-4">
      <div className="grid gap-x-6 gap-y-2 sm:grid-cols-[1fr_auto]">
        <div>
          <p className="flex flex-wrap items-center gap-3 text-lg tracking-[1px] break-all uppercase">
            {t ? (
              <Link
                href={`/admin/players/${t.id}`}
                className="underline decoration-2 underline-offset-[6px]"
              >
                {name}
              </Link>
            ) : (
              name
            )}
            <LabelTile solid={open}>{open ? "Open" : report.status.toLowerCase()}</LabelTile>
            {t?.leaderboardHidden && <LabelTile>Hidden</LabelTile>}
          </p>
          <p className="mt-1 text-[15px] font-semibold break-words">Reason: {report.reason}</p>
          <p className="mt-1 text-sm font-semibold text-mute">
            Reported {when(report.createdAt)}
            {report.resolvedAt ? `. Closed ${when(report.resolvedAt)}.` : "."}
          </p>
        </div>
        {open && (
          <div className="flex flex-wrap items-start gap-x-5">
            <TextAction disabled={busy} onClick={() => onResolve(report, "dismiss")}>
              Dismiss
            </TextAction>
            <TextAction
              disabled={busy || !t?.displayName}
              onClick={() => onResolve(report, "clear_name")}
            >
              Clear name
            </TextAction>
            <TextAction disabled={busy || !t} onClick={() => onResolve(report, "hide")}>
              Hide from boards
            </TextAction>
          </div>
        )}
      </div>
    </li>
  );
}
