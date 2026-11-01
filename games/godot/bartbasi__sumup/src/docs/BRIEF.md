# SumUp: Kickoff Brief

This is the kickoff brief from Bart Basi, the project owner, copied into the repo so every agent can read it. Wording is unchanged; only the formatting was turned into Markdown. The one exception: on 2026-10-13 Bart renamed the game from numbersgame to SumUp, and the name was changed here to match. The Development Manager owns this file. Nobody else edits it.

You are the Development Manager for SumUp, a number-merge puzzle game for Android (later iOS, Windows and Linux). You run the team described below, coordinate their work, integrate it, and report to Bart Basi, who owns the project. Read this whole brief before doing anything.

If anything here is unclear, conflicts with something else in this brief, or would force you to guess, stop and ask Bart. Do not pick an interpretation silently.

## 1. What we are building

A game with the same core mechanic as the mobile game "2248", rebuilt with our own rules document, our own modern visual design, and no paid anything.

- Endless mode only for v1. Play until no move is possible, chase a high score.
- Boosters exist, but the player pays for them with score points, never money.
- Built-in skins the player can switch between.
- One clean, positive click sound, which the player can turn on or off.
- Fully offline.

## 2. Fixed decisions (do not revisit without asking Bart)

| Topic | Decision |
|---|---|
| Engine | Godot 4, latest stable 4.x installed on this machine. Record the exact version in README.md. |
| Language | GDScript, statically typed. No C#, no GDExtension. |
| Renderer | Compatibility renderer, for the widest Android device support. |
| Platform for v1 | Android, portrait only. Develop and iterate in the Godot editor on Windows. |
| Dev machine | Windows, Claude Code. |
| Repo | github.com/bartbasi/sumup, private. |
| Assets | Nothing paid. Every visual and every sound is made in code. No image files, no audio files, no asset store downloads, no third-party addons. |
| Network | None. No accounts, no ads, no analytics, no leaderboards. Release builds request no Android permissions. |
| Skins | Built-in only for v1. Player-made skins are a v2 or v3 feature. Do not build import of any kind. |
| Level goals | Not in v1. Keep game rules separate from UI so they can be added later, but build nothing for them now. |
| Booster payment | Cost is deducted from the current run's score. |

## 3. Game rules (the Lead Game Designer turns this into docs/GDD.md)

These are the rules Bart confirmed. The designer fills the gaps marked Designer decides, documents each decision with worked examples, and gets Bart's sign-off at Hard Stop 1.

**Board.** A grid of numbered tiles. Every value is a power of two. 5 columns by 8 rows unless the designer has a strong reason to change it.

**Making a chain.** The player drags a finger across tiles that touch, in any of eight directions (including diagonals). A tile cannot be used twice in one chain.

- The chain must start with two tiles of equal value.
- Each next tile must equal the previous tile or be double it.
- Lifting the finger with a chain of 2 or more commits it. Lifting on an invalid chain cancels with no penalty.

**Merge result.** The connected values are summed and converted to a power of two. Designer decides the rounding rule (round down or round up to a power of two) and shows at least six worked examples. The live result shows as a preview while dragging.

**After a merge.** The result lands on the last tile of the chain. Other chain tiles clear, tiles above fall down, and new tiles spawn from the top. Designer decides the spawn table: which values can spawn and how that range moves up as the board's highest tile grows.

**Score.** Each committed chain adds the sum of its tile values to the score. Track Best Score and Best Tile separately, because spending on boosters lowers the final score.

**Game over.** No valid chain exists on the board. Designer decides how the game-over moment offers any booster the player can still afford (Shuffle is the obvious rescue) before the run ends.

**Boosters.** Paid from current score. A booster the player cannot afford is visibly disabled. Score can never go below zero.

| Booster | Effect | Target |
|---|---|---|
| Hammer | Destroys one tile; tiles above fall, a new tile spawns | One tile |
| Swap | Swaps two tiles | Two tiles |
| Shuffle | Randomly rearranges the whole board | None |
| Double | Doubles one tile's value | One tile |
| Undo | Restores board and score to before the last chain. The Undo cost stays spent. | None |

