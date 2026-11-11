# Mortgage Crisis — User Manual (WIP)

This document describes **how to play and test the current build** of Mortgage Crisis, from the user’s point of view.

It will evolve as new phases land. If something in the game feels “undocumented”, that’s a bug in the docs.

## Quick start (TIC-80)

- Build the cartridge:

```bash
npm run build
```

- In TIC-80, import/run `game.js` (see `README.md` for workflow notes).
- Controls are **controller-first**, but the build also supports **mouse** (hover + click + drag-and-drop).

## Title screen (current)

On boot you start on the **Title screen**:

- It shows the project name, a main menu, and a controls quick-reference (plus the version).
- Use **Up/Down** to choose a menu item, then **A** to select.
- Mouse:
  - **Hover** a menu item to select it
  - **Left click** to confirm
- Menu feedback (e.g. disabled **Continue**) appears as a **toast** at the top of the screen (same style as in-game).
- **New Game** starts a fresh game.
- If a game is already running, selecting **New Game** asks for confirmation (**A** confirm, **B** cancel).
- **Continue** returns to the current in-memory game (disabled until you’ve started one).
- **How to Play** opens the in-game how-to screen (**B** returns to Title).
- **About** opens the in-game about screen (**B** returns to Title).
- **Dev: ON/OFF** (dev-only) toggles dev tooling (debug buttons + DebugText/Render mode toggle).

## Controls (current)

Button IDs are TIC-80 defaults for player 1: UP=0 DOWN=1 LEFT=2 RIGHT=3 A=4 B=5 X=6 Y=7.

- **D-pad**: move selection (cursor) between zones and items.
- **A (tap)**:
  - on a hand card: open the action menu (Place/Build/Rent/Sly/Bank, depending on the card)
  - in menus: choose the hovered menu item
  - on a center button: activate it (e.g. **Menu** returns to the title screen)
  - in prompts: confirm the prompt action (e.g. discard)
- **A (hold)**:
  - start “grab/targeting” quickly (hold + nudge a direction enters targeting immediately)
  - release A to confirm (when targeting was entered from a hold)
- **B (tap)**: back/cancel out of menu/targeting (and some prompts, if allowed).
- **X (hold)**: Inspect overlay (after a short delay).
- **Y (tap)**: when **Dev tools** are enabled, toggle DebugText ↔ Render.

### Mouse controls

- **Hover**: moves selection cursor.
- **Left click**: confirm / open menu (equivalent to **A tap**).
- **Left drag**: drag-and-drop quick play (equivalent to **A hold** → targeting; release confirms).
- **Right click**: back/cancel (equivalent to **B**).
- **Middle click (hold)**: Inspect (equivalent to **X hold**).
- **Wheel**: optional up/down navigation pulses (configurable; invert knob exists).

## Gameplay loop (current)

Mortgage Crisis is still under active development; the full card set is not implemented yet. The current gameplay focuses on:

- **Turn loop**:
  - start-of-turn draw (draw 2, or draw 5 if your hand is empty)
  - play up to **3** cards (`playsLeft`)
  - end turn
- **Win condition**: first to **3 complete property sets**

### Ending the turn with too many cards (discard prompt)

If you end your turn with more than 7 cards, you enter a forced prompt:

- A banner/toast shows **“Too many cards. Discard N”**
- **A** discards the highlighted hand card
- **B** cancels only **before the first discard** in that prompt instance; after you discard once, it’s forced

### Paying a debt (pay-debt prompt)

Some effects can force a “pay a debt” prompt (Phase 06 foundation).

- A banner/toast shows **“Pay debt: $N left”**
  - If the debt is action-sourced and **Just Say No** is currently legal, the toast teaches it (e.g. **“Rent: Pay $N or Just Say No”**).
- **D-pad**: navigate to a payable card (bank cards, properties, or a House on a set)
- **A**: pay the highlighted card (it’s removed immediately)
- **B**: disallowed (forced prompt) — you must pay until it auto-finishes
- **House-pay-first**: if a set has a House, you can’t pay properties from that set until the House is paid
  - pressing **A** on a property in that set redirects selection to the House (it does **not** pay automatically)
  - press **A** again on the House to pay it
- The prompt **auto-finishes** when the debt is covered or you run out of payables (overpay is allowed; no change is returned)
- Where paid cards go:
  - paid **properties** → recipient gets a **placeReceived** prompt
  - paid **money/action/house** → recipient’s **bank**

#### Just Say No during pay-debt (Phase 08)

For action-sourced debts (notably Rent), the payer may cancel the action by playing JSN:

- JSN is legal only **before any payment is made** (i.e. buffer is empty).
- If JSN is legal and you have a JSN in hand: **tap A** on the JSN card in hand to play it.

### Placing received properties (faux-turn placement prompt)

When you receive properties as payment, you place them explicitly:

- A banner/toast shows **“Place received properties: N”**
- Row 4 shows a **faux-hand** of received properties on the **left**, plus your real hand/bank to the right
- Only the faux-hand cards are actionable
- **A** on a received property enters targeting to choose its destination (existing set or new set)
  - For Wild properties: **Up/Down** toggles the chosen color during targeting
