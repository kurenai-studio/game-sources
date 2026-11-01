# Scoundrel — UI Layer

This documents the UI: the decisions locked in the design interview, the
visual tokens, the architecture, and every component on screen. It complements
[`design.md`](design.md) (the rules engine); keep both in sync with the code.

> ## Where this stands, 2026-09-24
>
> **Sound** shipped in 2.1.0: the title's volume row and the M key are described here;
> everything else is in [`audio.md`](audio.md).
>
> **This document is current.** It was for a while a mix of what shipped and what was being
> replaced, with a banner telling you to read parts of it as history; that mix has been
> audited out. Where a passage *is* history it now says so in its own line, and says what the
> lesson became.
>
> **There is no Scene2D in the project.** Every screen draws in immediate mode at a fixed
> 1280×720, and the five navigable ones share `PixelScreen`. `CardTiles`, `Choreographer`,
> `Motion` and `Widgets` are gone; so are the *Ashen* palette and both vector faces —
> Silkscreen is the only type in the game, and the colour rule is the two tiers described
> under Design tokens.
>
> **The look.** A torchlit dungeon: a procedural backdrop (warm glow with a live flicker over
> a vignette, drifting embers) and hand-drawn 64×64 pixel sprites at ×2 inside 176×256 framed
> cards. Motion — deal-in, avoid-sweep, HP pulses, the per-card resolve effects, the death
> cinematic — steps on a 12 fps grid; idles run at 6, floored in `Frames`.
>
> The board's own furniture lives in `BoardView` (the room and every effect), `BoardHud` (the
> chrome), `CardFace` (the printing), and `BoardArt`/`CardArt`/`HudArt` (the measurements).

## Locked decisions (from the design interview)

- **Layout: room-centered.** The four room cards dominate the center; thin HUD
  strips top and bottom. No sidebar.
- **Cards: typed tiles.** Role-colored (monster/weapon/potion), big value,
  small rank + suit index in the corner.
- **Input: press-then-pick.** A card with one legal move plays immediately; a
  monster with both fight options pops a small two-button chooser at the card.
  Avoid is a HUD button.
