# Algomind — Visual Design Guide

> **Goal:** Give Algomind its own visual identity across the Godot game, the public website, and the admin dashboard (the latter two live in one Next.js app). Algomind must not look like any other product in the same family of projects, in layout, type, color, or shape.  
> **Reference renders:** [design/SCREENS.md](design/SCREENS.md) lists every game screen; [overview-light](design/overview-light.png) and [overview-dark](design/overview-dark.png) show them all.  
> **Status:** Direction chosen (below). Tokens are the starting values from the concept renders; contrast was checked, and final fonts are still to be chosen.

> **Depth direction (approved 2026-10-31, not yet built).** The owner approved a second direction: the same Instruction Tape identity with depth (section 14). It is a concept in `docs/design/depth/`. Until the migration lands, sections 1 to 13 describe the shipped code and still apply to it; section 14 applies to the depth track.

## 1. Design direction: Instruction Tape

**The unit is the tile.** A program is a strip of instruction tiles. The board's cells, the command tiles, the level tiles, and the wordmark letters are all the same family of flat, square, chamfered pieces. A viewer should understand the game from the shapes: a strip of instructions runs under a fixed read-head while a small machine moves across a grid.

Character: flat, high-contrast, industrial-label. Not cute, not neon, not a SaaS dashboard, not a terminal.

### Signature elements (what makes it Algomind)

- **Chamfered tile.** One corner (top right) is cut at 45°. Tiles, buttons, fields, and toggles share it. Board cells stay square so the grid reads cleanly.
- **One accent: signal yellow `#FFC20E`.** Yellow marks the current instruction, the target, the read-head, and the one primary action. It is the same in both themes. Yellow is never used as text or a line on the light ground (contrast 1.4:1); it is always a fill with ink on top.
- **Hatched walls.** Diagonal hatch marks obstacles; in a failure, the wall that was hit turns yellow-striped.
- **The tape.** A continuous strip of instruction tiles slides under a fixed yellow read-head. See section 5.
- **Automaton.** A chamfered block with a yellow wedge showing its facing direction. It is read by shape and orientation, not color alone.
- **Tile wordmark.** `ALGOMIND` is set as eight tiles, the first one yellow.

### Not allowed (anti-slop rules)

These apply to the game, the public site, and the dashboard. Reviewers and AI tools should reject any change that breaks them.

- No gradients, glow, drop shadows, frosted glass, blur, particles, bevels, or 3D.
- No cards. Group with spacing and a small caption, not with boxes or borders. No card inside a card.
- No border where spacing would do.
- Exactly one primary (yellow) button per screen. Secondaries are outlined tiles; tertiary actions are underlined text.
- No two-tone headlines, taglines, eyebrow marketing text, motivational copy, questions to the player, or exclamation marks.
- No emoji. No decorative icons that do not mean something in the game.
- No default component-library look in the dashboard (rounded pills, soft shadows, pastel badges).
- No loops or idle animation. No animation over 250 ms except the result screen.
- Do not borrow another project's fonts, palette, wordmark, or corner style.
- Prefer deleting to adding. A screen improves when parts are removed.

### Principles

- **Legibility before decoration.** Board state, program, and goal read at a glance.
- **One focal point.** On the game screen the board is first and the tape is second.
- **Consistent meaning.** A shape or marker means the same thing in the game, tutorials, previews, website, and dashboard.
- **Accessible by construction.** Color is never the only signal. Every command, state, and marker also has a shape, icon, number, or label.
- **Made for thumbs.** Primary actions sit in the bottom third of the screen.

## 2. Themes

Light and dark are both first-class. The setting offers System (default), Light, and Dark. Every screen is designed and checked in both. The shape language, layout, and yellow accent do not change between themes; only the ground and ink swap.

