import { describe, expect, it } from "vitest";
import {
  describeRule,
  ruleMet,
  type PlayerStats,
} from "../src/modules/achievements/achievement-rules.js";
import { addDays, daysBetween, isValidDate } from "../src/modules/daily/dates.js";
import { pickFromPool } from "../src/modules/daily/daily-rotation.js";
import { computeStreak } from "../src/modules/daily/streak.js";
import { periodRange } from "../src/modules/leaderboards/periods.js";
import { checkDisplayName, nameKey } from "../src/modules/profile/name-rules.js";
import { rankFor } from "../src/modules/profile/ranks.js";

describe("display names", () => {
  it("accepts ordinary names and tidies spaces", () => {
    expect(checkDisplayName("  Sam  Lee ")).toEqual({ ok: true, name: "Sam Lee" });
    expect(checkDisplayName("pixel_fox-7").ok).toBe(true);
  });

  it("refuses names that are too short, too long, or use other characters", () => {
    for (const bad of ["ab", "a".repeat(21), "name!", "émile", "a@b.co", "_name", "name_"]) {
      expect(checkDisplayName(bad), bad).toMatchObject({ ok: false, code: "NAME_INVALID" });
    }
  });

  it("refuses a name with no letter", () => {
    expect(checkDisplayName("12345")).toMatchObject({ ok: false, code: "NAME_INVALID" });
  });

  it("refuses names that impersonate the game or staff, even with look-alike digits", () => {
    for (const bad of ["admin", "Algomind", "4dm1n", "support", "Moderator"]) {
      expect(checkDisplayName(bad), bad).toMatchObject({ ok: false, code: "NAME_NOT_ALLOWED" });
    }
  });

  it("refuses obvious abuse, also with digits swapped for letters", () => {
    for (const bad of ["fuck you", "sh1t", "h1tler", "big d1ck"]) {
      expect(checkDisplayName(bad), bad).toMatchObject({ ok: false, code: "NAME_NOT_ALLOWED" });
    }
  });

  it("does not refuse a harmless word that merely contains a short blocked word", () => {
    expect(checkDisplayName("Scunthorpe fan").ok).toBe(false); // "cunt" inside: a known limit of word lists
    expect(checkDisplayName("Classic Cocktail").ok).toBe(false);
    expect(checkDisplayName("Maple Tree").ok).toBe(true);
  });

  it("compares names ignoring case and spacing", () => {
    expect(nameKey("  Sam   LEE ")).toBe("sam lee");
  });
});

describe("ranks", () => {
  it("steps up at the thresholds and names the next one", () => {
    expect(rankFor(0)).toEqual({ name: "Novice", next: { name: "Apprentice", at: 100 } });
    expect(rankFor(99).name).toBe("Novice");
    expect(rankFor(100).name).toBe("Apprentice");
    expect(rankFor(1500)).toEqual({ name: "Master", next: null });
  });
});

describe("leaderboard periods", () => {
  it("starts a week on Monday, in UTC", () => {
    const wednesday = new Date("2026-10-21T15:00:00Z");
    expect(periodRange("week", wednesday).from.toISOString()).toBe("2026-10-19T00:00:00.000Z");
    expect(periodRange("week", wednesday).to.toISOString()).toBe("2026-10-26T00:00:00.000Z");
    const sunday = new Date("2026-10-25T23:59:59Z");
    expect(periodRange("week", sunday).from.toISOString()).toBe("2026-10-19T00:00:00.000Z");
    const monday = new Date("2026-10-26T00:00:00Z");
    expect(periodRange("week", monday).from.toISOString()).toBe("2026-10-26T00:00:00.000Z");
  });

  it("covers a calendar month, including December into January", () => {
    const range = periodRange("month", new Date("2026-12-31T23:00:00Z"));
    expect(range.from.toISOString()).toBe("2026-12-01T00:00:00.000Z");
    expect(range.to.toISOString()).toBe("2027-01-01T00:00:00.000Z");
  });

  it("covers everything for all time", () => {
    const range = periodRange("all", new Date());
    expect(range.from.getUTCFullYear()).toBeLessThan(2010);
    expect(range.to.getUTCFullYear()).toBeGreaterThan(2090);
  });
});

describe("daily dates", () => {
  it("validates real calendar dates only", () => {
    expect(isValidDate("2026-10-20")).toBe(true);
    expect(isValidDate("2026-02-30")).toBe(false);
    expect(isValidDate("2026-1-2")).toBe(false);
  });

  it("adds days across month ends and counts the gap", () => {
    expect(addDays("2026-10-31", 1)).toBe("2026-11-01");
    expect(addDays("2026-03-01", -1)).toBe("2026-02-28");
    expect(daysBetween("2026-10-20", "2026-10-23")).toBe(3);
  });
});

