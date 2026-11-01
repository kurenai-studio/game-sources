# SumUp

A number merge puzzle game for Android, built with Godot 4. Endless mode, boosters paid with score, built in skins, fully offline.

The game itself sends and receives nothing. The one link out is the Buy me a coffee button, which opens a web page in the phone's browser.

## Engine

- Godot 4.7.2 stable, exact build `4.7.2.stable.official.ed1daf0bf`. Use the standard build, not the .NET build.
- Compatibility renderer, GDScript only (statically typed)

## Run the tests

From the repo root, in a Bash shell (Git Bash on Windows):

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd
```

The first command builds Godot's class cache and is only needed after a fresh clone. The test run exits with code 0 when every test passes.

In PowerShell, pipe Godot's output, or PowerShell will not wait for Godot or report its exit code:

```powershell
godot --headless --path . --script res://tests/run_tests.gd | Out-Host; $LASTEXITCODE
```

## Build for Android

### What a fresh Windows machine needs

Do these once. The commands are for PowerShell.

1. **Git for Windows**, which also gives you Git Bash:
   `winget install --id Git.Git -e`
2. **Godot 4.7.2**:
   `winget install --id GodotEngine.GodotEngine --version 4.7.2 -e`
   Open a new terminal afterwards. `godot --version` must print `4.7.2.stable.official.ed1daf0bf`. If you install Godot another way, either put it on PATH as `godot` or set the `GODOT` environment variable to the full path of the Godot exe; the build scripts use it.
3. **Godot export templates 4.7.2.** Start Godot, open Editor > Manage Export Templates, and click Download and Install. They must be the same version as the editor. They end up in `%APPDATA%\Godot\export_templates\4.7.2.stable`.
4. **JDK 17** (Eclipse Temurin):
   `winget install --id EclipseAdoptium.Temurin.17.JDK -e`
5. **Android SDK in `C:\Android\Sdk`** with Platform-Tools, Build-Tools 35.0.1 and Platform 35:
   - From https://developer.android.com/studio download "Command line tools only" for Windows. Unzip it and move what is inside its `cmdline-tools` folder to `C:\Android\Sdk\cmdline-tools\latest`, so that `C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat` exists.
   - Then run:
     ```powershell
     C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=C:\Android\Sdk "platform-tools" "build-tools;35.0.1" "platforms;android-35"
     C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=C:\Android\Sdk --licenses
     ```
   - Android Studio's SDK Manager works too, as long as the SDK location is `C:\Android\Sdk`.
   - The NDK and CMake are not needed. Godot only uses them for Gradle builds, and this project uses Godot's prebuilt Android template.
6. **Point Godot at the JDK and the SDK.** Open the project in the Godot editor (`godot -e --path .` from the repo root). In Editor > Editor Settings > Export > Android, set:
   - Java SDK Path: the JDK folder, for example `C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot`
   - Android SDK Path: `C:\Android\Sdk`
7. **Debug keystore.** Once the Java SDK Path is set, Godot creates a debug keystore at `%APPDATA%\Godot\keystores\debug.keystore` and fills in Debug Keystore, Debug Keystore User (`androiddebugkey`) and Debug Keystore Pass (`android`) on the same settings page. Check that those three are filled in. If they are empty, make the keystore yourself and fill them in:
   ```powershell
   New-Item -ItemType Directory -Force "$env:APPDATA\Godot\keystores"
   keytool -genkeypair -v -keystore "$env:APPDATA\Godot\keystores\debug.keystore" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
   ```
   The keystore lives outside the repo and must never be copied into it. `.gitignore` refuses keystore and key files.

### Build the debug APK

From the repo root:

| Shell | Command |
|---|---|
| PowerShell | `powershell -ExecutionPolicy Bypass -File scripts\build.ps1` |
| Git Bash | `scripts/build.sh` |

The script checks the Godot version, imports the project, then runs:

```bash
godot --headless --path . --export-debug "Android" build/sumup-debug.apk
```

The result is `build/sumup-debug.apk`, about 55 MB. With only Build-Tools 35.0.1 installed, Godot prints "Could not find version of build tools that matches Target SDK, using 35.0.1" along the way. That is expected: the export targets Android 16 (SDK 36) and signs with Build-Tools 35.0.1. If Build-Tools 36 is installed too, Godot signs with that and the message does not appear.

The launcher icon PNGs in `launcher/` are drawn by `tools/launcher_icon.gd` and committed, so a normal build does not redraw them. To redraw them first (after a change to the Gumdrop colors, tile radius, lip or tile font), add `-Icons` (PowerShell) or `--icons` (Git Bash). The icon tool opens a window for a moment and closes by itself. The build also redraws them if one of the four PNGs is missing.

### Install on a phone

Turn on USB debugging once:

1. On the phone, open Settings > About phone and tap Build number seven times. On Samsung phones it is Settings > About phone > Software information > Build number. Enter your PIN if asked.
2. Open Developer options (Settings > System > Developer options, or Settings > Developer options on Samsung) and turn on USB debugging.
3. Connect the phone to the computer with a USB data cable. When the phone asks "Allow USB debugging?", tick "Always allow from this computer" and tap Allow.

Then, from the repo root:

| Shell | Command |
|---|---|
| PowerShell | `powershell -ExecutionPolicy Bypass -File scripts\install.ps1` |
| Git Bash | `scripts/install.sh` |

The script checks that one phone is connected and ready, then runs:

```powershell
C:\Android\Sdk\platform-tools\adb.exe install -r build\sumup-debug.apk
```

`-r` replaces an installed copy and keeps its saved game. The script says what to do when no phone is found, when the phone has not allowed the computer yet, or when more than one device is connected. If Windows does not see the phone at all, install the phone maker's USB driver.

The game was called numbersgame before it was renamed SumUp, and its package name changed from `com.bartbasi.numbersgame` to `com.bartbasi.sumup`. Android treats them as two different apps, so the first SumUp install sits next to the old numbersgame app instead of replacing it, and SumUp starts without the old saved game. Uninstalling numbersgame deletes its saved game, so uninstall it only once its save has been moved.

If adb reports `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, the copy on the phone was signed with another computer's debug keystore. Uninstall SumUp on the phone first. That deletes its saved game.

