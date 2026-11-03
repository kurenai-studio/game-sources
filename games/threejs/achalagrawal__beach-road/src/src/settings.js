// Player preferences and lifetime stats, kept in localStorage (silently in-memory if unavailable).

const KEY = 'beachRoad.settings.v1';

export const DEFAULTS = {
  look: 'golden',
  time: 'default',       // 'default' = the look's own time, a preset id, or 'cycle'
  weather: 'clear',      // preset id or 'auto'
  traffic: 'normal',
  station: 'auto',       // 'auto' = match the look
  volume: { master: 0.9, music: 0.8, sfx: 0.8 },
  muted: false,
  quality: 'auto',
  car: 'sedan',
  paint: null,           // null = the model's first paint
  camera: 'chase',
  units: 'kmh',
  hud: true,
  stats: { distance: 0, time: 0 },
};

function merge(base, over) {
  const out = { ...base };
  for (const [k, v] of Object.entries(over ?? {})) {
    out[k] = v && typeof v === 'object' && !Array.isArray(v) && base[k] && typeof base[k] === 'object' ? merge(base[k], v) : v;
  }
  return out;
}

export function loadSettings() {
  try {
    return merge(DEFAULTS, JSON.parse(localStorage.getItem(KEY) || '{}'));
  } catch {
    return merge(DEFAULTS, {});
  }
}

export function saveSettings(s) {
  try { localStorage.setItem(KEY, JSON.stringify(s)); } catch { /* private mode */ }
}
