import { defineConfig } from "@playwright/test";

const publicURL = process.env.PLAYWRIGHT_BASE_URL;

export default defineConfig({
  // Real drive animations, full keyboard solutions and individual undo presses.
  timeout: 180_000,
  testDir: "./tests",
  testMatch: "browser.spec.ts",
  workers: 1,
  reporter: "list",
  use: {
    baseURL: publicURL ?? "http://127.0.0.1:4174",
    viewport: { width: 1440, height: 1100 },
    headless: true,
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
    launchOptions: process.env.PLAYWRIGHT_EXECUTABLE_PATH
      ? { executablePath: process.env.PLAYWRIGHT_EXECUTABLE_PATH }
      : {},
  },
  webServer: publicURL ? undefined : {
    command: "npm run dev -- --port 4174 --strictPort",
    url: "http://127.0.0.1:4174",
    reuseExistingServer: false,
  },
});
