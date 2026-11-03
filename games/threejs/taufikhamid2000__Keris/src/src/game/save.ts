// Browser progress saving. Pure data helpers plus a small store over an injected Storage-like object,
// so everything is unit tested in save.test.ts. No DOM or three.js. Every storage access is wrapped in
// try/catch and degrades to in-memory when localStorage is missing or blocked (private mode, SSR).

export const SAVE_KEY = "keris:save";
export const SAVE_VERSION = 2;
export const MISSION_ID = "malacca-1511";

export type Checkpoint = "start" | "kapitan";
export type QualityPref = "auto" | "low" | "high";

export interface MissionStats {
  completed: boolean;
  attempts: number;
  /** fastest full run from the mission start, in seconds */
  bestTime: number | null;
  /** best stealth rating, 1..3 (see stealthRating) */
  bestRating: number | null;
}

export interface SaveSettings {
  quality: QualityPref;
  /** look sensitivity multiplier, applies to mouse and touch */
  lookSens: number;
  invertY: boolean;
}

export interface SaveData {
  version: number;
  /** last checkpoint reached in the current attempt, null if the player never started */
  checkpoint: Checkpoint | null;
  missions: Record<string, MissionStats>;
  settings: SaveSettings;
  /** the intro cutscene has been shown (or skipped) once; Reset progress clears it */
  seenIntro: boolean;
}

export const LOOK_SENS_MIN = 0.4;
export const LOOK_SENS_MAX = 2.5;

export function defaultMission(): MissionStats {
  return { completed: false, attempts: 0, bestTime: null, bestRating: null };
}

export function defaultSettings(): SaveSettings {
  return { quality: "auto", lookSens: 1, invertY: false };
}

export function defaultSave(): SaveData {
  return { version: SAVE_VERSION, checkpoint: null, missions: {}, settings: defaultSettings(), seenIntro: false };
}

// ---------------------------------------------------------------- rating and formatting

/** 3 = never spotted, 2 = spotted once or twice, 1 = more. Alerts are guards that went fully alert. */
export function stealthRating(alerts: number): number {
  if (!(alerts > 0)) return 3;
  return alerts <= 2 ? 2 : 1;
}

export const RATING_NAMES: Record<number, string> = { 3: "Ghost", 2: "Shadow", 1: "Seen" };

export function ratingLabel(r: number | null): string {
  if (r === null) return "-";
  const n = Math.max(1, Math.min(3, Math.round(r)));
  return `${"*".repeat(n)} ${RATING_NAMES[n]}`;
}

export function formatTime(sec: number | null): string {
  if (sec === null || !Number.isFinite(sec) || sec < 0) return "-";
  const t = Math.floor(sec);
  const m = Math.floor(t / 60);
  const s = t % 60;
  return `${m}:${String(s).padStart(2, "0")}`;
}

// ---------------------------------------------------------------- validation and migration

const isObj = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null && !Array.isArray(v);
const num = (v: unknown, lo: number, hi: number, fallback: number) => (typeof v === "number" && Number.isFinite(v) ? Math.min(hi, Math.max(lo, v)) : fallback);

function cleanMission(v: unknown): MissionStats {
  const d = defaultMission();
  if (!isObj(v)) return d;
  return {
    completed: v.completed === true,
    attempts: Math.floor(num(v.attempts, 0, 1e6, 0)),
    bestTime: typeof v.bestTime === "number" && Number.isFinite(v.bestTime) && v.bestTime > 0 ? Math.min(v.bestTime, 1e6) : null,
    bestRating: typeof v.bestRating === "number" && Number.isFinite(v.bestRating) ? Math.round(num(v.bestRating, 1, 3, 1)) : null,
  };
}

function cleanSettings(v: unknown): SaveSettings {
  const d = defaultSettings();
  if (!isObj(v)) return d;
  return {
    quality: v.quality === "low" || v.quality === "high" ? v.quality : "auto",
    lookSens: num(v.lookSens, LOOK_SENS_MIN, LOOK_SENS_MAX, d.lookSens),
    invertY: v.invertY === true,
  };
}