- **B** is not a general cancel during this prompt (you must place the received properties)

### Wild replace-window (optional reposition prompt, Phase 10)

After some property placements, the rules may offer an *optional* prompt to reposition a Wild:

- Trigger: after placing a property **into a set**, if that set contains an eligible Wild that can be removed while leaving the source set still **complete**
- A banner/toast shows **“Move a Wild? A:move B:skip”**
- The cursor auto-focuses an eligible Wild in the source set
- **B**: skip (no reposition)
- **A (tap)**: enter targeting to choose where the Wild goes
- **A (hold + nudge)**: enter targeting in “hold” mode (release A confirms)

While targeting the Wild move:

- **Left/Right**: cycle destinations (matching-color sets + New set, plus **Source** to cancel; ordered left→right)
- **Up/Down**: toggle which color the Wild will count as at the destination
- Confirm normally with **A**, or cancel by cycling to **Source** and confirming

### Playing a Rent card (Phase 06 vertical slice)

If you have a Rent card and at least one eligible set, it can be played (not just banked):

- Cursor the Rent card in hand, then **tap A** to open the menu
- Choose **Rent**
- If there are multiple eligible sets, you enter a Rent picker:
  - default selection is your **highest-rent** eligible set
  - **Left/Right**: cycle which of your sets you’re charging rent from (spatial, left→right across your table; wraps)
  - the overlay shows the chosen set and the amount
  - **A** confirms, **B** cancels (or cycle to **Source** and confirm)
- After confirming, the opponent pays via the standard **pay-debt prompt** (and may be able to respond with JSN before paying anything).

After confirming:

- The Rent card is discarded, consumes a play, and the opponent enters a **pay-debt prompt**.
- In Render mode the opponent is controlled by the AI (Phase 07), so you’ll see them pay (or respond with JSN if legal).

### Playing Sly Deal (Phase 08)

Sly Deal steals an opponent property that is **not** part of a complete set.

- Enter from hand via:
  - **tap A** → menu:
    - `Sly Deal...` when there are multiple legal targets (enters targeting)
    - `Sly Deal → <Color>` when there is exactly one legal target (auto-applies on select)
  - **hold A** → immediate Sly targeting (when legal targets exist)
- While in Sly targeting:
  - **Left/Right** cycles targets ordered by screen-space X (left→right)
  - the cursor jumps onto the current target (cursor-moving targeting; avoids a “two cursors” look)
  - a `Source` option exists at the end and returns selection to the Sly card

If the defender has a JSN in hand, they enter a forced response prompt:

- **A on the target**: Allow (the steal resolves)
- **A on a JSN in hand**: Just Say No (cancels)
- **B**: disallowed (forced prompt)

## Inspect (hold X)

Inspect shows the selected card’s details. Notes:

- Inspect only shows while you’re in normal browsing / prompt flow.
- In menus/targeting, Inspect is intentionally suppressed to reduce UI noise.
  - Mouse: you can also hold **middle click** to Inspect.

## Hand card actions (menu)

When your cursor is on a hand card, **tap A** to open a menu of actions that are currently legal for that card:

- **Place** (property cards)
- **Build** (house cards, only when legal)
- **Rent** (rent action cards, only when legal)
- **Sly Deal** (sly deal action cards, only when legal)
- **Bank** (money/action cards that can be banked, only when legal)

Notes:

- The menu is **actionable-only**: if nothing is legal right now (e.g. **no plays left** while browsing), the menu may show **only Cancel**.
- When you **Bank** an **action card**, it becomes **money only** for the rest of the game (you can’t play it as an action later).

### Single-destination shortcuts

If **Place**, **Build**, **Rent**, or **Sly Deal** has exactly **one** legal destination/target, the UI may:

- show a more specific label (e.g. **“Place → New Set”**), and
- auto-apply immediately when you select it from the menu.
  - For **Sly Deal**, hovering `Sly Deal → <Color>` also previews the steal by ghosting the Sly card in hand and showing a yellow-highlight preview on the target property.

## Targeting (destination selection)

Targeting appears when an action needs a destination selection (e.g. placing a property into one of multiple sets).

There are two ways to enter targeting:

- **From the menu**: tap A on Place/Build/Rent/Sly Deal to enter targeting (when there are multiple destinations/targets); confirm with **tap A**.
- **From a hold**: hold A on a hand card to enter targeting; confirm with **release A**.

While targeting:

- **Left/Right**: cycle destinations/options (ordered spatially left→right by on-screen position; wraps)
- **Up/Down**: toggle Wild color (when targeting a Wild placement or Wild move)
- **B**: cancel targeting and return to browse

### Hold‑A hold-chain targeting (action cycling)

When you **hold A** on many hand cards, the UI enters a hold‑A targeting flow that can be a **chain of segments** (a “hold-chain”):

