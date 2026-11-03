import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { readJson, removeKey, resetStorageProbe, writeJson } from '../src/core/storage';
import {
  AUDIO_TRACK_KEYS,
  QUIET_BY_DEFAULT,
  SETTINGS_REV,
  defaultSettings,
  sanitizeSettings,
} from '../src/config/settings';
import { ProfileStore, emptyProfile, sanitizeProfile } from '../src/meta/Profile';
import { RunState } from '../src/sim/RunState';
import { runResult } from '../src/meta/Profile';
import { STRINGS } from '../src/i18n/strings';

/** Minimal in-memory Storage, plus a switch to make it throw like Safari private mode. */
class FakeStorage {
  map = new Map<string, string>();
  throwing = false;
  get length(): number {
    return this.map.size;
  }
  getItem(k: string): string | null {
    if (this.throwing) throw new Error('denied');
    return this.map.get(k) ?? null;
  }
  setItem(k: string, v: string): void {
    if (this.throwing) throw new Error('quota');
    this.map.set(k, v);
  }
  removeItem(k: string): void {
    if (this.throwing) throw new Error('denied');
    this.map.delete(k);
  }
  clear(): void {
    this.map.clear();
  }
  key(i: number): string | null {
    return [...this.map.keys()][i] ?? null;
  }
}

let fake: FakeStorage;

function install(storage: FakeStorage | undefined): void {
  Object.defineProperty(globalThis, 'localStorage', {
    value: storage,
    configurable: true,
    writable: true,
  });
  resetStorageProbe();
}

beforeEach(() => {
  fake = new FakeStorage();
  install(fake);
});

afterEach(() => {
  install(undefined);
});

describe('storage', () => {
  it('round-trips JSON', () => {
    writeJson('k', { a: 1 });
    expect(readJson('k', null)).toEqual({ a: 1 });
  });

  it('falls back when the key is missing or corrupt', () => {
    expect(readJson('nope', 'fallback')).toBe('fallback');
    fake.map.set('tide.bad', '{not json');
    expect(readJson('bad', 'fallback')).toBe('fallback');
  });

  it('never throws when storage is unavailable or denied', () => {
    install(undefined);
    expect(() => writeJson('k', 1)).not.toThrow();
    expect(readJson('k', 7)).toBe(7);

    install(fake);
    fake.throwing = true;
    resetStorageProbe();
    expect(() => writeJson('k', 1)).not.toThrow();
    expect(readJson('k', 7)).toBe(7);
    expect(() => removeKey('k')).not.toThrow();
  });

  it('namespaces its keys so it cannot collide with anything else on the origin', () => {
    writeJson('settings', 1);
    expect([...fake.map.keys()]).toEqual(['tide.settings']);
  });
});

describe('settings', () => {
  it('merges a partial blob onto the defaults', () => {
    const s = sanitizeSettings({
      audio: { movement: { enabled: false, volume: 0.35 } },
    });
    expect(s.audio.movement).toEqual({ enabled: false, volume: 0.35 });
    expect(s.audio.ocean).toEqual(defaultSettings().audio.ocean);
  });

  it('migrates the old sound and music switches into the mixer', () => {
    const s = sanitizeSettings({ sound: false, music: true });
    expect(s.audio.movement.enabled).toBe(false);
    expect(s.audio.objectives.enabled).toBe(false);
    expect(s.audio.danger.enabled).toBe(false);
    expect(s.audio.interface.enabled).toBe(false);
    expect(s.audio.ocean.enabled).toBe(true);
    // ...but `music: true` is a default nobody touched, not a request for the
    // chord, so it lands on today's default rather than switching six slots on.
    expect(s.audio.drone.enabled).toBe(false);
    expect(sanitizeSettings({ music: false }).audio.ocean.enabled).toBe(false);
  });

  /**
   * The one thing a stored blob is not allowed to do: keep a default that has
   * been deliberately withdrawn.
   *
   * Every save on a device predates `rev`, and every one of them was written
   * while the bed's two held layers were on. Without this step the change would
   * reach nobody who had ever opened the game, which is the population it is for.
   */
  it('takes the held layers back once, from a save written before they were', () => {
    const stored = { audio: { drone: { enabled: true }, shimmer: { enabled: true } } };
    const migrated = sanitizeSettings(stored);
    for (const key of QUIET_BY_DEFAULT) expect(migrated.audio[key].enabled, key).toBe(false);
    expect(migrated.rev).toBe(SETTINGS_REV);

    // ...once. A player who switched the chord on *after* the step ran keeps it,
    // which is the whole difference between a migration and a preference.
    const chosen = sanitizeSettings({ ...stored, rev: SETTINGS_REV });
    for (const key of QUIET_BY_DEFAULT) expect(chosen.audio[key].enabled, key).toBe(true);
    // Everything else the old blob said survives the step untouched.
    expect(sanitizeSettings({ rev: 0, muted: true }).muted).toBe(true);
  });

  it('starts every act with the two held layers off and the rest on', () => {
    const { audio } = defaultSettings();
    expect(QUIET_BY_DEFAULT).toEqual(['drone', 'shimmer']);
    for (const key of AUDIO_TRACK_KEYS) {
      expect(audio[key].enabled, key).toBe(!(QUIET_BY_DEFAULT as readonly string[]).includes(key));
      // Off, not turned down: the level is the one a player finds when they
      // press the switch, and it is the same level every other track opens at.
      expect(audio[key].volume, key).toBe(1);
    }
  });

  it('rejects hostile or stale values instead of adopting them', () => {
    const s = sanitizeSettings({
      sound: 'yes',
      audio: {
        ocean: { enabled: 'sometimes', volume: 4 },
        movement: { enabled: false, volume: 'loud' },
      },
      // Keys that were settings once, `lang` among them. A blob written by an
      // older build still carries them, and the merge has to drop them rather
      // than carry them forward into an object nothing will ever read again.
      lang: 'auto',
      quality: 'ultra',
      showHud: null,
      haptics: false,
      extra: 1,
    });
    expect(s.audio.ocean).toEqual({ enabled: true, volume: 1 });
    expect(s.audio.movement).toEqual({ enabled: false, volume: 1 });
    expect('lang' in s).toBe(false);
    expect('quality' in s).toBe(false);
    expect('showHud' in s).toBe(false);
    expect('haptics' in s).toBe(false);
    expect('extra' in s).toBe(false);
  });

  it('survives a non-object', () => {
    expect(sanitizeSettings(null).audio.ocean.enabled).toBe(true);
    expect(sanitizeSettings('nope').audio.interface.enabled).toBe(true);
  });
});

