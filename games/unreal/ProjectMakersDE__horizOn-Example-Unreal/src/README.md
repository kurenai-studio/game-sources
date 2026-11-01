# Seagull Storm / Unreal

A compact coastal survival game and C++ reference for the horizOn SDK. Move the
square-headed seagull, collect shells, choose weapon upgrades and survive the
three-minute tide before defeating the octopus. Progress buys speed, damage,
health and magnet upgrades for the next run.

The refresh includes shared cel-shaded artwork, horizOn charcoal/cream/orange/teal
styling, readable default engine fonts, charcoal HUD backing, viewport-fitting
title/SDK panels, immediate first waves, auto-aimed feathers, visible poison hazards,
healing drops every twelve kills and queued upgrade choices. The original atlas
files remain available for compatibility.

The gull and crab have separate cutout limbs and body parts from the accepted
October 3 animation mockup. After editor import, actor-driven idle, movement,
attack and hurt poses rotate those parts around their original pivots. Original
full-image flipbooks are hidden while the complete rig is available. Actor
collision, movement and 44/38-unit full-canvas widths stay unchanged.
Moving feet/legs retain their walk cycle during auto-fire wing/claw attacks.

**Unreal readiness:** the project targets Unreal 5.8.3. The native editor target,
asset bootstrap and a rendered standalone editor-game run have passed on macOS
arm64 with Xcode 26.6 and the Metal Toolchain. Imported maps, sprites, flipbooks,
materials and audio are committed alongside their original source assets.
The universal Mac Development package (arm64+x64) built, cooked and archived
successfully. Its actual arm64 game/Player-Values and Hello runs passed; the game
also passed at 960×540. There are 31 rendered package captures. The two game runs
have one expected deliberate HTTP503 retry warning each, zero errors, and zero
skips; Hello has zero warnings/errors. The runs use synthetic loopback fixtures,
not a real Develop or production backend.

## Start

1. Open `SeagullStorm.uproject` in Unreal **5.8** and compile `SeagullStormEditor`.
   The imported map, sprites, flipbooks, materials and audio are already included.
2. Open `/Game/Maps/MainMap` and press Play.
3. Select **Play offline practice**. No backend or account is required for this
   game flow. Practice progress is stored at `Saved/SeagullStorm/practice.json`.

For online examples, configure your own app's API key in the horizOn settings or
an untracked local configuration. `Config/DefaultGame.ini` deliberately retains
`YOUR_API_KEY`. Use a dedicated QA app/player when testing SDK writes. Never
commit a real key, password or session token.

| Control | Action |
|---|---|
| WASD / arrows / gamepad left stick | Move |
| Automatic | Fire feathers at nearby enemies; unlocked weapons fire on cooldown |
| Mouse | Menus and upgrade cards |
| Escape / gamepad Start / Pause button | Pause |

## Official embedded SDK

`Plugins/HorizonSDK` is the complete, unmodified official develop snapshot
`a3ff3cc5075b0d3644473fa69b6a31b18cbe7e8a` (descriptor version 1.6.0).
It includes Player Values, Statistics, Realtime, Validated Actions and the native
unity-build correction. This is an explicitly pinned develop source snapshot;
no release was created. `SDK-SOURCE.json` records all 181 official files and hashes.
The descriptor is the version string carried by that snapshot, not a released tag.
The optional asset regeneration steps are in [EDITOR_SETUP.md](EDITOR_SETUP.md).

The example enables `HORIZON_WITH_VALIDATED_ACTIONS=1`. The release synchronization
workflow replaces the entire plugin on future SDK releases. Example configuration
lives outside the plugin and is preserved.

## Run and save boundaries

- **Practice:** no ticket request, score submission or cloud-save write. Local
  progression is separate from signed-in progression. Practice resets gameplay
  configuration to local defaults.
- **Online validation:** the arena and run clock start after the ticket and server
  seed arrive. The HUD shows that the result is pending. Game over displays server
  acceptance, refusal or connection failure. Failed ticket acquisition starts a
  practice run and never falls back to ordinary score submission.
- **Ordinary boards:** `validated_runs_enabled=false` explicitly selects the
  ordinary SDK score path. Its result is labeled as unvalidated. A validated-only
  board can reject this request with `VALIDATED_SUBMIT_REQUIRED`.
- **Cloud Save:** loads and writes use the signed-in player's session. A failed
  download does not overwrite old cloud progress with defaults. Newly created
  players may initialize a new cloud save. Restored players require a successful
  load before writes; the SDK currently reports both missing saves and transport
  errors through the same `false` callback, so this case stays read-only.
- Purchases and gifts wait for loaded progress. Purchases, manual saves, gifts and
  run-end snapshots are written in order for their original owner. Gift coin
  rewards require an explicit positive whole `coins` value; cosmetic-only gifts
  do not manufacture coins.
- Late callbacks cannot overwrite a newer run or an explicit practice choice.
  Authentication uses a persistent gate across title widgets; a pending request
  must finish before another begins. Sign-out clears a late authentication result.
  Cloud/config loads and gift callbacks carry the original session generation and
  owner. Cloud loads are discarded if gameplay has begun.

