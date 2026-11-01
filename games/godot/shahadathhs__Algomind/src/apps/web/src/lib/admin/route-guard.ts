import { ADMIN_PATH, SIGN_IN_PATH } from "./config";

/**
 * Decides whether a request under /admin is sent to sign-in. This is a convenience only: it
 * checks that a refresh cookie exists, not that it is valid. The API authorizes every call.
 * Returns the redirect target, or null to let the request through.
 */
export function guardRedirect(pathname: string, hasRefreshCookie: boolean): string | null {
  if (hasRefreshCookie) return null;
  if (pathname === SIGN_IN_PATH || pathname.startsWith(`${SIGN_IN_PATH}/`)) return null;
  if (pathname.startsWith(`${ADMIN_PATH}/api/`)) return null;
  const next =
    pathname === ADMIN_PATH || pathname === `${ADMIN_PATH}/`
      ? ""
      : `?next=${encodeURIComponent(pathname)}`;
  return `${SIGN_IN_PATH}${next}`;
}