describe('i18n', () => {
  it('has no empty string in the table', () => {
    for (const [key, value] of Object.entries(STRINGS)) {
      if (key === 'zonePrefix') continue;
      expect(value.length, key).toBeGreaterThan(0);
    }
  });
});

describe('profile', () => {
  it('records personal bests and reports which ones broke', () => {
    const store = new ProfileStore(emptyProfile());
    const first = store.record({
      score: 1000,
      depth: 500,
      gates: 4,
      peakShoal: 120,
      zone: 1,
      rescued: 20,
      reforms: 1,
      seconds: 40,
      levelsCleared: 2,
      ringsHeld: 7,
      completed: false,
    });
    expect(first).toEqual({ score: true, depth: true, gates: true });

    const second = store.record({
      score: 900,
      depth: 800,
      gates: 4,
      peakShoal: 100,
      zone: 0,
      rescued: 5,
      reforms: 0,
      seconds: 30,
      levelsCleared: 1,
      ringsHeld: 3,
      completed: false,
    });
    expect(second).toEqual({ score: false, depth: true, gates: false });
    expect(store.profile.bestScore).toBe(1000);
    expect(store.profile.bestDepth).toBe(800);
    expect(store.profile.deepestZone).toBe(1);
    expect(store.profile.runs).toBe(2);
    expect(store.profile.totalRescued).toBe(25);
  });

  it('persists and reloads', () => {
    const store = new ProfileStore(emptyProfile());
    store.record(runResult(Object.assign(new RunState(), { score: 4242, distance: 900 }), 2));
    expect(new ProfileStore().profile.bestScore).toBe(4242);
  });

  it('reset wipes both the object and the stored copy', () => {
    const store = new ProfileStore(emptyProfile());
    store.record(runResult(Object.assign(new RunState(), { score: 10 }), 0));
    store.reset();
    expect(store.profile.runs).toBe(0);
    expect(new ProfileStore().profile.bestScore).toBe(0);
  });

  it('refuses nonsense from storage rather than propagating NaN into the HUD', () => {
    const p = sanitizeProfile({
      bestScore: 'lots',
      bestDepth: -50,
      runs: 3.7,
      seenHints: ['a', 5, 'b'],
      totalSeconds: NaN,
    });
    expect(p.bestScore).toBe(0);
    expect(p.bestDepth).toBe(0);
    expect(p.runs).toBe(3);
    expect(p.seenHints).toEqual(['a', 'b']);
    expect(p.totalSeconds).toBe(0);
  });

  /**
   * The station record has to survive the reload, because the whole of its job is
   * to be there when the player comes back a week later and asks what is left.
   */
  it('persists how far into each act the player has got', () => {
    const store = new ProfileStore(emptyProfile());
    store.recordStations('water', 6);
    store.recordStations('air', 2);
    const reloaded = new ProfileStore().profile;
    expect(reloaded.stations.water).toBe(6);
    expect(reloaded.stations.air).toBe(2);
    expect(reloaded.stations.home).toBe(0);
    // ...and a reset takes it with everything else.
    store.reset();
    expect(new ProfileStore().profile.stations.water).toBe(0);
  });

  it('remembers one-shot hints', () => {
    const store = new ProfileStore(emptyProfile());
    expect(store.hasSeen('drag')).toBe(false);
    store.markSeen('drag');
    store.markSeen('drag');
    expect(store.hasSeen('drag')).toBe(true);
    expect(store.profile.seenHints).toEqual(['drag']);
  });
});
