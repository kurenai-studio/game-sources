import { apiBaseUrl } from "@/lib/api";
import type { ApiErrorBody, ApiTokens, SessionPayload } from "@/lib/api/types";
import { clearRefreshCookie, isSecureCookie, readCookie, refreshCookie } from "./cookie";
import {
  CHANGE_PASSWORD_PATH,
  REFRESH_COOKIE,
  SIGN_IN_PATH,
  safeNext,
  sessionMaxAgeSeconds,
} from "./config";

/**
 * The web app's own server routes for the admin session (a backend for frontend). They keep the
 * refresh token in an httpOnly cookie so JavaScript never sees it, and they hold the only rule
 * the browser must not decide: only ADMIN users get a session here. The API stays the authority
 * on every other rule.
 */

const UPSTREAM_TIMEOUT_MS = 10_000;

/** Auth paths the proxy refuses, because only the session routes may handle refresh tokens. */
const SESSION_ONLY = new Set(["auth/login", "auth/refresh", "auth/logout", "auth/change-password"]);

function problem(status: number, code: string, message: string): Response {
  const body: ApiErrorBody = { statusCode: status, code, message };
  return Response.json(body, { status, headers: { "Cache-Control": "no-store" } });
}

/** The configured public host (from SITE_URL), or null when it is not set. */
function siteHost(): string | null {
  try {
    return process.env.SITE_URL ? new URL(process.env.SITE_URL).host : null;
  } catch {
    return null;
  }
}

/** Unsafe methods must come from this site: the Origin host has to match the site's own host. */
export function isSameOrigin(req: Request): boolean {
  const origin = req.headers.get("origin");
  if (!origin) return false;
  let host: string;
  try {
    host = new URL(origin).host;
  } catch {
    return false;
  }
  // The site's own host: the Host header the platform set for this request, or the configured
  // public address. A forwarded-host header is never trusted: a caller can claim anything there.
  return host === (req.headers.get("host") ?? new URL(req.url).host) || host === siteHost();
}

async function upstream(path: string, init: RequestInit): Promise<Response | null> {
  try {
    return await fetch(`${apiBaseUrl()}/${path}`, {
      ...init,
      cache: "no-store",
      signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
    });
  } catch {
    return null;
  }
}

function jsonInit(body: unknown, authorization?: string | null): RequestInit {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (authorization) headers.Authorization = authorization;
  return { method: "POST", headers, body: JSON.stringify(body) };
}

function isTokens(value: unknown): value is ApiTokens {
  const v = value as Partial<ApiTokens> | null;
  return (
    !!v &&
    typeof v.accessToken === "string" &&
    typeof v.refreshToken === "string" &&
    typeof v.expiresIn === "number" &&
    !!v.user &&
    typeof v.user.email === "string"
  );
}

async function readTokens(res: Response): Promise<ApiTokens | null> {
  try {
    const body: unknown = await res.json();
    return isTokens(body) ? body : null;
  } catch {
    return null;
  }
}

/** A successful session: the JSON without the refresh token, plus the rotated cookie. */
function sessionResponse(tokens: ApiTokens): Response {
  const payload: SessionPayload = {
    accessToken: tokens.accessToken,
    expiresIn: tokens.expiresIn,
    user: tokens.user,
  };
  const res = Response.json(payload, { headers: { "Cache-Control": "no-store" } });
  res.headers.append(
    "Set-Cookie",
    refreshCookie(tokens.refreshToken, sessionMaxAgeSeconds(), isSecureCookie()),
  );
  return res;
}

function withClearedCookie(res: Response): Response {
  res.headers.append("Set-Cookie", clearRefreshCookie(isSecureCookie()));
  return res;
}

function redirect(location: string, setCookie?: string): Response {
  const res = new Response(null, {
    status: 303,
    headers: { Location: location, "Cache-Control": "no-store" },
  });
  if (setCookie) res.headers.append("Set-Cookie", setCookie);
  return res;
}

/** Best effort: tell the API to revoke a refresh token. */
async function revoke(refreshToken: string): Promise<void> {
  await upstream("auth/logout", jsonInit({ refreshToken }));
}

