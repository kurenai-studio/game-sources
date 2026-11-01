# Code Health R1–R6 Implementation Plan

> ## ✅ Executed 2026-08-14 — do not re-run
>
> All six items shipped. This file is kept as the record of intent; **the spec is the record of
> what happened** ([`../specs/2026-08-13-code-health-r1-r6-design.md`](../specs/2026-08-13-code-health-r1-r6-design.md)).
> Four of its steps did not survive contact with the code:
>
> - **Task 10** put the run-end hit test on `EndSummary`. It went to `ButtonRow.indexAt`, beside
>   the `lay` that produces the slots — this plan named the host before reading the code.
> - **Tasks 11 and 13** are void. `chooserLabel`/`chooserSlotX`, `calloutLines`/`calloutH`,
>   `shownDepth` and `orMinusOne` turned out to be adapters over `Labels`, `TextWrap`,
>   `CalloutPlacement` and `BoardView`, all already extracted and tested. Only `nextPlate` was
>   real, and it went to `CalloutPlacement`.
> - **Task 7's death check** said to trigger the death in `SpriteLab`. That would have proved
>   nothing: `SpriteLab` is the one screen deliberately left unconverted. It was verified by
>   dying for real instead.
> - **Task 9's "byte-identical screenshots"** is unachievable — the backdrop has a live flicker
>   and drifting embers, so no two frames of this game ever match. A same-build noise floor was
>   measured and compared against instead.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clear six pieces of structural debt from the Scoundrel codebase — dead assets, a superseded palette, a five-times-copied screen frame, disagreeing board anchors, an unenforced colour rule, and a 1,128-line screen — before release 2 is tagged.

**Architecture:** Deletions first, then one `PixelScreen` base class absorbing the duplicated screen frame, then single-sourcing the board anchors, then a two-tier palette with a test that enforces it, then a closed list of six pure-helper extractions out of `GameScreen`. One commit per item so any regression bisects to a single change.

**Tech Stack:** Java 21, libGDX (LWJGL3 backend), Gradle multi-module, JUnit 5 under `core/src/test/java`, JaCoCo gate via `./gradlew core:check`.

**Spec:** [`docs/superpowers/specs/2026-08-13-code-health-r1-r6-design.md`](../specs/2026-08-13-code-health-r1-r6-design.md)

## Global Constraints

Every task's requirements implicitly include these. They come from `CLAUDE.md` and `HANDOFF.md` and are not negotiable within this plan.

- **The rules engine stays pure.** No `com.badlogic.gdx.*` in `model`, `rules`, `runs`, `achievements`, `tutorial`. Verify: `grep -rl 'com.badlogic.gdx' core/src/main/java/com/tomer/scoundrel/{model,rules,runs,achievements,tutorial}` must be empty.
- **Never regenerate, recolour or "improve" a sprite.** No task here touches sprite pixels. If one appears to require it, stop and ask.
- **`TextureFilter.Nearest`, integer sprite scales (1, 2, 3, 4), whole-pixel positions.** `Math.round` every computed position before drawing.
- **`PixelViewport(1280, 720)` on every screen.** Do not re-derive layout per window size.
- **Silkscreen only**, at sizes 8, 12, 14, 26, 38. Nothing on a converted screen is set below 12px.
- **No fades, hover glows, panel shadows or rounded corners.** Screen transitions are cuts.
- **Effects hold at 12 fps, idles at 6**, floored through `Frames` — never a local `1f / 12f`.
- **Tests first (red-green) for pure logic.** UI rendering is the documented exception: verified by screenshot, not unit test.
- **`./gradlew core:check` must be green before every commit.** Baseline: 585 tests, 0 failures, 73 test classes (measured 2026-08-12).
- **One commit per task.** Commit messages: lowercase conventional prefix, then a descriptive line — match the existing log (`git log --oneline -5`).

## File Structure

**Created**

| File | Responsibility |
|---|---|
| `core/src/main/java/com/tomer/scoundrel/screens/PixelScreen.java` | The screen frame: batch, viewport, surface, backdrop, press, chrome; a `final render` carrying the two-pass draw and the post-navigation guard |
| `core/src/main/java/com/tomer/scoundrel/screens/UiPalette.java` | Tier 2 of the palette: the 31 colours drawn in code that are not on a ramp, each with provenance |
| `core/src/test/java/com/tomer/scoundrel/screens/UiPaletteTest.java` | Enforces the two-tier invariant by scanning source |
| `core/src/test/java/com/tomer/scoundrel/screens/BoardAnchorsTest.java` | Pins the flight targets to the furniture centres they aim at |
| `core/src/test/java/com/tomer/scoundrel/screens/OverlayHitTest.java` | Characterization for the run-end overlay geometry |
| `core/src/test/java/com/tomer/scoundrel/screens/ChooserLabelTest.java` | Characterization for chooser labels and slot placement |
| `core/src/test/java/com/tomer/scoundrel/screens/TutorialCalloutTest.java` | Characterization for tutorial target, lines and height |
| `core/src/test/java/com/tomer/scoundrel/screens/ShownDepthTest.java` | Characterization for the depth ticker's lag |

**Modified**

| File | Change |
|---|---|
| `assets/fonts/`, `assets/ui/` | Delete 881,084 bytes of unloaded files |
| `screens/Theme.java` | Delete 8 dead colour tokens |
| `screens/TitleScreen.java`, `ModeSelectScreen.java`, `RecordsScreen.java`, `TrophiesScreen.java`, `GameScreen.java` | Extend `PixelScreen`; delete the duplicated frame |
| `screens/CardFlight.java` | Stop declaring anchors; derive from `BoardArt`/`HudArt` |
| `screens/ScreenArt.java`, `BoardArt.java`, `HudArt.java`, `EffectArt.java`, `CardArt.java` | Colour constants reference `UiPalette` |
| `CLAUDE.md`, `HANDOFF.md` | Correct the font line and the §6 palette overclaim |

**Not touched:** `SpriteLab.java` (developer inspector, 3 of the 5 fields, no press gesture — keeps extending `ScreenAdapter` directly).

---

## Task 1: R5 — delete the dead assets

**Files:**
- Delete: `assets/fonts/AlegreyaSans-Bold.ttf`, `assets/fonts/AlegreyaSans-Regular.ttf`, `assets/fonts/IMFellEnglish-Regular.ttf`, `assets/fonts/OFL-AlegreyaSans.txt`, `assets/fonts/OFL-IMFellEnglish.txt`
- Delete: `assets/ui/` (all 7 files)
- Modify: `CLAUDE.md` — the line reading "pending deletion"

**Interfaces:**
- Consumes: nothing
- Produces: nothing (deletion only)

- [ ] **Step 1: Prove nothing loads them**

```bash
grep -rn "fonts/\|\.ttf\|uiskin\|ui/font" core/src lwjgl3/src --include=*.java
```

Expected: exactly two hits, `Theme.java:80` and `Theme.java:82`, both Silkscreen. **If anything else appears, stop** — the file is in use and this task's premise is wrong.

- [ ] **Step 2: Delete**

```bash
cd /c/Users/tomer/scoundrel-game
git rm -q assets/fonts/AlegreyaSans-Bold.ttf assets/fonts/AlegreyaSans-Regular.ttf \
          assets/fonts/IMFellEnglish-Regular.ttf assets/fonts/OFL-AlegreyaSans.txt \
          assets/fonts/OFL-IMFellEnglish.txt
git rm -qr assets/ui
```

- [ ] **Step 3: Confirm what remains**

```bash
ls assets/fonts/
```

Expected exactly: `OFL-Silkscreen.txt`, `Silkscreen-Bold.ttf`, `Silkscreen-Regular.ttf`.

Do **not** hand-edit `assets/assets.txt`. It is regenerated from the directory listing by the `generateAssetList` task, which `processResources` depends on (`build.gradle:110`).

- [ ] **Step 4: Update the CLAUDE.md line**

Replace:

```
  no anti-aliasing. `Theme` loads the two Silkscreen TTFs and nothing else; the three vector
  faces are still in `assets/fonts/` and load nowhere, pending deletion.
```

with:

```
  no anti-aliasing. `Theme` loads the two Silkscreen TTFs and nothing else; the three vector
  faces and the Scene2D skin were deleted with the last of Scene2D.
```

- [ ] **Step 5: Verify by running the game**

```bash
./gradlew core:check
```

Expected: BUILD SUCCESSFUL, 585 tests.

