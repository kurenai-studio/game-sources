import { defineConfig } from 'vite';

export default defineConfig({
  server: { port: 8910, strictPort: true, host: '127.0.0.1' },
  build: { target: 'esnext', sourcemap: true },
  optimizeDeps: { include: ['three'] },
});
