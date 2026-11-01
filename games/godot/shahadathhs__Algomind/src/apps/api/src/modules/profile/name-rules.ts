/** Rules for a display name shown to other players. Pure: no database. */

const PATTERN = /^[A-Za-z0-9][A-Za-z0-9 _-]{1,18}[A-Za-z0-9]$/;

/** Words that impersonate the game or its staff, refused outright. */
const RESERVED = [
  "admin",
  "administrator",
  "algomind",
  "moderator",
  "mod",
  "staff",
  "support",
  "system",
];

/**
 * A short list of obvious abuse. It is a first line of defence, not a filter that can catch
 * everything: players can report a name and an admin can clear or hide it.
 */
const BLOCKED = [
  "fuck",
  "shit",
  "bitch",
  "cunt",
  "dick",
  "cock",
  "pussy",
  "nigger",
  "nigga",
  "faggot",
  "retard",
  "whore",
  "slut",
  "rape",
  "nazi",
  "hitler",
];

const LEET: Record<string, string> = { "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t" };

/** The name as the unique check sees it: trimmed, spaces collapsed, lowercased. */
export function nameKey(name: string): string {
  return name.trim().replace(/\s+/g, " ").toLowerCase();
}

/** The name with look-alike digits swapped for letters and separators removed, for the word lists. */
function squashed(name: string): string {
  return nameKey(name)
    .replace(/[0-9]/g, (d) => LEET[d] ?? d)
    .replace(/[^a-z]/g, "");
}

export type NameCheck =
  | { ok: true; name: string }
  | { ok: false; code: "NAME_INVALID" | "NAME_NOT_ALLOWED"; message: string };

export function checkDisplayName(input: string): NameCheck {
  const name = input.trim().replace(/\s+/g, " ");
  if (!PATTERN.test(name)) {
    return {
      ok: false,
      code: "NAME_INVALID",
      message: "Use 3 to 20 letters, digits, spaces, dashes or underscores.",
    };
  }
  if (/^[0-9 _-]+$/.test(name)) {
    return { ok: false, code: "NAME_INVALID", message: "A name needs at least one letter." };
  }
  const flat = squashed(name);
  const reserved = RESERVED.some((word) => flat === word || flat.startsWith(`${word}x`));
  if (reserved || BLOCKED.some((word) => flat.includes(word))) {
    return { ok: false, code: "NAME_NOT_ALLOWED", message: "That name is not allowed." };
  }
  return { ok: true, name };
}
