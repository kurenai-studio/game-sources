import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import { SITE_DESCRIPTION, VIEWPORT } from "@/lib/seo";
import { siteUrl } from "@/lib/site";
import { THEME_INIT_SCRIPT } from "@/lib/theme";
import "./globals.css";

const DESCRIPTION = SITE_DESCRIPTION;

export const viewport: Viewport = VIEWPORT;

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl()),
  title: { default: "Algomind", template: "%s · Algomind" },
  description: DESCRIPTION,
  openGraph: {
    type: "website",
    siteName: "Algomind",
    title: "Algomind",
    description: DESCRIPTION,
    locale: "en",
  },
  twitter: { card: "summary_large_image", title: "Algomind", description: DESCRIPTION },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    // suppressHydrationWarning: the script below may set data-theme before React hydrates.
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_INIT_SCRIPT }} />
        {/* Without JavaScript nothing can slide in, so a section marked .reveal must simply be there. */}
        <noscript>
          <style>{".reveal{opacity:1!important;transform:none!important}"}</style>
        </noscript>
      </head>
      {/* suppressHydrationWarning: browser extensions (ColorZilla, Grammarly and others) add
          attributes to <body> before React hydrates; that is not a mismatch in our markup. */}
      <body className="min-h-screen bg-ground text-ink" suppressHydrationWarning>
        {children}
      </body>
    </html>
  );
}
