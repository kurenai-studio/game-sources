"use client";

import Link from "next/link";
import { Notice } from "./ui";
import { PlayerAccount } from "./players/player-account";
import { PlayerActions } from "./players/player-actions";
import { PlayerLeaderboard } from "./players/player-leaderboard";
import { PlayerPoints } from "./players/player-points";
import { PlayerProgress } from "./players/player-progress";
import { PlayerSessions } from "./players/player-sessions";
import { PlayerStatusTile } from "./players/player-status";
import { usePlayer } from "./players/use-player";

/** One player: who they are, what they have done, and what an admin can do. */
export function PlayerDetail({ playerId }: { playerId: string }) {
  const { detail, error, notice, busy, gone, actions } = usePlayer(playerId);

  if (gone) {
    return (
      <div className="py-6">
        <Notice kind="info">The account was deleted.</Notice>
        <div className="mt-4">
          <Link href="/admin/players" className="underline decoration-2 underline-offset-[6px]">
            All players
          </Link>
        </div>
      </div>
    );
  }
  if (!detail) {
    return error ? (
      <div className="py-6">
        <Notice>{error}</Notice>
      </div>
    ) : (
      <p role="status" className="py-10 text-sm tracking-[2px] uppercase">
        Loading player
      </p>
    );
  }

  return (
    <div>
      <Link
        href="/admin/players"
        className="mb-4 inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px]"
      >
        All players
      </Link>
      <div className="mb-8">
        <p className="mb-2 text-xs tracking-[2px] text-mute uppercase">Player</p>
        <h1 className="flex flex-wrap items-center gap-4 text-[34px] leading-tight tracking-[1px] break-all uppercase">
          {detail.account.email}
          <PlayerStatusTile status={detail.account.status} />
        </h1>
      </div>
      {notice && (
        <div className="mb-4">
          <Notice kind="info">{notice}</Notice>
        </div>
      )}
      {error && (
        <div className="mb-4">
          <Notice>{error}</Notice>
        </div>
      )}
      <PlayerAccount detail={detail} />
      <PlayerActions
        key={detail.account.displayName ?? ""}
        account={detail.account}
        busy={busy}
        actions={actions}
      />
      <PlayerLeaderboard account={detail.account} busy={busy} actions={actions} />
      <PlayerProgress progress={detail.progress} />
      <PlayerPoints points={detail.points} />
      <PlayerSessions sessions={detail.sessions} settings={detail.settings} />
    </div>
  );
}
