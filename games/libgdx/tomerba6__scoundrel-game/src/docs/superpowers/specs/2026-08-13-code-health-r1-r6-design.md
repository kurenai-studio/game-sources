# Code health R1–R6 — design

**Date:** 2026-08-13 · **Branch:** `ui-revamp-and-sprites` · **Status:** approved, not started

Everything the codebase needs before release 2 is tagged. Every figure below was measured on
2026-08-12/13 and carries the command that produced it; nothing is quoted from a doc.

---

## 1. Why

The pixel-art revamp landed: `HANDOFF.md` has no open steps and no open questions, all six
screens are converted, Scene2D is gone. What it left behind is six pieces of structural debt,
found in two sweeps. None of it is a known player-visible bug — with one possible exception
(R2) that needs a screenshot to settle.

This spec covers the code. It does **not** cover the rest of release 2.

## 2. Scope

**In:** R1–R6 below, all of them, before the `v*` tag that cuts release 2.

**Out, named so they are not forgotten** — each needs its own spec:

- **B · Doc currency.** `docs/design.md` (601 lines) and `docs/ui.md` (493) have not been
  line-audited. `CHANGELOG.md`'s `[Unreleased]` needs to become a versioned section.
- **C · Release mechanics.** `gradle.properties` still reads `projectVersion=1.0.0`. The branch
  is well ahead of `main` — `git rev-list --count main..HEAD`, since any figure written here
  goes stale the next commit. `release.yml` fires on `push: tags: ['v*']`.
- **D · Pre-release verification.** A real playthrough of all three modes plus the tutorial.

## 3. Order

Two real dependencies; the rest is free choice:

```
R5 assets ─┐
R3 Theme ──┴──▶ R1 palette     dead colours would otherwise need carve-out
                               entries in the very table being written

R6 PixelScreen ──▶ R4 extraction   slice GameScreen against a fixed frame

R2 anchors ── independent
```

**Execution order: R5 → R3 → R6 → R2 → R1 → R4.** Deletions first because they shrink what
everything after them has to consider. R4 last because it is the only open-ended item and the
most expensive to verify.

One commit per item, so any regression bisects to a single change.

---

## 4. R5 · Dead assets

**Finding.** 881,084 bytes ship in every build and nothing loads them. The only font loads in
the tree are `Theme.java:80,82`, both Silkscreen.

| Files | Bytes |
|---|---|
| `AlegreyaSans-{Bold,Regular}.ttf`, `IMFellEnglish-Regular.ttf`, their two OFL texts | 734,509 |
| `assets/ui/` — `uiskin.{json,atlas,png}` + four `.fnt`, the Scene2D skin | 146,575 |

**Change.** Delete both groups. `assets/assets.txt` regenerates itself — `generateAssetList` is
wired to `processResources` and rebuilds the list from the directory, so it must not be
hand-edited. Update the CLAUDE.md line that currently reads "pending deletion".

**Done.** `assets/fonts/` holds only `Silkscreen-{Regular,Bold}.ttf` and `OFL-Silkscreen.txt`;
`assets/ui/` is gone.

**Verify.** Launch the game; all six screens render. A missing font would throw at `Theme`
construction, so this fails loudly rather than subtly.

## 5. R3 · Theme's superseded Ashen palette

**Finding.** Eight of `Theme`'s ten colour tokens have **zero references** outside their own
file: `SOOT`, `STONE`, `DRIED_BLOOD`, `IRON`, `HERBAL`, `CARD_MONSTER`, `CARD_WEAPON`,
`CARD_POTION`. They are the release-1 palette that the 80-colour ramp system replaced.

Only `TORCHLIGHT` (`d9a441`) and `BONE` (`e8ddc7`) survive, and both are on the accent ramp.

**Change.** Delete the eight.

**Done.** `Theme` holds only colour tokens with live references.

**Verify.** Compilation is the proof — an unused-constant deletion cannot break at runtime what
it does not break at compile time. `./gradlew core:check` as backstop.

**Note.** `4e2620` survives the deletion independently as `BoardArt.CHIP_FACE`.

## 6. R6 · `PixelScreen`

