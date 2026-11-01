/** The only cookie the site sets: the admin refresh token, httpOnly, under /admin only. */
export const REFRESH_COOKIE = "algomind_admin_refresh";
export const ADMIN_PATH = "/admin";
export const SIGN_IN_PATH = "/admin/sign-in";
export const CHANGE_PASSWORD_PATH = "/admin/change-password";

function positiveInt(value: string | undefined, fallback: number): number {
  const n = Number(value);
  return Number.isInteger(n) && n > 0 ? n : fallback;
}

/** Cookie lifetime; ADMIN_SESSION_MAX_AGE_SECONDS, default 7 days. */
export function sessionMaxAgeSeconds(): number {
  return positiveInt(process.env.ADMIN_SESSION_MAX_AGE_SECONDS, 7 * 24 * 60 * 60);
}

/** Inactivity timeout in minutes; ADMIN_INACTIVITY_MINUTES, default 30. */
export function inactivityMinutes(): number {
  return positiveInt(process.env.ADMIN_INACTIVITY_MINUTES, 30);
}

/** Only same-site /admin pages are valid sign-in redirect targets. */
export function safeNext(value: string | null | undefined): string {
  if (
    !value ||
    !value.startsWith("/admin") ||
    value.startsWith("//") ||
    value.includes("\\") ||
    value.includes("..")
  ) {
    return ADMIN_PATH;
  }
  if (value.startsWith("/admin/api") || value.startsWith(SIGN_IN_PATH)) return ADMIN_PATH;
  if (value !== ADMIN_PATH && !value.startsWith("/admin/") && !value.startsWith("/admin?")) {
    return ADMIN_PATH;
  }
  return value;
}
