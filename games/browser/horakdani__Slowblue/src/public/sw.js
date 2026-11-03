/*
 * Slowblue service worker.
 *
 * Deliberately dumb: precache what the first frame needs, then stale-while-revalidate
 * every same-origin GET. Vite fingerprints its assets, so a stale hashed file is never
 * the wrong file - only the HTML can go stale, and that is revalidated on every load.
 * Nothing is ever fetched cross-origin, because the game has no network code at all.
 */

/**
 * The build's own manifest, rewritten in place by `slowblue-precache-manifest` in
 * vite.config.ts. This line is what it replaces; the plugin fails the build if it
 * cannot find it, because a worker that silently ships the dev value is exactly the
 * failure this whole file exists to prevent.
 *
 * The dev value is real and correct for dev: the worker is only registered in a
 * production build (see src/platform/pwa.ts), so an empty asset list here is never
 * anything's offline story.
 */
const BUILD = { version: 'dev', assets: [] }; /* __SLOWBLUE_BUILD__ */

/**
 * The cache name follows the manifest, not a number someone remembers to bump.
 * `activate` deletes every other cache, so a build whose assets changed starts clean
 * and a rebuild that changed nothing keeps its cache warm.
 */
const VERSION = `slowblue-${BUILD.version}`;
/**
 * Where this worker was served from, which is not necessarily the origin root.
 *
 * GitHub Pages serves a project site under `/<repo>/`, so a shell list written as
 * `/index.html` precaches four URLs that do not exist and the first offline launch
 * is a blank screen. The worker's own location is the one thing that always knows
 * the answer, so every path below is built from it rather than assumed.
 */
const BASE = new URL('./', self.location).pathname;
/** What the page is, independent of any build: documents, manifest, icon. */
const SHELL = [BASE, `${BASE}index.html`, `${BASE}manifest.webmanifest`, `${BASE}icon.svg`];
/**
 * ...plus what this build's page actually loads.
 *
 * Without the second half the game did not survive its first flight. The hashed
 * bundle is requested by a page the worker does not yet control - it was installing
 * while that request went past - so `fetch` never saw it and nothing cached it. The
 * next launch, offline, asked for a module the cache had never heard of.
 */
const PRECACHE = [...new Set([...SHELL, ...BUILD.assets])];

/**
 * How a cached entry is looked up, and why `ignoreVary` is not optional here.
 *
 * The precache almost shipped broken a second time, in a way that reads as working:
 * the bundle was in the cache, under exactly the right URL, and the cache still
 * answered "no". `install` fetches it plainly, with no `Origin` header. The page asks
 * for it as `<script type="module" crossorigin>`, which is a CORS request and does
 * carry one. Vite's preview server - and most static hosts - answer with
 * `Vary: Origin`, so the Cache API compares those two `Origin` values, finds one
 * present and one absent, and refuses the match. Offline, that is a blank screen
 * again, this time with the file sitting in the cache the whole way.
 *
 * Nothing on this origin varies its body by request header: the assets are
 * fingerprinted static files and there is no content negotiation to respect. So the
 * lookup ignores `Vary` outright, and ignores the query string for the same reason
 * it always did - `/?seed=123` is the same document as `/`.
 */
const MATCH = { ignoreSearch: true, ignoreVary: true };

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(VERSION)
      // addAll rejects the whole install if any single URL 404s; individual puts
      // let the worker install successfully on a partial deploy. A miss here is not
      // fatal either way: the fetch handler caches whatever it passes on the next
      // online load, so the cost of one failed put is one more launch with signal.
      .then((cache) => Promise.all(PRECACHE.map((url) => cache.add(url).catch(() => undefined))))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== VERSION).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  event.respondWith(
    caches.open(VERSION).then(async (cache) => {
      const cached = await cache.match(req, MATCH);
      const network = fetch(req)
        .then((res) => {
          if (res.ok && res.type === 'basic') cache.put(req, res.clone());
          return res;
        })
        .catch(() => cached);
      // Navigations must not block on a slow network when a shell is already cached.
      if (cached !== undefined) {
        event.waitUntil(network.catch(() => undefined));
        return cached;
      }
      const res = await network;
      if (res !== undefined) return res;
      // The shell answers a navigation that missed, and *only* a navigation. It used
      // to answer everything, which meant an uncached module script was served 200
      // with a page of HTML in its body: no failed request, no error in the console,
      // no game, blank screen. A script that cannot be found should say so.
      if (req.mode === 'navigate') {
        const fallback = await cache.match(`${BASE}index.html`, MATCH);
        if (fallback !== undefined) return fallback;
      }
      return Response.error();
    }),
  );
});