- **A press must never be swallowed.** This UI's recurring bug, and the rule that outlived the
  toolkit that caused it. *(Scene2D is gone; the two traps below are history, but the second
  half of each is still live and still enforced.)*
  1. **Modality is a decision somebody has to make, explicitly.** Under Scene2D the trap was
     `Table` defaulting to `Touchable.childrenOnly`, so only a card's *label glyphs* were
     clickable and presses on the blank part vanished; the same default made the end overlay
     non-modal, and presses fell through to a dead board. Nothing goes through Scene2D now —
     the board hit-tests its own rectangles (`CardHitRegions`) — but the decision did not go
     away, it moved: **`PixelScreen.modal()`** is where a screen says that a click hitting none
     of its targets is swallowed rather than passed through. The run-end panel, the abandon-run
     question (the board's own input processor makes the same call) and the erase confirmation
     are modal; the tutorial callout deliberately is not, because playing the board is the whole
     point of it.
  2. **Cards act on _press_, buttons on _release_.** Scene2D's `ClickListener` only fired when
     the release landed back on the same actor, so fast play — the mouse already travelling to
     the next card as the button came up — silently lost clicks. The distinction survives the
     toolkit and is now deliberate: cards resolve on press, and every button goes through
     `PressGesture` so a press can be taken back by sliding off.
- **Menu buttons act on release, and show the press while they wait**
  (`PressGesture`, added 2026-08-10). The pixel menus hit-test their own
  rectangles, so they get none of Scene2D's button behaviour for free and had
  been acting on the press instead. Three parts, and the third is the one that
  is easy to miss:
  1. The release only counts where the press began. Sliding off lifts the plate
     and cancels; sliding back on re-arms it, because a wobble on the way to a
     click is not a change of mind.
  2. A held plate is drawn **pressed** — the bevel inverted, the face on its
     shadowed step, the label travelled 2px down and right into the recess
     (`Chrome.plate`). Release semantics without this read as a button that did
     not work. A mode panel is the button on its own screen, so it takes the
     same treatment; its *frame* stays put, because 1200px of panel shifting
     bodily would eat the 14px gap below it and read as a layout fault. The
     recess is drawn inside the frame, so a selected panel keeps its gold edge
     and gains the press rather than choosing between them.
  3. A screen with more than one kind of target hit-tests into **one id space**,
     because the gesture matches a release against a press by equality and
     cannot know which family an index came from. Panels and buttons are their
     own index, −1 is nothing, and shared chrome takes the negatives below that
     (`ScreenArt.BACK`). The two families must not overlap on screen either, or
     a point would have two answers and which won would come down to the order
     of the ifs — pinned by `ScreenArtTest`.
  4. **The action fires from `render`, not from the release.** A click is often
     shorter than four frames and every menu button navigates, so acting the
     instant the button came up cut to the next screen before the sunk plate had
     been drawn once — release semantics that felt *less* responsive than the
     press-to-act they replaced. The release arms; `PressGesture.advance` fires
     once the plate has actually been on screen for 60ms. Note the hazard that
     goes with it: navigating disposes the calling screen, so `render` must
     `return` immediately after — see the death-cinematic note below.
- **Event log: fading feed.** The last few events float top-right and fade;
  no permanent log panel.
- **Flow (revised 2026-07-07):** launch lands on a tiny **title screen** —
  the navigation anchor every future menu (variants) hangs off: New game /
  Records / Trophies / a dim credit line. Win/loss dims the board under an
  overlay with the score, best line, any freshly unlocked achievements, then
  New game / Trophies / Records. **Records and Trophies are reachable only
  between games** (title + end overlay): a run, once started, can't be paused
  to visit them. *(Revised 2026-09-25: it can be abandoned — ESC asks first —
  and an abandoned run is recorded nowhere, consistent with quit-outs being
  unrecorded.)*
- **Window:** resizable, 1280×720 default, `PixelViewport` — a fit that snaps the scale down
  to a multiple of 0.5 and letterboxes the rest, so pixel art always lands on whole screen
  pixels. See the architecture note below for why a plain fit was not enough.
- **Mood: torchlit dungeon** — dark, warm, quiet.

## Design tokens

**The palette is two tiers, and `Theme` is not where it lives.** The *Ashen* seven-token
table this section used to carry went with release 1; six of the seven had no reader left by
the time they were deleted.

| Tier | Where | What it governs |
|---|---|---|
| The eighty | `Ramps` | Sprite pixels. Nine ramps of eight steps plus eight accents (`HANDOFF.md` §6). The hurt and rim generators snap unmatched colours to the nearest entry, which is how six part-off-ramp creatures still flash on-palette |
| The thirty-two | `UiPalette` | Every colour drawn in code that is *not* on a ramp — the §11 chrome, the potion bottle's glass, the cleaved card's cut faces, the HUD tints. All sampled from the reference render, each with a comment saying what it draws |

`UiPaletteTest` scans both declaration forms out of the source and fails on a colour in
neither, so a new one has to be justified rather than merely typed. What it cannot govern is
blended output: a shadow drawn as `0x000000` at half alpha is off-ramp by construction, and
that is where §11's "flat colour, never alpha" quietly loses.

`Theme` keeps exactly two colours, the ones the torch itself is lit in — `TORCHLIGHT`
(`#d9a441`) and `BONE` (`#e8ddc7`) — both on the accent ramp.

Type: **Silkscreen, and nothing else.** Generated at startup via `gdx-freetype` from the two
TTFs in `assets/fonts/` (SIL OFL, licence bundled), rasterised at 1:1 with `mono = true`,
`hinting = None`, gamma 1 and **Nearest** filtering — the opposite of how a vector face is
loaded, and the reason the readout renders in exactly one colour where Alegreya took 27.

IM Fell English and Alegreya Sans are **gone**, files and all: they set type on nothing after
the last two overlays were converted, and the three TTFs left `assets/` with the default
libGDX skin. The old display face's old-style numerals were a period touch worth remembering
and not worth keeping a vector face for.

Silkscreen has no suit glyphs, so ♠♥♦♣ are rasterised from geometry (`PipMask`, `Pips`) rather
than drawn as font characters; feed copy writes names out ("the Queen of clubs").

Its sizes are the only ones anything may ask for, and they live in `PixelType`: 8, 12, 14, 26,
38. All even, because the viewport snaps to half-steps and an odd size lands on a half pixel
at ×1.5.

**Nothing below 12 for anything a player reads.** Silkscreen's strokes are 1px,
so at the ×1.5 a 1920×1080 display gets, each stroke lands on either one screen
pixel or two depending where it falls. On a 12px glyph that is coarse; on an 8px
one it is the difference between a letter and a smudge. `SMALL` (8) survives for
incidental furniture only — a portrait caption, a credit line. When a string
does not fit at 12, wrap it and grow the row (`TextWrap`) rather than dropping
to 8.

## Architecture

- **View = f(state), drawn from scratch each frame.** `GameScreen` holds the
  immutable `GameState`; every move runs `apply` and replaces it, and the board
  is drawn from that state on every frame. There is nothing to update
  incrementally — if the state is right, the screen is right. Motion never
  weakens this: an effect plays *over* a board that is already final, so no
  animation ever carries game state.
- **`BoardView`: the room and everything that happens to it.** It owns the idle
  clock, each card's stagger, and the single effect currently running; it owns
  no game state and no rules. `GameScreen` tells it which cards are in the room,
  what just happened to one of them, and where the pointer is. The developer lab
  (`SpriteLab`, F9) draws through the same class, which is the only thing that
  makes it a useful instrument.
- **Effects are blocking but skippable, and no click is ever wasted.** While one
  plays, a press settles it *and* resolves whatever card it landed on. Always
  safe, because the state underneath is already final. Each effect is a pure,
  unit-tested timeline quantised to a 12 fps grid — `CardFlight` (the deal, the
  avoid sweep, the equip carry), `Barehanded`, `WeaponKill`, `PotionDrink`,
  `PotionSpill`, `HpPulse`, `DeathCinematic` — and nothing tweens: every value
  holds for a whole frame.

  Resolving a card sets **three clocks** going, and they are not one thing:
  what happens to the card that left, the survivors re-centring around the gap,
  and whatever the dungeon sends up to replace it. The first two run *together* —
  the room closes over the gap as the monster dies — while the deal waits, because
  a fresh card flying over the one being killed is a different thing entirely.
  `RoomMotion` is the four-case decision, and it has its own test because "which
  clock is this card on" was got wrong twice.

  A fresh card comes out of the depth ticker, the dungeon made physical, and the
  ticker keeps counting it until it lands. The heal from a potion waits for the
  bottle to actually pour, so the bar filling always has a visible cause — and a
  *wasted* potion never goes near the bar at all, spilling grey where it stood.
- **Death cinematic.** A losing blow withholds the end overlay until the
  cinematic has run, and at ~5.5s it is deliberately the slowest thing in the
  game — every other effect was cut to get here, and this is what the time was
  taken for. The fatal blow plays at **half speed**; the board is then left
  **standing, lit and unmoving** for the best part of a second, long enough to
  read the empty bar and the number under zero. Only then does the torch gutter
  out over it — held values, not a ramp, because a dying flame flares back —
  while the screen goes out by **ordered 4×4 dither: pattern, never alpha**, so
  the board thins out rather than dimming.

  The **depth ticker is drawn over the dither** and outlives everything else, so
  the last thing on screen is the gauge that says how far you got; then it goes
  too, a beat before YOU DIED grows in. The dungeon deals nothing after a fatal
  blow — the room closes over the gap, but you are not being sent another card.
  A click fast-forwards straight to the settled screen at any point. Only losses
  animate — a win keeps the instant `DUNGEON CLEARED` overlay, and the tutorial
  never dies.
- **Navigation.** `ScoundrelGame` is the navigator: it owns the shared
  `Theme`, `RunLog`, and `AchievementStore`, exposes
  `showTitle`/`showGame`/`showRecords`/`showTrophies`, and disposes the
  outgoing screen on every switch. Screens are cheap and built fresh each
  time; nothing is cached across switches.
- **Dumb view.** The screen calls only `newGame` / `legalMoves` / `apply`.
  Everything conditional (Avoid enabled, instant-play vs chooser, chooser
  contents) derives from `legalMoves`. Zero rule logic in screens — even
  damage previews were omitted rather than duplicate combat math in the UI.
- **`Theme` owns what the GL side needs**: the Silkscreen faces at their five sizes, the
  generated textures the backdrop and the dither draw from, and the two accent colours the
  torch is lit in. Created once in `ScoundrelGame`, disposed once, passed to screens. It used
  to own the palette and a set of flat drawables; the drawables went with Scene2D and the
  palette went to `Ramps` and `UiPalette`.
- **`PixelScreen` is the frame every navigable screen draws inside** — the batch, the
  viewport, the surface, the backdrop, the chrome and the press gesture, declared once instead
  of five times. Its `render` is **final**, and that is the point: activating a target
  navigates, navigating disposes the screen, and drawing afterwards reads freed native memory
  and takes the JVM down rather than throwing. The guard sits above a `drawContent` a subclass
  cannot reach until the check has passed, so the mistake is no longer expressible. Four hooks
  carry the differences — `advance` (extra clocks), `backdropLight` (the death's guttering
  torch), `modal`, and `escape` (the title has nowhere to go; the ledger closes its dialog
  first; the board asks before abandoning a run). `GameScreen` replaces the frame's input
  processor with its own, so anything the frame routes — ESC included — reaches the board only if
  the board routes it too; ESC didn't, and until 2026-09-25 a run could only be left by
  finishing it. `SpriteLab` deliberately stays outside it: no press gesture, no backdrop, and
  nobody navigates to a developer tool.
- **No skin, and now no Scene2D.** Styles used to be built in code rather than
  from a `Skin` JSON/atlas, to keep them compiler-checked. That question is
  moot: nothing builds a widget any more. Every screen draws tinted rectangles
  and Silkscreen glyphs straight onto a batch through `Chrome`.
- **`PixelViewport` at a fixed 1280×720 virtual resolution** — all layout math
  in one coordinate system, any window size letterboxes. Fonts are generated
  once at design sizes. It is a `FitViewport` that snaps the scale down to a
  multiple of 0.5 rather than fitting exactly, so a 64×64 sprite drawn at ×2
  always lands on a whole number of screen pixels; a plain fit gives ×1.25 at
  1600×900 and the pixel art crawls. The scale arithmetic is the pure,
  headlessly tested `PixelScale`, leaving the viewport itself a thin shell.
- **Draw order is the layering, now that there are no stages.** `GameScreen`
  draws the backdrop, the HUD, the board, the chooser and the feed onto the
  surface, then whichever overlay is up on top of that. Modality is a decision
  in the hit test rather than a property of an actor: the run-end panel
  swallows every press whether or not it landed on a button, and the tutorial's
  callout deliberately does not — only its Skip and Next are targets, because
  playing the board is the whole point of it.
- **Events feed the feed; state feeds everything else.** `MoveResult.events`
  are consumed once for feed lines; persistent widgets render from state.
  `RoomDealt` and `GameWon/Lost` are filtered (board and overlay own those
  facts). The feed shares the observer seam with the `runs` and `achievements`
  layers — one event stream, consumed for different ends.
- **Run recording and achievements.** `ScoundrelGame` builds a `RunLog`
  (`~/.scoundrel/runs.log`) and an `AchievementStore`
  (`~/.scoundrel/achievements.log`) and hands both to the screen. Each game
  gets a `RunRecorder` and an `AchievementTracker`, both fed every
  `MoveResult`. When the game ends, `finishRun` appends the run, then evaluates
  the achievements newly earned (from the run summary plus history) and appends
  each to the store; those fresh unlocks are listed on the end overlay. The two
  storage steps are independently guarded — a failure in either is logged and
  never interrupts play, nor stops the other.

## Components on screen

- **Top strip** — the banded health bar with its reading beside it (`14 /20 HP`,
  unclamped: a killing blow shows how far past zero it took you, and only the
  bar's fill clamps); the **depth ticker** (one tick per card of the deck, gold =
  still face-down, dark = gone) with a `DEPTH n · m:ss` caption under it carrying
  a live run timer — `RunRecorder.elapsedSeconds` off the recorder's
  clock, ticked each `render`, frozen at the final time on game over (so it agrees
  with the recorded `RunRecord.seconds`), and formatted by the shared `ClockText`.
  The tutorial has no recorder, so it shows no timer. The **Avoid** button
  (torchlight when legal, stone when not).
- **Backdrop** — behind every screen, drawn first and never a hit target
  (`Backdrop`): a procedural torch glow (a generated radial texture, tinted
  torchlight, its alpha modulated by `TorchFlicker` — a pure, tested sine-blend
  so it breathes without looping) over a generated vignette, plus drifting
  embers (`Embers`, a pure tested particle sim). All from `Theme`'s generated
  textures; no external assets.
- **Room row** — up to four 176×256 cards, centred for however many are in the
  room. Each is an outer bezel, a role-coloured plate with 2px light/dark
  bevels, and a recessed well holding the 64×64 sprite at ×2. The sprites
  **breathe together**: `SpriteBob` lifts and settles them ±2px on one shared
  clock, eight steps at the idle 6fps, moving the sprite alone while the frame
  and printing hold still. It takes no card argument, which is how the
  synchronisation is enforced rather than merely intended — and it is the
  opposite of `IdleCycle`'s per-card stagger, deliberately (see HANDOFF §7).
  Resting cards only; anything mid-flight or mid-effect owns its own motion. A 26px header
  carries the rank, its suit pip and the type; the footer carries the value at
  38px with a hard 4px drop shadow. Plates come from the ramp system
  (`CardArt.paletteFor`): oxblood monster, slate weapon, moss potion.
- **Chooser** — a stack of the board's own gold plates over the pressed card,
  one per legal move (`USE WEAPON` / `BAREHANDED`), drawn by the same
  `BoardHud.drawPlate` the Avoid button is. Generic: a future card offering three
  moves gets three plates. Every plate takes the widest label's width — a ragged
  stack reads as two unrelated buttons rather than one choice. Geometry and hit
  test are `ChooserArt`; a press *outside* it dismisses the chooser **and**
  resolves the card it landed on, so the press is never spent merely closing it.
- **Trophy rail** (bottom-left) — the equipped weapon's own sprite in a recessed
  well, its name and value beside it, then slain-monster chips in kill order, and
  the threshold plate: `SLAYS ANYTHING` (fresh), `SLAYS < N`, or `SPENT` (slew a
  2). Reads `BAREHANDED` when nothing is equipped — the well is always there, so
  equipping does not shift the strip sideways.

  The rail **lags the engine deliberately**. A move settles the instant you press
  the card, but a weapon still hopping down to the well has not arrived and a
  monster still being cleaved has not died, so neither the icon nor the chip
  beside it may appear yet: `BoardView.railAhead` holds the previous state until
  what you can see agrees.
- **Potion marker** (bottom-right) — the potion sprite in its well with
  `POTION READY` or `POTION USED` beside it. Never dimmed: an alpha over the dark
  board would make colours that are on no ramp, so the label carries the state.
- **Fading feed** (top-right) — up to four lines, fading after ~4s:
  "Slew the Queen of clubs — took 6", "Fought … barehanded — took 12",
  "Drank the 7 of hearts — healed 5" / "— already full",
  "… wasted — one potion a turn", "Equipped the 5 of diamonds",
  "The weapon dulls — slays < 6" / "The weapon is spent",
  "Avoided the room", and "Sound off" / "Sound on" when M is pressed mid-run.
- **Sound** (everything else in [`audio.md`](audio.md)) — each sound fires on its animation's
  beat and a skip plays what is pending; menu buttons click on press; the music crossfades while
  the screens cut, and on a death dies with the torch. **M** mutes everything from any screen,
  polled in `ScoundrelGame` beside F11. Minimised, nothing is heard but the audio keeps time with
  the picture, so nothing plays late when the window comes back.
- **Title screen** — The Debt idling at ×3 in its well; beside it `SCOUNDREL` in Silkscreen at
  52px (the 26px face at ×2) with a 4px hard shadow, then the NEW GAME, HOW TO PLAY, THE LEDGER
  and TROPHIES buttons, the volume row, and a dim designer-credit line. **New game** opens the
  mode picker; **How to play** starts the tutorial. On the very first launch
  (`!TutorialFlag.isSeen()`) a modal **New here?** prompt pops over the menu — **Play
  tutorial** / **Maybe later** — and either choice marks it seen, so it is offered exactly once.
  - **The volume row** (not in the mock; signed off by screenshot): **MUSIC** and **SOUND**
    plates side by side under TROPHIES, 129×36 each — the column's width and gaps, the back
    plate's height. Each shows its level as three pips (gold lit, a sunk slot unlit, grey while
    muted) and cycles OFF → 1 → 2 → 3 on release, un-muting. MUSIC clicks on press like every
    button; SOUND clicks on release, *at its new level*, so the click previews what you chose.
    Under the row, always, a line says what M does: `M TO MUTE ALL`, or `MUTED · M TO UNMUTE`.
    Geometry in `ScreenArt`, text in `Labels.muteHint`, the plate in `Chrome.levelPlate`.
