import { describe, expect, it } from "vitest";
import { simulate, solve } from "@algomind/level-contract";
import { achievementRuleSchema } from "../src/modules/achievements/achievement-rules.js";
import { DEFAULT_ACHIEVEMENTS } from "../src/modules/achievements/default-achievements.js";
import { analyzeLevel } from "../src/modules/levels/level-analysis.js";
import { newCode } from "../src/modules/share/share.service.js";
import { buildLevel } from "../src/modules/seed/seed-level.js";
import { LEVELS, POOL_LEVELS } from "../src/modules/seed/starter-campaign.seed.js";

describe("the daily pool", () => {
  it("has enough levels that a month rarely repeats, with unique slugs and boards", () => {
    expect(POOL_LEVELS.length).toBeGreaterThanOrEqual(15);
    const slugs = POOL_LEVELS.map((l) => l.slug);
    expect(new Set(slugs).size).toBe(slugs.length);
    const boards = POOL_LEVELS.map((l) => l.rows.join("/"));
    expect(new Set(boards).size).toBe(boards.length);
  });

  it("does not reuse a campaign slug or board, so a daily is never a level the player knows", () => {
    const campaignSlugs = new Set(LEVELS.map((l) => l.def.slug));
    const campaignBoards = new Set(LEVELS.map((l) => l.def.rows.join("/")));
    for (const level of POOL_LEVELS) {
      expect(campaignSlugs.has(level.slug), level.slug).toBe(false);
      expect(campaignBoards.has(level.rows.join("/")), level.slug).toBe(false);
    }
  });

  it.each(POOL_LEVELS.map((l) => [l.slug, l] as const))(
    "%s validates, is solved by its reference program, and has a limit equal to par",
    (_slug, def) => {
      const level = buildLevel(def, `pool-${def.slug}`);
      const best = solve(level);
      expect(best).not.toBeNull();
      const analysis = analyzeLevel(level, best!.program);
      expect(analysis.errors).toEqual([]);
      expect(simulate(level, best!.program).status).toBe("SUCCEEDED");
      expect(def.maxCommands).toBe(best!.commands);
      expect(def.maxCommands).toBeLessThanOrEqual(20);
    },
  );

  it("makes every loop level need a loop", () => {
    for (const def of POOL_LEVELS.filter((l) => l.commands.includes("REPEAT"))) {
      const level = buildLevel(def, `pool-${def.slug}`);
      const plain = solve({
        ...level,
        availableCommands: level.availableCommands.filter((c) => c !== "REPEAT"),
      })!;
      expect(plain.commands, def.slug).toBeGreaterThanOrEqual(2 * def.maxCommands);
    }
  });
});

describe("the default badges", () => {
  it("have valid rules, unique slugs, and short text", () => {
    const slugs = DEFAULT_ACHIEVEMENTS.map((b) => b.slug);
    expect(new Set(slugs).size).toBe(slugs.length);
    for (const badge of DEFAULT_ACHIEVEMENTS) {
      expect(achievementRuleSchema.safeParse(badge.rule).success, badge.slug).toBe(true);
      expect(badge.title.length).toBeLessThanOrEqual(40);
      expect(badge.description.length).toBeLessThanOrEqual(140);
    }
  });

  it("only name campaign levels that exist", () => {
    const campaignSlugs = new Set(LEVELS.map((l) => l.def.slug));
    for (const badge of DEFAULT_ACHIEVEMENTS) {
      if (badge.rule.type === "level_solved") {
        expect(campaignSlugs.has(badge.rule.slug), badge.slug).toBe(true);
      }
    }
  });
});

describe("share codes", () => {
  it("are eight characters from a readable alphabet, and do not repeat", () => {
    const seen = new Set<string>();
    for (let i = 0; i < 2000; i += 1) {
      const code = newCode();
      expect(code).toMatch(/^[0-9a-hjkmnp-tv-z]{8}$/);
      seen.add(code);
    }
    expect(seen.size).toBe(2000);
  });
});
