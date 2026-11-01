/** A valid 5x5 level: start (0,4) facing north, goal (0,0); four MOVE_FORWARD solve it. */
export function level(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    schemaVersion: 1,
    levelId: "00000000-0000-4000-8000-000000000001",
    levelVersion: 1,
    slug: "test-level",
    title: "Test level",
    description: "",
    difficulty: "easy",
    requires: { mechanics: [] },
    board: { width: 5, height: 5, walls: [] },
    initialState: { position: [0, 4], direction: "north" },
    availableCommands: ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"],
    constraints: { maxCommands: 6, maxSteps: 20 },
    goal: { type: "reach_tile", position: [0, 0] },
    hints: [],
    ...overrides,
  };
}

export const SOLUTION = [
  { op: "MOVE_FORWARD" },
  { op: "MOVE_FORWARD" },
  { op: "MOVE_FORWARD" },
  { op: "MOVE_FORWARD" },
];
