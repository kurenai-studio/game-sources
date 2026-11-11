# Phase 13 — Menu as main entry point

Phase 13 turns the Title screen into the cartridge’s **main entry point**: you start here, choose what to do, and can return here later.

It also introduces an explicit **dev tools** path so play sessions can feel fresh by default while still being reproducible when debugging.

## What shipped

### Interactive Title menu

- **Up/Down**: change selection
- **A**: select
- Menu items:
  - **New Game**: starts a fresh session
    - if a session already exists, asks for confirmation before overwriting it
  - **Continue**: resumes the current in-memory session (disabled until one exists)
  - **How to Play**: still a placeholder at this phase (enabled next phase)
  - **Dev tools toggle** (dev-only): enables extra debug affordances

### Seed policy: fresh by default, reproducible in dev

- With dev tools **off**, starting a new game uses a **time-based seed** so repeated games differ.
- With dev tools **on**, starting a new game remains **deterministic** for reproducible debugging.

### Title feedback uses in-game toast style

- Disabled actions and status messages appear as toast boxes.
- Toasts can stack, and identical messages dedupe.

### Return to Title from gameplay

- Gameplay includes a **Menu** action that returns to the Title screen without discarding the current session.
- **Continue** resumes that same session.

### Version display

- The version string is shown on the Title screen.

## Definition of done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)
