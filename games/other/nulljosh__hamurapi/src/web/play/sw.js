// Keeps the game playable with no internet. Bump the name to ship a new version.
const CACHE = "hamurapi-1.0.0-j";
const FILES = ["./", "rules.js", "scene.js", "sprites.png", "sprites.json", "story.json", "manifest.webmanifest", "../icon.png", "../icon-192.png",
  ...["music", "tap", "harvest", "poor", "rats", "starve", "arrive", "plague", "omen", "win", "lose"].map(n => `audio/${n}.mp3`)];
self.addEventListener("install", e => e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)).then(() => self.skipWaiting())));
self.addEventListener("activate", e => e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())));
// Network first, so a new deploy shows up at once; the cache answers when the network cannot.
self.addEventListener("fetch", e => {
  if (e.request.method !== "GET") return;
  e.respondWith(fetch(e.request).then(r => { if (r.ok) { const copy = r.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); } return r; })
    .catch(() => caches.match(e.request, { ignoreSearch: true })));
});