- **Tutorial** — a scripted, guided run played on the real board
  (`GameScreen` in tutorial mode, given a `TutorialGuide`). It deals the curated
  `TutorialScript` deck, records nothing, and layers guidance on top: each step
  marks its target — a room card or the Avoid button — with **eight corner ticks**
  in cream, leaving the edges open (the closed pulsing outline this once described
  went with the pixel conversion; see the TUTORIAL overlay entry below), and a
  **contextual callout** of the narration that points above the card, below the
  Avoid button, or sits under the room for rule-explanation beats. Input is
  **gated** to the current step: only the marked card responds (no chooser), and Avoid is live only on the step that
  teaches it. Explanation beats carry a **Next**; a persistent **Skip tutorial**
  corner button leaves to the title. Clearing the deck shows a **Tutorial
  complete** screen that prints the run's actual score and reads it back as the
  rule that produced it (`Labels.tutorialScore`), then Play for real / Main menu.
  The whole thing teaches every rule in sequence — combat, degradation both ways,
  potions and the one-per-turn cap, avoiding and never-twice, and **scoring** in
  two centred beats where it bites: the negative losing score right after the
  bare-handed 9 halves your health, and what a cleared dungeon is worth (plus the
  20-plus-potion flourish) with the last monster still standing. It is proven
  end-to-end by a headless test that plays the script through the engine to a
  win, and that pins the winning beat's promise — `score == health left` — against
  the real scoring strategy.
