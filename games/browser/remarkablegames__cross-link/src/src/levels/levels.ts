import type { Level } from '../types'

/*
 * Level Design Guide
 * ==================
 *
 * Complexity levers (stack these to increase difficulty):
 *
 *  1. More pairs — each additional color pair adds more intersections to reason about
 *  2. Draw order — arrange lines so the player must draw A before B (B can only cross A if A exists)
 *  3. Same color, multiple pairs — same-color pairs look identical (e.g. 2–3 gold pairs);
 *     the player must figure out which pair to draw first based on what it needs to cross
 *  4. Reused bridge lines — a single line (e.g. rose vertical) crosses two different-color lines
 *     at different points, so it must be drawn *after* both, acting as a chain finisher
 *  5. Combo clears — position a line so it crosses 2+ existing lines simultaneously;
 *     the player must set up all those lines first
 *  6. Interleaved chains — two independent sub-chains that must be solved in strict alternation
 *     (e.g. cyanA → goldA → white → cyanB → goldB → rose)
 *
 * Constraints:
 *  - Available colors: g=gold, c=cyan, r=rose, v=green, w=white
 *  - Each color must appear an even number of times — dots pair up, so 2, 4, 6, … per color
 *
 * Pitfalls to avoid:
 *  - Parallel same-color lines can never cross each other — don't place them so only a
 *    parallel crossing would solve the level
 *  - Make sure every line in the solution has at least one valid crossing partner already on
 *    the board when it's drawn (i.e. the solution sequence is actually achievable)
 *  - Avoid layouts where trial-and-error is the only strategy — at least one visual cue
 *    should hint at the intended sequence
 */