The input evidence format is shared with Unity/Godot: a version byte, little-endian
seed and tick-delta events for movement, upgrade choices and run end, capped at
32 KiB. Truncated logs are not submitted. This records client input; physics,
frame timing, active balance configuration and persistent upgrades are not a
complete deterministic replay. Server rule validation and evidence acceptance
do not establish authoritative replay verification.

When requested by the server, the official SDK uploads the same input bytes as
evidence. The SDK tools panel shows the upload outcome independently of score
acceptance. Earned server-owned values are sent only when configured rules define
`coins`; the read-only balances panel shows server values separately from client
progression coins.

## SDK coverage

The hub's **SDK tools** panel exposes optional operations with pending/success/error
states. Read-only demonstrations do not manufacture server configuration. Empty
catalogs, unsupported capabilities and unranked players have visible outcomes.

| Feature | Integration / visible entry point |
|---|---|
| Connection | Startup connection and configured app hosts; local practice remains available |
| Authentication | Guest signup, email signup/sign-in, session restore and sign-out; Apple native flow on iOS |
| Remote Config | Hub loads gameplay/upgrade settings; practice uses complete local defaults |
| Cloud Save | Session-bound hub load and run-end save; explicit Save progress in SDK tools |
| Leaderboards | Board list including validated-only flag, selected board key, fresh Top 10, neighbors and own rank |
| Validated Actions | Run ticket/seed, rule-checked submit, server state and automatic evidence-upload outcome |
| Player Profile | Read current avatar/frame/badges and cosmetics catalog; select an available avatar while preserving other slots |
| Localization | SDK tools fetch English/German strings and display returned keys; game UI itself remains English |
| News | Hub and pause menu display app news |
| Player Values | Separate hub panel: explicit balances/offers, confirmed-price purchase, signed adjustment and original-operation retry |
| Gift Codes | Explicit validation/redeem panel; unavailable in practice |
| Feedback | Explicit category/title/message form; unavailable in practice |
| User Logs / Crash Reporting | Online run summaries, balancing warnings, breadcrumbs, custom keys and handled failures; no deliberate crash |
| Email Sending | Explicit template-slug field and **Send template to my account**; requires an email account and configured app template |

Google's authorization-code acquisition flow is not implemented in this desktop
example; the unused Google button is hidden. Apple sign-in is exposed only on iOS.
Email sending never happens automatically and was not exercised during this
refresh. Template variables are empty in this minimal demonstration.

## Remote Config

All settings have offline defaults. These existing keys control the ranked flow:

| Key | Default | Behavior |
|---|---|---|
| `validated_runs_enabled` | `true` | Request a ticket and submit through Validated Actions |
| `validated_runs_board` | `default` | Board key shared by run tickets, score submissions and leaderboard reads |
| `validated_runs_send_coins` | `false` | Send earned `coins` only with configured server value rules |
| `run_duration_seconds` | `180` | Survival phase duration |
| `boss_wave_enabled` | `true` | Spawn octopus after the survival phase |
| `wave_interval_seconds` | `15` | Subsequent wave cadence; first wave starts immediately |
| `wave_enemy_count_base` | `5` | Initial enemy count |
| `wave_enemy_count_growth` | `1.3` | Wave growth, capped at 80 spawns per wave |

Enemy, weapon, upgrade and card keys are defined in
`Source/SeagullStorm/Data/SeagullConfigCache.cpp`. Server rules can use stages
`wave_N`; configure those stages before expecting stage-based validation to pass.
The example never creates backend boards, rules, templates, cosmetics or data.

## Player statistics

Create these definitions in the project's Dashboard before using the statistics demonstration:

| Key | Mode | Reset |
| --- | --- | --- |
| `kills` | `sum` | `none` |
| `rounds` | `sum` | `none` |
| `best_score` | `max` | `none` |

Each completed online round sends its actual kills, one round and its final score in one atomic statistics batch. The Statistics button opens the complete server snapshot with explicit Refresh and Retry Original actions. The game persists an unsent draft before loading server time, then assigns one operation ID before the first POST. A restart, timeout, conflict or `OPERATION_EXPIRED` retains the original ID and payload. An unresolved original blocks another online round; local Practice remains available. Reads and startup never book saved round batches.

`ASeagullStatisticsHelloActor` provides a standalone Hello variant on a level using `GameModeBase`. It connects/restores or signs up once, submits the existing example score and displays the statistics panel. Its demonstration button explicitly submits `kills=3`, `rounds=1`, `best_score=1200`. It never posts a saved statistics batch merely because the level starts.

The game facade uses the official SDK's example identity guard. It preserves a project-scoped guest and a durable unknown-signup marker before HTTP; a failed restore never falls back to a new guest. Explicit Guest selects the protected guest ahead of an email cache. Unvalidated legacy credentials are backed up without assigning them to the current project. All embedded plugin files remain byte-identical to the official commit in `SDK-SOURCE.json`.

## Verification

Engine-independent checks:

```sh
python3 Scripts/verify_project.py
python3 Tests/run_cutout_pose_test.py
python3 Tests/run_input_log_test.py
python3 Tests/run_session_boundary_test.py
python3 Tests/run_sdk_contracts.py --sdk-source /path/to/horizOn-SDK-Unreal
```

The input-log check compiles the real example implementation against a small
array boundary. The SDK runner loads fixtures from the exact official commit in
`SDK-SOURCE.json`, including statistics and player-value contracts. The session-boundary check compiles
the real facade methods against delayed SDK boundaries and verifies auth/practice/
sign-out races, stale config/save reads, preload purchase gates, ordered owner-bound
writes, ticket serialization and synchronous/stale evidence events. The original checks passed on
October 2, 2026; the TASK-1005 changes are verified separately by the current CI and native reports. These checks make no backend calls and do not compile Unreal game
modules, reflection or Slate widgets.

The October 3 cutout check compiles the production pose math and checks the
accepted manifest's pivots/layers, gait amplitudes, wing/claw attacks, hurt
priority, paused clocks and facing. It verifies canvas x-right/y-down maps into
arena x-right/y-up and clockwise angles become negative world yaw. The renderer
maps Paper2D local X to world X and local Z to world Y, then mirrors the whole
rig parent. Integrity checks verify all 16 part PNG hashes, RGBA/full-canvas
dimensions and the separate shadow. These passed locally, without native Unreal.

The native acceptance runner starts an isolated synthetic HTTP fixture on
127.0.0.1, creates a fresh Unreal user directory, checks the actual automation
report and HTTP operation IDs, and stops both owned processes. It never reads a
real API key. Use a fresh output directory for each run:

```sh
python3 Scripts/run_native_acceptance.py --editor /path/to/UnrealEditor --output /tmp/seagull-game-proof
python3 Scripts/run_native_acceptance.py --editor /path/to/UnrealEditor --hello --output /tmp/seagull-hello-proof
python3 Scripts/run_native_acceptance.py --editor /path/to/UnrealEditor --statistics --port 18813 --output /tmp/seagull-statistics-proof
python3 Scripts/run_native_acceptance.py --editor /path/to/UnrealEditor --statistics --hello --port 18813 --output /tmp/seagull-statistics-hello-proof
```

Use `--game /path/to/SeagullStorm` for a packaged Development executable. The
runner keeps Mac App Sandbox enabled, uses a unique private container subfolder,
copies its evidence out and removes only that owned subfolder. Add
`--width 960 --height 540` for the smaller viewport, or
`--headless` for a separate NullRHI check. Rendered runs capture the actual game
viewport; NullRHI does not provide visual evidence. The game check covers title,
practice, movement, cutout assets, pause, XP choice, death, restart, timer/boss
victory (accelerated timer and deterministic boss damage/position for QA) and the Player Values flow. The Hello check spawns the unchanged official
`AHelloHorizonActor` in a base GameMode and verifies connect, anonymous signup,
score submission and its visible completion. These are loopback integration
proofs, separate from real Develop or production service acceptance.

## Player Values

The hub's **Player Values** panel uses the SDK's typed snapshots. Practice remains
local. Online balances never use local progression coins and are replaced from
authorized server state, with no client-side delta credit. Refresh offers before
purchasing; a changed definition/price requires another explicit confirmation.

A purchase/adjustment first persists its exact payload, quoted catalog version and operation ID in a
project/player-bound SaveGame slot. Regional hosts share that stable identity.
An unknown result, timeout or refusal keeps the original intent; **Retry original**
refreshes current offers and resends that same ID and payload. Changed catalog
terms require another explicit confirmation. The server currently books the offer
configured when it handles the write; the API has no atomic quoted-version
precondition, so an admin change between refresh and POST can still change its
price. No new operation can overtake the saved original. Corrupt or
conflicting saved data blocks a new write and is retained for recovery. Only a
confirmed successful original operation removes its saved intent. Session,
project, host, practice and widget generations fence late callbacks.

The native fixture deliberately commits the purchase and loses both initial
receipts. Explicit retry receives the replay: gold ends at 93 and energy at 10,
The retry catalog then changes to a cost of 9 and requires fresh confirmation;
the committed original still replays its original cost of 7. A separate -1
adjustment ends at 9. The immutable saved file and conflicting-payload guard are
checked before retry. Exactly one purchase ID is used across
all three transport attempts.

## Assets and license

New shared artwork was generated through OpenRouter with
`google/gemini-2.5-flash-image` on October 2, 2026. Its transparent sprite backgrounds
were keyed into true RGBA and visually inspected; the arena is opaque.
`Content/Textures/asset-manifest.json` records provenance and file hashes.

`Content/Textures/Cutout/rig.json` records the accepted mockup's 16 part PNGs,
custom pivots, ordered layers and separate shadow. Limbs and closed body surfaces
were rebuilt from its vector paths. The gull head is clipped from the original
shared artwork. These are cutout parts animated in code.

Code: [MIT](LICENSE). Font and artwork provenance: [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
