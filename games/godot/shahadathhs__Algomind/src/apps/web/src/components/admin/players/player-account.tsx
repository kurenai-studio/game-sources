import type { PlayerDetail } from "@/lib/admin/admin-api";
import { when } from "@/lib/admin/format";

/** Who the player is: the facts an admin needs before acting. */
export function PlayerAccount({ detail }: { detail: PlayerDetail }) {
  const { account, points, progress, lastSyncAt } = detail;
  const facts: [string, string][] = [
    ["Display name", account.displayName ?? "None"],
    ["Joined", when(account.createdAt)],
    ["Last active", account.lastActiveAt ? when(account.lastActiveAt) : "Never"],
    ["Last sync", lastSyncAt ? when(lastSyncAt) : "Never"],
    ["Levels cleared", String(progress.length)],
    ["Points", String(points.total)],
  ];
  return (
    <dl className="mb-10 grid max-w-[560px] grid-cols-[auto_1fr] gap-x-6 gap-y-2 text-[15px] font-semibold">
      {facts.map(([label, value]) => (
        <div key={label} className="contents">
          <dt className="text-mute">{label}</dt>
          <dd>{value}</dd>
        </div>
      ))}
    </dl>
  );
}
