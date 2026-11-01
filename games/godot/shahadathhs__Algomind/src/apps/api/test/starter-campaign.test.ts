import { describe, expect, it } from "vitest";
import { simulateAll, solve, type Program } from "@algomind/level-contract";
import { analyzeLevel } from "../src/modules/levels/level-analysis.js";
import { LEVELS, buildLevel } from "../src/modules/seed/starter-campaign.seed.js";
import { CAMPAIGN } from "../src/modules/seed/starter-campaign.data.js";

const built = LEVELS.map((entry) => ({
  ...entry,
  level: buildLevel(entry.def, `test-${entry.def.slug}`),
}));

/** The reference solution: the one in the data (levels with IF), else the exact solver's. */
const referenceOf = (entry: (typeof built)[number]): readonly unknown[] =>
  entry.def.solution ?? solve(entry.level)!.program;

/** The analysis of each level, computed once: it runs the exact solver, which is the slow part. */
const analyses = new Map<string, ReturnType<typeof analyzeLevel>>();
const analysisOf = (entry: (typeof built)[number]) => {
  let analysis = analyses.get(entry.def.slug);
  if (!analysis) {
    analysis = analyzeLevel(entry.level, referenceOf(entry));
    analyses.set(entry.def.slug, analysis);
  }
  return analysis;
};

