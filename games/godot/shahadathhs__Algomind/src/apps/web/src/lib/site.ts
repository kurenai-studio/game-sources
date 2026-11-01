const DEFAULT_SITE_URL = "https://playalgomind.vercel.app";

/**
 * The public origin of the site, used for absolute URLs (sitemap, robots, metadata).
 * Set SITE_URL on the host (for example when a custom domain is added); it is read at build time.
 */
export function siteUrl(): string {
  return (process.env.SITE_URL ?? DEFAULT_SITE_URL).replace(/\/$/, "");
}
