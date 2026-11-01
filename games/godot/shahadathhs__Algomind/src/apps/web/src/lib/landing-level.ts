// The real level behind the landing page drawings: "Around the wall", exactly as the seed defines
// it (apps/api/src/modules/seed/starter-campaign.data.ts). Plain data with no imports, so the API
// test `landing-sync.test.ts` can read it and fail when the seed changes and this copy does not.
// The drawings (sample-screens.ts) are computed from it with the contract's solver and simulator.

export const LANDING_LEVEL = {
  number: 6,
  level: {
    schemaVersion: 1,
    levelId: "around-the-wall",
    levelVersion: 1,
    slug: "around-the-wall",
    title: "Around the wall",
    description: "",
    difficulty: "easy",
    requires: {
      mechanics: [],
    },
    board: {
      width: 6,
      height: 6,
      walls: [
        [3, 3],
        [4, 3],
        [5, 3],
      ],
    },
    initialState: {
      position: [5, 5],
      direction: "north",
    },
    availableCommands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"],
    constraints: {
      maxCommands: 13,
      maxSteps: 200,
    },
    goal: {
      type: "reach_tile",
      position: [3, 2],
    },
    hints: [],
  },
} as const;

/** World 2 as the campaign defines it, for the levels-screen drawing. `first` is its first level number. */
export const LANDING_WORLD = {
  number: 2,
  title: "Routes",
  summary: "Look at the whole board, then choose a route.",
  first: 6,
  chapters: [
    {
      title: "Detours",
      levels: 3,
    },
    {
      title: "Budgets",
      levels: 2,
    },
  ],
} as const;
