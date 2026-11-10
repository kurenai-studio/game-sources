# Attribution — LD56

- **Authors / upstream owner:** [JereNurminen](https://github.com/JereNurminen)
- **Upstream:** https://github.com/JereNurminen/LD56
- **License:** AGPL-3.0 (see `LICENSE`)
- **Pinned commit:** `70933c8dca8d7430d03214d934c5ae6a373df8a8` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the GNU Affero General Public License v3.0.

**Third-party notes:**
- Official Unity packages only (Unity 6000.0.22f1), listed in `src/Packages/manifest.json` and `src/Packages/packages-lock.json`: 2D feature set (animation, Aseprite importer, pixel-perfect, PSD importer, sprite, SpriteShape, tilemap, and `com.unity.2d.tilemap.extras`); Input System 1.11.1; Universal Render Pipeline 17.0.3; Shader Graph; Timeline 1.8.7; uGUI; Visual Scripting 1.9.4; Multiplayer Center 1.0.0 (official builtin package, not vendored); Collab Proxy; Rider / Visual Studio IDE packages; test framework; macOS/Linux toolchain; and built-in modules. All locked packages come from the Unity registry or are builtin. No packages are vendored into this snapshot.
- No TextMesh Pro, no bundled fonts. Sprites under `src/Assets/Sprites/` appear to be original jam art, including `saw_rail.aseprite`. The repository contains no third-party asset credits. macOS `.DS_Store` files were omitted from this snapshot.
- No DOTween, no EmojiOne, no FXAA, no Unity Standard Assets, no Asset Store packages, no LFS, no DLL. `ProjectSettings/ProjectVersion.txt` is retained.
- Product / jam: [Ludum Dare 56 — Sheeplings](https://ldjam.com/events/ludum-dare/56/sheeplings). Playable scenes in EditorBuildSettings: `Assets/Scenes/Level1.unity`, `Assets/Scenes/Level2.unity`, `Assets/Scenes/Level3.unity`, and `Assets/Scenes/Level4.unity` (the template `Assets/Scenes/SampleScene.unity` is present but disabled).
