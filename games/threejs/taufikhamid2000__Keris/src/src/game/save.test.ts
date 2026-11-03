import { describe, expect, it } from "vitest";
import {
  MISSION_ID,
  SAVE_KEY,
  SAVE_VERSION,
  SaveStore,
  defaultSave,
  exportCode,
  formatTime,
  hasProgress,
  importCode,
  markIntroSeen,
  migrate,
  parseSave,
  ratingLabel,
  recordStart,
  recordWin,
  resetProgress,
  sanitize,
  shouldShowIntro,
  stealthRating,
  updateSettings,
  type StorageLike,
} from "./save";

function memStorage(initial: Record<string, string> = {}): StorageLike & { map: Map<string, string> } {
  const map = new Map(Object.entries(initial));
  return {
    map,
    getItem: (k) => map.get(k) ?? null,
    setItem: (k, v) => void map.set(k, v),
    removeItem: (k) => void map.delete(k),
  };
}
const throwing: StorageLike = {
  getItem: () => {
    throw new Error("blocked");
  },
  setItem: () => {
    throw new Error("blocked");
  },
  removeItem: () => {
    throw new Error("blocked");
  },
};

describe("rating and formatting", () => {
  it("rates by alerts", () => {
    expect(stealthRating(0)).toBe(3);
    expect(stealthRating(1)).toBe(2);
    expect(stealthRating(2)).toBe(2);
    expect(stealthRating(3)).toBe(1);
    expect(stealthRating(NaN)).toBe(3);
  });
  it("formats time and rating", () => {
    expect(formatTime(0)).toBe("0:00");
    expect(formatTime(75.9)).toBe("1:15");
    expect(formatTime(null)).toBe("-");
    expect(formatTime(-3)).toBe("-");
    expect(ratingLabel(3)).toBe("*** Ghost");
    expect(ratingLabel(null)).toBe("-");
  });
});

describe("parseSave / sanitize", () => {
  it("gives defaults for null, empty, garbage and non-objects", () => {
    for (const t of [null, undefined, "", "not json", "[]", "42", "null", '"x"', "{"]) expect(parseSave(t as string)).toEqual(defaultSave());
  });
  it("round-trips a valid save", () => {
    const d = recordWin(recordStart(defaultSave()), { time: 120, alerts: 0, fromStart: true }).data;
    expect(parseSave(JSON.stringify(d))).toEqual(d);
  });
  it("falls back per field and drops unknown fields", () => {
    const d = parseSave(
      JSON.stringify({
        version: 1,
        checkpoint: "nowhere",
        evil: 1,
        settings: { quality: "ultra", lookSens: 999, invertY: "yes" },
        missions: { [MISSION_ID]: { completed: "x", attempts: -5, bestTime: -1, bestRating: 99 } },
      }),
    );
    expect(d.checkpoint).toBeNull();
    expect(d.settings).toEqual({ quality: "auto", lookSens: 2.5, invertY: false });
    expect(d.missions[MISSION_ID]).toEqual({ completed: false, attempts: 0, bestTime: null, bestRating: 3 });
    expect("evil" in d).toBe(false);
  });
  it("sanitize of junk is defaults", () => {
    expect(sanitize(5)).toEqual(defaultSave());
  });
});

describe("versioning and migration", () => {
  it("rejects missing, bad and newer versions", () => {
    expect(migrate({})).toBeNull();
    expect(migrate({ version: "1" })).toBeNull();
    expect(migrate({ version: 0 })).toBeNull();
    expect(migrate({ version: 1.5 })).toBeNull();
    expect(migrate({ version: SAVE_VERSION + 1, checkpoint: "kapitan" })).toBeNull();
    expect(parseSave(JSON.stringify({ version: SAVE_VERSION + 1, checkpoint: "kapitan" }))).toEqual(defaultSave());
  });
  it("runs a migration chain in order", () => {
    const seen: number[] = [];
    const migrations = {
      1: (o: Record<string, unknown>) => (seen.push(1), { ...o, checkpoint: "kapitan" }),
      2: (o: Record<string, unknown>) => (seen.push(2), { ...o, settings: { quality: "low" } }),
    };
    const d = migrate({ version: 1 }, migrations, 3);
    expect(seen).toEqual([1, 2]);
    expect(d?.checkpoint).toBe("kapitan");
    expect(d?.settings.quality).toBe("low");
    expect(d?.version).toBe(SAVE_VERSION);
  });
  it("returns null for a missing or throwing step", () => {
    expect(migrate({ version: 1 }, {}, 2)).toBeNull();
    expect(
      migrate(
        { version: 1 },
        {
          1: () => {
            throw new Error("x");
          },
        },
        2,
      ),
    ).toBeNull();
  });
});