**Finding.** Six screens each carry their own copy of the same frame. Five of the six declare
the identical five fields, in the same order:

| Screen | viewport | batch | surface | backdrop | press |
|---|---|---|---|---|---|
| `TitleScreen` | :59 | :60 | :61 | :62 | :71 |
| `ModeSelectScreen` | :32 | :33 | :34 | :35 | :57 |
| `RecordsScreen` | :49 | :50 | :51 | :52 | :54 |
| `TrophiesScreen` | :38 | :39 | :40 | :41 | :43 |
| `GameScreen` | :80 | :81 | :87 | :89 | :99 |
| `SpriteLab` | :51 | :52 | :59 | — | — |

Duplicated with them: an identical `dispose()`, an identical `resize()`, the two-pass
surface→window render skeleton, `viewport.unproject(new Vector2(…))`, and — the reason this
item exists — a hand-written guard in every screen:

```java
if (fired != PressGesture.NONE) {
    activate(fired);
    if (game.getScreen() != this) {
        return;                 // navigating disposed batch + surface
    }
}
```

Drawing past that guard is an `EXCEPTION_ACCESS_VIOLATION` that kills the JVM rather than
throwing, so no test can catch it. `run-scoundrel/SKILL.md` records it as having happened.
Five hand-maintained copies of a rule whose failure mode is a native crash, in the one package
outside the coverage gate.

The four menu screens' input adapters are byte-identical too — 21 lines of
`touchDown`/`touchDragged`/`touchUp`, each doing `press.press/moveOver/release(hit(x, y))`
behind a left-button check. Their `keyDown` differs only in what follows a shared
`ESC → game.showTitle()`.

**Change.** One `PixelScreen extends ScreenAdapter` holding `game`, `theme`, `viewport`,
`batch`, `surface`, `backdrop`, `chrome`, `press`.

| Member | Kind | Rationale |
|---|---|---|
| `render(float)` | **final** | Carries the skeleton and the guard. Final is the point: `drawContent` is unreachable before the guard runs |
| `resize(int,int)` | **final** | The `≤0` check plus `viewport.update(w, h, true)` |
| `unproject(int,int)` | **final** | Replaces five copies |
| `advance(delta)` | default → `backdrop.advance(delta)` | `TitleScreen` adds a clock; `GameScreen` advances board, bar, feed, death |
| `backdropLight()` | default → `1f` | `GameScreen` overrides for the death's torch guttering |
| `show()` | default → installs `FrameInput` | `GameScreen` overrides with `BoardInput` |
| `dispose()` | default → surface + batch | `GameScreen` overrides, calls `super` |
| `keyPressed(int)` | default → `false` | `ModeSelectScreen` takes the digit keys |
| `drawContent(float)` | **abstract** | The only part that differs |
| `hit(int,int)` / `activate(int)` | **abstract** | Per-screen target mapping |

`FrameInput` moves into the base: the 21 shared pointer lines, the shared `ESC`, then
`keyPressed`.

`GameScreen`'s input stays its own — cards act on press, plus the chooser, the death-skip and
the Avoid plate — which is why `show()` is overridable rather than final.

`SpriteLab` is **not** converted. It holds three of the five fields, has no press gesture and
no backdrop, and is the F9 developer inspector rather than a screen anyone navigates to. It
keeps extending `ScreenAdapter` directly.

**Done.** Five screens extend `PixelScreen`; `render` is `final`; each screen holds only its
content, `drawContent`, `hit` and `activate`.

**Size.** ≈ −170 lines (**est.** — ~40 frame + 21 input per menu screen, ~40 from `GameScreen`,
against a new class of ~110). The measured figure gets recorded after the change, not before.

**Accepted cost.** A final `render` means a screen needing a different frame cannot have one.
That case exists today — `SpriteLab` — and its answer is to extend `ScreenAdapter` directly.
Preferred over a template with escape hatches, which is how the guard would leak back out.

**Verify.** `core:check`, then a driven screenshot pass over all six screens. This is the only
change that touches five screens at once, so it is the prime suspect if a later pass fails.

## 7. R2 · Anchors

**Finding.** The board's anchors exist twice, under colliding names, and they disagree.

