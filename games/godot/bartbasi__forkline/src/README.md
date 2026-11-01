# Forkline

Forkline is a tower defense game for Android phones. Night creatures come down the roads of a hillside village toward your home. The roads fork, and you place a few gates to close branches and steer them past your towers. Solve each map like a puzzle, then watch it play out.

It is free, with no ads, no in-app purchases, no accounts and no tracking. It works fully offline and asks for no permissions.

Forkline is in development. Nothing here is released yet.

Copyright 2026 Play, Inc. Designed and written by Bart Basi, with assistance from Claude. Feedback is welcome at bartbasi@gmail.com.

## Engine

Built with Godot 4.7.2 stable (`4.7.2.stable.official.ed1daf0bf`), the standard build, not .NET. GDScript, statically typed, with the Compatibility renderer. Android first. Every visual, effect, sound and piece of music is made in code in this repo. The only files made by others are the GPL text and the Outfit font with its license.

## Running the tests

From the repo root, in Bash:

```bash
godot --headless --path . --import                            # build the class cache (fresh clone, or after adding a class_name)
godot --headless --path . --quit                              # the project opens and runs
godot --headless --path . --script res://tests/run_tests.gd   # all tests; exit code 0 means every test passed
```

Add `-- --only=sim,run` to the last command to run only those folders under `tests/`.

## Setting up a fresh Windows machine

1. Install Godot 4.7.2 stable (standard build) and put `godot` on PATH. From Bash it returns real exit codes. In PowerShell it only waits and returns an exit code when its output is piped.
2. Install JDK 17 (Temurin) and the Android SDK (in `C:\Android\Sdk`, with platform-tools and build-tools).
3. In Godot, install the 4.7.2 export templates (they go in `%APPDATA%\Godot\export_templates\4.7.2.stable`).
4. In Godot's editor settings, set the Android SDK path and a debug keystore. Keep keystores outside the repo, for example in `%APPDATA%\Godot\keystores\`.

## Building and installing

From the repo root:

```bash
bash scripts/build.sh       # checks the Godot version, imports, exports build/forkline-debug.apk
bash scripts/install.sh     # checks for exactly one ready phone, then installs the APK
bash scripts/check_apk.sh   # lists what the APK bundles and checks it requests no permissions
```

PowerShell versions of the build and install scripts sit next to them (`scripts/build.ps1`, `scripts/install.ps1`). The phone needs USB debugging on.

## What the export contains

The Android package is `io.github.bartbasi.forkline`. The APK holds the game's code and scenes, the LICENSE and NOTICE files as plain text (readable in the About screen), the Godot Engine, and the libraries the Godot Android build adds (listed under License below). It requests no Android permissions. The tests, tools, docs, scripts and prototypes stay out of it.

## Support

Forkline is free, with no ads and no tracking, and it always will be. If you'd like to support more games like it, you can [buy me a coffee](https://buymeacoffee.com/playinc). Never expected, always appreciated.

## License

Copyright 2026 Play, Inc.

Forkline is free software under the GNU General Public License, version 3, with three additional terms under section 7 of that license. They cover all of Forkline: its code, shaders, visuals, icons, sounds and documents.

1. Author attribution, 7(b): any work based on Forkline, in whole or in part, keeps the attribution "Based on Forkline, designed and written by Bart Basi, with assistance from Claude. Copyright 2026 Play, Inc." in its source code (by keeping the NOTICE file or its full text) and, if it has a user interface, among the legal notices it shows, such as an About screen.
2. Marking modified versions, 7(c) and 7(d): a modified version is marked as changed from the original and is not presented as the original Forkline. Beyond the attribution in term 1, it may not use the names Play, Inc. or Bart Basi to promote it or to suggest that they made or endorsed it.
3. Name and icon, 7(c) and 7(e): the license grants no trademark rights to the name Forkline or to the Forkline icon. A modified version you distribute uses its own name and icon instead. Saying it is "based on Forkline" is allowed, and term 1 requires it.

The full license text is in [LICENSE](LICENSE). The additional terms, in their exact wording, are in [NOTICE](NOTICE). Both ship inside the app and can be read in its About screen. Every source file starts with a two line notice pointing to LICENSE and NOTICE; please keep it.

Parts made by others have their own licenses:

- The Godot Engine is under the MIT license. The About screen shows the engine's license and the notices for the parts it includes.
- On Android, the Godot build adds the AndroidX libraries, the Kotlin standard library, kotlinx.coroutines, the JetBrains Java Annotations, the JSpecify annotations and Guava's ListenableFuture, all under the Apache License, version 2.0, and LLVM libc++, under the Apache License, version 2.0, with LLVM exceptions.
- The Outfit font is under the SIL Open Font License, version 1.1. Its license is in src/theme/fonts/OFL.txt.
