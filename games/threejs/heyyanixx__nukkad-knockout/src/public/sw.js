// Offline support (v2): network-first for the page, cache-first for hashed assets.
// Cache name bumped for v2 so phones that had v1 installed pick up the 3D build.
const CACHE = 'nukkad-ko-v2-3d-2';
const SHELL = ['./', './manifest.webmanifest', './fonts/Anton-Regular.ttf', './icons/icon-192.png'];
self.addEventListener('install', (e) => { self.skipWaiting(); e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL))); });
self.addEventListener('activate', (e) => e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim())));
self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) return;
  const put = (res) => { if (res.ok) { const copy = res.clone(); caches.open(CACHE).then((c) => c.put(req, copy)); } return res; };
  if (req.mode === 'navigate') {
    // page: try the network first so updates land, fall back to the cached shell offline
    e.respondWith(fetch(req).then(put).catch(() => caches.match(req).then((hit) => hit || caches.match(new URL(req.url).pathname.includes('/classic') ? './classic/' : './'))));
    return;
  }
  e.respondWith(caches.match(req).then((hit) => hit || fetch(req).then(put)));
});
