// Tiny localStorage wrapper. Every access is guarded, so private mode, blocked
// storage or broken JSON never crash the game.

const PREFIX = 'air-hockey:';

/** Returns the storage object or null when it is not reachable. */
function store() {
  try {
    return globalThis.localStorage ?? null;
  } catch {
    return null;
  }
}

/**
 * Reads a JSON value, or returns `fallback` when it is missing or unreadable.
 * @template T
 * @param {string} key
 * @param {T} fallback
 * @returns {T | unknown}
 */
export function load(key, fallback) {
  try {
    const raw = store()?.getItem(PREFIX + key);
    return raw == null ? fallback : JSON.parse(raw);
  } catch {
    return fallback;
  }
}

/**
 * Saves a JSON value; failures are ignored.
 * @param {string} key
 * @param {unknown} value
 */
export function save(key, value) {
  try {
    store()?.setItem(PREFIX + key, JSON.stringify(value));
  } catch {
    // Storage full or blocked: the game keeps working without saving.
  }
}
