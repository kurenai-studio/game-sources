import { defineConfig } from 'vite';
// base './' = works on any host or sub-folder (GitHub Pages, Netlify, tab.bot ...)
export default defineConfig({ base: './', build: { outDir: 'site', emptyOutDir: true, assetsInlineLimit: 0 } });
