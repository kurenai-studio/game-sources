"use client";

import { useCallback, useState } from "react";
import { Caption } from "@/components/ui/caption";
import type { AdminReport, ReportAction } from "@/lib/admin/social-api";
import { OutlineAction, PageHeading, SelectField } from "../ui";
import { ResourceMessages } from "../resource-messages";
import { useAdminResource } from "../use-admin-resource";
import { useSocialApi } from "../use-social-api";
import { ReportRow } from "./report-row";

const CONFIRM: Record<ReportAction, (name: string) => string> = {
  dismiss: () => "Dismiss this report? No change is made to the player.",
  clear_name: (name) =>
    `Clear the name "${name}"? The player also leaves the boards until they choose a new name and opt in again.`,
  hide: (name) =>
    `Hide ${name} from every leaderboard? You can show them again from their player page.`,
};
const DONE: Record<ReportAction, string> = {
  dismiss: "Report dismissed.",
  clear_name: "Name cleared and the player taken off the boards. The report is closed.",
  hide: "Player hidden from the boards. The report is closed.",
};

/** The moderation queue: reported names, and what an admin can do about each. */
export function ReportsAdmin() {
  const api = useSocialApi();
  const [status, setStatus] = useState<"OPEN" | "ALL">("OPEN");
  const load = useCallback(async () => (await api.listReports(status)).items, [api, status]);
  const { data, error, notice, busy, run, reload } = useAdminResource(load);

  function resolve(report: AdminReport, action: ReportAction) {
    const name = report.target?.displayName ?? "this player";
    if (!window.confirm(CONFIRM[action](name))) return;
    void run(() => api.resolveReport(report.id, action), DONE[action]);
  }

  return (
    <div>
      <PageHeading caption="Admin" title="Reports" />
      <p className="mb-8 max-w-[640px] text-base font-semibold text-mute">
        Players can report a name on a leaderboard. Dismiss a report that is not a problem, clear a
        name that is, or hide a player from every board. Nothing here deletes an account or shows a
        player&apos;s email.
      </p>
      <div className="mb-6 max-w-[240px]">
        <SelectField
          label="Show"
          id="report-status"
          value={status}
          onChange={(e) => setStatus(e.target.value as "OPEN" | "ALL")}
        >
          <option value="OPEN">Open reports</option>
          <option value="ALL">All reports</option>
        </SelectField>
      </div>
      <ResourceMessages notice={notice} error={error} loading={!data} what="reports" />
      {!data && error && (
        <OutlineAction type="button" onClick={() => void reload()}>
          Try again
        </OutlineAction>
      )}
      {data && data.length === 0 && (
        <div className="py-6">
          <Caption>No reports</Caption>
          <p className="mt-2 text-base font-semibold text-mute">
            {status === "OPEN" ? "Nothing is waiting for review." : "Nobody has been reported."}
          </p>
        </div>
      )}
      {data && data.length > 0 && (
        <ul className="grid" aria-label="Reports">
          {data.map((r) => (
            <ReportRow key={r.id} report={r} busy={busy} onResolve={resolve} />
          ))}
        </ul>
      )}
    </div>
  );
}
