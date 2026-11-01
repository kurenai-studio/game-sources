// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import type { Plugin } from 'vite';
import { defineConfig } from 'vitest/config';
import { SW_FILE, buildVersion, precachePath, precacheUrls, serviceWorkerSource } from './src/pwa/swSource.ts';

/** Every file under dir, as paths relative to it with forward slashes. */
function walk(dir: string, rel = ''): string[] {
  const out: string[] = [];
  for (const e of readdirSync(path.join(dir, rel), { withFileTypes: true })) {
    const p = rel ? `${rel}/${e.name}` : e.name;
    if (e.isDirectory()) out.push(...walk(dir, p));
    else out.push(p);
  }
  return out;
}

/**
 * The installable app (milestone 1 of lane G7): once the build has written dist (the bundle and the public files), this
 * writes dist/sw.js, a service worker that keeps every built file under a cache named for the build's version stamp.
 */
function serviceWorker(): Plugin {
  let outDir = '';
  return {
    name: 'antwars-service-worker',
    apply: 'build',
    configResolved(config) {
      outDir = path.resolve(config.root, config.build.outDir);
    },
    closeBundle() {
      const kept = walk(outDir).filter(precachePath);
      const urls = precacheUrls(kept);
      // The stamp covers the kept files and the worker's own code, so a change to either is a new version.
      const version = buildVersion(
        kept.map((p) => ({ path: p, bytes: readFileSync(path.join(outDir, p)) })),
        serviceWorkerSource('', urls),
      );
      writeFileSync(path.join(outDir, SW_FILE), serviceWorkerSource(version, urls));
      console.log(`[antwars] ${SW_FILE} version ${version}, ${kept.length} files kept for offline play`);
    },
  };
}

export default defineConfig({
  base: './',
  plugins: [serviceWorker()],
  server: { port: 5173, strictPort: true },
  build: { target: 'es2020', chunkSizeWarningLimit: 2000 },
  test: { include: ['src/**/*.test.ts'], environment: 'node' },
});