type Credentials = { email: string; password: string; next: string | null };

async function readCredentials(req: Request, isForm: boolean): Promise<Credentials | null> {
  try {
    if (isForm) {
      const form = await req.formData();
      const email = form.get("email");
      const password = form.get("password");
      const next = form.get("next");
      if (typeof email !== "string" || typeof password !== "string") return null;
      return { email, password, next: typeof next === "string" ? next : null };
    }
    const body = (await req.json()) as Partial<Credentials>;
    if (typeof body.email !== "string" || typeof body.password !== "string") return null;
    return { email: body.email, password: body.password, next: null };
  } catch {
    return null;
  }
}

/** POST /admin/api/session/login. JSON for the app, a plain form POST (303) without JavaScript. */
export async function login(req: Request): Promise<Response> {
  const isForm = (req.headers.get("content-type") ?? "").includes(
    "application/x-www-form-urlencoded",
  );
  const fail = (status: number, code: string, message: string, formError: string): Response =>
    isForm ? redirect(`${SIGN_IN_PATH}?error=${formError}`) : problem(status, code, message);

  if (!isSameOrigin(req)) return fail(403, "BAD_ORIGIN", "Request origin not allowed.", "origin");

  const creds = await readCredentials(req, isForm);
  if (!creds || !creds.email || !creds.password) {
    return fail(400, "INVALID_REQUEST", "Email and password are required.", "invalid");
  }

  const res = await upstream(
    "auth/login",
    jsonInit({ email: creds.email, password: creds.password }),
  );
  if (!res)
    return fail(502, "UPSTREAM_UNAVAILABLE", "The API could not be reached.", "unavailable");
  if (res.status === 401 || res.status === 400 || res.status === 422) {
    return fail(401, "INVALID_CREDENTIALS", "Email or password is incorrect.", "invalid");
  }
  if (res.status === 429) {
    return fail(429, "RATE_LIMITED", "Too many attempts. Wait and try again.", "rate");
  }
  if (!res.ok)
    return fail(502, "UPSTREAM_UNAVAILABLE", "The API returned an error.", "unavailable");

  const tokens = await readTokens(res);
  if (!tokens)
    return fail(502, "UPSTREAM_INVALID", "The API response was not understood.", "unavailable");

  if (tokens.user.role !== "ADMIN") {
    await revoke(tokens.refreshToken);
    return fail(403, "NOT_ADMIN", "This account cannot use the dashboard.", "forbidden");
  }

  if (isForm) {
    const target = tokens.user.mustChangePassword ? CHANGE_PASSWORD_PATH : safeNext(creds.next);
    return redirect(
      target,
      refreshCookie(tokens.refreshToken, sessionMaxAgeSeconds(), isSecureCookie()),
    );
  }
  return sessionResponse(tokens);
}

/** POST /admin/api/session/refresh: rotates the cookie and returns a new access token. */
export async function refresh(req: Request): Promise<Response> {
  if (!isSameOrigin(req)) return problem(403, "BAD_ORIGIN", "Request origin not allowed.");
  const token = readCookie(req.headers.get("cookie"), REFRESH_COOKIE);
  if (!token) return problem(401, "NO_SESSION", "There is no session.");

  const res = await upstream("auth/refresh", jsonInit({ refreshToken: token }));
  if (!res) return problem(503, "UPSTREAM_UNAVAILABLE", "The API could not be reached.");
  if (res.status === 401 || res.status === 403) {
    return withClearedCookie(problem(401, "SESSION_REJECTED", "The session is no longer valid."));
  }
  if (!res.ok) return problem(503, "UPSTREAM_UNAVAILABLE", "The API returned an error.");

  const tokens = await readTokens(res);
  if (!tokens) return problem(503, "UPSTREAM_INVALID", "The API response was not understood.");
  if (tokens.user.role !== "ADMIN") {
    await revoke(tokens.refreshToken);
    return withClearedCookie(problem(403, "NOT_ADMIN", "This account cannot use the dashboard."));
  }
  return sessionResponse(tokens);
}