Designer decides each booster's cost (flat, or scaled to board progress) with reasoning and examples from an early, mid and late game. Targeting boosters can be cancelled by tapping the booster again.

**Number display.** Large values abbreviate (for example 1024 stays, 2048 becomes 2K). Designer decides the exact threshold and format, and it must stay readable on the smallest tile size we support.

**Persistence.** The current run saves automatically and resumes after the app is closed or killed. Settings (sound on or off, selected skin) and Best Score and Best Tile persist.

## 4. Visual and sound direction

Design is the most important quality bar in this project. It has to look fresh, modern and clean, not like a template.

- Dark mode first, bold colors. All three design directions (Phase 1) live inside that range but must be clearly different from each other, not three color swaps of one layout.
- Every visual is built in Godot code: StyleBoxFlat, Theme resources, _draw() calls, shaders, Tweens. No image files.
- Numbers on tiles meet a 4.5:1 contrast ratio against their tile color, checked by a script, not by eye. The number is always shown, so color is never the only signal.
- Respect device safe areas (notches, rounded corners, gesture bar).
- Target 60 fps on a mid-range Android phone.
- Fonts. Open question for Bart at Hard Stop 1. A font file, even a free open-license one, is not "made in code". The default is Godot's built-in font or the device's system font. The senior designer shows the chosen direction both ways (system font and one free open-license font) so Bart can decide.

**Click sound.** Synthesized in code at startup into an AudioStreamWAV (short, bright, soft attack, quick decay, roughly 50 to 90 ms, no clipping). It plays when a tile joins a chain and when a chain commits. On by default. The toggle lives in Settings and persists. No other sounds in v1 unless Bart approves them.

## 5. The team

In Phase 0, create one agent file per role in .claude/agents/, using each role below as the source for the file's description and instructions. Each file says what the agent owns, what it reads, what it produces, and that it must not touch files outside its ownership.

Subagents cannot launch other subagents. You, the main session, launch every agent. When the Senior Graphic Designer needs its two artists, it writes their task briefs and you launch them.

**Development Manager** (you, the main session). Owns the plan, docs/ARCHITECTURE.md, integration, git, and all communication with Bart. You launch agents, check their output against the brief, resolve conflicts between them, and enforce hard stops.

**Lead Game Designer** (lead-game-designer). Writes docs/GDD.md from section 3. Owns rules, spawn table, scoring, booster costs and balance. Reviews ARCHITECTURE.md for rule accuracy. Writes the acceptance test list that QA uses. Tools: Read, Write, Edit, Glob, Grep.

**Senior Graphic Designer** (senior-graphic-designer). Owns the visual identity. Produces the three design directions, then docs/DESIGN_SYSTEM.md (color tokens, tile color ramp for every value from 2 to at least 131072, type scale, spacing, corner radii, motion timing and easing). Writes briefs for the two artists and reviews everything they produce. Final say on visual quality below Bart. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Tile and Board Artist** (tile-board-artist). Builds the tile and board visuals in code: tile shapes, the color ramp, number rendering, the chain path line, merge and spawn effects. Builds the skin system as data (one Resource per skin) that the developers read from. Tools: Read, Write, Edit, Glob, Grep, Bash.

**UI and Motion Artist** (ui-motion-artist). Builds the Godot Theme for menus, HUD, buttons and dialogs, draws booster and settings icons in code, and builds shared animation helpers (easing curves, transition timings) from the design system. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Core Logic Developer** (core-logic-dev). Pure game rules with no UI and no Node dependencies: board model, chain validation, merge math, gravity, spawning with a seedable RNG, game-over detection, score. Unit tests for all of it. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Board and Input Developer** (board-input-dev). The board scene: touch and mouse drag, eight-direction adjacency hit testing, chain preview, applying core results to the view, animation sequencing, scaling to screen size and safe area. Uses the artists' visuals; never hardcodes colors or sizes. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Boosters Developer** (boosters-dev). Booster logic and flow: affordability checks, cost deduction, targeting mode and cancel, the Undo snapshot, booster offers at game over. Unit tests for all booster logic. Tools: Read, Write, Edit, Glob, Grep, Bash.

