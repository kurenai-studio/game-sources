import { defineConfig } from 'vite';
import { readFileSync } from 'node:fs';
import { fileURLToPath, URL } from 'node:url';

const packageMetadata = JSON.parse(
  // eslint-disable-next-line security/detect-non-literal-fs-filename -- fixed repository URL, not user input
  readFileSync(fileURLToPath(new URL('./package.json', import.meta.url)), 'utf8'),
) as {
  version: string;
};
// eslint-disable-next-line security/detect-non-literal-fs-filename -- fixed repository URL, not user input
const projectLicense = readFileSync(fileURLToPath(new URL('./LICENSE', import.meta.url)), 'utf8');
// eslint-disable-next-line security/detect-non-literal-fs-filename -- fixed repository URL, not user input
const thirdPartyNotices = readFileSync(
  fileURLToPath(new URL('./THIRD_PARTY_NOTICES.md', import.meta.url)),
  'utf8',
);

export default defineConfig({
  base: './',
  define: {
    __APP_VERSION__: JSON.stringify(packageMetadata.version),
  },
  plugins: [
    {
      name: 'ship-legal-notices',
      generateBundle() {
        this.emitFile({ type: 'asset', fileName: 'LICENSE', source: projectLicense });
        this.emitFile({ type: 'asset', fileName: 'THIRD_PARTY_NOTICES.txt', source: thirdPartyNotices });
      },
    },
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  build: {
    target: 'es2022',
    sourcemap: false,
    chunkSizeWarningLimit: 1500,
    rollupOptions: {
      output: {
        manualChunks: {
          phaser: ['phaser'],
        },
      },
    },
  },
  server: {
    port: 4173,
    strictPort: true,
    headers: {
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'no-referrer',
      'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
    },
  },
  preview: {
    port: 4173,
    strictPort: true,
  },
});
