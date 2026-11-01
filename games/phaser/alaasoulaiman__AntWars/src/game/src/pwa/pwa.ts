// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The page side of the installable app: registers the service worker the build writes (src/pwa/swSource.ts), notices a
// new version waiting behind the one in use, and on the player's tap hands over to it and reloads. Every browser call
// is guarded: a browser without service workers, or one that refuses them, still plays (just not offline).

export interface PwaState {
  /** The browser has service workers and this is a built game (the dev server never registers one). */
  supported: boolean;
  registered: boolean;
  /** A service worker answers this page's requests (so a reload works with no network). */
  controlled: boolean;
  /** A new version has installed and waits for the tap that reloads into it. */
  updateReady: boolean;
  /** The browser said the game can be installed (Chrome's beforeinstallprompt; iPhone Safari never says it). */
  installable: boolean;
  /** The version stamp of the worker running this page (it answers a message), null until it has answered. */
  version: string | null;
  error: string | null;
}

const state: PwaState = { supported: false, registered: false, controlled: false, updateReady: false, installable: false, version: null, error: null };

/** Asks the worker in control for its version stamp; the title shows it small, so a phone can tell which build it runs. */
function askVersion(): void {
  const ctl = navigator.serviceWorker.controller;
  if (!ctl) return;
  try {
    const ch = new MessageChannel();
    ch.port1.onmessage = (e: MessageEvent) => {
      const v = e.data && typeof e.data.version === 'string' ? (e.data.version as string) : null;
      if (v) state.version = v;
    };
    ctl.postMessage({ type: 'version' }, [ch.port2]);
  } catch {
    // No stamp shown; the game plays the same.
  }
}
let waiting: ServiceWorker | null = null;
let reloadAsked = false;
let reloading = false;
let lastCheck = 0;

/** A copy of the state for the HUD and the smoke test. */
export function pwaState(): PwaState {
  return { ...state };
}

/** The running build's stamp for the title (the first 7 of its 14 hex digits), or an empty line before the worker answers. */
export function buildStamp(): string {
  return state.version ? `build ${state.version.slice(0, 7)}` : '';
}

/** True when a new version waits and a tap on the line would reload into it. */
export function updateReady(): boolean {
  return state.updateReady && waiting !== null;
}

/** The tap on "New version": the waiting version takes over and the page reloads into it (controllerchange below). */
export function applyUpdate(): boolean {
  if (!waiting) return false;
  reloadAsked = true;
  try {
    waiting.postMessage({ type: 'skip-waiting' });
    return true;
  } catch (e) {
    state.error = String(e);
    return false;
  }
}

function watch(reg: ServiceWorkerRegistration, w: ServiceWorker | null): void {
  if (!w) return;
  const check = () => {
    // Installed while another version runs this page: it waits for the tap. The first install has no controller yet and
    // takes over by itself (nothing to reload into).
    if (w.state === 'installed' && navigator.serviceWorker.controller) {
      waiting = reg.waiting ?? w;
      state.updateReady = true;
    }
  };
  check();
  w.addEventListener('statechange', check);
}

/** Registers ./sw.js after the page has loaded, so the first visit's game files are not fought over. */
export function registerServiceWorker(enabled: boolean): void {
  try {
    if (!enabled || typeof navigator === 'undefined' || !('serviceWorker' in navigator)) return;
    state.supported = true;
    state.controlled = navigator.serviceWorker.controller !== null;
    window.addEventListener('beforeinstallprompt', () => {
      state.installable = true;
    });
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      state.controlled = navigator.serviceWorker.controller !== null;
      askVersion();
      // Only the player's tap reloads; the first install's takeover changes nothing on screen.
      if (reloadAsked && !reloading) {
        reloading = true;
        window.location.reload();
      }
    });
    const register = () => {
      navigator.serviceWorker.register('./sw.js').then(
        (reg) => {
          state.registered = true;
          askVersion();
          if (reg.waiting && navigator.serviceWorker.controller) {
            waiting = reg.waiting;
            state.updateReady = true;
          }
          watch(reg, reg.installing);
          reg.addEventListener('updatefound', () => watch(reg, reg.installing));
          // The installed app comes back from the background without a page load: look for a new build then, once a minute at most.
          document.addEventListener('visibilitychange', () => {
            if (document.visibilityState !== 'visible' || Date.now() - lastCheck < 60_000) return;
            lastCheck = Date.now();
            reg.update().catch(() => undefined);
          });
        },
        (e) => {
          state.error = String(e);
        },
      );
    };
    if (document.readyState === 'complete') register();
    else window.addEventListener('load', register, { once: true });
  } catch (e) {
    state.error = String(e);
  }
}
