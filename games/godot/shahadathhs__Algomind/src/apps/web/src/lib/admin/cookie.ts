import { ADMIN_PATH, REFRESH_COOKIE } from "./config";

/** Reads one cookie from a Cookie header. */
export function readCookie(header: string | null, name: string): string | null {
  if (!header) return null;
  for (const part of header.split(";")) {
    const i = part.indexOf("=");
    if (i < 0) continue;
    if (part.slice(0, i).trim() === name) {
      try {
        return decodeURIComponent(part.slice(i + 1).trim());
      } catch {
        return null;
      }
    }
  }
  return null;
}

/** The Set-Cookie value for the refresh token: httpOnly, SameSite=Strict, Path=/admin. */
export function refreshCookie(token: string, maxAgeSeconds: number, secure: boolean): string {
  return [
    `${REFRESH_COOKIE}=${encodeURIComponent(token)}`,
    `Path=${ADMIN_PATH}`,
    `Max-Age=${maxAgeSeconds}`,
    "HttpOnly",
    "SameSite=Strict",
    ...(secure ? ["Secure"] : []),
  ].join("; ");
}

/** Expires the refresh cookie. */
export function clearRefreshCookie(secure: boolean): string {
  return refreshCookie("", 0, secure);
}

/**
 * Whether the refresh cookie carries `Secure`. Set SECURE_COOKIES=true or false to decide
 * explicitly (false only for a production build served over plain http on localhost). Otherwise it
 * is on in production and whenever SITE_URL is https, so a missing NODE_ENV cannot turn it off.
 */
export function isSecureCookie(): boolean {
  const explicit = process.env.SECURE_COOKIES;
  if (explicit === "true") return true;
  if (explicit === "false") return false;
  return (
    process.env.NODE_ENV === "production" || process.env.SITE_URL?.startsWith("https:") === true
  );
}
