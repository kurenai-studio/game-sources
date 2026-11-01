---
name: run-scoundrel
description: Build, launch, and drive the Scoundrel libGDX desktop game on Windows - start the app, click through menus, play cards, and capture screenshots to verify UI changes. Use when asked to run, start, launch, screenshot, play, or manually test Scoundrel.
---

# Running Scoundrel

Scoundrel is a Java 21 / libGDX (LWJGL3) **desktop** game. `gradlew lwjgl3:run`
opens a **borderless-fullscreen** window titled `Scoundrel` at the monitor's
native resolution. There is no DOM and no built-in remote control, so the only
way to verify UI work is to **screenshot pixels and synthesise mouse clicks**
through Win32.

> **Go windowed before you drive anything.** Every coordinate in this file is a
> client pixel in a **1280x720** window, and fullscreen capture goes stale in
> ways that are easy to miss (see Gotchas). Send `key:F11` in its **own**
> `drive.ps1` call, then click and shoot in the calls after it — a resize
> mid-chain leaves the following `shot:` capturing a stale rectangle.

That harness is committed here:

```
.claude/skills/run-scoundrel/drive.ps1
```

All paths below are relative to the repo root. Gradle commands are run from
**Git Bash**; the driver is run from **PowerShell**.

## Prerequisites

A JDK 21+ on `PATH` and a real interactive Windows desktop session. Nothing to
install - the Gradle wrapper is committed. There is no headless path: the driver
screenshots the actual screen, so the window must be visible and not minimised.

## Build and test

```bash
./gradlew core:test          # the engine, the observers, the screen helpers
./gradlew lwjgl3:compileJava # launcher compiles
```

`core:test` prints almost nothing on success — and **exit 0 does not mean the
tests ran.** Gradle caches results against their inputs, so an unchanged tree
gives `:core:test UP-TO-DATE`: task skipped, no test events, exit 0. (That is
also what makes IntelliJ report *"Test events were not received"* — nothing is
broken, the task was skipped.) A test that passes because it never executed is
the failure mode this project has actually hit, so:

```bash
./gradlew core:cleanTest core:check   # force re-execution, then gate
```

Then **prove they ran** rather than trusting the exit code — the result XMLs are
rewritten only by a real run, so check their totals and their freshness:

```bash
# totals across the suite, and how long ago they were written
python -c "
import glob,os,time,xml.etree.ElementTree as ET
t=f=s=0; newest=0
for p in glob.glob('core/build/test-results/test/TEST-*.xml'):
    r=ET.parse(p).getroot()
    t+=int(r.get('tests')); f+=int(r.get('failures'))+int(r.get('errors')); s+=int(r.get('skipped'))
    newest=max(newest,os.path.getmtime(p))
print('tests',t,'failures',f,'skipped',s,'| written %.0fs ago'%(time.time()-newest))"
```

Stale timestamps mean you are reading the previous run. To confirm one specific
class ran, read its own XML:

```bash
grep -oE 'tests="[0-9]+" skipped="[0-9]+" failures="[0-9]+" errors="[0-9]+"' \
  core/build/test-results/test/TEST-com.tomer.scoundrel.rules.GameModesTest.xml
```

## Run (agent path) - START HERE

### 1. Launch, backgrounded

`lwjgl3:run` never returns, so it must be backgrounded:

```bash
nohup ./gradlew lwjgl3:run > /tmp/scoundrel-run.log 2>&1 &
```

### 2. Wait for the window and go windowed

Cold start is **60-120s** (Gradle + JVM + GL init). `-WaitSeconds` polls for the
window, so this single call covers the wait — and the game comes up
borderless-fullscreen, so take it to 1280x720 in the same call:

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -WaitSeconds 240 -Actions "key:F11,wait:600"
```

### 3. Screenshot, in a separate call

The resize has to land before anything is captured — `shot:` uses the client size
read at *invocation start*, so a shot chained after `key:F11` captures a stale
rectangle:

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -Actions "shot:C:\temp\scoundrel\title.png"
```

Then **look at the PNG** with the Read tool. A blank frame means it never came up;
a 1920x1080-ish frame means the F11 did not land and every coordinate below is off.

### 4. Click and screenshot

Actions are comma-separated and run in order: `click:<x>:<y>`, `move:<x>:<y>`,
`down:<x>:<y>`, `up` / `up:<x>:<y>`, `key:<name>`, `wait:<ms>`, `shot:<path>`,
`resize:<w>:<h>`.

`down:`/`up:` are the two halves of a click, so a **held** button can be
screenshotted — `click:` is over long before a `shot:` could catch it. Menu
buttons draw themselves sunk while held and act on release, so a press that
slides off and is taken back is driven as
`down:731:349,shot:...,move:250:650,shot:...,up:250:650`. Bare `up` releases
wherever the pointer already is. Always pair them in one chain: a `down:` with
no `up:` leaves the OS mouse button stuck down for whatever runs next.