- Each segment corresponds to a targeting kind (e.g. `rent`, `build`, `bank`, `sly`, `source`)
- **Left/Right** cycles within the current segment; cycling past the end moves to the next segment
- Default choice prefers the “primary action” segment when it exists (e.g. **Rent** prefers the highest amount target)
- Confirm by **releasing A**

Note:

- If you hold‑A on a Sly Deal card when there are **no legal Sly targets**, the hold-chain starts at **Bank** so you can still Bank the card quickly.

### Source destination (cancel-by-dropping-back)

Targeting includes a special destination called **Source**:

- Cycling to **Source** and confirming cancels the action (no command is applied).
- While targeting, the grabbed source card is usually hidden at its source position so it doesn’t look like you have “two copies” on screen.
  - When **Source** is the selected destination, the real source card is shown again with the normal selection highlight.

Mouse note:

- During drag-and-drop targeting, you can cancel by releasing off-target, or by dragging back onto the source card and releasing.

## Ghost/preview space reservation (no overlap)

When an action shows destination **ghosts** (outlines) or a **preview** card rendered “into” a stack, the UI reserves real space for that synthetic item:

- Ghosts and previews **do not overlap** real cards (or each other in the same slot).
- This includes banking: when a bank destination is ghosted/previewed, the visible bank stack shifts to make room for the synthetic “new top” slot.

## Draw + reshuffle visibility (animations)

Draws are staged so they’re readable:

- When you draw multiple cards, they are **dealt one-by-one** instead of instantly appearing.
- If the deck runs out and the game reshuffles discard into deck, you’ll see a short **“Deck ran out. Shuffling”** toast plus a simple deck animation.
- While shuffle/deal animations run, **input is temporarily locked** so you don’t miss it.
  - During the shuffle, the discard pile is shown **empty** (it has already been consumed) and the deck count is temporarily shown as **empty** until the shuffle finishes.

## Disallowed action feedback

When you try to do something illegal or currently unavailable:

- The selection highlight **flashes red** briefly.
- If you repeat the same mistake, you’ll also get a short toast explaining why (e.g. “Not available”).

## Debug harness (for testers/dev)

The project includes a built-in harness to make testing faster.

### Modes

- **DebugText mode**: text-only debug view
- **Render mode**: the actual rendered game UI
- Dev tools are toggled from the Title screen (`Dev: ON/OFF`).
- When dev tools are enabled, toggle DebugText ↔ Render with **Y**.

### DebugText controls

DebugText mode uses the simplest possible bindings:

- **A**: step one random legal move
- **B**: next scenario
- **X**: reset scenario
- **Y**: toggle DebugText ↔ Render

### DebugText prompt stage line

The DebugText screen’s **left column** includes a `Prompt:` line to show which rules prompt is active (useful for tracking the Rent/debt cycle):

- `Prompt:(none)`
- `Prompt:payDebt rem:$<n> buf:<n>` (selecting payment)
- `Prompt:placeRecv n:<n>` (placing received properties)
- `Prompt:replaceWindow` (optional Wild reposition after a placement)
- `Prompt:discardDown to:<n> left:<n>` (discarding down to 7)

### DebugText “UI snapshot” column legend

The DebugText screen has a **right column** showing a compact UI snapshot (captured from the last Render-mode tick).

- **`UI:<mode> I:<0/1> Drag:<0/1>`**
  - `mode`: `browse` | `menu` | `targeting` | `prompt`
  - `I`: `view.inspectActive` (1 when Inspect overlay is active)
  - `Drag`: 1 when you are in hold-targeting (i.e. currently “dragging” a card)
- **`Cur:r<row> i<i>`**
  - current cursor position (row + index)
- **`Menu:<i>/<n> <id>`** (only when `UI:menu`)
  - hovered menu index / count, and menu item id (e.g. `place`, `build`, `rent`, `sly`, `bank`)
- **`Tgt:<kind> <cmdI>/<n>`** (only when `UI:targeting`)
  - `kind`: `place` | `moveWild` | `build` | `bank` | `rent` | `sly` | `source`
  - `cmdI/n`: selected destination index + total destinations
- **`Prompt:<kind>`** (only when `UI:prompt`)
  - one of: `discardDown` | `payDebt` | `placeReceived` | `replaceWindow` | `respondAction`
- **`Tgt:<kind> <cmdI>/<n> h:<0/1>`** (only when `UI:targeting`)
  - `h`: 1 when targeting was entered from **holding A** (confirm on A release)
- **`Down:...`**
  - raw “currently held” button states (not one-frame pulses), captured from the last Render-mode tick
- **`Held:A<frames> X<frames> Grab:<0/1> XLatch:<0/1>`**
  - `Held:A` / `Held:X`: how many frames A/X have been held (controls state)
  - `Grab`: whether the controls layer considers “A grab mode” active
  - `XLatch`: whether the controls layer considers Inspect latched (after delay)
- **`Intent:<summary>`**
  - what the UI returned last frame, e.g. `applyCmd:bank`, `debug:step`, or `(none)`

