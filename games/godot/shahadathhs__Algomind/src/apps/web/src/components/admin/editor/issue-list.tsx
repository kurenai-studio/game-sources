"use client";

import { Caption } from "@/components/ui/caption";
import { boardIssuePath } from "@/lib/admin/board-model";
import type { CheckIssue } from "@/lib/admin/admin-api";

export function IssueList({ title, issues }: { title: string; issues: CheckIssue[] }) {
  if (issues.length === 0) return null;
  return (
    <div>
      <Caption as="h3" className="mb-2">
        {title} ({issues.length})
      </Caption>
      <ul className="grid gap-2">
        {issues.map((issue, i) => (
          <li
            key={i}
            className="flex flex-wrap gap-x-3 border-t border-faint pt-2 text-[15px] font-semibold"
          >
            <span className="text-xs tracking-[2px] uppercase">{issue.gate.replace("_", " ")}</span>
            <span className="text-mute">{boardIssuePath(issue.path) || "level"}</span>
            <span>{issue.message}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
