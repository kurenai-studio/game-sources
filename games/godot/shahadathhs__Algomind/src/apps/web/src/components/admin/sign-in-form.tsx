"use client";

import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { formText } from "@/lib/admin/form";
import { SIGN_IN_ERRORS } from "@/lib/admin/messages";
import { ApiError, NetworkError } from "@/lib/api/errors";
import { Field, Notice, PrimaryAction } from "./ui";
import { useSessionManager } from "./session-provider";

function messageFor(err: unknown): string {
  if (err instanceof NetworkError) return SIGN_IN_ERRORS.unavailable;
  if (err instanceof ApiError) {
    if (err.code === "INVALID_CREDENTIALS" || err.status === 401) return SIGN_IN_ERRORS.invalid;
    if (err.code === "NOT_ADMIN") return SIGN_IN_ERRORS.forbidden;
    if (err.status === 429) return SIGN_IN_ERRORS.rate;
    return SIGN_IN_ERRORS.unavailable;
  }
  return SIGN_IN_ERRORS.unavailable;
}

/**
 * Works without JavaScript (a plain POST that answers with a redirect). With JavaScript it signs
 * in over fetch so the access token stays in memory and the page does not reload.
 */
export function SignInForm({
  next,
  initialError,
  note,
}: {
  next: string;
  initialError?: string;
  note?: string;
}) {
  const manager = useSessionManager();
  const router = useRouter();
  const [error, setError] = useState<string | undefined>(initialError);
  const [pending, setPending] = useState(false);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    setPending(true);
    setError(undefined);
    try {
      await manager.login(formText(form, "email"), formText(form, "password"));
      router.replace(next);
    } catch (err) {
      setError(messageFor(err));
      setPending(false);
    }
  }

  return (
    <form
      method="post"
      action="/admin/api/session/login"
      onSubmit={onSubmit}
      className="flex flex-col gap-6"
    >
      <input type="hidden" name="next" value={next} />
      {note && !error && <Notice kind="info">{note}</Notice>}
      {error && <Notice>{error}</Notice>}
      <Field
        label="Email"
        id="email"
        name="email"
        type="email"
        autoComplete="username"
        required
        autoFocus
      />
      <Field
        label="Password"
        id="password"
        name="password"
        type="password"
        autoComplete="current-password"
        required
      />
      <PrimaryAction type="submit" disabled={pending} className="w-full">
        {pending ? "Signing in" : "Sign in"}
      </PrimaryAction>
    </form>
  );
}
