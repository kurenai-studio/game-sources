# Validation and capture

Use Godot **4.5.1**, Bash, GNU `timeout`, and Xvfb (`xvfb-run`). FFmpeg is additionally required to recreate the GIF. Set `GODOT_BIN` if Godot is not on `PATH`:

```sh
GODOT_BIN=/path/to/Godot_v4.5.1-stable_linux.x86_64 bash tools/validate.sh
```

The same validation runs in [GitHub Actions](../.github/workflows/validate.yml). The workflow downloads the official Godot archive and verifies a pinned SHA-512 checksum. Script errors, engine errors, and assertion failures fail validation even when Godot returns exit code zero.

## Automated coverage

| Check | What it verifies | Observed result |
| --- | --- | --- |
| Headless editor import | Scene, script, and asset import | Pass |
| `test_rules.gd` | Absorption thresholds, growth, combo scoring, bounds, candidate tuning | Pass |
| `test_integration.gd` | Real movement, touch release/cancel, focus loss, collision, absorption, pause, timer, replay | 22 checks, zero failures |
| `test_playthrough.gd` | Three candidates × four deterministic seeds, full 90-second rounds | 12 rounds, zero failures; all reach level 6 and absorb 192 props |
| Main scene smoke | Startup and 180 headless frames | Pass |
| `test_ui.gd` under Xvfb | Native touch button activation, saved settings, mute, pause, responsive scroll reachability | 37 checks, zero failures |

UI tests run with a rendering display because headless input emulation does not reproduce native touch-to-button dispatch. They test 360×640, 960×540, and 540×960 window sizes, restore the original settings file after testing, and verify that primary actions can be scrolled into view. These tests do not certify real touchscreen hardware or display cutouts.

Xvfb/Mesa may print X input method or V-Sync warnings. A rendered UI shutdown can also report an `AudioStreamGeneratorPlayback` ObjectDB leak warning after rapid scene destruction; this has not caused behavioral failures and remains a cleanup limitation. The normal headless gameplay tests exit without that warning. Do not interpret software-rendered test timings as phone performance.

## CPU simulation profile

```sh
godot --headless --path . --script tests/profile_simulation.gd -- --report=docs/performance.json
```

The profile runs 5,401 physics steps for an ordinary round and a maximum-radius scenario. It reports mean, median, 95th percentile, maximum step duration, static memory change, and final game statistics. [Recorded measurements](performance.json) exclude rendering and GPU work. See the [independent review](QA_REVIEW.md) for findings and their fixes.

## Authentic screenshots and GIF

```sh
GODOT_BIN=/path/to/godot bash tools/capture.sh
```

This starts the real main scene, captures menu and character selection, plays a seeded round through ordinary movement and absorption, captures pause, resumes, and waits for the genuine results screen. It never injects score or growth. The capture helper saves actual viewport images and a 14-second frame sequence; FFmpeg reduces that sequence to a 270-pixel-wide, 10-fps GIF with a 96-color palette.

The checked-in images live in `docs/media/`; `capture.json` records the engine, source frame rate, frame count, and final real round statistics. The GIF has 140 frames and is approximately 4.2 MB. For raw output without overwriting the checked-in images:

```sh
xvfb-run -a -s "-screen 0 1280x1280x24" godot --path . --rendering-method gl_compatibility \
  --audio-driver Dummy --fixed-fps 30 --script scripts/capture.gd \
  -- --output=/tmp/buraco-capture
```

## Device checks

Linux and Android export configuration is included. Build validation is separate from gameplay validation and from installation on hardware. Follow [MOBILE.md](MOBILE.md) for Android/iOS setup and the physical-device checklist. No iOS build, signing, store review, or real-device performance is claimed by these automated checks.