describe("the starter campaign", () => {
  it("has twenty worlds, forty-eight chapters, and one hundred thirteen levels in a fixed order", () => {
    expect(CAMPAIGN.worlds.map((w) => w.title)).toEqual([
      "Basics",
      "Routes",
      "Loops",
      "Until",
      "Decisions",
      "Wall follower",
      "Procedures",
      "Debug",
      "Generalize",
      "Counters",
      "Memory",
      "Sweep",
      "Patrol",
      "Keys",
      "Delivery",
      "Switches",
      "Ice and belts",
      "Teleporters",
      "Recursion",
      "Capstone",
    ]);
    expect(CAMPAIGN.worlds.flatMap((w) => w.chapters.map((c) => c.title))).toEqual([
      "Moves",
      "Turns",
      "Detours",
      "Budgets",
      "Repeat",
      "Patterns",
      "Run to the wall",
      "Corridors",
      "Look",
      "Both sides",
      "Right hand",
      "Other ways",
      "Name it",
      "Parts",
      "Counts and ends",
      "Branches and parts",
      "Sizes",
      "Shapes",
      "Growing",
      "Spirals",
      "Breadcrumbs",
      "Dead ends",
      "Rooms",
      "Halls",
      "Dodge",
      "Rings",
      "Two guards",
      "First keys",
      "Two doors",
      "Guarded",
      "First parcels",
      "Two parcels",
      "In the way",
      "First switches",
      "Two gates",
      "In the way",
      "Ice",
      "Belts",
      "Together",
      "First pairs",
      "Two pairs",
      "With a guard",
      "Calling itself",
      "Conditions",
      "After the call",
      "Two ideas",
      "Guarded",
      "All together",
    ]);
    expect(LEVELS).toHaveLength(113);
  });

  it("gives every Patrol level guards, and no other level any", () => {
    for (const entry of built) {
      // The Capstone mixes these tools on purpose; its own test checks it.
      if (entry.world.title === "Capstone") continue;
      const patrol =
        entry.world.title === "Patrol" ||
        entry.chapterTitle === "Guarded" ||
        entry.def.slug === "guarded-parcel" ||
        entry.def.slug === "gate-and-guard" ||
        entry.def.slug === "belts-and-a-guard" ||
        entry.def.slug === "guarded-portal";
      expect(entry.def.patrols !== undefined, entry.def.slug).toBe(patrol);
      if (!patrol) continue;
      // The guards matter: the shortest program without them fails, and the limit is the exact par.
      const bare = solve({ ...entry.level, patrols: undefined })!;
      expect(simulateAll(entry.level, bare.program as Program).status, entry.def.slug).toBe(
        "FAILED",
      );
      expect(entry.def.maxCommands, entry.def.slug).toBe(analysisOf(entry).par!.commands);
    }
  });

  it("gives every Keys level a lock, and the shortest program that ignores them fails", () => {
    for (const entry of built) {
      // The Capstone mixes these tools on purpose; its own test checks it.
      if (entry.world.title === "Capstone") continue;
      const keys = entry.world.title === "Keys" || entry.def.slug === "behind-the-door";
      expect(entry.def.locks !== undefined, entry.def.slug).toBe(keys);
      if (!keys) continue;
      const bare = solve({ ...entry.level, locks: undefined, patrols: undefined })!;
      expect(simulateAll(entry.level, bare.program as Program).status, entry.def.slug).toBe(
        "FAILED",
      );
      expect(entry.def.maxCommands, entry.def.slug).toBe(analysisOf(entry).par!.commands);
      // Only the last chapter has a guard.
      expect(entry.def.patrols !== undefined, entry.def.slug).toBe(
        entry.chapterTitle === "Guarded",
      );
    }
  });

  it("gives every Delivery level a crate, and the shortest program that ignores them fails", () => {
    for (const entry of built) {
      // The Capstone mixes these tools on purpose; its own test checks it.
      if (entry.world.title === "Capstone") continue;
      const delivery = entry.world.title === "Delivery" || entry.def.slug === "gate-and-crate";
      expect(entry.def.deliveries !== undefined, entry.def.slug).toBe(delivery);
      if (!delivery) continue;
      const bare = solve({
        ...entry.level,
        deliveries: undefined,
        locks: undefined,
        switches: undefined,
        patrols: undefined,
      })!;
      expect(simulateAll(entry.level, bare.program as Program).status, entry.def.slug).toBe(
        "FAILED",
      );
      expect(entry.def.maxCommands, entry.def.slug).toBe(analysisOf(entry).par!.commands);
    }
  });

  it("gives every Switches level a switch, and the shortest program that ignores them fails", () => {
    for (const entry of built) {
      // The Capstone mixes these tools on purpose; its own test checks it.
      if (entry.world.title === "Capstone") continue;
      const switches = entry.world.title === "Switches";
      expect(entry.def.switches !== undefined, entry.def.slug).toBe(switches);
      if (!switches) continue;
      const bare = solve({
        ...entry.level,
        switches: undefined,
        deliveries: undefined,
        patrols: undefined,
      })!;
      expect(simulateAll(entry.level, bare.program as Program).status, entry.def.slug).toBe(
        "FAILED",
      );
      expect(entry.def.maxCommands, entry.def.slug).toBe(analysisOf(entry).par!.commands);
    }
  });

  it("gives every Ice and belts level ice or belts, and the shortest program that ignores them fails", () => {
    for (const entry of built) {
      // The Capstone mixes these tools on purpose; its own test checks it.
      if (entry.world.title === "Capstone") continue;
      const floor = entry.world.title === "Ice and belts";
      expect((entry.def.ice ?? entry.def.belts) !== undefined, entry.def.slug).toBe(floor);
      if (!floor) continue;
      const bare = solve({ ...entry.level, ice: undefined, belts: undefined, patrols: undefined })!;
      expect(simulateAll(entry.level, bare.program as Program).status, entry.def.slug).toBe(
        "FAILED",
      );
      expect(entry.def.maxCommands, entry.def.slug).toBe(analysisOf(entry).par!.commands);
    }
  });

  it("gives every Teleporters level a pair, and the shortest program that ignores them fails", () => {
    for (const entry of built) {
      // The Capstone mixes these tools on purpose; its own test checks it.
      if (entry.world.title === "Capstone") continue;
      const portals = entry.world.title === "Teleporters";
      expect(entry.def.teleports !== undefined, entry.def.slug).toBe(portals);
      if (!portals) continue;
      const bare = solve({ ...entry.level, teleports: undefined, patrols: undefined })!;
      expect(simulateAll(entry.level, bare.program as Program).status, entry.def.slug).toBe(
        "FAILED",
      );
      expect(entry.def.maxCommands, entry.def.slug).toBe(analysisOf(entry).par!.commands);
    }
  });

  it("makes every Recursion level call a procedure from its own body, with a sensor as the base case", () => {
    for (const entry of built.filter((b) => b.world.title === "Recursion")) {
      expect(entry.def.requires, entry.def.slug).toEqual(["recursion"]);
      const proc = (referenceOf(entry) as Program).find((n) => n.op === "PROC") as
        { body: { op: string; when?: string }[] } | undefined;
      const inner = (proc?.body ?? []).filter((n) => n.op === "CALL");
      expect(inner.length, entry.def.slug).toBeGreaterThan(0);
      expect(
        inner.some((n) => n.when !== undefined),
        entry.def.slug,
      ).toBe(true);
    }
  });

  it("makes every Capstone level a mix: at least two board tools, each one needed, and a guard on five", () => {
    const fields = [
      "locks",
      "deliveries",
      "switches",
      "ice",
      "belts",
      "teleports",
      "patrols",
    ] as const;
    const capstone = built.filter((b) => b.world.title === "Capstone");
    expect(capstone).toHaveLength(8);
    expect(capstone.filter((b) => b.def.patrols !== undefined)).toHaveLength(5);
    for (const entry of capstone) {
      const present = fields.filter((f) => entry.def[f] !== undefined);
      expect(present.length, entry.def.slug).toBeGreaterThanOrEqual(2);
      const par = analysisOf(entry).par!.commands;
      expect(entry.def.maxCommands, entry.def.slug).toBe(par);
      // Leaving any one tool out gives a shorter way: each is needed.
      for (const field of present) {
        const without = solve({ ...entry.level, [field]: undefined });
        expect(
          without !== null && without.commands < par,
          `${entry.def.slug} without ${field}`,
        ).toBe(true);
      }
      const bare = solve(
        Object.fromEntries(
          Object.entries(entry.level).filter(([k]) => !(fields as readonly string[]).includes(k)),
        ) as typeof entry.level,
      )!;
      expect(simulateAll(entry.level, bare.program as Program).status, entry.def.slug).toBe(
        "FAILED",
      );
    }
  });

  it("uses each slug, title, and board once", () => {
    const unique = (values: string[]) => new Set(values).size === values.length;
    expect(unique(LEVELS.map((l) => l.def.slug))).toBe(true);
    expect(unique(LEVELS.map((l) => l.def.title))).toBe(true);
    expect(unique(LEVELS.map((l) => l.def.rows.join("/")))).toBe(true);
  });

  it.each(built.map((b) => [b.def.slug, b] as const))(
    "%s validates, is solved by its reference program, and has a limit at or above par",
    (_slug, entry) => {
      const program = referenceOf(entry);
      const analysis = analysisOf(entry);
      expect(analysis.errors).toEqual([]);
      expect(analysis.referenceSolved).toBe(true);
      expect(simulateAll(entry.level, program as Program).status).toBe("SUCCEEDED");
      expect(entry.def.maxCommands).toBeGreaterThanOrEqual(analysis.par!.commands);
    },
  );

  it.each(built.map((b) => [b.def.slug, b] as const))(
    "%s offers only the commands it needs, and hints that fit",
    (_slug, entry) => {
      const used = new Set<string>();
      const walk = (node: { op: string; body?: unknown[]; then?: unknown[]; else?: unknown[] }) => {
        used.add(node.op === "CALL" ? "PROC" : node.op);
        for (const list of [node.body, node.then, node.else]) {
          for (const inner of (list ?? []) as (typeof node)[]) walk(inner);
        }
      };
      for (const node of referenceOf(entry) as Program) walk(node);
      // Every offered command is a real choice: the shortest program does not have to use all of
      // them, but none may be missing.
      for (const op of used) expect(entry.def.commands).toContain(op);
      // Each loop and decision belongs to its world: Repeat to world 3, Repeat until to worlds 4 and 5,
      // If to world 5, none of them earlier.
      const world = entry.world.title;
      const all = world === "Generalize" || world === "Debug";
      const decide = world === "Decisions" || world === "Wall follower";
      const later = ["Counters", "Memory", "Sweep"].includes(world);
      expect(entry.def.commands.includes("REPEAT")).toBe(
        world === "Loops" || world === "Procedures" || world === "Counters" || all,
      );
      expect(entry.def.commands.includes("REPEAT_UNTIL")).toBe(
        world === "Until" || decide || later || all,
      );
      expect(entry.def.commands.includes("IF")).toBe(
        decide || world === "Memory" || world === "Sweep" || all,
      );
      expect(entry.def.commands.includes("INC")).toBe(world === "Counters");
      expect(entry.def.commands.includes("MARK")).toBe(world === "Memory");
      expect(entry.def.commands.includes("PROC")).toBe(
        world === "Procedures" || world === "Recursion" || all,
      );
      expect(entry.def.hints?.length ?? 0).toBeGreaterThanOrEqual(1);
      expect(entry.def.hints?.length ?? 0).toBeLessThanOrEqual(3);
      for (const hint of entry.def.hints ?? []) expect(hint.length).toBeLessThanOrEqual(140);
    },
  );

  it("offers every movement command from the first level, and each loop only in its world", () => {
    const movement = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"];
    const extra: Record<string, string[]> = {
      Loops: ["REPEAT"],
      Until: ["REPEAT_UNTIL"],
      Decisions: ["REPEAT_UNTIL", "IF"],
      "Wall follower": ["REPEAT_UNTIL", "IF"],
      Procedures: ["REPEAT", "PROC"],
      Recursion: ["PROC"],
      Debug: ["REPEAT", "REPEAT_UNTIL", "IF", "PROC"],
      Generalize: ["REPEAT", "REPEAT_UNTIL", "IF", "PROC"],
      Counters: ["REPEAT", "REPEAT_UNTIL", "INC"],
      Memory: ["REPEAT_UNTIL", "IF", "MARK"],
      Sweep: ["REPEAT_UNTIL", "IF"],
    };
    for (const entry of built) {
      const expected = [...movement, ...(extra[entry.world.title] ?? [])];
      expect(entry.def.commands, entry.def.slug).toEqual(expected);
    }
  });

  it("gives the Budgets chapter and the loop worlds exactly the shortest program", () => {
    for (const entry of built) {
      const par = analysisOf(entry).par!.commands;
      const world = entry.world.title;
      const chapter = entry.chapterTitle;
      if (world === "Debug") {
        // The limit fits the broken program and its fix; par is the best program there is.
        expect(entry.def.maxCommands, entry.def.slug).toBeGreaterThanOrEqual(par);
      } else if (chapter === "Budgets" || !["Routes"].includes(world)) {
        expect(entry.def.maxCommands, entry.def.slug).toBe(par);
      } else {
        expect(entry.def.maxCommands, entry.def.slug).toBeGreaterThan(par);
      }
    }
  });

  it("keeps every limit within what fits on a phone", () => {
    // The Tremaux search is 21 slots and is the point of the Memory world, so it gets four more.
    for (const entry of built) {
      const limit = entry.world.title === "Memory" ? 24 : 20;
      expect(entry.def.maxCommands, entry.def.slug).toBeLessThanOrEqual(limit);
    }
  });

  // The plain program must be longer than the limit, and by how much depends on the loop: a counted
  // loop saves at least half, a loop that runs to the wall also pays for the turns between runs.
  const loopWorlds = [
    { world: "Loops", ratio: 2, strip: ["REPEAT", "REPEAT_UNTIL"], uses: "REPEAT" },
    { world: "Until", ratio: 1.5, strip: ["REPEAT", "REPEAT_UNTIL"], uses: "REPEAT_UNTIL" },
    { world: "Decisions", ratio: 1.5, strip: ["IF"], uses: "IF" },
    { world: "Wall follower", ratio: 1.5, strip: ["IF"], uses: "IF" },
    { world: "Procedures", ratio: 1.3, strip: ["PROC"], uses: "PROC" },
    { world: "Recursion", ratio: 1.3, strip: ["PROC"], uses: "PROC" },
    { world: "Counters", ratio: 2, strip: ["INC"], uses: "INC" },
  ];

  it.each(loopWorlds)("makes every $world level need its tool", ({ world, ratio, strip }) => {
    for (const entry of built.filter((b) => b.world.title === world)) {
      const plain = solve({
        ...entry.level,
        availableCommands: entry.level.availableCommands.filter((c) => !strip.includes(c)),
      })!;
      expect(plain.commands, entry.def.slug).toBeGreaterThan(entry.def.maxCommands);
      // The tool is not a marginal gain.
      expect(plain.commands, entry.def.slug).toBeGreaterThanOrEqual(ratio * entry.def.maxCommands);
    }
  });

  it.each(loopWorlds)(
    "solves every $world level with a program that uses its tool",
    ({ world, uses }) => {
      const has = (list: readonly unknown[]): boolean =>
        (list as { op: string; body?: unknown[] }[]).some(
          (node) => node.op === uses || (node.body ? has(node.body) : false),
        );
      for (const entry of built.filter((b) => b.world.title === world)) {
        expect(has(referenceOf(entry)), entry.def.slug).toBe(true);
      }
    },
  );

  it("gives every level with a reference solution step room for twice its longest run", () => {
    for (const entry of built.filter((b) => b.def.solution && b.world.title !== "Sweep")) {
      const run = simulateAll(entry.level, referenceOf(entry) as Program);
      const longest = Math.max(...run.results.map((r) => r.steps));
      expect(longest * 2, entry.def.slug).toBeLessThanOrEqual(entry.level.constraints.maxSteps);
    }
  });

  it("gives every Sweep level a tight step budget: wandering runs out, the reference run fits", () => {
    for (const entry of built.filter((b) => b.world.title === "Sweep")) {
      const run = simulateAll(entry.level, referenceOf(entry) as Program);
      expect(run.status, entry.def.slug).toBe("SUCCEEDED");
      const longest = Math.max(...run.results.map((r) => r.steps));
      expect(entry.level.constraints.maxSteps, entry.def.slug).toBeGreaterThanOrEqual(longest);
      expect(entry.level.constraints.maxSteps, entry.def.slug).toBeLessThanOrEqual(
        Math.ceil(longest * 1.3),
      );
      expect(entry.level.goal.type, entry.def.slug).toBe("visit_all");
    }
  });

  it("makes every Memory level a maze with loops, where a hand on the wall never arrives", () => {
    const rightHand = [
      {
        op: "REPEAT_UNTIL",
        until: "GOAL",
        body: [
          { op: "IF", when: "CLEAR_RIGHT", then: [{ op: "TURN_RIGHT" }], else: [] },
          {
            op: "IF",
            when: "CLEAR_AHEAD",
            then: [{ op: "MOVE_FORWARD" }],
            else: [{ op: "TURN_LEFT" }],
          },
        ],
      },
    ] as Program;
    for (const entry of built.filter((b) => b.world.title === "Memory")) {
      expect(simulateAll(entry.level, rightHand).status, entry.def.slug).toBe("FAILED");
    }
  });

  it("gives every Generalize level boards that a first-board program cannot cheat", () => {
    for (const entry of built.filter((b) => b.world.title === "Generalize")) {
      const boards = entry.level.extraBoards ?? [];
      expect(boards.length, entry.def.slug).toBeGreaterThanOrEqual(1);
      expect(boards.length, entry.def.slug).toBeLessThanOrEqual(3);
      // The best program for the level's own board alone must fail on another board.
      const own = solve({ ...entry.level, extraBoards: undefined })!;
      expect(simulateAll(entry.level, own.program).status, entry.def.slug).toBe("FAILED");
    }
  });
});