| Token        | Light     | Dark      | Use                                                          |
| ------------ | --------- | --------- | ------------------------------------------------------------ |
| `ground`     | `#F1F1EC` | `#0E0F11` | Screen background                                            |
| `ink`        | `#13161A` | `#F2F2EE` | Text, outlines, solid tiles                                  |
| `on-ink`     | `#FFFFFF` | `#0E0F11` | Text/icons on solid ink tiles                                |
| `floor`      | `#FFFFFF` | `#1D1F23` | Empty board cells, upcoming tiles                            |
| `strip`      | `#E4E4DD` | `#191B1E` | Tape background                                              |
| `mute`       | `#5C6168` | `#8D9299` | Secondary text, captions                                     |
| `faint`      | `#B9BBB5` | `#3B3F45` | Locked (disabled) tiles                                      |
| `slot`       | `#9A9D9A` | `#5A5F66` | Dashed empty slots and not-downloaded tiles                  |
| `signal`     | `#FFC20E` | `#FFC20E` | Accent fill: current step, target, read-head, primary action |
| `on-signal`  | `#13161A` | `#0E0F11` | Text/icons on signal                                         |
| `wall`       | `#13161A` | `#3A3E44` | Wall fill                                                    |
| `wall-hatch` | `#383E45` | `#5E646C` | Wall hatch                                                   |
| `trail`      | `#FFE9A0` | `#3D3418` | Cells the automaton has passed                               |

Contrast (WCAG ratios, computed from these values):

| Pair                    | Light                       | Dark |
| ----------------------- | --------------------------- | ---- |
| `ink` on `ground`       | 16.0                        | 17.1 |
| `on-signal` on `signal` | 11.2                        | 11.9 |
| `mute` on `ground`      | 5.5                         | 6.1  |
| `mute` on `strip`       | 4.9                         | 5.5  |
| `signal` on `ground`    | 1.4 (fill only, never text) | 11.9 |

The concept renders used `#6C7076` for light `mute`; it measured 4.4 on `ground` and 3.9 on `strip`, so it was darkened to `#5C6168`. `faint` is for disabled tiles and is exempt from text contrast, but locked levels must still be identifiable by their icon or legend, not only by being faint. Re-check every token pair when values change.

### Token source of truth

Tokens are defined once, in `packages/design-tokens` (a data file). A script generates the Godot palette script and the web CSS custom properties from it, and CI fails if generated files are out of date. No app defines a color by hand. The generated Godot palette and the generated web CSS variables are the only places colors appear; a grep for hex values or `Color(` outside them must fail.

## 3. Typography

- **Direction:** a bold, condensed, geometric sans for UI and display, set mostly in capitals with generous letter-spacing for labels; numerals tabular so counters never change width.
- **Renders** use macOS system fonts as placeholders (Avenir Next Condensed). They are not shippable.
- **Chosen for the game:** Barlow Condensed Bold (SIL OFL, `apps/game/assets/fonts/`, licence beside it), bundled, with letter spacing and tabular numerals set in code. The web app has not adopted it yet; the choice is open until both use the same font. The original brief for the choice follows.
- **To decide:** one open-licensed (SIL OFL) condensed sans, bundled in both Godot and the web app (not loaded from a third-party host at runtime). Evaluate a few candidates on the tile wordmark and on 12–16 px labels before choosing, and record the license beside the font files. Do not use monospaced or pixel faces as the primary identity.
- Keep body copy short. Long text uses sentence case; capitals are for labels, titles, and button text.

Reference sizes at the 390 px-wide design width (adjust per platform and test on devices):

| Role                  | Size  |
| --------------------- | ----- |
| Screen title          | 34    |
| Level title           | 22    |
| Button label          | 15–22 |
| Body, messages        | 14–16 |
| Caption, step numbers | 12–13 |

## 4. Shape and board language

| Element               | Rule                                                                                                   |
| --------------------- | ------------------------------------------------------------------------------------------------------ |
| Tile / button / field | Square with the top-right corner chamfered. Chamfer is about 0.2 of tile size (12 px on a 58 px tile). |
| Board cell            | Square, 2 px gap, no chamfer, no grid lines                                                            |
| Floor                 | `floor` fill                                                                                           |
| Wall                  | `wall` fill with diagonal `wall-hatch`; yellow-striped when it caused a failure                        |
| Target                | Yellow cell with a ring and a dot (none when the goal is to visit every cell)                          |
| Breadcrumb            | An ink arrow in the cell, pointing to the cell it leads back to; replaces the trail marker             |
| Trail                 | `trail` tint plus a small square marker (so it does not rely on tint)                                  |
| Automaton             | Chamfered ink block with a yellow wedge pointing along its facing                                      |
| Outline control       | 2 px `ink` inset outline on a `ground` fill (the fill hides content behind overlays)                   |
| Toggle                | Chamfered tile: filled yellow with ON, outlined with OFF                                               |
| Dashed outline        | An empty slot or content that is not downloaded                                                        |

