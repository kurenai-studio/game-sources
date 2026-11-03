import { describe, expect, it } from "vitest";
import { deadzone, diffButtons, pickPad, readPad } from "./gamepad";

const btn = (pressed: boolean, value = pressed ? 1 : 0) => ({ pressed, value });

describe("deadzone", () => {
  it("zeroes small drift", () => {
    expect(deadzone(0.1, 0.05)).toEqual({ x: 0, y: 0 });
  });
  it("full deflection stays full", () => {
    expect(deadzone(1, 0).x).toBeCloseTo(1);
  });
  it("rescales from the edge", () => {
    const v = deadzone(0.2, 0);
    expect(v.x).toBeGreaterThan(0);
    expect(v.x).toBeLessThan(0.1);
  });
});

describe("readPad", () => {
  it("left stick up is forward, right stick drives look", () => {
    const s = readPad({ axes: [0, -1, 1, 0], buttons: [] });
    expect(s.move.y).toBeCloseTo(1);
    expect(s.look.x).toBeCloseTo(1);
  });
  it("analog triggers count as pressed past half", () => {
    const s = readPad({ axes: [], buttons: [btn(false, 0.3), btn(false, 0.8)] });
    expect(s.buttons).toEqual([false, true]);
  });
});

describe("diffButtons", () => {
  it("reports edges only", () => {
    expect(diffButtons([true, false, true], [true, true, false])).toEqual({ down: [1], up: [2] });
  });
});

describe("pickPad", () => {
  it("prefers a standard-mapped pad and skips disconnected slots", () => {
    const a = { connected: true, mapping: "" };
    const b = { connected: true, mapping: "standard" };
    expect(pickPad([null, a, b])).toBe(b);
    expect(pickPad([{ connected: false, mapping: "standard" }, a])).toBe(a);
    expect(pickPad([null])).toBeNull();
  });
});
