import type { ContactInput } from "./social-api";

export const CONTACT_LIMITS = {
  displayName: 80,
  email: 120,
  github: 200,
  website: 200,
  issues: 200,
  note: 280,
} as const;

export type ContactField = keyof ContactInput;
export type ContactProblems = Partial<Record<ContactField, string>>;

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function httpsProblem(value: string): string | undefined {
  if (value === "") return undefined;
  try {
    return new URL(value).protocol === "https:"
      ? undefined
      : "Use a link that starts with https://.";
  } catch {
    return "Use a full link that starts with https://.";
  }
}

/** The same rules the API applies, so most mistakes are caught before the request. */
export function contactProblems(v: ContactInput): ContactProblems {
  const out: ContactProblems = {};
  if (v.displayName.trim() === "") out.displayName = "A name is required.";
  if (v.email !== "" && !EMAIL.test(v.email))
    out.email = "Enter a valid email address, or leave it empty.";
  const github = httpsProblem(v.github);
  if (github) out.github = github;
  const website = httpsProblem(v.website);
  if (website) out.website = website;
  for (const f of Object.keys(CONTACT_LIMITS) as ContactField[]) {
    if (v[f].length > CONTACT_LIMITS[f]) out[f] = `At most ${CONTACT_LIMITS[f]} characters.`;
  }
  return out;
}

/** Field messages from the API's 422 issues (`path` is the field name). */
export function issueProblems(issues: unknown): ContactProblems {
  const out: ContactProblems = {};
  if (!Array.isArray(issues)) return out;
  for (const i of issues as { path?: unknown; message?: unknown }[]) {
    if (typeof i.path === "string" && i.path in CONTACT_LIMITS && typeof i.message === "string") {
      out[i.path as ContactField] ??= i.message;
    }
  }
  return out;
}
