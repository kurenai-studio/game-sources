import { ApiError } from "@/lib/api/errors";

/** Messages for failures reported by the plain form POST (`?error=`). */
export const SIGN_IN_ERRORS: Record<string, string> = {
  invalid: "Email or password is incorrect.",
  forbidden: "This account cannot use the dashboard.",
  rate: "Too many attempts. Wait a minute and try again.",
  unavailable: "The API could not be reached. Try again shortly.",
  origin: "The request was blocked. Reload the page and try again.",
};

/** Messages for why a session ended (`?reason=`). */
export const END_NOTES: Record<string, string> = {
  inactive: "Signed out after a period of inactivity.",
  expired: "The session expired. Sign in again.",
  elsewhere: "Signed out in another tab.",
  "signed-out": "Signed out.",
};

/** What the dashboard says for an API error code, where the server's own message is not enough. */
const API_MESSAGES: Record<string, string> = {
  NOT_EMPTY: "It still contains items. Move them out first.",
  DRAFT_EXISTS: "A draft already exists. Open it or discard it first.",
  SLUG_TAKEN: "That slug is taken.",
};

/** One sentence for any failure of an admin API call: the API's reason, or the connection. */
export function apiMessage(err: unknown): string {
  if (!(err instanceof ApiError)) return "The server could not be reached.";
  return API_MESSAGES[err.code] ?? err.message;
}
