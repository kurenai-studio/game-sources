import { defineConfig } from 'vite';
import { resolve } from 'path';
import { copyFileSync, rmSync, readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, statSync } from 'fs';
import { join } from 'path';

export default defineConfig({
  root: 'src',
  base: './',
  publicDir: '../public',
  build: {
    outDir: resolve(__dirname, 'public'),
    emptyOutDir: false,
    copyPublicDir: false,
    rollupOptions: {
      input: resolve(__dirname, 'src/index.html'),
      output: {
        entryFileNames: 'assets/bundle-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]',
        chunkFileNames: 'assets/[name]-[hash].js'
      }
    },
    sourcemap: true,
    minify: 'esbuild',
    write: true
  },
  plugins: [
    {
      name: 'clean-assets',
      buildStart() {
        const assetsDir = resolve(__dirname, 'public/assets');
        const publicDir = resolve(__dirname, 'public');
        
        if (existsSync(assetsDir)) {
          try {
            console.log('Cleaning assets directory...');
            const files = readdirSync(assetsDir);
            let removedCount = 0;
            files.forEach(file => {
              const filePath = join(assetsDir, file);
              try {
                const stat = statSync(filePath);
                if (stat.isFile() || stat.isDirectory()) {
                  rmSync(filePath, { recursive: true, force: true });
                  removedCount++;
                }
              } catch (e) {
                console.warn(`Failed to remove ${file}:`, e);
              }
            });
            if (removedCount > 0) {
              console.log(`Removed ${removedCount} file(s) from assets directory`);
            }
          } catch (e) {
            console.warn('Failed to clean assets directory:', e);
            try {
              rmSync(assetsDir, { recursive: true, force: true });
              mkdirSync(assetsDir, { recursive: true });
              console.log('Recreated assets directory');
            } catch (e2) {
              console.error('Failed to recreate assets directory:', e2);
            }
          }
        } else {
          mkdirSync(assetsDir, { recursive: true });
        }
      }
    },
    {
      name: 'move-html',
      closeBundle() {
        try {
          const srcHtmlPath = resolve(__dirname, 'public/src/index.html');
          if (existsSync(srcHtmlPath)) {
            let htmlContent = readFileSync(srcHtmlPath, 'utf-8');
            // Fix asset paths
            htmlContent = htmlContent.replace(/\.\.\/assets\//g, './assets/');
            htmlContent = htmlContent.replace(/\/style\.css/g, './style.css');
            writeFileSync(resolve(__dirname, 'public/index.html'), htmlContent);
            rmSync(resolve(__dirname, 'public/src'), { recursive: true, force: true });
          }
        } catch (e) {
          console.warn('Failed to move HTML:', e);
        }
      }
    }
  ],
  server: {
    port: 3000,
    open: true
  }
});