Then launch and screenshot the title screen using the `run-scoundrel` skill. A missing font throws during `Theme` construction, so failure is loud:

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "shot:C:\temp\scoundrel\r5-title.png"
```

Read the PNG. Expected: the title screen, wordmark and four buttons in Silkscreen, The Debt breathing in its portrait well.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: delete the fonts and skin that went with Scene2D

881,084 bytes that nothing has loaded since the pixel conversion: the two
Alegreya faces, IM Fell English, their OFL texts, and the whole default
libGDX skin. The only font loads left in the tree are Theme's two
Silkscreen TTFs."
```

---

## Task 2: R3 — delete Theme's superseded Ashen colours

**Files:**
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/Theme.java:26-39`

**Interfaces:**
- Consumes: nothing
- Produces: `Theme.TORCHLIGHT` and `Theme.BONE` remain the only public colour tokens

- [ ] **Step 1: Re-prove the eight are dead**

```bash
cd /c/Users/tomer/scoundrel-game/core/src/main/java/com/tomer/scoundrel
for c in SOOT STONE DRIED_BLOOD IRON HERBAL CARD_MONSTER CARD_WEAPON CARD_POTION; do
  echo "$c -> $(grep -rl "Theme\.$c\b" --include=*.java . | wc -l) file(s)"
done
```

Expected: every one reports `0 file(s)`. **If any reports 1 or more, stop** and remove only the dead ones.

- [ ] **Step 2: Delete the eight declarations**

In `Theme.java`, delete these lines and any comment block that exists only to describe them:

```java
public static final Color SOOT = Color.valueOf("17130f");
public static final Color STONE = Color.valueOf("241d16");
public static final Color DRIED_BLOOD = Color.valueOf("8c2f22");
public static final Color IRON = Color.valueOf("7a8794");
public static final Color HERBAL = Color.valueOf("5d8a4a");
public static final Color CARD_MONSTER = Color.valueOf("4e2620");
public static final Color CARD_WEAPON = Color.valueOf("3f484e");
public static final Color CARD_POTION = Color.valueOf("374b32");
```

Keep `TORCHLIGHT` (`d9a441`) and `BONE` (`e8ddc7`) — both are referenced, and both are on the accent ramp.

- [ ] **Step 3: Compile — this is the test**

```bash
cd /c/Users/tomer/scoundrel-game && ./gradlew core:compileJava lwjgl3:compileJava
```

Expected: BUILD SUCCESSFUL. A deleted constant that was actually used is a compile error, so this is a complete check.

- [ ] **Step 4: Run the gate**

```bash
./gradlew core:check
```

Expected: BUILD SUCCESSFUL, 585 tests, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/Theme.java
git commit -m "refactor: drop the eight Ashen colours nothing reads

The release-1 palette the 80-colour ramp system replaced. Theme kept
declaring SOOT, STONE, DRIED_BLOOD, IRON, HERBAL and the three card
plates long after the last reference to them went; only TORCHLIGHT and
BONE are still read, and both sit on the accent ramp."
```

---

## Task 3: R6a — create `PixelScreen` and convert `TrophiesScreen`

`TrophiesScreen` goes first because it is the smallest of the five (245 lines) and has the simplest `activate()` — one target, `ESC · BACK`.

**Files:**
- Create: `core/src/main/java/com/tomer/scoundrel/screens/PixelScreen.java`
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/TrophiesScreen.java`

**Interfaces:**
- Consumes: `Theme`, `Backdrop`, `Chrome`, `PixelViewport`, `PixelSurface`, `PressGesture`, `ScoundrelGame`, `CardArt.BACKDROP`
- Produces, and every later R6 task depends on these exact signatures:
  ```java
  protected PixelScreen(ScoundrelGame game, Theme theme)
  protected final Vector2 unproject(int screenX, int screenY)
  protected void advance(float delta)            // default: backdrop.advance(delta)
  protected float backdropLight()                // default: 1f
  protected boolean keyPressed(int keycode)      // default: false
  protected abstract void drawContent(float delta);
  protected abstract int hit(int screenX, int screenY);
  protected abstract void activate(int target);
  ```

- [ ] **Step 1: Write `PixelScreen`**

Create `core/src/main/java/com/tomer/scoundrel/screens/PixelScreen.java`:

```java
package com.tomer.scoundrel.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.ScreenUtils;
import com.tomer.scoundrel.ScoundrelGame;

/**
 * The frame every navigable screen draws inside: the 1280×720 surface, the
 * viewport that scales it to the window, the torchlit backdrop behind it, and
 * the press gesture that turns clicks into targets.
 *
 * <p><b>{@link #render(float)} is final, and that is the point of this class.</b>
 * Activating a target navigates, and navigating disposes this screen along with
 * its batch and surface — drawing afterwards reads freed native memory and takes
 * the JVM down with an {@code EXCEPTION_ACCESS_VIOLATION} rather than throwing
 * something catchable. That guard used to be hand-copied into five screens. Here
 * it is written once, above a {@link #drawContent} a subclass cannot reach until
 * the check has passed.
 *
 * <p>The two passes are equally load-bearing. Everything is drawn at 1:1 onto the
 * surface, and that one image is scaled to the window once — drawn straight to
 * the window instead, every quad rounds separately and identical features
 * disagree by a pixel. See {@code HANDOFF.md} §4.
 *
 * <p>{@code SpriteLab} deliberately does not extend this: it has no press gesture
 * and no backdrop, and it is a developer tool rather than a screen anyone
 * navigates to.
 */
public abstract class PixelScreen extends ScreenAdapter {

    protected final ScoundrelGame game;
    protected final Theme theme;
    protected final PixelViewport viewport;
    protected final SpriteBatch batch = new SpriteBatch();
    protected final PixelSurface surface;
    protected final Backdrop backdrop;
    protected final Chrome chrome;
    protected final PressGesture press = new PressGesture();

    protected PixelScreen(ScoundrelGame game, Theme theme) {
        this.game = game;
        this.theme = theme;
        this.viewport = new PixelViewport(Theme.WORLD_WIDTH, Theme.WORLD_HEIGHT);
        this.surface = new PixelSurface((int) Theme.WORLD_WIDTH, (int) Theme.WORLD_HEIGHT);
        this.backdrop = new Backdrop(theme);
        this.chrome = new Chrome(theme);
    }

    @Override
    public void show() {
        Gdx.input.setInputProcessor(new FrameInput());
    }

    @Override
    public final void render(float delta) {
        int fired = press.advance(delta);
        if (fired != PressGesture.NONE) {
            activate(fired);
            if (game.getScreen() != this) {
                return;
            }
        }
        advance(delta);

        surface.begin(new Color((CardArt.BACKDROP << 8) | 0xff));
        batch.setProjectionMatrix(surface.projection());
        batch.begin();
        backdrop.render(batch, backdropLight());
        drawContent(delta);
        batch.end();
        surface.end();

        ScreenUtils.clear(Color.BLACK);
        viewport.apply();
        batch.setProjectionMatrix(viewport.getCamera().combined);
        batch.begin();
        surface.draw(batch, Theme.WORLD_WIDTH, Theme.WORLD_HEIGHT);
        batch.end();
    }

    @Override
    public final void resize(int width, int height) {
        if (width <= 0 || height <= 0) {
            return;
        }
        viewport.update(width, height, true);
    }

    @Override
    public void dispose() {
        surface.dispose();
        batch.dispose();
    }

    /** A window-space point in the 1280×720 design space. */
    protected final Vector2 unproject(int screenX, int screenY) {
        return viewport.unproject(new Vector2(screenX, screenY));
    }

    /** Moves this screen's clocks on. The backdrop always; more if overridden. */
    protected void advance(float delta) {
        backdrop.advance(delta);
    }

    /** How brightly the torch burns, 0..1. Only the death gutters it. */
    protected float backdropLight() {
        return 1f;
    }

    /** Keys beyond the shared ESC. Return true if handled. */
    protected boolean keyPressed(int keycode) {
        return false;
    }

    protected abstract void drawContent(float delta);

    /** What a window-space point is on, as a target id, or {@link PressGesture#NONE}. */
    protected abstract int hit(int screenX, int screenY);

    /** What a released target does. Only reached once its press has been seen. */
    protected abstract void activate(int target);

    private final class FrameInput extends InputAdapter {
        @Override
        public boolean touchDown(int screenX, int screenY, int pointer, int button) {
            if (button != Input.Buttons.LEFT) {
                return false;
            }
            return press.press(hit(screenX, screenY));
        }

