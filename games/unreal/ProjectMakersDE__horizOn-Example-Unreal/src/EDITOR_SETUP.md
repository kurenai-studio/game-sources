# Unreal 5.8 editor setup

The project has been compiled and imported with Unreal 5.8.3 on macOS. Imported
`.umap`/`.uasset` files are included. Source PNG/OGG assets and the idempotent
bootstrap remain available to regenerate deliberately removed assets. See the
README for the native acceptance runner and exact verification boundaries.

## Bootstrap

1. Open `SeagullStorm.uproject` in Unreal **5.8**. Compile the editor target with the
   platform's normal C++ toolchain (Xcode on Mac, Visual Studio on Windows).
2. Confirm Paper2D, Python Editor Script Plugin and Editor Scripting Utilities are
   enabled. The `.uproject` enables the scripting plugins for editor targets only.
3. Save unrelated unsaved editor work before running the setup script: creating a
   new map closes the current level. Choose **Tools > Execute Python Script** and
   select `Scripts/setup_editor_assets.py`.
4. The script imports the nine shared PNGs into `/Game/Textures`, creates correctly
   scaled sprites under `/Game/Sprites`, creates the canonical one-frame flipbooks
   under `/Game/Flipbooks`, imports the fourteen audio files and creates the unlit
   fallback arena-color material and `/Game/Maps/MainMap`. It also imports the
   16 cutout parts and separate shadow from `Content/Textures/Cutout/` into
   `/Game/Textures/Cutout/`, creating custom-pivot sprites in
   `/Game/Sprites/Cutout/` from `rig.json`.
5. Restart the editor. Asset lookups in C++ constructors cache missing files until
   the next editor process. Open `/Game/Maps/MainMap`, press Play and select
   **Play offline practice**. An API key is optional for this flow.

The script reuses existing assets and maps. It will not silently replace manual
editor changes. To regenerate an asset deliberately, remove that generated asset
in the editor and rerun the script. All source PNG/OGG files remain intact.

The gull and crab use seven and nine independent cutout parts. The C++ rig
rotates limbs and body poses for idle, movement, attack and hurt. Weapon firing
triggers gull attacks, health loss triggers hurt, and crab contact attacks/hits
trigger claw/hurt poses. Pause stops the actor-driven animation clock. Moving
feet/legs keep their global gait phase during upper-body attacks. Parts and
shadow are owned by the actor and removed during teardown. The original full
flipbook is hidden and stopped once all rig sprites resolve. Missing imported
parts retain the original fallback image.

Cutout sprites use full-canvas images, source-pixel custom pivots, bilinear
filtering, clamp addressing, retained alpha, no mipmaps and masked unlit material.
The shadow uses translucent unlit material and stays beneath the rig. Part Z
offsets increase in manifest order. Paper2D local X/Z are explicitly mapped to
arena X/Y. Source Y is negated and clockwise source angles become negative world
yaw. Facing mirrors the complete parent including every pivot and translation.
Canvas centers remain at actor centers. The gull/crab widths remain 44/38 units.
The octopus remains 86 units and other foes 38–42 units.

## Canonical assets

| Sprite | Source PNG | Flipbooks |
|---|---|---|
| `SP_Seagull` | `seagull_hero.png` | `FB_Seagull_Idle`, `Walk`, `Hurt`, `Death` |
| `SP_Crab` | `enemy_crab.png` | `FB_Crab_Walk`, `Death` |
| `SP_Jellyfish` | `enemy_jellyfish.png` | `FB_Jellyfish_Idle`, `Death` |
| `SP_Pirate` | `enemy_pirate.png` | `FB_Pirate_Walk`, `Death` |
| `SP_Boss` | `enemy_octopus.png` | `FB_Boss_Idle`, `Death` |
| `SP_XPShell` | `pickup_shell.png` | `FB_XPShell` |
| `SP_Coin` | `pickup_coin.png` | `FB_Coin` |
| `SP_Health` | `pickup_heart.png` | `FB_Health` |
| `SP_Feather` | legacy `weapons.png`, first 32×32 cell | `FB_Feather` |
| `SP_Arena` | `arena_background.png` | Used directly by the map generator |

Cutout assets are named `/Game/Sprites/Cutout/SP_Cutout_gull_<part>` and
`SP_Cutout_crab_<part>` for each manifest part, plus `SP_Cutout_shadow`.
They do not need flipbooks. Preserve their custom pivots when importing manually.
The packaging config always cooks `/Game/Sprites` (including Cutout), `/Game/Flipbooks`,
`/Game/Materials`, `/Game/Audio`, MainMap and their dependencies,
since the C++ rig resolves these assets at BeginPlay.

