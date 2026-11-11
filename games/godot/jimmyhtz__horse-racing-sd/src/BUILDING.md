# Building Horse Racing 0.22.0

Use the standard Godot 4.7.2 editor, Python 3.11 or newer, and official matching export templates. No Python runtime or Godot editor is required by people installing a release. Build tooling downloads no private data and does not use saved games.

1. Clone or extract this source release.
2. Download the official Godot 4.7.2 editor for your operating system from https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable .
3. Run `python tools/prepare_templates.py` to download, verify and extract the required desktop export templates under .build/templates. To reuse the 1.28 GB archive already downloaded, pass `--archive PATH`.
4. Run `python tools/build_desktop.py --godot PATH_TO_GODOT --platform windows` (or linux, linux-arm64, macos, all). The tool builds from a disposable copy and puts packages in dist. Use `--makensis PATH_TO_MAKENSIS` with Windows to also create the full installer. NSIS 3.13 is available from https://nsis.sourceforge.io/Download .

The Windows and Linux preset uses a separate executable and PCK file. macOS exports a universal ZIP so executable permissions survive a build on Windows. macOS uses ad-hoc signing, not notarization. Paid developer signing credentials are not part of this repository.

The source build configuration never contains a personal filesystem path. Export include filters retain JSON help/data and the Windows speech script. Player SVGs load as imported textures. Each package uses a new temporary payload folder, so unrelated files left in dist cannot enter it. Build outputs omit developer tests, local logs and saved games.

On macOS, the build tool copies the editor bundle into temporary storage and uses its self-contained editor mode. It refuses to build in an ordinary account that already contains game data, because the editor also touches a project recovery-lock file. The CI startup script refuses to run on an ordinary Mac account because macOS does not honor the Windows and Linux data-location variables. Its packaged startup check is restricted to a disposable GitHub-hosted runner with no existing game data. Use a separate operating-system account for manual native Mac building and testing.

## Tests

Use isolated data folders, for example by setting APPDATA on Windows or XDG_DATA_HOME and XDG_CONFIG_HOME on Linux to a disposable test folder. Run `godot --headless --path . --script tests/help_release_tests.gd` and `godot --headless --path . --script tests/settings_layout_tests.gd`. The CI workflow runs these on each supported runner, exports its native package, and starts the exported game headlessly.

Windows-only `tests/release_portability_tests.gd` validates packaged speech-worker staging, errors, cleanup and synthesis. A graphical audio test is `tests/clip_speech_smoke.gd`. Tests that require real system voices or a display are separate from headless CI. Headless startup does not prove audible speech or interactive layout quality.

The established probability/payback checks are in tests/test_payback_math.py and tools/payback_v2. A release containing only help and packaging changes need not recalibrate an unchanged movement model. Changes to that model must rerun its relevant mathematical and simulation checks.

## Release maintenance

Build from a clean source tree, verify platform packages and public contents, then tag the commit. Publish the installer, platform archives, matching source ZIP, and SHA256SUMS.txt together. Never publish .build, runtime, diagnostic logs, saved games, PINs, or speech cache files. The shipped LICENSE and third-party notices must stay with binaries and source.
