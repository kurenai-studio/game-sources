"use client";

import { useEffect, useState, type ReactNode } from "react";
import { Caption } from "@/components/ui/caption";
import { TextLink } from "@/components/ui/text-link";
import { OutlineAction, PageHeading } from "./ui";
import { ApiStatus } from "./api-status";
import { useSessionManager, useSessionState } from "./session-provider";

function Row({ term, children }: { term: string; children: ReactNode }) {
  return (
    <div className="flex flex-wrap gap-x-6 gap-y-1 py-2">
      <dt className="w-44 text-xs tracking-[2px] text-mute uppercase">{term}</dt>
      <dd className="text-base break-all">{children}</dd>
    </div>
  );
}

function clock(ms: number): string {
  return new Date(ms).toLocaleTimeString([], { hour12: false });
}

export function SettingsView() {
  const state = useSessionState();
  const manager = useSessionManager();
  const [expiry, setExpiry] = useState(0);

  useEffect(() => {
    const read = () => setExpiry(manager.getAccessExpiry());
    read();
    const id = setInterval(read, 5000);
    return () => clearInterval(id);
  }, [manager]);

  if (state.status !== "authenticated") return null;
  const minutes = Math.round(manager.getInactivityMs() / 60_000);
  return (
    <>
      <PageHeading caption="Admin" title="Settings" />
      <div className="flex flex-col gap-10">
        <section aria-labelledby="account">
          <Caption as="h2" className="mb-2">
            <span id="account">Account</span>
          </Caption>
          <dl>
            <Row term="Email">{state.user.email}</Row>
            <Row term="Role">{state.user.role}</Row>
          </dl>
          <TextLink href="/admin/change-password">Change password</TextLink>
        </section>
        <section aria-labelledby="session">
          <Caption as="h2" className="mb-2">
            <span id="session">Session</span>
          </Caption>
          <dl>
            <Row term="Inactivity limit">{minutes} minutes</Row>
            <Row term="Access renews">{expiry ? `Before ${clock(expiry)}` : "Not yet"}</Row>
          </dl>
        </section>
        <ApiStatus />
        <div>
          <OutlineAction type="button" onClick={() => void manager.logout()}>
            Sign out
          </OutlineAction>
        </div>
      </div>
    </>
  );
}
