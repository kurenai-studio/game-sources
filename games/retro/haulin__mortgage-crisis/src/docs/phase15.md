# Phase 15 — Animations (MVP readability)

Phase 15 improves the **readability** of key “watch moments” (start of game, debt payment, steals) with a small, curated set of animations—without slowing down normal play.

## Goals

- Make it obvious what happened when cards move ownership.
- Keep animations short and safe under TIC-80 constraints.
- Avoid spending animation budget on low-signal moves (routine placements stay snappy).

## What shipped

### Game start: deal → toast → draw

New Game now visually explains the 5/7 opening:

- deal 5 cards to each player
- show a “You start / AI starts” toast
- animate the starting player drawing 2 more cards

### Debt buffer visualization

During debt payment, selected payables are shown in a dedicated **payment buffer** stack near the center so it’s clear what’s already committed.

The buffer stays visible while post-prompt transfers drain out, so you don’t get “buffer disappears but cards are still flying”.

### Curated transfer animations

Only ownership-changing transfers are animated, one card at a time:

- debt drains from the payment buffer to the recipient
- steals fly from the opponent table into the recipient’s receive area
- when the AI chooses a payment source, a short hold/highlight makes the source readable before the card flies

Non-goals (kept out to reduce risk):

- discard animations
- “same-owner” placement flights (received-property placement stays snappy)

### Focus stability during locks

While an animation is active, selection/focus is kept stable so the cursor doesn’t wander as stacks reflow.

## How it works (conceptually)

- The rules engine emits structured “what happened” events.
- The UI converts those events into a timed animation queue.
- While a card is in-flight, the UI hides it at its state location so it can’t appear twice.
- Transfer origins prefer the last known on-screen position; otherwise a fixed center anchor is used.
- Animation pacing is controlled by a small set of tuning knobs (including a global speed multiplier for slow-motion debugging), validated in tests to avoid runtime fallbacks.

## Definition of done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)