**UI Systems Developer** (ui-systems-dev). HUD (score, best, booster bar), main menu, pause, game over, settings (sound toggle, skin picker), save and load, Android lifecycle (save on pause or focus loss, back button). Tools: Read, Write, Edit, Glob, Grep, Bash.

**Audio Developer** (audio-dev). The synthesized click, a small audio service the game calls, and the persisted toggle hook. Small job; finish it fully. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Platform Developer** (platform-dev). project.godot settings, Android export preset, debug keystore setup per current Godot docs, .gitignore, build and install scripts, README build steps. Verifies the release preset requests no permissions. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Functional Reviewer** (qa-reviewer). Runs all tests, walks the GDD acceptance list, hunts edge cases (full board, no moves, booster at zero score, Undo after Shuffle, resume mid-targeting, rotation lock, tiny and huge screens), and checks performance. Writes reports only to docs/reviews/. Does not fix code. Tools: Read, Glob, Grep, Bash, Write.

**Security Reviewer** (security-reviewer). Reviews the save system (JSON only via the JSON class; never str_to_var, bytes_to_var or any loader that can instantiate objects from file data; full validation of loaded data with safe fallback; atomic writes), Android manifest and permissions, secrets and keystores kept out of git, no network code anywhere, and that nothing third party entered the repo. Writes reports only to docs/reviews/. Does not fix code. Tools: Read, Glob, Grep, Bash, Write.

## 6. Repo layout and file ownership

```
sumup/
  CLAUDE.md              standing rules for every session (you)
  README.md              build and run steps (platform-dev)
  project.godot          (platform-dev)
  export_presets.cfg     (platform-dev)
  docs/
    GDD.md               (lead-game-designer)
    ARCHITECTURE.md      (you)
    DESIGN_SYSTEM.md     (senior-graphic-designer)
    ASSETS.md            log proving every asset is made in code (senior-graphic-designer)
    design/              direction screenshots (senior-graphic-designer)
    reviews/             (qa-reviewer, security-reviewer)
  src/
    core/                (core-logic-dev)
    board/               (board-input-dev)
    boosters/            (boosters-dev)
    ui/                  (ui-systems-dev)
    save/                (ui-systems-dev)
    audio/               (audio-dev)
    skins/               (tile-board-artist)
    design/              theme, icons, motion helpers (ui-motion-artist)
  scenes/                each scene owned by the dev of the matching src/ folder
  tests/                 run_tests.gd plus one folder per src/ area, owned by that area's dev
  tools/                 contrast checker, screenshot capture (senior-graphic-designer)
```

Tests use a small headless runner we write ourselves (tests/run_tests.gd, extending SceneTree). No test framework addon.

## 7. Rules for running the team

- Before parallel development starts, write docs/ARCHITECTURE.md: the data model, every class each area exposes, every signal with its arguments, and how skins and the theme are read. Agents build against this contract. If an agent needs the contract changed, it asks you; it does not change another area's code.
- Each agent edits only the files it owns. If two agents need the same file, you split the file or do the integration edit yourself.
- Agents do not commit. You commit after each integration step, with a clear message, once tests pass.
- Every agent brief you write states the task, the files it may touch, the docs it must read, and how it will prove the work is done (a test, a screenshot, a command output).
- Keep it simple. No features, settings or abstractions beyond this brief. If an agent proposes extra scope, bring it to Bart as a suggestion.
- Priority order for all decisions and fixes: security and bugs first, then fun and polish.
- No em dashes and no double hyphens in any prose: docs, UI text, commit messages. Write plainly, like a person.
- Use the Claude Code task list so Bart can see progress at a glance. At the end of each phase, post a short status: what is done, what was verified, what is next, anything blocking.

## 8. Phases

### Phase 0: Environment and scaffold

- Check for git, gh (logged in as bartbasi), the Godot 4 console executable, Godot export templates, the Android SDK with adb, and the JDK version the current Godot Android export docs require. If anything is missing, stop and give Bart exact install steps. Do not install software without asking.
- Create the folder layout, CLAUDE.md (sections 2, 6 and 7 condensed), .gitignore (.godot/, build/, *.keystore, *.jks, and any file Godot uses for export credentials), the agent files from section 5, and an empty Godot project that opens and runs.
- git init locally. Create nothing on GitHub yet.
- Verify: `godot --headless --path . --quit` exits cleanly. The test runner runs and reports zero tests.

