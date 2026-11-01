import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));

// Plain JS on purpose: Next 16.2.11+ supports TypeScript 7, and the config stays trivial.
// `standalone` output keeps the Docker image small; the tracing root is the monorepo root
// so workspace packages are included.
/** @type {import("next").NextConfig} */
const nextConfig = {
  output: "standalone",
  outputFileTracingRoot: join(here, "..", ".."),
  poweredByHeader: false,
  async headers() {
    // No third-party resource is loaded anywhere, so these cost nothing. A strict
    // Content-Security-Policy needs per-request nonces for the inline theme script (a follow-up).
    const everywhere = [
      { key: "X-Content-Type-Options", value: "nosniff" },
      { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
      { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
    ];
    return [
      { source: "/:path*", headers: everywhere },
      {
        // The dashboard is never framed.
        source: "/admin/:path*",
        headers: [
          { key: "Content-Security-Policy", value: "frame-ancestors 'none'" },
          { key: "X-Frame-Options", value: "DENY" },
        ],
      },
    ];
  },
};

export default nextConfig;