| | value | source |
|---|---|---|
| Rail icon, as drawn | left `32`, top `618` → **centre (64, 650)** | `BoardArt.railIconX/Y()` = `24 + (80−64)/2`, `610 + 8` |
| Equip flight, where it lands | **centre (96, 646)** | `CardFlight.RAIL_X/Y` |

`BoardView:488` flies the card using the same centre convention the deal uses, so the equip
lands 32px right of the well its icon then appears in. At the flight's final 18% scale the card
is about 32px wide — a full card-width of disagreement.

Separately, `CardFlight.TICKER_Y = 60` and `HudArt.TICKER_Y = 26` are the same name for
different things: a flight target centre and the HUD strip's top edge.

**This is not yet a confirmed bug.** Nobody has watched an equip land frame by frame.

**Change.**

1. **First**, screenshot an equip and establish which number is the truth. Two outcomes, and
   they lead to different work:
   - *The card visibly lands off the well* — R2 fixes a live bug. `BoardArt` is the truth,
     because it is what the player sees for the rest of the run.
   - *It looks right* — the offset is absorbed by the flight's final 18% scale and R2 is purely
     preventative. `BoardArt` is still the truth; the flight simply stops asserting its own.
2. `CardFlight` stops declaring anchors; it derives them from `BoardArt`/`HudArt`.
3. Remove the name collisions.
4. A test asserts each flight target equals the furniture centre it aims at.

**Done.** One source for each anchor, no colliding names, and the test in place. The capture from
step 1 is attached to the commit message either way, so the next person knows which case it was.

**Verify.** The before/after equip capture, plus `core:check`.

## 8. R1 · The two-tier palette

**Finding.** CLAUDE.md states the palette rule absolutely — "every pixel sits on a locked
80-colour ramp system… a helpful palette tweak is a regression". That is not true of the code,
and was never true of the art:

- `HANDOFF.md` §8 already records that six of the 26 creature sprites are partly off-ramp, up to
  92% for the Ace. `Ramps` handles it by snapping to the nearest entry before brightening.
- Of 56 distinct `0x` colour constants in `screens`, **35 sit outside the 80.** Twenty are
  specified in `HANDOFF.md` itself (the §11 chrome hexes, `74838f`); the rest are commented
  *"from the reference mock"* and *"from the reference render"* — the potion bottle's glass and
  the cleaved card's cut faces. They were sampled from the art, not invented.
- `HANDOFF.md` contradicts itself: §6 says the 80 "are also the only colours the UI should use";
  §11 then specifies nine chrome hexes that are not among them.

**There are two declaration forms, and the first sweep missed one.** A `0x[0-9a-f]{6}` scan does
not see `Color.valueOf("d9a441")`, so it never looked at `Theme`. Full inventory: **80 constants
in `0x` form, 11 in `Color.valueOf` form.** Of the ten distinct `valueOf` values, only
`8c2f22`, `d9a441` and `e8ddc7` are on a ramp — and the seven that are not are exactly the dead
tokens R3 deletes. R3 therefore removes the whole second-form problem.

**Change.** Two documented tiers.

- **Tier 1 · `Ramps`** (exists, unchanged) — the 80. Governs sprite pixel operations, already
  enforced at runtime by `HurtMask`/`SpentMask`.
- **Tier 2 · `UiPalette`** (new) — every colour drawn in code that is not on a ramp. Each entry
  carries its provenance in a comment: the `HANDOFF.md` section that specifies it, or "sampled
  from the reference render". ~34 entries after R3; the exact list is pinned by writing it.

**The invariant:** *every named colour constant in `screens` is a member of `Ramps` ∪
`UiPalette`.*

**`UiPaletteTest`** — pure and headless, following the file-reading precedent of `RimMaskTest`
(`Path.of("..", "art-reference", "sprites")`), so it reads
`Path.of("src", "main", "java", …, "screens")` relative to the module directory:

1. Scan every `.java` in `screens` for **both** forms — `static final int NAME = 0x…;` and
   `Color.valueOf("…")`.
2. Mask 8-digit ARGB down to RGB.
3. Assert membership in one of the two tables; fail with `file:line` for any stray.
4. Assert the two tables are **disjoint**, so each colour has exactly one right home.

