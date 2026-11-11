# Phase 07 — AI (random legal) + narrated pacing

This phase adds a very small opponent AI for play-testing flows end-to-end.

## What shipped

- Opponent (P1) takes actions automatically in Render mode (`MC.mainTick`).
- AI picks **one random legal move** per step and waits a fixed number of frames between steps.
- Each AI command can emit a short narration toast (“AI: Rent”, “AI: Place -> …”).

In practice, Phase 07 also became our “playtest polish” phase: we tightened several UX edges (Rent preview consistency, endgame handling, and—most importantly—centralized focus/autofocus so the cursor stops fighting the player).

## Implementation

The AI loop is intentionally simple:

- Determine the current actor (prompt actor when prompting; otherwise the active player).
- Generate legal commands, pick **one** using deterministic RNG, and apply it.
- Emit short narration toasts for readability while playtesting.

Render-mode input is suppressed while the AI is the actor (to prevent conflicting commands), and the pacing loop runs only when not animation-locked.

Game over exception:

- When a winner is present, inputs remain available so the dev harness can always Reset/Next even if `activeP` is still the opponent.

## Policy system (future hook)

The AI module is structured around **pluggable policies** so we can evolve beyond “random legal” without rewriting call sites:

- A **policy** assigns a weight/score to each legal command.
- The picker does a deterministic **weighted choice** (seeded RNG), so runs remain reproducible.
- Policies can be chosen **per player**, making it possible to run deterministic “policy vs policy” comparisons by replaying the same seed + scenario(s).

## Focus policy (Phase 07 playtest ergonomics)

We moved autofocus/selection preservation out of scattered UI logic into a single module so it’s easier to tweak, test, and reason about.

The focus system is centralized so it’s easier to tweak, test, and reason about:

- Preserve selection across state churn.
- Apply **event-driven one-shot focus nudges** (not “always-on” invariants) so browsing doesn’t trigger autofocus.

### Debug pause latch (no autofocus after debug buttons)

Playtesting with `Step`/`Next`/`Reset` should not immediately snap the cursor somewhere else.

- `view.ux.autoFocusPausedByDebug`: boolean latch set when pressing debug buttons.
- While latched:
  - no autofocus rules run (and preservation only runs if selection disappears)
  - latch clears on the **first non-debug input** (D-pad, or `A` on a non-debug selection)
- The latch is preserved across scenario resets (`Next`) so it doesn’t get dropped when the view is recreated.

### One-shot focus rules we added/updated

All are gated to avoid interfering with prompts, inspection, game over, and debug-pause as appropriate.

- **Turn start**: `OnPlayerTurnStart_FocusHandOrEnd`
  - on transition into P0’s turn, focus hand if non-empty, otherwise `End` (if plays remain)
- **Plays exhausted**: `OnPlaysExhausted_End` (when plays transition from \(>0\) to \(<=0\))
- **Hand became empty mid-turn**: `OnHandBecameEmpty_End` (hand length transition \(>0\) → \(0\))
- **Pay debt default focus**: `OnEnterPayDebtPrompt_DefaultFocus` (bank if available, else properties/houses)
- **Pay debt invalid attempt**: `OnInvalidActionPayDebt_DefaultFocus` triggered by `pendingFocusErrorCode === "cant_pay"`
- **Empty-hand invalid attempt**: `OnInvalidActionWhileHandEmpty_End` triggered by `pendingFocusErrorCode` while hand empty

### Debug visibility

To aid future bug reports, DebugText now shows:

- `Anchor:uid... <zone>` (selection anchor)
- `FocusErr:<code>` (pending focus error channel)
- `FocusRule:<id>` (rendered full-width so long ids fit)

## Rent/menu preview consistency (tap-A vs hold-A)

- Actions that invoke targeting show an ellipsis (e.g. `Rent...`) to signal “more steps”.
- For **single-target Rent**, tap‑A menu-hover previews now:
  - highlight the destination set like hold‑A targeting
  - ghost the source hand card (no “double-highlight”)
- For **multi-target** `Rent...`, menu-hover does **not** preview a default destination (avoid implying a default choice).

Implementation notes (conceptual):

- Menus signal multi-step actions with an ellipsis (`...`).
- Hover previews only show when the destination is unambiguous.
- Rendering can “ghost” a source card during targeting/preview to avoid double-highlights.

## Endgame UX (winner clarity + safe inputs)

When a win is detected mid-flow (including during prompts like received-property placement), we now:

- replace stale prompt messaging with a persistent `Winner: Player/Opponent` toast
- keep navigation + inspect working
- block tap‑A on non-buttons (blink feedback only; no menu/targeting/command attempts)
- auto-focus `Reset` (debug enabled) and render it in the “ready” style

## Config knobs

AI pacing is controlled by a couple of UI timing knobs (frames @ 60fps): step delay and narration toast duration.

Toast visuals are renderer-owned; AI narration is rendered with a distinct background style.

