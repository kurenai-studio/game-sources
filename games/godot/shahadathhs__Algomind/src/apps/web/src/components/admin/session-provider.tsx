"use client";

import { usePathname } from "next/navigation";
import {
  createContext,
  useContext,
  useEffect,
  useState,
  useSyncExternalStore,
  type ReactNode,
} from "react";
import { SIGN_IN_PATH } from "@/lib/admin/config";
import {
  SessionManager,
  type ChannelLike,
  type LocksLike,
  type SessionState,
} from "@/lib/admin/session-manager";

const SESSION_CHANNEL = "algomind-admin-session";
const ACTIVITY_EVENTS = ["pointerdown", "keydown", "scroll", "touchstart"] as const;

const SessionContext = createContext<SessionManager | null>(null);
const LOADING: SessionState = { status: "loading" };

function createManager(inactivityMinutes: number): SessionManager {
  return new SessionManager({
    fetch: (input, init) => fetch(input, init),
    now: () => Date.now(),
    setTimer: (fn, ms) => setTimeout(fn, ms),
    clearTimer: (handle) => clearTimeout(handle as ReturnType<typeof setTimeout>),
    openChannel: () =>
      typeof BroadcastChannel === "undefined"
        ? null
        : (new BroadcastChannel(SESSION_CHANNEL) as unknown as ChannelLike),
    locks:
      typeof navigator !== "undefined" && "locks" in navigator
        ? (navigator.locks as unknown as LocksLike)
        : null,
    inactivityMs: inactivityMinutes * 60_000,
  });
}

/** Owns the session manager for the whole /admin area. */
export function SessionProvider({
  inactivityMinutes,
  children,
}: {
  inactivityMinutes: number;
  children: ReactNode;
}) {
  const [manager] = useState(() => createManager(inactivityMinutes));
  const pathname = usePathname();
  const onSignIn = pathname === SIGN_IN_PATH;

  useEffect(() => {
    // The sign-in page has no session to restore; the cookie check there would only fail.
    void manager.start({ restore: !onSignIn });
    const onActivity = () => manager.noteActivity();
    const onVisible = () => {
      if (document.visibilityState === "visible") manager.checkNow();
    };
    for (const name of ACTIVITY_EVENTS)
      window.addEventListener(name, onActivity, { passive: true });
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      for (const name of ACTIVITY_EVENTS) window.removeEventListener(name, onActivity);
      document.removeEventListener("visibilitychange", onVisible);
      manager.stop();
    };
    // Restoring happens once per mount; moving between pages keeps the in-memory session.
    // oxlint-disable-next-line react-hooks/exhaustive-deps
  }, [manager]);

  return <SessionContext.Provider value={manager}>{children}</SessionContext.Provider>;
}

export function useSessionManager(): SessionManager {
  const manager = useContext(SessionContext);
  if (!manager) throw new Error("useSessionManager must be used inside SessionProvider.");
  return manager;
}

export function useSessionState(): SessionState {
  const manager = useSessionManager();
  return useSyncExternalStore(manager.subscribe, manager.getState, () => LOADING);
}
