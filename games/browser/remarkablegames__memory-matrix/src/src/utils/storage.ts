import type { Mode, Settings } from 'src/types/game';

export const STORAGE_KEY = 'org.remarkablegames.memory-matrix';

function defaults(): Settings {
  return { best: { classic: 0, timed: 0 }, volume: 0.5 };
}

export const DEFAULT_SETTINGS: Settings = defaults();

function toCount(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0
    ? Math.floor(value)
    : 0;
}

function toVolume(value: unknown): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    return DEFAULT_SETTINGS.volume;
  }
  return Math.min(1, Math.max(0, value));
}

/**
 * Reads persisted settings, falling back to defaults for missing or
 * malformed data. Never throws.
 *
 * @returns The validated settings currently in storage.
 */
export function loadSettings(): Settings {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw === null) {
      return defaults();
    }

    const data: unknown = JSON.parse(raw);
    if (typeof data !== 'object' || data === null) {
      return defaults();
    }

    const { best, volume } = data as { best?: unknown; volume?: unknown };
    const storedBest =
      typeof best === 'object' && best !== null
        ? (best as Record<string, unknown>)
        : {};

    return {
      best: {
        classic: toCount(storedBest.classic),
        timed: toCount(storedBest.timed),
      },
      volume: toVolume(volume),
    };
  } catch {
    // Storage unavailable (private mode) or malformed JSON: use defaults.
    return defaults();
  }
}

/**
 * Merges a patch into the persisted settings. Best-effort: never throws.
 *
 * @param patch - Fields to overwrite; unspecified fields keep their value.
 */
export function saveSettings(patch: Partial<Settings>): void {
  try {
    const current = loadSettings();
    const next: Settings = {
      best: patch.best ? { ...current.best, ...patch.best } : current.best,
      volume: patch.volume ?? current.volume,
    };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  } catch {
    // Storage unavailable: settings simply do not persist.
  }
}

/**
 * Persists a new best score for one mode without touching the other.
 *
 * @param mode - Game mode the score belongs to.
 * @param score - Rounds cleared.
 */
export function saveBest(mode: Mode, score: number): void {
  const best = { ...loadSettings().best };
  best[mode] = score;
  saveSettings({ best });
}
