import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { defineConfig, type Plugin } from 'vite';

/** The line in `public/sw.js` this plugin owns, matched by its trailing marker. */
const BUILD_LINE = /^const BUILD = .*__SLOWBLUE_BUILD__.*$/m;

/**
 * Writes the build's asset list into the service worker.
 *
 * The worker has to precache the hashed bundle, and only the build knows its name.
 * The alternative - a worker that discovers assets by watching `fetch` - is what was
 * there before, and it has a hole the size of the first launch: the page that loads
 * the bundle is not yet controlled by the worker installing underneath it, so the one
 * request that matters is the one request the handler never sees.
 *
 * `public/sw.js` stays the readable source of truth and is copied verbatim by vite;
 * this rewrites the copy in `dist` afterwards. That ordering is an assumption about
 * vite's internals, so it is asserted rather than trusted: if the marker line is gone
 * from the output - not copied yet, renamed, already replaced - the build fails here
 * instead of shipping a worker that quietly precaches nothing.
 */
function precacheManifest(): Plugin {
  let assets: string[] = [];
  let outDir = 'dist';
  let base = '/';
  return {
    name: 'slowblue-precache-manifest',
    apply: 'build',
    configResolved(config) {
      outDir = resolve(config.root, config.build.outDir);
      // A project page is served under `/<repo>/`, and a precache list written at the
      // origin root there asks for files that are not at those URLs. `config.base`
      // already ends in a slash, whatever it was set to.
      base = config.base;
    },
    generateBundle(_options, bundle) {
      // Sourcemaps are not bundle entries in rollup, but `.map` is filtered anyway:
      // the one thing this list must never do is put 2.4 MB of debug data into an
      // offline install that no browser was going to ask for.
      assets = Object.keys(bundle)
        .filter((file) => !file.endsWith('.map'))
        .map((file) => `${base}${file}`)
        .sort();
    },
    closeBundle() {
      const file = resolve(outDir, 'sw.js');
      const source = readFileSync(file, 'utf8');
      if (!BUILD_LINE.test(source)) {
        throw new Error(`slowblue-precache-manifest: no BUILD line in ${file}`);
      }
      // The version is the manifest's own fingerprint, so `activate` drops the old
      // cache exactly when the assets changed and never when they did not.
      const version = createHash('sha256').update(assets.join('\n')).digest('hex').slice(0, 12);
      const build = JSON.stringify({ version, assets });
      writeFileSync(file, source.replace(BUILD_LINE, `const BUILD = ${build};`));
    },
  };
}

export default defineConfig({
  /**
   * Where the game is served from.
   *
   * `/` for a dev server and for a site at a domain root; `BASE_PATH=/Slowblue/` for
   * a GitHub Pages project site, which is what `npm run deploy` sets. Everything
   * that has to agree with it reads it rather than repeating it: the service worker
   * takes its own location, the manifest is relative to itself, and the precache
   * list is written by the plugin below out of `config.base`.
   */
  base: process.env.BASE_PATH ?? '/',
  plugins: [precacheManifest()],
  // 5173 by default so the README's "open this on your phone" stays true, but never
  // pinned: PORT wins, and vite falls forward to the next free port rather than
  // failing when something else already owns 5173.
  server: {
    // Be explicit: on macOS `true` may bind the IPv6 loopback only, which makes
    // 127.0.0.1 previews and phones on the LAN report the app as unavailable.
    host: '0.0.0.0',
    port: Number(process.env.PORT) || 5173,
    strictPort: false,
  },
  build: {
    target: 'es2020',
    /**
     * Emitted, never advertised.
     *
     * `true` put a `sourceMappingURL` comment on the bundle, which is an invitation
     * to fetch 2.4 MB next to a 399 KB game - and it is 2.4 MB the precache would
     * then have had to have an opinion about. `hidden` keeps the maps on disk, where
     * the allocation probe in `e2e/measure.spec.ts` can still be pointed at them to
     * put names back on minified frames, and takes them off the wire. A deploy
     * should not upload `*.map`; nothing in the app refers to them.
     */
    sourcemap: 'hidden',
  },
});
