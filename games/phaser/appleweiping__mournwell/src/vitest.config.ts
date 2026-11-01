import { defineConfig } from 'vitest/config';
import { fileURLToPath, URL } from 'node:url';

export default defineConfig({
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  test: {
    environment: 'node',
    exclude: ['e2e/**', 'node_modules/**', 'dist/**'],
    testTimeout: 15_000,
    coverage: {
      reporter: ['text', 'json-summary'],
    },
  },
});
