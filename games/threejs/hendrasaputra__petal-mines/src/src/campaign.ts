import { startGame, type Config } from './engine';

export interface Level {
  id: string;
  title: string;
  chapter: 'classic' | 'layered' | 'connected';
  description: string;
  lesson: string;
  config: Config;
}

/** Curated generator-v1 seeds; campaign.test.ts proves every shipped opening without guesses. */
export const campaign: Level[] = [
  {
    id: 'first-steps', title: 'First steps', chapter: 'classic',
    description: 'A safe opening and a little room to think.',
    lesson: 'Numbers count the eight surrounding tiles on this floor. When a number has that many neighboring flags, the other neighbors are safe. Reveal all safe tiles to finish.',
    config: { width: 5, height: 5, floors: 1, mines: 3, mode: 'classic', seed: 'petal-campaign-0', firstReveal: [12], generatorVersion: 1 },
  },
  {
    id: 'clear-thinking', title: 'Clear thinking', chapter: 'classic',
    description: 'Put your flags to work.',
    lesson: 'Flag suspected mines, then inspect a revealed number and choose Open unflagged neighbors. Chording opens the unflagged neighbors only when the flag count matches; incorrect flags can expose a mine.',
    config: { width: 6, height: 6, floors: 1, mines: 5, mode: 'classic', seed: 'petal-campaign-0', firstReveal: [14], generatorVersion: 1 },
  },
  {
    id: 'another-perspective', title: 'Another perspective', chapter: 'layered',
    description: 'Two floors, two independent puzzles.',
    lesson: 'These floors are independent. Every number still counts neighbors on its own floor. Switch floors or use Focus to inspect each puzzle; clear both floors to win.',
    config: { width: 5, height: 5, floors: 2, mines: 3, mode: 'layered', seed: 'petal-campaign-0', firstReveal: [12, 12], generatorVersion: 1 },
  },
  {
    id: 'three-little-worlds', title: 'Three little worlds', chapter: 'layered',
    description: 'A taller stack, the same familiar logic.',
    lesson: 'Explore all three floors. Exploded view separates the stack; the floor selector chooses where you play. The global mine counter covers all floors, while each floor has five mines.',
    config: { width: 6, height: 6, floors: 3, mines: 5, mode: 'layered', seed: 'petal-campaign-0', firstReveal: [14, 14, 14], generatorVersion: 1 },
  },
  {
    id: 'look-up', title: 'Look up', chapter: 'connected',
    description: 'A clue can point to a different floor.',
    lesson: 'An ↑ clue counts mines in the 3×3 footprint on the floor immediately above, including the directly aligned tile. Edges clip the footprint. Ordinary numbers still count eight same-floor neighbors. Inspect the clue to see its target tiles.',
    config: { width: 5, height: 5, floors: 2, mines: 3, mode: 'connected', vertical: 'above', seed: 'petal-campaign-2', firstReveal: [11, 12], generatorVersion: 1 },
  },
  {
    id: 'look-down', title: 'Look down', chapter: 'connected',
    description: 'The same idea, in the other direction.',
    lesson: 'A ↓ clue counts the 3×3 footprint on the floor immediately below. It never includes tiles on its own floor. A vertical zero floods its target footprint, and a vertical chord checks flags in that same footprint.',
    config: { width: 5, height: 5, floors: 2, mines: 3, mode: 'connected', vertical: 'below', seed: 'petal-campaign-71', firstReveal: [6, 7], generatorVersion: 1 },
  },
  {
    id: 'hidden-connections', title: 'Hidden connections', chapter: 'connected',
    description: 'Follow the logic through all three floors.',
    lesson: 'Combine local numbers with ↑ and ↓ clues. Each arrow refers only to the immediately adjacent floor. Use the neighborhood preview and floor selector to carry deductions across the stack.',
    config: { width: 5, height: 5, floors: 3, mines: 3, mode: 'connected', vertical: 'both', seed: 'petal-campaign-20', firstReveal: [6, 7, 8], generatorVersion: 1 },
  },
];

export function createLevel(level: Level) { return startGame(level.config); }
