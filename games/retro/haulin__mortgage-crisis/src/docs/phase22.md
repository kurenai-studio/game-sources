# Phase 22 — Publish Demo (screenshots + links + TIC-80 metadata)

Phase 22 is a “publish pass”: make the demo easier to present, easier to find, and less likely to get tripped up by platform quirks when uploading.

## What shipped

### Screenshot / marketing capture mode (Title)

- Added a **capture mode toggle** (off by default) that hides **Title screen chrome** (menu, controls table, subtitle, version, toasts).
- Shipped behavior in capture mode is a clean Title composition: **background + logo only**, suitable for cover/marketing screenshots.

### Publish links surfaced in-game and in repo

- README now links to:
  - the itch.io page (downloads + feedback hub)
  - the TIC-80 “play in browser” page
- About screen now includes:
  - **Play in browser** (TIC-80 link)
  - **Downloads & feedback** (itch.io + GitHub)

### TIC-80 metadata reliability

- Added the required **`author`** metadata tag (alongside title/desc/script/saveid).
- Worked around a TIC-80 listing scraper edge-case by duplicating the metadata comments at the **end** of the cartridge so the website shows the correct title/description (instead of accidentally picking up unrelated `title:`/`desc:` fields inside the game code).

### Version bump

- Demo version bumped to **Demo v0.22** (config + README + About header).

## Verification

- `npm test`
- `npm run build` (regenerates `game.js` so it stays in sync with `src/`)

