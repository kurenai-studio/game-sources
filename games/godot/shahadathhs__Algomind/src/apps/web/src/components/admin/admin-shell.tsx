"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useRef, type ReactNode } from "react";
import { ThemeToggle } from "@/components/public/theme-toggle";
import { Wordmark } from "@/components/ui/wordmark";
import { CHANGE_PASSWORD_PATH, SIGN_IN_PATH } from "@/lib/admin/config";
import { OutlineAction } from "./ui";
import { SessionCountdown } from "./session-countdown";
import { useSessionManager, useSessionState } from "./session-provider";

/** Only built screens appear here. */
const NAV = [
  { href: "/admin", label: "Home" },
  { href: "/admin/levels", label: "Levels" },
  { href: "/admin/campaign", label: "Campaign" },
  { href: "/admin/players", label: "Players" },
  { href: "/admin/reports", label: "Reports" },
  { href: "/admin/daily", label: "Daily" },
  { href: "/admin/achievements", label: "Badges" },
  { href: "/admin/level-stats", label: "Statistics" },
  { href: "/admin/contact", label: "Contact" },
  { href: "/admin/capabilities", label: "Capabilities" },
  { href: "/admin/points", label: "Points" },
  { href: "/admin/import", label: "Import" },
  { href: "/admin/audit", label: "Audit log" },
  { href: "/admin/settings", label: "Settings" },
] as const;

function StatusScreen({ children }: { children: ReactNode }) {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-[420px] flex-col justify-center gap-4 px-5 py-10">
      <Wordmark />
      {children}
    </main>
  );
}

/**
 * The admin frame and the browser-side route guard. The guard is for user experience; the API
 * authorizes every call. Signed-out visitors are sent to sign-in, and an account that must change
 * its password is sent to that page first.
 */
export function AdminShell({ children }: { children: ReactNode }) {
  const state = useSessionState();
  const manager = useSessionManager();
  const pathname = usePathname();
  const router = useRouter();
  const mustChange = state.status === "authenticated" && state.user.mustChangePassword;

  const triedRestore = useRef(false);

  useEffect(() => {
    if (state.status !== "anonymous") return;
    // Arriving from the sign-in page leaves the session unrestored even with a valid cookie
    // (Back button): look once before sending the visitor to sign in again.
    if (!state.reason && !triedRestore.current) {
      triedRestore.current = true;
      void manager.restoreQuietly();
      return;
    }
    const params = new URLSearchParams();
    if (state.reason) params.set("reason", state.reason);
    if (state.reason !== "signed-out" && pathname !== "/admin") params.set("next", pathname);
    const query = params.toString();
    // A full navigation, so memory is dropped and the cleared cookie is seen by the server.
    window.location.assign(query ? `${SIGN_IN_PATH}?${query}` : SIGN_IN_PATH);
  }, [state, pathname, manager]);

  useEffect(() => {
    if (mustChange && pathname !== CHANGE_PASSWORD_PATH) router.replace(CHANGE_PASSWORD_PATH);
  }, [mustChange, pathname, router]);

  if (state.status === "loading") {
    return (
      <StatusScreen>
        <p role="status" className="text-sm tracking-[2px] uppercase">
          {state.offline ? "Waiting for the server" : "Restoring session"}
        </p>
        <noscript>
          <p className="text-[15px] font-semibold">The dashboard needs JavaScript.</p>
        </noscript>
      </StatusScreen>
    );
  }
  if (state.status === "anonymous") {
    return (
      <StatusScreen>
        <p role="status" className="text-sm tracking-[2px] uppercase">
          Going to sign in
        </p>
        <Link
          href={SIGN_IN_PATH}
          className="text-[13px] tracking-[2px] underline decoration-2 underline-offset-[6px] uppercase"
        >
          Sign in
        </Link>
      </StatusScreen>
    );
  }
  if (mustChange && pathname !== CHANGE_PASSWORD_PATH) {
    return (
      <StatusScreen>
        <p role="status" className="text-sm tracking-[2px] uppercase">
          Password change required
        </p>
      </StatusScreen>
    );
  }

  return (
    <div className="mx-auto w-full max-w-[1120px] px-5 pb-16 sm:px-8">
      <header className="flex flex-wrap items-center justify-between gap-x-6 gap-y-2 py-4">
        <div className="flex items-center gap-4">
          <Wordmark size="sm" />
          <span className="text-xs tracking-[2px] text-mute uppercase">Admin</span>
        </div>
        <div className="flex flex-wrap items-center gap-x-4 gap-y-1">
          <SessionCountdown />
          <ThemeToggle />
          <OutlineAction type="button" onClick={() => void manager.logout()}>
            Sign out
          </OutlineAction>
        </div>
      </header>
      {!mustChange && (
        <nav aria-label="Dashboard" className="mb-10 flex flex-wrap gap-3">
          {NAV.map((item) => {
            const current =
              item.href === "/admin" ? pathname === item.href : pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                aria-current={current ? "page" : undefined}
                className={`tile inline-flex h-11 items-center px-5 text-[13px] tracking-[2px] uppercase ${
                  current ? "bg-ink text-on-ink" : "bg-strip text-ink"
                }`}
                style={{ ["--chamfer" as string]: "10px" }}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>
      )}
      <main id="main">{children}</main>
    </div>
  );
}
