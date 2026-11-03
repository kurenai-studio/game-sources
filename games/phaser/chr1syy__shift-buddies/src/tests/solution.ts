import type { Action, Direction } from "../src/game/rules.ts";

const walk = (direction: Direction, count: number): Action[] =>
  Array.from({ length: count }, () => ({ type: "move", direction }));

// Explicit route, also used as real keyboard input by the browser test.
// Coordinates are zero-based (x / y), as shown on the robot cards.
export const solution = {
  swapAndPower: [
    ...walk("down", 2), { type: "swap" }, ...walk("up", 4),
    { type: "interact" }, // Pip supplies A at 3/3 through the shaft
  ],
  boltToPlate: [
    { type: "switch" }, ...walk("right", 4), // Bolt holds A at 8/7
  ],
  pipToExit: [
    { type: "switch" }, { type: "interact" }, ...walk("down", 4),
    ...walk("right", 4), ...walk("down", 2), ...walk("right", 7),
  ],
  boltToExit: [
    { type: "switch" }, ...walk("right", 7), ...walk("down", 2),
  ],
} satisfies Record<string, Action[]>;

export const fullSolution: Action[] = Object.values(solution).flat();

// Two short introductions. Victory deliberately keeps the supporting buddy at
// work: Bolt on the plate in room 1, Pip supplying power in room 2.
export const bodySolution: Action[] = [
  { type: "switch" }, ...walk("right", 2), { type: "switch" },
  ...walk("up", 2), ...walk("right", 6),
];
export const moduleSolution: Action[] = [
  ...walk("up", 3), ...walk("right", 2),
  { type: "pull", direction: "left" }, { type: "pull", direction: "left" },
  ...walk("down", 4), { type: "swap" },
  ...walk("up", 3), ...walk("right", 2), ...walk("up", 1),
  ...walk("right", 3), { type: "interact" },
  { type: "switch" }, ...walk("right", 3),
];

export const freightSetup: Action[] = [
  { type: "swap" }, ...walk("up", 1), ...walk("right", 4), ...walk("up", 2),
  { type: "interact" }, { type: "switch" }, ...walk("left", 2),
  ...walk("up", 5), ...walk("right", 3), ...walk("down", 1), // blocked turn toward crate
];
export const freightSolution: Action[] = [
  ...freightSetup, { type: "pull", direction: "down" },
  ...walk("left", 3), ...walk("down", 4), ...walk("right", 13), ...walk("down", 1),
  { type: "switch" }, { type: "interact" }, ...walk("down", 3),
  ...walk("right", 7), ...walk("down", 1),
];
export const routesSolution: Action[] = [
  ...walk("down", 2), { type: "swap" }, ...walk("up", 4), { type: "interact" },
  { type: "switch" }, ...walk("right", 4),
  { type: "switch" }, { type: "interact" }, ...walk("down", 4), ...walk("right", 4),
  { type: "swap" }, ...walk("down", 1), ...walk("right", 2), ...walk("up", 1),
  { type: "pull", direction: "down" }, ...walk("right", 1), ...walk("up", 1),
  ...walk("right", 4), ...walk("down", 2), { type: "switch" },
  ...walk("down", 1), ...walk("right", 2), ...walk("up", 1), ...walk("right", 5), ...walk("down", 2),
];
export const bridgeSolution: Action[] = [
  { type: "swap" }, ...walk("up", 2), ...walk("right", 1), { type: "interact" },
  { type: "switch" }, ...walk("right", 1), ...walk("up", 2), ...walk("right", 4),
  { type: "switch" }, { type: "interact" }, ...walk("left", 1), ...walk("down", 4),
  ...walk("right", 6), { type: "interact" }, // Pip helps Bolt through B at 10/9
  { type: "switch" }, ...walk("right", 2), ...walk("down", 3), ...walk("right", 2), ...walk("down", 2),
  { type: "switch" }, { type: "interact" }, ...walk("right", 4),
];
export const allSolutions = { bodies: bodySolution, modules: moduleSolution, tech: fullSolution,
  freight: freightSolution, routes: routesSolution, bridge: bridgeSolution };
