// Offline support and instant launches. Cache first: every request is
// answered from the cache straight away, even on a weak connection. Each
// launch downloads the whole game again in the background, so a new deploy
// shows up on the launch after the one that fetched it.
//
// Each download is stored as a version of its own, in a cache that never
// changes once complete. Opening the page picks the newest complete version
// and every later request from that page is answered from the same one, so a
// page never runs a mix of two versions, even when a download finishes while
// it is still loading.

// Every version's cache is named with this, then a number that grows with
// each download, so the newest version has the highest.
const VERSION_PREFIX = 'tetris-version-';
// Which version each page opened with. Kept in a cache rather than in the
// worker's memory, so a newer worker that takes over still knows.
const PINS = 'tetris-pins';
// How long a page keeps the version it opened with. Pages ask for all their
// files as they start, so this only needs to outlast loading.
const PIN_MS = 10 * 60 * 1000;
// The caches earlier workers kept, cleared out when this one takes over.
const OLD_CACHES = ['tetris', 'tetris-2'];
const APP_SHELL = [
  './',
  'index.html',
  'style.css',
  'script.js',
  'manifest.webmanifest',
  'icons/icon.svg',
  'icons/icon-192.png',
  'icons/icon-512.png',
  'icons/apple-touch-icon.png',
  'game/gameManager.js',
  'game/gameState.js',
  'game/inputController.js',
  'game/position.js',
  'game/session.js',
  'game/tetromino.js',
  'game/tetrominoFactory.js'
];

// `self` is this service worker; the cast tells the type checker so.
const worker = /** @type {ServiceWorkerGlobalScope} */ (/** @type {unknown} */ (self));

/** @param {string} name */
const versionNumber = name => parseInt(name.slice(VERSION_PREFIX.length), 10);

/** @returns {Promise<string[]>} Every version cache, oldest first. */
async function versionNames() {
  const names = (await caches.keys()).filter(name => name.startsWith(VERSION_PREFIX));
  return names.sort((a, b) => versionNumber(a) - versionNumber(b));
}

// A download stores every file in one step, so a version cache with anything
// in it is complete. An empty one is still downloading, or was cut off.
/** @returns {Promise<string[]>} Every complete version, newest first. */
async function completeVersions() {
  /** @type {string[]} */
  const complete = [];
  for (const name of (await versionNames()).reverse()) {
    if ((await (await caches.open(name)).keys()).length > 0) complete.push(name);
  }
  return complete;
}

/** @returns {Promise<string | null>} */
async function newestVersion() {
  return (await completeVersions())[0] ?? null;
}

/** @param {string} clientId */
const pinKey = clientId => `pins/${encodeURIComponent(clientId)}`;

/**
 * @param {string} clientId
 * @param {string} version
 */
async function pin(clientId, version) {
  await (await caches.open(PINS)).put(pinKey(clientId), Response.json({ version, at: Date.now() }));
}

// The version a page opened with, while it still exists, or else the newest.
/**
 * @param {string} clientId
 * @returns {Promise<string | null>}
 */
async function versionFor(clientId) {
  const pinned = clientId ? await caches.match(pinKey(clientId), { cacheName: PINS }) : undefined;
  const version = pinned ? /** @type {{ version: string }} */ (await pinned.json()).version : null;
  return version && await caches.has(version) ? version : newestVersion();
}

/**
 * @param {Request} request
 * @param {string | null} version
 */
async function answer(request, version) {
  const cached = version ? await caches.match(request, { cacheName: version, ignoreSearch: true }) : undefined;
  // Not cached: ask the network, or a plain network error if offline.
  return cached ?? fetch(request).catch(() => Response.error());
}

/** @param {FetchEvent} event */
async function openPage(event) {
  const version = await newestVersion();
  if (version && event.resultingClientId) await pin(event.resultingClientId, version);
  return answer(event.request, version);
}

// Deletes the versions older than the newest complete one, except any a page
// opened with in the last few minutes. The one before the newest is kept too:
// a page opening just as a download finished may have picked it and not yet
// noted that it did.
async function removeOldVersions() {
  const complete = await completeVersions();
  const newest = complete[0];
  if (!newest) return;
  const kept = new Set(complete.slice(0, 2));
  const pins = await caches.open(PINS);
  for (const key of await pins.keys()) {
    const pinned = await pins.match(key);
    if (!pinned) continue;
    const { version, at } = /** @type {{ version: string, at: number }} */ (await pinned.json());
    if (Date.now() - at > PIN_MS) await pins.delete(key);
    else kept.add(version);
  }
  for (const name of await versionNames()) {
    if (versionNumber(name) < versionNumber(newest) && !kept.has(name)) await caches.delete(name);
  }
}

// Downloads every file of the game into a new version cache, in one step. If
// any file fails, the new cache is deleted, so a version is always whole.
// 'no-cache' checks each file with the server instead of reusing the
// browser's own copy, which may be minutes old.
async function download() {
  const names = await versionNames();
  const number = names.length > 0 ? versionNumber(names[names.length - 1]) + 1 : 1;
  // The random part keeps downloads that start at the same time apart.
  const name = `${VERSION_PREFIX}${number}-${Math.random().toString(36).slice(2)}`;
  try {
    await (await caches.open(name)).addAll(APP_SHELL.map(file => new Request(file, { cache: 'no-cache' })));
  } catch (error) {
    await caches.delete(name);
    throw error;
  }
  // Only tidying: the new version is stored whether or not this works.
  await removeOldVersions().catch(() => {});
}

worker.addEventListener('install', event => {
  event.waitUntil(download());
  worker.skipWaiting();
});

// Clears out the caches of earlier workers, which kept a single cache that
// each download changed in place. Only those, by name: GitHub Pages serves
// every project of an account from one origin, and they all share its caches.
worker.addEventListener('activate', event => {
  event.waitUntil(Promise.all(OLD_CACHES.map(name => caches.delete(name)))
    .then(() => worker.clients.claim()));
});

worker.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  if (event.request.mode !== 'navigate') {
    event.respondWith(versionFor(event.clientId).then(version => answer(event.request, version)));
    return;
  }
  const opened = openPage(event);
  event.respondWith(opened);
  // Opening the game downloads the newest version for the next launch, once
  // this page has its own. A failed download (offline) changes nothing.
  event.waitUntil(opened.then(() => download()).catch(() => {}));
});
