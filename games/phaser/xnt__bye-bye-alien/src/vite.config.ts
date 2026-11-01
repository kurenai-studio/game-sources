import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  base: process.env.GITHUB_ACTIONS ? '/bye-bye-alien/' : '/',
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  build: {
    target: 'ES2020',
    outDir: 'dist',
  },
  server: {
    port: 3000,
    open: true,
  },
});
