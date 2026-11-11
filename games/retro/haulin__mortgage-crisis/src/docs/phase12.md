# Phase 12 — Title screen (boot + static menu)

Phase 12 adds a boot-first **Title screen** so the cartridge opens on the game’s identity and a quick controls reference.

This phase intentionally kept the menu **non-interactive** (visual only). The next phase turns the menu into the real entry point and gates developer tooling behind an explicit dev path.

## What shipped

- **Boot first**: the first thing you see is the Title screen.
- **Temporary dev shortcut**: a simple “press any button to continue” path existed to jump into the dev harness during early iteration (later replaced by a real menu flow).
- **Layout**:
  - large logo/title
  - short subtitle (“inspired by …”)
  - a small controls table (controller + keyboard)
  - a static menu list (New Game / Continue / How to Play)
  - optional tiled background

## Deferred

- interactive menu navigation and selection
- making Title the persistent entry point for all users (with dev tooling gated behind a toggle)

## Definition of done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)

