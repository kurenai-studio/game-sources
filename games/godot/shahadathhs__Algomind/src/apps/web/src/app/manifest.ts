import type { MetadataRoute } from "next";
import { TOKEN_COLORS } from "@/lib/token-colors.generated";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Algomind",
    short_name: "Algomind",
    description: "A programming puzzle for Android. Offline first. No ads. No purchases.",
    start_url: "/",
    scope: "/",
    display: "browser",
    background_color: TOKEN_COLORS.light.ground,
    theme_color: TOKEN_COLORS.light.ground,
    icons: [
      { src: "/pwa-icon/192", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/pwa-icon/512", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "/pwa-icon/maskable-192", sizes: "192x192", type: "image/png", purpose: "maskable" },
      { src: "/pwa-icon/maskable-512", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
}
