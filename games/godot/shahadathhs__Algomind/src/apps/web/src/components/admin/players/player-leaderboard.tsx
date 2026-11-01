import type { PlayerDetail } from "@/lib/admin/admin-api";
import { OutlineAction } from "../ui";
import type { usePlayer } from "./use-player";

type Actions = ReturnType<typeof usePlayer>["actions"];

const yesNo = (value: boolean) => (value ? "Yes" : "No");

/** Where this player stands on the public boards, and the admin override. */
export function PlayerLeaderboard({
  account,
  busy,
  actions,
}: {
  account: PlayerDetail["account"];
  busy: boolean;
  actions: Actions;
}) {
  const hidden = account.leaderboardHidden;
  const facts: [string, string][] = [
    ["Opted in", yesNo(account.leaderboardOptIn)],
    ["Shown as Anonymous", yesNo(account.hideName)],
    ["Hidden by an admin", yesNo(hidden)],
    ["Public id", account.publicId],
  ];
  return (
    <section aria-label="Leaderboard" className="mb-10 max-w-[560px]">
      <h2 className="mb-3 text-xs font-bold tracking-[2px] text-mute uppercase">Leaderboard</h2>
      <dl className="mb-4 grid grid-cols-[auto_1fr] gap-x-6 gap-y-2 text-[15px] font-semibold">
        {facts.map(([label, value]) => (
          <div key={label} className="contents">
            <dt className="text-mute">{label}</dt>
            <dd className="break-all">{value}</dd>
          </div>
        ))}
      </dl>
      <p className="mb-4 text-[15px] font-semibold text-mute">
        A player on the boards shows only their name (or Anonymous), rank, and points or result.
        Hiding removes them from every board without changing their account.
      </p>
      <OutlineAction
        type="button"
        disabled={busy}
        onClick={() => {
          const ask = hidden
            ? "Show this player on the boards again?"
            : "Hide this player from every leaderboard?";
          if (window.confirm(ask)) void actions.setBoardHidden(!hidden);
        }}
      >
        {hidden ? "Show on boards" : "Hide from boards"}
      </OutlineAction>
    </section>
  );
}
