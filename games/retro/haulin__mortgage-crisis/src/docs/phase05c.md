# Phase 05c — Draw + reshuffle animations

Phase 05c makes **draws and reshuffles visible** to the player by staging them over time, and temporarily locking input so the user can’t miss what happened.

## What Phase 05c implements

### Reshuffle visibility (discard → deck)

When the deck runs out during a draw and discard is reshuffled into deck:

- the rules emit a `reshuffle` event
- the UI shows a short toast: **“Deck ran out. Shuffling”**
- the renderer plays a simple deck underlayer outline animation
- input is locked while the shuffle animation/toast is active
- during the shuffle animation, the deck count is temporarily **masked** (shown as empty) so it doesn’t look “already full” before the shuffle finishes
  - the discard pile is shown **empty** during the shuffle (it has already been consumed into the deck)

### Staged dealing for any draw

When the rules emit a `draw` event:

- the UI enqueues a deal animation step
- the drawn cards are **hidden** from the hand row models until revealed
- cards are revealed **one-by-one** (player sees faces; opponent sees card backs)
- input is locked while dealing runs

This avoids “2–5 cards appear instantly” and makes draw timing readable.

## Architecture notes

- The rules/engine emit **structured events** (`draw`, `reshuffle`, …) as part of normal command application.
- The UI layer turns those events into **timed animation steps + toasts**, and **locks input** while they run.
- The animation layer applies **presentation** to the computed row models (pile masking, shuffle underlayers, deal overlays, and hiding in‑flight dealt cards).
- The renderer stays **display-only** and consumes already-presented `computed` models; it does not need to know about animation state internals.

## Config knobs

Animation timings are tunable in `MC.config.ui` (frames @ 60fps):

- `animSpeedMult` (added in Phase 15): global multiplier applied to shuffle/deal/xfer timings (useful for slow-motion debugging).
- `dealFramesPerCard`
- `dealGapFrames`
- `shuffleAnimFrames`
- `shuffleToastFrames`

These are validated in config sanity tests.

Note: effective staged-deal timing is `dealFramesPerCard * animSpeedMult` and `dealGapFrames * animSpeedMult`.
If a test needs to tick “exactly until reveal”, prefer reading the active step’s `dealFrames`/`gapFrames` from `view.anim.active` instead of assuming the base config values.

## Definition of done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)
- In play:
  - reshuffles are obvious (toast + deck animation)
  - draws are staged and readable (cards don’t “pop” into hand instantly)

