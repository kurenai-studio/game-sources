import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/**/*.test.ts'],
    exclude: ['e2e/**', 'node_modules/**'],
    // The playability probes fly whole campaigns with scripted hands, synchronously, for
    // tens of seconds each. Vitest 2 never noticed how long a synchronous test took; 5.x
    // does, and its 5 s default failed 29 correct tests the day it was adopted.
    testTimeout: 300_000,
  },
});
