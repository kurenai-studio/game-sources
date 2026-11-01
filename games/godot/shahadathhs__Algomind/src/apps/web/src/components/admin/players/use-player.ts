"use client";

import { useCallback, useEffect, useState } from "react";
import { SessionEndedError } from "@/lib/api/errors";
import type { PlayerDetail } from "@/lib/admin/admin-api";
import { downloadJson } from "@/lib/admin/download";
import { apiMessage } from "@/lib/admin/messages";
import { useAdminApi } from "../use-admin-api";
import { useSocialApi } from "../use-social-api";

/** One player and the actions an admin can take on them. Each action reloads the detail. */
export function usePlayer(playerId: string) {
  const api = useAdminApi();
  const social = useSocialApi();
  const [detail, setDetail] = useState<PlayerDetail | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [gone, setGone] = useState(false);

  const load = useCallback(async () => {
    try {
      setDetail(await api.getPlayer(playerId));
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    }
  }, [api, playerId]);

  useEffect(() => {
    // The state updates run after the request resolves, not synchronously in the effect.
    // oxlint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  /** Runs an action, says what happened, and reloads. Resolves true when it worked. */
  const run = useCallback(
    async <T>(
      action: () => Promise<T>,
      done: string | ((result: T) => string),
      reload = true,
    ): Promise<boolean> => {
      setError(null);
      setNotice(null);
      setBusy(true);
      try {
        const result = await action();
        setNotice(typeof done === "string" ? done : done(result));
        if (reload) await load();
        return true;
      } catch (err) {
        if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
        return false;
      } finally {
        setBusy(false);
      }
    },
    [load],
  );

  const actions = {
    revokeSessions: () =>
      run(
        () => api.revokePlayerSessions(playerId),
        ({ revoked }) => `Signed out ${revoked} session${revoked === 1 ? "" : "s"}.`,
      ),
    resetProgress: () => run(() => api.resetPlayerProgress(playerId), "Progress and points reset."),
    setName: (name: string | null) =>
      run(
        () => api.setPlayerName(playerId, name),
        name ? "Display name saved." : "Display name cleared.",
      ),
    suspend: () => run(() => api.suspendPlayer(playerId), "Player suspended and signed out."),
    unsuspend: () => run(() => api.unsuspendPlayer(playerId), "Player can sign in again."),
    setBoardHidden: (hidden: boolean) =>
      run(
        () => social.setLeaderboardHidden(playerId, hidden),
        hidden ? "Player hidden from the boards." : "Player shown on the boards again.",
      ),
    export: () =>
      run(
        async () => downloadJson(`player-${playerId}.json`, await api.exportPlayer(playerId)),
        "Data exported.",
        false,
      ),
    remove: async (confirmEmail: string) => {
      const ok = await run(
        () => api.deletePlayer(playerId, confirmEmail),
        "Account deleted.",
        false,
      );
      if (ok) setGone(true);
      return ok;
    },
  };

  return { detail, error, notice, busy, gone, actions };
}
