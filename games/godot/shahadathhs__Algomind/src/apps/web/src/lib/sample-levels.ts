import type { BoardData } from "@/lib/board";

/**
 * Static sample boards for the landing page's levels strip. They are illustrations of the board
 * language, not published levels. The strip shows real published boards (getCampaign) and falls
 * back to these only when the API cannot be reached, so the page never depends on it being up.
 */
export type SampleLevel = { id: string; title: string; board: BoardData };

export const SAMPLE_LEVELS: readonly SampleLevel[] = [
  {
    id: "straight",
    title: "Straight ahead",
    board: {
      width: 5,
      height: 5,
      walls: [],
      goal: { x: 0, y: 1 },
      automaton: { x: 0, y: 4, dir: "N" },
    },
  },
  {
    id: "trench",
    title: "Past the trench",
    board: {
      width: 5,
      height: 5,
      walls: [
        { x: 1, y: 3 },
        { x: 1, y: 4 },
      ],
      goal: { x: 3, y: 4 },
      automaton: { x: 0, y: 4, dir: "N" },
    },
  },
  {
    id: "corner",
    title: "Around the corner",
    board: {
      width: 5,
      height: 5,
      walls: [
        { x: 1, y: 4 },
        { x: 2, y: 3 },
        { x: 1, y: 2 },
        { x: 4, y: 2 },
      ],
      goal: { x: 3, y: 2 },
      automaton: { x: 0, y: 4, dir: "N" },
    },
  },
  {
    id: "long-wall",
    title: "The long wall",
    board: {
      width: 5,
      height: 5,
      walls: [
        { x: 0, y: 2 },
        { x: 1, y: 2 },
        { x: 2, y: 2 },
        { x: 3, y: 2 },
      ],
      goal: { x: 0, y: 0 },
      automaton: { x: 0, y: 4, dir: "N" },
    },
  },
  {
    id: "ring",
    title: "The ring",
    board: {
      width: 5,
      height: 5,
      walls: [
        { x: 1, y: 1 },
        { x: 3, y: 1 },
        { x: 1, y: 3 },
        { x: 3, y: 3 },
      ],
      goal: { x: 2, y: 2 },
      automaton: { x: 0, y: 4, dir: "N" },
    },
  },
];
