/**
 * Slowblue: offline install support, and nothing else.
 *
 * The game has no network code and no backend, so "works with no signal" is not a
 * feature to build - it is a fact to stop the browser from breaking. A service
 * worker that caches the shell is the whole requirement. It is registered only in a
 * production build, because a dev build with a caching worker in front of it is an
 * hour of confusing stale modules waiting to happen.
 */
export function registerServiceWorker(): void {
  if (import.meta.env.DEV) return;
  if (typeof navigator === 'undefined' || !('serviceWorker' in navigator)) return;
  window.addEventListener('load', () => {
    // `BASE_URL` rather than '/': a project page is served under `/<repo>/`, and a
    // worker registered at the origin root there is a 404 with no offline install
    // behind it. It ends in a slash, so the scope is the directory the game lives in.
    navigator.serviceWorker.register(`${import.meta.env.BASE_URL}sw.js`).catch(() => {
      /* an uninstallable game is still a playable game */
    });
  });
}