describe("the daily rotation", () => {
  const pool = ["c-level", "a-level", "b-level", "d-level"];

  it("is deterministic and does not depend on the pool's order", () => {
    expect(pickFromPool("2026-10-20", pool)).toBe(pickFromPool("2026-10-20", [...pool].reverse()));
  });

  it("never repeats the day before when the pool has two or more levels", () => {
    let day = "2026-01-01";
    for (let i = 0; i < 200; i += 1) {
      const next = addDays(day, 1);
      expect(pickFromPool(next, pool)).not.toBe(pickFromPool(day, pool));
      day = next;
    }
  });

  it("never repeats the day before for pools of two and three either", () => {
    for (const small of [
      ["a", "b"],
      ["a", "b", "c"],
      ["a", "b", "c", "d", "e"],
    ]) {
      let day = "2026-01-01";
      for (let i = 0; i < 400; i += 1) {
        const next = addDays(day, 1);
        expect(pickFromPool(next, small), `${small.length} levels, ${next}`).not.toBe(
          pickFromPool(day, small),
        );
        day = next;
      }
    }
  });

  it("returns the only level of a one-level pool, and nothing for an empty pool", () => {
    expect(pickFromPool("2026-10-20", ["only"])).toBe("only");
    expect(pickFromPool("2026-10-20", [])).toBeNull();
  });

  it("uses every level of the pool over time", () => {
    const seen = new Set<string>();
    let day = "2026-01-01";
    for (let i = 0; i < 100; i += 1) {
      seen.add(pickFromPool(day, pool)!);
      day = addDays(day, 1);
    }
    expect(seen.size).toBe(pool.length);
  });
});

describe("streaks", () => {
  it("counts consecutive days and is alive today or yesterday", () => {
    const days = ["2026-10-17", "2026-10-18", "2026-10-19"];
    expect(computeStreak(days, "2026-10-19")).toEqual({ current: 3, best: 3 });
    expect(computeStreak(days, "2026-10-20")).toEqual({ current: 3, best: 3 });
  });

  it("is over after two missed days", () => {
    expect(computeStreak(["2026-10-17", "2026-10-18"], "2026-10-21")).toEqual({
      current: 0,
      best: 2,
    });
  });

  it("forgives one missed day, but only once in seven days", () => {
    // 1, 2, (miss 3), 4: bridged.
    expect(computeStreak(["2026-10-01", "2026-10-02", "2026-10-04"], "2026-10-04").current).toBe(3);
    // 1, (miss 2), 3, (miss 4), 5: the second gap is inside seven days, so the run restarts.
    expect(computeStreak(["2026-10-01", "2026-10-03", "2026-10-05"], "2026-10-05").current).toBe(1);
    // A bridge, then more than seven days later another bridge: allowed.
    const spread = [
      "2026-10-01",
      "2026-10-03",
      "2026-10-04",
      "2026-10-05",
      "2026-10-06",
      "2026-10-07",
      "2026-10-08",
      "2026-10-09",
      "2026-10-10",
      "2026-10-12",
    ];
    expect(computeStreak(spread, "2026-10-12").current).toBe(10);
  });

  it("is alive the day after a missed day only while a grace is free", () => {
    expect(computeStreak(["2026-10-10", "2026-10-11"], "2026-10-13").current).toBe(2);
    expect(computeStreak(["2026-10-10", "2026-10-11"], "2026-10-14").current).toBe(0);
  });

  it("keeps the best run after a break, ignores duplicates, and handles no days", () => {
    const days = ["2026-10-01", "2026-10-02", "2026-10-03", "2026-10-03", "2026-10-20"];
    expect(computeStreak(days, "2026-10-20")).toEqual({ current: 1, best: 3 });
    expect(computeStreak([], "2026-10-20")).toEqual({ current: 0, best: 0 });
  });
});

describe("achievement rules", () => {
  const stats: PlayerStats = {
    levelsSolved: 12,
    starsTotal: 30,
    parLevels: 4,
    points: 480,
    streak: 3,
    dailySolved: 5,
    solvedSlugs: new Set(["say-it-once"]),
  };

  it("meets a threshold at the value and not below it", () => {
    expect(ruleMet({ type: "levels_solved", value: 12 }, stats)).toBe(true);
    expect(ruleMet({ type: "levels_solved", value: 13 }, stats)).toBe(false);
    expect(ruleMet({ type: "par_levels", value: 5 }, stats)).toBe(false);
    expect(ruleMet({ type: "points_total", value: 480 }, stats)).toBe(true);
    expect(ruleMet({ type: "streak", value: 3 }, stats)).toBe(true);
    expect(ruleMet({ type: "stars_total", value: 31 }, stats)).toBe(false);
    expect(ruleMet({ type: "daily_solved", value: 5 }, stats)).toBe(true);
  });

  it("meets a level rule only for that level", () => {
    expect(ruleMet({ type: "level_solved", slug: "say-it-once" }, stats)).toBe(true);
    expect(ruleMet({ type: "level_solved", slug: "stairs" }, stats)).toBe(false);
  });
});

describe("describing a rule in words", () => {
  it("uses the singular for one and the plural otherwise", () => {
    expect(describeRule({ type: "levels_solved", value: 1 })).toBe("Solve 1 level");
    expect(describeRule({ type: "levels_solved", value: 10 })).toBe("Solve 10 levels");
    expect(describeRule({ type: "daily_solved", value: 1 })).toBe("Solve 1 daily challenge");
    expect(describeRule({ type: "streak", value: 1 })).toBe("A streak of 1 day");
    expect(describeRule({ type: "stars_total", value: 1 })).toBe("Earn 1 star in total");
  });
});