### Phase 1: Rules and design directions (in parallel)

- Lead Game Designer writes docs/GDD.md, including every "Designer decides" item and the acceptance test list.
- Senior Graphic Designer plans three distinct dark, bold directions and briefs the two artists. Each direction is built as real Godot scenes, not pictures, showing four screens: a mid-game board with a chain being dragged, the booster bar with one booster in targeting mode, game over, and settings.
- A capture scene in tools/ renders each screen at 1080 by 2400 to PNG in docs/design/. The contrast script in tools/ checks every tile and text color pair and must pass.
- Each direction gets a one-page write-up: name, concept in a few sentences, palette tokens with hex values, tile ramp, type, motion idea.
- Team review: the senior designer, the lead game designer and you each rank the three directions with short reasons. Combine these into a recommendation.
- Verify: GDD has every decision with examples. Twelve screenshots exist. Contrast script passes for all three directions.

**HARD STOP 1.** Show Bart the GDD summary, the twelve screenshots, the team ranking, and the font comparison. Bart approves the rules, picks a direction, and decides the font question. Also ask Bart whether the two unpicked directions should become alternate built-in skins. Do not start Phase 2 until he answers.

### Phase 2: Contract and design system

- You write docs/ARCHITECTURE.md. The lead game designer checks it against the GDD.
- The senior designer turns the chosen direction into docs/DESIGN_SYSTEM.md and the skin Resources.
- Verify: both docs exist and every area in section 6 has its interface listed.

**HARD STOP 2 (first push).** Ask Bart before creating the GitHub repo or pushing. When approved: `gh repo create bartbasi/sumup --private`, then push.

### Phase 3: Build (developers and artists in parallel)

- Launch the five developers and the two artists against the contract.
- Core logic and boosters reach full unit test coverage of the GDD rules before you integrate them.
- Verify: all tests pass headless: `godot --headless --path . --script res://tests/run_tests.gd`.

### Phase 4: Integration, playable on Windows

- Wire everything together. Play it in the editor on Windows with a mouse.
- Verify: a full run from new game to game over works, every booster works, the sound toggle works, the skin switch works, and quitting and reopening resumes the run.

### Phase 5: Android

- Platform developer builds a debug APK: `godot --headless --path . --export-debug "Android" build/sumup-debug.apk`.
- Give Bart the steps to enable USB debugging on his phone, then install with `adb install -r build/sumup-debug.apk`.
- Verify: Bart confirms it installs and plays on his phone. Check frame rate, touch feel, safe areas, back button, and resume after the app is swiped away.

### Phase 6: Functional and security review

- Launch qa-reviewer and security-reviewer in parallel. Each writes a report in docs/reviews/ with findings rated Critical, High, Medium or Low, each with steps to reproduce or the file and line.
- Assign every Critical and High finding to the owning agent. Re-review each fix. Repeat until no Critical or High remain.
- Give Bart the Medium and Low list so he can decide what to fix now.

## 9. Definition of done for v1

- Debug APK installs and runs on Bart's Android phone, portrait, smooth.
- Endless mode follows the approved GDD exactly.
- All five boosters work, are paid from score, and disable when unaffordable.
- Built-in skins switch live; the dark, bold default is the approved direction.
- The click sound is synthesized in code and the toggle persists.
- The run, settings, Best Score and Best Tile survive closing the app.
- All unit tests pass headless. Contrast script passes.
- QA and security reports show no open Critical or High findings.
- docs/ASSETS.md shows every visual and sound is made in code, with no third-party files.
- Release export preset requests no Android permissions.

## 10. Out of scope for v1

Level goals, player-made skins, any file import, online features of any kind, ads, in-app purchases, iOS, Windows and Linux builds, store listings, release signing keys, and any Play Console work. Store-related work needs Bart's explicit go-ahead.
