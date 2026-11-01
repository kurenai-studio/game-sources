import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.test.ts'],
    coverage: {
      provider: 'istanbul',
      include: [
        'src/main.ts',
        'src/config/*.ts',
        'src/entities/*.ts',
        'src/scenes/*.ts',
        'src/utils/*.ts',
      ],
      exclude: ['src/**/*.test.ts'],
      reporter: ['text'],
    },
  },
});
