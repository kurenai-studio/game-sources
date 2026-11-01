import type { Metadata } from "next";
import type { ReactNode } from "react";
import { SessionProvider } from "@/components/admin/session-provider";
import { inactivityMinutes } from "@/lib/admin/config";

// The dashboard is never indexed or statically cached; the inactivity timeout is read at request
// time so changing ADMIN_INACTIVITY_MINUTES needs no rebuild.
export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Admin",
  robots: { index: false, follow: false },
};

export default function AdminLayout({ children }: { children: ReactNode }) {
  return <SessionProvider inactivityMinutes={inactivityMinutes()}>{children}</SessionProvider>;
}
