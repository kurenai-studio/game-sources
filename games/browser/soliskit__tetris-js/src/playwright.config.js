import { defineConfig } from '@playwright/test';

const PORT = 4173;

export default defineConfig({
  testDir: 'e2e',
  globalSetup: './e2e/global-setup.js',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: 0,
  reporter: process.env.CI ? [['list'], ['github']] : 'list',
  use: {
    baseURL: `http://localhost:${PORT}`
  },
  projects: [
    {
      // The oldest supported device, on Safari's engine.
      name: 'iphone-14-pro-max-webkit',
      use: { browserName: 'webkit', viewport: { width: 430, height: 932 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true }
    },
    {
      // The same phone on Chromium, which also runs the tests that need
      // Chrome only tools (simulated touch and pinch, install checks).
      name: 'iphone-14-pro-max',
      use: { browserName: 'chromium', viewport: { width: 430, height: 932 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true }
    },
    {
      name: 'desktop',
      use: { browserName: 'chromium', viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 }
    }
  ],
  webServer: {
    command: 'node index.js',
    env: { PORT: String(PORT) },
    url: `http://localhost:${PORT}`,
    reuseExistingServer: !process.env.CI
  }
});
