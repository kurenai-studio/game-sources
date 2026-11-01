# AI Failure Log

A record of every place where AI-generated work on this project was wrong, incomplete, or needed
correction. Entries are append-only; later notes go in a dated "Follow-up:" line.

Project: 2D fighting game in Defold 1.14 (Lua), art in LibreSprite, HTML5 target.

## Summary

Total entries: 19

| Area | Count |
|---|---|
| collision | 0 |
| hitboxes | 0 |
| animation | 0 |
| input | 0 |
| GUI | 2 |
| messaging | 1 |
| factories/proxies | 0 |
| physics/timing | 0 |
| rendering | 3 |
| build/HTML5 | 3 |
| Lua logic | 3 |
| other | 7 |

| Failure type | Count |
|---|---|
| build error | 3 |
| runtime error | 6 |
| wrong behavior | 5 |
| hallucinated API | 0 |
| outdated API | 1 |
| other-engine habit | 0 |
| logic error | 2 |
| incomplete | 2 |

| Severity | Count |
|---|---|
| blocker | 2 |
| needed fix | 6 |
| near miss | 11 |

Entries F-1 to F-15 were backfilled on 2026-10-31 from the first build session, before this log existed.
All 15 were found by the agent itself (headless simulation, engine logs, screenshots), not by the user.

---

### F-1: Dead no-op call left in fireball sprite generator
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** other (Python art generator)
- **Request:** "make a small game development project with Defold and LibreSprite ... a 2D fighting game ... two characters with move sets, one scene, a simple main menu ... combat AI"
- **Expected:** Fireball sprite renders with a dark outline; no pointless code.
- **What the AI did:** Wrote an `outlined()` call with an empty draw function "to keep the API symmetric", then built the outline by hand on the next lines anyway.
  ```python
  out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
  outlined(out, (w, h), lambda dd: None)  # no-op keeps API symmetric
  alpha = img.split()[3].point(...).filter(ImageFilter.MaxFilter(3))
  ```
- **Failure type:** logic error (dead code)
- **Detected by:** agent self-check (re-reading before first run)
- **Root cause:** Changed approach mid-function and kept the abandoned call with a made-up justification in the comment.
- **Fix:** Deleted the call. Output was unchanged.
- **Severity:** near miss
- **Eval potential:** Give a model a function with a do-nothing call and a plausible comment, and ask it to review the code. A correct answer flags the call as dead code and doesn't accept the comment as a reason.

### F-2: Hit handler read `self.move` after clearing it
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** Lua logic
- **Request:** Same as F-1 (fighter move sets).
- **Expected:** A fighter hit mid-attack goes into hitstun, with a crouching hit-reaction if it was crouching.
- **What the AI did:** `take_hit` set `self.move = nil` first, then called `is_crouching()`, which reads `self.move.crouch` while the fighter's state is still `"attack"`.
  ```lua
  function M:take_hit(h, dir, blocked)
      self.move = nil
      ...
      self.low = self:is_crouching()   -- indexes self.move -> nil
  ```
  Error: `fighter.lua:97: attempt to index field 'move' (a nil value)`
- **Failure type:** runtime error
- **Detected by:** agent self-check (headless CPU-vs-CPU simulation, `tests/sim.lua`)
- **Root cause:** Order-dependent state reset. A query function depended on state that the same function had already cleared.
- **Fix:** Save `local was_low = self:is_crouching()` before any state is cleared, and use it afterwards.
- **Severity:** needed fix
- **Eval potential:** Give a state machine where a reset clears a field that a helper reads later. Ask why it crashes only when an attacker is hit during their own attack; a correct answer names the ordering and saves the value first.

### F-3: Simultaneous hits ("trades") crashed on the second hit
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** Lua logic
- **Request:** Same as F-1.
- **Expected:** When both fighters' attacks connect on the same frame, both take the hit.
- **What the AI did:** Collected both hits, then applied them in order using `att.move`. The first `take_hit` cleared the other fighter's `move`, so the second hit passed `nil` as its damage data.
  ```lua
  pending[#pending + 1] = { att, def, hx, hy }
  ...
  local blocked = self:apply_hit(att, def, att.move, att.x, p[3], p[4])
  ```
  Error: `match.lua:169: attempt to index local 'h' (a nil value)`