/** POST /admin/api/session/logout: revokes the refresh token and clears the cookie. */
export async function logout(req: Request): Promise<Response> {
  if (!isSameOrigin(req)) return problem(403, "BAD_ORIGIN", "Request origin not allowed.");
  const token = readCookie(req.headers.get("cookie"), REFRESH_COOKIE);
  if (token) await revoke(token);
  const isForm = (req.headers.get("content-type") ?? "").includes(
    "application/x-www-form-urlencoded",
  );
  if (isForm) return redirect(SIGN_IN_PATH, clearRefreshCookie(isSecureCookie()));
  return withClearedCookie(
    new Response(null, { status: 204, headers: { "Cache-Control": "no-store" } }),
  );
}

/** POST /admin/api/session/change-password: forwards the bearer token and takes the new session. */
export async function changePassword(req: Request): Promise<Response> {
  if (!isSameOrigin(req)) return problem(403, "BAD_ORIGIN", "Request origin not allowed.");
  const authorization = req.headers.get("authorization");
  if (!authorization) return problem(401, "UNAUTHORIZED", "Sign in again.");
  let body: { currentPassword?: unknown; newPassword?: unknown };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return problem(400, "INVALID_REQUEST", "The request body must be JSON.");
  }
  if (typeof body.currentPassword !== "string" || typeof body.newPassword !== "string") {
    return problem(400, "INVALID_REQUEST", "Current and new password are required.");
  }
  const res = await upstream(
    "auth/change-password",
    jsonInit(
      { currentPassword: body.currentPassword, newPassword: body.newPassword },
      authorization,
    ),
  );
  if (!res) return problem(502, "UPSTREAM_UNAVAILABLE", "The API could not be reached.");
  if (!res.ok) return passThrough(res);
  const tokens = await readTokens(res);
  if (!tokens) return problem(502, "UPSTREAM_INVALID", "The API response was not understood.");
  if (tokens.user.role !== "ADMIN") {
    await revoke(tokens.refreshToken);
    return withClearedCookie(problem(403, "NOT_ADMIN", "This account cannot use the dashboard."));
  }
  return sessionResponse(tokens);
}

const FORWARDED_REQUEST_HEADERS = [
  "authorization",
  "content-type",
  "accept",
  "if-match",
  "if-none-match",
];
const FORWARDED_RESPONSE_HEADERS = ["content-type", "etag", "content-disposition", "retry-after"];

function passThrough(res: Response): Response {
  const headers = new Headers({ "Cache-Control": "no-store" });
  for (const name of FORWARDED_RESPONSE_HEADERS) {
    const value = res.headers.get(name);
    if (value) headers.set(name, value);
  }
  const noBody = res.status === 204 || res.status === 205 || res.status === 304;
  return new Response(noBody ? null : res.body, { status: res.status, headers });
}

/** Forwards a call to the API with the browser's bearer token. Never forwards or sets cookies. */
export async function proxy(req: Request, segments: string[]): Promise<Response> {
  const path = segments.map(encodeURIComponent).join("/");
  if (
    segments.length === 0 ||
    segments.some((s) => s === "" || s === "." || s === ".." || s.includes("\\")) ||
    SESSION_ONLY.has(path)
  ) {
    return problem(404, "NOT_FOUND", "Not found.");
  }
  const safe = req.method === "GET" || req.method === "HEAD";
  if (!safe && !isSameOrigin(req)) return problem(403, "BAD_ORIGIN", "Request origin not allowed.");

  const headers = new Headers();
  for (const name of FORWARDED_REQUEST_HEADERS) {
    const value = req.headers.get(name);
    if (value) headers.set(name, value);
  }
  const search = new URL(req.url).search;
  const init: RequestInit = { method: req.method, headers };
  if (!safe) init.body = await req.arrayBuffer();
  const res = await upstream(`${path}${search}`, init);
  if (!res) return problem(502, "UPSTREAM_UNAVAILABLE", "The API could not be reached.");
  return passThrough(res);
}
