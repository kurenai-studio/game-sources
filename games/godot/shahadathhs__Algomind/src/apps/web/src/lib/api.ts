const DEFAULT_API_BASE_URL = "http://localhost:8000/v1";

/** Server-side API base URL (never exposed to the browser). */
export function apiBaseUrl(): string {
  return (process.env.API_BASE_URL ?? DEFAULT_API_BASE_URL).replace(/\/$/, "");
}
