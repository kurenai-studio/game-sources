"use client";

import { useState, type FormEvent } from "react";
import type { PlayerDetail } from "@/lib/admin/admin-api";
import { Field, OutlineAction } from "../ui";
import { TextAction } from "../text-action";
import type { usePlayer } from "./use-player";

type Actions = ReturnType<typeof usePlayer>["actions"];

/** Everything an admin can do to this player. Each action is written to the audit log. */
export function PlayerActions({
  account,
  busy,
  actions,
}: {
  account: PlayerDetail["account"];
  busy: boolean;
  actions: Actions;
}) {
  const [name, setName] = useState(account.displayName ?? "");
  const [deleting, setDeleting] = useState(false);
  const [typed, setTyped] = useState("");
  const suspended = account.status === "SUSPENDED";

  function saveName(e: FormEvent) {
    e.preventDefault();
    void actions.setName(name.trim() || null);
  }

  return (
    <section aria-label="Actions" className="mb-10 grid max-w-[560px] gap-6">
      <h2 className="text-xs font-bold tracking-[2px] text-mute uppercase">Actions</h2>
      <form onSubmit={saveName} className="flex flex-wrap items-end gap-3">
        <Field
          label="Display name"
          id="player-name"
          value={name}
          maxLength={24}
          onChange={(e) => setName(e.target.value)}
        />
        <OutlineAction type="submit" disabled={busy || name.trim() === (account.displayName ?? "")}>
          Save name
        </OutlineAction>
        {account.displayName && (
          <TextAction
            disabled={busy}
            onClick={() => {
              setName("");
              void actions.setName(null);
            }}
          >
            Clear name
          </TextAction>
        )}
      </form>
      <div className="flex flex-wrap gap-x-5 gap-y-1">
        <TextAction
          disabled={busy}
          onClick={() => {
            if (window.confirm("Sign this player out of every device?"))
              void actions.revokeSessions();
          }}
        >
          Sign out everywhere
        </TextAction>
        {suspended ? (
          <TextAction disabled={busy} onClick={() => void actions.unsuspend()}>
            Unsuspend
          </TextAction>
        ) : (
          <TextAction
            disabled={busy}
            onClick={() => {
              if (window.confirm("Suspend this player? They are signed out and cannot sign in."))
                void actions.suspend();
            }}
          >
            Suspend
          </TextAction>
        )}
        <TextAction disabled={busy} onClick={() => void actions.export()}>
          Export data
        </TextAction>
        <TextAction
          disabled={busy}
          onClick={() => {
            if (
              window.confirm(
                "Reset this player's progress and points on the server? Their device keeps its copy and sends it again at the next sync.",
              )
            )
              void actions.resetProgress();
          }}
        >
          Reset progress
        </TextAction>
        <TextAction disabled={busy} onClick={() => setDeleting(true)}>
          Delete account
        </TextAction>
      </div>
      {deleting && (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            void actions.remove(typed);
          }}
          className="grid gap-3"
          aria-label="Delete account"
        >
          <p className="text-base font-semibold">
            This deletes the account, progress, points and sessions for good. Type {account.email}{" "}
            to confirm.
          </p>
          <Field
            label="Email to confirm"
            id="player-delete"
            value={typed}
            onChange={(e) => setTyped(e.target.value)}
            autoComplete="off"
          />
          <div className="flex flex-wrap gap-3">
            <OutlineAction type="submit" disabled={busy || typed.trim() !== account.email}>
              Delete account
            </OutlineAction>
            <OutlineAction type="button" onClick={() => setDeleting(false)}>
              Cancel
            </OutlineAction>
          </div>
        </form>
      )}
    </section>
  );
}
