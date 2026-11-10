# Attribution — LD55

- **Authors / upstream owner:** [JereNurminen](https://github.com/JereNurminen)
- **Upstream:** https://github.com/JereNurminen/LD55
- **License:** GPL-3.0 (see `LICENSE`)
- **Pinned commit:** `eb7bc1ad418aaa89a03022730fd331a905fa697d` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the GNU General Public License v3.0.

**Third-party notes:**
- Official Unity packages only (Unity 2023.2.17f1), listed in `src/Packages/manifest.json` and `src/Packages/packages-lock.json`: 2D feature set (animation, Aseprite importer, pixel-perfect, PSD importer, sprite, SpriteShape, tilemap, and `com.unity.2d.tilemap.extras`); Universal Render Pipeline 16.0.5; Shader Graph; Timeline 1.8.6; uGUI; Visual Scripting 1.8.0; Collab Proxy; Rider / Visual Studio IDE packages; test framework; macOS/Linux toolchain; and built-in modules. All locked packages come from the Unity registry or are builtin. No packages are vendored into this snapshot.
- No TextMesh Pro, no bundled fonts. Sprites under `src/Assets/Sprites/` and WAV sounds under `src/Assets/Sounds/` appear to be original jam art; the repository contains no third-party asset credits.
- No DOTween, no EmojiOne, no FXAA, no Unity Standard Assets, no Asset Store packages, no LFS, no DLL. `ProjectSettings/ProjectVersion.txt` is retained.
- Product / jam: [Ludum Dare 55 — Pest Control](https://ldjam.com/events/ludum-dare/55/pest-control). Playable scene in EditorBuildSettings: `Assets/Scenes/Scene1.unity` (the template `Assets/Scenes/SampleScene.unity` is present but disabled).