- **RUN END** — one 600px panel over the modal dim, covering both outcomes:
  eyebrow, headline with a 4px hard shadow, three figures in a shared frame
  (score, then the middle cell, then time), a `NEW BEST` badge, and the
  trophies the run unlocked. **The middle cell never repeats the score:** a
  clear scores exactly the health you kept, so it reports `DAMAGE TAKEN` — what
  getting out cost — and a death, which has no health left to report, counts the
  monsters `STILL DOWN THERE`, the one figure that explains how far below zero
  the score is. The damage figure is set in the health bar's own blood — the red
  it flashes when you are hit. The verdict and, on a win, the score take the
  outcome's own colour, the green and blood the ledger sets `CLEARED` and
  `DEFEATED` in; the render has the headline cream, and the hard shadow still
  carries it under the colour. A death is the *same layout* with the gold accents
  swapped for dried blood — `EndSummary` decides every word and colour, so there
  is one drawing method and not two. The panel has two heights: a run that
  unlocked nothing drops the rule and the trophy band and shrinks by 114, rather
  than leaving a hole. Its four buttons are sized by their labels and centred as
  a row (`ButtonRow`) on the panel, not the stage.
  - **Each unlocked trophy's row:** its seal, its name, and its deed. The deed wraps
    (`TextWrap`) to the rule's right end (`ScreenArt.END_TEXT_RIGHT`) in at most two lines,
    which share the seal's height. Drawn as one unbounded line, Rock Bottom's ran about
    65 px off the panel (`069b190`).
