import { ApiError, NetworkError, readApiError, SessionEndedError } from "./errors";

/** Sends an authenticated request through the session (see lib/admin/session-manager.ts). */
export type Requester = (path: string, init?: RequestInit) => Promise<Response>;

/**
 * A small typed JSON client over a Requester. Later dashboard screens add their own typed
 * functions on top of it; the session (bearer token, one refresh and retry on 401) is the
 * Requester's job, not this client's.
 */
export function createApiClient(request: Requester) {
  async function call<T>(method: string, path: string, body?: unknown): Promise<T> {
    const headers: Record<string, string> = { Accept: "application/json" };
    const init: RequestInit = { method, headers };
    if (body !== undefined) {
      init.body = JSON.stringify(body);
      headers["Content-Type"] = "application/json";
    }
    let res: Response;
    try {
      res = await request(path, init);
    } catch (err) {
      if (err instanceof SessionEndedError || err instanceof NetworkError) throw err;
      throw new NetworkError();
    }
    if (!res.ok) throw await readApiError(res);
    if (res.status === 204) return undefined as T;
    return (await res.json()) as T;
  }

  return {
    get: <T>(path: string) => call<T>("GET", path),
    post: <T>(path: string, body?: unknown) => call<T>("POST", path, body),
    put: <T>(path: string, body?: unknown) => call<T>("PUT", path, body),
    patch: <T>(path: string, body?: unknown) => call<T>("PATCH", path, body),
    delete: <T>(path: string, body?: unknown) => call<T>("DELETE", path, body),
  };
}

export type ApiClient = ReturnType<typeof createApiClient>;

export type Readiness = "ready" | "database-down" | "unreachable";

/** Reads API readiness through the session. Throws only when the session ended or access is forbidden. */
export async function readReadiness(request: Requester): Promise<Readiness> {
  let res: Response;
  try {
    res = await request("health/ready", { method: "GET" });
  } catch (err) {
    if (err instanceof SessionEndedError) throw err;
    return "unreachable";
  }
  if (res.ok) return "ready";
  if (res.status === 503) return "database-down";
  if (res.status === 403) throw new ApiError(403, "FORBIDDEN", "Forbidden.");
  return "unreachable";
}
