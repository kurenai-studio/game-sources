import { defineConfig } from 'vite';

// No 'three' -> 'three/webgpu' alias: both builds share three.core.js since r170.
// Relative base so the build runs under any path, such as GitHub Pages at /crimsonland/.
export default defineConfig({
  base: './',
  build: { target: 'es2022', chunkSizeWarningLimit: 1600 },
});