describe("recording progress", () => {
  it("recordStart sets the checkpoint and counts attempts", () => {
    const d = recordStart(recordStart(defaultSave()));
    expect(d.checkpoint).toBe("start");
    expect(d.missions[MISSION_ID].attempts).toBe(2);
    expect(hasProgress(d)).toBe(true);
    expect(hasProgress(defaultSave())).toBe(false);
  });
  it("recordWin keeps only better bests", () => {
    const a = recordWin(recordStart(defaultSave()), { time: 200, alerts: 3, fromStart: true });
    expect(a.newBestTime && a.newBestRating).toBe(true);
    expect(a.data.missions[MISSION_ID]).toMatchObject({ completed: true, bestTime: 200, bestRating: 1 });
    const b = recordWin(a.data, { time: 250, alerts: 1, fromStart: true });
    expect(b.newBestTime).toBe(false);
    expect(b.newBestRating).toBe(true);
    expect(b.data.missions[MISSION_ID]).toMatchObject({ bestTime: 200, bestRating: 2 });
    const c = recordWin(b.data, { time: 150, alerts: 5, fromStart: true });
    expect(c.data.missions[MISSION_ID]).toMatchObject({ bestTime: 150, bestRating: 2 });
    expect(c.data.checkpoint).toBe("start");
  });
  it("a run from a later checkpoint completes the mission but sets no bests", () => {
    const r = recordWin(defaultSave(), { time: 30, alerts: 0, fromStart: false });
    expect(r.data.missions[MISSION_ID]).toMatchObject({ completed: true, bestTime: null, bestRating: null });
    expect(r.newBestTime).toBe(false);
  });
  it("does not mutate its input", () => {
    const d = recordStart(defaultSave());
    const snap = JSON.stringify(d);
    recordWin(d, { time: 10, alerts: 0, fromStart: true });
    expect(JSON.stringify(d)).toBe(snap);
  });
  it("updateSettings clamps and validates", () => {
    expect(updateSettings(defaultSave(), { lookSens: 50, quality: "low" }).settings).toMatchObject({ lookSens: 2.5, quality: "low" });
    expect(updateSettings(defaultSave(), { lookSens: -1 }).settings.lookSens).toBe(0.4);
  });
});

describe("reset", () => {
  it("clears progress and stats but keeps settings", () => {
    let d = updateSettings(recordWin(recordStart(defaultSave()), { time: 99, alerts: 0, fromStart: true }).data, { quality: "high", invertY: true });
    d = resetProgress(d);
    expect(d.checkpoint).toBeNull();
    expect(d.missions).toEqual({});
    expect(d.settings).toMatchObject({ quality: "high", invertY: true });
  });
});

describe("export / import code", () => {
  it("round-trips", () => {
    const d = recordWin(recordStart(defaultSave()), { time: 321, alerts: 0, fromStart: true }).data;
    expect(importCode(exportCode(d))).toEqual(d);
    expect(importCode(`  ${exportCode(d)}\n`)).toEqual(d);
  });
  it("rejects invalid, tampered and newer-version codes", () => {
    expect(importCode("")).toBeNull();
    expect(importCode("hello world!")).toBeNull();
    expect(importCode(btoa("not json"))).toBeNull();
    expect(importCode(btoa(JSON.stringify({ version: 99 })))).toBeNull();
    expect(importCode(btoa(JSON.stringify([1, 2])))).toBeNull();
    expect(importCode("A".repeat(30000))).toBeNull();
  });
  it("sanitizes imported values", () => {
    const d = importCode(btoa(JSON.stringify({ version: 1, checkpoint: "kapitan", settings: { lookSens: 1e9 } })));
    expect(d?.checkpoint).toBe("kapitan");
    expect(d?.settings.lookSens).toBe(2.5);
  });
});

