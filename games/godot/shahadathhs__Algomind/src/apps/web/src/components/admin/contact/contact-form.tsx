"use client";

import { useState, type FormEvent } from "react";
import {
  CONTACT_LIMITS,
  contactProblems,
  type ContactField,
  type ContactProblems,
} from "@/lib/admin/contact-form";
import type { AdminContact, ContactInput } from "@/lib/admin/social-api";
import { Field, OutlineAction, PrimaryAction } from "../ui";

const FIELDS: { name: ContactField; label: string; type?: string; hint?: string }[] = [
  { name: "displayName", label: "Name" },
  { name: "email", label: "Email", type: "email", hint: "Leave empty to publish no address." },
  { name: "github", label: "GitHub", type: "url", hint: "A link that starts with https://." },
  { name: "website", label: "Website", type: "url", hint: "A link that starts with https://." },
  {
    name: "issues",
    label: "Issues page",
    type: "url",
    hint: "Where people report problems. Leave empty to use the project's GitHub issues.",
  },
  { name: "note", label: "Note", hint: "One short line shown under the details." },
];

function pick(c: AdminContact): ContactInput {
  const { displayName, email, github, website, issues, note } = c;
  return { displayName, email, github, website, issues, note };
}

/** The contact fields with counters, local checks that mirror the API, and the API's field errors. */
export function ContactForm({
  saved,
  busy,
  serverProblems,
  onSave,
}: {
  saved: AdminContact;
  busy: boolean;
  /** Field messages from the API's last refusal. */
  serverProblems: ContactProblems;
  onSave: (input: ContactInput) => Promise<boolean>;
}) {
  const [values, setValues] = useState<ContactInput>(pick(saved));
  const [problems, setProblems] = useState<ContactProblems>({});

  async function submit(e: FormEvent) {
    e.preventDefault();
    const trimmed = Object.fromEntries(
      Object.entries(values).map(([k, v]) => [k, v.trim()]),
    ) as ContactInput;
    const local = contactProblems(trimmed);
    setProblems(local);
    if (Object.keys(local).length > 0) return;
    await onSave(trimmed);
  }

  return (
    <form
      onSubmit={(e) => void submit(e)}
      aria-label="Contact details"
      noValidate
      className="grid max-w-[560px] gap-5"
    >
      {FIELDS.map((f) => {
        const value = values[f.name];
        const limit = CONTACT_LIMITS[f.name];
        const problem = problems[f.name] ?? serverProblems[f.name];
        return (
          <div key={f.name}>
            <Field
              label={f.label}
              id={`contact-${f.name}`}
              type={f.type ?? "text"}
              value={value}
              aria-invalid={problem ? true : undefined}
              onChange={(e) => setValues({ ...values, [f.name]: e.target.value })}
              hint={`${f.hint ? `${f.hint} ` : ""}${value.length} of ${limit} characters.`}
            />
            {problem && (
              <p role="alert" className="mt-2 text-sm font-semibold">
                <span className="mr-2 text-xs tracking-[2px] uppercase">Error</span>
                {problem}
              </p>
            )}
          </div>
        );
      })}
      <div className="flex flex-wrap items-center gap-4">
        <PrimaryAction type="submit" disabled={busy}>
          Save
        </PrimaryAction>
        <OutlineAction
          type="button"
          disabled={busy}
          onClick={() => {
            setValues(pick(saved));
            setProblems({});
          }}
        >
          Reset
        </OutlineAction>
      </div>
    </form>
  );
}