        @Override
        public boolean touchDragged(int screenX, int screenY, int pointer) {
            press.moveOver(hit(screenX, screenY));
            return false;
        }

        @Override
        public boolean touchUp(int screenX, int screenY, int pointer, int button) {
            if (button != Input.Buttons.LEFT) {
                return false;
            }
            return press.release(hit(screenX, screenY));
        }

        @Override
        public boolean keyDown(int keycode) {
            if (keycode == Input.Keys.ESCAPE) {
                game.showTitle();
                return true;
            }
            return keyPressed(keycode);
        }
    }
}
```

- [ ] **Step 2: Compile the new class alone**

```bash
cd /c/Users/tomer/scoundrel-game && ./gradlew core:compileJava
```

Expected: BUILD SUCCESSFUL. If `PressGesture.NONE`, `Chrome`'s constructor or `PixelSurface.projection()` has a different signature than assumed, fix the call here before touching any screen.

- [ ] **Step 3: Convert `TrophiesScreen`**

In `TrophiesScreen.java`:

1. Change the declaration to `public final class TrophiesScreen extends PixelScreen {`.
2. Delete these fields (they now live in the base): `viewport` (:38), `batch` (:39), `surface` (:40), `backdrop` (:41), `press` (:43), and the `chrome` field.
3. In the constructor, delete the four assignments to `viewport`, `surface`, `backdrop`, `chrome`, and call `super(game, theme)` as the first statement. Delete the `game`/`theme` field assignments and declarations if the base now provides them.
4. Delete `show()`, `resize()`, `dispose()` and the entire `TrophiesInput` inner class.
5. Rename `hit(int, int)` to keep its name but add `@Override` and make it `protected`.
6. Rename `activate()` to `activate(int target)`, add `@Override`, make it `protected`. Its body stays `game.showTitle();` — the parameter is ignored because `ScreenArt.BACK` is its only target.
7. Replace `public void render(float delta)` with:

```java
@Override
protected void drawContent(float delta) {
    chrome.header(batch, "TROPHIES", "", press.sunk() == ScreenArt.BACK);
    drawProgress();
    for (int i = 0; i < entries.size(); i++) {
        drawEntry(entries.get(i), i);
    }
}
```

Everything the old `render` did around that — `backdrop.advance`, the guard, `surface.begin`, `batch.begin`, `backdrop.render`, `batch.end`, `surface.end`, the clear, `viewport.apply`, the second pass — is deleted, because the base does it.

8. Replace the body of `hit` with `Vector2 point = unproject(screenX, screenY);` in place of `viewport.unproject(new Vector2(screenX, screenY))`.

- [ ] **Step 4: Compile and run the gate**

```bash
./gradlew core:check
```

Expected: BUILD SUCCESSFUL, 585 tests, 0 failures.

- [ ] **Step 5: Screenshot the converted screen**

There is no unit test for a GL screen — this is the documented exception in `CLAUDE.md`. Drive to Trophies from the title in a single call:

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "shot:C:\temp\scoundrel\r6a-title.png,click:731:517,wait:400,shot:C:\temp\scoundrel\r6a-trophies.png,click:1174:45,wait:400,shot:C:\temp\scoundrel\r6a-back.png"
```

Read all three PNGs. Expected: title → TROPHIES with its progress bar and ten entries in two columns → back at the title. The third shot proves the guard still works: if navigating away drew one more frame, the process would be gone and the shot would fail.

- [ ] **Step 6: Commit**

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/PixelScreen.java \
        core/src/main/java/com/tomer/scoundrel/screens/TrophiesScreen.java
git commit -m "refactor: one screen frame instead of five, starting with TROPHIES

PixelScreen owns the batch, viewport, surface, backdrop and press every
navigable screen was declaring for itself, and its render is final: the
guard that stops a screen drawing after it has navigated - and disposed
its own batch - now sits above a drawContent the subclass cannot reach
before the check. It was hand-copied into five screens, and getting it
wrong takes the JVM down rather than throwing."
```

---

## Task 4: R6b — convert `RecordsScreen`

**Files:**
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/RecordsScreen.java`

**Interfaces:**
- Consumes: `PixelScreen` (Task 3)
- Produces: nothing new

- [ ] **Step 1: Convert**

1. `public final class RecordsScreen extends PixelScreen {`
2. Delete fields `viewport` (:49), `batch` (:50), `surface` (:51), `backdrop` (:52), `press` (:54), and `chrome`.
3. Constructor: `super(game, theme);` first, delete the four assignments.
4. Delete `show()` (:107), `resize()` (:388), `dispose()`, and the input inner class.
5. `hit` → `protected`, `@Override`, body uses `unproject(screenX, screenY)`.
6. `activate` → `protected void activate(int target)`, `@Override`.
7. `render(float)` → `protected void drawContent(float delta)` containing **only** the calls between `backdrop.render(...)` and `batch.end()` in the current body — the header, the table and the totals panel. Delete the surrounding frame.

- [ ] **Step 2: Run the gate**

```bash
./gradlew core:check
```

Expected: BUILD SUCCESSFUL, 585 tests.

- [ ] **Step 3: Screenshot**

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "click:731:461,wait:400,shot:C:\temp\scoundrel\r6b-ledger.png,click:1174:45,wait:400,shot:C:\temp\scoundrel\r6b-back.png"
```

Expected: THE LEDGER with its table and 296px totals panel, then the title.

- [ ] **Step 4: Commit**

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/RecordsScreen.java
git commit -m "refactor: THE LEDGER draws inside the shared frame"
```

---

## Task 5: R6c — convert `ModeSelectScreen`

This one has the digit keys, so it is the first to use `keyPressed`.

**Files:**
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/ModeSelectScreen.java`

**Interfaces:**
- Consumes: `PixelScreen` (Task 3), specifically `keyPressed(int)`
- Produces: nothing new

- [ ] **Step 1: Convert**

1. `public final class ModeSelectScreen extends PixelScreen {`
2. Delete fields `viewport` (:32), `batch` (:33), `surface` (:34), `backdrop` (:35), `press` (:57), `chrome`.
3. Constructor: `super(game, theme);` first; delete the four assignments at :62-65.
4. Delete `show()` (:69), `resize()`, `dispose()`, and `PickerInput` **except** its digit handling, which becomes:

```java
@Override
protected boolean keyPressed(int keycode) {
    // The number in each panel's well is not decoration.
    int index = keycode - Input.Keys.NUM_1;
    if (index >= 0 && index < modes.size()) {
        game.showGame(modes.get(index));
        return true;
    }
    return false;
}
```

The `ESCAPE → game.showTitle()` case is deleted — the base handles it.

5. `hit` → `protected`, `@Override`, using `unproject(screenX, screenY)`.
6. `activate(int target)` → `protected`, `@Override`.
7. `render(float)` → `drawContent(float)`. `followPointer()` moves into `drawContent` as its first statement, before the header, preserving its current position relative to drawing.

- [ ] **Step 2: Run the gate**

```bash
./gradlew core:check
```

Expected: BUILD SUCCESSFUL, 585 tests.

- [ ] **Step 3: Screenshot, including a digit key**

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "click:731:349,wait:400,shot:C:\temp\scoundrel\r6c-modes.png,key:2,wait:1500,shot:C:\temp\scoundrel\r6c-relentless.png"
```

Expected: the three mode panels, then a Relentless board. The digit key proves `keyPressed` is wired; if the second shot is still the picker, the key was dropped — re-send it once before concluding the code is wrong (`SKILL.md` documents swallowed keys).

- [ ] **Step 4: Commit**

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/ModeSelectScreen.java
git commit -m "refactor: NEW GAME draws inside the shared frame

Its digit keys are the first user of PixelScreen.keyPressed; ESC is the
base's now."
```

---

## Task 6: R6d — convert `TitleScreen`

This one has its own clock, so it is the first to override `advance`.

**Files:**
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/TitleScreen.java`

**Interfaces:**
- Consumes: `PixelScreen` (Task 3), specifically `advance(float)`
- Produces: nothing new

- [ ] **Step 1: Convert**

1. `public final class TitleScreen extends PixelScreen {`
2. Delete fields `viewport` (:59), `batch` (:60), `surface` (:61), `backdrop` (:62), `press` (:71), `chrome`.
3. Constructor: `super(game, theme);` first; delete the assignment at :88 and its three neighbours.
4. Delete `show()` (:126), `resize()` (:323), `dispose()`, and the input inner class.
5. Keep the `elapsed` field and override:

```java
@Override
protected void advance(float delta) {
    super.advance(delta);
    elapsed += delta;
}
```

6. `hit` → `protected`, `@Override`, using `unproject(screenX, screenY)`.
7. `activate(int target)` → `protected`, `@Override`.
8. `render(float)` → `drawContent(float)`, keeping only the drawing: the portrait well with The Debt's idle, the wordmark, the rule, the best-score line, the four buttons, the credit line, and the first-run prompt when it is up.

**Note:** `TitleScreen` has no `ESC · BACK` — the base's `ESC → game.showTitle()` is a no-op here because it is already the title. Leave it; a screen navigating to itself is handled by `game.getScreen() != this` being false, so nothing is disposed.

- [ ] **Step 2: Run the gate**

```bash
./gradlew core:check
```

Expected: BUILD SUCCESSFUL, 585 tests.

- [ ] **Step 3: Screenshot, including a held button**

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "shot:C:\temp\scoundrel\r6d-title.png,down:731:349,shot:C:\temp\scoundrel\r6d-held.png,move:250:650,shot:C:\temp\scoundrel\r6d-slid-off.png,up:250:650,wait:400,shot:C:\temp\scoundrel\r6d-cancelled.png"
```

Expected: the title; the New game plate drawn **sunk** (bevel inverted, label 2px down-right); the plate back up after sliding off; still the title, because the press was taken back. This exercises the press gesture through the base's `FrameInput` in all three of its states.

- [ ] **Step 4: Commit**

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/TitleScreen.java
git commit -m "refactor: the title draws inside the shared frame

Its portrait clock is the first user of PixelScreen.advance."
```

---

## Task 7: R6e — convert `GameScreen`

The largest, and the only one keeping its own input and `dispose`.

**Files:**
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java`

**Interfaces:**
- Consumes: `PixelScreen` (Task 3) — `advance`, `backdropLight`, `show`, `dispose`
- Produces: nothing new

- [ ] **Step 1: Convert**

1. `public final class GameScreen extends PixelScreen {`
2. Delete fields `viewport` (:80), `batch` (:81), `surface` (:87), `backdrop` (:89), `press` (:99), `chrome` if present.
3. All three constructors: the private one calls `super(game, theme)` first; delete the assignment at :157 and its neighbours.
4. **Keep** `show()` (:168) overriding the base — `BoardInput` handles cards on press, the chooser, the death-skip and the Avoid plate, none of which the base's `FrameInput` knows about.
5. **Keep** `dispose()`, adding `super.dispose();` as its **last** statement so the base frees surface and batch after this screen frees its own.
6. Override the two hooks:

```java
@Override
protected void advance(float delta) {
    // Not super.advance(delta): this screen's own advance() already moves
    // the backdrop on, along with the board, the bar, the feed and the death.
    advanceClocks(delta);
}

@Override
protected float backdropLight() {
    return deathElapsed >= 0f ? DeathCinematic.torchLight(deathElapsed) : 1f;
}
```

Rename the existing `private void advance(float delta)` (:383) to `advanceClocks` to avoid clashing with the base's hook. Update its one call site.

7. Add the two abstract members the base requires:

```java
@Override
protected int hit(int screenX, int screenY) {
    return overlayHit(screenX, screenY);
}

@Override
protected void activate(int target) {
    activateOverlay(target);
}
```

8. `render(float)` → `protected void drawContent(float delta)`, keeping **only** what is currently between `backdrop.render(...)` and `batch.end()`:

```java
@Override
protected void drawContent(float delta) {
    int shake = deathElapsed >= 0f ? DeathCinematic.shakeX(deathElapsed) : 0;
    batch.getTransformMatrix().translate(shake, 0, 0);
    batch.setTransformMatrix(batch.getTransformMatrix());
    drawHud();
    board.draw(batch);
    drawChooser();
    drawFeed();
    batch.getTransformMatrix().translate(-shake, 0, 0);
    batch.setTransformMatrix(batch.getTransformMatrix());
    if (deathElapsed >= 0f) {
        drawDeath();
    }
    if (endSummary != null) {
        drawEndPanel();
    } else if (calloutUp) {
        drawTutorialOverlay();
    }
}
```

**Ordering is load-bearing:** the backdrop is drawn by the base *before* the shake is applied, because the death shakes the board and not the dark it happens in. That is preserved — the base draws the backdrop, then calls `drawContent`, which applies the shake.

- [ ] **Step 2: Run the gate**

```bash
./gradlew core:check
```

Expected: BUILD SUCCESSFUL, 585 tests.

- [ ] **Step 3: Play a room**

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "click:731:349,wait:400,click:638:159,wait:2000,shot:C:\temp\scoundrel\r6e-board.png,click:340:342,wait:900,shot:C:\temp\scoundrel\r6e-resolved.png,click:1198:46,wait:900,shot:C:\temp\scoundrel\r6e-avoided.png"
```

Expected: a dealt room of four; one card resolved with the room closing up; a room avoided into the depth ticker. Card centres for a 4-card room are 340, 540, 740, 940 — recompute with `x = 640 - (n * 200) / 2 + 88 + (i * 200)` if the room has shrunk.

- [ ] **Step 4: Verify the death path still guards correctly**

The death navigates to the title after its cinematic, which is the exact case the guard exists for. Use the lab rather than dying for real (driving a run to completion writes to the player's real `~/.scoundrel/runs.log`):

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -Actions "key:F9,wait:600,key:F9,wait:600,move:340:342,key:X,wait:3000,shot:C:\temp\scoundrel\r6e-death.png,wait:4000,shot:C:\temp\scoundrel\r6e-after-death.png"
```

Expected: the death cinematic mid-flight, then its end. **If the process is gone by the second shot, the guard is broken** — check `/tmp/scoundrel-run.log` for an `hs_err_pid*.log`.

- [ ] **Step 5: Commit**

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java
git commit -m "refactor: the board draws inside the shared frame

It keeps its own input - cards act on press, and the chooser, the
death-skip and the Avoid plate are all its own - and its own dispose,
now calling super last. The backdrop is still drawn before the shake is
applied, so the death shakes the board and not the dark."
```

---

## Task 8: R2 — single-source the board anchors

**Files:**
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/CardFlight.java:19-22`
- Create: `core/src/test/java/com/tomer/scoundrel/screens/BoardAnchorsTest.java`

**Interfaces:**
- Consumes: `BoardArt.railIconX()`, `BoardArt.railIconY()`, `BoardArt.RAIL_ICON`, `HudArt` ticker constants
- Produces: `CardFlight.railTargetX()`, `CardFlight.railTargetY()` — or, if the capture shows the flight is right, the same constants sourced from `BoardArt`

- [ ] **Step 1: Capture an equip before changing anything**

This decides which number is the truth. Drive to a board, take a weapon, and catch the landing:

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "key:F9,wait:600,key:F9,wait:600,key:S,wait:400,move:340:342,key:E,wait:600,shot:C:\temp\scoundrel\r2-equip-1.png,wait:800,shot:C:\temp\scoundrel\r2-equip-2.png,wait:800,shot:C:\temp\scoundrel\r2-equip-3.png,wait:1200,shot:C:\temp\scoundrel\r2-landed.png"
```

`S` is slow motion (÷8) — sub-second effects cannot be frame-grabbed at speed. Confirm the header reads `[SLOW 1/8]` in the first shot before trusting the timings; it is a toggle and carries state between calls.

- [ ] **Step 2: Read the captures and decide**

Measure where the card's centre lands in `r2-landed.png` against where the rail icon sits.

- **The card lands visibly right of the well** → `CardFlight` is wrong; `BoardArt` is the truth. R2 fixes a live bug.
- **They coincide** → the offset is absorbed by the flight's final 18% scale. `BoardArt` is still the truth; the flight simply stops asserting its own copy.

Record which case it was — it goes in the commit message.

- [ ] **Step 3: Write the failing test**

Create `core/src/test/java/com/tomer/scoundrel/screens/BoardAnchorsTest.java`:

```java
package com.tomer.scoundrel.screens;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

/**
 * The board's anchors exist once. CardFlight used to declare its own copy of
 * where the rail is, and the two drifted 32px apart without anything noticing —
 * a full card-width at the flight's final scale.
 */
class BoardAnchorsTest {

    @Test
    void equipFlightLandsOnTheRailIcon() {
        int iconCentreX = BoardArt.railIconX() + BoardArt.RAIL_ICON / 2;
        int iconCentreY = BoardArt.railIconY() + BoardArt.RAIL_ICON / 2;

        assertEquals(iconCentreX, CardFlight.EQUIP.toX(),
                "the equip flight must land where the rail icon is drawn");
        assertEquals(iconCentreY, CardFlight.EQUIP.toY(),
                "the equip flight must land where the rail icon is drawn");
    }

    @Test
    void avoidSweepLandsOnTheDepthTicker() {
        assertEquals(640, CardFlight.AVOID.toX(),
                "the ticker's lit block is centred on the board");
    }
}
```

- [ ] **Step 4: Run it and watch it fail**

```bash
./gradlew core:test --tests '*BoardAnchorsTest'
```

Expected: FAIL on `equipFlightLandsOnTheRailIcon`, reporting expected `64` but was `96` (and `650` vs `646`).

- [ ] **Step 5: Make it pass**

In `CardFlight.java`, delete:

```java
static final int TICKER_X = 640;
static final int TICKER_Y = 60;
static final int RAIL_X = 96;
static final int RAIL_Y = 646;
```

Replace the two `Flight` constants' targets with values derived from the furniture:

```java
/** The depth ticker's lit block, which HudArt keeps centred on the board. */
private static final int TICKER_X = 640;
private static final int TICKER_Y = 60;

static final Flight AVOID = new Flight(TICKER_X, TICKER_Y, FRAME, 0f,
        new int[] {100, 58, 16});

static final Flight EQUIP = new Flight(
        BoardArt.railIconX() + BoardArt.RAIL_ICON / 2,
        BoardArt.railIconY() + BoardArt.RAIL_ICON / 2,
        FRAME, 0f, new int[] {100, 55, 18});
```

Then fix every reference to the deleted names. `BoardView:461-462` uses `CardFlight.TICKER_X`/`TICKER_Y` — those stay, now private-to-public as needed; expose them as `static final` if `BoardView` requires them, but do **not** re-introduce `RAIL_X`/`RAIL_Y`.

`HudArt.TICKER_Y` (26, the strip's top) keeps its name — the collision is gone because `CardFlight` no longer has a public one.

- [ ] **Step 6: Run the test and the gate**

```bash
./gradlew core:test --tests '*BoardAnchorsTest' && ./gradlew core:check
```

Expected: PASS, then BUILD SUCCESSFUL with 587 tests (585 + 2 new).

- [ ] **Step 7: Capture the equip again and compare**

Re-run the Step 1 command with output paths `r2-after-*.png`. Compare `r2-landed.png` with `r2-after-landed.png`.

- If Step 2 found a bug: the card should now land **on** the well.
- If Step 2 found them coincident: the two captures should be indistinguishable.

- [ ] **Step 8: Commit**

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/CardFlight.java \
        core/src/test/java/com/tomer/scoundrel/screens/BoardAnchorsTest.java
git commit -m "fix: the equip lands on the rail it becomes

CardFlight declared its own RAIL_X/RAIL_Y of (96, 646) while the icon it
turns into is centred at (64, 650) by BoardArt - 32px apart, a full card
width at the flight's final 18% scale. The flight now derives its target
from the furniture, and a test holds them together. HudArt.TICKER_Y and
CardFlight.TICKER_Y were also the same name for different things."
```

Adjust the subject to `refactor:` and the wording if Step 2 showed the offset was invisible.

---

## Task 9: R1 — the two-tier palette

**Files:**
- Create: `core/src/main/java/com/tomer/scoundrel/screens/UiPalette.java`
- Create: `core/src/test/java/com/tomer/scoundrel/screens/UiPaletteTest.java`
- Modify: `HANDOFF.md` §6, `CLAUDE.md`

**Interfaces:**
- Consumes: `Ramps.contains(int rgb)`
- Produces: `UiPalette.contains(int rgb)`, `UiPalette.size()`

- [ ] **Step 1: Write the failing test**

Create `core/src/test/java/com/tomer/scoundrel/screens/UiPaletteTest.java`:

```java
package com.tomer.scoundrel.screens;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

/**
 * The palette rule, enforced. {@code HANDOFF.md} §6 claims the 80 ramp colours
 * are the only ones the UI may use; that was never true outside the sprites —
 * the chrome, the potion bottle and the cleaved card's faces were all sampled
 * from the reference render and sit off-ramp. This pins the honest version:
 * every colour is on a ramp, or is a named exception with its provenance
 * recorded in {@link UiPalette}.
 *
 * <p>It reads source rather than reflecting over fields, so a colour added in
 * any form is caught. Declarations only: {@code argb[i] & 0xffffff} in the mask
 * generators is a bit mask, not a colour.
 */
class UiPaletteTest {

    private static final Path SOURCES =
            Path.of("src", "main", "java", "com", "tomer", "scoundrel", "screens");

    private static final Pattern INT_FORM =
            Pattern.compile("static final int ([A-Z_][A-Z0-9_]*) = 0x([0-9a-fA-F]{6,8})");

    private static final Pattern COLOR_FORM =
            Pattern.compile("Color\\.valueOf\\(\"([0-9a-fA-F]{6})\"\\)");

    private record Declared(String file, int line, String name, int rgb) {
        @Override
        public String toString() {
            return String.format("%s:%d %s = %06x", file, line, name, rgb);
        }
    }

    @Test
    void everyDeclaredColourIsOnARampOrIsANamedException() throws IOException {
        List<Declared> strays = new ArrayList<>();
        for (Declared declared : scan()) {
            if (!Ramps.contains(declared.rgb()) && !UiPalette.contains(declared.rgb())) {
                strays.add(declared);
            }
        }
        assertTrue(strays.isEmpty(),
                "colours on neither the ramps nor UiPalette:\n  "
                        + String.join("\n  ", strays.stream().map(Object::toString).toList()));
    }

    @Test
    void theTwoTiersAreDisjoint() {
        List<String> both = new ArrayList<>();
        for (int rgb : UiPalette.all()) {
            if (Ramps.contains(rgb)) {
                both.add(String.format("%06x", rgb));
            }
        }
        assertTrue(both.isEmpty(),
                "these are on a ramp and must not also be UiPalette entries: " + both);
    }

    private List<Declared> scan() throws IOException {
        List<Declared> found = new ArrayList<>();
        try (Stream<Path> files = Files.list(SOURCES)) {
            for (Path file : files.filter(p -> p.toString().endsWith(".java")).toList()) {
                List<String> lines = Files.readAllLines(file);
                for (int i = 0; i < lines.size(); i++) {
                    collect(found, file.getFileName().toString(), i + 1, lines.get(i));
                }
            }
        }
        return found;
    }

    private void collect(List<Declared> found, String file, int line, String text) {
        Matcher ints = INT_FORM.matcher(text);
        while (ints.find()) {
            String hex = ints.group(2);
            // The 8-digit form is ARGB; the colour is its low three bytes.
            int rgb = (int) (Long.parseLong(hex, 16) & 0xffffffL);
            found.add(new Declared(file, line, ints.group(1), rgb));
        }
        Matcher colors = COLOR_FORM.matcher(text);
        while (colors.find()) {
            found.add(new Declared(file, line, "Color.valueOf",
                    Integer.parseInt(colors.group(1), 16)));
        }
    }
}
```

- [ ] **Step 2: Run it and watch it fail**

```bash
./gradlew core:test --tests '*UiPaletteTest'
```

Expected: FAIL to compile — `UiPalette` does not exist. That is the red state.

- [ ] **Step 3: Write `UiPalette` with all 31 entries**

Create `core/src/main/java/com/tomer/scoundrel/screens/UiPalette.java`. Every value below was measured from the current source on 2026-08-13; the comment on each records where it comes from.

```java
package com.tomer.scoundrel.screens;

import java.util.Set;

/**
 * Tier two of the palette: every colour drawn in code that is <b>not</b> on one
 * of the eighty ramp entries in {@link Ramps}.
 *
 * <p>{@code HANDOFF.md} §6 says the eighty "are also the only colours the UI
 * should use". That was never true and could not be: §11 of the same document
 * specifies nine chrome hexes that are not among them, and the potion bottle and
 * the cleaved card's cut faces were sampled straight from the reference render.
 * None of these were invented — each is either quoted in the brief or taken off
 * the art. This class is the honest version of the rule, and
 * {@code UiPaletteTest} is what keeps it honest.
 *
 * <p><b>What this cannot govern:</b> blended output. {@code fill(…, 0x000000,
 * 0.5f)} puts a colour on screen that is on no ramp by construction. Bringing
 * those shadows onto flat palette steps would change pixels and is deliberately
 * out of scope.
 */
final class UiPalette {

    private static final Set<Integer> COLOURS = Set.of(
            // --- structure, HANDOFF §11 -------------------------------------
            0x0f1410,   // FRAME — the 2px recess around every widget
            0x161210,   // FACE_PANEL
            0x141110,   // FACE_TABLE, and the even ledger row
            0x12161a,   // FACE_WELL, the rail well, the gold plate's label
            0x1a1410,   // DARK plate
            0x2f2620,   // DARK_LIGHT bevel
            0x0a0806,   // DARK_DARK bevel, the value and wordmark shadows
            0x4a3524,   // rules, the ready marker, locked trophy text
            0x191513,   // odd ledger row, earned trophy row
            0x131110,   // locked trophy row
            0x1e1a17,   // an unearned seal's empty well
            0x241d16,   // the "no trophies" badge
            0x9a8b70,   // header caption, the feed, the depth line, the cork
            0x6b5f4c,   // captions, the badge label, the HP suffix, FILL_LOW
            0x746d63,   // a quiet ledger cell
            0x494336,   // an unselected mode's well digit
            0x3a2e26,   // an unlit step dot
            0x74838f,   // starting health, the rail's weapon name
            0x0e050c,   // the title portrait's field
            0x100c09,   // the stage behind everything

            // --- the HUD ----------------------------------------------------
            0x1e2a1c,   // the health bar's empty track
            0x3b4334,   // that track's lip
            0x2d3029,   // the segment lines over the fill
            0x20180e,   // a spent depth tick

            // --- the slain stack --------------------------------------------
            0x4e2620,   // a chip's face
            0xa35543,   // a chip's label

            // --- drawn objects, sampled from the reference render ------------
            0x3a1d18,   // the cleaved card's upper cut face
            0x2c1512,   // its lower cut face
            0x5d8a4a,   // the potion bottle's glass
            0x507641,   // that glass in shade
            0x35291f,   // the bottle's edge

            // --- and black ---------------------------------------------------
            // Drawn at alpha as a shadow line under the rail well and the card
            // well, and as RimMask's fully transparent clear.
            0x000000);

    private UiPalette() {
    }

    static boolean contains(int rgb) {
        return COLOURS.contains(rgb);
    }

    static Set<Integer> all() {
        return COLOURS;
    }

    static int size() {
        return COLOURS.size();
    }
}
```

- [ ] **Step 4: Run the test and watch it pass**

```bash
./gradlew core:test --tests '*UiPaletteTest'
```

Expected: PASS, both tests.

If `everyDeclaredColourIsOnARampOrIsANamedException` fails, its message lists the exact `file:line name = rrggbb` of anything missed — add it to `UiPalette` with a comment saying what it draws. If `theTwoTiersAreDisjoint` fails, a value above is already on a ramp and must be deleted from `UiPalette` rather than duplicated.

- [ ] **Step 5: Correct the two documents that overclaim**

In `HANDOFF.md` §6, after "**80 colours. Nothing outside this list appears in any sprite**, so these are also the only colours the UI should use.", add:

```markdown
> **As built — the second half of that sentence was never true.** §11 of this
> document specifies nine chrome hexes that are not on any ramp, and the potion
> bottle, the cleaved card's cut faces and the HUD tints were sampled from the
> reference render rather than the ramps. The sprites are the part this rule
> really governs, and even there §8 records six that are partly off it. What
> ships is two tiers: `Ramps` holds the eighty and governs sprite pixel
> operations; `UiPalette` holds the 31 colours drawn in code that are not on
> them, each with its provenance. `UiPaletteTest` fails if a colour appears in
> neither.
```

In `CLAUDE.md`, replace:

```
- **Never regenerate, recolour, or "improve" a sprite.** Every pixel sits on a locked 80-colour
  ramp system that took ~30 generations to settle.
```

with:

```
- **Never regenerate, recolour, or "improve" a sprite.** Sprite pixels sit on the locked
  80-colour ramp system (`Ramps`) that took ~30 generations to settle. Colours drawn in code —
  chrome, the bottle, the cleave faces — are the second tier (`UiPalette`), sampled from the
  reference render; `UiPaletteTest` fails if a colour is on neither.
```

- [ ] **Step 6: Prove zero pixels changed**

Nothing was recoloured — the tables describe what is already on screen. Capture all six screens and compare against the Task 7 captures:

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "shot:C:\temp\scoundrel\r1-title.png,click:731:461,wait:400,shot:C:\temp\scoundrel\r1-ledger.png,click:1174:45,wait:400,click:731:517,wait:400,shot:C:\temp\scoundrel\r1-trophies.png"
```

```bash
md5sum /c/temp/scoundrel/r6b-ledger.png /c/temp/scoundrel/r1-ledger.png
```

Expected: **identical checksums** for the screens captured both times. A difference means a colour constant was altered, not just catalogued — revert and find it.

- [ ] **Step 7: Run the gate and commit**

```bash
./gradlew core:check
```

Expected: BUILD SUCCESSFUL, 589 tests (587 + 2 new).

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/UiPalette.java \
        core/src/test/java/com/tomer/scoundrel/screens/UiPaletteTest.java \
        HANDOFF.md CLAUDE.md
git commit -m "test: the palette rule, in the version that is actually true

The eighty ramp colours were never all the UI used - §11 of the brief
specifies chrome that is not on them, and the bottle and the cleaved
card's faces came off the reference render. So: two tiers. Ramps governs
sprite pixels; UiPalette holds the 31 drawn-in-code colours that are not
on a ramp, each with its provenance. A test reads both declaration forms
out of the source and fails on anything in neither.

No pixel changes - the tables describe what was already on screen."
```

---

## Task 10: R4a — extract `overlayHit` and `endSlots`

**Files:**
- Create: `core/src/test/java/com/tomer/scoundrel/screens/OverlayHitTest.java`
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java:256-306`
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/EndSummary.java` (host for the moved geometry)

**Interfaces:**
- Consumes: `ButtonRow.Slot`, `ScreenArt`
- Produces: `EndSummary.slots(List<String> labels)` returning `List<ButtonRow.Slot>`, and `EndSummary.hit(List<ButtonRow.Slot> slots, float x, float y)` returning the slot index or `PressGesture.NONE`

- [ ] **Step 1: Read the three methods before moving anything**

```bash
sed -n '256,306p' core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java
```

Note the exact signatures of `endButtons()`, `endSlots()`, `overlayHit(int, int)` and the `contains(Vector2, int, int, int, int)` helper. The characterization test must be written against **current behaviour**, so copy real values out of this source rather than inventing them.

- [ ] **Step 2: Write the characterization test**

Create `core/src/test/java/com/tomer/scoundrel/screens/OverlayHitTest.java`. Fill the expected values from what Step 1 showed:

```java
package com.tomer.scoundrel.screens;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * The run-end panel's four buttons: where they sit, and what a click on one
 * returns. Characterized before the geometry moved off GameScreen, so the move
 * could be proved to change nothing.
 */
class OverlayHitTest {

    private static final List<String> BUTTONS =
            List.of("New game", "Main menu", "Trophies", "Records");

    @Test
    void fourButtonsAreEvenlySpacedInOneColumn() {
        List<ButtonRow.Slot> slots = EndSummary.slots(BUTTONS);

        assertEquals(4, slots.size());
        int pitch = slots.get(1).y() - slots.get(0).y();
        assertEquals(pitch, slots.get(2).y() - slots.get(1).y(),
                "the run-end column is evenly pitched");
        assertEquals(pitch, slots.get(3).y() - slots.get(2).y(),
                "the run-end column is evenly pitched");
    }

    @Test
    void aPointInsideASlotReturnsThatSlot() {
        List<ButtonRow.Slot> slots = EndSummary.slots(BUTTONS);
        ButtonRow.Slot third = slots.get(2);

        assertEquals(2, EndSummary.hit(slots,
                third.x() + third.w() / 2f, third.y() + third.h() / 2f));
    }

    @Test
    void aPointBetweenSlotsHitsNothing() {
        List<ButtonRow.Slot> slots = EndSummary.slots(BUTTONS);
        ButtonRow.Slot first = slots.get(0);
        ButtonRow.Slot second = slots.get(1);
        float gapY = (first.y() + first.h() + second.y()) / 2f;

        assertEquals(PressGesture.NONE,
                EndSummary.hit(slots, first.x() + first.w() / 2f, gapY));
    }
}
```

- [ ] **Step 3: Run it and watch it fail**

```bash
./gradlew core:test --tests '*OverlayHitTest'
```

Expected: FAIL to compile — `EndSummary.slots` and `EndSummary.hit` do not exist yet.

- [ ] **Step 4: Move the methods verbatim**

Cut the bodies of `endSlots()` and the geometry half of `overlayHit()` out of `GameScreen` and paste them into `EndSummary` as `static` methods, changing **nothing but the signature**. Leave `GameScreen.overlayHit` as a delegate that supplies the unprojected point:

```java
private int overlayHit(int screenX, int screenY) {
    Vector2 point = unproject(screenX, screenY);
    if (endSummary != null) {
        return EndSummary.hit(EndSummary.slots(endButtons()), point.x, point.y);
    }
    // ... the tutorial's Skip/Next cases, unchanged
}
```

- [ ] **Step 5: Run the test and the gate**

```bash
./gradlew core:test --tests '*OverlayHitTest' && ./gradlew core:check
```

Expected: PASS, then BUILD SUCCESSFUL with 592 tests.

- [ ] **Step 6: Click all four buttons — the test cannot see a miswired call site**

A characterization test proves the geometry still computes the same numbers. It says nothing about whether `GameScreen` still passes the right point into it. Reach the panel by rigging rather than by finishing a run — finishing one appends to the player's real `~/.scoundrel/runs.log`:

1. Temporarily edit the tutorial's end so it builds `EndSummary.of(Status.WON, 17, 214L, false, 0, 3)`.
2. Drive the tutorial to its end and screenshot the panel.
3. Click each of the four buttons in turn, screenshotting where each lands: New game → a board; Main menu → the title; Trophies → TROPHIES; Records → THE LEDGER.
4. `git checkout -- core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java` to drop the rigging.

Button coordinates, from `SKILL.md`: `639,423` / `639,464` / `639,505` / `639,546`.

- [ ] **Step 7: Commit**

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java \
        core/src/main/java/com/tomer/scoundrel/screens/EndSummary.java \
        core/src/test/java/com/tomer/scoundrel/screens/OverlayHitTest.java
git commit -m "refactor: the run-end panel's button geometry leaves GameScreen

Characterized first, then moved verbatim. All four buttons driven to
confirm the call site still passes the right point - which is the half a
characterization test cannot see."
```

---

## Task 11: R4b — extract `chooserLabel` and `chooserSlotX`

**Files:**
- Create: `core/src/test/java/com/tomer/scoundrel/screens/ChooserLabelTest.java`
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java:921-931`
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/ChooserArt.java`

**Interfaces:**
- Consumes: `Move`, `ChooserArt`
- Produces: `ChooserArt.label(Move move)` returning `String`, `ChooserArt.slotX(int cardCentreX, int plateW)` returning `int`

- [ ] **Step 1: Read the current methods**

```bash
sed -n '921,931p' core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java
```

- [ ] **Step 2: Write the characterization test**

```java
package com.tomer.scoundrel.screens;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.rules.Move;
import org.junit.jupiter.api.Test;

/**
 * What the two-move chooser says and where it sits. A monster while armed is
 * the only card that offers a choice, and its two plates are the only strings
 * this popup ever shows.
 */
class ChooserLabelTest {

    @Test
    void barehandedAndArmedAreTheTwoLabels() {
        Card jack = Card.of("clubs", 11);

        assertEquals("Barehanded", ChooserArt.label(new Move.FightBarehanded(jack)));
        assertEquals("Use weapon", ChooserArt.label(new Move.FightWithWeapon(jack)));
    }

    @Test
    void theChooserIsCentredOnItsCard() {
        assertEquals(640 - 120 / 2, ChooserArt.slotX(640, 120));
    }

    @Test
    void aChooserOnAnEdgeCardStaysOnTheBoard() {
        assertEquals(0, Math.max(0, ChooserArt.slotX(40, 120)),
                "a chooser never starts left of the board");
    }
}
```

**Before running:** confirm the exact label strings and the `Move` subtype names in Step 1's output and correct the test to match. The test characterizes what is there — it does not propose new wording.

- [ ] **Step 3: Run it and watch it fail**

```bash
./gradlew core:test --tests '*ChooserLabelTest'
```

Expected: FAIL to compile — the two methods do not exist on `ChooserArt`.

- [ ] **Step 4: Move both verbatim into `ChooserArt`**

`chooserLabel(Move)` becomes `ChooserArt.label(Move)`. `chooserSlotX()` becomes `ChooserArt.slotX(int cardCentreX, int plateW)` — it currently reads `chooserCard` and `chooserPlateW` off the screen, so those become parameters. `GameScreen` keeps a one-line delegate that supplies them.

- [ ] **Step 5: Run the test and the gate**

```bash
./gradlew core:test --tests '*ChooserLabelTest' && ./gradlew core:check
```

Expected: PASS, then BUILD SUCCESSFUL with 595 tests.

- [ ] **Step 6: Drive the chooser**

The popup needs an armed player and a monster. In the lab, `E` equips and the board can then be clicked:

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "click:731:349,wait:400,click:638:159,wait:2000,shot:C:\temp\scoundrel\r4b-room.png"
```

Read the shot, find a weapon (a diamond) and a monster, click the weapon, then click the monster and screenshot the chooser. Click each of its two plates in separate runs and confirm each resolves the way its label says.

- [ ] **Step 7: Commit**

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java \
        core/src/main/java/com/tomer/scoundrel/screens/ChooserArt.java \
        core/src/test/java/com/tomer/scoundrel/screens/ChooserLabelTest.java
git commit -m "refactor: the chooser's labels and placement move to ChooserArt"
```

---

## Task 12: R4c — extract the tutorial callout decisions

**Files:**
- Create: `core/src/test/java/com/tomer/scoundrel/screens/TutorialCalloutTest.java`
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java:722-748`
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/CalloutPlacement.java`

**Interfaces:**
- Consumes: `TutorialStep`, `TextWrap`, `CalloutPlacement`
- Produces: `CalloutPlacement.targetOf(TutorialStep step)` returning `int[]`, `CalloutPlacement.lines(TutorialStep step, ToIntFunction<String> measure)` returning `List<String>`, `CalloutPlacement.height(int lineCount)` returning `int`

- [ ] **Step 1: Read all three methods**

```bash
sed -n '722,762p' core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java
```

- [ ] **Step 2: Write the characterization test**

Follow the `TextWrap`/`ButtonRow` pattern already in this codebase: the font measuring is **passed in as a function** so the arithmetic stays headless.

```java
package com.tomer.scoundrel.screens;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.tomer.scoundrel.tutorial.TutorialStep;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Where the tutorial's callout points and how tall it has to be. The callout
 * grows to fit its narration — the real script runs to about 180 characters
 * against the reference render's 90 — so the height is computed, not fixed.
 */
class TutorialCalloutTest {

    /** Six pixels a character: enough to exercise the wrap deterministically. */
    private static final java.util.function.ToIntFunction<String> MEASURE =
            s -> s.length() * 6;

    @Test
    void narrationWrapsToTheCalloutWidth() {
        TutorialStep step = TutorialStep.values()[1];
        List<String> lines = CalloutPlacement.lines(step, MEASURE);

        assertTrue(lines.size() >= 1, "a step always has narration");
        for (String line : lines) {
            assertTrue(MEASURE.applyAsInt(line) <= CalloutPlacement.WIDTH,
                    "no line is wider than the callout: " + line);
        }
    }

    @Test
    void heightGrowsWithLineCount() {
        assertTrue(CalloutPlacement.height(5) > CalloutPlacement.height(3),
                "the callout grows to fit its narration");
    }

    @Test
    void aStepThatTeachesACardPointsAtIt() {
        TutorialStep step = TutorialStep.values()[1];
        int[] target = CalloutPlacement.targetOf(step);

        assertEquals(2, target.length, "a target is an x/y pair");
    }
}
```

**Before running:** open `TutorialStep` and correct the enum access and the `CalloutPlacement.WIDTH` constant name to whatever is actually there.

- [ ] **Step 3: Run it and watch it fail**

```bash
./gradlew core:test --tests '*TutorialCalloutTest'
```

Expected: FAIL to compile.

- [ ] **Step 4: Move the three methods verbatim**

`tutorialTarget` → `CalloutPlacement.targetOf`, `calloutLines` → `CalloutPlacement.lines` with the measuring function as a parameter, `calloutH` → `CalloutPlacement.height`. `GameScreen` keeps one-line delegates passing `theme`'s font measure in.

- [ ] **Step 5: Run the test and the gate**

```bash
./gradlew core:test --tests '*TutorialCalloutTest' && ./gradlew core:check
```

Expected: PASS, then BUILD SUCCESSFUL with 598 tests.

- [ ] **Step 6: Drive the tutorial and watch the notch**

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "click:640:349,wait:2500,shot:C:\temp\scoundrel\r4c-step1.png"
```

Then advance step by step, screenshotting each. At every step check: the callout's notch points at the card the narration is talking about; no text is clipped; the panel does not push into the HUD. The explanation beat sits **under** the room, not over it.

- [ ] **Step 7: Commit**

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java \
        core/src/main/java/com/tomer/scoundrel/screens/CalloutPlacement.java \
        core/src/test/java/com/tomer/scoundrel/screens/TutorialCalloutTest.java
git commit -m "refactor: the tutorial callout's target, wrap and height move out

Measuring is passed in as a function, the way TextWrap and ButtonRow do
it, so the arithmetic stays headless."
```

---

## Task 13: R4d — extract `shownDepth`, `nextPlate` and `orMinusOne`

The three trivial ones, done together because each is a handful of lines and none owns an interactive surface.

**Files:**
- Create: `core/src/test/java/com/tomer/scoundrel/screens/ShownDepthTest.java`
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java:436-444,762-778,1067-1074`
- Modify: `core/src/main/java/com/tomer/scoundrel/screens/HudArt.java`

**Interfaces:**
- Consumes: `HudArt`
- Produces: `HudArt.shownDepth(int engineDepth, boolean rising, int cardsInFlight)` returning `int`

- [ ] **Step 1: Read all three**

```bash
sed -n '436,444p;762,778p;1067,1074p' core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java
```

- [ ] **Step 2: Write the characterization test**

```java
package com.tomer.scoundrel.screens;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

/**
 * The depth ticker deliberately lags the engine. The engine settles a whole
 * move on the press, so a tick would go out before its card had left the
 * dungeon — the gauge has to wait for what the player can see.
 */
class ShownDepthTest {

    @Test
    void aSettledBoardShowsTheEngineDepth() {
        assertEquals(30, HudArt.shownDepth(30, false, 0));
    }

    @Test
    void cardsStillRisingKeepTheirTicksLit() {
        assertEquals(32, HudArt.shownDepth(30, true, 2),
                "a card in the air is still between the ticks and the table");
    }
}
```

**Before running:** correct the parameters to match what Step 1 showed `shownDepth()` actually reads.

- [ ] **Step 3: Run it and watch it fail**

```bash
./gradlew core:test --tests '*ShownDepthTest'
```

Expected: FAIL to compile.

- [ ] **Step 4: Move all three**

- `shownDepth()` → `HudArt.shownDepth(...)`, with the fields it reads becoming parameters.
- `nextPlate()` → keep in `GameScreen` but change its return from `int[]` to a small `record Plate(int x, int y)` declared in `ScreenArt`. Primitive obsession is the smell; a two-field record is the fix.
- `orMinusOne(Integer)` → `LedgerRow.orMinusOne(Integer)`, beside the other null-tolerant ledger helpers.

Each `GameScreen` method becomes a one-line delegate so the diff reads at a glance.

- [ ] **Step 5: Run the test and the gate**

```bash
./gradlew core:test --tests '*ShownDepthTest' && ./gradlew core:check
```

Expected: PASS, then BUILD SUCCESSFUL with 600 tests.

- [ ] **Step 6: Verify the ticker on a real board**

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "click:731:349,wait:400,click:638:159,wait:2000,shot:C:\temp\scoundrel\r4d-dealt.png,click:1198:46,wait:1200,shot:C:\temp\scoundrel\r4d-avoided.png"
```

Expected: the lit block of the depth strip stays centred on x=640, and the count does not jump before the cards have moved.

- [ ] **Step 7: Commit**

```bash
git add core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java \
        core/src/main/java/com/tomer/scoundrel/screens/HudArt.java \
        core/src/main/java/com/tomer/scoundrel/screens/ScreenArt.java \
        core/src/main/java/com/tomer/scoundrel/screens/LedgerRow.java \
        core/src/test/java/com/tomer/scoundrel/screens/ShownDepthTest.java
git commit -m "refactor: the last three helpers leave GameScreen

shownDepth to HudArt, orMinusOne to LedgerRow, and nextPlate's int[] pair
becomes a record. The extraction list from the spec is closed."
```

---

## Task 14: Final verification

**Files:** none modified — this task only measures and records.

- [ ] **Step 1: Measure what changed**

```bash
cd /c/Users/tomer/scoundrel-game
echo "GameScreen: $(wc -l < core/src/main/java/com/tomer/scoundrel/screens/GameScreen.java) lines (was 1128)"
echo "main total: $(find core/src/main -name '*.java' | xargs wc -l | tail -1)  (was 11498)"
git diff --stat main..HEAD -- core/src/main/java/com/tomer/scoundrel/screens/
```

Record the real numbers. The spec's `≈ −170 lines` for R6 was an estimate and is now replaceable with a measurement.

- [ ] **Step 2: Run the full gate one last time**

```bash
./gradlew core:check
```

Expected: BUILD SUCCESSFUL. Count the tests from the XML rather than trusting the console:

```bash
grep -ho 'tests="[0-9]*"' core/build/test-results/test/TEST-*.xml \
  | grep -o '[0-9]*' | awk '{t+=$1} END {print "tests: "t}'
```

Expected: 600, up from 585.

- [ ] **Step 3: Re-prove the two structural invariants**

```bash
grep -rl 'com.badlogic.gdx' core/src/main/java/com/tomer/scoundrel/{model,rules,runs,achievements,tutorial}
grep -rl 'scene2d' core/src lwjgl3/src
```

Expected: both empty.

- [ ] **Step 4: A full playthrough**

Play one Standard run start to finish and one tutorial, screenshotting each screen at least once. This is the only step that exercises the five converted screens, the chooser, the tutorial callout and the run-end panel together.

**Back up the run log first** — a completed run appends to the player's real history:

```bash
cp ~/.scoundrel/runs.log ~/.scoundrel/runs.log.backup
cp ~/.scoundrel/achievements.log ~/.scoundrel/achievements.log.backup
```

- [ ] **Step 5: Update the CHANGELOG**

Add to `[Unreleased]` under `### Changed`:

```markdown
- One screen frame instead of five. `PixelScreen` owns the batch, viewport, surface, backdrop
  and press gesture that every navigable screen was declaring for itself, and its `render` is
  final — the guard that stops a screen drawing after it has navigated, and disposed its own
  batch, is now written once above a `drawContent` a subclass cannot reach before the check.
- The equip flight lands on the rail icon it becomes. It had been aiming 32px to its right,
  a full card-width at the flight's final scale, because `CardFlight` kept its own copy of
  where the rail is.
- The palette rule is enforced, in the version that is true: `Ramps` governs sprite pixels,
  `UiPalette` holds the 31 colours drawn in code that were sampled from the reference render
  rather than the ramps, and a test fails on anything in neither.
```

- [ ] **Step 6: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: record the code health pass in the changelog"
```

---

## Self-Review

**Spec coverage.** R5 → Task 1. R3 → Task 2. R6 → Tasks 3–7 (one per screen, base created in 3). R2 → Task 8. R1 → Task 9. R4's six extractions → Tasks 10–13 (`overlayHit`+`endSlots`, `chooserLabel`+`chooserSlotX`, the three tutorial methods, and the trivial three together). Spec §10's verification table → the screenshot step inside each task plus Task 14. Spec §11's risks → the click passes in Tasks 10–12 and the playthrough in Task 14. No spec section is unimplemented.

**Placeholders.** None. Every step names exact files, exact line ranges, runnable commands and expected output. Three tasks (11, 12, 13) tell the implementer to *confirm signatures against the current source before running the test* — that is a deliberate instruction, not a gap: those methods are private and their exact parameter lists could not be read without opening files this plan does not require the reader to have open.

**Type consistency.** `PixelScreen`'s eight protected members are declared once in Task 3's Interfaces block and used with identical names in Tasks 4–7. `EndSummary.slots`/`hit`, `ChooserArt.label`/`slotX`, `CalloutPlacement.targetOf`/`lines`/`height` and `HudArt.shownDepth` each appear in their producing task's Interfaces block before being used.

**Known soft spot.** Test counts in the "Expected" lines (592, 595, 598, 600) assume each new test class adds exactly the number of `@Test` methods written here. If a characterization test needs an extra case after reading the real source, those numbers shift — treat them as a guide, and trust `0 failures` over the total.
