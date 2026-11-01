# Defold Fighter

A 2D fighting game in Defold 1.14 (Lua), with art in LibreSprite. The target is HTML5 (wasm-web).
README.md covers the layout, controls, build and art pipeline.

## Working notes
- Game logic lives in `modules/` and is plain Lua with no Defold API calls. Run `tests/sim.lua` after changing frame data or the AI.
  There's no `lua` on PATH on the dev machine: use the LuaJIT inside the Defold editor jar (`libexec/x86_64-win32/luajit-64.exe`),
  e.g. `luajit-64.exe tests/sim.lua 20` from the project root (see F-18).
- Command-line builds use Bob from the editor jar. `tools/build_web.bat` does the HTML5 bundle.
  When the engine is running, build to a separate `--output` folder, because it locks `game.arcd`.
- Write Defold resource files and any text with escape sequences using the file tools, not shell heredocs or printf (see F-5 and F-13 in the log).
- Debug drawing (`draw_line` / `draw_debug_text` messages to `@render:`) shows only on the debug engine, not in release or HTML5 builds (see F-16).
  Test visual features on a release build before calling them done.
- Defold screen and GUI coordinates start at the bottom-left corner, with y pointing up (see F-17).
- Don't name a custom message `"volume"`: posting it crashes Defold 1.14 natively, with no Lua error (see F-19).
  If the engine dies with an `ERROR:CRASH` stack, bisect the change rather than guessing.
- If you're unsure whether a Defold API exists, check the docs bundled in the editor jar (`doc/*.sdoc`) or defold.com/ref. Bob builds don't catch a wrong Lua API name (see F-8).

## AI Failure Log (standing task for this whole project)
Alongside the dev work, maintain `Docs/AI-Failure-Log.md`. It is an honest record of every place where AI-generated work (yours or another agent's) was wrong, incomplete, or needed correction.
The log will be used to write evaluation tasks for AI models, so accuracy matters more than looking good.

### When to log
- Code you wrote fails to build, throws a runtime error, or behaves wrong in the game.
- The user corrects you, rejects your approach, or has to re-prompt for the same thing.
- You used a Defold API, message, property or setting that doesn't exist, is outdated, or doesn't work the way you assumed (check defold.com/ref when unsure).
- You applied a habit from another engine (Unity, Godot, Love2D) that doesn't fit Defold.
- Near misses: code that ran but needed a nudge, was fragile, or only worked by accident.
- The user says "log that" or similar.

Log the entry once the issue is resolved (or marked unresolved), in the same session.
Don't skip an entry because the fix was small. Never invent or exaggerate a failure, and never leave one out because it's embarrassing.

### Rules
- Append new entries at the bottom, numbered F-N in sequence.
- Never rewrite past entries. Add a dated "Follow-up:" line instead.
- Update the summary tables at the top of the file (by Area, by Failure type, by Severity, and the total) every time you add an entry.
- The log may be shared, so leave out API keys, personal info, and anything unrelated to the project.

### Entry format
```
### F-[number]: [short title]
- **Date:** YYYY-MM-DD
- **Agent/model:** e.g. Claude Code, Codex (if known)
- **Area:** collision | hitboxes | animation | input | GUI | messaging | factories/proxies |
  physics/timing | rendering | build/HTML5 | Lua logic | other
- **Request:** the user's prompt, verbatim or closely paraphrased
- **Expected:** what correct behavior looks like in the game
- **What the AI did:** short description, plus the key snippet (15 lines max)
- **Failure type:** build error | runtime error | wrong behavior | hallucinated API |
  outdated API | other-engine habit | logic error | incomplete
- **Detected by:** engine/build error | user | agent self-check
- **Root cause:** why it went wrong; mark "(uncertain)" if you're guessing
- **Fix:** what actually worked, with the correct API or approach
- **Severity:** blocker | needed fix | near miss
- **Eval potential:** one line on how this could become a task that tests an AI model
  (what to ask, and what a correct answer must get right)
```
