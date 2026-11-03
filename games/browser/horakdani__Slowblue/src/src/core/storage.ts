/**
 * Slowblue: every persisted value goes through here.
 *
 * `localStorage` throws rather than returns null in a surprising number of real
 * situations - Safari private mode, disabled site data, a full quota, a sandboxed
 * iframe. A game must never fail to start because a preference could not be read,
 * so every access is wrapped and every failure degrades to "no stored value".
 */

// The game was renamed to Slowblue; this prefix was not. Every key already on a
// player's device is `tide.*`, and renaming it would silently throw away their
// profile, their settings and their telemetry. The prefix is not user-visible.
const PREFIX = 'tide.';

function store(): Storage | null {
  try {
    const s = globalThis.localStorage;
    if (s === undefined || s === null) return null;
    // Touch it: some browsers only throw on first use, not on property access.
    const probe = `${PREFIX}__probe`;
    s.setItem(probe, '1');
    s.removeItem(probe);
    return s;
  } catch {
    return null;
  }
}

let cached: Storage | null | undefined;

function backing(): Storage | null {
  if (cached === undefined) cached = store();
  return cached;
}

/** The stored text of a key, or null. */
function readRaw(key: string): string | null {
  const s = backing();
  if (s === null) return null;
  try {
    return s.getItem(PREFIX + key);
  } catch {
    return null;
  }
}

/** Puts already-serialised text in. */
function writeRaw(key: string, raw: string): void {
  const s = backing();
  try {
    s?.setItem(PREFIX + key, raw);
  } catch {
    /* quota or private mode: the game keeps running, the value is just not kept */
  }
}

export function readJson<T>(key: string, fallback: T): T {
  const raw = readRaw(key);
  if (raw === null) return fallback;
  try {
    const parsed: unknown = JSON.parse(raw);
    return parsed === null || parsed === undefined ? fallback : (parsed as T);
  } catch {
    return fallback;
  }
}

export function writeJson(key: string, value: unknown): void {
  let raw: string;
  try {
    raw = JSON.stringify(value);
  } catch {
    // A value that will not serialise is not a value either store can hold, and
    // finding that out must not be how a save fails loudly.
    return;
  }
  writeRaw(key, raw);
}

export function removeKey(key: string): void {
  const s = backing();
  try {
    s?.removeItem(PREFIX + key);
  } catch {
    /* ignore */
  }
}

/** Test hook: forget the cached availability probe. */
export function resetStorageProbe(): void {
  cached = undefined;
}
