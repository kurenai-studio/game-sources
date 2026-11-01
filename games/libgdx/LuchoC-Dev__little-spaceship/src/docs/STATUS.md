# Project status

Last updated: 06/09/2026.

Read this first if you are picking the project up. It says where things stand and what comes next; `CLAUDE.md` says how to work here.

**The project went into standby on 06/09/2026, after phase 11k.** If you are returning after that, read
[`RESUMING.md`](RESUMING.md) before this file: it carries what a status document does not — the state the
tree was left in, which of the open issues are already finished, what is half-built on purpose, and the
traps that have already cost hours.

## Where we are

**`main` is now the whole picture, and the game is finished except for shipping it.** The three branches
that held the MVP were reviewed and merged on 25/08/2026 — sprites (#30), audio (#31), boss (#29) — and
everything they left unwired was closed the same day, along with a balance pass driven by playing, two
defects and a UI pass. `./gradlew build` is green and `core` carries **331 tests** on `dev`.

**The MVP is shipped.** The game is live at <https://luchoc-dev.github.io/little-spaceship/>, it runs
in a browser with no install, and phase 09 closed on 25/08/2026. What follows is polish, and the
post-MVP backlog below says what is rough.

A pattern worth knowing before you trust any phase marked done: **three times in one day, art that a
phase had "delivered" turned out to exist only under `docs/design/`, with nothing in `assets/` and no
code loading it** — the sprites, then the fonts. A phase status saying the art is drawn does not mean
the game can draw it. Check `assets/` and check what the loader actually asks for.

Phase 10a found the **fourth** instance on 26/08: `docs/design/skin/` holds a generated `skin.png`,
`skin.atlas` and `skin.json`, and `07-skin.md` announced them under "What ships". Nothing loads them —
`GameSkin` builds the whole skin in code. Unlike the first three that is not a defect, only a
document, and it is corrected; but four is a pattern, not bad luck.

What exists in the repository:

- `docs/planning/` — fourteen documents covering vision, MVP spec, game systems, campaign, progression, balance values, architecture and the agent workflow.
- `docs/sources/` — the verbatim ChatGPT transcript the planning came from. Spanish on purpose; it is evidence.
- ~~`spikes/web-viability/`~~ — **deleted on 27/08/2026 by phase 11a**, on the project owner's decision. It was a throwaway prototype that validated the platform, and the one thing that kept it — `rngcheck/` being the only measurement that `Rng` produces a bit-identical stream under TeaVM — ended when [#52](https://github.com/LuchoC-Dev/little-spaceship/issues/52) moved that check onto the real `core` class in the `:rngparity` subproject (`./gradlew :rngparity:rngParityCheck`), with no copy of `Rng.java` anywhere. **The evidence is not gone, it moved into history:** the last commit containing the directory is `68d002e0560ce40842dc8f72e876fa5fe78bb3ed`, and `git show 68d002e0560c:spikes/web-viability/<path>` still reads any of its files. Every citation of it elsewhere in `docs/` — the benchmark behind `11-technical-prototype-results.md`, the build commands phase 09's plan points at, the working references in phases 01 and 03 — is a dated record of a past phase and stays as written; that commit is what makes them chaseable. Resolved [#5](https://github.com/LuchoC-Dev/little-spaceship/issues/5); see `docs/plan/10a-honest-documentation/decisions.md`, D1.
- `docs/design/` — the visual direction: the closed `ls32` palette, sprite sizes in pixels per archetype, bitmap typography, HUD layout, legibility rules, and pixel-exact mocks. Synchronisation point 1, settled.
- `.claude/agents/` — six agent definitions with project-scoped persistent memory.
- `core/` — the ECS, the fixed-step loop, `Rng`, `InputFrame` and the ports, plus motion, collision, the defensive chain, cleanup, the content contracts, the spawner, and phase 05's systems: weapons and their upgrades, power-ups, the attachment, the bomb, `Health` and scoring, the boss and its six colliders, and phase 11b's wave scheduling, entity lifetime and safety box. **331 tests**, no libGDX on its classpath.
- `game/` and `desktop/` — the LWJGL3 launcher, the input adapter that sums keyboard and relative mouse, an allocation-free renderer reading through `WorldView`, integer-scaled viewport, placeholder art at the sizes the visual direction fixed, the real sprite atlas and bitmap fonts, the Skin, the seven screens, audio, and the JSON content loader. Still no tests ([#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19)). `web/` carries `WebLauncher` and the TeaVM build that ships the live site.
- `assets/data/` — the content as JSON: six archetypes, **seven** trajectories, **eight** formations, one attachment, and — since phase 11b — **thirteen waves in `waves.json`**, placed by `level-01.json` as fifteen ordered `WavePlacement`s. The level carries no absolute timestamp any more; it still carries the boss.
- `.github/workflows/ci.yml` — CI on every push and pull request: compiles, runs the tests, builds the
  desktop and TeaVM web targets. It cannot prove the web build *runs*; a human does that.
- `README.md` and `LICENSE` (MIT) — written for the repository going public. The licence covers the
  whole repository, art and audio included.

## The three merges, and what they did not do

Merged 25/08/2026 after one `reviewer` pass each, on Sonnet, one per pull request.

| PR | Branch | Verdict |
|---|---|---|
| [#30](https://github.com/LuchoC-Dev/little-spaceship/pull/30) | `feat/sprite-production` | accept — every measurable claim reproduced against the committed PNGs |
| [#31](https://github.com/LuchoC-Dev/little-spaceship/pull/31) | `feat/audio` | accept — `core` untouched, no threads, determinism intact |
| [#29](https://github.com/LuchoC-Dev/little-spaceship/pull/29) | `feat/boss` | accept — including the coordinator-committed last commit, whose "277 tests" is exact |

The merges resolved the cross-branch dependencies but did **not** finish the features. Three
capabilities landed connected to nothing, and one deliverable was not what its phase status implied.
All four were closed the same day, on their own branches, each merged after the coordinator audited
the diff:

- **`EnemyDestroyed` had no listener** — the explosion sound was generated, loaded and silent.
  `AudioDirector` is now the simulation's `GameEventSink`.
- **Nothing read `bossStatus()` for audio** — `MusicTrack.BOSS` never played. The `false→true` edge
  now swaps the music. The return-on-death path needed no new code: `LittleSpaceshipGame.setScreen`
  already stops the music for any screen that is not `PlayScreen`.
- **No archetype declared a `"weapon"`** — enemies did not shoot in the shipped level. `enemy-shooter`
  now carries `{ "pattern": "straight-single", "rate": 1.8, "speed": 90 }`. Those numbers are
  `level-designer`'s judgement, not a decided value; see `docs/plan/07-boss/status.md`.
- **The sprites were not in the game.** `#30`'s diff touched only `docs/design/`: the 34 character
  sprites lived as pixel art in `docs/design/mockups/src/01-sprites.js`, and the PNGs that script
  renders are gitignored previews. `PackedSpriteAtlas` and `SpriteAtlas` already existed and were
  falling back to `PlaceholderAtlas` for want of a file. `docs/design/atlas/build-atlas.js` now
  generates `assets/atlas/sprites.png`/`.atlas` from that one source, and the game loads it.

## What is left

1. ~~**Balance.**~~ **Closed on 25/08 by the player's own judgement: good enough to ship.** What is
   left is in "Post-MVP backlog" below, not here. The history below is kept because it records how the
   numbers got where they are.

   Also fixed the same day, both defects rather than balance: the player could fly off the top and
   bottom of the screen for ever (`MotionSystem.clampPlayerToPlayfield` clamped x only — there was no
   y clamp at all), and the HUD's labels sat on top of their own icon rows.

   Level 1's pacing was written before enemies could shoot, and enemy health is still
   placeholder — a heavy carrier dies in about 1.2 s against the 32 s its stretch reserves. Decided:
   tuned by playing, not by arithmetic.

   Two play sessions on 25/08 drove a round of fixes, all merged the same day.

   **What was wrong and is now fixed.** Only `enemy-shooter` was ever armed, and it does not appear
   in `level-01.json` until 166 s — so the player met no enemy fire at all. Worse, `EnemyWeapon`
   initialised `cooldownRemaining` to the full cooldown, so an enemy had to survive an entire cooldown
   before its first shot, while these archetypes carry no `health` component and die to one player
   projectile. Nothing ever fired.

   `EnemyWeapon` now takes an optional `"firstShotDelay"`, independent of `"rate"` and defaulting to it
   (zero rejected: an enemy firing the frame it spawns is unreadable). The roster in
   `02-mvp-functional-spec.md` was then honoured properly — Basic, Fast light, shooter and Super-fast
   all shoot; Tank and carrier do not, as specified. The boss's `patternCooldown` went 1.3 → 0.7,
   making its attack cycle 2.05 s → 1.45 s against the fixed 0.75 s tell. Verified on screen: six
   enemy projectiles in flight from three archetypes at once, and the player losing a life to them.

   **The open tension, deliberately not resolved.** The spec asks the basic for "low health and a slow
   shot", and those fight each other: dying to one hit, a basic rarely lives to fire twice, so its
   rate-of-fire contrast against the shooter is mostly invisible. The honest fix is a small `Health`
   (2–3 points) on `enemy-basic` and `enemy-light`, which is a real balance change — it lengthens clear
   time and introduces chip damage against `weaponProjectileDamage: 10`. Left for a play session to
   decide, not for arithmetic.

   **Watch first, next session:** whether the basic reads as firing less often than the shooter or just
   dies too fast to tell; whether the boss at 0.7 now feels like a boss; whether `enemy-rush`'s single
   likely shot reads as "shoots little" rather than "does not shoot"; and whether `enemy-light`'s
   130 u/s projectile is dodgeable — it is the fastest enemy shot in the game.
2. ~~**Phase 09 is the only thing left before the MVP.**~~ **Closed on 25/08. The game is live at
   <https://luchoc-dev.github.io/little-spaceship/>** — a link a stranger can open, which is what
   this phase existed for.

   The launcher (#33), CI (#35), the README (#37) and the Pages deploy (#39) all merged the same
   day, each after a `reviewer` pass on Sonnet. The MIT licence, the repository description and its
   topics landed alongside them, and the repository was made public by the player.

   **Verified against the live site, not against a green workflow:** `index.html`, `app.js`,
   `startup-logo.png`, the sprite atlas and every music and SFX file return 200. `app.js` is served
   gzipped at 302,393 bytes against 1,027,585 on disk. The thirteen main files total **1,437,558
   bytes (~1.4 MB)** as actually served — the Pages artifact is 2,470,942 bytes across 34 files, but
   the CDN compresses the JavaScript.

   **The WAVs are served uncompressed** — `level.wav` 592,748 bytes and `boss.wav` 395,180 — so
   roughly a megabyte of the download is raw music. That is the single largest load-time win
   available and it is in the post-MVP backlog below.

   Browsers: **Chrome and Firefox verified by hand**; Edge dropped by the player's decision. Load
   time was not measured beyond the sub-second `curl` figures above; a real browser's network panel
   would be the honest instrument.

### Post-MVP backlog, from real play on 25/08

The player judged the gameplay good enough to ship and asked that none of these be changed before the
MVP. They are written down here because they came from playing, which is the only source this project
trusts for balance, and because two of them are defects rather than tuning.

- **The shooting sound glitches under sustained fire.** Appears after firing continuously for a while.
  Most likely `Sound` instance exhaustion in libGDX — every shot starts a new one and nothing bounds
  them. Not diagnosed.
- **Frame rate drops about 20 FPS for 5–10 seconds at certain points.** Cause unknown. The obvious
  hypothesis — projectiles accumulating off screen — was **checked and refuted**: `LifetimeSystem`
  expires both projectile layers past the playfield edge with a 16 unit margin, so they do not pile
  up. Do not start from that theory again.
- **The boss is still too easy, and the reason is its aim, not its volume.** Tripling the fan to three
  rays per part barely moved it. The player's diagnosis is better than the fix: the spread always
  points *outward* and the sweep *inward*, so a player who parks in the centre is never threatened.
  The fight is a positioning problem solved once, not a dodge. What to try: five rays, and aim the fan
  at the player rather than at fixed outward angles. That changes the nature of the attack instead of
  its quantity — and it must be weighed against the tell staying honest, which is what makes this boss
  fair.
- **The download is 2.5 MB, and 1.3 MB of it is two music WAVs** (`level.wav` 592 KB, `boss.wav`
  395 KB). The release `app.js` is only ~298 KB gzipped, so the code is not the problem — uncompressed
  audio is. For a portfolio piece where the visitor waits or leaves, encoding the music to OGG is the
  single biggest win available, and libGDX plays OGG on both targets. Measured on 25/08 by the web
  launcher work; not done because the MVP was frozen.
- **QUIT does nothing on the web target** ([#40](https://github.com/LuchoC-Dev/little-spaceship/issues/40)).
  `MenuScreen.java:30` wires it to `Gdx.app::exit`, which closes the window on desktop and cannot do
  anything in a browser — JavaScript may not close a tab it did not open. Found by playing the
  deployed build on 25/08. It is a dead control in the first menu a stranger sees, and the fix is a
  decision rather than code: hide it on web, give it a different meaning there, or accept it. The
  spec in `02-mvp-functional-spec.md` asks for Play/Options/Quit and was written for a desktop game.
- **Every enemy projectile uses `shot-e-small`.** `EnemyWeaponSystem` hardcodes it. The tank's shot
  should be visibly heavier — `shot-e-heavy` already exists in the atlas, unused — which needs
  `EnemyWeapon` to carry a sprite id per weapon.

### The UI pass, 25/08 — closed

The player called the screens "not well made": buttons with no padding or padding on one side only,
text overflowing its frames, a BACK button clipped off the bottom of Options. None of it was padding.

**`GameSkin.build()` was calling `new BitmapFont()` — libGDX's bundled Arial — and registering it under
the names `"font-mini"` and `"font-title"`.** Every screen and `HudRenderer` asked the Skin for the
project's own fonts by name and got Arial. Smooth, proportional, wrong metrics, inside layouts drawn
pixel-exactly around a fixed 6/8 px advance. The frames were right; the glyphs were wrong. The hand-drawn
sheets had existed since #30 and had never been made loadable — **the same gap the sprites had**: art
produced in `docs/design/`, never packaged into `assets/`. That pattern appeared three times in one day;
it is worth checking for a fourth before assuming a phase is done.

`docs/design/fonts/build-fnt.js` now emits `assets/fonts/*.fnt` + page from the sheets, and `GameSkin`
loads them at scale 1. Fixed alongside it: the BACK button (the placeholder's line height overflowed the
480×270 viewport — `BaseUiScreen.content` has no clip), absent button minimums (`04-hud-layout.md`'s
60×12 was never enforced), one-sided padding, menu entries now centred so a short label's slack splits
evenly, and the focus marker no longer flush against the frame.

**One thing deliberately re-added:** the focused entry grows 6 px. That was never an animation — with the
placeholder font each button sized to its own text, so swapping `"  "` for `"> "` widened it for free.
A fixed advance makes that swap cost zero pixels, so the movement vanished when the real font landed. It
is now driven from the cell's width, not the button's padding, because the 60 px plate minimum absorbs
padding on short labels and nothing moves.

### Known and deliberately left open

None of these block the MVP. Each is a real thing someone chose not to fix under a deadline.

- **Art and ECS disagree on five pickup ids** (`pickup-weapon` vs `pickup-weapon-upgrade`, and four
  more), bridged by alias regions in `sprites.atlas` — same pixels, second name — because renaming
  either side crosses an agent boundary. Settle it by picking a side, not by adding a third alias.
- **`boss-shot` has no authored art.** It was invented in phase 07, after the sprite pass, and is
  aliased to `shot-e-small`. It reads correctly; it is not its own sprite.
- ~~The HUD's icon squares overlap their text labels.~~ **Fixed on 25/08.** `HudRenderer` fed
  `BitmapFont.draw` through the rect helper `yGdx(yDown, height)`, but a font's `y` is already a top
  edge ("the top of most capital letters"), not a bottom-left corner, so the cap height was subtracted
  twice and every label landed one line down, on its own icon row. A separate `yGdxTop` helper now
  serves text. The score value was silently mispositioned by the same bug. Still open from this entry:
  the five `icon-*` sprites exist in the atlas and `HudRenderer` does not use them. It is not
  "text-only", which this entry said until 26/08: it draws flat rectangles at the design's exact
  coordinates and colours, and what is missing is the iconography.
- ~~Ramming the boss does not repeatedly damage the player.~~ **Withdrawn on 25/08 after a play
  session.** Ramming damages the player normally. The "one hit then nothing" an agent saw under
  sustained overlap is `03-game-systems.md`'s decided rule — all damage taken grants temporary
  invulnerability — working exactly as specified. Kept here as a record that a guess reached this
  document as an open unknown; check `docs/planning/` before writing down that the game fails to do
  something.
- **`game` now imports `core.domain.event`** (`EnemyDestroyed`, `GameEvent`), the first such import in
  the project, and the mechanical boundary grep in `.claude/agent-memory/game-presentation/` will flag
  it. It is not a violation: `core.port.GameEventSink` already imports `GameEvent`, and `GameEvent`'s
  own javadoc says the events "are the whole contract" towards presentation. The event package is a
  boundary package that happens to be filed under `domain`. If that keeps causing false alarms, move
  it to `core.port` rather than weakening the check.
- **`ship-bank`, `ship-tilt`, `ship-hit`, the thrust and muzzle effects, `module-satellite`,
  `structure-tower` and the five `icon-*` glyphs** are in the atlas and referenced by nothing. Art
  waiting for a system.

~~Two things phase 09 must check~~ **Both closed on 25/08 by #33, and one of them was never real:**

- ~~`tools/audio` uses `java.nio.file` inside the module TeaVM compiles.~~ **Fixed.** `GenerateAudio`,
  `Synth` and `Wav` moved to their own Gradle source set at `game/src/tools/java`. `web` depends on
  `:game`, which exposes only `main`, so TeaVM never sees them. Verified against the jar, not
  assumed: `game.jar` carries no `tools` classes.
- ~~The Skin integration is reflective and needs TeaVM declarations.~~ **It was not.** `GameSkin`
  builds the entire skin in code from `Pixmap`/`NinePatch`/style objects; the only file it reads is a
  plain-text AngelCode `.fnt`, which is not reflective. There is no `Skin(FileHandle, TextureAtlas)`
  and no `skin.load(...)` anywhere. `docs/design/07-skin.md` described the reflective path and was
  wrong about the code; that stale doc is what put this warning here in the first place.
  **Corrected on 26/08/2026 by phase 10a**, which also found the drift was wider than this entry
  knew: none of that page's fourteen drawables, five named colours or focus nine-patch is in the
  game either. See `docs/plan/10a-honest-documentation/audit.md`, F10.

## What is settled

Platform, architecture and MVP scope are decided, and the technical parts were **measured, not assumed** — see `docs/planning/11-technical-prototype-results.md`.

The short version lives in `CLAUDE.md`: invariants, web-target pitfalls, conventions, commit rules and the agent roster. The long version is in `docs/planning/`.

`docs/planning/08-decisions-and-open-items.md` is the one to check before deciding anything: it separates confirmed decisions from provisional ones and from what is still open.

## What comes next

**The MVP is shipped, so what comes next is the post-MVP work.** Four groups, in order, with the
reordering first so everything after it is built on a base that holds:
[`docs/plan/post-mvp-roadmap.md`](plan/post-mvp-roadmap.md).

**The 10 group is done.** Phase 10a audited every document here against the
code and corrected what was false — [the audit](plan/10a-honest-documentation/audit.md) is the record,
and it is worth reading before trusting any document in this repository, because it says which ones
were checked and what each one got wrong. Phase 10b then measured what a phase costs, audited the six
agent definitions and nine phases of agent memory, and changed how work reaches `main`. Phase 10c
reviewed the architecture against what the 11 group needs and found that it **holds, with four named
additive extensions and no change to its shape** — [the decision](plan/10c-architecture-review/decision.md)
records what was rejected as well as what was chosen. **The 11 group is next**, and its first task is
[#44](https://github.com/LuchoC-Dev/little-spaceship/issues/44): rule-asserting tests, because
everything 10c named is a behaviour change under a suite that mostly proves a run reproduces itself.

**The 11 group was planned on 27/08/2026** into six phases — [11a](plan/11a-rule-asserting-tests/plan.md)
through [11f](plan/11f-web-defects/plan.md) — in a conversation with the project owner that closed
every question the roadmap left open: what ends a wave, how it is placed, whether it takes parameters,
where waves live, where a movement shape is chosen, what form the per-level document takes, and how
long level 1 runs. Those answers are in
[the decision record](planning/08-decisions-and-open-items.md), "The 11 group, 27/08/2026". The same
conversation resolved [#91](https://github.com/LuchoC-Dev/little-spaceship/issues/91): **invariant 6
in `CLAUDE.md` now reads "no abstraction without a real case you can point at"**, which is 10c's
proposed wording accepted unchanged.

**Phase 10d ran between 11b and 11c**, out of numerical order and on purpose: 11b's three broken rules were going to repeat in 11c, which is the first phase to run agents in parallel over `core/` and `assets/data/` at once. It belongs to the 10 group by subject — it is 10b's successor — and to the 11 group only by date.

**11a, 11b, 11c, 11d and 11e are done and on `dev`.** 11a measured the test baseline and added
rule-asserting tests; 11b built the wave system and is the first phase of the group to change
production code; 11c made movement a described thing; 11d generated the per-level document from the
content and made CI fail when they disagree. **11e is done and on `dev`** — level 1 redesigned onto the
shapes 11c built, which no level had used until now, played twice by the project owner and confirmed
by them as correct. **The 11 group is complete and on `dev`** — 11f was the last of it, the four web defects. **11g is done and on `dev`** — the `shield` drop level 1 turned out to be missing, a third task the play session found, and the half of [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19) that was never blocked. **`game` has tests for the first time.** **Phase 11h is done and on `dev`** — a test mode, so one wave or the boss can be opened from a menu instead of playing 134.5 s to reach it, as a build flavour whose code is absent from the shipped build rather than hidden in it. **Phase 11i is done and on `dev`** — enemies can now follow a drawn path: enter, turn, wait, loop a bounded number of times, leave, with mirroring for free. **Phase 11j is done and on `dev`** — a path can be written where it happens rather than as a velocity, and the same path can run faster without changing size; **curves were refused** (a semicircle out of constant-velocity segments is a polygon, and real circular motion needs sin/cos against a determinism constraint already measured), and level 1's redesign moved to **11k**. **Phase 11k is done and on `dev`** — level 1 rebuilt on a vocabulary written for it, per archetype: `enemy-basic` and `enemy-shooter` no longer fly the same shape, and neither do `enemy-tank` and `enemy-carrier`, where before this phase four of six archetypes flew exactly one shape for the whole level. The boss moves, on a design the project owner drew. **Phase 12 is not planned yet.** **Phase 12 follows**: levels 2 and 3, which the roadmap calls the first honest measurement of whether this group worked.

**11e is the phase that tested whether this project's own rule survives contact with itself.** The
rule, decided on 22/08 and again on 25/08, is that balance is tuned by playing and not by arithmetic,
and `docs/STATUS.md` calls playing *"the only source this project trusts for balance"*. So the phase
was structured to make that unavoidable: agents build a candidate, the project owner plays it, the
phase tunes from what they report, and **the candidate is not the deliverable**. The session earned
it — it reversed a change made the previous day on the repository's own arithmetic, and it found two
defects that a clean generated document, a green `pre-pr-check` and a `reviewer` audit had all passed.

It inherits two concrete warnings, both still live. From 11b: `LifetimeSystem`'s safety box sits 128 units
past every playfield edge, sized against today's formations, and a movement shape that leaves the
playfield and re-enters is exactly what that box must not eat
([#117](https://github.com/LuchoC-Dev/little-spaceship/issues/117)). From 11c: **the veers must spawn
on the side they veer away from** — `veer-left` at `atX >= 0.75`, `veer-right` at `atX <= 0.25` — or
the shape happens off screen.

**How work reaches `main` changed on 26/08/2026**, by the project owner's decision: `main` ← `dev` ←
one phase branch ← one sub-branch per agent. Nothing is committed on `main` or `dev`, a phase opens a
pull request against `dev` rather than merging, an agent merges nothing, and only the project owner
merges `dev` into `main`. Every agent runs `tools/pre-pr-check` before opening a pull request. The
whole regime is in [how to run a phase](plan/how-to-run-a-phase.md). None of the 10 group changes production code; it decides, and the 11 group
executes. Four issues were handed forward: [#52](https://github.com/LuchoC-Dev/little-spaceship/issues/52),
[#53](https://github.com/LuchoC-Dev/little-spaceship/issues/53),
[#54](https://github.com/LuchoC-Dev/little-spaceship/issues/54) and
[#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56).

Four issues came out of playing the deployed build on 25/08:
[#40](https://github.com/LuchoC-Dev/little-spaceship/issues/40) QUIT is dead on web,
[#41](https://github.com/LuchoC-Dev/little-spaceship/issues/41) losing pointer lock breaks the mouse,
[#42](https://github.com/LuchoC-Dev/little-spaceship/issues/42) no in-game options,
[#43](https://github.com/LuchoC-Dev/little-spaceship/issues/43) the shield and attachment are
invisible. None block playing.

### The original plan, for reference

The master plan is in `docs/plan/`, starting from [the overview](plan/00-overview.md). Each phase has
its own folder with a `plan.md` and a `status.md`.

| Milestone | Date |
|---|---|
| MVP — level 1 playable in the browser with its own art | 26/08/2026 |
| Finish — polish, game feel, final audio | 09/09/2026 |

The order from here is the two numbered items in "What is left": balance by playing, then phase 09.
Everything the three merged branches left unwired is closed.

### Phase state

| # | Phase | State |
|---|---|---|
| 01 | Foundations | **done** — merged in #2 |
| 02 | Core mechanics | **done** — merged in #10 |
| 03 | First playable | **done** — merged in #14 |
| 04 | Content pipeline | **done** — core in #16, loader in #14 |
| 05 | Game systems | **done** — merged in #22 |
| 06 | Presentation | **done** — direction #8, integration #26, sprites packed into `assets/atlas/` and the real bitmap fonts into `assets/fonts/` on 25/08 |
| 07 | Boss | **merged** — #29, with level 1 and enemy fire. Four archetypes shoot; the boss fans 6 projectiles a volley |
| 08 | Audio and polish | **merged** — #31, with both dead cues wired on 25/08. Nobody has heard it yet; phase 09's browser pass is the first listen |
| 09 | Web, CI and release | **done** — launcher (#33), CI (#35), README (#37) and Pages deploy (#39). The game is live |
| 10a | Honest documentation | **done** — every document in `docs/` audited against the code, 33 false statements corrected, #5 resolved, #3 and #4 decided, and a mechanism chosen. See [the audit](plan/10a-honest-documentation/audit.md) |
| 10b | Agents and sessions | **done** — phase 09 measured (813 calls, $110.76 equivalent, 83 % of it the coordinator's model choice), the six agent definitions and 46 memory files audited, the agent-memory worktree trap closed with a hook, an evidence rule for claims about a system, and the `dev`/phase/sub-branch regime with `tools/pre-pr-check`. See [the measurement](plan/10b-agents-and-sessions/measurement.md). Merged into `dev` in #76 and into `main` in #79 |
| 10c | Architecture review | **done** — the architecture holds for the 11 group with four named additive extensions (#84, #85, #86, #87) and no change to its shape; all fifteen open issues triaged, #23 closed as already fixed and #11 decided; invariant 6's expired wording put to the project owner as #91. No production code changed. See [the decision](plan/10c-architecture-review/decision.md) and [the assessment](plan/10c-architecture-review/assessment.md). Merged into `dev` in #93 |
| 10d | Rules the tools enforce | **done** — merged into `dev` in [#152](https://github.com/LuchoC-Dev/little-spaceship/pull/152). Written after 11b broke three written rules across five agents, each where the rule existed only as a sentence someone had to recall. One status file per task instead of one shared file, so parallel tasks cannot conflict; `pre-pr-check` fails a branch that does work and records nothing, and parses workflow files; a `commit-msg` hook refuses a malformed subject as it is written; the coordinator creates every branch and worktree; `agent-prompts.md` no longer sends agents to `main`; and a `pr-check` workflow verifies the pull request as an object and runs `pre-pr-check` rather than trusting pasted text. **Four of its own rules broke on contact with reality** (#136, #137/#132, #148, #150) — three were specifications written from one point of view, the fourth was a tool nothing checked. No production code. The `reviewer` pass its own plan argued for ran afterwards and merged in [#159](https://github.com/LuchoC-Dev/little-spaceship/pull/159): it answered **no** to the plan's own brief — *would an agent who has read only these documents do the right thing?* — and found two more, both shapes nobody had lived through. `git revert`'s wording was welcomed by `commit-msg` and rejected by `pre-pr-check` (#154), and neither check looked at which phase's directory a fragment sat in (#155). Fixing them exposed two further instances of one rule written twice, so the phase ships three shared scripts — `tools/commit-subject-ok`, `tools/status-fragments` and its `--misplaced` mode — instead of matching logic kept in agreement by care. **Eight faults, six of them one rule stated from a single point of view, two of them one rule stated twice** |
| 11a | Tests that assert rules | **done** — merged into `dev` in [#109](https://github.com/LuchoC-Dev/little-spaceship/pull/109). The baseline measured by reading all 289 tests (167 assert a rule, 9 reproducibility, 4 both, 117 infrastructure), which **falsifies the roadmap's suite-wide claim** and confirms it only for the five replay files; five rule-asserting tests added where nothing went red before, including the boss-module test #44 was raised for; #3/#53, #4/#54 and #52 closed, the `Rng` parity check moved onto the real class in `:rngparity`, and #104 and #108 opened. `reviewer` accepted, and `spikes/web-viability/` was deleted in the same merge |
| 11b | The wave system | **done** — merged into `dev` in [#131](https://github.com/LuchoC-Dev/little-spaceship/pull/131). A wave is named, reusable content in `assets/data/waves.json`; a level is an ordered list of `WavePlacement`s and carries no absolute timestamp. `level-01.json` migrated one-to-one, its 92 original spawn times re-derived independently by `reviewer`. #84, #85, #87, #111-#114, #122 and #126 closed. **Three defects, none found by reading code:** a negative offset silently did nothing, so waves could never overlap (found by `level-designer` trying to use it); the level's first wave was a tick late (found by running the *old* tests against the new system); and two rule-named tests passed while their rule was violated (found by falsifying them). 303 tests to 322. Debts opened: #117, #123, #128, #129, #132 |
| 11c | Movement as a described thing | **done** — merged into `dev` in [#174](https://github.com/LuchoC-Dev/little-spaceship/pull/174). The same archetype now enters differently at second 30 and at second 200 without being two archetypes, which closes the handover 10c's area E left (#86) — the one place that review found a *missing* mechanism rather than a strained one. A shape is a function from an entity's own elapsed time to its velocity: two kinds, `constant {vx, vy}` and `arc {vx, vy, ay}`, decided in `docs/plan/11c-movement-shapes/shape-catalogue.md` against the beats that ask for them, with **eight shapes refused by name**. `core/port/TrajectoryDefinition.java` is sealed over two records, `game/adapter/content/JsonContentSource.java` reads them and refuses an unknown kind, and `SpawnEvent` carries an optional `trajectoryId` with the archetype supplying the default. Proven in tests, not prose: one `enemy-rush` on `dive` and on `strike-run`, and 300 ticks of a curve that turns. #161-#164 and #86 closed. `SystemOrder` unchanged; 322 tests to 331. **Two things settled by measuring rather than arguing** — TeaVM compiles sealed interfaces (the real transpile was run and `app.js` grepped, against #123's blindness), and the uniform `Trajectory` attach reaches nothing hand-set. **The plan named one agent too few, twice**, because the content JSON is read in `game/` and not in `core/`; corrected in place, and 11d reads the same way. **No level uses a shape yet** — that is 11e |
| 11d | The per-level document | **done** — merged into `dev` in [#195](https://github.com/LuchoC-Dev/little-spaceship/pull/195). `assets/data/` is the only thing a person edits, and `tools/build-level-docs.js` generates `docs/levels/level-01.md` and `docs/levels/waves.md` from it; `.github/workflows/ci.yml` regenerates on every push and fails if the tree changes. **Demonstrated, not argued**: one line of the generated document was edited by hand and [run 33411807522](https://github.com/LuchoC-Dev/little-spaceship/actions/runs/33411807522) went red with the diff and the fix. `docs/plan/11d-per-level-document/document-contract.md` decided the sections before the generator existed, and refuses eleven by name. #177, #180, #182, #183, #186, #187, #190 and #192 closed. **Three defects, each found a different way.** #177 was two failures and the second had never run, because `pr-check.yml` exits at its first step. #190 was found by *using* the document — `level-designer` wrote a real `level-02.json` from it and the file did not load, because the document printed values and never JSON keys. #192 was found by the coordinator's audit and had survived a contract, a generator, a CI check and a read-back: the boss section claimed every ray leaves through a side edge, when two of six reach the floor first, and printed a `y at the side edge` of `-199.4` — a place that projectile never gets to. **The `reviewer` pass did not run**, the account having hit its monthly spend limit; the coordinator audited instead, per the precedent of 20/08/2026. **#56 stays open**, decided by measuring rather than estimating |
| 11e | Level 1 redesigned, balance and the boss | **done** — merged into `dev` in [#214](https://github.com/LuchoC-Dev/little-spaceship/pull/214), with the project owner's direct approval. The phase ran in two halves by the owner's decision of 31/08: agents built a candidate, the owner played it on 01/09 on the desktop target, and the phase tuned from what they reported. Level 1 is **fourteen beats, twelve of which carry a wave**, on the shapes 11c built — `grep -c trajectory assets/data/waves.json` went 0 to 13, closing the gap 11c left. The boss no longer fires at fixed outward and inward angles: `core/domain/system/BossSystem.java` locks the player's position at the instant the tell begins and fans five rays at that frozen point, by vector arithmetic and `Math.sqrt` so determinism holds under TeaVM. #198, #199, #200, #201, #202 and #210 closed through PRs #203, #204, #207, #209, #211 and #212. **The session is the result, not the candidate.** It confirmed the boss — difficulty called *ideal*, one session after the same fight was diagnosed as beatable by parking at screen centre — and it **reversed a change made the day before**: #199 raised enemy health because the repository's own arithmetic said a carrier died in 1.2 s against a 32 s stretch, and play said the first ninety seconds were too hard. **It also found two defects no check could see**: five enemies at second zero of an audiovisual introduction, and a 7 s escort over the boss's entrance that existed so "fourteen waves, one per beat" would come out even. `build-level-docs.js` reported Checks clean for both, `pre-pr-check` was green, and `reviewer` audited the escort specifically and called it a sound design call. One run found it. **That acceptance criterion was rewritten rather than worked around**, struck through and dated in `plan.md` and recorded in `docs/planning/08-decisions-and-open-items.md` under "Level 1 played, 01/09/2026". **Four defects opened and still open**: #205, #206, #208 and the carrier's mechanism — at 700 hp a carrier still dies before its first child in beat 11 under ideal fire, and the `Spawner` interval came 4.0 s to 3.0 s, which closes beat 8 and not beat 11. **#212 and #211 were merged without a `reviewer` pass**, on the owner's explicit instruction; the coordinator verified the numbers against `assets/data/` and that is recorded as a coordinator's check rather than an independent audit |
| 11f | The four web defects | **done** — merged into `dev` in [#232](https://github.com/LuchoC-Dev/little-spaceship/pull/232), with the project owner's direct approval, **completing the 11 group**. The four defects a stranger hits in the first minute — #40, #41, #42, #43 — plus #19's task, through PRs #228, #221, #227, #224 and #229. **All four verified by the project owner on 01/09/2026 in a real browser and on the desktop build**, which is the closure evidence the phase required and which no agent could supply: headless Chrome fails under SwiftShader even when a real browser works. **Twice, reading a jar settled what no run could.** `backend-web-1.6.1-sources.jar` ships in the Gradle cache: `isCursorCatched()` is a live DOM read of `document.pointerLockElement` (`WebInput.java:785`), and `Gdx.app.getType()` returns `ApplicationType.WebGL` as a constant (`WebApplication.java:440`). **And reading found a defect running could not.** #221's first version tested for a lost pointer lock in the same call that requested it; `requestPointerLock()` is granted asynchronously, so on web the click that engaged the mouse would have paused the game, forever — while desktop LWJGL3, which applies the catch synchronously, showed it working perfectly. `reviewer` raised it as a suspicion it could not confirm; the fix became a latch that arms only once the grant is observed. **Mid-phase the project owner added a rule**: an agent may launch the game only to confirm it starts, never to play it — `how-to-run-a-phase.md`, "Running the game is not playing it". Three new issues left open (#223, #225, #230) plus #218 and #219 opened at the phase's start, and **#19 stays open on purpose** with its two halves split. **One coordinator error is recorded rather than corrected quietly**: #222 was merged with `pre-pr-check` red, missed through a badly chained shell command, and #223 is the check's own blind spot it exposed |
| 11g | The shield drop, and a test harness for `game` | **done** — merged into `dev` in [#242](https://github.com/LuchoC-Dev/little-spaceship/pull/242), with the project owner's direct approval. Three tasks, five pull requests: #234 (a `shield` drop at 37.0 s), #235 (a test harness for `game`), #237 and #239 (the shell drawn on the ship). **Not a planned phase** — two things the 11 group left behind, and a third the play session found. **`game` had no tests and now has two**, through JDK dynamic proxies over `Gdx.input`/`Graphics` — **with no new dependency and no `build.gradle` change**, because the test source set already worked and was simply empty. Phase 03 had solved this in two throwaway programs that were never committed; the technique was never the blocker, the irreproducibility was, and it cost an untestable module since then. The mutation test was reproduced twice, by the author and by the coordinator. **Two documents were wrong, and only one was looked for.** #230 existed because 11f wired `icon-shield` from unreferenced atlas art and level 1 turned out to carry no `shield` drop at all. #238 was found because `visual-designer` read `WorldRenderer` instead of trusting `04-hud-layout.md`, which calls the invulnerability aura a 2-frame ring against code that draws a static square — wrong on shape and animation, and designing against it would have produced a different shield. **Both play-verifiable results confirmed by the project owner on 02/09/2026.** **Two coordinator errors recorded rather than corrected quietly**: the opening commit landed directly on the phase branch, and #237 was merged with no `reviewer` pass and audited retrospectively afterwards |
| 11h | A test mode, so a wave can be looked at without playing to it | **done** — merged into `dev` in [#249](https://github.com/LuchoC-Dev/little-spaceship/pull/249), with the project owner's direct approval on 03/09/2026. Four tasks, six pull requests: #247 (the `-Ptests` build flavour and the TESTS menu), #246 (four scenarios as level files), #254 (the flavour boots straight into TESTS) and #253 (the boss scenario alone), plus #248 and #256. **Not a planned phase** — the project owner decided to give level 1 more depth through movement and grouping, and that the tool comes first, because judging one wave costs playing the level up to it and the boss costs 134.5 s. **Nothing had to be invented, and that is the result**: a scenario *is* a level file (`JsonContentSource.java:349` accepts only `boss`/`events`/`waves`), which level runs was already one field whose javadoc had predicted exactly this change (`LittleSpaceshipGame.java:42`), and both halves of the build flavour had precedents — the `tools` source set and `-Prelease`. **The criterion was absence, not concealment**: two mutually exclusive source directories define the same class `TestMode`, one real and one a no-op, and `reviewer` proved it past what was asked by running the real TeaVM compile, `:web:gdx_teavm_web_js_build` — `:web:build` reports `compileTeavmJava NO-SOURCE` and proves nothing — and grepping the emitted `app.js` for zero hits. **Level 1 is untouched.** Two findings left open: #252 (a dropped pickup has no `Motion` and hangs in the air, scheduled to 11i because it changes an approved level's difficulty) and #255 (content cannot place a power-up, only an enemy carrying one). **Two coordinator errors recorded rather than corrected quietly**: the opening commit landed directly on the phase branch again, two days after 11g recorded the same thing, and a launch prompt gave an agent a wrong issue number that reached a status fragment — caught by `reviewer` checking the citation against what the issue said rather than what it was called |
| 11i | A path is a list of segments, and a shape can be mirrored | **done** — merged into `dev` in [#284](https://github.com/LuchoC-Dev/little-spaceship/pull/284), with the project owner's approval on 04/09/2026. **Four planned tasks and seven defects found while it ran**, through eleven pull requests. A movement shape may now be an ordered list of bounded segments with waits and repeats (`core/port/PathTrajectoryDefinition.java`), and `{"mirrorOf": "<id>"}` gives the horizontally negated shape in one line, resolved at content load with no new `core` API. **Bounding the loops is what made the phase small, and it was the project owner's decision**: with segments of known duration a path is still a pure function of `elapsed`, so `Trajectory` still holds only `trajectoryId` and `elapsed` — which means `shape-catalogue.md`'s refusal of waypoints was **dissolved** rather than overridden, while `enterAndHold`'s was genuinely reopened; both struck through and dated saying which. **Six of the seven defects were found by someone not looking for them**: `pickupFallSpeed` was a tuning knob wired to nothing (a `default` returning `20f`, the JSON key never read, the balance parser ignoring unknown keys) — fixed, and given the first test `JsonBalanceValues` has ever had, though **its other twenty fields are still unverified against a parsed fixture**; **CI was red for four consecutive runs** because `pre-pr-check` does not run the doc generator and neither does `./gradlew build`, and it was fixed by accident when a later task regenerated for its own content; two branches green alone were red together, which is the content guarantee working; and `reviewer` re-derived a path's arithmetic instead of reading it and found every timestamp after a wait half a second late — **the failure task 3 was written to be able to produce**. `core` 335 → **351 tests**. **Verified by the project owner playing the five path scenarios**, which no agent could do. Open: #280 (a loop is always a path's tail, so "circle three times and then dive" is unsayable), #255, whether `pre-pr-check` should run the doc generator, and whether the TESTS list should be discovered rather than hardcoded — a measured cost after three round trips. **Two coordinator errors recorded rather than corrected quietly**: a task was told not to touch `waves.json`, which is the shared wave library and not level 1's content, and a task brief handed an agent a wrong issue number that reached a status fragment |
| 11j | Paths written where they happen, and a speed that does not resize them | **done** — merged into `dev` in [#304](https://github.com/LuchoC-Dev/little-spaceship/pull/304), with the project owner's direct approval on 05/09/2026. Three planned tasks and five defects, through eight pull requests. **A path can now be written where it happens**: a `path` entry declares exactly one of `"segments"` (relative — a velocity held for a duration) or `"waypoints"` (absolute — an entry point, then destinations with a speed), resolved in `game/adapter/content/JsonContentSource.java` into the same `PathSegment` `core` already took, **with no new `core` API** — the reparameterization the project owner proposed after playing 11i, and it cost exactly what they predicted. **The kind of a path is answered by its key, once, at the top**, and mixing the two forms in one path is refused structurally rather than validated after the fact — the risk the plan named as the single biggest thing the phase could get wrong. **A speed multiplier, resolved at load**: `{"speedOf": "x", "multiplier": 2}` raises velocities **and** divides durations, so the geometry is identical and only the traversal time changes — the owner's decision, not the other meaning of "faster", and no `scale` was built. The spawn-event alternative was argued and refused under invariant 6: it buys a genuinely different capability (one shape at two speeds in one wave), needs a `SpawnEvent` field, and nothing written asks for it. **An `arc`'s `ay` takes the square of the multiplier while its velocities take the first power** — `vy·t + ay·t²/2` requires it, and scaling `ay` linearly gives a different parabola that still looks plausible; only a traced geometry test catches that, and `reviewer` confirmed it by mutation. **Seven trajectories and five scenarios**, one entry per capability the existing twelve could not express rather than one per beat, with **nothing deleted and level 1 untouched** — the diff over `trajectories.json` and `waves.json` removes no line. `game` 24 → **44 tests**; `core` unchanged at **351**, because none of this is in `core`. **Both audits found a defect, and both were in prose while the code was right**: a javadoc naming a guard that never fires (an absurd multiplier overflows a *velocity* to infinity long before a duration could underflow), and five removal times early by exactly one collider radius (`isPastSafetyBox` tests `x + radius`, so an entity leaves when its edge clears the box). Both corrected by the coordinator before merge; **both were catchable only because task 3 is required to write down what each trajectory should look like**, an instruction that has now produced a finding in two consecutive phases, with the JSON right and the prose wrong each time. **Verified by the project owner playing the five scenarios**, which found the phase's last defect: PLAY starting the last test scenario instead of level 1, because `overrideLevelId` set a field nothing ever cleared — a lifetime its own javadoc stated as a fact. Never reached a shipped build. Open: [#300](https://github.com/LuchoC-Dev/little-spaceship/issues/300) (nothing checks that an absolutely-authored path is placed at the `atX` it was written for — raised by task 1, answered by task 3, and it belongs in `tools/build-level-docs.js`, which already reads waves and trajectories together), the absolute form being absolute in `y` only modulo the collider radius, and #280. **The TESTS list is no longer an open question with a small cost**: nine entries became fourteen, a content task shipped five scenarios it could not list, and no test can cover the list at all because `TestScenarios` lives only in the `-Ptests` source set. **A coordinator error recorded rather than corrected quietly**: two pull requests opened ready instead of as drafts, and a phase branch left unpushed so a documentation branch cut from it carried an agent-memory commit into its own diff |
| 11k | Level 1 rebuilt on a vocabulary written for it | **done** — merged into `dev` in [#341](https://github.com/LuchoC-Dev/little-spaceship/pull/341), with the project owner's direct approval on 06/09/2026. **What 11h, 11i and 11j were built to make possible**, and each of those ended with level 1 deliberately untouched. Seven planned tasks and eight defects, through seventeen pull requests. **A vocabulary written per archetype** — thirteen authored shapes, six `mirrorOf` and one `speedOf`, replacing the seven from 11c — on the owner's rule of two or three movements that resemble each other, mirrors free. Level 1 is twelve placements and 68 spawns on it, with **`level-01.json` byte-identical** because the whole redesign lives in `waves.json`, which is 11b's split paying off. **The boss moves**: the ten vertices of a five-pointed star, every hop within three perimeter steps, chosen from the seeded `Rng`, the points derived offline and written as literals because 11j refused runtime trigonometry; a move takes a fixed duration whatever the distance, which was the owner's own answer to a synchronisation problem. **Front weapons on their own clock**, coinciding with every rear volley by arithmetic, tuned by play from ~17.5 projectiles/s to ~13.1 against ~5.3 before. **The generator began the phase blind to half the movement vocabulary** — a level placing a `path` crashed it — and now resolves every kind, measures a sideways exit from the trailing edge, handles a steepening arc, and checks an absolute path against its `atX` ([#300](https://github.com/LuchoC-Dev/little-spaceship/issues/300)). The TESTS menu discovers itself from `assets/data/test-*.json`. **Five times the code was right and the prose was wrong, and no check found any of them** — every one came from someone re-deriving, and once a replacement test asserted nothing at all, bounding a delta from one side where the failure it named makes the delta larger. **[#337](https://github.com/LuchoC-Dev/little-spaceship/issues/337) is the phase's most instructive failure**: a delayed formation slot activated one tick early because `MotionSystem` reached its crossing by repeated addition while the delay was formed by a single multiplication — both halves were well tested, the property was end-to-end, and nothing crossed the seam. **Three capabilities were built and deliberately left unused**: a single-file column no content asks for, a placeable pickup whose loader half was never built ([#255](https://github.com/LuchoC-Dev/little-spaceship/issues/255) stays open, half done), and the thinly used absolute form. `core` 351 → **370 tests**, `game` 44 → **50**. **Played across three sessions by the project owner**, who tuned the boss down once and closed with *"la jugabilidad es perfecta"*. Four coordinator errors recorded rather than corrected quietly, including a merge with a `build` check still pending |
| 11l | The check that fails every release | **done** — merged into `dev` in [#348](https://github.com/LuchoC-Dev/little-spaceship/pull/348), with the project owner's direct approval on 06/09/2026. **One defect, found by doing the thing it breaks**: opening the `dev` → `main` release for 11h–11k turned `pr-check` red, because `tools/pre-pr-check` counted status fragments with a sub-branch's rule and a release carries one per task of every phase in it — sixty, here. **It is the half of [#177](https://github.com/LuchoC-Dev/little-spaceship/issues/177) that fix did not reach**: 11d taught the branch-name check that a release is legitimate and the fragment check never learned it. **The third instance of one pattern** — a check never observed on a release, because the release before it failed earlier for a different reason, which #177's own record had already noted once. Fixed with an exemption as narrow as the branch-name check's, verified by hand in all four cases including the negative one. **Two coordinator errors recorded**: the fix was first opened as a `fix/` branch straight against `dev` (caught by `pr-check`, the mechanism working as 10d intended), and the phase's `status.md` was first committed directly on the phase branch — **the third time after 11g and 11h**, and still a rule no tool enforces |

## Open items that do not block

None of these stop step one. Each is due when its moment arrives:

- the intensity-curve tooling — the level's length and climax are now decided, the tool to shape the curve is not;
- pointer capture for relative mouse, and browsers other than Chrome.

## Traps that already cost hours

All of these are in `CLAUDE.md`, but they are worth repeating because they are silent:

- `assets/startup-logo.png` is mandatory or the web build crashes on preload, with an error that never mentions the logo.
- Headless Chrome cannot validate the web runtime. It fails under SwiftShader even when a real browser works.
- `ExecutorService`, `CompletableFuture` and `ReentrantLock` do not exist in TeaVM: they break the build. The core is single-threaded by decision, and it was measured that concurrency would buy nothing.
- Breaking determinism does not fail loudly. It silently invalidates every replay.
- **`gdx_teavm_web_js_run` serves on 8080, not 8181.** The pinned 1.6.1 plugin's real port. The
  claim of 8181 came from `spikes/web-viability/README.md`, which phase 09's plan sent people to for
  the commands; that directory was deleted on 27/08/2026 and the README is readable at `68d002e0560c`.
- `gdx_teavm_web_js_build -Prelease` **reuses the previous non-release output**: `generateJavaScript`
  reports `UP-TO-DATE` even though release mode changes obfuscation, optimisation and source maps,
  and leaves a stale `app.js.map` behind. Run `clean` before measuring a release build.
- `du -sh` overstates a TeaVM debug dist by roughly 4x — it copies ~580 tiny sourcemap files, each
  rounded up to a filesystem block. Sum actual file bytes when measuring download size.

## How work is organised

One issue per task, one branch per issue, merged through a pull request that closes it. Commits go through the `/git-commit` skill. `reviewer` accepts or rejects a phase against the acceptance criteria in its `plan.md`.

Repository: <https://github.com/LuchoC-Dev/little-spaceship> — **public** since 25/08/2026, when the MVP shipped, under MIT. Several parallel Claude sessions each get their own git worktree.

Six agents own different modules, so their boundaries come from the architecture rather than from goodwill. Each keeps its own memory under `.claude/agent-memory/`, and that memory records only what the agent learned that is not already written in `docs/`.