`key:` takes `ESC`, `ENTER`, `SPACE`, `TAB`, any single letter or digit, or
`F1`-`F12` — the bindings the game polls per frame rather than through an
input processor:
**F11** toggles fullscreen, **F9** opens the developer sprite inspector
(`SpriteLab`), **Esc** leaves it, **M** mutes all audio (any screen; writes
`~/.scoundrel/audio.settings`).

Inside the lab, one key per effect, acting on whatever card the pointer is over:
**K** weapon kill, **B** barehanded, **A** avoid sweep, **E** equip, **P** potion,
**W** wasted potion, **D** hit, **H** heal, **X** death (with its music and
guttering torch), **Tab** the all-sprites sheet, **S** slow motion (÷8). Two need
no card: **R** toggles the run music, **V** plays a win (its cue, then the chime).
An effect removes its card and the other three **re-centre** (440/640/840), so
re-aim the pointer before the next key. Sub-second effects cannot be frame-grabbed at
their own speed — turn **S** on first, then trigger, and pace the `shot:`s at
eight times the timing you are checking.

**Audio has no pixels, so verify it from the sound log.** Launch with
`SCOUNDREL_AUDIO_LOG=1` in the environment (`gradlew lwjgl3:run` does not forward
`-D`); every play, effect, cue, level change and minimise prints to stdout as
`audio <seconds since launch> <event>`. `SCOUNDREL_NO_AUDIO=1` runs the game on
LibGDX's silent stand-in, as a machine with no audio device would. Keys are
sometimes dropped — check the log after each one that matters.

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 `
  -Actions "click:640:346,wait:1200,shot:C:\temp\scoundrel\picker.png"
```

### 5. Stop

```powershell
& powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\run-scoundrel\drive.ps1 -Kill
```

## Verified coordinates

Client pixels, origin **top-left**, window 1280x720 — so these hold only after
`key:F11` has taken the game out of its default borderless-fullscreen.

| Screen | Target | x, y |
|---|---|---|
| Title (pixel) | New game / How to play / The ledger / Trophies | 731,349 / 731,405 / 731,461 / 731,517 |
| Title (pixel) | First-run prompt: Play tutorial / Maybe later (shown while `~/.scoundrel/tutorial.seen` is absent; answering it creates the file) | 640,381 / 640,437 |
| Title (pixel) | MUSIC / SOUND plates (cycle on release) | 661,568 / 800,568 |
| Mode picker (pixel) | Standard / Relentless / Frail | 638,159 / 638,262 / 638,365 |
| Mode picker (pixel) | `ESC · BACK` in the header band | 1174,45 |
| Game board | Avoid button | 1198,46 |
| Game board | ESC's abandon question: Keep playing / Abandon run | 506,419 / 774,419 |
| The ledger | ERASE ALL PROGRESS plate (opens the same dialog: Keep it / Erase everything at 506,419 / 774,419 — never click the second) | 1123,665 |
| Game board | card centres, y = 342 | see formula below |
| End panel | New game / Main menu / Trophies / The ledger, one row | 444 / 573 / 698 / 825, at y = 533 with trophies unlocked, 476 without |

The room row is **centred**, so card centres shift as the room shrinks. Since the
pixel conversion cards are **176 wide on a 200 pitch**; for `n` cards the i-th
centre (0-based) is:

```
x = 640 - (n * 200) / 2 + 88 + (i * 200)
```

Verified: n=4 gives 340, 540, 740, 940; n=3 gives 440, 640, 840; n=2 gives
540, 740; n=1 gives 640. **A click between those centres lands in the 24px gap
and does nothing** — which looks exactly like a bug in whatever you just changed.
Recompute for the current room size before blaming the code.

## Gotchas

These all cost real time in this container.

- **The game writes to the real `~/.scoundrel/`.** Driving a game *to completion*
  appends to `runs.log` and can unlock achievements in the player's actual
  history. Abandoning mid-run (ESC → Abandon run, or kill the app) records nothing - runs persist only
  at game end. Back up `runs.log` / `achievements.log` before automating full games.
  A volume plate or **M** writes `audio.settings`; remove it afterwards if it was
  not there before. **The user also plays in the same window**, so check file
  timestamps against your own drives before blaming automation for a change.
- **Esc in a run asks; it does not leave.** Mid-run, `key:ESC` puts up the abandon
  question, and a chain that assumes it is back on the title clicks into that dialog
  instead. Leave with `key:ESC,wait:500,click:774:419` (Abandon run), which records
  nothing. Once the run is over, or in the tutorial, ESC goes straight to the title;
  with the move chooser open, the first ESC only closes the chooser (`BoardEscape`).
- **The window moves between launches.** Observed at screen 449,174 then 531,167
  then 320,144. The driver recomputes the client origin on every invocation -
  never hardcode screen coordinates.
- **The first synthesised click gets swallowed** activating the window, unless
  the caller forces foreground properly. `drive.ps1` does the
  `AttachThreadInput` dance for this; a naive `SetForegroundWindow` is refused
  and costs you a click.
