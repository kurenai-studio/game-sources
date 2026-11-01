"use client";

import { useCallback, useEffect, useState } from "react";
import { SessionEndedError } from "@/lib/api/errors";
import { apiMessage } from "@/lib/admin/messages";

/**
 * One loaded resource plus the actions that change it. `run` clears the messages, performs the
 * action, says what happened, and reloads. `load` must be stable (wrap it in useCallback).
 */
export function useAdminResource<T>(load: () => Promise<T>) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const reload = useCallback(async () => {
    try {
      setData(await load());
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    }
  }, [load]);

  useEffect(() => {
    // The state updates run after the request resolves, not synchronously in the effect.
    // oxlint-disable-next-line react-hooks/set-state-in-effect
    void reload();
  }, [reload]);

  /** Resolves true when the action worked. */
  const run = useCallback(
    async <R>(action: () => Promise<R>, done: string): Promise<boolean> => {
      setError(null);
      setNotice(null);
      setBusy(true);
      try {
        await action();
        setNotice(done);
        await reload();
        return true;
      } catch (err) {
        if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
        return false;
      } finally {
        setBusy(false);
      }
    },
    [reload],
  );

  return { data, error, notice, busy, run, reload };
}
