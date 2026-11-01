import { getJson } from "@/lib/campaign";

/** The public contact details, set by an admin in the dashboard and read from `GET /v1/contact`. */
export type ContactDetails = {
  displayName: string;
  email: string;
  github: string;
  website: string;
  issues: string;
  note: string;
};

export type ContactState =
  { status: "available"; details: ContactDetails } | { status: "unavailable" };

/** Where to report a problem when the API cannot be reached. */
export const ISSUES_URL = "https://github.com/shahadathhs/Algomind/issues";

function text(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

/** Keeps only http(s) links, so a bad value in the data never becomes a script link. */
export function safeUrl(value: string): string {
  return /^https?:\/\//i.test(value) ? value : "";
}

/** Reads the contact details, or says the API is unavailable. Cached for a minute like the campaign. */
export async function getContact(): Promise<ContactState> {
  try {
    const body = await getJson("/contact");
    if (typeof body !== "object" || body === null) return { status: "unavailable" };
    const b = body as Record<string, unknown>;
    return {
      status: "available",
      details: {
        displayName: text(b.displayName),
        email: text(b.email),
        github: safeUrl(text(b.github)),
        website: safeUrl(text(b.website)),
        issues: safeUrl(text(b.issues)),
        note: text(b.note),
      },
    };
  } catch {
    return { status: "unavailable" };
  }
}
