# Phase 20 — Demo polish 2 (deck + showcase + game-over FX)

Phase 20 was a demo-readiness pass: make the game feel more complete at a glance, and improve the “end-to-end” experience (title → play → win → reset) while keeping the cartridge lean and deterministic.

## What shipped

### Economy rebalance (2-player)

Playtesting showed that the previous “bigger pool” made cash too abundant in 2P: late-game rents lost meaning.

We rebalanced the money distribution to reduce cash inflation while keeping debts playable:

- **$1** × 2
- **$2** × 2
- **$3** × 3
- **$4** × 2
- **$5** × 1

Also:

- **Rent Any** now banks for **$2** (it’s more flexible than the 2‑color rent cards, so it should carry a slightly higher bank value).

Total deck size is now **42 cards**.

### How to Play: rent cap clarification

Added a small How-to bullet clarifying an easy-to-miss rule:

- **Rent is capped once a set is complete — extra properties don’t raise it.**

This matches the shipped rent behavior: rent is based on set size up to the required completion size, and additional properties beyond completion don’t increase the base rent.

### Screenshot-friendly “Showcase” scenario

Added a busy but clean mid-game snapshot scenario for screenshots and demos:

- player has multiple sets including a **House** on a complete set
- opponent has both **protected** (complete) and **stealable** (incomplete) properties
- player hand includes Rent/Sly/JSN + property + money
- banks + discard have enough depth to look “real”

For screenshot composition, the “Rent Any” card is positioned so the default highlight isn’t pressed against the screen edge.

### Game over: non-blocking golden-rain sparks

Game over is now more exciting without getting in the way:

- purely visual (no gameplay state mutation)
- **non-blocking** (no input lock)
- winner toast remains readable (FX renders underneath toasts)
- owned by the presentation/animation layer (so a future reduced-motion option can disable it cleanly)

The effect is intentionally simple and original: falling “spark flakes” with subtle lateral nudges and shimmering highlights, with different palettes for player win vs opponent win.

### Title screen UX polish: stable default selection

Fixed a title-menu edge case where mouse mode could be active without hovering a menu item, resulting in no visible selection.

Shipped behavior: there is always a stable selected item (defaulting to “New Game”), and mouse hover only overrides selection when it’s actually hovering an item.

## Refactors (small readability wins)

### Scenario-building helper

Scenario definitions had a lot of repetitive “take card X, push to hand/bank/discard” lines.

Added a tiny helper to populate a zone from an ordered list of cards, keeping scenarios shorter and easier to audit.

## Tests updated / added

- Updated deck-composition expectations (including total card count and per-card counts)
- Added coverage for the new Showcase scenario’s shape/assumptions
- Added sanity coverage for the new game-over FX tunables and presentation state shape
- Hardened a few tests to avoid assuming low-count cards must still be in the deck after scenario setup

## Definition of done

- `npm test` passes
- `npm run build` regenerates `game.js` (artifact matches current source)

