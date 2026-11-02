import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    clearMocks: true,
    exclude: ['**/node_modules/**', '**/dist/**'],
    projects: [
      {
        test: {
          name: 'libs',
          include: ['libs/**/src/**/*.test.ts'],
        },
      },
      {
        test: {
          name: 'cli',
          include: ['apps/cli/src/**/*.test.{ts,tsx}'],
          setupFiles: ['apps/cli/setupTests.ts'],
        },
      },
    ],
    coverage: {
      include: ['libs/**/src/**/*.ts', 'apps/**/src/**/*.{ts,tsx}'],
      exclude: ['libs/warriorjs-tower-**/src/**', '**/*.test.{ts,tsx}'],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});
