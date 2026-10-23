import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 30000,
  retries: 1,
  use: {
    baseURL: 'http://localhost:3001',
    viewport: { width: 800, height: 600 },
  },
  webServer: {
    command: 'npx vite preview --port 3001',
    port: 3001,
    reuseExistingServer: !process.env.CI,
  },
});