- **Failure type:** runtime error
- **Detected by:** agent self-check (headless simulation)
- **Root cause:** It detected the hits and applied them in two passes but didn't snapshot the data the second pass needed. The first application changed it.
- **Fix:** Store the move in the pending record at detection time: `{ att, def, hx, hy, att.move }`, and use `p[5]`.
- **Severity:** needed fix
- **Eval potential:** Ask for "simultaneous hit resolution" in a fighting game. A correct answer captures every hit's data before applying any of them.

### F-4: Character balance declared fixed too early (Comet Knee dominated)
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** Lua logic (frame data / AI)
- **Request:** Same as F-1 (two characters with move sets, combat AI).
- **Expected:** At equal AI difficulty neither character wins much more than half the time.
- **What the AI did:** First tuning had Vera beating Kenji 16–4. It weakened Comet Knee once, and on a 32-match sample (Kenji 12–20) called it "close to even" and moved on. A later 240-match run showed Vera winning 82%. It took four more tuning rounds. The real driver was an asymmetry, not raw damage: Vera's punch→Comet Knee cancel was a guaranteed combo, while Kenji's punch→Fireball (18-frame startup) wasn't.
  ```lua
  -- final state
  frames = { { "special_0", 5 }, { "special_1", 7 }, { "special_2", 4, spawn = true }, { "special_3", 18 } }, -- Kenji
  { "special_0", 4, invuln = true }, { "special_0", 3 },
  { "special_1", 5, hit = true, vx = 11 }, { "special_2", 12, hit = true, vx = 8 }, -- Vera
  damage = 9,
  ```
- **Failure type:** wrong behavior
- **Detected by:** agent self-check (per-move damage tally in headless simulation)
- **Root cause:** It drew a conclusion from a sample that was too small, and tuned damage, range and invulnerability before checking the structural cause (combo cancels).
- **Fix:** Shorter Comet Knee travel and invulnerability, damage 9, tighter AI usage ranges, and a 12-frame Fireball startup so Kenji's cancel also combos. Final result: Kenji wins 54% over 360 matches (3 random seeds); mirror matches are even.
- **Severity:** needed fix
- **Eval potential:** Give two move lists with frame data and ask which character is favored and why. A correct answer spots the cancel-combo asymmetry and asks for a large enough sample before calling it balanced.

### F-5: Shell escaping corrupted generated Defold `.go` files
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** other (tooling for Defold resource files)
- **Request:** Same as F-1.
- **Expected:** Embedded component data in `.go` files uses escaped `\n` and `\"` inside one quoted string.
- **What the AI did:** It generated the files with `printf` in Git Bash. The `\\n` sequences came out as real newlines inside the quoted `data:` string. A second attempt, using a Python heredoc in the same shell, failed with a `SyntaxError` because backslashes were mangled again.
  ```
  data: "default_animation: \"kenji_idle_0\"
  material: \"/builtins/materials/sprite.material\"
  ```