Scanning *declarations* rather than all literals is deliberate: a naive literal scan trips over
`argb[i] & 0xffffff` and `| 0xff000000` in the mask generators, which are bit masks. Every
colour in this codebase arrives as a named constant.

`0xffffffff` (white tint reset) and `0x00000000` (transparent) are excluded by name. `0x000000`
is **not** excluded — it is a real colour here, drawn as three alpha-blended shadow lines
(`BoardHud:178`, `CardFrame:70,75`), and gets a `UiPalette` entry recording that.

**What this test cannot do, stated so the invariant is not overclaimed a second time.** It
governs *declared* colours. It cannot govern what reaches the screen: `fill(…, 0x000000, 0.5f)`
blends black over a plate at run time and produces a pixel that is on no ramp by construction.
Alpha blending is already a documented exception in `HANDOFF.md` §11 ("striping by flat colour,
never alpha") which those shadows quietly break. Bringing them onto flat palette steps is
plausible future work; it would change pixels, so it is **not** in this spec.

**Done.** Both tables exist, the test passes, and `HANDOFF.md` §6's overclaim is corrected in
the same change.

**Verify.** **Zero pixels change** — nothing is recoloured, the tables describe what is already
on screen. Before/after screenshots over all six screens, expecting byte-identical.

## 9. R4 · `GameScreen` extraction

**Finding.** 1,128 lines, ~55 methods, six concerns: run lifecycle, effect dispatch, HUD, end
panel, tutorial overlay, chooser. `screens` is outside the JaCoCo gate, so none of it is
covered.

**Change.** A **closed** list of six extractions, each characterize-then-move: write the
characterization test against current behaviour, run it, move the method verbatim, confirm the
test still passes.

1. `overlayHit` + `endSlots`
2. `chooserLabel` + `chooserSlotX`
3. `tutorialTarget` + `calloutLines` + `calloutH`
4. `shownDepth`
5. `nextPlate`
6. `orMinusOne`

Anything else discovered along the way is **written down, not done**. The list does not grow.

> **As built — four of the six were empty, and R4 closed at two.** This list was derived from a
> method-name inventory; the bodies were not read until execution. Two held pure logic that had
> not already been extracted:
>
> | # | Outcome |
> |---|---|
> | 1 | **Real.** The band check and slot scan became `ButtonRow.indexAt`, beside the `lay` that produces the slots — not `EndSummary`, which this document guessed at. 5 tests |
> | 5 | **Real.** The right-alignment and below-the-last-line geometry became `CalloutPlacement.nextPlate`, returning a `Plate` record rather than the `int[4]` `GameScreen` was indexing at three call sites. 4 tests |
> | 2 | Empty. `Labels.move(…).toUpperCase()`, and `Labels.move` is already pure with all five cases tested; `chooserSlotX` is an index lookup into a `BoardView.slotX` that `BoardViewSlotsTest` covers |
> | 3 | Empty. Thin adapters over `TextWrap`, `ScreenArt.calloutH` and `CalloutPlacement`, all extracted and tested by earlier passes |
> | 4 | Empty. `dungeon.size() + board.rising() - board.sweeping()` — a one-line sum of three collaborator reads |
> | 6 | Empty. `value == null ? -1 : value` |
>
> Moving the four would add indirection whose tests mostly re-assert what `Labels`, `TextWrap`
> and `CalloutPlacement` already prove — the "no speculative abstraction" guardrail in
> `CLAUDE.md`. The earlier characterize-then-move passes had already taken the real logic out;
> what remains at those points is wiring, which is what a screen is for.
>
> **`GameScreen` therefore stays at ~1,084 lines, and that is the honest floor** for a class that
> owns a board, a chooser, a run-end panel and a tutorial overlay. Recorded because the line
> count on its own invites someone to try again and find the same four dead ends.

**Done.** The two real extractions are out, each with its own test, and the four empty ones are
recorded above rather than forced.

**Verify — this is the item where `core:check` is least sufficient.** A characterization test
proves the extracted method still behaves the same. It says nothing about whether `GameScreen`
still *calls* it correctly: a wrong argument order or coordinate space at the call site leaves
every test green while the feature stops responding. The call site is GL code no test reaches.

Two tiers:

- **Trivial three** (`orMinusOne`, `nextPlate`, `shownDepth`) — leave `GameScreen`'s method as a
  one-line delegate so the diff reads at a glance; `core:check` plus a normal playthrough carry
  it.
- **Interactive three** — each needs a driven **click** pass, not a screenshot, on the surface
  it serves:

| Extraction | Silent failure | Pass required |
|---|---|---|
| `overlayHit` + `endSlots` | run-end buttons stop responding | Rig the panel, click all four: New game, Main menu, Trophies, Records |
| `chooserLabel` + `chooserSlotX` | the two-move popup mis-hits | Equip a weapon, click a monster, click each option |
| `tutorialTarget` + `calloutLines` + `calloutH` | callout points at the wrong card, or clips | Drive the tutorial, check the notch at several steps |

R4 is the cheapest to write and the most expensive to verify. That is the reason it goes last.

---

## 10. Verification strategy

| After | Check |
|---|---|
| every item | `./gradlew core:check` — 585 tests plus the coverage gate on the pure packages |
| R5, R6, R1 | driven screenshot pass over all six screens, plus one equip and one weapon kill |
| R1 specifically | before/after capture expecting **byte-identical** output |
| R2 | an equip captured before the change, to decide which anchor is right |
| R4 | the click passes in §9 |

Captures are taken **windowed**, in a single `drive.ps1` call, and checksummed before being
believed — `SKILL.md` documents dropped keys and stale fullscreen captures as real hazards.

The run-end panel is reached by rigging, never by playing a run to completion: finishing one
appends to the player's real `~/.scoundrel/runs.log`.

## 11. Risks

1. **The screenshot passes are judgement, not assertions.** They catch "that looks wrong", not
   "that is 1px off". Nothing in this plan closes that gap, and R1's byte-identical expectation
   is the only place a diff is mechanical.
2. **R6 touches five screens in one change.** Highest blast radius here.
3. **R4 is six independent extractions.** Each is safe; they accumulate.
4. **`screens` has no coverage gate**, so every safety net in this document is either a pure
   test on extracted logic or a human looking at a picture.

## 12. Decisions taken

| Decision | Chosen | Rejected, and why it is worth knowing |
|---|---|---|
| Scope before the tag | All of R1–R6 | Shipping first and refactoring after was offered; R4's open-endedness was flagged as a release risk and accepted deliberately, mitigated by the closed list in §9 |
| Palette invariant | Two tiers, both tested | Snapping the strays onto one ramp was rejected: it would change pixels that were sampled from the reference render, making the art match it *less* well. Document-only was rejected for leaving no guard against future drift |
| R4 "done" | A named, closed extraction list | A line budget invites extracting whatever is easiest to hit the number; a coverage target needs a pure/GL split of the package that does not exist yet |
| R6 shape | One base, five screens, final `render` | Composition was rejected: it leaves the crash guard as a convention written five times, which is the single thing most worth removing. Including `SpriteLab` was rejected: the base would grow no-ops for a dev tool that is never navigated to |

## 13. Measurements

All taken 2026-08-12/13 on `ui-revamp-and-sprites`.

| Figure | Value | Command |
|---|---|---|
| Tests | 585 pass, 0 fail, 73 classes | `./gradlew core:test`, summed from the JUnit XML |
| Main / test lines | 11,498 / 8,612 | `find … -name "*.java" \| xargs wc -l` |
| `screens` classes / test files | 60 / 42 | `ls … \| wc -l` |
| `GameScreen` | 1,128 lines | `wc -l` |
| Colour constants | 80 `0x` form, 11 `Color.valueOf` form | `grep -rhcE` over `screens` |
| Off-ramp `0x` values | 35 of 56 distinct | `comm -23` against the §6 table |
| Dead assets | 881,084 bytes | `stat -c%s` |
| Purity boundary | clean | `grep -rl 'com.badlogic.gdx'` over the five pure packages — empty |
| Scene2D | gone | `grep -rl scene2d core/src lwjgl3/src` — empty |
| Unreferenced classes | none | per-class reference count across both modules |