- **TUTORIAL overlay** — the board under the lighter **veil** (half the modal
  dim: what the step is telling you to click has to stay readable), the taught
  card ringed by eight 24×4 corner ticks, and the narration in a callout that
  points at it with a stepped notch — blocks, never a rotation. The callout
  grows to fit its words and flips above or below its target to stay on screen
  (`CalloutPlacement`); an explanation beat points at nothing, so it takes no
  notch and sits *under* the room where it covers neither cards nor HUD. `STEP
  n OF m` and a dot per beat come from the guide itself.
- **NEW GAME (mode picker)** — headed `NEW GAME` over `Choose your descent.`,
  one hairline-ruled row per mode from `GameModes.all()`: the mode's name as the
  torchlight button that starts the run, what it changes, and a right-aligned
  `trophies count` / `no trophies` tag. That tag states the Standard-only
  achievement rule *where the choice is made*, so a variant run never silently
  fails to unlock. Back returns to the title. A new mode appears here with no
  change to the screen.
- **THE LEDGER (records screen)** — the top 10 runs in one framed table, rows
  striping `191513`/`141110` by **flat colour, never alpha**, beside a 296px
  totals panel. Seven columns: Roman-numeral rank, score (cream, dried blood
  when negative), outcome (`71b45c` cleared / `8c2f22` defeated), **the mode it
  was run in**, date, duration, monsters slain. The mode tag is required
  reading, not decoration: this table is `HighScores.top`, a **single ranking
  across every mode**, so a Frail 14 can sit directly beside a Standard 20 and
  the tag is the only thing that makes the pair legible. Per-mode ranking exists
  but is used elsewhere — `HighScores.bestForRuleset` is what decides the run-end
  panel's `NEW BEST`, so a first Frail run earns the badge without troubling the
  Standard table. The title's best line is `HighScores.best`, overall again. An id with no matching mode renders as the
  raw id rather than taking the screen down. The table's height follows its row
  count, so a short log shrinks the frame instead of leaving it hanging. Empty
  state invites a first run. What a row *says* is the pure `LedgerRow`.
  - The totals panel is **not** the reference render's list. That render asks
    for `WEAPONS BROKEN`, and weapons never break in Scoundrel — they degrade
    and stay equipped, which is the rule the whole game turns on. The row was
    drawn from placeholder data, so the panel keeps the render's shape and
    eight-row rhythm and is filled with figures the game actually keeps
    (`LedgerTotals`), two of them — the score extremes and the fastest clear —
    derived rather than stored.
