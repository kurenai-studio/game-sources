import { defineConfig } from 'vite';

export default defineConfig({
  // Use relative paths so built assets work with file:// protocol in Electron
  base: './',
  server: {
    port: 5173,
    strictPort: true
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
});
