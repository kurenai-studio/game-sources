"use client";

import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { formText } from "@/lib/admin/form";
import { ApiError, NetworkError, SessionEndedError } from "@/lib/api/errors";
import { PageHeading, Field, Notice, PrimaryAction } from "./ui";
import { useSessionManager, useSessionState } from "./session-provider";

type Issue = { message?: unknown };

function messageFor(err: unknown): string {
  if (err instanceof SessionEndedError) return "The session ended. Sign in again.";
  if (err instanceof NetworkError) return "The API could not be reached. Try again shortly.";
  if (err instanceof ApiError) {
    if (err.status === 422 && err.code === "INVALID_CURRENT_PASSWORD") {
      return "The current password is incorrect.";
    }
    if (err.status === 422) {
      const issues = Array.isArray(err.issues) ? (err.issues as Issue[]) : [];
      const first = issues.find((i) => typeof i.message === "string")?.message;
      return typeof first === "string" ? first : err.message;
    }
    return err.message;
  }
  return "The password could not be changed.";
}

export function ChangePasswordForm() {
  const manager = useSessionManager();
  const state = useSessionState();
  const router = useRouter();
  const [error, setError] = useState<string>();
  const [pending, setPending] = useState(false);
  const forced = state.status === "authenticated" && state.user.mustChangePassword;

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const current = formText(form, "current");
    const next = formText(form, "new");
    const confirm = formText(form, "confirm");
    if (next !== confirm) return setError("The new passwords do not match.");
    if (next === current) return setError("The new password must differ from the current one.");
    setPending(true);
    setError(undefined);
    try {
      await manager.changePassword(current, next);
      router.replace("/admin");
    } catch (err) {
      setError(messageFor(err));
      setPending(false);
    }
  }

  return (
    <div className="max-w-[420px]">
      <PageHeading caption="Account" title="Change password" />
      {forced && (
        <div className="mb-6">
          <Notice kind="info">Choose a new password before using the dashboard.</Notice>
        </div>
      )}
      <form onSubmit={onSubmit} className="flex flex-col gap-6">
        {error && <Notice>{error}</Notice>}
        <Field
          label="Current password"
          id="current"
          name="current"
          type="password"
          autoComplete="current-password"
          required
        />
        <Field
          label="New password"
          id="new"
          name="new"
          type="password"
          autoComplete="new-password"
          required
        />
        <Field
          label="Repeat new password"
          id="confirm"
          name="confirm"
          type="password"
          autoComplete="new-password"
          required
        />
        <PrimaryAction type="submit" disabled={pending} className="w-full">
          {pending ? "Saving" : "Change password"}
        </PrimaryAction>
      </form>
    </div>
  );
}