- **Erase-progress confirmation** — a destructive reset is never one press. The
  Erase control (ledger only — deliberately the one such button in the whole
  app) opens a modal that names exactly what will be lost (`N recorded runs and
  M trophies`). The ledger goes under the **modal dim** first, since the dialog
  asks about the very thing behind it. **Keep it** is the gold plate — the
  opposite of how the rest of the game uses gold, and deliberate: the prominent
  choice here is the safe one. Both plates take release semantics and the
  pressed state, so even `ERASE EVERYTHING` can be taken back by sliding off,
  which is verified by screenshot rather than assumed. Escape backs out of the
  dialog before it backs out of the screen. Confirming wipes both logs as a
  *soft* delete: `clear()` moves each file to a `.bak` sibling rather than
  deleting, so a mistake is recoverable from disk (the game never auto-restores
  it). The ledger then re-shows empty. The dialog is shared: its geometry is
  `ScreenArt.DIALOG_*` and `Chrome.confirmation` draws it, for this and the
  abandon-run question below.
- **Abandon-run question** — ESC on the board (and Android's Back, once there is
  an Android build) never throws a live run away on one press. Mid-run it puts up
  `ABANDON THIS RUN?`, which is the erase confirmation's dialog: the modal dim,
  **Keep playing** as the gold plate and `ABANDON RUN` beside it, with a second
  ESC as the safe answer. Abandoning goes to the title and records nothing — a
  run is filed only when it ends — so there is no ledger row and no trophies,
  exactly as closing the window leaves things. The run clock keeps running while
  the question is up, as it does when the window is minimised. ESC backs out of
  the innermost thing first (`BoardEscape`, tested headlessly): the question,
  then a death still playing (skipped to the end panel, as a click does), then an
  open chooser. It leaves without asking once the run is over (already filed) and
  in the tutorial (recorded nowhere, and SKIP is already one press). The plates
  are silent, like every button pressed during a run.
