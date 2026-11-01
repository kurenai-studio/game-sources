---
name: windows-desktop-screenshot-verification
description: how to actually see and click the LWJGL3 desktop window from this Bash-only environment, to satisfy "verify on a real GPU, not headless"
metadata:
  type: project
---

This environment has no direct screenshot/GUI tool, but the desktop build runs as a real Win32
window on a real GPU, and `CLAUDE.md`'s pitfall list explicitly distrusts headless verification
(that pitfall is written for headless Chrome/web, but the same doubt applies to trusting "it didn't
crash" as proof a screen renders correctly). This is the technique that worked, run through the
`Bash` tool as inline PowerShell (`powershell -NoProfile -Command "..."`), on Windows:

1. Launch the app in the background: `(./gradlew.bat :desktop:run --console=plain > /tmp/run.log 2>&1 &)`, then sleep a few seconds.
2. Find the window: `Get-Process java | Select-Object Id, MainWindowTitle` — the one with the app's title (set via `Lwjgl3ApplicationConfiguration.setTitle`).
3. Foreground it: a small inline C# snippet via `Add-Type` calling `user32.dll`'s `ShowWindow`/`SetForegroundWindow` on `$p.MainWindowHandle`. Skipping this step screenshots whatever else has focus (e.g. an IDE window on top) instead of the game.
4. Screenshot the primary screen with `System.Windows.Forms.Screen` + `System.Drawing.Graphics.CopyFromScreen`, save to a PNG under the scratchpad, then `Read` it as an image.
5. To click a button: `user32.dll`'s `SetCursorPos` to the window's screen coordinates (the window's own top-left plus the logical-pixel position, scaled by whatever integer factor the window opened at) followed by `mouse_event` with `MOUSEEVENTF_LEFTDOWN`/`MOUSEEVENTF_LEFTUP` (`0x0002`/`0x0004`).
6. Kill the process afterwards: `Get-Process java | Stop-Process -Force` — the background gradle run keeps the JVM alive after the shell call returns.

Confirmed this actually catches real bugs `compileJava` cannot: it is what surfaced the
`Skin.add`/`getDrawable` mismatch (see `[[skin-add-drawable-lookup-mismatch]]`), a runtime exception
thrown from `create()` that only a real launch — not a compile — could ever show. After fixing it,
the same loop (steps 1-4, then click through menu → ship select → play) is what confirmed the HUD
plates, the checkerboard playfield and the screen navigation actually render as intended, not just
that the code compiles.

**A blank/black window is not necessarily a rendering bug.** Repeated `:desktop:run` invocations
without stopping the previous JVM leave Gradle daemons stacked up; the game process still launches
and its title shows in `Get-Process`, but the window can screenshot as flat black with zero draw
calls visible, no exception anywhere in the log. Kill every `java` process
(`Get-Process java | Stop-Process -Force`) before each fresh launch, wait a full ~10s after starting
before the first screenshot, and don't use `./gradlew --stop` to clean up — it kills the daemon the
running game's JVM lives inside, not just idle ones. Confirmed: the exact same build that screenshot
solid black once rendered correctly on the next clean launch with no code change in between.

**Simulating a keypress into the LWJGL3/GLFW window needs the scan code, not just the virtual-key
code.** Neither `System.Windows.Forms.SendKeys.SendWait` nor `user32.dll`'s `keybd_event(vk, 0, ...)`
(scan code byte left at 0) nor `PostMessage(hwnd, WM_KEYDOWN, vk, 0)` (lParam scan-code bits left at
0) reaches the game at all — no exception, no visible effect, focus just never moves. GLFW's Win32
backend resolves a key from the **scan code** bits of `WM_KEYDOWN`'s `lParam`, not from the
virtual-key code in `wParam`; a message with scan code 0 resolves to an unknown key and is silently
dropped. Fix: call `MapVirtualKey(vk, MAPVK_VK_TO_VSC)` (`uMapType = 0`) to get the real scan code,
pass it as `keybd_event`'s `bScan` argument, and set `KEYEVENTF_EXTENDEDKEY` (`0x1`) for arrow keys
and other extended keys (they share a scan code with the numpad otherwise). Confirmed this actually
moves keyboard focus in a scene2d `Stage`, where the three broken techniques above produced nothing
observable at all — worth trying this before concluding a keyboard-input code path is broken from a
screenshot showing no change.

**A plain `ShowWindow`/`SetForegroundWindow` call can silently fail to raise the game window** on
this machine, because another application (seen here: a Warp terminal tab running an unrelated
Claude session on the same Windows desktop) already holds the foreground and Windows' focus-stealing
prevention blocks a background process from stealing it. Symptom: the call returns no error, but the
next screenshot still shows the other app full-screen, not the game. Fix: `AttachThreadInput` the
calling thread to the current foreground window's thread before calling `ShowWindow` /
`BringWindowToTop` / `SetForegroundWindow`, then detach afterwards — this is the standard Win32
workaround for the same-desktop-different-app case and it reliably raised the window here.
Also worth checking first: `Get-Process java | Select-Object Id, MainWindowTitle` before assuming a
second `java` process is a rendering conflict — on a shared machine another agent's own
`:desktop:run` can be running concurrently, but each has its own PID and only the one with the
expected title (set via `Lwjgl3ApplicationConfiguration.setTitle`) is this session's window.

**A frozen-looking gameplay screenshot is not necessarily a bug.** Level 1's five scripted enemies
(`assets/data/level-01.json`) can all die before the player takes a single hit if nothing shoots
back in time, in which case the HUD legitimately stops changing once the wave timeline empties and
no enemy is left — `LevelOutcome` stays `IN_PROGRESS` until the run actually ends, so a static score
across several screenshots can mean "nothing new happened" rather than "the render loop stalled".
Also: transient effects tied to a short `core` duration (a 2 s respawn grace, a 3-tick damage flash)
are very hard to catch with this screenshot technique — each `powershell` round-trip to capture and
save a screenshot costs roughly 1-2 s, which is longer than some of the states it would need to catch
mid-flight. Reading the drawing code and hand-tracing the tick arithmetic is the fallback when a
state is real but too short-lived to reliably screenshot.
