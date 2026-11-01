# SumUp: standing rules

SumUp is a number merge puzzle game (same core mechanic as "2248") for Android, built in Godot 4. Bart Basi owns the project. The main Claude Code session is the Development Manager (DM): it plans, launches every agent, integrates, commits, and is the only one who talks to Bart. The full kickoff brief is in docs/BRIEF.md. Read it before starting any phase.

## Fixed decisions (ask Bart before revisiting any of these)

- Engine: Godot 4.7.2 stable (`4.7.2.stable.official.ed1daf0bf`), Compatibility renderer.
- Language: GDScript, statically typed everywhere (typed variables, parameters and return values). No C#, no GDExtension. project.godot treats untyped declarations as errors.
- Platform for v1: Android, portrait only. Develop and iterate in the Godot editor on Windows.
- Repo: github.com/bartbasi/sumup, public (see 2026-10-23 below). Only the DM pushes.
- Assets: nothing paid, nothing third party. Every visual and every sound is made in code (StyleBoxFlat, Theme resources, `_draw()`, shaders, Tweens, AudioStreamWAV filled by code). No image files, no audio files, no asset store downloads, no addons. The exceptions are the Outfit font and the GPL text in COPYING (see Bart's decisions below).
- License: GNU GPL version 3 with the section 7 terms in NOTICE (see Bart's decisions below). COPYING is the official text, byte for byte (MD5 1ebbd3e34237af26da5dc08a4e440464). Never edit it.
- Network: none. No accounts, ads, analytics or leaderboards. Release builds request no Android permissions. The one exception is the Buy Me a Coffee button (2026-10-17), which hands a fixed address to the phone's browser; the game itself never sends or receives anything.
- Skins: built in only for v1. No import of any kind.
- Level goals: not in v1. Keep game rules separate from UI so they can be added later, but build nothing for them.
- Boosters are paid from the current run's score. Score can never go below zero.
- Out of scope: level goals, player-made skins, file import, anything online, ads, in-app purchases, iOS, Windows and Linux builds, release signing keys, Play Console work. Store listing material is in scope since 2026-10-17 (see below).

## Ownership

Each agent edits only what it owns, plus any path its task brief from the DM explicitly grants for that task. Godot's `.uid` files belong to whoever owns the file next to them.

| Path | Owner |
|---|---|
| CLAUDE.md, docs/BRIEF.md, docs/ARCHITECTURE.md, .claude/agents/, .gitattributes, COPYING, NOTICE | DM |
| scenes/main.tscn, tests/run_tests.gd, tests/base_test.gd | DM |
| README.md, project.godot, export_presets.cfg, .gitignore, scripts/ (build and install scripts) | platform-dev |
| docs/GDD.md (rules, balance, acceptance test list) | lead-game-designer |
| docs/DESIGN_SYSTEM.md, docs/ASSETS.md, docs/design/, tools/, launcher/ (written only by tools/launcher_icon.gd) | senior-graphic-designer |
| docs/store/ (text: privacy policy, listing) | DM |
| docs/store/graphics/ | senior-graphic-designer |
| docs/reviews/qa-*.md | qa-reviewer |
| docs/reviews/security-*.md | security-reviewer |
| src/core/, tests/core/ | core-logic-dev |
| src/board/, scenes/board/, tests/board/ | board-input-dev |
| src/boosters/, scenes/boosters/, tests/boosters/ | boosters-dev |
| src/ui/, src/save/, scenes/ui/, tests/ui/, tests/save/ | ui-systems-dev |
| src/audio/, scenes/audio/, tests/audio/ | audio-dev |
| src/skins/, scenes/skins/, tests/skins/ | tile-board-artist |
| src/design/, scenes/design/, tests/design/ | ui-motion-artist |

Autoload and input map entries in project.godot are added by the DM during integration, so two agents never edit that file at once.

## Decisions from Bart since the brief

- 2026-10-10: Skin Resources. The senior-graphic-designer specifies every value in docs/DESIGN_SYSTEM.md. The tile-board-artist writes the Resource files in src/skins/. The senior-graphic-designer reviews them.
- 2026-10-10: Android launcher icon. It is drawn in code by a tool script in tools/ that saves the icon image the export uses, and it is logged in docs/ASSETS.md. No hand made or downloaded image.
- 2026-10-10: Commits are authored as the bartbasi GitHub account (set in this repo's git config, not globally).
- 2026-10-10, Hard Stop 1: Gumdrop is the default look. Slate and Nova ship as built in skins the player can switch to in Settings.
- 2026-10-10: A skin switches the whole look: tiles, colors, chain line, effects, motion, HUD, booster bar, icons, buttons, background and font, so the play screen matches that direction's Phase 1 screens. Menus and dialogs (out of moves offer, end of run, settings, pause, main menu) keep one shared arrangement, drawn in each skin's style.
- 2026-10-10, Hard Stop 1: Fonts. Gumdrop and Nova use Outfit (SIL Open Font License 1.1). Slate uses the system font (Roboto on Android). `Outfit[wght].ttf` and its `OFL.txt` are the only third party files allowed in the repo, unmodified, side by side, and logged in docs/ASSETS.md.
- 2026-10-10, Hard Stop 1: Best Score updates live (GDD D-16). All GDD rules are approved as recommended.
- 2026-10-10, Hard Stop 1: Three additions to v1 scope: small tiles are cleared automatically as the game moves up, as in 2248; tiles that could join next are highlighted while dragging; the end of run screen shows this run's highest tile. Not added: a confirm step before Shuffle and Undo.
- 2026-10-10: Bart approved creating the private GitHub repo and pushing (Hard Stop 2 cleared early). It was created as bartbasi/numbersgame and renamed bartbasi/sumup on 2026-10-13.
- 2026-10-11: Bart approved the rebuilt tile colors (DESIGN_SYSTEM.md) and the working copy in DESIGN_SYSTEM.md 7.8.
- 2026-10-11: Reopening the app with a saved run goes straight back into the run. The main menu shows only at first launch, when no valid run is saved, and after a run ends. (Replaced by the 2026-10-14 splash screen decision.)
- 2026-10-13: Three additions to v1 scope.
  - How to play (now the Info guide, 2026-10-14): a button on the main menu and in Pause opens a screen explaining how the game works and how points are scored, in short sections, each with a small row of real tiles drawn in the current skin. It opens only when tapped, never by itself.
  - About: a row in Settings opens an About screen: what the game is, the version, made by Bart Basi, fully offline with no data collected, and the licenses (the game's own, the Godot engine's MIT notice and its parts, the Outfit font's OFL).
  - Stars: a star each time a low number is removed for the first time in a run (the window floor reaching a new level, from the 2K tile on). Hammer and Undo can never earn a star twice. Every 3 stars give one free booster: the player's next booster costs nothing. The HUD shows the stars.
- 2026-10-13: License. The game is GNU GPL version 3 with two additional terms under section 7: 7(b) every copy and every modified version keeps the attribution "Copyright 2026 Bart Basi" (changed to "Copyright 2026 Play, Inc." on 2026-10-17) in its About screen; 7(c) modified versions must be marked as changed from the original. The full GPL text ships in the app and is readable in the About screen. The GPL text is an approved third party file, like the font.
- 2026-10-13: The game is renamed from numbersgame to SumUp, everywhere in the repo and on GitHub (bartbasi/sumup). The Android package is com.bartbasi.sumup. Dated review reports in docs/reviews/ keep the old name, as records of what was tested. The local folder on this machine stays `C:\bart\numbergame`.
- 2026-10-13, Phase 6: of the three Low security findings, Bart chose to fix SEC-01 (a board whose only pairs overflow 64 bits counts as a move) now. SEC-02 (no flush before the save rename, no profile backup) and SEC-03 (the Windows account name in local paths) stay open for later.
- 2026-10-13, Phase 6: Bart chose to fix all eight QA findings in docs/reviews/qa-2026-10-13.md now (QA6-01 to QA6-08), including QA6-06 (the kill window after a commit) and QA6-07 (Windows only save after a failed rename).
- 2026-10-14: Splash screen, replacing the main menu. It shows every time the app opens (this replaces the 2026-10-11 rule), on first launch and after a run ends. Three buttons: PLAY continues the saved run, or starts a new one when none is saved; INFO opens one full guide to the game (scoring, chains, clearing, stars, free boosters, each booster, out of moves, records), which replaces How to play everywhere, Pause included; ABOUT opens the About screen, which also shows "github.com/bartbasi/sumup" as plain text, not a link. No mockups: Bart reviews the build on his phone.
- 2026-10-15: Bart tested the splash build on his Fold5 (splash, Info, About, home and back, swipe away) and approved it fully as built, including the button labels "Play", "Info" and "About" in normal case. SEC-04 and SEC-05 were fixed overnight under the security first rule.
- 2026-10-17: Copyright. Bart incorporated as Play, Inc. The attribution everywhere (NOTICE, README, About, the 7(b) term) becomes "Copyright 2026 Play, Inc." "Made by Bart Basi" stays in About. Bart signed the copyright assignment to Play, Inc. the same day.
- 2026-10-17: Buy Me a Coffee, in the app for everyone (Bart accepted the Google Play payments policy risk outside the US after the DM flagged it). A small, quiet "Buy me a coffee" button at the bottom of the splash, below Play, Info and About, and a support block with the same button in About. Tapping opens https://buymeacoffee.com/playinc in the phone's browser; nothing else in the app touches the network. The GitHub address stays plain text. The link also goes in README; the store listing is Bart's. About text (Bart chose this wording): "SumUp is free, with no ads and no tracking, and it always will be. If you'd like to support more games like it, you can buy me a coffee. Never expected, always appreciated."
- 2026-10-17: Bart tested the coffee button on his Fold5 ("worked great") and approved the "Supporting SumUp" heading and the added Offline sentence as built.
- 2026-10-17: Store material, added to scope at Bart's request: a privacy policy page, the Play Store listing text and the store graphics (icon, feature graphic, screenshots), all in docs/store/. The DM writes the text; the senior-graphic-designer makes the graphics in code with tools/. Play Console work itself, release signing and publishing still need Bart's go ahead. The listing waits on a DUNS number for Play, Inc.
- 2026-10-18: License terms mirror Updraft. NOTICE now credits "Designed and written by Bart Basi, with assistance from Claude." and has three section 7 terms: 7(b) any work based on SumUp keeps "Based on SumUp, designed and written by Bart Basi, with assistance from Claude. Copyright 2026 Play, Inc." in its source (NOTICE) and in its user interface legal notices; 7(c) and 7(d) modified versions are marked, not presented as the original, and may not use the names Play, Inc. or Bart Basi to promote them; 7(c) and 7(e) no trademark rights to the name SumUp or its icon. This replaces the two 2026-10-13 terms. The game's own About keeps "Made by Bart Basi" and "Copyright 2026 Play, Inc.".
- 2026-10-21: Unlimited score and tiles. Bart reached the 64 bit score limit in real play (score 9,221,253,119,629,040,934 on a board of 2^56 tiles), so every chain was refused. Bart approved: the score is kept exactly with no 64 bit limit, and tiles keep doubling past 2^62. A far ceiling stays only to refuse tampered saves (about 2^65535 for tiles, and a score of about that length). Long scores show at most 10 digits plus a letter for the dropped groups of three (9,221,253,119B). Tile labels keep their 1024 steps and continue past T (2^56 reads 64Q); past the named units a systematic letter scheme (aa, ab, and so on) takes over. Bart's current run and records must carry over unchanged.
- 2026-10-21: Bart asked for a "Buy me a coffee" button on the play screen too, placed so it never obstructs play. The senior-graphic-designer places it per skin, out of reach of board drags and the booster bar, small and quiet like the splash one, and says what happens on phones with no spare room. It replaces the GDD rule that the button shows only on the splash and in About. Built after the unlimited numbers work, in the same install. Bart also approved a quiet "Buy me a coffee" row in the Pause panel (2026-10-21), so it is reachable mid run on every phone.
- 2026-10-21: Bart chose to fix all six QA Lows (QA21-01 to 06). Slate keeps the plural "s" lowercase after a tile label ("NO MORE 8Qs"), and the play screen coffee button takes a stacked form in the side gutter. Bart checked the stacked button on his unfolded Fold5 and approved it as built ("works great").
- 2026-10-23: The repo is public, and Play, Inc. apps are public by default. Bart confirmed that github.com/bartbasi/sumup is public (GitHub already showed it as public). This replaces "private" in the brief (docs/BRIEF.md keeps its original wording, as a record). Making anything else public, such as a new repo or GitHub Pages, still needs Bart's go ahead.
- 2026-10-23: Credits fixed, as the DM recommended. About's Licenses text no longer counts the terms (it said "two" after NOTICE grew to three): "...version 3, with additional terms (see the SumUp license below). Any work based on SumUp keeps its attribution, and changed versions are marked as changed. SumUp comes with no warranty." The row reads "GNU GPL version 3, added terms". The libraries the Android build adds (AndroidX, the Kotlin standard library, kotlinx.coroutines, JetBrains Java Annotations, all Apache 2.0, and LLVM libc++, Apache 2.0 with LLVM exceptions) are credited in NOTICE, README and the Godot Engine license view in About, under "Android libraries". Check the APK's contents against these credits before every release.
- 2026-10-13: Bart approved the About and license wording in DESIGN_SYSTEM.md 7.10 as written. On his Fold5 cover screen the camera hole does not cover the score (QA's Q2), so nothing changes for it.

## Rules for every session and agent

- docs/ARCHITECTURE.md (written in Phase 2) is the contract. Build against it. If you need the contract or another area's code changed, stop and ask the DM. Never edit another area's files.
- Agents never commit. The DM commits after each integration step, once tests pass.
- Keep it simple. No features, settings or abstractions beyond the brief. Extra ideas go to the DM as suggestions for Bart.
- Priority for every decision and fix: security and bugs first, then fun and polish.
- No em dashes and no double hyphens in prose: docs, UI text, code comments, commit messages. Write plainly, like a person. Command line flags inside code formatting are fine.
- If anything is unclear, conflicts, or would force a guess, stop and ask. Do not pick an interpretation silently.
- Hard stops: Hard Stop 1 and Hard Stop 2 are both cleared. Ask Bart before any store work, release signing, or anything else outside the brief.
- Every agent finishes with a short report: what changed (file list), how it was proven (command and result, screenshot path, or test names), open questions, and any contract change requests.

## Commands

Run Godot commands from the repo root in the Bash tool.

```bash
godot --headless --path . --import                            # build the class cache (fresh clone, or after adding a class_name)
godot --headless --path . --quit                              # project opens and runs
godot --headless --path . --script res://tests/run_tests.gd   # all tests; exit code 0 means every test passed
```

## Writing tests

- Put tests in `tests/<area>/test_*.gd`. Each file starts with `extends "res://tests/base_test.gd"`.
- Every method named `test_*` runs on a fresh instance. Optional hooks: `before_each()`, `after_each()`.
- Helpers: `assert_true`, `assert_false`, `assert_eq`, `assert_ne`, `assert_null`, `assert_not_null`, `assert_near`, `fail`.
- A script error raised while a test runs (a null access, for example) counts as a failure.
- Tests are synchronous. Seed every RandomNumberGenerator so results repeat.

## Environment notes (this Windows machine)

- `godot` on PATH is a WinGet link to the main Godot 4.7.2 exe. It works from Bash with real exit codes. In PowerShell the same exe does not wait or return an exit code unless its output is piped, so prefer Bash.
- Do not use `godot_console.exe`. It fails with "CreateProcess failed, error 193" because a stray installer log file directly in `C:\Users` (named after the first word of the user folder's name) breaks the wrapper's unquoted path. Bart wants that file left alone: never move, rename or delete it.
- Paths in committed files: never write the Windows account name. Write `%TEMP%`, `%APPDATA%` or `%USERPROFILE%` style placeholders instead (SEC-03).
- Other projects run Godot on this machine at the same time (Bart's Updraft project, from another Claude session, uses the same exe name). Never end Godot processes by name (`taskkill /IM`, `pkill godot`, `Stop-Process -Name`). End only a process you started, by its own PID, and wrap long Godot runs in `timeout` so a hang ends by itself.
- Android SDK: `C:\Android\Sdk`. adb is at `C:\Android\Sdk\platform-tools\adb.exe` and is not on PATH. JDK 17 (Temurin) is on PATH. The Android debug keystore lives outside the repo in Godot's editor settings folder.
- docs/ has a `.gdignore`, so Godot never imports the design screenshots into the game.
- Pushing (DM only): git's credential manager has no GitHub login here, so push through the gh login without changing git config: `git -c credential.helper= -c "credential.helper=!gh auth git-credential" push origin main`.
- Public classes in src/ use `class_name` (names fixed in docs/ARCHITECTURE.md). After adding one, run `godot --headless --path . --import`. If several agents import at once and you then see "could not find type" errors, import again. tools/ code uses preload and adds no class names.
