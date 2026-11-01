// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The service worker the build writes beside the game (vite.config.ts): it keeps every built file, so after the first
// visit the game opens with no network, and a new build arrives as a new version that the player reloads into with a tap.
// Pure on purpose (no Node, no browser): the build calls it with the files on disk, the tests with made up ones.

/** The worker's file name, at the root of the build beside index.html. */
export const SW_FILE = 'sw.js';

/** True for a built file the worker keeps: everything but itself, source maps, dot files and the host's own files. */
export function precachePath(path: string): boolean {
  const name = path.split('/').pop() ?? path;
  if (path === SW_FILE || name.startsWith('.')) return false;
  if (name.endsWith('.map')) return false;
  return name !== '_headers' && name !== '_redirects' && name !== 'netlify.toml';
}

/** cyrb53: a small 53 bit hash of bytes, enough to tell one build from another. */
export function hash53(bytes: Uint8Array, seed = 0): number {
  let h1 = 0xdeadbeef ^ seed;
  let h2 = 0x41c6ce57 ^ seed;
  for (let i = 0; i < bytes.length; i++) {
    const b = bytes[i];
    h1 = Math.imul(h1 ^ b, 2654435761);
    h2 = Math.imul(h2 ^ b, 1597334677);
  }
  h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507);
  h1 ^= Math.imul(h2 ^ (h2 >>> 13), 3266489909);
  h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507);
  h2 ^= Math.imul(h1 ^ (h1 >>> 13), 3266489909);
  return 4294967296 * (2097151 & h2) + (h1 >>> 0);
}

/**
 * The version stamp of a build: one hash over every kept file's path, size and bytes, in path order, and over the
 * worker's own code (worker, its source with no version in it), as 14 hex digits. The same files and worker give the
 * same stamp (no update offered); one changed byte anywhere, the worker's code included, gives a new one.
 */
export function buildVersion(files: ReadonlyArray<{ path: string; bytes: Uint8Array }>, worker = ''): string {
  const enc = new TextEncoder();
  const lines = [...files]
    .filter((f) => precachePath(f.path))
    .sort((a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0))
    .map((f) => `${f.path}:${f.bytes.length}:${hash53(f.bytes).toString(16)}`);
  lines.push(`worker:${hash53(enc.encode(worker)).toString(16)}`);
  return hash53(enc.encode(lines.join('\n'))).toString(16).padStart(14, '0');
}

/** The addresses the worker keeps, relative to its own place: index.html is kept as the game's address, ./ (no redirect). */
export function precacheUrls(paths: ReadonlyArray<string>): string[] {
  const urls = paths.filter(precachePath).map((p) => (p === 'index.html' ? './' : `./${p}`));
  return [...new Set(urls)].sort();
}

/**
 * The worker itself. It keeps the build's files under one cache named for the version; a page load of the game (with
 * any query, ?debug or ?round=8) opens the kept game; any other request for a kept file is answered from the cache. A
 * new build installs beside the old one and waits; the page shows a line and a tap sends skip-waiting, the new version
 * takes over and the page reloads. Old caches go when the new version takes over.
 */
export function serviceWorkerSource(version: string, urls: ReadonlyArray<string>): string {
  return `// Ant Wars service worker, written by the build (src/pwa/swSource.ts). Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
const VERSION = ${JSON.stringify(version)};
const CACHE = 'antwars-' + VERSION;
const FILES = ${JSON.stringify(urls)};
const SCOPE = new URL('./', self.location).pathname;

// A response that came through a redirect cannot answer a page load, so it is kept as a clean copy.
async function keepable(res) {
  if (!res.redirected) return res;
  const body = await res.blob();
  return new Response(body, { status: res.status, statusText: res.statusText, headers: res.headers });
}

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    await Promise.all(FILES.map(async (f) => {
      const res = await fetch(new Request(f, { cache: 'reload' }));
      if (!res.ok) throw new Error('precache ' + f + ' answered ' + res.status);
      await cache.put(f, await keepable(res));
    }));
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith('antwars-') && key !== CACHE) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('message', (event) => {
  const type = event.data && event.data.type;
  if (type === 'skip-waiting') self.skipWaiting();
  else if (type === 'version' && event.ports && event.ports[0]) event.ports[0].postMessage({ version: VERSION, files: FILES.length });
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  // The cache holds only this build's own files, so a stored Vary (a server's Vary: Origin) never picks between copies:
  // without ignoreVary the game's module script (sent with an Origin header) missed its kept copy when offline.
  if (req.mode === 'navigate') {
    if (url.pathname !== SCOPE && url.pathname !== SCOPE + 'index.html') return;
    event.respondWith((async () => {
      const kept = await caches.open(CACHE).then((c) => c.match('./', { ignoreVary: true }));
      return kept || fetch(req);
    })());
    return;
  }
  event.respondWith((async () => {
    const kept = await caches.open(CACHE).then((c) => c.match(req, { ignoreVary: true }));
    return kept || fetch(req);
  })());
});
`;
}