export const LEVELS: Level[] = [
  {
    // Level 1 — Tutorial: 2 pairs (gold + cyan), simple X cross
    // gold: (2,2)→(9,9), cyan: (9,2)→(2,9) — guaranteed cross
    map: [
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . g . . . . . . c . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . c . . . . . . g . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
    ],
    tileWidth: 50,
    tileHeight: 50,
    hints: [
      'Tap a gold star',
      'Tap the other gold star',
      'Now connect the cyan stars',
      'Lines cross and clear!',
    ],
  },

  {
    // Level 2 — 2 gold pairs (X cross) + 1 cyan pair, draw order intro
    // goldA: (2,2)→(9,9) ↘, goldB: (9,2)→(2,9) ↙ — cross each other
    // cyan: (1,5)→(10,5) — horizontal, crosses both golds
    // solution: goldA → goldB (same-color cross) → cyan (crosses both golds)
    map: [
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . g . . . . . . g . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. c . . . . . . . . c .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . g . . . . . . g . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
    ],
    tileWidth: 50,
    tileHeight: 50,
    hints: ['Can the same color clear lines?'],
  },

  {
    // Level 3 — 3 pairs (gold + cyan + rose), draw order matters
    // gold: (2,2)→(10,5), rose: (1,3)→(9,8), white: (1,6)→(7,10), cyan: (9,3)→(2,9)
    // solution: draw gold, rose, white (parallel, no cross), cyan last — crosses both
    map: [
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . g . . . . . . c . .',
      '. r . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . g . .',
      '. w . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . c . . . . . . r . .',
      '. . . . . . . . . . . .',
      '. . . . . . . w . . . .',
      '. . . . . . . . . . . .',
    ],
    tileWidth: 50,
    tileHeight: 50,
    hints: ['Draw order matters'],
  },

  {
    // Level 4 — 4 pairs, two interleaved order-constrained pairs
    // gold: (2,1)→(9,10), cyan: (9,1)→(2,10) — diagonals crossing rose and green
    // rose: (1,4)→(10,4), green: (1,5)→(10,5) — parallel horizontals, don't cross each other
    // solution: rose → gold (crosses rose) → green → cyan (crosses green)
    map: [
      '. . . . . . . . . . . .',
      '. . g . . . . . . c . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. r . . . . . . . . r .',
      '. v . . . . . . . . v .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . c . . . . . . g . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
    ],
    tileWidth: 50,
    tileHeight: 50,
    hints: ['Perfect the sequence'],
  },

  {
    // Level 5 — 6 pairs, two gold pairs + white combo, strict sequence
    // goldA: (2,1)→(9,10) ↘, goldB: (9,1)→(2,10) ↙ — same color, no cross
    // white: (1,3)→(10,3) — horizontal, crosses both golds
    // rose: (1,4)→(10,4) — horizontal, crosses both golds and white
    // green: (1,6)→(10,6) — horizontal, crosses golds and cyan
    // cyan: (4,1)→(7,10) — diagonal, crosses green and white
    // solution: cyan → green → goldA → goldB → white → rose (combo crosses all 3)
    map: [
      '. . . . . . . . . . . .',
      '. . g . . c . . . g . .',
      '. . . . . . . . . . . .',
      '. w . . . . . . . . w .',
      '. r . . . . . . . . r .',
      '. . . . . . . . . . . .',
      '. v . . . . . . . . v .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . g . . c . . . g . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
    ],
    tileWidth: 50,
    tileHeight: 50,
    hints: ['One line can do the work of many'],
  },

  {
    // Level 6 — 4 pairs with same-color gold (parallel horizontals, can't cross)
    // goldA: (2,4)→(9,4), goldB: (2,9)→(9,9) — parallel horizontals, same color
    // rose: (5,1)→(5,11) — vertical at col 5, crosses both golds (used twice)
    // cyan: (2,6)→(5,3) — diagonal ↗ crosses goldA at (3.5,4)
    // green: (8,6)→(5,9) — diagonal ↙ crosses goldB at (6.5,9)
    // solution: cyan → goldA → rose (clears) → green → goldB → rose (clears)
    map: [
      '. . . . . r . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . c . . . . . .',
      '. g . . . . . . . g . .',
      '. . . . . . . . . . . .',
      '. c . . . . . . v . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. g . . v . . . . g . .',
      '. . . . . r . . . . . .',
      '. . . . . . . . . . . .',
    ],
    tileWidth: 50,
    tileHeight: 50,
    hints: ['Some lines are worth drawing twice'],
  },

  {
    // Level 7 — 6 pairs (2 gold + 2 cyan + rose + white), two reused bridge lines
    // goldA: (2,1)→(9,10) ↘, goldB: (9,1)→(2,10) ↙
    // cyanA: (2,4)→(9,4) —, cyanB: (2,7)→(9,7) —
    // rose: (1,3)→(10,3) — horizontal, crosses both golds
    // white: (1,8)→(10,8) — horizontal, crosses both golds
    // goldA crosses cyanA and white; goldB crosses cyanB and rose
    // rose crosses goldB (and white if rose drawn after white — invalid); white crosses goldA
    // solution: cyanA → goldA (crosses cyanA) → white (crosses goldA) → cyanB → goldB (crosses cyanB) → rose (crosses goldB)
    map: [
      '. . . . . . . . . . . .',
      '. . g . . . . . . g . .',
      '. . . . . . . . . . . .',
      '. r . . . . . . . . r .',
      '. . c . . . . . c . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . c . . . . . c . . .',
      '. w . . . . . . . . w .',
      '. . . . . . . . . . . .',
      '. . g . . . . . . g . .',
      '. . . . . . . . . . . .',
    ],
    tileWidth: 50,
    tileHeight: 50,
    hints: ['Which pair do you draw first?'],
  },

  {
    // Level 8 — 7 pairs (2 gold + 2 cyan + rose + white + green), interior dots
    // Colors: g=gold (2 pairs), c=cyan (2 pairs), r=rose, w=white, v=green
    // solution: cyanA → cyanB → green (crosses both cyans) → rose → goldA (crosses rose) → white → goldB (crosses white)
    map: [
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . g . . . c . . w . .',
      '. . . . r . . . . . . .',
      '. . . . . . . g . . . .',
      '. . . c . . . . . v . .',
      '. . . . . g . . . . . .',
      '. w . . . . . . r . . .',
      '. . . v . . . . . c . .',
      '. . . . . . g . c . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
    ],
    tileWidth: 50,
    tileHeight: 50,
    hints: ['Not all crossings are obvious'],
  },

  {
    // Level 9 — [description]: 10 pairs (3 gold + 2 cyan + 2 rose + green + 2 white)
    // solution: cyan → green (clears both) → gold → rose (clears both) → rose → gold (clears both) → white → gold (clears both)
    map: [
      '. . . . . r . . g . . .',
      '. . . g . . . . r . . .',
      '. w . . . . g . . . . .',
      '. . . . . . . . . c . .',
      '. . g . . . . . . . . .',
      '. . . . . v . . . r . .',
      '. . . . . . . . . w . .',
      '. . . . c . . . . . . .',
      '. . . r . . . . . . . .',
      '. . . . . . . g . . . .',
      '. . . . . v . . . . . .',
      '. . . g . c . . c . . .',
    ],
    tileWidth: 50,
    tileHeight: 50,
    hints: ['Every chain has a first link'],
  },

  {
    // Level 10 — [description]: 12 pairs (3 gold + 3 cyan + 2 rose + 2 green + 2 white)
    // solution: cyan → cyan (clears both) → green → white → gold (clears both) → rose → gold (clears both) → rose → gold (clears both)
    map: [
      '. . . c . . . . g . . .',
      '. . . . . w . . . . r .',
      '. g . . . . . c . . . .',
      '. . . . r . . . g . . .',
      '. . . . . . . . . c . .',
      '. v . . . . . . . . g .',
      '. . . . . . w . . . . .',
      '. . r . . . . . . v . .',
      '. c . . . g . . . . . .',
      '. . . . . . . . c . . .',
      '. . . . g . . r . . . .',
      '. c . . . . . . . . . .',
    ],
    tileWidth: 50,
    tileHeight: 50,
    hints: ['Save the hardest for last'],
  },

  /*
  Level N — [description]: [N] pairs ([colors])
  [colorA]: ([col],[row])→([col],[row]) [direction], [colorB]: ([col],[row])→([col],[row]) [direction]
  solution: [colorA] → [colorB] → ... (crosses [colorX])
  {
    map: [
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
      '. . . . . . . . . . . .',
    ],
    tileWidth: 50,
    tileHeight: 50,
    hints: [''],
  },
  */
]
