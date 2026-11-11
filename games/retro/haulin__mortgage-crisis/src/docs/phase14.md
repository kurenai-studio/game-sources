# Phase 14 — How to Play

Phase 14 adds an in-cartridge **How to Play** screen so the demo is self-explanatory without external docs, while keeping the content easy to iterate on.

## What shipped

### Entry + exit

- “How to Play” is selectable from the Title menu.
- **B** returns to the Title screen.

### Paging + scrolling

- Ships with **3 pages**: **Quick Start**, **Controls**, **Details**.
- **Left/Right** cycles pages (wrap-around).
- **Up/Down** scrolls within the current page when content overflows.
- A small scrollbar appears only when a page is scrollable.
- The screen remembers **last page + per-page scroll** when you exit and reopen it.

### Content authoring model (human-editable)

- Content is written as structured blocks (headings, paragraphs, bullet lists).
- Optional tiny “demo” drawings can be placed above or beside a block.
- Supports lightweight inline color emphasis via `<cN>…</c>` tags.
- Wrapping favors predictable layout (whitespace is normalized).

### Important rules called out

- **Banking action cards** is permanent: once banked, an action counts as **money only** for the rest of the game.
- **No change**: overpay is allowed when paying debts, but no change is returned.

## Definition of done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)