- **TROPHIES (achievements screen)** — the whole catalog as a book of deeds, ten
  entries in two columns of five, filled **down then across** (getting that
  row-major would silently reorder the catalog and look entirely plausible).
  Each row: a 26px seal well, the title, the deed, and the date won. The seal's
  fill is the *only* difference between earned and locked — §11 rules out a
  padlock glyph and a greyscale filter, so an empty well is the locked state. A
  hidden trophy stays `???` until earned, then reveals its real title and text.
  The header carries a 160×16 progress bar built exactly like the board's health
  bar, down to reusing its dark-green empty track under a gold fill — that reads
  like an oversight and is not, it is what the reference shows. The date a
  trophy was won is kept, which the render drops; it is real information and the
  row has the width. What a row says is the pure `TrophyEntry`.

## Files

- `core/src/main/java/com/tomer/scoundrel/screens/Theme.java` — tokens
  (palette, motion timings, card size), fonts, drawables, suit shapes, and the
  4×4 dither tile every modal overlay dims through. The tile lives here rather
  than on `Chrome` because `Theme` is the one shared, disposed object; a texture
  on `Chrome` would leak once per screen.
- `core/src/main/java/com/tomer/scoundrel/screens/Chrome.java` /
  `ScreenArt.java` — the menu kit: the five parts every screen outside the board
  is assembled from (frame, face, bevel, label, rule), plus `plate` — the one
  button shape, at every size, raised or held down — `header` for the band four
  screens share, `dim` for a modal, and `confirmation`, the one dialog (the
  ledger's erase and the board's abandon question). All the arithmetic is in
  `ScreenArt` where it is tested; `Chrome` only turns measurements into draw calls.
- `core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java` — the one
  screen: layout builders, interaction, feed, overlays (including ESC's abandon
  question), run recording, and (given a `TutorialGuide`) the guided-tutorial
  mode — glow outline, callout, gating, and the Tutorial-complete ending.
- `core/src/main/java/com/tomer/scoundrel/tutorial/` — the pure tutorial logic:
  `TutorialScript` (curated deck + narrated steps), `TutorialStep`,
  `TutorialGuide` (the gating state machine), and `TutorialFlag` (the seen
  marker). No LibGDX; drives the engine via its ordered-deck entry.
- `core/src/main/java/com/tomer/scoundrel/screens/BoardView.java` — the room
  and every effect that plays over it, drawn in immediate mode. Shared with the
  developer lab so the instrument shows what ships. (Replaces `Choreographer`.)
- `core/src/main/java/com/tomer/scoundrel/screens/BoardHud.java` /
  `CardFrame.java` / `CardFace.java` / `Pips.java` / `EffectArt.java` — the
  board's chrome, the card frame, the printing on a card, the four suit pips,
  and the generated shapes the effects use. `BoardHud.drawPlate` is the board's
  one button shape: the Avoid button and every choice in the move chooser are
  the same method, so they cannot drift apart.
- `core/src/main/java/com/tomer/scoundrel/screens/PixelSurface.java` — the
  offscreen target, exactly the design size, that the board is drawn onto so the
  finished image is scaled to the window **once**. Without it every draw call is
  scaled and rounded on its own, and at a fractional window scale identical
  features disagree — see HANDOFF §4.
- `core/src/main/java/com/tomer/scoundrel/screens/TitleScreen.java` /
  `ModeSelectScreen.java` / `RecordsScreen.java` / `TrophiesScreen.java` — the
  navigation anchor, the difficulty picker, THE LEDGER, and the achievement
  catalog. All on the pixel kit, drawn in immediate mode, as are the run-end
  panel and the tutorial overlay that `GameScreen` draws over the board.
  `Widgets` is gone with the last of Scene2D.
- `core/src/main/java/com/tomer/scoundrel/screens/PixelScreen.java` — the shared screen frame
  described above; the five navigable screens extend it.
- `core/src/main/java/com/tomer/scoundrel/screens/Ramps.java` / `UiPalette.java` /
  `Sprites.java` — the eighty ramp colours and the thirty-two drawn-in-code exceptions, and
  the atlas loader that builds the hurt and rim pages at startup.
- `core/src/main/java/com/tomer/scoundrel/screens/Frames.java` — the one place time is floored
  onto the frame grid: `at`, `atPeriod`, `snap`, and the two rates (12 for effects, 6 for
  idles). It multiplies by the rate rather than dividing by a stored `1/12`, which drifts past
  the boundary epsilon after an hour of uptime.
