# Forkline: standing rules

Forkline is an original tower defense game for Android phones, built in Godot 4.7.2: hand-built maps whose roads fork, plus gates the player places to steer enemies. Bart Basi owns the project. The main Claude Code session is the Development Manager (DM): it plans, launches every agent, integrates, commits, and is the only one who talks to Bart. Company rules come from C:\bart\playbook\PLAYINC_PLAYBOOK.md (version 1); the decisions that apply are copied below so this file stands on its own. The full kickoff brief is in docs/BRIEF.md. Read it before starting any phase.

## Fixed decisions (ask Bart before revisiting any of these)

- Engine: Godot 4.7.2 stable (`4.7.2.stable.official.ed1daf0bf`), the standard build, not .NET. Compatibility renderer (2D).
- Language: GDScript, statically typed everywhere (typed variables, parameters and return values). No C#, no GDExtension, no addons. project.godot treats untyped declarations as errors.
- Platform for v1: Android first. Develop and iterate in the Godot editor on Windows. iOS, Windows and Linux builds are out of scope.
- Orientation: portrait by default. On a foldable's inner screen, or any window close to square or wider than tall, the game switches to a landscape layout on its own, with no setting. Layout follows window size, not an orientation lock. The approach is written in docs/ARCHITECTURE.md before UI work starts.
- Name: Forkline. Store title "Forkline: Tower Defense". Folder C:\bart\forkline. Repo github.com/bartbasi/forkline, public by default once Bart approves the first push. Android package `io.github.bartbasi.forkline`, which can never change once the app is on Play.
- Copyright line, exactly: `Copyright 2026 Play, Inc.` In NOTICE, README, About and anywhere else a copyright line shows. About also says "Made by Bart Basi". NOTICE and the attribution term say "Designed and written by Bart Basi, with assistance from Claude."
- License: GNU GPL version 3 with the three section 7 terms in NOTICE (playbook template 16.1). LICENSE is the official gnu.org text, byte for byte (MD5 `1ebbd3e34237af26da5dc08a4e440464`). Never edit it. UI copy never counts the terms: say "with additional terms".
- Source file header on every source file, checked by a test:
  `# Forkline. Copyright 2026 Play, Inc.`
  `# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.`
- Network: none. No network code anywhere. Release builds request no Android permissions, not even INTERNET. No ads, analytics, tracking, accounts, leaderboards, purchases or real money. Everything is earned by playing.
- The only exits from the app hand a fixed constant address to another app on the phone: Buy me a coffee (`https://buymeacoffee.com/playinc`, browser), the source code link in About (browser), and Send feedback in About (email app, to bartbasi@gmail.com). The app itself sends nothing. Tests replace the opener so nothing real opens.
- Assets: every visual, effect, sound and piece of music is made in code. No image, audio or asset store files. Generated outputs (launcher icons, store graphics) are drawn by tool scripts and committed. Approved third party files: the GPL text, and the Outfit font with its OFL.txt (picked at hard stop A). Anything else: ask first. Every asset is logged in docs/ASSETS.md.
- No other game's name appears anywhere players can see: UI, listing, marketing. The look copies no existing game's characters, layouts, palettes or tower designs.
- Content stays non-gory so the rating stays Everyone. Store target audience 13 and over.
- Models: Claude Opus 5.5 (`claude-opus-5-5`) and Claude Sonnet 5.5 (`claude-sonnet-5-5`) only. Effort levels high and max only. Each agent's model and effort are set in its file in .claude/agents/.
- Out of scope: networking of any kind, cloud saves, iOS, Windows and Linux builds, player-made skins or any file import, a look picker, release signing and Play Console work (ask first), and anything not in docs/BRIEF.md.

## Ownership

Each agent edits only what it owns, plus any path its task brief from the DM explicitly grants for that task. Godot's `.uid` and `.import` files belong to whoever owns the file next to them. A path not in this table belongs to the DM until the DM assigns it in a task brief and records it here.

