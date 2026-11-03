/**
 * Player settings, remembered in the browser between sessions. Storage can be unavailable
 * (private windows, blocked site data), so every read and write falls back to the defaults.
 */
export interface Settings {
  /** Master volume, 0 to 1. */
  volume: number;
  /** Blood on people when they are hit or downed. Training props never bleed. */
  blood: boolean;
  /** Camera shake on gunfire and hits. */
  shake: boolean;
}

const KEY = 'breach.settings';
const DEFAULTS: Settings = { volume: 0.8, blood: true, shake: true };

function load(): Settings {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) {
      const saved = JSON.parse(raw) as Partial<Settings> & { sound?: boolean };
      // Earlier versions stored sound as on/off.
      if (saved.volume === undefined && saved.sound === false) saved.volume = 0;
      delete saved.sound;
      return { ...DEFAULTS, ...saved };
    }
  } catch {
    // Fall through to defaults.
  }
  return { ...DEFAULTS };
}

export const settings: Settings = load();

export function saveSettings(): void {
  try {
    localStorage.setItem(KEY, JSON.stringify(settings));
  } catch {
    // Not persisted this session; the in-memory value still applies.
  }
}
