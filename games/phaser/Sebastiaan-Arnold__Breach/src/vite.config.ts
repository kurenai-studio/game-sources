import { defineConfig } from 'vite';
import { version } from './package.json';

export default defineConfig({
  // Relative base so the build works on GitHub Pages under /<repo>/ as well as locally.
  base: './',
  define: {
    __APP_VERSION__: JSON.stringify(version),
  },
  build: {
    target: 'es2022',
    chunkSizeWarningLimit: 2000,
  },
});
