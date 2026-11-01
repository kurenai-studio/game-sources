import { NextResponse, type NextRequest } from "next/server";
import { REFRESH_COOKIE } from "@/lib/admin/config";
import { guardRedirect } from "@/lib/admin/route-guard";

// Sends visitors without an admin session cookie to sign-in. User experience only: the API
// authorizes every call, and the page itself checks the session again in the browser.
export function proxy(request: NextRequest) {
  const target = guardRedirect(request.nextUrl.pathname, request.cookies.has(REFRESH_COOKIE));
  if (target) return NextResponse.redirect(new URL(target, request.url));
  return NextResponse.next();
}

export const config = {
  matcher: ["/admin", "/admin/:path*"],
};