describe("SaveStore", () => {
  it("starts with defaults on empty storage and writes under one key", () => {
    const st = memStorage();
    const s = new SaveStore(st);
    expect(s.get()).toEqual(defaultSave());
    s.update((d) => recordStart(d));
    expect([...st.map.keys()]).toEqual([SAVE_KEY]);
    expect(JSON.parse(st.map.get(SAVE_KEY)!).checkpoint).toBe("start");
  });
  it("persists across store instances (reload)", () => {
    const st = memStorage();
    new SaveStore(st).update((d) => updateSettings(recordStart(d), { lookSens: 1.5 }));
    const again = new SaveStore(st);
    expect(again.get().checkpoint).toBe("start");
    expect(again.get().settings.lookSens).toBe(1.5);
  });
  it("survives corrupt and newer stored data", () => {
    expect(new SaveStore(memStorage({ [SAVE_KEY]: "{{{ corrupt" })).get()).toEqual(defaultSave());
    expect(new SaveStore(memStorage({ [SAVE_KEY]: JSON.stringify({ version: 9, checkpoint: "kapitan" }) })).get()).toEqual(defaultSave());
  });
  it("works in memory with no storage or throwing storage", () => {
    for (const st of [null, throwing]) {
      const s = new SaveStore(st);
      expect(() => s.update((d) => recordStart(d))).not.toThrow();
      expect(s.get().checkpoint).toBe("start");
      expect(s.persistent).toBe(false);
      expect(() => s.reset()).not.toThrow();
      expect(s.get().checkpoint).toBeNull();
    }
  });
  it("reset clears progress in storage", () => {
    const st = memStorage();
    const s = new SaveStore(st);
    s.update((d) => recordWin(recordStart(d), { time: 50, alerts: 0, fromStart: true }).data);
    s.reset();
    const again = new SaveStore(st);
    expect(hasProgress(again.get())).toBe(false);
    expect(again.get().missions).toEqual({});
  });
  it("notifies subscribers with a new snapshot identity and supports unsubscribe", () => {
    const s = new SaveStore(null);
    let n = 0;
    const off = s.subscribe(() => n++);
    const before = s.getSnapshot();
    s.update((d) => recordStart(d));
    expect(n).toBe(1);
    expect(s.getSnapshot()).not.toBe(before);
    off();
    s.reset();
    expect(n).toBe(1);
  });
  it("importFrom replaces data only for valid codes", () => {
    const s = new SaveStore(null);
    const code = exportCode(recordStart(defaultSave()));
    expect(s.importFrom("garbage!")).toBe(false);
    expect(s.get().checkpoint).toBeNull();
    expect(s.importFrom(code)).toBe(true);
    expect(s.get().checkpoint).toBe("start");
    expect(importCode(s.exportCode())).toEqual(s.get());
  });
});

describe("seenIntro flag", () => {
  const v1 = (extra: Record<string, unknown> = {}) => ({ version: 1, checkpoint: null, missions: {}, settings: {}, ...extra });
  it("is false by default and shown once", () => {
    expect(defaultSave().seenIntro).toBe(false);
    expect(shouldShowIntro(defaultSave())).toBe(true);
    const seen = markIntroSeen(defaultSave());
    expect(seen.seenIntro).toBe(true);
    expect(shouldShowIntro(seen)).toBe(false);
    expect(markIntroSeen(seen)).toBe(seen);
  });
  it("migrates v1: untouched saves see the intro, players with progress do not", () => {
    expect(migrate(v1())?.seenIntro).toBe(false);
    expect(migrate(v1())?.version).toBe(2);
    expect(migrate(v1({ checkpoint: "start" }))?.seenIntro).toBe(true);
    expect(migrate(v1({ checkpoint: "kapitan" }))?.seenIntro).toBe(true);
    expect(migrate(v1({ missions: { [MISSION_ID]: { attempts: 2 } } }))?.seenIntro).toBe(true);
    expect(migrate(v1({ missions: { [MISSION_ID]: { completed: true, attempts: 0 } } }))?.seenIntro).toBe(true);
    expect(migrate(v1({ missions: { a: "junk" } }))?.seenIntro).toBe(false);
  });
  it("keeps other v1 data when migrating", () => {
    const d = migrate(v1({ checkpoint: "kapitan", settings: { lookSens: 2, invertY: true } }));
    expect(d?.checkpoint).toBe("kapitan");
    expect(d?.settings.lookSens).toBe(2);
    expect(d?.settings.invertY).toBe(true);
  });
  it("loads old v1 stored text and old export codes", () => {
    const old = JSON.stringify(v1({ checkpoint: "start" }));
    expect(parseSave(old).seenIntro).toBe(true);
    expect(importCode(btoa(old))?.seenIntro).toBe(true);
  });
  it("rejects non-boolean values and round-trips through export/import", () => {
    expect(sanitize({ version: 2, seenIntro: "yes" }).seenIntro).toBe(false);
    expect(sanitize({ version: 2, seenIntro: 1 }).seenIntro).toBe(false);
    const d = markIntroSeen(defaultSave());
    expect(importCode(exportCode(d))).toEqual(d);
  });
  it("reset progress clears it but keeps settings", () => {
    const d = updateSettings(markIntroSeen(recordStart(defaultSave())), { lookSens: 2 });
    const r = resetProgress(d);
    expect(r.seenIntro).toBe(false);
    expect(r.settings.lookSens).toBe(2);
    const s = new SaveStore(memStorage());
    s.update(markIntroSeen);
    s.reset();
    expect(s.get().seenIntro).toBe(false);
  });
  it("persists across store instances", () => {
    const st = memStorage();
    new SaveStore(st).update(markIntroSeen);
    expect(new SaveStore(st).get().seenIntro).toBe(true);
  });
});
