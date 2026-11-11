# Phase 21 — About screen + repo cleanup

Phase 21 adds a user-facing **About** screen inside the TIC-80 cartridge, and then cleans up the repository so it’s easier to understand for first-time visitors.

## What shipped

### In-game About screen

- Added an **About** entry on the Title screen.
- About is a **single scrollable page** (no paging).
- Content focuses on:
  - the demo/version context
  - what the full version is aiming for (high level)
  - where to report bugs / give feedback (URL rendered as text; not clickable)
  - credits + legal notes

### Reuse the existing “How to Play” rendering

Instead of creating a second bespoke UI, About reuses the same internal document-style renderer as “How to Play”:

- headings / paragraphs / bullet lists
- word-wrapping tuned for 240×136
- consistent scroll behavior + header chrome

This keeps future editing of informational screens cheap and consistent.

### Version bump

- The demo version string was bumped to **Demo v0.21**, and the UI reflects it.

### Repo cleanup (visitor-focused)

- Added an MIT **LICENSE** file.
- Rewrote the **README** to be visitor-facing (what the game is, what’s playable, where to report issues).
- Added a separate development notes doc to hold deeper workflow/compatibility details without bloating the README.
- Reorganized files to reduce “mystery meat” at repo root:
  - TIC-80 reference material lives under `tic-80-docs/`
  - old experiments/discarded assets live under `other/`
- Updated existing docs so they don’t point at moved/deleted paths.

### Verification

- `npm test` passes
- `npm run build` regenerates `game.js` so it stays in sync with `src/`

