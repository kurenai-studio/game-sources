import { defineConfig } from "vite";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  // Capacitor loads the bundle from a local file:// path, so assets must be
  // referenced relatively rather than from the server root.
  base: "./",
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  build: {
    outDir: "dist",
    assetsInlineLimit: 0, // keep sprite/JSON files as real files Phaser can fetch
  },
  server: {
    host: true, // expose on LAN so you can test on a phone's browser
    port: 5173,
  },
});
