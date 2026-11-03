import { defineConfig } from 'vitest/config';

// Slowblue: separate runner for the tuning sweeps. They take minutes, so they must
// never be part of `npm test` - but they are a permanent tool, not scratch work.
export default defineConfig({
  test: {
    environment: 'node',
    include: ['tools/**/*.sweep.ts'],
    testTimeout: 900_000,
  },
});
