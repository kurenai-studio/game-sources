import type { Metadata, MetadataRoute, Viewport } from "next";
import type { Release } from "@/lib/releases";
import { siteUrl } from "@/lib/site";
import { TOKEN_COLORS } from "@/lib/token-colors.generated";

export const SITE_NAME = "Algomind";
export const SITE_DESCRIPTION =
  "A programming puzzle for Android. Offline first. No ads. No purchases.";

/** The public pages, in sitemap order. /admin is intentionally absent (it is noindex). */
export const PUBLIC_PATHS = [
  "/",
  "/levels",
  "/download",
  "/how-to-play",
  "/play",
  "/privacy",
  "/contact",
] as const;

/** Light and dark browser chrome colors, from the design tokens. */
export const VIEWPORT: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: TOKEN_COLORS.light.ground },
    { media: "(prefers-color-scheme: dark)", color: TOKEN_COLORS.dark.ground },
  ],
};

type PageMetadataInput = {
  /** The page title; the root layout's template adds " · Algomind". */
  title: string;
  /** Use the title as is, without the template. */
  absoluteTitle?: boolean;
  description: string;
  /** Path of the page, starting with "/". Becomes the canonical URL. */
  path: string;
  /** Title for social previews when it should differ from the page title. */
  shareTitle?: string;
};

/**
 * Metadata for one public page: title, description, canonical URL, Open Graph and Twitter tags.
 * A page's openGraph replaces the layout's wholesale, so the shared fields are repeated here.
 * The share image comes from the opengraph-image / twitter-image files in the route segment.
 */
export function pageMetadata(input: PageMetadataInput): Metadata {
  const shareTitle = input.shareTitle ?? input.title;
  return {
    title: input.absoluteTitle ? { absolute: input.title } : input.title,
    description: input.description,
    alternates: { canonical: input.path },
    openGraph: {
      type: "website",
      siteName: SITE_NAME,
      locale: "en",
      title: shareTitle,
      description: input.description,
      url: input.path,
    },
    twitter: { card: "summary_large_image", title: shareTitle, description: input.description },
  };
}

/** Absolute URL of a path on the site. */
export function absoluteUrl(path: string): string {
  return path === "/" ? `${siteUrl()}/` : `${siteUrl()}${path}`;
}

/**
 * Serialises JSON-LD for an inline script. "<" is escaped so the data can never close the
 * script element.
 */
export function jsonLdString(data: unknown): string {
  return JSON.stringify(data).replace(/</g, "\\u003c");
}

export function websiteJsonLd() {
  return {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: SITE_NAME,
    url: absoluteUrl("/"),
    description: SITE_DESCRIPTION,
    inLanguage: "en",
  };
}

/**
 * The Android app. Only facts that are true: free, Android, downloaded from the download page.
 * The version and dates are included only when a published release provides them. There are no
 * ratings or reviews because there are none.
 */
export function mobileApplicationJsonLd(release?: Pick<Release, "version" | "publishedAt">) {
  return {
    "@context": "https://schema.org",
    "@type": "MobileApplication",
    name: SITE_NAME,
    description: SITE_DESCRIPTION,
    url: absoluteUrl("/"),
    applicationCategory: "GameApplication",
    genre: "Puzzle",
    operatingSystem: "ANDROID",
    inLanguage: "en",
    downloadUrl: absoluteUrl("/download"),
    offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
    ...(release
      ? {
          softwareVersion: release.version,
          ...(release.publishedAt ? { datePublished: release.publishedAt } : {}),
        }
      : {}),
  };
}

/**
 * Sitemap entries are absolute URLs. The sitemap is built when the site is deployed and every
 * deploy rebuilds the pages, so lastModified is the build time.
 */
export function sitemapEntries(lastModified: Date): MetadataRoute.Sitemap {
  return PUBLIC_PATHS.map((path) => ({ url: absoluteUrl(path), lastModified }));
}