/** Field-by-field clean of a current-version object: bad fields fall back to defaults, unknown fields are dropped. */
export function sanitize(v: unknown): SaveData {
  if (!isObj(v)) return defaultSave();
  const missions: Record<string, MissionStats> = {};
  if (isObj(v.missions)) {
    for (const k of Object.keys(v.missions)) if (k.length <= 64 && Object.keys(missions).length < 32) missions[k] = cleanMission(v.missions[k]);
  }
  return {
    version: SAVE_VERSION,
    checkpoint: v.checkpoint === "start" || v.checkpoint === "kapitan" ? v.checkpoint : null,
    missions,
    settings: cleanSettings(v.settings),
    seenIntro: v.seenIntro === true,
  };
}

/** Migration step N upgrades version N data to version N+1. */
export type Migrations = Record<number, (old: Record<string, unknown>) => Record<string, unknown>>;
export const MIGRATIONS: Migrations = {
  // v1 -> v2: adds seenIntro. Anyone who already started or finished the mission has played past where
  // the intro would show, so they are not shown it; a v1 save with no progress sees it once.
  1: (old) => {
    const missions = isObj(old.missions) ? Object.values(old.missions) : [];
    const played =
      old.checkpoint === "start" ||
      old.checkpoint === "kapitan" ||
      missions.some((m) => isObj(m) && (m.completed === true || (typeof m.attempts === "number" && m.attempts > 0)));
    return { ...old, seenIntro: played };
  },
};

/**
 * Turn any parsed value into current SaveData, or null if it cannot be used (not an object, no integer
 * version, a version newer than this build understands, or a missing migration step).
 */
export function migrate(raw: unknown, migrations: Migrations = MIGRATIONS, target = SAVE_VERSION): SaveData | null {
  if (!isObj(raw)) return null;
  let v = raw.version;
  if (typeof v !== "number" || !Number.isInteger(v) || v < 1 || v > target) return null;
  let cur: Record<string, unknown> = raw;
  while (v < target) {
    const step = migrations[v];
    if (!step) return null;
    try {
      cur = step(cur);
    } catch {
      return null;
    }
    if (!isObj(cur)) return null;
    v++;
    cur = { ...cur, version: v };
  }
  return sanitize(cur);
}

/** Parse stored text. Never throws; anything unusable gives defaults. */
export function parseSave(text: string | null | undefined): SaveData {
  if (!text) return defaultSave();
  try {
    return migrate(JSON.parse(text)) ?? defaultSave();
  } catch {
    return defaultSave();
  }
}

export function serializeSave(d: SaveData): string {
  return JSON.stringify(d);
}

// ---------------------------------------------------------------- pure updates

export function withCheckpoint(d: SaveData, cp: Checkpoint | null): SaveData {
  return { ...d, checkpoint: cp };
}

/** The player started the mission from the beginning. */
export function recordStart(d: SaveData, mission = MISSION_ID): SaveData {
  const m = d.missions[mission] ?? defaultMission();
  return { ...d, checkpoint: "start", missions: { ...d.missions, [mission]: { ...m, attempts: m.attempts + 1 } } };
}

export interface RunResult {
  /** seconds of play */
  time: number;
  /** guards that went fully alert */
  alerts: number;
  /** the run began at the mission start, not at a later checkpoint; only those can set bests */
  fromStart: boolean;
}

export interface WinOutcome {
  data: SaveData;
  rating: number;
  newBestTime: boolean;
  newBestRating: boolean;
}

/** Mission escaped: mark complete, update bests (full runs only) and reset the checkpoint to the start. */
export function recordWin(d: SaveData, r: RunResult, mission = MISSION_ID): WinOutcome {
  const m = d.missions[mission] ?? defaultMission();
  const rating = stealthRating(r.alerts);
  const time = Number.isFinite(r.time) && r.time > 0 ? r.time : null;
  const newBestTime = r.fromStart && time !== null && (m.bestTime === null || time < m.bestTime);
  const newBestRating = r.fromStart && (m.bestRating === null || rating > m.bestRating);
  const next: MissionStats = {
    ...m,
    completed: true,
    bestTime: newBestTime ? time : m.bestTime,
    bestRating: newBestRating ? rating : m.bestRating,
  };
  return { data: { ...d, checkpoint: "start", missions: { ...d.missions, [mission]: next } }, rating, newBestTime, newBestRating };
}

