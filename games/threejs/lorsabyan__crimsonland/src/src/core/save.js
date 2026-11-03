// Local profile. Storage can throw in private windows, so the game must work without it.
const KEY = 'crimsonland.profile.v1';
const defaults = () => ({ bests: { survival: [], rush: [], typing: [] }, missions: {}, volume: 0.8, music: 0.55, quality: null, shake: true, biome: 'dust', unlockAll: false });

export function loadProfile() {
  try { return { ...defaults(), ...JSON.parse(localStorage.getItem(KEY) ?? '{}') }; } catch { return defaults(); }
}

export function saveProfile(p) {
  try { localStorage.setItem(KEY, JSON.stringify(p)); } catch { /* storage unavailable: the session still works */ }
}
