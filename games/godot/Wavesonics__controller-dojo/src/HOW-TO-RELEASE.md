# How to release

Publishes Controller Dojo to https://stumpy-dog-studios.itch.io/controller-dojo via itch.io's `butler`.

## Tools

Neither tool is on PATH. Use the full paths:

| Tool | Path |
| --- | --- |
| Godot 4.7.1 | `%APPDATA%\itch\apps\godot\Godot_v4.7.1-stable_win64_console.exe` |
| butler 15.30.0 | `%APPDATA%\itch\broth\butler\versions\15.30.0\butler.exe` |

Use the `_console.exe` Godot variant. The plain `win64.exe` is a GUI-subsystem binary and writes nothing to stdout, so headless output comes back empty.

Check butler auth (opens a browser only if the stored credentials are stale):

```bash
"$APPDATA/itch/broth/butler/versions/15.30.0/butler.exe" login
```

## 0. Fresh clone

Two things a clone does not carry: the `.export/` subdirectories and the Android build template. `tools/setup.ps1` creates both.

```bash
powershell -ExecutionPolicy Bypass -File tools\setup.ps1
```

It is safe to re-run and does nothing it has already done. It creates the per-platform export directories, installs the Android build template if `android/build/` is missing, copies `tools/android/ControllerRumblePlugin.kt` into the template, and adds the plugin's `meta-data` entry to the template's `AndroidManifest.xml`.

Run it again after **Project > Install Android Build Template** or any use of `--install-android-build-template`, both of which overwrite the manifest. See the Android section for why that matters.

Skip it if you are only exporting for desktop or web and `.export/` already exists.

## 1. Export

Every preset writes into `.export/` at the project root, one subdirectory per platform. Keep it that way even though the desktop presets now embed their pack: the web export emits a spread of same-named sibling files, and mixing platforms in one folder makes it impossible to push a single platform's build cleanly.

Because the paths live in the presets, the export commands take no output path:

```powershell
$godot = "$env:APPDATA\itch\apps\godot\Godot_v4.7.1-stable_win64_console.exe"
$proj  = "C:\Users\adamw\Code\Test\GodotMcpTest"
& $godot --headless --path $proj --export-release "Web"
& $godot --headless --path $proj --export-release "Windows Desktop"
& $godot --headless --path $proj --export-release "Linux"
& $godot --headless --path $proj --export-release "macOS"
```

Godot will not create the output directory; a missing one fails with `Prepare Template: The given export path doesn't exist.` Only `.export/.gdignore` is committed, so the per-platform subdirectories come from step 0.

`.export/` is ignored by git, and the `.gdignore` inside it keeps Godot from scanning finished builds back into the project as resources.

The web target must be named `index.html`. itch.io serves that filename as the entry point and will not run the build otherwise.

The macOS target must be a `.zip`. Godot can only write a `.dmg` when running on macOS itself, and itch takes the zipped `.app` anyway.

Confirm every command exited 0 before pushing.

## 2. Push

```powershell
$butler = "$env:APPDATA\itch\broth\butler\versions\15.30.0\butler.exe"
$out    = "C:\Users\adamw\Code\Test\GodotMcpTest\.export"
& $butler push "$out\web" stumpy-dog-studios/controller-dojo:html5
& $butler push "$out\windows" stumpy-dog-studios/controller-dojo:windows
& $butler push "$out\linux" stumpy-dog-studios/controller-dojo:linux
& $butler push "$out\macos\ControllerTraining.zip" stumpy-dog-studios/controller-dojo:osx
```

Channel names matter. `html5` tells itch the build is playable in a browser; `windows`, `linux`, and `osx` tag the downloads for their respective platforms.

The macOS push targets the zip file rather than its directory. Pushing the directory would leave the `.app` double-zipped, and the itch app cannot unpack that into a launchable bundle.

butler diffs against the previous build, so repeat pushes upload only the delta. Expect well over 99% reuse when only game content changed.

## 3. Verify

```powershell
& "$env:APPDATA\itch\broth\butler\versions\15.30.0\butler.exe" status stumpy-dog-studios/controller-dojo
```