## 5. The tape and the game screen

### Layout (portrait, 390 × 844 reference)

1. Top bar: back, level number and title, hint, menu.
2. Objective row: the goal on the left, command count on the right. After a run, a plain-language result replaces it.
3. Board: the full content width (350 px at the reference size), square.
4. Program: the tape.
5. Commands: Move, Left, Right as large tiles.
6. Controls: Step, Run/Continue (the one primary), Reset.

A level with test boards adds a row of **board tabs** between the objective row and the board (40 px high, nothing is added for a single-board level). A tab is a chamfered tile: the shown board is solid ink, the others are outlined. A board solved by the current program carries the check icon beside its label, so state is never colour alone. Labels read BOARD 1, BOARD 2 and so on; when they would not fit (more than three boards on a phone) they shrink to the numbers and the word BOARD stands once at the start of the row, so six tabs fit 360 px. While a run is on or the level is solved the other tabs are disabled. The board stays at least 120 px square.

If height runs out, the board shrinks last; the tape and commands compress first. Do not let cells become hard to tell apart.

### Tape

- A continuous strip. The read-head is fixed at its center (a yellow line with a downward triangle). The strip slides so the current instruction sits under the head.
- **Tile states:** executed = solid ink; current = yellow; upcoming = outlined; empty slot = dashed. Step numbers sit under each tile.
- **Ready (editing):** the strip is left-aligned with no head and a dashed plus slot at the end. Tap a command to append; tap a tile to select it for removal or reordering. Dragging is optional, never required.
- **Loops:** a loop is a **count tile** (outlined, "x3") followed by its body tiles inside one 2 px ink bracket with the chamfered corner; the bracket is dashed while the loop is open and takes the next command. The count tile turns solid ink when selected, and while running it reads "round/count" ("2/6"). Tiles in a body are numbered like any others: one number per slot. Selecting a count tile shows minus and plus tools; Remove deletes the whole loop and moving it moves its body. The Repeat command tile uses a two-arrow icon and reads End loop (with a check) while a loop is open. With four commands in the row, labels drop to 14 px. **Repeat until** is a second loop group drawn the same way (same bracket, same body tiles, same numbering), with its own header and command tile. The header is an outlined square tile with the chamfer, a wall icon (an arrow running into a bar) above the words UNTIL and BLOCKED on two lines (the icon is dropped when the tape is compact and the tile is under 48 px; the words stay, so the shape never carries the meaning alone). It has no count, so selecting it shows no minus or plus tool. It turns solid ink when selected or passed during a run; the loop the read-head is in shows ROUND over the round number in place of the words. The command tile uses the same wall icon and the label UNTIL (END LOOP with a check while its loop is open). With five commands in the row the tiles stack the icon over the label and the label shrinks, never below 8 px, to fit.
- **If:** an If group is drawn as a bracket of its own (2 px ink, chamfered corner, dashed while open). It holds an **If header** (an outlined square tile reading IF over an arrow icon and the word AHEAD, LEFT or RIGHT; on a compact tape under 48 px the arrow is dropped and the two words stay, so the sensor is always readable as text), the then tiles, an **Else divider** (a dashed outlined tile with the word ELSE, no number, not a slot) and the else tiles. The header turns solid ink when selected or passed during a run. An If in a loop body is drawn inside the loop's bracket. Commands of a branch that the run did not take stay outlined. Sensor arrows are a stem and a filled head pointing up, left or right; the If command tile uses a forking-arrows icon and reads END IF with a check while open; the Else tile is text only. The UNTIL GOAL header swaps the wall icon for a ring with a dot and the word BLOCKED for GOAL. Six palette tiles stack icon over label and the label shrinks, never below 8 px.
- **Procedures:** a definition is drawn at the start of the tape (before the main program) as a bracket of its own (2 px ink, chamfered corner, dashed while open). It holds a **Proc header** (an outlined square tile with a bracket-and-bars icon, the word PROC and the name A, B or C as a large letter; on a compact tape under 48 px the icon is dropped and the word and letter stay) and its body tiles. A loop or an If inside a definition is drawn exactly as in the main program, in a bracket inside the definition's bracket. A short ink divider separates the last definition from the main program. A **Call tile** is an outlined square with an arrow-to-bar icon, the word CALL and the name; it is solid ink once passed and yellow while its procedure runs. The header turns solid ink when selected or once the run has reached it. The Proc command tile uses the bracket icon and reads END PROC with a check while open; Call command tiles read CALL A, CALL B, CALL C. The palette keeps up to six tiles in one row; with more it splits evenly into two rows of at least 44 px height, and every tile stacks the icon over a label that shrinks, never below 8 px. All of it uses ink, ground, floor and the one signal fill; no new color.
- **Counter and breadcrumb tiles:** the **Inc** command tile is a "+1" glyph over the label INC; the **Mark** tile is a dot with an arrow behind it over MARK. As tape cells they are plain command tiles (outlined, solid when passed, yellow when current). The count tile of a loop that counts with N reads "N" under a three-rising-bars icon (the icon is dropped on a compact tile; "xN" stays). While running the caption above the tape also reads "PROGRAM N 3". Same ink, ground, floor and signal fill; no new color.
- **Nested loops:** the inner loop is a bracket inside the outer loop's bracket (each 2 px ink, chamfered, 5 px apart), drawn exactly like a single loop; the dashed bracket and the plus slot belong to the loop being filled. On a level with nested loops the loop command tiles keep their labels while a loop is open and a separate END LOOP tile (check icon) closes the open loop.
- **Else if:** an else-if chain is one If bracket. An **ELSE IF header** is the If header with the words ELSE IF in place of IF (an outlined square tile, the same icon-and-side layout, ink when selected or passed). It stands where the ELSE divider would stand and replaces it. Breadcrumb sensors use three icons: an arrow (CLEAR), an arrow that ends at an empty square (NEW), and a dot with an arrow leaving it (BACK); a compact tile that has no room for the icon shows IF, NEW or BACK, and the side as three short lines. The **Else if** command tile is the forking-arrows icon over ELSE IF; it shows beside Else only while an If is open. With up to thirteen palette tiles the row splits into two rows of at least 44 px height; the label shrinks, never below 8 px.
- **Failure:** the failing tile shows an X; the wall that was hit turns yellow-striped; the message names what happened.
- **Solved:** all tiles are executed; a result block shows commands used, steps, and best; Next is the one primary action.

