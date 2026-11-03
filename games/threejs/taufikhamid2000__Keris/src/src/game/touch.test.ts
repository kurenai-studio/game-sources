import { describe, expect, it } from "vitest";
import { QUALITY, clampToRadius, isTouchDevice, joystickVector, lookDelta, pickQuality, pixelRatioFor, qualityFromUrl, spreadIndices } from "./touch";

describe("joystickVector", () => {
  it("is zero inside the deadzone", () => {
    expect(joystickVector(3, -3, 50)).toEqual({ x: 0, y: 0, mag: 0, run: false });
    expect(joystickVector(0, 0, 50).mag).toBe(0);
  });
  it("maps screen-up to forward and right to strafe right", () => {
    const f = joystickVector(0, -30, 50);
    expect(f.y).toBeGreaterThan(0);
    expect(f.x).toBeCloseTo(0);
    const r = joystickVector(30, 0, 50);
    expect(r.x).toBeGreaterThan(0);
    expect(r.y).toBeCloseTo(0);
    expect(joystickVector(0, 30, 50).y).toBeLessThan(0);
  });
  it("rescales past the deadzone so magnitude starts at 0 and reaches 1", () => {
    const just = joystickVector(50 * 0.19, 0, 50);
    expect(just.mag).toBeGreaterThan(0);
    expect(just.mag).toBeLessThan(0.05);
    expect(joystickVector(50, 0, 50).mag).toBeCloseTo(1);
    expect(joystickVector(500, 0, 50).mag).toBeCloseTo(1);
  });
  it("runs only near the edge", () => {
    expect(joystickVector(30, 0, 50).run).toBe(false);
    expect(joystickVector(48, 0, 50).run).toBe(true);
    expect(joystickVector(0, -200, 50).run).toBe(true);
  });
  it("keeps diagonals at unit length at most", () => {
    const d = joystickVector(100, -100, 50);
    expect(Math.hypot(d.x, d.y)).toBeCloseTo(1);
  });
  it("handles a bad radius", () => {
    expect(joystickVector(10, 10, 0).mag).toBe(0);
  });
});

describe("clampToRadius", () => {
  it("leaves short offsets and clamps long ones", () => {
    expect(clampToRadius(3, 4, 10)).toEqual({ x: 3, y: 4 });
    const c = clampToRadius(30, 40, 10);
    expect(Math.hypot(c.x, c.y)).toBeCloseTo(10);
    expect(c.x / c.y).toBeCloseTo(0.75);
  });
});

describe("lookDelta", () => {
  it("scales by sensitivity", () => {
    expect(lookDelta(10, 5, 2)).toEqual({ dx: 20, dy: 10 });
  });
  it("can invert Y", () => {
    expect(lookDelta(0, 10, 1, true).dy).toBe(-10);
  });
  it("caps runaway deltas", () => {
    expect(lookDelta(10000, -10000, 1.6, false, 120)).toEqual({ dx: 120, dy: -120 });
  });
});

describe("isTouchDevice", () => {
  const base = { coarse: false, fine: true, hasTouchStart: false, maxTouchPoints: 0 };
  it("desktop mouse is not touch", () => {
    expect(isTouchDevice(base)).toBe(false);
  });
  it("coarse pointer is touch", () => {
    expect(isTouchDevice({ ...base, coarse: true, fine: false })).toBe(true);
  });
  it("touchscreen laptop with a fine primary pointer keeps desktop controls", () => {
    expect(isTouchDevice({ ...base, hasTouchStart: true, maxTouchPoints: 10 })).toBe(false);
  });
  it("touch events with no fine pointer is touch", () => {
    expect(isTouchDevice({ ...base, fine: false, hasTouchStart: true })).toBe(true);
    expect(isTouchDevice({ ...base, fine: false, maxTouchPoints: 5 })).toBe(true);
  });
  it("query param overrides", () => {
    expect(isTouchDevice({ ...base, search: "?touch=1" })).toBe(true);
    expect(isTouchDevice({ ...base, coarse: true, fine: false, search: "?touch=0" })).toBe(false);
  });
});

describe("quality", () => {
  it("auto picks low on touch and high otherwise", () => {
    expect(pickQuality(true)).toBe("low");
    expect(pickQuality(false)).toBe("high");
  });
  it("query param wins and ignores junk", () => {
    expect(pickQuality(true, "?quality=high")).toBe("high");
    expect(pickQuality(false, "?quality=low")).toBe("low");
    expect(pickQuality(true, "?quality=ultra")).toBe("low");
  });
  it("caps the pixel ratio", () => {
    expect(pixelRatioFor("low", 3)).toBe(1.5);
    expect(pixelRatioFor("high", 3)).toBe(2);
    expect(pixelRatioFor("low", 1)).toBe(1);
    expect(pixelRatioFor("low", 0)).toBe(1);
  });
  it("low is cheaper than high on every axis", () => {
    const l = QUALITY.low;
    const h = QUALITY.high;
    expect(l.pixelRatioCap).toBeLessThan(h.pixelRatioCap);
    expect(l.shadowMapSize).toBeLessThan(h.shadowMapSize);
    expect(l.fogFar).toBeLessThan(h.fogFar);
    expect(l.lampLights).toBeLessThan(h.lampLights);
    expect(l.antialias).toBe(false);
  });
});

describe("spreadIndices", () => {
  it("picks n distinct, evenly spread indices", () => {
    const s = [...spreadIndices(17, 5)].sort((a, b) => a - b);
    expect(s).toHaveLength(5);
    expect(new Set(s).size).toBe(5);
    expect(Math.max(...s)).toBeLessThan(17);
    expect(s[0]).toBeLessThan(5);
    expect(s[4]).toBeGreaterThan(11);
  });
  it("returns all when n >= total", () => {
    expect(spreadIndices(4, 10).size).toBe(4);
  });
});

describe("pickQuality with a saved preference", () => {
  it("defaults by device when the preference is auto", () => {
    expect(pickQuality(true, "")).toBe("low");
    expect(pickQuality(false, "", "auto")).toBe("high");
  });
  it("a saved low/high beats the device default", () => {
    expect(pickQuality(false, "", "low")).toBe("low");
    expect(pickQuality(true, "", "high")).toBe("high");
  });
  it("the ?quality= param beats the saved value", () => {
    expect(pickQuality(false, "?quality=low", "high")).toBe("low");
    expect(pickQuality(true, "?quality=high", "low")).toBe("high");
    expect(qualityFromUrl("?quality=ultra")).toBeNull();
    expect(pickQuality(true, "?quality=ultra", "high")).toBe("high");
  });
});
