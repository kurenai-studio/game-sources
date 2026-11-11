# Mobile builds

The project targets Godot **4.5.1** using the Compatibility renderer. The Android preset targets ARM64; the source can also be exported for iOS. Desktop screenshot capture and headless tests do not establish real-device performance or app-store readiness.

## Android

1. Install Godot 4.5.1 and its matching export templates using **Editor → Manage Export Templates**.
2. Install OpenJDK 17 and the Android SDK versions required by [Godot 4.5's Android export guide](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html). Set Java SDK Path and Android SDK Path in the editor's Export settings.
3. Open **Project → Export → Android**. The committed preset uses ARM64, has no Internet permission, and contains no signing credentials.
4. Export a debug APK for a connected device, or run:

   ```sh
   mkdir -p build/android
   godot --headless --path . --export-debug Android build/android/buraco-politico.apk
   adb install -r build/android/buraco-politico.apk
   ```

Release signing requires your own keystore. Configure it locally through Godot or supported export environment variables; never commit the keystore, passwords, or `.godot/export_credentials.cfg`. For Google Play distribution, enable the Gradle build, export an Android App Bundle, and complete store-specific requirements separately.

## iOS

Export on **macOS with Xcode** and the matching Godot templates. Add an iOS preset locally, provide your Apple Team ID and unique bundle identifier, export the Xcode project, and sign and run it through Xcode. The Linux development environment cannot validate an iOS build or Apple signing. See the [Godot 4.5 iOS export guide](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_ios.html).

## Device acceptance checklist

- Complete a 90-second round using only touch; test a thumb drag, lift, and a fresh drag from a different point.
- Press pause with a second finger while moving. Confirm movement stops and timer, absorption, and scoring remain frozen until resume.
- Background and foreground the app; check that interrupted input does not leave the hole moving.
- Check the smallest supported portrait display, a tall phone, a tablet, and a cutout display. Every control must remain visible and usable, with at least a 48-pixel logical target.
- Check each character, results, retry, main menu, and persistent best score after relaunch.
- Profile a full round on an actual lower-end Android device. Record frame times and peak memory; desktop software rendering is not a mobile GPU benchmark.
- Confirm readable labels and state indicators without relying only on color. Check mute behavior and system volume.

No physical-device certification or store submission is implied by the included export presets.

## Build evidence for v0.1.0

The Android ARM64 debug APK was exported successfully with Godot 4.5.1, OpenJDK 17, Android platform/build-tools 35 and the matching Godot Android template. `apksigner verify --verbose` verified v2 and v3 signatures. `aapt dump badging` reports package `com.buracopolitico.game`, minimum SDK 24 and target SDK 35. This verifies packaging and signing, not device execution. Java/Android SDK paths are local editor settings and are not committed. The project enables ETC2/ASTC texture import for Android export validation.

`GODOT_BIN=godot bash tools/export.sh` builds and packages Linux, Web and the Android debug APK. Release APK/AAB signing and iOS builds remain separate owner-controlled steps.