- `core/src/main/java/com/tomer/scoundrel/screens/Backdrop.java` — the ambient
  layer drawn first on every screen: torch glow, vignette, and embers.
- `core/src/main/java/com/tomer/scoundrel/screens/CardHitRegions.java` /
  `TorchFlicker.java` / `Embers.java` / `ClockText.java` / `FeedText.java` /
  `Feed.java` / `Labels.java` / `ResolveEffect.java` / `BoardArt.java` /
  `CardArt.java` / `HudArt.java` / `PixelScale.java` / `PixelType.java` /
  `PressGesture.java` / `LedgerRow.java` / `LedgerTotals.java` /
  `TrophyEntry.java` / `TextWrap.java` / `EndSummary.java` / `ButtonRow.java` /
  `CalloutPlacement.java` / `CornerTicks.java` — the
  pure, headlessly unit-tested logic behind the screens: the "which card is
  under this point" lookup, the flicker curve, the ember sim, the
  run-timer/duration formatting, the event-feed text and its stepped fade, the
  labels, the animation-routing decision, and every board measurement.
- `core/src/main/java/com/tomer/scoundrel/screens/ChooserArt.java` /
  `RoomMotion.java` / `HealthReadout.java` / `PipMask.java` — the same idea for
  the decisions the board makes rather than the numbers it holds: where the move
  chooser's plates go, which clock each card of the room is on, what the health
  bar says (which is not always what the state says), and the four suit pip
  shapes. Each of these was a branch inside a screen before it was a class, and
  three of the four were extracted because that branch had a bug in it.
  `BoardEscape.java` is the same idea written the other way round: what ESC does
  on the board was decided and tested as a class before the screen called it.
- `core/src/main/java/com/tomer/scoundrel/screens/CardFlight.java` /
  `WeaponKill.java` / `Barehanded.java` / `PotionDrink.java` / `PotionSpill.java` /
  `HpPulse.java` / `DeathCinematic.java` / `IdleCycle.java` — one pure timeline
  per effect, each quantised to the 12 fps grid (6 for idles) and unit tested.
  `PotionSpill` is the wasted potion, which goes nowhere near the health bar.
- `core/src/main/java/com/tomer/scoundrel/screens/SpentMask.java` /
  `HurtMask.java` / `RimMask.java` — pixel transforms applied at load rather than
  tints applied at draw, so no blend can land a colour between two ramp steps:
  the drained bottle, the struck creature, and its outline.
- `core/src/main/java/com/tomer/scoundrel/ScoundrelGame.java` — the navigator:
  creates the Theme, RunLog and AchievementStore, boots into `TitleScreen`,
  owns disposal. It also owns the audio (`SoundBank`, `MusicDeck`, the `MusicDirector`, the
  `AudioControls` volume), polls F11, F9 and M, and silences the audio while minimised.
- `core/src/main/java/com/tomer/scoundrel/screens/SoundBank.java` / `MusicDeck.java` /
  `Beats.java` / `AudioLog.java` — the GL side of the audio: the effects, the streams, each
  effect's beat, and the optional sound log. The pure side is the `audio` package; both are in
  [`audio.md`](audio.md).
- `lwjgl3` launcher — borderless-fullscreen at the monitor's resolution (F11 / Alt+Enter toggle a
  1280×720 window), title "Scoundrel"; `SCOUNDREL_NO_AUDIO=1` starts it with no audio device.
- `assets/fonts/` — `Silkscreen-Regular.ttf`, `Silkscreen-Bold.ttf` and the one OFL licence.
  Nothing else: the vector faces and the default libGDX skin were deleted once nothing loaded
  them, 881 KB that had been shipping in every build.

## What survived the illustration pass

The illustration pass has landed: 31 hand-drawn objects and 130 idle frames, every screen on
the pixel kit, Scene2D and both vector faces gone. It changed nearly every line of drawing
code in the project — and touched **none** of the rules below, which is the useful part.

What did not move, and should not:

- **The dumb-view rule.** The screen calls `newGame` / `legalMoves` / `apply` and nothing else.
- **State rebuild as the source of truth.** The board is drawn from the state each frame; an
  effect plays *over* a board that is already final, so no animation ever carries game state.
- **`legalMoves`-driven interaction.** Avoid's enablement, instant-play versus chooser, and the
  chooser's contents all derive from it rather than from re-implemented rules.
- **The event-stream feed**, sharing its observer seam with `runs` and `achievements`.

If an animation needs to know a rule, that is a sign the engine should expose it, not that the
UI should re-derive it. The pass is the evidence: the effects were built against the event
stream and the state, and none of them needed a rule.
