# Attribution — LD57

- **Authors / upstream owner:** [JereNurminen](https://github.com/JereNurminen) (Jere Nurminen)
- **Upstream:** https://github.com/JereNurminen/LD57
- **License:** MIT (see `LICENSE`), covering files under `Assets` except the two third-party items noted below
- **Pinned commit:** `fa51d0dcee6a67b6a8064f8f04e215040795398d` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the Assets (with the exceptions below) under the MIT License (Copyright 2025 Jere Nurminen).

**Third-party notes:**
- Official Unity packages (Unity 6000.0.22f1) listed in `src/Packages/manifest.json` and `src/Packages/packages-lock.json`: Universal Render Pipeline 17.0.3; Input System 1.11.2; 2D feature 2.0.1; AI Navigation 2.0.4; Timeline 1.8.7; uGUI 2.0.0; Visual Scripting 1.9.4; Multiplayer Center 1.0.0; Unity Ads / Analytics / Purchasing; Collab Proxy; Rider / Visual Studio IDE packages; test framework; macOS toolchain; and built-in modules. Locked registry packages come from the Unity registry or are builtin. No packages are vendored into this snapshot.
- LiberationSans (SIL Open Font License 1.1) is retained as the TextMesh Pro default font, including `src/Assets/TextMesh Pro/Fonts/LiberationSans - OFL.txt`.
- TextMesh Pro EmojiOne sprites and `EmojiOne.asset` were omitted. `TMP Settings.asset` `m_defaultSpriteAsset` was cleared and `m_enableEmojiSupport` was set to 0 because they pointed at the omitted EmojiOne asset. The playable scene does not require it. No TMP Documentation or Examples & Extras were present in upstream.
- Background music [`cool-hip-hop-loop-275527.mp3`](https://pixabay.com/sound-effects/cool-hip-hop-loop-275527/) by SergeQuadrado via Pixabay (Pixabay Content License, Published 2024-12-16) was omitted along with its `.meta` file. The upstream LICENSE excludes this file from the MIT grant. The Pixabay Content License is not whitelist OSS and forbids redistributing the unaltered audio as a standalone file; shipping the mp3 as-is would not be explicitly redistributable custom OSS. GUID references may remain in the scene, consistent with the omitted C&C Red Alert font.
- The font `C&C Red Alert [LAN].ttf` by [N3tRunn3r](https://www.dafont.com/c-c-red-alert-inet.font), credited in the upstream README, and its generated TMP SDF asset `C&C Red Alert [LAN] SDF.asset`, are excluded from the MIT grant and were omitted (along with their `.meta` files) because the font is a recreation of copyrighted Command & Conquer typography and is not clearly redistributable in this archive. GUID references may remain in UI prefabs.
- `.DS_Store` files were omitted. No DOTween, no FXAA, no Unity Standard Assets, no Asset Store packages, no Library, no Logs, no LFS, no DLL. `ProjectSettings/ProjectVersion.txt` is retained.
- Product / jam: Ludum Dare 57 — Depths (entry: Umbrage). Playable scene in EditorBuildSettings: `Assets/Test.unity`.