| Path | Owner |
|---|---|
| CLAUDE.md, docs/BRIEF.md, docs/ASSETS.md, .claude/agents/, project.godot, scenes/main.tscn, LICENSE, NOTICE, README.md, .gitignore, .gitattributes, docs/.gdignore, tests/run_tests.gd, tests/base_test.gd, tests/project/, git | DM |
| docs/design/, data/stats/ | game-designer |
| docs/ARCHITECTURE.md | architect |
| docs/art/, src/theme/, tools/icon/, icons/, tests/theme/ | art-director |
| src/sim/, tests/sim/, src/save/, tests/save/ | sim-engineer |
| data/levels/, data/segments/, tests/levels/ | level-designer |
| tools/balance/, docs/balance/ | balance-analyst |
| src/run/, data/cards/, data/runs/, tests/run/ | roguelite-engineer |
| src/ui/ (including the app glue in src/ui/app.gd), scenes/ui/, tests/ui/ | ui-engineer |
| src/render/, shaders/, tests/render/, docs/render/ | render-engineer |
| src/audio/, tests/audio/ | audio-engineer |
| scripts/, export_presets.cfg, tools/store/, docs/store/, docs/release.md | release-engineer |
| docs/reviews/qa-*.md | qa-reviewer |
| docs/reviews/security-*.md | security-reviewer |

Autoload and input map entries in project.godot are added by the DM during integration, so two agents never edit that file at once. The contract plans no autoloads. scenes/main.tscn only instances scenes/ui/app.tscn.

## Decisions from Bart

