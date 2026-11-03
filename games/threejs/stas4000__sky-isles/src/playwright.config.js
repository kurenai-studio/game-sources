import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './test',
  testMatch: /.*\.e2e\.js/,
  timeout: 60_000,
  workers: 2,
  retries: 2,
  expect: { timeout: 10_000 },
  fullyParallel: false,
  use: {
    baseURL: 'http://127.0.0.1:4185',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure'
  },
  projects: [
    { name: 'desktop', use: { ...devices['Desktop Chrome'], viewport: { width: 1440, height: 900 } } },
    { name: 'mobile', use: { ...devices['iPhone 15 Pro Max'], browserName: 'chromium' } }
  ],
  webServer: {
    command: 'npm run dev -- --port 4185 --strictPort',
    url: 'http://127.0.0.1:4185',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000
  }
});