If the script reports a Python API/import error, keep the source files and use
Unreal's ordinary texture import, **Create Sprite** and **Create Flipbook** actions
at these exact paths. Confirm RGBA, bilinear filter, no mipmaps, centered pivots,
no sprite collision and `/Paper2D/MaskedUnlitSpriteMaterial`. Sphere components
provide gameplay collision. Do not call the bootstrap verified until its output
has been opened and played in the engine.

The script follows Epic's published APIs:
[PaperSprite](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/PaperSprite?application_version=5.5),
[Texture2D](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/Texture2D?application_version=5.5),
[PaperSpriteFactory](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/PaperSpriteFactory?application_version=5.5),
[PaperFlipbookKeyFrame](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/PaperFlipbookKeyFrame?application_version=5.5),
[LevelEditorSubsystem](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/LevelEditorSubsystem?application_version=5.5).
The bootstrap has executed successfully in the actual 5.8 editor commandlet.

## Native acceptance checks

- Compile `SeagullStormEditor`; inspect import output and asset sizing/orientation.
- Verify gull wings/feet/head and crab legs/claws animate without frozen duplicate
  limbs, move/idle settle correctly, attack/hurt events trigger, facing survives
  vertical movement, and every part/shadow disappears after restart or teardown.
  Check front/rear layer order, alpha edges, pause/resume and unchanged collision.
- Play practice from a fresh clone/config placeholder, move with WASD/arrows, pause
  and resume, collect XP, choose queued cards, heal, die and retry.
- Play through the survival timer and octopus fight; verify poison circles are
  visible and disappear when the run is cleaned up.
- Restart and confirm practice upgrades/highscore persist locally.
- Configure a dedicated QA app and player; verify ticket-before-clock, accepted
  submit, rank/board/around/state/profile reads and rejected/unavailable outcomes.
- Verify cloud progress cannot be overwritten after a failed load. The official
  SDK conflates absent save and network failure; new signups initialize safely,
  existing users require a successful load.
- Delay authentication, switch to practice, then retry another login; repeat with
  sign-out. Delay initial cloud/config reads and attempt a purchase/gift. Verify
  owner changes discard old responses and purchase/gift/manual/run save snapshots
  arrive in order. Test a cosmetic-only gift and a valid coin gift separately.
- Verify dark HUD backing, readable font, status wrapping and pause hit testing
  at 1280×720 and a smaller viewport. Source-only layout changes are not a native
  visual verification.
- Run optional gift, feedback and email actions only when deliberately selected;
  no email or production write was performed during this refresh.
- Package and run a standalone build, then commit generated `.uasset`/`.umap`
  files if the native checks succeed. Font/PNG loose-file staging is configured.

## Reproduce the Mac Development package

Use the real Xcode/Metal toolchain and include the explicit `-package` step:

```sh
"/path/to/UE/Engine/Build/BatchFiles/RunUAT.sh" BuildCookRun \
  -project="$PWD/SeagullStorm.uproject" -noP4 -platform=Mac \
  -clientconfig=Development -clientarchitecture=arm64+x64 -editorarchitecture=arm64 \
  -build -cook -stage -pak -package -archive \
  -archivedirectory="$PWD/Build/MacQA" -ubtargs=-NoUBA -unattended
```

`-package` finalizes the self-contained app with its engine/runtime libraries;
archiving the bare build app alone is insufficient. `-NoUBA` uses the native
compiler/linker directly and avoids a local build-accelerator link hang. The
Development receipt stages Unreal's automation report template; Shipping does
not include that QA template.

Run `Scripts/run_native_acceptance.py --game Build/MacQA/SeagullStorm.app/Contents/MacOS/SeagullStorm --output /tmp/seagull-package-proof`
with a fresh output directory, then repeat with `--hello` and a separate output.
The recorded 2026-10-16 checks built both Mac architectures and executed arm64
with Metal at 1280×720 and 960×540, including imported assets and fonts. Native
reports contain the actual tests, their errors/warnings and all HTTP-fixture
receipts; NullRHI or source-only CI does not replace these rendered checks.


For the TASK-1005 statistics round and standalone Hello checks, repeat the native
runner with `--statistics --port 18813`, adding `--hello` for the Hello variant.
Use a new report directory each time. The strict local fixture deliberately sets
server operation time two days behind local UTC, loses the first committed
receipt, and expires a later original. It checks one three-counter batch,
unchanged operation IDs, explicit replay and full server-state replacement.
The native test also checks a persisted unassigned draft across a reload and
refuses replacing its finalized operation ID. These are synthetic local proofs;
real Cloud and simpleServer runtime acceptance is tracked separately.