- 2026-10-23: Path design is hybrid: hand-built maps with forks, plus gates the player places to close branches.
- 2026-10-23: Version 1 includes the campaign with stars, Twist versions, the roguelite mode and the daily challenge. No networking of any kind.
- 2026-10-23: Portrait by default, landscape automatically on foldable inner screens.
- 2026-10-23: Theme is cozy storybook fantasy: a warm hillside village at dusk, towers as lantern-lit watch posts and cottages, enemies as mischievous night creatures that puff into sparkles, no blood (brief section 4).
- 2026-10-23: Name Forkline. Store title "Forkline: Tower Defense". Package name `io.github.bartbasi.forkline`.
- 2026-10-23: "Play" on the front door opens a mode screen with Campaign, Roguelite and Daily. When a level or run is saved, a Continue card sits at the top of that screen and resumes it in one tap. This replaces the playbook's "Play continues the saved session" default.
- 2026-10-23: Optional Relaxed difficulty next to Normal (the default), picked per level or per run. Relaxed gives more lives and more starting gold and changes nothing else. A Relaxed win earns one star; the second and third stars need Normal. The daily challenge is always Normal.
- 2026-10-23: About has a tappable source code link and a Send feedback button (playbook 6.3). Pause has a quiet Buy me a coffee row. The coffee button is also at the bottom of the front door and in About's "Supporting Forkline" section (playbook defaults). It is not on the play screen. The privacy policy names all three outbound buttons.
- 2026-10-23: Models are Claude Opus 5.5 and Claude Sonnet 5.5 only, at effort high or max only, as in the brief's section 7.1 table.
- 2026-10-23: Everything else follows the playbook defaults: Godot 4.7.2, GDScript statically typed, Android first, assets made in code, GPL v3 with the Play, Inc. terms.
- 2026-10-23: Paths the brief gives no owner (the main scene and app glue, save file reading and writing for progress and settings, docs/ASSETS.md, the launcher icon tool, tower and enemy stat data) stay with the DM until the architect names an owner in the contract. The DM then records them in the ownership table.
- 2026-10-23: Owners for the open paths, from the architect's proposal: data/stats/ to the game designer; data/runs/ to the roguelite engineer; tools/icon/, icons/ and tests/theme/ to the art director; tests/render/ and tests/audio/ to those areas; the app glue to the ui-engineer. One change by the DM: src/save/ and tests/save/ go to the sim engineer (Opus), not the roguelite engineer, because saves are the most security sensitive code and the sim engineer already owns sim state saving. docs/ASSETS.md stays with the DM.
- 2026-10-23 (DM, under Bart's go ahead): In the APK the Outfit font ships as Godot's imported font resource, which stores the font's bytes compressed without loss (the engine restores them exactly), with OFL.txt beside it as a plain file. The raw .ttf is not added a second time. This matches SumUp. In the repo both files stay unmodified, side by side, in src/theme/fonts/.
- 2026-10-23 (DM): The theme slice in prototypes/theme/ stays until the audio engineer has carried its music and sounds into src/audio/ in phase 5 and Bart has had the chance to see it on his Fold5. Then the DM deletes it.
- 2026-10-23: The architect gets WebSearch and WebFetch, for research only (Android large-screen behavior). The game itself has no network code.
- 2026-10-23: Bart approved the kickoff and told the DM to go ahead with what it thinks best. Where the brief is silent, follow the playbook.
- 2026-10-23, hard stop A: Bart approved everything as the DM recommended:
  - The look: the cozy storybook theme slice (docs/art/THEME.md), judged from the screenshots. Bart still sees it on his Fold5 when the phone is connected.
  - Font: Outfit everywhere (SIL Open Font License 1.1). `Outfit[wght].ttf` and its `OFL.txt` ship unmodified, side by side, and are credited in NOTICE, README and About.
  - Names: the slice and RULES.md named towers and creatures differently. In phase 4 the game designer and art director agree on one set, keeping the jobs in RULES.md, and match the silhouettes to it. Bart sees the final list before any code uses it.
  - Rules: docs/design/RULES.md is approved as written, including section 19.1: level 1-1 opens with two towers so the brief's "no single tower earns three stars alone" check can pass on every level; the roguelite and daily open at 12 stars and use every tower and creature, with an info card the first time each appears; star rules, Relaxed numbers (40 lives, 1.5 times starting gold), the Twist list, the campaign plan, the economy (70% refund for anything not bought in the current build phase), the Gatecrasher rules, route lines shown through the whole build phase, every level starting at 1x, attacks that land instantly, and at most 2 waves on the map at once.
  - No mid-wave gate switch. Speed is not remembered between levels. No "damage dealt" readout in version 1.
  - Resume: killing the app and reopening returns to the exact moment (brief 3.10).
  - Maps are at most 7 columns by 8 to 13 rows, so map cells stay 48 dp on the Fold5 cover screen.
  - Saved games: one per mode (campaign level, roguelite run, daily), so one never ends another. The Continue card resumes the most recent.
  - No rotation on the unfolded phone: the portrait lock stays, and the landscape layout comes from the window shape.
  - Folding or unfolding mid-wave pauses the game.
  - The level card does not remember Relaxed. Normal is always the default.
- 2026-10-24, hard stop B: Bart played region 1 on his Fold5, said "so far so good", approved everything and asked the DM to continue. Approved with it, as the DM recommended:
  - The theme slice on the phone. The DM deleted prototypes/theme/ the same day.
  - The name list in docs/art/NAMES.md.
  - Level 1-5 is renamed "Wings at Dusk".
  - The region 1 tuning (docs/design/TUNING_R1.md), including the new third stars and a 1000 health Grumblesack.
  - A third star of "no tower above tier 1" reads "Upgrade no towers." on cards and screens.
  - Speed resets to 1x after Continue.
  - The fun review's after-playtest list (docs/design/FUN_REVIEW_R1.md) goes ahead, except item 7 (a "packed" mark in the wave preview), which Bart was not asked about and which goes beyond brief 3.5.
- 2026-10-25: Bart chose the run length: RULES 14.1 becomes "about 12 to 16 minutes at 1x, about 15 to 20 of real play with card picks". Runs stay as tuned (docs/design/TUNING_RUNS.md).
- 2026-10-25, hard stop C: Bart searched "Forkline" in the stores and app repositories and found no one using it. He approved creating github.com/bartbasi/forkline as a public repo and the first push, and asked the DM to keep pushing as verified work lands (each push only after the full suite passes on a clean copy). His friends test from the repo with debug builds; no release signing yet.
- 2026-10-26: Bart: "always publish a binary to github when we're building open source software". The DM attaches the APK to a GitHub release at each verified milestone (full suite passed on a clean copy, scripts/check_apk.sh passed), tagged at that commit. Until release signing is approved these are debug builds, and the release notes say so.
- 2026-10-26: Bart approved GitHub Pages for the privacy policy. The DM publishes docs/store/site/ to the gh-pages branch (docs/release.md).
- 2026-10-26: Bart asked for clearer shot effects on every tower, the catapult first. Done in a68c16c and approved on his Fold5.
- 2026-10-27: Bart approved the DM's recommendations: Play App Signing with an upload key that the release engineer creates and that stays outside the repo (Bart keeps a backup); the app bundle (AAB) build that Play requires; answering the content rating questionnaire with mild fantasy violence; keeping the Buy me a coffee row in store screenshot 5. Play Console itself still waits for the DUNS number.
- 2026-10-27: Bart asked for 4 more campaign regions of 6 levels each, with more complex pathing, new creatures, new towers and new features. This extends brief 3.6 (about 24 levels in 4 regions) to 48 levels in 8 regions. He chose: version 1 launches on Play with all 48 levels, not before; the same pace as regions 1 to 4 (about 4 new towers, about 8 new creatures, 4 bosses, one new map feature per region); new towers and creatures join the roguelite and daily once the player has unlocked them in the campaign. Maps keep the 7 column limit. The game designer writes docs/design/EXPANSION.md first, and Bart approves it, names included, before any code uses it.
- 2026-10-27: Bart approved docs/design/EXPANSION.md (as revised after the architect's review) and docs/art/EXPANSION_LOOK.md as shown, including Snoozer renamed Yawner and the art director's silhouette and color changes. Numbers stay starting targets until each region's balance pass. The daily follows content tiers: players at the same stage share the same daily, and a tier 0 daily is exactly today's. Regions 2 to 4 (Millbrook, Willow Fen, Moonspire Keep) also get their own ground colors; play does not change. Still no mid-wave gate switch.
- 2026-10-28: Bart asked for: a Restart button beside Abandon, reachable from inside any level (Pause), with a confirm; finger drag scrolling in lists such as the campaign level list (only the scroll bar worked on his Fold5); and a small round button inside levels that turns music on and off. The DM's calls: Restart on a campaign level or Twist starts it over on the same difficulty and records nothing; in a roguelite run or the daily it follows the existing "start over" rule (the current run counts as lost at its wave, then a new run starts; the daily replays the same day's daily). Music gets its own setting beside sound: the HUD button toggles music only, with a music note icon crossed out when off, and Settings shows "Music" and "Sound effects".
- 2026-10-28 (night): Bart accepted all the DM's recommendations and, while he sleeps, approved the DM following its own advice at any gate in the expansion work (tuning, star rules, hint wording, regions 7 and 8). Signing, Play Console and anything outside the brief still wait for him. The DM tells him each text change he will see. Region 6 text changes from this: the Scarecrow card line and the 6-2 hint say "Walkers"; 6-1's third star is "No tower above tier 2."; the 6-6 hint ends "Frighten it with a Scarecrow."; the 7-2 hint says "a straight road".
- 2026-10-29 (DM, under that approval): Glimmertoad's 8-6 boss wave starts at strength 50 (1800 health), not 75, because a probe on real maps found 75 about twice as hard as 5-6's boss; the region 8 tuning still decides. Its run boss packs start at 80 and 70. Its card line now gives the count: "At half health, 6 Flitters fly out." New run cards: "You can build Moth Lanterns for the rest of the run." and "Moth Lanterns reach 1 tile further."
- 2026-10-30 (DM, under the same approval): region 8 and 5-6 tuning (docs/design/TUNING_R8.md). 5-6's third star becomes "Build no Sling Posts." 8-6's boss wave goes to strength 55, its wave 9 brings 5 Dusk Moths, and in Double Trouble the second Glimmertoad comes 12 s after the first. Glimmertoad's two run packs drop to 50 and b4_blinking_watch's last wave brings 3 Dusk Moths, provisional until the B7 re-run.
- 2026-10-30: Bart asked that the round button inside levels turn off sound effects and music together. It now toggles the master sound switch (`sound_on`, Settings' "Sound effects"), shown as a speaker crossed out when off. The player's own Music setting is kept. Bart also checked folding and unfolding mid-wave on his Fold5: it works.
- 2026-10-30 (DM): after the final balance pass (docs/balance/final-2026-10-30.md, docs/design/TUNING_FINAL.md), 3-5's wave 12 brings 33 Pips, not 32, so no lone Sling Post earns three stars. From tier 2 on, run bars are read with the three newer tower cards out of the pool (RULES 14.8, second reading), because their cost is spread over all three and cannot be tuned card by card. In a run, the call button's owed-card label reads "Card due next" (QA 2026-10-30 L1).

## Rules for every session and agent

- Read docs/BRIEF.md, CLAUDE.md and docs/ARCHITECTURE.md (once it exists) before starting any task.
- docs/ARCHITECTURE.md is the contract. Build against it. Contract changes and changes to anyone else's area go through the DM. Never edit another area's files.
- Agents never commit or push. The DM commits after each integration step, once all tests pass, with a plain message saying what changed and why. Commits are authored as the bartbasi account, set in this repo's git config only.
- Keep it simple. No features, settings or abstractions beyond the brief. Ideas go in reports as suggestions for Bart.
- Priority for every decision and fix: security and bugs first, then fun and polish.
- No em dashes and no double hyphens in prose: docs, UI text, code comments, commit messages. Short, plain sentences. No marketing voice. Command line flags inside code formatting are fine.
- If anything is unclear, conflicts, or would force a guess, stop and ask. Do not pick an interpretation silently.
- The game rules run in plain classes with no UI or Node dependencies, on a fixed timestep with seeded randomness, so the same inputs always give the same result.
- Saves: JSON only, read through the JSON parser. Never `str_to_var`, `bytes_to_var`, `FileAccess.get_var`, `ConfigFile`, `load()` or any loader that can create objects from file data. Validate every loaded field (type, range, shape) and fall back safely to defaults. Write atomically (temp file, then rename) and handle a failed rename. Put a far ceiling on loaded numbers to refuse tampered saves, never a limit a real player can reach.
- Every outbound address is a constant, written once, never built from input.
- Color is never the only signal. Text meets 4.5:1 contrast, checked by a script. Touch targets at least 48 dp. Respect safe areas. 60 fps on the Fold5.
- The DM runs at most four agents at once and works phase by phase. Never launch the whole team together. If a max effort agent stalls, sprawls or adds unrequested features, the DM drops it to high for that task and tells Bart.
- Hard stops: A is cleared (2026-10-23). B is cleared (2026-10-24). C is cleared (2026-10-25): the repo is public and the DM pushes verified work. Ask first before GitHub Pages, any signing, any Play Console work, and anything outside the brief. Play Console waits for Play, Inc.'s DUNS number.
- Before the first push, remind Bart to search "Forkline" in Google Play on his phone and run a quick trademark search.
- End every phase with a short status for Bart: done, verified, next, blocking.
- Every agent ends with a short report: files changed, how it was proven (command and result, test names, screenshot path), open questions, contract change requests.

## Commands

Run Godot commands from the repo root in the Bash tool.

```bash
godot --headless --path . --import                            # build the class cache (fresh clone, or after adding a class_name)
godot --headless --path . --quit                              # project opens and runs
godot --headless --path . --script res://tests/run_tests.gd   # all tests; exit code 0 means every test passed
```

## Writing tests

- Put tests in `tests/<area>/test_*.gd`. Each file starts with `extends "res://tests/base_test.gd"`.
- Every method named `test_*` runs on a fresh instance. Tests are synchronous.
- Seed every random generator so results repeat.
- Optional hooks: `before_each()`, `after_each()`.
- Helpers: `assert_true`, `assert_false`, `assert_eq`, `assert_ne`, `assert_null`, `assert_not_null`, `assert_near`, `fail`.
- A script error raised while a test runs (a null access, for example) counts as a failure.
- `-- --only=sim,run` after the test command runs only those folders under tests/.
- tests/project/ checks the source file header on every .gd and .gdshader file, the LICENSE MD5 and the NOTICE credit lines.

## Environment notes (this Windows machine)

- `godot` on PATH is a WinGet link to the Godot 4.7.2 exe. Use it from Bash, where it returns real exit codes. In PowerShell it does not wait or return an exit code unless its output is piped.
- Do not use `godot_console.exe`. It fails with "CreateProcess failed, error 193" because of a stray installer log file directly in `C:\Users`. Bart wants that file left alone: never move, rename or delete it.
- Other projects run Godot on this machine at the same time. Never end Godot processes by name (`taskkill /IM`, `pkill godot`, `Stop-Process -Name`). End only a process you started, by its PID, and wrap long Godot runs in `timeout`.
- Paths in committed files: never write the Windows account name. Use `%TEMP%`, `%APPDATA%` or `%USERPROFILE%` style placeholders.
- Android SDK at `C:\Android\Sdk`. adb is at `C:\Android\Sdk\platform-tools\adb.exe`, not on PATH. JDK 17 (Temurin) is on PATH. Export templates in `%APPDATA%\Godot\export_templates\4.7.2.stable`. The debug keystore lives in `%APPDATA%\Godot\keystores\`, outside the repo.
- Pushing (DM only, after hard stop C): git's credential manager has no GitHub login here, so push through gh: `git -c credential.helper= -c "credential.helper=!gh auth git-credential" push origin main`.
