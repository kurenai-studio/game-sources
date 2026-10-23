# Gator Hunt

A small arcade game: alligators crawl in from the right edge of the screen in four lanes, and you shoot them with the mouse (or a tap, on Android) before too many escape off the left edge.

This started as a student project years ago, written in Java Swing/AWT. It was later modernized in two steps:

1. Migrated from a raw Eclipse project to Maven, translated from Serbian to English, and refactored for clarity.
2. Ported from AWT/Swing to [LibGDX](https://libgdx.com/), split into a multi-module Gradle project (`core` / `desktop` / `android`), so the same game logic now runs as a desktop app *and* an Android app, as a step toward publishing on Google Play.

## How to play

- Aim with the mouse (desktop) or your finger (Android) — click or tap directly on an alligator to shoot it.
- There's a short cooldown between shots.
- Score points for every alligator you hit before 20 of them escape off-screen.
- On the game-over screen: tap, or press `Space`/`Enter`, to play again. `Esc` quits (desktop only).

## Project structure

- **`core`** — all the shared game logic and rendering, platform-independent:
  - `GatorHuntGame` — the LibGDX entry point: game loop, input, rendering, state machine (playing → game over).
  - `Alligator` — one alligator's position, speed, points, and sprite.
  - `AlligatorSpawner` — spawn timing and row cycling for one session.
  - `GameStats` — score and counters for the current session.
- **`desktop`** — a thin LWJGL3 launcher that runs `core` in a fullscreen window.
- **`android`** — a thin Android launcher (`AndroidLauncher`) that runs the same `core` inside an Android `Activity`.
- **`assets/sprites`** — shared images, used by both platform modules.
- **`assets/fonts`** — `Bangers-Regular.ttf` ([SIL Open Font License](assets/fonts/OFL.txt), from [Google Fonts](https://fonts.google.com/specimen/Bangers)), used to generate the HUD font at runtime via `gdx-freetype`.

## Running the desktop version

Requires JDK 17+. No local Gradle install needed — the wrapper handles it.

```bash
./gradlew desktop:run
```

On macOS this passes `-XstartOnFirstThread` automatically (required by LWJGL/GLFW); if you ever run the jar directly instead, add that flag yourself.

## Running the Android version

Needs the Android SDK (Android Studio will install it for you on first sync). Verified end to end on a real device (Huawei P30 Pro): builds, installs, launches, renders, and registers touch input correctly.

1. Open the project root in **Android Studio** (it will detect the Gradle multi-module setup automatically).
2. Let it sync — Android Studio will prompt to install/update the SDK, build tools, and possibly offer an "Upgrade Assistant" if `compileSdk 36` / Android Gradle Plugin `9.4.0` are no longer the latest by the time you read this. Accept the suggested versions.
3. Run the `android` configuration on a device or emulator, or from the command line once the SDK is set up:
   ```bash
   ./gradlew android:installDebug
   ```

### Publishing to Google Play (not something I can do for you)

Once it runs correctly on a device:

1. Create a Google Play Developer account (one-time $25 fee).
2. Generate a signing key and build a signed **Android App Bundle**: `./gradlew android:bundleRelease` (Android Studio's Build menu can also do this with a guided wizard).
3. Fill in the Play Console store listing: screenshots, description, content rating questionnaire, privacy policy (simple for an offline game with no data collection, but still required). A 512x512 copy of the launcher icon for the listing itself is at `store/play_store_icon_512.png`.
4. Submit for review.

## Tests

```bash
./gradlew core:test
```

Covers the parts that don't need a display or a GPU: alligator movement, spawn-row cycling, and the score/counter bookkeeping in `GameStats`.

## A note on the AWT → LibGDX port

LibGDX's `SpriteBatch` draws bottom-left-origin, Y-up by default, while the original game (and its input/collision code) was written top-left-origin, Y-down, like most 2D screen/AWT code. Rather than fight that with a flipped camera (which would also flip `BitmapFont` text upside down, since font layout assumes Y-up), every draw call converts coordinates explicitly — see `Alligator.draw()`. Input and collision detection were left as-is in Y-down space, since `Gdx.input.getX()/getY()` already use that convention.

Shooting is handled through LibGDX's `InputProcessor.touchDown()` callback rather than polling `Gdx.input.isTouched()` once per frame. Polling only sees the touch state at the instant each frame happens to check it, so a quick tap can begin and end between two polls and never get registered; `touchDown()` is queued by LibGDX and guaranteed to fire for every touch, regardless of frame timing. This was a real, reproducible problem on a physical device (a Huawei P30 Pro) before the fix — confirmed by sending spaced taps via `adb shell input tap` and comparing against the `SHOTS FIRED` counter.