/** The intro has been shown or skipped. */
export function markIntroSeen(d: SaveData): SaveData {
  return d.seenIntro ? d : { ...d, seenIntro: true };
}

/** The intro plays automatically before the first mission only. */
export function shouldShowIntro(d: SaveData): boolean {
  return !d.seenIntro;
}

/** Clear progress and stats (including the seen-intro flag) but keep the player's settings. */
export function resetProgress(d: SaveData): SaveData {
  return { ...defaultSave(), settings: d.settings };
}

export function updateSettings(d: SaveData, patch: Partial<SaveSettings>): SaveData {
  return { ...d, settings: cleanSettings({ ...d.settings, ...patch }) };
}

/** Continue is offered only when the player has actually started the mission. */
export function hasProgress(d: SaveData): boolean {
  return d.checkpoint !== null;
}

// ---------------------------------------------------------------- export / import code

function toB64(s: string): string {
  if (typeof btoa === "function") return btoa(s);
  return Buffer.from(s, "binary").toString("base64");
}
function fromB64(s: string): string {
  if (typeof atob === "function") return atob(s);
  return Buffer.from(s, "base64").toString("binary");
}

/** Base64 of the save JSON (all ASCII: only numbers, booleans and enum strings are stored). */
export function exportCode(d: SaveData): string {
  return toB64(serializeSave(d));
}

/** Validate and decode a pasted code. Returns null on anything invalid. */
export function importCode(code: string): SaveData | null {
  const c = code.trim().replace(/\s+/g, "");
  if (!c || c.length > 20000 || !/^[A-Za-z0-9+/]+={0,2}$/.test(c)) return null;
  try {
    return migrate(JSON.parse(fromB64(c)));
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------- store

export interface StorageLike {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}

/** localStorage if it exists and works, else null. Never throws. */
export function browserStorage(): StorageLike | null {
  try {
    if (typeof window === "undefined") return null;
    const s = window.localStorage;
    if (!s) return null;
    const probe = "keris:probe";
    s.setItem(probe, "1");
    s.removeItem(probe);
    return s;
  } catch {
    return null;
  }
}

/**
 * Holds the current save, mirrors it to storage on every change, and exposes subscribe/getSnapshot for
 * React's useSyncExternalStore. If storage is missing or throws, it keeps working in memory.
 */
export class SaveStore {
  private data: SaveData;
  private listeners = new Set<() => void>();
  /** true when writes are not reaching storage (blocked, full, or unavailable) */
  persistent: boolean;

  constructor(
    private storage: StorageLike | null,
    private key = SAVE_KEY,
  ) {
    this.persistent = storage !== null;
    this.data = this.read();
  }

  private read(): SaveData {
    if (!this.storage) return defaultSave();
    try {
      return parseSave(this.storage.getItem(this.key));
    } catch {
      this.persistent = false;
      return defaultSave();
    }
  }

  private write() {
    if (!this.storage) return;
    try {
      this.storage.setItem(this.key, serializeSave(this.data));
    } catch {
      this.persistent = false; // quota or blocked: keep the in-memory copy
    }
  }

  readonly subscribe = (cb: () => void) => {
    this.listeners.add(cb);
    return () => {
      this.listeners.delete(cb);
    };
  };

  /** Immutable snapshot; the object identity changes on every update. */
  readonly getSnapshot = (): SaveData => this.data;

  get(): SaveData {
    return this.data;
  }

  set(next: SaveData) {
    this.data = next;
    this.write();
    this.listeners.forEach((l) => l());
  }

  update(fn: (d: SaveData) => SaveData) {
    this.set(fn(this.data));
  }

  /** Wipe progress and stats; settings are kept. */
  reset() {
    this.set(resetProgress(this.data));
  }

  /** Replace everything from an export code. Returns false (and changes nothing) if the code is invalid. */
  importFrom(code: string): boolean {
    const d = importCode(code);
    if (!d) return false;
    this.set(d);
    return true;
  }

  exportCode(): string {
    return exportCode(this.data);
  }
}

let shared: SaveStore | null = null;
/** The page-wide store, created on first use in the browser. */
export function getSaveStore(): SaveStore {
  if (!shared) shared = new SaveStore(browserStorage());
  return shared;
}
