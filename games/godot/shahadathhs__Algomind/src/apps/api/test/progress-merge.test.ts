import { describe, expect, it } from "vitest";
import {
  mergeCompletion,
  shouldReplaceSettings,
  type StoredCompletion,
} from "../src/modules/me/me.merge.js";

const at = (seconds: number) => new Date(seconds * 1000);
const stored: StoredCompletion = { levelVersion: 1, bestCommands: 6, completedAt: at(500) };

describe("mergeCompletion", () => {
  it("keeps the fewer commands for the same level version", () => {
    const better = mergeCompletion(stored, {
      levelVersion: 1,
      bestCommands: 4,
      completedAt: at(900),
    });
    expect(better).toEqual({
      action: "update",
      data: { levelVersion: 1, bestCommands: 4, completedAt: at(500) },
    });
    expect(
      mergeCompletion(stored, { levelVersion: 1, bestCommands: 9, completedAt: at(900) }),
    ).toEqual({ action: "none" });
  });

  it("lets a newer level version replace the score", () => {
    const result = mergeCompletion(stored, {
      levelVersion: 2,
      bestCommands: 11,
      completedAt: at(900),
    });
    expect(result).toEqual({
      action: "update",
      data: { levelVersion: 2, bestCommands: 11, completedAt: at(500) },
    });
  });

  it("never lets an older level version replace a newer score", () => {
    const newer: StoredCompletion = { levelVersion: 3, bestCommands: 8, completedAt: at(500) };
    expect(
      mergeCompletion(newer, { levelVersion: 1, bestCommands: 2, completedAt: at(900) }),
    ).toEqual({
      action: "none",
    });
  });

  it("always keeps the earliest completion time", () => {
    const result = mergeCompletion(stored, {
      levelVersion: 1,
      bestCommands: 6,
      completedAt: at(100),
    });
    expect(result).toEqual({
      action: "update",
      data: { levelVersion: 1, bestCommands: 6, completedAt: at(100) },
    });
  });

  it("is idempotent: applying the result again changes nothing", () => {
    const incoming = { levelVersion: 2, bestCommands: 5, completedAt: at(100) };
    const first = mergeCompletion(stored, incoming);
    if (first.action !== "update") throw new Error("expected an update");
    expect(mergeCompletion(first.data, incoming)).toEqual({ action: "none" });
  });
});

describe("shouldReplaceSettings", () => {
  it("takes the first settings", () => {
    expect(shouldReplaceSettings(null, at(10))).toBe(true);
  });

  it("takes newer settings and ignores equal or older ones", () => {
    expect(shouldReplaceSettings(at(100), at(200))).toBe(true);
    expect(shouldReplaceSettings(at(100), at(100))).toBe(false);
    expect(shouldReplaceSettings(at(100), at(50))).toBe(false);
  });
});
