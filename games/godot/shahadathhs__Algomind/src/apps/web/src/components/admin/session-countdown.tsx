"use client";

import { useEffect, useState } from "react";
import { useSessionManager } from "./session-provider";

export function formatRemaining(ms: number): string {
  const total = Math.max(0, Math.ceil(ms / 1000));
  const m = Math.floor(total / 60);
  const s = total % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

/** Time left before the session ends for inactivity. Any input resets it. */
export function SessionCountdown() {
  const manager = useSessionManager();
  const [remaining, setRemaining] = useState<number | null>(null);

  useEffect(() => {
    const tick = () => setRemaining(manager.getInactivityDeadline() - Date.now());
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, [manager]);

  if (remaining === null) return <span className="inline-block h-11 min-w-[110px]" />;
  const soon = remaining <= 60_000;
  return (
    <p
      className="flex min-h-11 items-center gap-2 text-[13px] tracking-[2px] uppercase"
      aria-label={`Session ends after inactivity in ${formatRemaining(remaining)}`}
    >
      <span className="text-mute">{soon ? "Ending" : "Session"}</span>
      <span
        className={`tile px-2 py-0.5 tabular-nums ${soon ? "bg-signal text-on-signal" : "bg-ink text-on-ink"}`}
        style={{ ["--chamfer" as string]: "6px" }}
      >
        {formatRemaining(remaining)}
      </span>
    </p>
  );
}