### Overlays

Hint, pause, and similar overlays use a near-opaque scrim of the `ground` color with solid tiles on it. Outline buttons keep their solid fill so nothing shows through. A hint is a solid ink block with a yellow chip label.

## 6. Motion

Animation explains the simulation; it does not delay it.

- Each step is short and consistent; the tape slides one tile and the automaton moves one cell together. Run speed (Slow, Normal, Fast) changes step duration.
- A blocked move gets a small nudge and the yellow wall stripe, not a large shake.
- Level completion uses a brief highlight; no confetti or particles.
- With **Reduce motion**, tape and automaton jump to the next state with a highlight instead of sliding, and result transitions are instant.
- Control feedback is 150 ms or less. Nothing loops while idle. Animation pauses when the app loses focus.
- Animations display simulation events; they never define game logic.

**On the public site** (`apps/web`), motion is CSS first, never idle, and under the same limits:

- The first things of a page rise one after another as it loads (`.rise`, 200 ms, once).
- Boards, worlds and list items rise or pop as they scroll into view (`.view-rise`, `.view-pop`, driven by the scroll with `animation-timeline: view()`, so they have no length of their own); a browser without it shows everything at rest. The big sections still slide in once with `Reveal`.
- Under a pointer a board, a world or a key lifts a few pixels (`.lift`, 150 ms) and a text link gets a heavier rule; the navigation links draw a rule from the left. Only on devices that hover.
- A thin bar at the top follows the scroll, the header stays at the top and gains its rule once the page has moved, and the phone on the landing page drifts up a little slower than the page.
- All of it sits inside `prefers-reduced-motion: no-preference`, so reduced motion switches it off, and none of it needs JavaScript.

## 7. Voice and copy

Short labels in capitals for controls; plain sentences for explanations. Explain what happened and what the player can do next.

Use:

