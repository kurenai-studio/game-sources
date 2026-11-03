import { describe, expect, it } from "vitest";
import {
  CAMERA_KEYS,
  EDGE_FADE,
  INTRO_CAPTIONS,
  INTRO_DURATION,
  REDUCED_CAPTIONS,
  REDUCED_DURATION,
  advanceIntro,
  cameraAt,
  captionAt,
  fadeAt,
  introDuration,
  isSkipKey,
  skipIntro,
  startIntro,
} from "./intro";

describe("timeline", () => {
  it("is about 15-25 seconds with 3-5 ordered, non-overlapping captions inside it", () => {
    expect(INTRO_DURATION).toBeGreaterThanOrEqual(15);
    expect(INTRO_DURATION).toBeLessThanOrEqual(25);
    for (const caps of [INTRO_CAPTIONS, REDUCED_CAPTIONS]) {
      expect(caps.length).toBeGreaterThanOrEqual(3);
      expect(caps.length).toBeLessThanOrEqual(5);
      caps.forEach((c, i) => {
        expect(c.end).toBeGreaterThan(c.start);
        if (i > 0) expect(c.start).toBeGreaterThanOrEqual(caps[i - 1].end);
      });
    }
    expect(INTRO_CAPTIONS.at(-1)!.end).toBeLessThanOrEqual(INTRO_DURATION);
    expect(REDUCED_CAPTIONS.at(-1)!.end).toBeLessThanOrEqual(REDUCED_DURATION);
    expect(REDUCED_DURATION).toBeLessThan(INTRO_DURATION);
  });
  it("picks the caption for a time, with fades, and null in the gaps", () => {
    expect(captionAt(0)).toBeNull();
    expect(captionAt(INTRO_CAPTIONS[0].start)?.opacity).toBe(0);
    const mid = captionAt((INTRO_CAPTIONS[0].start + INTRO_CAPTIONS[0].end) / 2);
    expect(mid?.index).toBe(0);
    expect(mid?.opacity).toBe(1);
    expect(captionAt(INTRO_CAPTIONS[0].end - 0.1)!.opacity).toBeLessThan(0.5);
    expect(captionAt(5.0)).toBeNull();
    expect(captionAt(12)?.index).toBe(2);
    expect(captionAt(20)?.text).toMatch(/Kapitan/);
    expect(captionAt(INTRO_DURATION)).toBeNull();
    expect(captionAt(3, true)?.index).toBe(1);
  });
  it("fades from black at the start and back to black at the end", () => {
    expect(fadeAt(0)).toBe(1);
    expect(fadeAt(EDGE_FADE)).toBe(0);
    expect(fadeAt(INTRO_DURATION / 2)).toBe(0);
    expect(fadeAt(INTRO_DURATION)).toBe(1);
    expect(fadeAt(REDUCED_DURATION, true)).toBe(1);
  });
});

describe("camera", () => {
  it("starts and ends on the first and last keys and stays finite", () => {
    expect(cameraAt(0).pos).toEqual(CAMERA_KEYS[0].pos);
    expect(cameraAt(INTRO_DURATION).pos).toEqual(CAMERA_KEYS.at(-1)!.pos);
    expect(cameraAt(-5).pos).toEqual(CAMERA_KEYS[0].pos);
    expect(cameraAt(999).look).toEqual(CAMERA_KEYS.at(-1)!.look);
    for (let t = 0; t <= INTRO_DURATION; t += 0.25) {
      const c = cameraAt(t);
      for (const n of [...c.pos, ...c.look]) expect(Number.isFinite(n)).toBe(true);
      expect(c.pos[1]).toBeGreaterThan(0.5); // never under the ground or water
    }
  });
  it("moves smoothly, and not at all in the reduced version", () => {
    const a = cameraAt(8).pos;
    const b = cameraAt(8.1).pos;
    expect(Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2])).toBeLessThan(2);
    expect(cameraAt(1, true)).toEqual(cameraAt(15, true));
  });
});

describe("playback and skip", () => {
  it("advances then finishes exactly at the end", () => {
    let s = startIntro();
    expect(s).toEqual({ t: 0, reduced: false, skipped: false, done: false });
    s = advanceIntro(s, 1.5);
    expect(s.t).toBe(1.5);
    expect(s.done).toBe(false);
    s = advanceIntro(s, 100);
    expect(s).toMatchObject({ t: INTRO_DURATION, done: true, skipped: false });
  });
  it("ignores bad dt and further advances once done", () => {
    let s = startIntro();
    expect(advanceIntro(s, -1).t).toBe(0);
    expect(advanceIntro(s, NaN).t).toBe(0);
    s = skipIntro(s);
    expect(advanceIntro(s, 5)).toBe(s);
  });
  it("skip works at any moment, once", () => {
    for (const t of [0, 0.01, 7, 21.99]) {
      const s = skipIntro({ ...startIntro(), t });
      expect(s).toMatchObject({ done: true, skipped: true, t });
      expect(skipIntro(s)).toBe(s);
    }
    const finished = advanceIntro(startIntro(), 999);
    expect(skipIntro(finished).skipped).toBe(false);
  });
  it("reduced motion uses the shorter timeline", () => {
    expect(introDuration(true)).toBe(REDUCED_DURATION);
    expect(advanceIntro(startIntro(true), 999).t).toBe(REDUCED_DURATION);
  });
  it("Escape, Space and Enter skip; gameplay keys do not", () => {
    for (const k of ["Escape", "Space", "Enter", "NumpadEnter"]) expect(isSkipKey(k)).toBe(true);
    for (const k of ["KeyW", "KeyE", "ShiftLeft", "Tab", ""]) expect(isSkipKey(k)).toBe(false);
  });
});