- **Toggle keys carry state between calls.** `S` (slow motion), `R` and `Tab` flip
  whatever the game is already in, and the game outlives a `drive.ps1` call. A
  second chain that "turns slow motion on" actually turns it off, and every
  timed capture then lands in the wrong place — which looks exactly like the
  effect being broken. Either do the whole sequence in one chain, or read the
  on-screen state (the ROOM line prints `[SLOW 1/8]`) before assuming.
- **Do the whole capture in one `drive.ps1` call.** Windows refuses
  `SetForegroundWindow` from a background process, so once the game loses focus
  the driver cannot get it back and exits `NOT_FOREGROUND` until a human clicks
  the window. The game *has* focus right after `lwjgl3:run`, so a single long
  action chain — toggle, trigger, and every `shot:` — works unattended, while
  splitting the same steps across several calls stalls partway. Chain
  aggressively; there is no cost to a long `-Actions` string.
- **The same swallowing hits `key:`, and worse right after launch.** A single
  `key:F9` in the first invocation after `lwjgl3:run` was dropped twice during
  this skill's own verification — the window exists well before the game loop is
  reading input. Send it twice (`key:F9,wait:600,key:F9`); the toggles that
  matter are guarded against re-entry, so a second press is a no-op rather than
  an undo. **Always confirm the screen actually changed** before measuring
  anything in the shot — a dropped key leaves you screenshotting the title screen
  and measuring the wrong pixels.
- **`Shot` uses the client size read at invocation start.** If an action resizes
  the window mid-run (any `key:F11`), the following `shot:` captures a stale
  rectangle. Take the screenshot in a *separate* `drive.ps1` call after a resize.
- **`SetProcessDPIAware()` is mandatory** before any coordinate work, or Windows
  reports scaled sizes and every click lands off-target.
- **`FindWindow` races window creation** during startup; the driver falls back to
  matching `MainWindowTitle` over the process list.
- **World Y points up, client Y points down**: `client_y = 720 - world_y` when converting a
  coordinate read off the UI code. `CardArt.toWorldY` is the conversion the screens use.
- **Cards resolve on _press_, buttons on _release_** (`PressGesture`; the old
  `Widgets.pressListener` went with Scene2D). The driver's `click:` sends a full down+up, which satisfies
  both. A menu button also holds its sunk plate for 60ms before acting, so a
  `shot:` taken within ~100ms of a `click:` catches the button still down rather
  than the screen it navigates to — `wait:` at least 300ms after clicking a menu.
- **A card with more than one legal move opens a chooser popup** centred on that
  card (e.g. "Barehanded" / "Use weapon" for a monster while armed). Scripted
  play needs a second click to pick one.
- **A disabled button silently does nothing** - e.g. Avoid is permanently
  disabled in Relentless mode, and disabled mid-room in every mode.
- **Action strings split on the first colon only**, because screenshot paths
  contain `C:\`.
- **A screen that switches itself mid-frame must stop rendering.** `game.showX()`
  disposes the screen that called it, batch and textures included. Returning
  from a *helper* rather than from `render` lets the rest of the frame draw
  through freed memory — an `EXCEPTION_ACCESS_VIOLATION` in native code that
  kills the JVM instead of throwing. If the window vanishes mid-chain, check
  `/tmp/scoundrel-run.log` for an `hs_err_pid*.log` before assuming the driver
  lost it.
- **Screenshots capture screen pixels, not the window's buffer.** Anything
  floating above the window lands in the PNG - a desktop notification toast
  occluded the bottom-right corner during this skill's own verification run. If
  a region looks wrong, re-take the shot before believing it.
- **In borderless fullscreen, `CopyFromScreen` goes stale.** Four shots across
  three `drive.ps1` calls came back **byte-identical** while the game was
  demonstrably navigating between screens — it ended on a screen none of them
  showed. It reads exactly like input being ignored, and it is not. Verify a
  fullscreen change with **one** shot taken right after entering fullscreen, do
  the navigating windowed, and `md5sum` the PNGs before believing a sequence of
  them. Windowed capture is unaffected.
- **Leaving fullscreen draws one frame at the wrong scale.** *Entering* is a
  single clean resize to the display mode. *Leaving* is two, because
  `setUndecorated(false)` puts the caption bar back while the window is still
  full width — traced as `1920x1080 scale=1.5` on the way in, then
  `1920x1050 scale=1.0` and `1280x720 scale=1.0` on the way out. That middle
  line is one frame of a 1280x720 image with 320px bars, and it is easy to
  screenshot by accident and read as the settled state. It is not: verify
  fullscreen scaling on a shot taken *while still fullscreen*, and confirm it
  against a `bars=0,0` reading rather than against a PNG.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `WINDOW_NOT_FOUND`, exit 2 | App isn't up. Re-run with `-WaitSeconds 240`; check `/tmp/scoundrel-run.log` for a Gradle/JVM failure. |
| Screenshot identical after a click | You clicked a disabled control, or the click landed in a gap between cards. Re-read the previous screenshot and re-derive the coordinate. |
| `SHOT C` and a stray file named `C` | You passed the path through a splitter that broke on `C:\`. Use the `shot:` action as documented. |
| Window found but screenshot shows another app | Something is covering it. The driver activates first; just re-run the action. |