- “THE AUTOMATON TRIED TO MOVE INTO A WALL”
- “THE AUTOMATON TRIED TO MOVE OFF THE BOARD”
- “THE PROGRAM ENDED BEFORE THE GOAL”
- “THE PROGRAM RAN TOO LONG AND WAS STOPPED”
- “LEVEL SOLVED”
- “THIS LEVEL COULD NOT LOAD” with “Levels you have already downloaded still work offline.”
- “UPDATE ALGOMIND” with the level's required version.

Avoid “Wrong!”, “You failed!”, taglines, error codes, long tutorial paragraphs over the board, and tooltips as the only way to learn an essential control.

## 8. Screens and states

The 15 game screens are listed in [design/SCREENS.md](design/SCREENS.md). Every one must exist in both themes before UI is considered done. Level tiles distinguish four states, each with a shape or icon as well as a visual treatment: **solved** (solid ink), **current** (yellow), **locked** (faint outline), **not downloaded** (dashed with a download icon). Worlds use the same four states. The world picker is a list of world tiles; the world screen shows each chapter's level tiles. Never conflate “not downloaded” with “locked by progression.”

### Social screens, stars, and board rows

Profile, Badges, Leaderboard and Daily share one frame (`PanelScreen`): back tile, small caption, title, a scrolling list, and up to three actions at the bottom (primary, secondary, tertiary). They add no new shapes or colors.

- **Star glyph.** A five-pointed star drawn from shapes (`StarGlyph`, also the `star` icon in `UiKit`). Earned stars are solid and the others outlined, so the count reads without color. A solved level tile shows its stars in place of the check, with the level number below; the legend's SOLVED swatch shows a star. The accessible name carries the count ("Level 05, solved, 3 stars").
- **Board row.** A 56 px row: rank, name (shortened with an ellipsis), then the result, with a hairline under it. The player's own row is a solid ink tile with a yellow YOU tag (shape and word, not color alone). REPORT is a small underlined tertiary action at the right of another player's row; hidden-name rows have none.
- **Badge row.** An 84 px row: a 44 px tile (solid with a check when earned, outlined with a lock when locked), the badge name, EARNED and the date or LOCKED, and the description in two lines.
- **Solved screen.** Share and Ranking are two secondary tiles in their own row above the result figures. Share reads COPIED for two seconds after copying (no animation).
- **States.** Loading, offline, signed out, empty and error are plain lines of text with one action (Try again, or Sign in): no illustrations.

## 9. Public website

The public site uses the same tokens, shapes, tile wordmark, and rules as the game, so it reads as the same product.

- Purpose: get people to install the app. Download is the single primary action. Launch pages: landing, download, how to play, privacy, contact. Later: level catalog and detail, play (browser build). See [README_WEB_PLAN.md](README_WEB_PLAN.md) and the renders in [design/web/](design/web/).
- The game appears as flat chamfered screens, not inside device bezels.
- Show real board renderings of published levels using the game's tile semantics. The product is the visual; avoid stock imagery and illustration.
- One primary action per screen (Download); secondary actions are underlined text.
- Pages are complete and readable without JavaScript. The browser game loads only after the visitor presses Play.
- Both themes follow the visitor's system setting, with a visible toggle.
- Respect reduced-motion; nothing loops.

## 10. Admin dashboard

Features, screens, and flows are in [README_DASHBOARD_PLAN.md](README_DASHBOARD_PLAN.md); renders are in [design/dashboard/](design/dashboard/).

The dashboard uses the same tokens and rules but is denser and utilitarian. It must not look like a stock component library.

### Main areas

- **Navigation:** Levels, Create Level, Settings (add sections only when needed).
- **Level list:** title, status (Draft, Published, Archived), published version, last updated, difficulty, actions.
- **Level editor:** metadata, board setup, initial state, allowed commands, constraints, goal, hints, reference solution.
- **Preview:** a readable preview that uses the same tile renderer and semantics as the game, with the tape and step controls running the reference simulator.
- **Validation panel:** human-readable errors and warnings linked to the relevant field, including solvability.
- **Publish panel:** a summary of the version about to be published, with a clear confirmation step.

### Publishing safety

- Draft and published states are visually distinct (draft uses an outlined tile; published uses solid ink).
- Saving a draft never publishes it implicitly.
- Publishing explains that it creates a new version.
- If validation fails, Publish is disabled and actionable errors are shown.
- Unpublishing requires confirmation and states that new fetches will no longer list the level; it does not imply cached copies disappear from devices.
- The currently published version is always visible.
- Session expiry signs the admin out automatically and preserves unsaved draft edits locally where possible.