### What the export contains

- The export preset is named `Android` in `export_presets.cfg`: package `com.bartbasi.sumup`, version code 1, version name taken from the project version (0.1), portrait, arm64-v8a and armeabi-v7a, Godot's prebuilt template (Gradle build off), launcher icons from `launcher/`.
- It requests no Android permissions, in debug and in release builds. The Buy me a coffee button hands its web address to the phone's browser, which needs no permission in the game, so the preset asks for none.
- It leaves out `tools/`, `tests/`, `docs/` and every review and sandbox scene.
- The export turns the four PNGs in `launcher/` into the Android launcher icons. It also packs `launcher/main_192.png` as a plain file, because `project.godot` uses it as the project icon. The other three PNGs are not packed.
- It adds three text files that are not Godot resources, so the preset's include filter lists them: `COPYING` and `NOTICE`, which the About screen reads, and the font license `src/design/fonts/OFL.txt`, which has to travel with the font.
- Debug builds are signed with the debug keystore from Godot's Editor Settings. Release signing is not set up for v1. If keystore paths or passwords are ever typed into the preset, Godot keeps them in `.godot/export_credentials.cfg`, which git ignores. Never put them in `export_presets.cfg`.

## Support

SumUp is free, with no ads and no tracking, and it always will be. If you'd like to support more games like it, you can [buy me a coffee](https://buymeacoffee.com/playinc). Never expected, always appreciated.

## License

Copyright 2026 Play, Inc.

SumUp is free software under the GNU General Public License, version 3, with three additional terms under section 7 of that license. They cover all of SumUp: its code, shaders, visuals, icons, sounds and documents.

1. Author attribution, 7(b): any work based on SumUp, in whole or in part, keeps the attribution "Based on SumUp, designed and written by Bart Basi, with assistance from Claude. Copyright 2026 Play, Inc." in its source code (by keeping the NOTICE file or its full text) and, if it has a user interface, among the legal notices it shows, such as an About screen.
2. Marking modified versions, 7(c) and 7(d): a modified version is marked as changed from the original and is not presented as the original SumUp. Beyond the attribution in term 1, it may not use the names Play, Inc. or Bart Basi to promote it or to suggest that they made or endorsed it.
3. Name and icon, 7(c) and 7(e): the license grants no trademark rights to the name SumUp or to the SumUp icon. A modified version you distribute uses its own name and icon instead. Saying it is "based on SumUp" is allowed, and term 1 requires it.

The full license text is in [COPYING](COPYING). The additional terms, in their exact wording, are in [NOTICE](NOTICE). Both ship inside the app and can be read in its About screen.

Parts made by others have their own licenses:

- The Outfit font, used by the Gumdrop and Nova skins, is under the SIL Open Font License, version 1.1. Its license is in [src/design/fonts/OFL.txt](src/design/fonts/OFL.txt).
- The Godot Engine is under the MIT license. The About screen shows the engine's license and the notices for the parts it includes.
- On Android, the engine's Android build adds the AndroidX libraries, the Kotlin standard library, kotlinx.coroutines and the JetBrains Java Annotations, all under the Apache License 2.0, and LLVM libc++, under the Apache License 2.0 with LLVM exceptions. They are listed in [NOTICE](NOTICE) and in the About screen.
