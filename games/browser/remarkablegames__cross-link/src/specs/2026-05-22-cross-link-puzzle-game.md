# Cross-Link Puzzle Game

Replace the existing placeholder game with a "connect the dots" puzzle where players draw lines between same-colored dot pairs, and crossing lines of different colors clear both lines and their dots.

## Core mechanics

- **Dots**: Colored circles placed at fixed positions per level. Each dot is used exactly once.
- **Drawing a line**: Click dot A (color red) → click dot B (color red) → red line is drawn between them. The dots become "connected" but stay visible until cleared.
- **Clearing**: When a newly drawn line geometrically intersects one or more existing lines of different colors, the new line **and all intersected lines** (plus their dots) are destroyed at once. A single line can trigger a combo clearing 3+ lines if it crosses multiple different-color lines.
- **Permanence**: Lines cannot be undone. The footer **Restart** button resets the entire level (dots and lines back to initial state).
- **Win condition**: All dots cleared → level complete → advance to next level.
- **Level progression**: Levels have 2–4 color pairs, increasing in complexity.

## File plan

### Modified files

| File                     | Change                                                       |
| ------------------------ | ------------------------------------------------------------ |
| `src/constants/scene.ts` | Add `LEVEL_COMPLETE` scene constant                          |
| `src/constants/tag.ts`   | Replace with `DOT`, `LINE` tags                              |
| `src/scenes/game.ts`     | Full rewrite — core game loop, input, rendering              |
| `src/scenes/start.ts`    | Import new scenes                                            |
| `src/scenes/preload.ts`  | Remove sprite loads (no sprites needed); go directly to game |
| `src/main.ts`            | Add kaplay config (600×800, stretch, letterbox, background)  |

### New files

| File                          | Purpose                                                                  |
| ----------------------------- | ------------------------------------------------------------------------ |
| `src/constants/color.ts`      | Named color constants (red, blue, green, yellow…)                        |
| `src/levels/index.ts`         | Level data: array of `Level` objects using `addLevel` ASCII grid layout  |
| `src/scenes/levelComplete.ts` | "Level Complete" screen with next-level button                           |
| `src/gameobjects/dot.ts`      | `addDot(x, y, color)` — circle with click handler                        |
| `src/gameobjects/line.ts`     | `addLine(a, b, color)` — draws line, checks intersections                |
| `src/types/level.ts`          | `Level` type: `{ map: string[], tileWidth: number, tileHeight: number }` |

## Level format

Levels use Kaplay's `addLevel` with a logical grid. Canvas is **600×800** (`stretch: true`, `letterbox: true`, 3:4 portrait): 100px header (level number + move counter), 600×600 play grid (y=100–700), 100px footer (restart button). **100px tiles**, 6×6 grid. Dot radius: **30px** (finger-friendly on mobile). Each tile symbol maps to a colored dot; `.` is empty space.

```ts
// Level 1 — 2 pairs (red + blue), simple X cross
// Grid: 6 cols × 6 rows, 100px tiles → dots at multiples of 100px
addLevel(
  [
    ". . . . . .",
    ". . . . . .",
    ". r . b . .",
    ". . . . . .",
    ". b . r . .",
    ". . . . . .",
  ],
  {
    tileWidth: 100,
    tileHeight: 100,
    tiles: { r: dotTile("red"), b: dotTile("blue") },
  },
);
// red line: (1,2)→(3,4) crosses blue line: (3,2)→(1,4) ✓
```

Dots connect to form diagonals that are guaranteed to cross.

### Deleted/emptied

- `src/gameobjects/player.ts` — replaced
- `src/gameobjects/enemy.ts` — replaced
- `src/events/cursors.ts` — no longer needed
- `src/types/gameobject.ts` — replaced by level types

## Visual theme — Constellations

| Element          | Style                                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------------- |
| Background       | Deep navy `#0a0a1a`, scattered tiny white static stars (non-interactive, drawn with `drawCircle`) |
| Dots             | Glowing stars — filled circle + larger semi-transparent halo ring for glow effect                 |
| Dot colors       | Gold `#f5c542`, Cyan `#4fc3f7`, Rose `#f48fb1`, Violet `#ce93d8`                                  |
| Lines            | Thin (2–3px), same color as dots, opacity ~0.7, slightly glowing                                  |
| Selected dot     | Halo pulses brighter                                                                              |
| Clear animation  | Star flares (scale up) then dissolves; line fades out                                             |
| Font             | White/silver, clean sans-serif                                                                    |
| Header/footer bg | Slightly lighter navy `#0d0d2b`, separated by a subtle divider                                    |

## Animations (Kaplay `tween`)

| Trigger                | Object      | Effect                                          |
| ---------------------- | ----------- | ----------------------------------------------- |
| Hover enter/leave      | Dot         | Scale 1.0 ↔ 1.15 (desktop only)                 |
| First click (select)   | Dot         | Scale pulse: 1.0 → 1.3 → 1.1                    |
| Line drawn             | Line        | Opacity fade-in: 0 → 1 (~150ms)                 |
| Clear (crossing)       | Dots + Line | Scale up + opacity 1 → 0 (~200ms), then destroy |
| Move counter increment | Text        | Scale bump: 1.0 → 1.2 → 1.0                     |
| Level complete         | Text        | Bounce in from above                            |

## Implementation steps

1. **Clean up** old player/enemy/cursor code; update constants and types.
2. **Level data** — define 5 levels in `src/levels/index.ts` with hand-placed dot pairs that guarantee crossable solutions.
3. **Dot game object** — circle rendered via Kaplay `circle()`, clickable, stores `color` and `connected` state.
4. **Game scene** — state machine: `idle` → `dotSelected` (first dot clicked) → on second same-color click, draw line; track all active lines.
5. **Line + intersection logic** — on each new line, collect all existing different-color lines it geometrically intersects; if any found, destroy the new line + all intersected lines + their dots simultaneously (combo).
6. **Win check** — after any clear, if no dots remain, go to `LEVEL_COMPLETE` scene.
7. **Level complete scene** — show message + "Next Level" click handler; loops back to game scene with incremented level index.
8. **Lint + type check** — `npm run lint:fix && npm run lint:tsc`.

## Level sketches (canvas 600×800, 6×6 grid at y=100–700)

| Level | Pairs | New concept                                               |
| ----- | ----- | --------------------------------------------------------- |
| 1     | 2     | **Tutorial** — Red & blue, simple X cross, guided prompts |
| 2     | 3     | Third color; draw order matters to solve                  |
| 3     | 3     | Combo — one line crosses two others simultaneously        |
| 4     | 4     | Four pairs, tighter grid                                  |
| 5     | 4     | Chain clearing, hardest layout                            |

## Tutorial (Level 1)

Step-by-step prompts shown in the header area, advancing automatically as the player acts:

1. `"Tap a red dot"` — waits for first dot click
2. `"Now tap the other red dot"` — waits for line to be drawn
3. `"Now connect the blue dots"` — waits for second line + crossing
4. `"Lines cross and clear!"` — brief pause, then auto-advance to Level 2

Prompt text is stored per-level in the level data as an optional `hints: string[]` array; non-tutorial levels have no hints.