### Responsive behavior

- Desktop first for the full editor, with usable tablet behavior.
- On narrow screens, stack metadata and validation panels rather than squeezing columns.
- Full keyboard navigation with visible focus states. Focus rings use **ink**, not signal (signal fails contrast on the light ground), and on chamfered tiles they are drawn inside the shape because `clip-path` clips an outer outline.
- Visible save status: Unsaved, Saving, Saved, Save failed. Warn before discarding edits.
- Keep primary actions obvious and destructive actions separated.

## 11. Accessibility and usability

- Text and icons meet contrast on their backgrounds in both themes (see section 2).
- Controls have accessible names. Touch targets are at least about 44 × 44.
- Color is never the only signal: every state has a shape, icon, number, or label.
- Visible focus states in the web app.
- Reduce motion is supported and respects the system setting.
- Sound is never the only feedback for any state.
- Test on real phone-sized screens, not only a desktop window.

## 12. Process and verification

You cannot judge a design you have not seen. Designs and UI changes follow gates:

1. **Concept** (done): direction chosen and rendered in both themes.
2. **Tokens and doc:** this document, the token source, and generated palettes agree.
3. **Gameplay screen first:** implemented fully, both themes, every state (ready, running, failed, solved).
4. **Remaining screens:** built only from existing parts. A new part is added to the system, and the doc is updated, with a stated reason.
5. **Web:** public pages and dashboard built from the same parts.

Verification:

- A debug-only screenshot path in the Godot build (a command-line argument that saves a frame and quits). It is not present in release builds.
- Capture each screen at **390 × 844**, **360 × 640**, and **412 × 915**, in **both themes**, with realistic state (a program on the tape, a trail on the board).
- Look at every screenshot and list what is wrong before reporting a screen done.
- Run the visual checklist below on each.

## 13. Visual-design acceptance checklist

- [ ] Cover the wordmark: could this be another app? If yes, fail.
- [ ] The board is the clear focal point; the tape is second.
- [ ] The automaton's facing is clear at a glance.
- [ ] Every command has a distinct icon and label; commands are distinguishable in grayscale.
- [ ] Success, failure, blocked, locked, not-downloaded, and loading states are visually distinct without color.
- [ ] No gradient, glow, shadow, glass, particle, card, two-tone headline, tagline, or exclamation mark anywhere.
- [ ] Exactly one primary button per screen.
- [ ] Every color comes from the generated tokens; none are hand-defined.
- [ ] Both themes pass contrast and look intentional.
- [ ] Layout holds at all three phone sizes with no overlap and no stretched board.
- [ ] Controls are usable with touch, without mandatory dragging.
- [ ] Reduce motion works and nothing loops while idle.
- [ ] The public site works without JavaScript and matches the game's visual language.
- [ ] The dashboard distinguishes drafts from published versions immediately, and a failed save or invalid publication is visible and actionable.
- [ ] This document matches the code.

## 14. Depth direction (approved, not yet built)

**Why.** The flat board (white squares, hatched blocks, a small triangle) and a flat interface read as plain and boring. A flat interface with a 3D board pasted in looked worse (tried and rejected). The depth direction changes the whole app together. Concept renders: [design/depth/](design/depth/) (menu, worlds, play in four states, large boards), generated by `scripts/concept-3d/depth.mjs`. Plan: [README_3D_VIEW_PLAN.md](README_3D_VIEW_PLAN.md).

**What stays.** The chamfered tile as the unit, the tape of instruction tiles, the one signal yellow (a fill with ink on top, never text on the light ground), the condensed type, the tile wordmark, light and dark themes both first-class, "color is never the only signal", the voice and copy rules, and reduce motion.

**What changes.**

