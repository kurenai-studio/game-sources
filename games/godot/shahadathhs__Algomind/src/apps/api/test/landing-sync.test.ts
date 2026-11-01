import { describe, expect, it } from "vitest";
// The landing page's drawings are computed from a copy of one real level and one real world.
// These imports read that copy (plain data, no imports) so a change to the seed must update it.
import { LANDING_LEVEL, LANDING_WORLD } from "../../web/src/lib/landing-level.js";
import { CAMPAIGN } from "../src/modules/seed/starter-campaign.data.js";
import { LEVELS, buildLevel } from "../src/modules/seed/starter-campaign.seed.js";

const entry = LEVELS.find((l) => l.def.slug === LANDING_LEVEL.level.slug);

describe("the landing page matches the seed", () => {
  it("draws a level that exists in the campaign", () => {
    expect(entry, "the landing level is no longer in the seed").toBeDefined();
  });

  it("copies that level's board, start, goal, commands, limit, and title", () => {
    const real = buildLevel(entry!.def, LANDING_LEVEL.level.levelId);
    expect(LANDING_LEVEL.level.board).toEqual(real.board);
    expect(LANDING_LEVEL.level.initialState).toEqual(real.initialState);
    expect(LANDING_LEVEL.level.goal).toEqual(real.goal);
    expect(LANDING_LEVEL.level.availableCommands).toEqual(real.availableCommands);
    expect(LANDING_LEVEL.level.constraints.maxCommands).toBe(real.constraints.maxCommands);
    expect(LANDING_LEVEL.level.title).toBe(real.title);
  });

  it("shows the level's real number in the campaign", () => {
    const number = LEVELS.findIndex((l) => l.def.slug === LANDING_LEVEL.level.slug) + 1;
    expect(LANDING_LEVEL.number).toBe(number);
  });

  it("draws world 2 with its real title, summary, chapters, and first level number", () => {
    const world = CAMPAIGN.worlds[LANDING_WORLD.number - 1]!;
    expect(LANDING_WORLD.title).toBe(world.title);
    expect(LANDING_WORLD.summary).toBe(world.description);
    expect(LANDING_WORLD.chapters).toEqual(
      world.chapters.map((c) => ({ title: c.title, levels: c.levels.length })),
    );
    const before = CAMPAIGN.worlds
      .slice(0, LANDING_WORLD.number - 1)
      .reduce((n, w) => n + w.chapters.reduce((m, c) => m + c.levels.length, 0), 0);
    expect(LANDING_WORLD.first).toBe(before + 1);
  });
});
