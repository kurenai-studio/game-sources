# Attribution — game-unity-ld58

- **Authors / upstream owner:** [cicanci](https://github.com/cicanci) (Bruno Cicanci)
- **Upstream:** https://github.com/cicanci/game-unity-ld58
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `4ea54b02559c9ef4ee359e1cbcf69a0d9d8176f0` (default branch `main`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the MIT License (Copyright 2025 Bruno Cicanci).

**Third-party notes:**
- Official Unity packages only (Unity 6000.2.6f2), listed in `src/Packages/manifest.json` and `src/Packages/packages-lock.json`: Universal Render Pipeline 17.2.0; Input System 1.14.2; AI Navigation 2.0.9; Timeline 1.8.9; uGUI 2.0.0; test framework; Visual Studio IDE package; and built-in modules. All locked packages come from the Unity registry or are builtin. No packages are vendored into this snapshot.
- LiberationSans (SIL Open Font License 1.1) is retained as the TextMesh Pro default font, including `src/Assets/TextMesh Pro/Fonts/LiberationSans - OFL.txt`.
- TextMesh Pro EmojiOne sprites and `EmojiOne.asset` were omitted. `TMP Settings.asset` `m_defaultSpriteAsset` was cleared and `m_enableEmojiSupport` was set to 0 because they pointed at the omitted EmojiOne asset. The playable scene does not require it. No TMP Documentation or Examples & Extras were present in upstream.
- No DOTween, no FXAA, no Unity Standard Assets, no Asset Store packages, no Library, no Logs, no LFS, no DLL, no `.DS_Store`. `ProjectSettings/ProjectVersion.txt` is retained.
- Product / jam: Ludum Dare 58 — Collector. Playable scene in EditorBuildSettings: `Assets/Scenes/PlaygroundScene.unity`.