- **Keys, not slabs.** Tiles and buttons are physical keys: a face, a visible lip of thickness, and a soft shadow. The primary button is a yellow key. The tape sits in a recessed trough and the read-head is a marker over the current key.
- **A board plate.** The board is a tray on the ground: a dark plate, floor tiles with a thin lip, walls as low blocks (about 0.6 of a cell, so they hide little), the goal as a raised yellow pad with its ring and dot, the automaton as a chamfered block with the wedge on its top face.
- **Camera.** Fixed, no free rotation. Pitch and perspective depend on board size: about 62 degrees with perspective for boards up to about 6 cells, easing to about 80 degrees and almost no perspective by 12 cells. Isometric is rejected (smallest cells, and blocks hide cells).
- **Light.** One light from the upper left. Allowed: a soft vertical ground gradient, three-tone face shading, a soft contact shadow under pieces and keys, and a thin lighter top edge. Still not allowed: glow, blur on content, particles, frosted glass, and 3D models or textures on the interface.
- **Patrols.** An obstacle that moves by a pattern is a diamond with a ring and a dot (a shape no wall or automaton has; built), its route is a thin line with a dot on each cell (built; numbered stops are not), and a caught guard turns signal yellow. A "stop by step" strip (planned, not built) would show where it is at each step ([README_GAME_RULES.md](README_GAME_RULES.md), section 3.9).
- **Keys and doors.** A key is a ring with a shaft and a tooth, a shut door a block with a keyhole (raised on the depth board), an open door an outline; with several locks a key and its door carry the same number of pips, so pairing is never only a color (built).
- **Crates and docks.** A crate is a solid square with a strap, a dock four corner brackets (with the crate inside once delivered); the crate carried is small and signal yellow on the automaton. With several deliveries a crate and its dock carry the same number of pips (built).
- **Switches and gates.** A switch is a plate with a lever whose knob moves from left to right when flipped; a shut gate is a block with bars (raised on the depth board), an open gate two posts; pairs share pips (built).
- **Ice and belts.** Ice is a floor cell with a thin inset outline and two glints, a belt two chevrons pointing the way it carries; the automaton slides through each cell of a step (built).
- **Teleporters.** Each end is two concentric rings (the target is a ring around a dot); pairs share pips; the automaton walks to the end and appears on the other (built).
- **Recursion.** A CALL with a sensor reads CALL IF and shows the sensor icon in place of the call icon; a Call tile can be added while a definition is open (built).
- **Failure.** The cell where a run failed is hazard-striped and the piece involved is outlined, so failure is a shape, not only a color.

**Colors.** Shades are never written by hand. The token generator in `packages/design-tokens` derives the face shades and the shadow color from the tokens, and tests check their contrast and that this table matches the token source (`packages/design-tokens/tokens.json`, key `depth`). The generated `DepthPalette` in the game holds these and the derived shades (lips, front, side, and edge shades). The base tokens:

| Token           | Light     | Dark      |
| --------------- | --------- | --------- |
| `ground-top`    | `#F3F1EB` | `#1B2028` |
| `ground-bottom` | `#DCD9D0` | `#0B0D10` |
| `ink`           | `#14181D` | `#F2F2EE` |
| `on-ink`        | `#FFFFFF` | `#0E0F11` |
| `mute`          | `#4E545C` | `#A9B1BC` |
| `tile`          | `#FBFAF7` | `#3A424E` |
| `strip`         | `#CFCBC1` | `#12151A` |
| `plate`         | `#2A2F37` | `#1F242C` |
| `floor`         | `#ECEAE3` | `#4A5362` |
| `wall`          | `#4B5461` | `#9AA5B6` |
| `wall-hatch`    | `#667082` | `#B6BFCD` |
| `trail`         | `#F7DF8A` | `#6B5A1C` |
| `signal`        | `#FFC20E` | `#FFC20E` |
| `on-signal`     | `#14181D` | `#0E0F11` |
| `shadow`        | `#14181D` | `#000000` |

**Cost.** The game draws everything with `_draw()`. `DepthKit` (`apps/game/scripts/ui/depth_kit.gd`) draws a vertex-colour gradient, soft shadows from stacked translucent polygons (8 layers a shadow), and offset lips with no shader; it was run in Godot 4.7.2 on the Compatibility renderer (macOS). A key is about 10 draw calls, so a screen with 20 keys is about 200. Android and the browser build are not tested, and the cost must be measured on a phone before it spreads to every screen.

**Dashboard.** The dashboard stays flat and utilitarian; its board editor and preview stay top-down, because authoring needs the plan view.

**Acceptance.** For each screen: both themes, three phone sizes (390x844, 360x640, 412x915), a small, a medium, and the largest board, reduce motion on, and screenshots looked at before the screen is called done.
