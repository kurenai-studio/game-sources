# Phase 18 — Demo-ready visuals (icons + background polish)

Phase 18 is a visual polish pass aimed at making the demo feel more intentional within TIC-80 constraints (palette limits, no true alpha, tight CPU/code budgets).

## What shipped

### Larger action/building icons

- Action/building cards now use larger **~15×15** center icons.
- Authoring convention: treat icons as 16×16 blocks with a colorkey padding row/column so the visible portion reads as a clean 15×15 with consistent spacing.

### VRAM layering: background + UI overlay

- One VRAM bank is treated as the **base/background** layer.
- A second bank is treated as the **UI overlay** layer.
- The overlay layer is cleared to a transparent index each frame so the background can show through UI “holes”.

### Background + panel treatment

- Gameplay uses a **static** repeating tile background (cheap + stable; avoids motion nausea).
- The center panel uses a **dither-tile** fill so the background subtly shows through.

### Plasma demo extracted (not shipped in main game)

The procedural plasma + palette cycling experiment was kept as a separate standalone demo cart so the main cartridge stays smaller and cheaper per-frame.

## Definition of done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)
