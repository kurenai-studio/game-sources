// Adapted from F:\bay-ride\vite.config.ts (Bay Ride): ports 5441 dev / 5440 preview.
import { defineConfig } from "vite";

export default defineConfig({
  base: "./",
  server: { port: 5441, strictPort: true, open: false },
  preview: { port: 5440, strictPort: true, open: false },
  build: {
    target: "es2022",
    sourcemap: false,
    rolldownOptions: {
      output: {
        // three ships as core + WebGL module + addons; separate vendor chunks load in parallel and cache.
        codeSplitting: {
          groups: [
            { name: "three-core", test: /node_modules[\/].*three[\/]build[\/]three\.core/, priority: 2 },
            { name: "three", test: /node_modules[\/].*three[\/]/, priority: 1 },
          ],
        },
      },
    },
  },
});
