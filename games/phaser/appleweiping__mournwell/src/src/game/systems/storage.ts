interface SaveData {
  version: 1;
  sound: boolean;
  runs: number;
  wins: number;
  bestTimeMs: number | null;
  wellscript: number;
}

const STORAGE_KEY = 'mournwell.save.v1';
const DEFAULT_SAVE: SaveData = {
  version: 1,
  sound: true,
  runs: 0,
  wins: 0,
  bestTimeMs: null,
  wellscript: 0,
};

function finiteNonNegative(value: unknown, fallback: number): number {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0 ? value : fallback;
}

function nullableFiniteNonNegative(value: unknown): number | null {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0 ? value : null;
}

export function loadSave(): SaveData {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_SAVE };
    const candidate = JSON.parse(raw) as Partial<SaveData>;
    if (candidate.version !== 1) return { ...DEFAULT_SAVE };
    return {
      version: 1,
      sound: typeof candidate.sound === 'boolean' ? candidate.sound : true,
      runs: finiteNonNegative(candidate.runs, 0),
      wins: finiteNonNegative(candidate.wins, 0),
      bestTimeMs: nullableFiniteNonNegative(candidate.bestTimeMs),
      wellscript: finiteNonNegative(candidate.wellscript, 0),
    };
  } catch {
    return { ...DEFAULT_SAVE };
  }
}

export function updateSave(patch: Partial<Omit<SaveData, 'version'>>): SaveData {
  const next = { ...loadSave(), ...patch, version: 1 as const };
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  } catch {
    // A blocked storage backend should never block a run.
  }
  return next;
}