- **Failure type:** build error (caught by inspecting the output before building)
- **Detected by:** agent self-check
- **Root cause:** Two levels of escaping (Defold's protobuf text format inside shell quoting). The Git Bash tool's heredoc and backslash handling didn't behave as assumed (exact mechanism uncertain).
- **Fix:** Wrote the generator as a `.py` file with the file-writing tool and ran it, so the shell never processes the escaped data.
- **Severity:** near miss
- **Eval potential:** Ask a model to generate a Defold `.go` file with an embedded sprite component. A correct answer escapes the nested `data:` string properly: one physical line, with `\n` and `\"`.

### F-6: Engine failed to start: "Unable to load bootstrap data"
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** build/HTML5
- **Request:** Same as F-1 (agent verifying its own build).
- **Expected:** `dmengine.exe` runs the game built by Bob.
- **What the AI did:** Built loose files (no `--archive`) and launched the engine from Git Bash with a relative project path.
  ```
  bob ... --variant debug build
  cd build/default && dmengine.exe game.projectc
  -> ERROR:ENGINE: Unable to load bootstrap data.  INFO:ENGINE: Loading data from: (empty)
  ```
- **Failure type:** runtime error
- **Detected by:** engine/build error
- **Root cause:** (uncertain) Either the engine didn't receive or accept the relative path from Git Bash, or it needs an archive build when started outside the editor. Both were changed at once, so it's not known which one mattered.
- **Fix:** Build with `--archive`, then start the engine from PowerShell with an absolute path: `dmengine.exe C:\...\build\default\game.projectc`. Log then shows `Loading data from: archive:...game.dmanifest`.
- **Severity:** blocker
- **Eval potential:** Ask how to run a Bob-built Defold project from the command line without the editor. A correct answer covers `--archive` and passing the `game.projectc` path, and checks the log's "Loading data from" line.

### F-7: Screenshot helper captured the wrong window
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** other (test tooling)
- **Request:** Same as F-1 (agent verifying the game visually).
- **Expected:** Screenshots of the agent's own autoplay game window.
- **What the AI did:** Captured a screen rectangle with `Graphics.CopyFromScreen`, which records whatever is on top. One capture showed a different game instance (the user's), and the next showed the Claude app.
  ```powershell
  $g.CopyFromScreen($pt.X, $pt.Y, 0, 0, $bmp.Size)
  ```
- **Failure type:** wrong behavior
- **Detected by:** agent self-check (the HUD said "KENJI" where the autoplay build shows "KENJI (CPU)")
- **Root cause:** Screen-region capture assumes the target window is in front. Bringing it to the front from a background process didn't work, because Windows restricts which process may take focus.
- **Fix:** `PrintWindow(hwnd, hdc, 3)` (PW_RENDERFULLCONTENT), which captures that window even when it's covered.
- **Severity:** near miss (could have produced false evidence about game state)
- **Eval potential:** Ask for a script that screenshots a specific window of an OpenGL game on Windows while other windows cover it. A correct answer uses a per-window capture, not a screen region.

### F-8: `gui.cancel_animation` doesn't exist in Defold 1.14
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** GUI
- **Request:** Same as F-1 (HUD with round announcements and combo counter).
- **Expected:** "ROUND 1", "FIGHT!", "K.O." and "N HITS" text pops up during a match.
- **What the AI did:** Called `gui.cancel_animation(node, property)` before starting each new animation. Every announcement errored, so no announcement text ever appeared. The game otherwise ran, and the build passed.
  ```lua
  gui.cancel_animation(n, "color.w")
  gui.cancel_animation(n, "scale")
  -- ERROR:SCRIPT: fight/hud.gui_script:58: attempt to call field 'cancel_animation' (a nil value)
  ```
- **Failure type:** outdated API
- **Detected by:** agent self-check (no announcement in a screenshot series that should have contained one, then the engine log)
- **Root cause:** Used an older API name from memory. The bundled 1.14 API docs (`doc/gui_script.cpp_doc.sdoc`) list only `gui.cancel_animations`. The version where the old name was removed is uncertain.
- **Fix:** `gui.cancel_animations(node, "color.w")`. Confirmed working in 1.14.
- **Severity:** needed fix
- **Eval potential:** Ask for Defold 1.14 GUI code that restarts a fade and scale animation on a text node. A correct answer uses `gui.cancel_animations` and `"color.w"`. Bob builds don't catch this, so the test has to run the code.

### F-9: Mirror matches were indistinguishable
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** rendering
- **Request:** Same as F-1 (menu allows Random or same-character opponents).
- **Expected:** In Kenji vs Kenji you can tell which fighter is which.
- **What the AI did:** Both fighters used identical sprites, with no alternate colors.
- **Failure type:** incomplete
- **Detected by:** agent self-check (screenshot of a random-pick mirror match)
- **Root cause:** It designed character select without considering same-character matches.
- **Fix:** Tint player 2's sprite when `state.p1 == state.p2`: `go.set(url, "tint", vmath.vector4(0.55, 0.75, 1.0, 1))`. A proper palette swap would look better; the tint is a placeholder.
- **Severity:** near miss
- **Eval potential:** Ask for a character-select feature. A correct answer handles mirror matches, for example with alternate colors.

### F-10: Rebuild failed because the running engine locked the archive
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** build/HTML5
- **Request:** Same as F-1 (agent rebuilding after a fix).
- **Expected:** Bob rebuilds while a copy of the game is still running.
- **What the AI did:** Rebuilt into `build/default` while a `dmengine` process had that build's `game.arcd` open.
  ```
  ERROR game.project:0 ...\build\default\game.arcd: The process cannot access the file because it is being used by another process
  ```
- **Failure type:** build error
- **Detected by:** engine/build error
- **Root cause:** On Windows a running engine keeps its archive open, so the file can't be overwritten.
- **Fix:** Build to a separate output folder (`--output build/verify`) for test runs.
- **Severity:** near miss
- **Eval potential:** Ask why a Defold command-line rebuild fails on Windows with "file in use". A correct answer names the running engine holding the archive and suggests a separate output folder or closing it.

### F-11: Screenshot helper crashed on a minimized window
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** other (test tooling)
- **Request:** "Yes, test them" (test pause, rematch and quit-to-menu)
- **Expected:** Periodic screenshots while waiting for a match to end.
- **What the AI did:** The helper read the client rectangle and created a bitmap of that size. A minimized window has a 0×0 client area, so `new Bitmap(0, 0)` threw and the wait loop produced no captures.
- **Failure type:** runtime error
- **Detected by:** agent self-check (PowerShell exception)
- **Root cause:** It didn't account for the window being minimized.
- **Fix:** If `IsIconic(hwnd)`, call `ShowWindow(hwnd, 4)` (restore without taking focus) before capturing.
- **Severity:** near miss
- **Eval potential:** Ask for a robust window-capture function. A correct answer handles minimized and zero-size windows.

### F-12: Pause-screen move list ran off both screen edges
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** GUI
- **Request:** "Yes, test them"
- **Expected:** The move list on the pause screen fits within the 1280-wide screen.
- **What the AI did:** Put the whole move list on one ~95-character line in a text node with `line_break: false`. At the 22 px font it was wider than the screen, so both ends were cut off.
  ```lua
  kenji = "J punch  K kick  L FIREBALL  |  down+J low jab  down+K sweep  air K jump kick  |  hold back to block",
  ```
- **Failure type:** wrong behavior
- **Detected by:** agent self-check (screenshot during the pause test)
- **Root cause:** Didn't estimate how wide the text would render in the chosen font.
- **Fix:** Two lines joined with `\n`, the node set to `line_break: true`, and its size set to 1000×80.
- **Severity:** needed fix
- **Eval potential:** Give a GUI text node with a font size and a long string, and ask whether it fits a 1280 px screen. A correct answer estimates the width and wraps the text.

### F-13: Heredoc turned `\n` in a Lua string into a real newline
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** other (tooling), affecting Lua source
- **Request:** "Yes, test them" (the F-12 fix)
- **Expected:** `"line one\nline two"` in `fight.script`.
- **What the AI did:** Did the replacement with a Python script in a bash heredoc. The `\\n` became a literal line break inside a double-quoted Lua string, which is a syntax error. This is the same mechanism as F-5, repeated later in the session.
  ```lua
  kenji = "J punch   K kick   L FIREBALL   hold back to block
  down+J low jab   down+K sweep   K in the air: jump kick",
  ```
- **Failure type:** build error (caught by grep before building)
- **Detected by:** agent self-check
- **Root cause:** It repeated a tooling pattern already known to break (F-5) instead of using the file-editing tool.
- **Fix:** Edited the line with the exact-replace edit tool.
- **Severity:** near miss
- **Eval potential:** Ask a model to make several edits that contain escape sequences. A correct answer avoids shell layers that re-interpret backslashes and checks the result.

### F-14: Wrong diagnosis of the frozen HTML5 build in the browser pane
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** other (HTML5 test harness)
- **Request:** "We're going to be building this for HTML."
- **Expected:** Find out whether the web build ignores input or whether the test environment is the problem.
- **What the AI did:** The menu didn't react to the browser pane's simulated key presses. It first blamed the hidden pane pausing the page. Its frame-rate test was wrong: the callback never rescheduled itself, so it could only ever count 1 frame.
  ```js
  function f(){ n++; } requestAnimationFrame(f);   // counts at most one frame
  ```
  A corrected test showed ~26 frames per second. Dispatching DOM `KeyboardEvent`s on the canvas worked; the pane's own key tool did not reach the page. The game also ran far below real time while the pane was hidden.
- **Failure type:** logic error
- **Detected by:** agent self-check
- **Root cause:** A diagnostic that couldn't produce the answer it was testing for, plus a guess made before checking.
- **Fix:** Rescheduling frame counter; then a headless Chrome script driven over the DevTools protocol to test at 60 fps.
- **Severity:** near miss
- **Eval potential:** Ask for a JS snippet that measures a page's frame rate over one second. A correct answer re-registers `requestAnimationFrame` on every frame.

### F-15: Headless Chrome test started without WebGL
- **Date:** 2026-10-31
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** build/HTML5
- **Request:** "We're going to be building this for HTML."
- **Expected:** Headless Chrome runs the Defold WebAssembly build so it can be screenshot-tested.
- **What the AI did:** Launched with `--headless=new --use-angle=swiftshader --enable-unsafe-swiftshader`. The page had no WebGL context.
  ```
  TypeError: Cannot read properties of undefined (reading 'getParameter') at _glGetString
  ```
- **Failure type:** runtime error
- **Detected by:** engine/build error (page exception captured over the DevTools protocol)
- **Root cause:** Wrong flags for software WebGL in headless Chrome (uncertain exactly which flag was missing).
- **Fix:** `--use-gl=angle --use-angle=swiftshader-webgl --ignore-gpu-blocklist --enable-webgl --enable-unsafe-swiftshader`. The build then ran at 60 fps with no console errors.
- **Severity:** near miss
- **Eval potential:** Ask how to automate screenshot tests of a WebGL or WebAssembly game in headless Chrome. A correct answer enables software WebGL and checks for a GL context.

### F-16: Hitbox viewer used debug lines, which the release/HTML5 engine doesn't draw
- **Date:** 2026-11-01
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** rendering
- **Request:** Build feature #2 from the suggestion list: "Hitbox viewer for training" ("Let's skip one and go straight to two.")
- **Expected:** Pressing H in a fight shows hurt, hit and push boxes, including in the HTML5 build (the project's target, which is a release build).
- **What the AI did:** Drew the boxes with `draw_line` messages and the color key with `draw_debug_text`. They showed on the debug engine. On the release engine nothing appeared, with no error or warning.
  ```lua
  for i = 1, 4 do
      msg.post("@render:", "draw_line", { start_point = corners[i], end_point = corners[i % 4 + 1], color = color })
  end
  msg.post("@render:", "draw_debug_text", { text = c[1], position = vmath.vector3(x, 140, 0), color = c[2] })
  ```
- **Failure type:** wrong behavior
- **Detected by:** agent self-check (screenshot of the release build)
- **Root cause:** The API exists and is current, but it only works on the debug engine. The 1.14 docs only say `draw_line` "should mostly be used for debugging purposes", and say nothing about release builds. The agent noticed that gap before writing the code but built on the API anyway and tested afterwards. Running the same archive on `dmengine.exe` draws the boxes and on `dmengine_release.exe` doesn't, so it's the engine variant, not the build. The engine-side mechanism (debug rendering compiled out of release) is (uncertain).
- **Fix:** Draw the boxes with sprites: a 4×4 white `pixel` atlas image in a `box.go` prototype, spawned from a pooled `factory`, positioned and scaled to each edge (2 px outline, 20% fill), with `tint` for color and `enable`/`disable` to hide unused sprites. The color key is GUI text nodes made with `gui.new_text_node`. Verified on the debug engine, the release engine, and the HTML5 bundle in headless Chrome.
- **Severity:** needed fix
- **Eval potential:** Ask for a hitbox debug overlay in a Defold game that ships to HTML5. A correct answer doesn't rely on `draw_line`/`draw_debug_text`, or says that they only show on the debug engine and tests a release build.

### F-17: Debug text placed as if y were measured from the top of the screen
- **Date:** 2026-11-01
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** rendering
- **Request:** Same as F-16.
- **Expected:** The hitbox color key sits near the top-left, under player 1's name.
- **What the AI did:** Placed the key at `vmath.vector3(20, 140, 0)`. Defold screen coordinates have their origin at the bottom-left, so the key showed up 140 px above the bottom edge, on top of the fighters.
- **Failure type:** wrong behavior
- **Detected by:** agent self-check (screenshot of the debug build)
- **Root cause:** (uncertain) Probably the top-left screen origin that many other engines and UI toolkits use. The code didn't state which origin it assumed.
- **Fix:** Moved to `config.HEIGHT - 120`. After F-16 the key became GUI text nodes at y = 595 in the 1280×720 GUI scene, which also has its origin at the bottom-left.
- **Severity:** near miss
- **Eval potential:** Ask where `msg.post("@render:", "draw_debug_text", { position = vmath.vector3(20, 140, 0), ... })` appears on a 1280×720 Defold screen. A correct answer says near the bottom-left, because y counts up from the bottom.

### F-18: Documented test command used a `lua` executable that isn't installed
- **Date:** 2026-11-01
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** other (documentation / tooling)
- **Request:** "Let's get this on GitHub. Upload the failure log as well and add an adequate README."
- **Expected:** The commands in README.md and CLAUDE.md work as written on the dev machine, or say what they need.
- **What the AI did:** The earlier README and the CLAUDE.md written for future sessions both said to run `lua tests/sim.lua 20`. There's no `lua` on PATH on this machine; the simulation had actually been run with the `luajit-64.exe` from the Defold editor jar. Running the documented command gives `lua: command not found`. The CLAUDE.md version had already been pushed in the first GitHub commit.
  ```
  Run `lua tests/sim.lua 20` after changing frame data or the AI.
  ```
- **Failure type:** incomplete
- **Detected by:** agent self-check (re-running the test before writing the GitHub README)
- **Root cause:** It wrote the generic command from memory instead of the one it had actually used.
- **Fix:** The README now says any Lua 5.1/LuaJIT works and explains how to get `luajit-64.exe` out of the Defold editor jar. CLAUDE.md now gives that path. Re-ran `luajit-64.exe tests/sim.lua 4`; all matches finished without errors.
- **Severity:** near miss
- **Eval potential:** Give a project's notes and a shell transcript, and ask the model to document how to run the tests. A correct answer uses the command that actually ran in the transcript and states its prerequisites.

### F-19: Posting a custom message named "volume" crashed the engine
- **Date:** 2026-11-01
- **Agent/model:** Claude Code (Claude Opus 5.5)
- **Area:** messaging
- **Request:** "Let's just add an audio volume control to finish up."
- **Expected:** Starting a fight shows the current volume on the pause screen; the game keeps running.
- **What the AI did:** Added a HUD update message called `"volume"`, posted from `fight.script` when a match starts and when the volume changes. As soon as the fight scene loaded, the engine died with a native crash (`ERROR:CRASH: CALL STACK:` with frames in `vsnprintf`/`printf`), with no Lua error first. The menu part of the feature worked.
  ```lua
  -- fight.script, new_match()
  msg.post("#hud", "volume", { label = settings.volume_label() })
  -- hud.gui_script
  elseif message_id == hash("volume") then
  ```
  The first diagnosis was a guess: that the "50%" label reached an engine log call as a format string. Removing the `%` still crashed, so that guess was wrong.
- **Failure type:** runtime error
- **Detected by:** engine/build error (native crash at fight start), then agent self-check (bisecting)
- **Root cause:** Bisected with `git stash` and rebuilds. The crash needs only that `msg.post` line: it still crashes with the HUD script back at its committed version (so nothing handles the message), and it stops when the line is removed or the message is renamed to `"volume_label"` with the same payload. Why the id `"volume"` crashes is (uncertain): it isn't documented as a built-in message in the 1.14 docs, and the only bare `volume` string in `dmengine.exe` belongs to glTF material data. It may be an engine bug or an undocumented internal message name. Not tested: other message ids, or other payloads with `"volume"`.
- **Fix:** Renamed the message to `"volume_label"` in both scripts, with a comment at the post site. The engine runs; the pause screen shows and changes the volume; verified on the desktop debug engine and in the HTML5 build.
- **Severity:** blocker (no fight could start)
- **Eval potential:** Give a Defold project whose engine dies with a native crash right after a change that added several things, and ask for a diagnosis plan. A correct answer bisects the change instead of guessing from the stack, and doesn't stop at the first plausible theory.
