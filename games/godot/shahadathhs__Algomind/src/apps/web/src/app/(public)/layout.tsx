import type { ReactNode } from "react";
import { NavProgress } from "@/components/public/nav-progress";
import { SiteFooter } from "@/components/public/site-footer";
import { SiteHeader } from "@/components/public/site-header";

export default function PublicLayout({ children }: { children: ReactNode }) {
  return (
    <div className="look-depth">
      {/* First focusable element: keyboard users skip the header. Visible only while focused. */}
      <a
        href="#main"
        className="tile fixed top-3 left-3 z-50 -translate-y-[200%] bg-ink px-4 py-3 text-sm tracking-[2px] text-on-ink uppercase focus:translate-y-0"
        style={{ ["--chamfer" as string]: "8px" }}
      >
        Skip to content
      </a>
      <NavProgress />
      <div className="scroll-progress" aria-hidden="true" />
      <SiteHeader />
      <main id="main" tabIndex={-1} className="outline-none">
        {children}
      </main>
      <SiteFooter />
    </div>
  );
}
