# Independent release review

Reviewed 2026-11-10 with Godot **4.5.1**, by a Codex agent that did not author the gameplay implementation. Scope: `gameplay.gd`, `game_rules.gd`, automated gameplay tests, export configuration, shipped asset inventory, and captured gameplay. This review intentionally did not claim an independent review of the reviewer's own UI code.

## Findings

### R1 — Include font licenses in downloadable builds (release packaging)

The initial Web PCK contained both imported Barlow fonts but no OFL license text. The source repository contains those licenses; `export_filter="all_resources"` with an empty `include_filter` omits non-resource text files from standalone builds. Include `LICENSE,assets/fonts/OFL-*.txt` in each export preset, rebuild, and confirm those files are in the exported resource inventory. This is a redistribution packaging correction, not a gameplay defect.

### R2 — Landmark sprite can disappear prematurely near viewport edge (minor visual issue)

The generated Congress sprite is 192×160 and draws at a width of 324.8 world pixels. Its top extends approximately 203 pixels above its world origin, while object-center culling grows the viewport rectangle by only 160 pixels. The top can therefore disappear with up to 43 world pixels still visible when its origin passes below the viewport. Use a conservative margin large enough for the largest sprite or intersect the actual sprite bounds. This does not affect collision or scoring.

### R3 — Refresh captured media after UI fixes (delivery accuracy)

At review time `docs/media/gameplay.png` still showed the earlier `44x COMBO` label and score caption, although the current UI had corrected the multiplier display. Regenerate media from the final build so screenshots and GIFs represent the delivered behavior.

The lead integrator owns fixes and their final regression verification; review findings are recorded here without editing implementation.

## Executed validation

- `tools/validate.sh`: passed Godot import, rules regression, **22 integration assertions**, **12 complete 90-second simulation rounds**, and the main-scene smoke test.
- All 12 combinations of three candidates and four deterministic seeds completed, reached level 6, and absorbed all 192 available objects through normal acceleration, collision, capture, growth, and scoring rules.
- Independently enumerated the actual `build/web/index.pck` through Godot's resource filesystem. All **nine PixelLab images**, both fonts, main scene, and four runtime scripts were present. Tests, capture script, tools, and documentation were absent.
- Inspected the actual gameplay screenshot and capture metadata. The media is an authentic Godot viewport capture driven by autonomous movement; it is not a mock-up or a claim of human playtesting.
- Re-ran CPU simulation profiling: ordinary round p95 **103 μs** per physics step, maximum-radius scenario p95 **118 μs** on this host. This excludes rendering, audio device cost, browser overhead, and mobile GPU performance.

## Gameplay and security assessment

No blocking gameplay or security defect was found in the reviewed implementation. Captured objects transition out of the available state before scoring, preventing duplicate capture. The terminal transition sets `active=false` before emitting results, and tests verify it emits only once. Pausing freezes time, growth animation, input, and sinks. Touch ownership, unrelated-finger release, canceled touch, and focus loss have explicit regression coverage. Oversized objects reject overlap, and the world boundary is enforced after collision resolution.

The world and object count are bounded. Spatial buckets limit collision/capture candidate checks; visual effects expire. Runtime scripts contain no network request, shell execution, credential access, or telemetry functionality. Android's Internet and network-state permissions are disabled. Capture tooling is excluded from exports.

## Limits and remaining device checks

The integration tests inject touch events into gameplay handlers and validate actual simulation behavior. They do **not** prove operating-system touch delivery, safe-area behavior, or complete GUI event propagation on an Android/iOS device. Complete the checklist in [MOBILE.md](MOBILE.md) on physical hardware before claiming device certification. Autonomous rounds prove reachability and progression; they do not substitute for human difficulty or usability testing.

Android export success and desktop simulation performance must not be described as physical-device frame-rate validation. iOS signing and device deployment require the corresponding Apple toolchain and credentials.

## Integration fixes

R1: all export presets explicitly include root LICENSE and bundled OFL texts, with readable copies also packaged beside Linux/Web builds. R2: sprite culling margin increased from 160 to 280 world pixels, covering the full Congress image. R3: media recaptured after the corrected HUD/mute/layout implementation; final release evidence is in `docs/media`. The lead reran the full validation suite, including 37 rendered UI checks, successfully.