`∙` means still processing, `√` means live. Processing usually takes under a minute. A push can report success while `status` still shows no channel, which just means itch has not finished indexing yet.

## 4. Dashboard steps

butler cannot set these, so do them by hand on the itch edit page after the first push of a channel:

- On the html5 upload, tick **This file will be played in the browser** and set the viewport to match the project window size. Without it the game is offered as a download instead of an embedded player.
- Confirm the Windows, Linux, and macOS uploads are tagged for their platforms. They normally auto-detect from the channel name.

## Android

The Android preset uses the gradle custom build (`gradle_build/use_gradle_build=true`) rather than the prebuilt template, because controller rumble needs an Android plugin compiled into the APK. Godot's Android port has no backend for `Input.start_joy_vibration`, so those calls are dropped there; `scripts/haptics.gd` routes around it, calling the plugin on Android and the engine everywhere else.

`android/` is generated and git-ignored, so the plugin's real source lives at `tools/android/ControllerRumblePlugin.kt` and `tools/setup.ps1` installs it into the template. Edit the copy under `tools/`, never the one under `android/build/`, or the next reinstall eats the change.

The plugin reaches the template as two pieces:

| File in the template | Purpose |
| --- | --- |
| `android/build/src/main/java/com/godot/game/rumble/ControllerRumblePlugin.kt` | Drives the pad's own vibrator through `InputDevice`; copied verbatim from `tools/android/` |
| `android/build/src/main/AndroidManifest.xml` | Registers it via an `org.godotengine.plugin.v2.ControllerRumble` meta-data entry, appended to `<application>` |

Reinstalling the build template, from **Project > Install Android Build Template** or the `--install-android-build-template` flag, overwrites `src/main/AndroidManifest.xml` and drops that meta-data. The build still succeeds and the rumble goes quiet with nothing in the log to say why. Re-run `tools/setup.ps1` after any reinstall; it restores both pieces and is a no-op when they are already in place.

Keep `permissions/vibrate=true` on the preset. The vibrator is off-limits without it, whether the motor is in the phone or in the pad.

Gradle builds need a JDK 17 or newer and the Android SDK, both set in Godot's editor settings under `export/android`. The build warns `Unable to strip the following libraries`, which is the missing NDK and is harmless: it costs a little APK size and nothing else.

## Notes

`export_presets.cfg` sets `exclude_filter="godot-mcp/*"` on every preset. The `godot-mcp` checkout lives inside the project folder, and the presets use `export_filter="all_resources"`, so without that filter the entire `node_modules` tree is packed into the game. It accounts for roughly 6 MB of a 6.3 MB pack. Keep the filter on any preset added later.

Every preset sets `binary_format/embed_pck=true`, so each desktop target is a single self-contained file with the pack appended: no loose `.pck` next to the binary, and nothing to lose when a player moves the executable. macOS embeds unconditionally, inside `Contents/Resources/` of the bundle.

Toggling `embed_pck` leaves the previous export's `.pck` sitting in the output directory; Godot never cleans it up. Delete it before pushing. It is stale content shipped under the name the engine looks for, and neither outcome is one you want to debug from a player bug report.

Remaining download size is engine baseline and cannot be trimmed from the project side: `index.wasm` is about 39 MB, `ControllerTraining.exe` about 104 MB, the Linux binary about 70 MB, and the macOS zip about 58 MB (universal, so it carries both x86_64 and arm64 slices).

The macOS preset uses `codesign/codesign=1`, Godot's built-in ad-hoc signing, which is the only option that works when exporting from Windows. Ad-hoc signatures are not Apple-notarized, so Gatekeeper quarantines the download: users must right-click the app and choose **Open**, or run `xattr -dr com.apple.quarantine "Controller Training.app"`. Worth saying so on the itch page.

Linux and macOS binaries need the executable bit, which Windows filesystems do not carry. butler detects ELF and Mach-O executables and sets it in the uploaded build, so this has not needed a manual fix; verify on the first Linux and macOS release rather than assuming it.
