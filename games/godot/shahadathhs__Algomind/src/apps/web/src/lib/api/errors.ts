import type { ApiErrorBody } from "./types";

/** The API (or the web app's session routes) answered with an error. */
export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly issues?: unknown;

  constructor(status: number, code: string, message: string, issues?: unknown) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    this.issues = issues;
  }
}

/** The request never got an answer (offline, DNS, timeout). */
export class NetworkError extends Error {
  constructor(message = "The server could not be reached.") {
    super(message);
    this.name = "NetworkError";
  }
}

/** The session ended (rejected refresh, inactivity, sign-out elsewhere) while a call was running. */
export class SessionEndedError extends Error {
  constructor(message = "The session has ended.") {
    super(message);
    this.name = "SessionEndedError";
  }
}

/** Turns a failed response into an ApiError, tolerating bodies that are not the error contract. */
export async function readApiError(res: Response): Promise<ApiError> {
  let body: Partial<ApiErrorBody> = {};
  try {
    body = (await res.json()) as Partial<ApiErrorBody>;
  } catch {
    // Not JSON; fall back to the status line.
  }
  return new ApiError(
    res.status,
    typeof body.code === "string" ? body.code : "UNKNOWN",
    typeof body.message === "string" ? body.message : `Request failed (${res.status}).`,
    body.issues,
  );
}
